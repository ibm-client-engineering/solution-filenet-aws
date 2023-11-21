---
id: solution-lessons
sidebar_position: 1
title: Lessons Learned
---

Throughout our journey on this project, the team encountered many obstacles. This section will outline any errors, blockers, and setbacks the team faced. We will discuss how these blockers were identified and resolved. 

### DynaTrace and FileNet

#### The Problem

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

#### The Solution

Dynatrace requires write access to the filesystem of the host or container where it is running to function correctly. Dynatrace agents and components need to store data, logs, and configuration information, which typically requires write access to the filesystem. In our case, FileNet filesystem is set to read-only. The team could request the client make modifications to DynaTrace. However, these accommodations were made previously and there are no guarantees that future updates to the cluster wouldn't re-enable DynaTrace in the namespace. The easiest solution would be to allow DynaTrace read/write access to FileNet's filesystem. This would eliminate any future errors and allow the client to continue to monitor with DynaTrace.

Earlier versions of FileNet have the filesystem set to read only by default. However, with the release of FileNet Version 5.5.11, FileNet deployments now have the option to set the filesystem to read/write. 

To accomplish this, we needed to update FileNet version 5.5.11 and then set the filesystem to read/write. For instructions on updating, please reference the [upgrade](/docs/3-Create/Upgrade/upgrade.mdx) section.

Once FileNet is upgraded to 5.5.11, we can enable the read/write file system in the CR with the following line:
```yaml
shared_configuration:
  sc_disable_read_only_root_filesystem: true
```

Now that the filesystem has been set to read/write, DynaTrace will no longer crash the pods.

:::warning
The team continued to experience issues with DynaTrace and FileNet IER deployment. As of writing, the FileNet Dev team is working on propagating the 5.5.11 read/write filesystem to IER. 
:::

The team had to use an alternative solution for IER. This included modifying a DaemonSet. A DaemonSet ensures that all (or some) nodes in a Kubernetes cluster run a copy of a specific pod. Unlike typical deployments where you specify the desired number of replicas, a DaemonSet ensures one pod instance per node. These pods are typically used for tasks like monitoring, logging, or other system-level services that should run on every node. We used the following command:

```
kubectl -n DYNATRACE_AGENT_NAMESPACE patch daemonset YOUR_DAEMONSET_NAME -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'
```
:::note
The previous command is a template. You need to modify `DYNATRACE_AGENT_NAMESPACE` to the namespace where the DynaTrace agent is deployed. Additionally, change `YOUR_DAEMONSET_NAME` with the DynaTrace DaemonSet name. 
:::

The key part of the command was modifying the `nodeSelector` to include a label called `non-existing` with the value `true`. Essentially, this label doesn't exist on any nodes. When you update the DaemonSet's template with a non-existent node selector, it effectively makes the DaemonSet unable to schedule pods on any nodes. By applying this patch, the DynaTrace DeamonSet will not have any nodes to run the pods on and the existing DynaTrace pods are deleted. 

#### Summary

DynaTrace requires a read/wite filesystem to operate correctly. FileNet has a read-only filesystem by default. The team upgraded to FileNet version 5.5.11 that has an option to disable read-only filesystem. This fixed the crashing pods.

### Creating A Document With Content Fails and Displays A Network Error Message

#### The Problem

While the team was working on use cases with the client, we ran into a blocker when trying to upload a document. When uploading a document the team was receiving the following error message:

![FileNet Lessons Learn 3.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/6cd0cd1b-291c-4983-85b0-12083f4b6ff0)

The team was able to access the Administrative Console for Content Engine (ACCE) and it appeared that the menus and other FileNet systems were working properly. After further testing, the team was able to create a document without this error occurring. The error was only presenting when creating a document that contained content. The team tried all the usual troubleshooting steps like restarting the pods, scaling up and down the operator and other common troubleshooting steps. However, the error when creating a document with content persisted and the team began to dig into the logs.

Due to the nature of the error, the team suspected that this was being caused by some type of networking or ingress problem. So the team decided to do a network trace. This involves recording network logs in a web browser and refers to capturing and logging all network activity that occurs when you interact with a website or web application in the web browser. The team used Google Chrome for this network trace. The following outlines the steps for obtaining the logs used for troubleshooting:

First we need to make sure "Enable Trace Logging" is enabled on the Domain level. To do this click "P8DOMAIN" from the menu on the left side. This should bring up a "P8DOMAIN" window. Scroll through the tabs until you get to the tab "Trace Subsystem". In this tab you should see a check box titled "Enable Trace Logging". Select this box. 

![FileNet Lessons Learn 4.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/acf547d6-fbfe-4bcb-a672-1a4971d74770)

In the same window, you should see "Subsystems". This lists which traces to enable for which systems. 

![FileNet Lessons Learn 5.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/2b9ed02a-c0e7-4ca2-a820-c9b2c79c0f3b)

For the following subsystems, make sure you select Detail, Moderate, and Summary checkboxes:
- Content Storage Trace Flags
- Database Trace Flags
- EJB Trace Flags
- Engine Trace Flags
- Error Trace Flags

Double check your selections and if they're correct, hit the save button.

Now lets setup network logging in the browser. Again, we will be using Chrome for this. Inside the Chrome webpage, right click anywhere on the page. A menu will appear. Select "inspect" from the menu and this should bring up a Chrome debugging window. Select the network tab. Make sure "record network log" is off (It will appear as a grey circle when off). Also make sure "Preserve log" is unselected.

![FileNet Lessons Learn 7.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/0e96fca8-9247-4fe3-9979-5362b8046bb5)

Now hit the "Record Network Log" button again to start recording network activity (The Record Network Log will have a red square when recording). Next enable the "Preserve log" option. If done correctly Chrome should now display an empty log with "Record Network Log" and "Preserve log" enabled. 

![FileNet Lessons Learn 8.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/df17983c-42ae-4759-bfdb-9346f78e8299)

Now go back to the ACCE console. We will recreate the error for the logs. So we need to create a document with content. Once we get the error message again, we can examine the Chrome debugging window again. We can turn off "Record Network Log". Scrolling through the header, there is a file with an error. Here we saw the error was "413 Payload Too Large". 

![FileNet Lessons Learn 9.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/2b397a71-3f88-4617-a85d-17fc67cd3456)

Optionally we could select the export button. This will export the logs to a file. When viewing the file we saw the same "413 Payload Too Large" error.

```
...
"response": {
          "status": 413,
          "statusText": "Payload Too Large",
          "httpVersion": "http/2.0",
...
}
```

So in this situation, the NGINX server was rejecting the request due to the body size exceeding the limit.

#### The Solution

The way the team resolved this was pretty straight forward. We needed to add an annotation to the FileNet CR within EKS. We added this `nginx.ingress.kubernetes.io/proxy-body-size: "0"` annotation to the `shared_configuration` section of the CR. 

```yaml
shared_configuration:
  ## The deployment context as selected. 
  sc_deployment_context: FNCM
  show_sensitive_log: true
  no_log: false 
  sc_ingress_enable: true 
  sc_service_type: NodePort
  sc_deployment_hostname_suffix: 
  sc_ingress_tis_secret_name: "filenet-poc-tls"
  sc_ingress_annotations:
  // highlight-next-line
    - nginx.ingress.kubernetes.io/proxy-body-size: "0"
    - nginx.ingress.kubernetes.io/affinity: cookie
    - nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    - nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    - nginx.ingress.kubernetes.io/secure-backends: "true"
    - nginx.ingress.kubernetes.io/session-cookie-name: route
    - nginx.ingress.kubernetes.10/session-cookie-hash: sha1
    - kubernetes.io/ingress.class: nginx
```

When `nginx.ingress.kubernetes.io/proxy-body-size` is set to 0, this removes they payload limit size. With this change to the CR, we were able to create documents with content successfully. 

#### Summary

The NGINX server was rejecting the payload with an error "413 Payload Too Large". This caused the failure when creating a document with content. The team resolved this by removing the payload limitation by adding `nginx.ingress.kubernetes.io/proxy-body-size: "0"` annotation to the CR. 

### Logging Into Navigator Fails and Displays A Network Error Message

#### The Problem

While the team was working on use cases with the client, we ran into an issue when trying to log into Navigator. When attempting to log into Navigator, the team was receiving the following error message:

![FileNet Lessons Learn 3.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/6cd0cd1b-291c-4983-85b0-12083f4b6ff0)

This message appears to be the general error message for networking issues within FileNet. The team then decided to inspect the Navigator pod logs. First we need to bash into the pod. 

```
kubectl exec -it NAVIGATOR_POD_NAME -- bash
```

Once inside the Navigator pod, there should be a directory name `logs`. Change to that directory. Inside the logs directory, there might be multiple folders. Look for the folder with the same name as the currently running pod. That folder should contain the latest logs. When the team examined those logs we saw the following error message:

```
com.filenet.api.exception.EngineRuntimeException: FNRCA0031E: API_UNABLE_TO_USE_CONNECTION: The URI for server communication cannot be determined from the connection object URL
```

Additionally, the team was given another clue when we were able to log in to the Navigator admin desktop. You can access the admin desktop by appending `?desktop=admin` to the end of the Navigator URL. Logging into the default desktop, however, continued to throw a network error. 

The team then checked the Server URL associated with the Repositories. To do this, log into the Navigator admin desktop. Click "Repositories" from the menu on the left side. Next select the repo you want to verify the connection to. Once selected it should highlight. Now press the "Edit" button directly above. 

![FileNet Lessons Learn 10.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/5474ab10-9627-4a79-ad5b-056fbb8cfa26)

The next page will display the general settings, along with the Server URL for that repository. Here you can edit and make changes to the repository settings. If all the options are correct, click the "Connect..." button at the bottom.

![FileNet Lessons Learn 10.png](https://zenhub.ibm.com/images/6442f46ac0371b5acaba3fc4/c47f3844-6720-472b-b862-3873df2e44ac)

In our case, when we hit the connect button, we saw the same network error message we saw at the beginning. 

Alternatively, We can also view Repository connection URL in the CR as `add_repo_ce_wsi_url`.

```yaml
ic_icn_init_info:
  icn_repos:
    - add repo id: "OS01геро"
      // highlight-next-line
      add_repo_ce_wsi_url: "http://{{ meta.name }}-cpe-stateless-svc.{{ meta.namespace }}.svc:9080/wsi/FNCEWS40MTOM/"
      ...
```

We then compared the Server URL to the service in the FileNet namespace using the command:

```
kubectl get services
```

We then compared the service to the Server URL being used for the Repository connection:

```
NAME                          TYPE      CLUSTER-IP      EXTERNAL- IP    PORT(S)                         AGE
fncmdeploy-cpe-stateless-svc  NodePort  172.20.74.23    <none>          9443:31688/TCP,9103:30012/TCP   167d
```

Here the team noticed differences in the service and the Repository connection Server URL. For more information reference [Upgrading FNCM containers](/docs/3-Create/Upgrade/upgrade.mdx#upgrading-fncm-containers). As of version 5.5.11, the `add_repo_ce_wsi_url` was updated in the default CR shipped with that case. So, the team encountered this issue after upgrading to 5.5.11.

#### The Solution

The way we resolved this issue is straightforward. We need to modify the Server URL for the repository to the correct URL. The team changed this URL in the Navigator Admin Desktop and in the CR.

#### Summary

When logging into Navigator, Navigator would attempt to connect to the repository that was associated with the default desktop. Since this repository had the wrong Server URL, it failed to connect and FileNet displayed a network error message. This issue was resolved by changing the Server URL to the correct URL.  