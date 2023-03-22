---
id: solution-prepare
sidebar_position: 1
title: Prepare
---

## Pre-Requisites

- Minimum Requirements
  - Software
  - Kubectl
  - AWS CLI
  - IAM
    - AWS EKS Security Group should ALLOW communication on assigned NodePorts

- Hardware
  - EKS
    - `m5.xlarge` and region as `us-east-1`. (this has 4 vcpu and 16 gigs ram)
    - Default storage class defined
  - Jump Server/Bastion Host for staging requirements

### Stage Requirements

#### Set Up AWS Account

- CMDLINE Client install (MacOS)

Download the client

```
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
```

Install it with sudo (to use for all users)

```
sudo installer -pkg ./AWSCLIV2.pkg -target /
```

Now let's configure our client env

```
aws configure
```

Answer all the questions with the info you got. If you already have a profile configured, you can add a named profile to your credentials

```
vi ~/.aws/credentials

[default]
aws_access_key_id =
aws_secret_access_key =

[748107796891_AWSAdmin]
aws_access_key_id=
aws_secret_access_key=
```

Also add location info to the config file

```
vi ~/.aws/config

[default]
region = us-east-1
output = json

[profile techzone_user]
region=us-east-1
output=json
```

We are also going to use some env magic to make sure we stick with the second profile

```
export AWS_PROFILE=748107796891_AWSAdmin
```

You may also copy the following out of the aws portal and paste it into your shell

```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

#### Create AWS VPC and EKS Cluster

- Installing or updating `eksctl`

For this we are going to use homebrew

```
brew tap weaveworks/tap

brew install weaveworks/tap/eksctl
```

**We are going to create an IAM user with admin privs to create and own this whole cluster.**

In the web management UI for AWS, go to IAM settings and create a user with admin privileges but no management console access. We created a user called "K8-Admin"

Delete or rename your `~/.aws/credentials` file and re-run `aws configure` with the new user's Access and secret access keys.

- Deploying a cluster with `eksctl`

Run the `eksctl` command below to create your first cluster and perform the following:

- Create a 3-node Kubernetes cluster named `dev` with one node type as `m5.xlarge` and region as `us-east-1`. (this has 4 vCPU and 16 GB Memory)
- Define a minimum of one node (`--nodes-min 1`) and a maximum of five-node (`--nodes-max 5`) for this node group managed by EKS. The node group is named `standard-workers`.
- Create a node group with the name `standard-workers` and select a machine type for the `standard-workers` node group.

```
eksctl create cluster \
--name mq-cluster \
--version 1.22 \
--region us-east-1 \
--nodegroup-name standard-workers \
--node-type m5.xlarge \
--nodes 6 \
--nodes-min 1 \
--nodes-max 7 \
--managed
```

#### Configure `kubectl`

Once the cluster is up, add it to your kube config

```
aws eks update-kubeconfig --name mq-cluster --region us-east-1
Added new context arn:aws:eks:us-east-1:748107796891:cluster/mq-cluster to /Users/user/.kube/config
```

#### Prepare the cluster for Ingress, Loadbalancer, and EFS

Associated an IAM oidc provider with the cluster. Assuming our region is `us-east-1`.

```
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=mq-cluster --approve
```

Install the EKS helm repo

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
```

Create an IAM policy using the policy downloaded in the previous step.

```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicy",
        "PolicyId": "ANPA24LVTCGNV55JFAAP5",
        "Arn": "arn:aws:iam::748107796891:policy/AWSLoadBalancerControllerIAMPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-01-17T20:22:23+00:00",
        "UpdateDate": "2023-01-17T20:22:23+00:00"
    }
}
```

Create an IAM role. Create a Kubernetes service account named `aws-load-balancer-controller` in the `kube-system` namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.
