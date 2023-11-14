---
id: solution-lessons
sidebar_position: 1
title: Lessons Learned
---

Throughout our journey on this project, the team encountered many obstacles. This section will outline any errors, blockers, and setbacks the team faced. We will discuss how these blockers were identified and resolved. 

### **DynaTrace and FileNet**

#### **The Problem**

While setting up FileNet on EKS, one of the elements the team had to take into account was the client's use of DynaTrace. Dynatrace is a performance monitoring and application performance management (APM) solution that can be used to monitor and analyze the performance of applications and services. When Dynatrace is used in a Kubernetes environment, it typically involves deploying Dynatrace agents or components as sidecar containers or as part of your application's deployment. These agents collect data about the performance of your applications, containers, and Kubernetes infrastructure and send that data to the Dynatrace platform for analysis.

During the initial setup of FileNet, the team was given a namespace that Dynatrace would be disabled in. The team was able to setup FileNet in this namespace and everything was working as intended. The FileNet containers were up and running in a healthy state for several weeks. The team was moving forward and completing use cases during this time. However, one day the team joined a session with the client and a large number of the pods were in CrashLoopBackoff.

![FileNet Lessons Learn 1.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/adcc307e-f0ea-4fda-9aa2-758d9c98e635)

The team tried all the usual troubleshooting steps like restarting the pods, scaling up and down the operator and other common troubleshooting steps. However, the crashing pods persisted and the team began to dig into the logs. After searching through several FileNet logs, the team looked through the logs of an init container associated with one of the failing pods. Here the team saw the following error:

```
cp: cannot open '/var/lib/dynatrace/oneagent/agent/config/deployment.conf' for reading: permission denied
cp: cannot open '/var/lib/dynatrace/oneagent/agent/config/deploymentChangesDataBackup' for reading: permission denied
cp: cannot access '/var/lib/dynatrace/oneagent/agent/watchdog': permission denied 
```

The team was able to find these logs using the following steps:
```
kubectl describe <NameOfFailingPod>
```
In the output there should be an 'Init Containers' section that has the name of the init container. 

![FileNet Lessons Learn 2.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/56736d1a-2cd4-4edd-9eaa-579e542a58d9)

We can now view the logs using the following command:

```
kubectl logs <NameOfFailingPod> -c <NameOfInitContainer>
```

####  **The Solution**

Dynatrace requires write access to the filesystem of the host or container where it is running to function correctly. Dynatrace agents and components need to store data, logs, and configuration information, which typically requires write access to the filesystem. In our case, FileNet filesystem is set to read-only. The team could request the client make modifications to DynaTrace. However, these accommodations were made previously and there are no guarantees that future updates to the cluster wouldn't re-enable DynaTrace in the namespace. The easiest solution would be to allow DynaTrace read/write access to FileNet's filesystem. This would eliminate any future errors and allow the client to continue to monitor with DynaTrace.

Earlier versions of FileNet have the filesystem set to read only by default. However, with the release of FileNet Version 5.5.11, FileNet deployments now have the option to set the filesystem to read/write. 

To accomplish this, we needed to update FileNet version 5.5.11 and then set the filesystem to read/write. For instructions on updating, please reference the upgrade section.

Once FileNet is upgraded to 5.5.11, we can enable the read/write file system in the CR with the following line:
```
shared_configuration:
  sc_disable_read_only_root_filesystem: true
```

Now that the filesystem has been set to read/write, DynaTrace will no longer crash the pods.

####  **Summary**

DynaTrace requires a read/wite filesystem to operate correctly. FileNet has a read-only filesystem by default. The team upgraded to FileNet version 5.5.11 that has an option to disable read-only filesystem. This fixed the crashing pods. 