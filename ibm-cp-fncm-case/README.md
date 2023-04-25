# Name

IBM&reg; FileNet Content Manager

# Introduction

## Summary
IBM FileNet Content Manager provides enterprise content management, enabling you to manage your organization's content and documents. The scalable software offers lifecycle management, transactional content processing, document management, content consolidation, content based application development, and compliance and governance. It helps you gain secure, mobile, anytime access across your content stores and supports your business processes.

## Features

Follow [link](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=containers-using) for more details.

* IBM&reg; FileNet Content Manager

  IBM FileNet Content Manager provides enterprise content management to enable secure access, collaboration support, content synchronization and sharing, and mobile  support to engage users over all channels and devices. IBM® FileNet® Content Manager consists of Content Process Engine (CPE), Content Search Service (CSS), Content  Management Interoperability Services (CMIS), Content Navigator Task Manager  and Content Services GraphQL (CGQL).

* IBM&reg; Content Navigator
  
  IBM Content Navigator provides a console to enable teams to view their documents, folders, and searches in ways that help them to complete their tasks.

## Details

## Prerequisites

- Follow [link] (https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployment-identifying-infrastructure-requirements)

  - IBM® FileNet Content Manager
    * Follow [link](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=containers-overview-content-services)
    * Follow [link](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=containers-v555-later-installing-operator)

  - IBM® Content Navigator
    * Follow [link](https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=domain-configuring-content-navigator-in-container-environment) for details about this product.


# PodSecurityPolicy Requirements

# SecurityContextConstraints Requirements

### Red Hat OpenShift SecurityContextConstraints Requirements
This Operator uses default Openshift Restricted SCC

  - IBM® FileNet Content Manager
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

  - IBM® Content Navigator
For Red Hat OpenShift, the default restricted SecurityContextConstraints (SCC) is sufficient.

### Resources Required

Minimum scheduling capacity:

| Software  | Memory (GB) | CPU (cores) | Disk (GB) | Nodes |
| --------- | ----------- | ----------- | --------- | ----- |
|           |             |             |           |       |
| CP4A      |  32 GB      |    8        |   500     |  3    |


# Download required container images.
- You can access the container images in the IBM Entitled registry with your IBMid.

        * Create a pull secret for the IBM Cloud Entitled Registry
          Follow [link] (https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=operator-getting-access-container-images)

## Installing

Follow [link] (https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=deployments-preparing-air-gap-environment)


### Configuration

Create a namespace and execute IBM FileNet Content Manager Operator.

## Storage

IBM® FileNet Content Engine Operator supports a NFS storage system.  A NFS storage system needs to be created as a pre-req before deploying IBM® Cloud Pak for Automation chart. 
Dynamic Provisioning of PersistenceVolumes is not supported by provising Storage Class in Custom Resource file.

## Documentation

# Limitations

Follow [link] (https://www.ibm.com/docs/en/filenet-p8-platform/5.5.x?topic=containers-known-issues-limitations-content-services)
