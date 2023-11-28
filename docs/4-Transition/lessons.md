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

To accomplish this, we needed to update FileNet version 5.5.11 and then set the filesystem to read/write. For instructions on updating, please reference the upgrade section.

Once FileNet is upgraded to 5.5.11, we can enable the read/write file system in the CR with the following line:
```yaml
shared_configuration:
  sc_disable_read_only_root_filesystem: true
```

Now that the filesystem has been set to read/write, DynaTrace will no longer crash the pods.

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


### IBM Content Navigator

#### The Problem

While modifying settings in the navigator, we encountered the following error:

![](https://media.github.ibm.com/user/436100/files/c026119b-3b95-4323-b2e4-279285b67e7a)

The team proceeded to view the logs within one of the navigator pods and repeated the triggering action, following the debugging steps outlined above under [Dynatrace and Filenet](http://localhost:3000/solution-filenet-aws/Transition/solution-lessons#dynatrace-and-filenet). We were able to find the following system error stack trace:

![](https://media.github.ibm.com/user/436100/files/930eb18f-5d12-4f66-b9af-1bc27cf2aa24)

Thus the problem was identified as a cyrpto error within the Navigator:

```
com.ibm.ecm.crypto.CipherException: Failed to encrypt
```

#### The Solution

Matching our error to the one found in [troubleshooting crypto errors in icn](https://www.ibm.com/support/pages/troubleshooting-crypto-errors-ibm-content-navigator), namely **com.ibm.ecm.crypto.CipherException: Failed to encrypt/decrypt**, we followed [the recommended steps](https://www.ibm.com/support/pages/node/876336) to fix the problem.

Using Chrome, we opened the developer tools:

![](https://media.github.ibm.com/user/436100/files/c56bf2b7-c127-4488-a99d-7c47ac14ef83)

Next, we switched to the Console and ran

```py
# run the first and then the next
icn.admin.keys.rotateKEK()
icn.admin.keys.rotateDEKs()
```

![](https://media.github.ibm.com/user/436100/files/161bc288-a40d-4806-acb2-fd33a058badd)

:::note
Although the Console may give warnings such as _The action was canceled_, you will know that it was succcessful if you see the _x keys were rotated_ message at the bottom of the browser window, as can be see in the image above.
:::

After applying these changes, the error was gone and we instead encountered the following message indicating that the setting changes were accepted:

![](https://media.github.ibm.com/user/436100/files/7a6dbd4b-f524-43c4-88d3-83bcaaa9b4d2)

#### Summary

The IBM Content Navigator was blocking all setting changes. This is because either the data encryption key (DEK) was not encrypted using the current key encryption key (KEK) or the secret was not encrypted using the current DEK. This resulted in a `com.ibm.ecm.crypto.CipherException: Failed to encrypt` error, found in the navigator logs. The team resolved this by running the `icn.admin.keys.rotateKEK()` and `icn.admin.keys.rotateDEKs()` commands in the browser console to rotate the keys.

### Web Process Designer

:::warning

Refer to this setup to learn how to setup plugins and edit the menu in ICN. Only follow it exactly if you would like to reproduce the issue- see the solution and summary.

:::

<details>
<summary>Setup Steps</summary>
<p>
1. Download CPE applets plugin from (home-link)/peengine/plugins/CPEAppletsPlugin.jar
2. Install plug-in to ICN:
  - Navigate to _ICN Admin console_ -> _plug-ins_
  - Create new plug-in and follow the steps
  - Once the plug-in is added, validate that it shows up like this:

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/054e95f3-18a7-4e38-94de-78fa90b49d5c)

3. Create Menu
  - Pre configuration menu (for reference):

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/cb3f868c-16e4-4925-9006-c033470e2dba)

  - Navigate to _Menus_ -> _Create a custom menu_ (in desktop configuration)

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/6d729ea9-8657-498c-85e2-b91fb98623b2)

4. Navigate to _Desktops_ and open icn_desktop
5. Go to _Menus_ -> _Feature Context Menus_
  - Update "Banner tools context menu" with newly created custom menu

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/f20d2932-64d8-45c3-a37c-d5aad7b663a5)

6. Save and close. Open the desktop and now the "Open Process Designer" option should be visible as an option from the navigation bar like so:

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/625de951-a3c8-4e2d-bd74-8cb53bd4cd64)
</p>
</details>

#### The Problem

After setting up the web version of Process Designer, opening it results in the following window, which calls for a Java 1.6.0 runtime:

![](https://zenhub.ibm.com/images/649c3ae08710884b790df62c/5975ce59-a3be-4a66-bd6b-6981189b0553)

#### The Solution

The Web version of Process Designer is no longer supported. See the steps [here](https://ibm-client-engineering.github.io/solution-filenet-aws/Create/Deploy/solution-deploy-workflow) to set it up locally.

#### Summary

Web Process Designer has been discontinued; use the local version instead.