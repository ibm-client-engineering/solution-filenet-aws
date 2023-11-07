---
id: stage
sidebar_position: 3
title: Stage
---
# Stage

## IBM Trial License

In order to use IBM Sterling B2Bi in your environment, you will require IBM licensing. Follow these steps.

1. Using your IBM ID, submit for SFG trial request using: https://www.ibm.com/account/reg/us-en/signup?formid=urx-51433

2. Use the access token for IBM Entitled Registry from Step 1 to pull and stage images (in their internal image repository, if necessary).


## Pre-Requisites

- Minimum Requirements
  - IBM FileNet Software (Images)
  - Kubectl
  - AWS CLI
  - IAM
    - AWS EKS Security Group should ALLOW communication on assigned NodePorts

- Hardware
  - EKS
    - `m5.xlarge` and region as `us-east-1`. (this has 4 vcpu and 16 gigs ram)
    - Default storage class defined
  - Jump Server/Bastion Host for staging requirements

## Sizing

### Small (targets development)

|Component |CPU Request (m)|CPU Limit (m)|Memory Request (Mi)|Memory Limit (Mi)|Number of replicas|
|---|----|---|---|---|--|
|CPE|1000|1000|3072|3072|1|
|CSS|1000|1000|4096|4096|1|
|CSGraphQL|500|1000|1536|1536|1|
|Navigator|1000|1000|3072|3072|1|
|External Share|500|1000|1536|1536|1|
|Task Manager|500|1000|1536|1536|1|
|CMIS|500|1000|1536|1536|1|

### Medium (targets production with high-availability)

|Component |CPU Request (m)|CPU Limit (m)|Memory Request (Mi)|Memory Limit (Mi)|Number of replicas|
|---|----|---|---|---|--|
|CPE|1500|2000|3072|3072|2|
|CSS|1000|2000|8192|8192|2|
|CSGraphQL|500|2000|3072|3072|2|
|Navigator|2000|3000|4096|4096|2|
|External Share|500|1000|1536|1536|2|
|Task Manager|500|1000|1536|1536|2|
|CMIS|500|1000|1536|1536|2|

### Large (targets production with high-availability)

|Component |CPU Request (m)|CPU Limit (m)|Memory Request (Mi)|Memory Limit (Mi)|Number of replicas|
|---|----|---|---|---|--|
|CPE|3000|4000|8192|8192|2|
|CSS|2000|2000|8192|8192|2|
|CSGraphQL|1000|2000|3072|3072|6|
|Navigator|2000|4000|6144|6144|6|
|External Share|500|1000|1536|1536|2|
|Task Manager|500|1000|1536|1536|2|
|CMIS|500|1000|1536|1536|2|

We are going with MEDIUM, so technically we only need 12 vcpus and 24 gigs RAM. We are going to provision a 6 node cluster with the `m5.xlarge` sizing as this will give us 24 vcpu and 96 gigs RAM, which is way more than we need anyway. Man, if there was only a sizing in AWS that was 4 VCPU/8 GIGS, that would be idea as we're going to have twice as many vpcus and 4 times as much RAM as we need.


## Set Up AWS Account

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

```tsx
vi ~/.aws/credentials

[default]
aws_access_key_id =
aws_secret_access_key =

[748107796891_AWSAdmin]
aws_access_key_id=
aws_secret_access_key=
```

Also add location info to the config file

```tsx
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

## Create AWS VPC and EKS Cluster

### Installing or updating `eksctl`

For this we are going to use homebrew

```
brew tap weaveworks/tap

brew install weaveworks/tap/eksctl
```

**We are going to create an IAM user with admin privs to create and own this whole cluster.**

In the web management UI for AWS, go to IAM settings and create a user with admin privileges but no management console access. We created a user called "K8-Admin"

Delete or rename your `~/.aws/credentials` file and re-run `aws configure` with the new user's Access and secret access keys.

### Deploying a cluster with `eksctl`

Run the `eksctl` command below to create your first cluster and perform the following:

-   Create a 6-node Kubernetes cluster named `filenet-east` with one node type as `m5.xlarge` and region as `us-east-1`.
-   Define a minimum of one node (`--nodes-min 1`) and a maximum of six-node (`--nodes-max 6`) for this node group managed by EKS. The node group is named `standard-workers`.
-   Create a node group with the name `filenet-workers` and select a machine type for the `filenet-workers` node group.

```tsx
eksctl create cluster \
--name filenet-east \
--version 1.24 \
--region us-east-1 \
--with-oidc \
--zones us-east-1a,us-east-1b,us-east-1c \
--nodegroup-name filenet-workers \
--node-type m5.xlarge \
--nodes 6 \
--nodes-min 1 \
--nodes-max 6 \
--tags "Product=FileNet" \
--managed
```
### OIDC
Associate an IAM oidc provider with the cluster if you didn't include `--with-oidc` above. Make sure to use the region you created the cluster in.
```
eksctl utils associate-iam-oidc-provider --region=us-west-1 --cluster=filenet-east --approve
```

### Configure `kubectl`

Once the cluster is up, add it to your kube config. `eksctl` will probably do this for you.

```
aws eks update-kubeconfig --name filenet-east --region us-east-1
```

## Installing Cluster components

### Install the EKS helm repo

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

### Install the EBS driver to the cluster

We install the EBS CSI driver as this gives us access to GP3 block storage.

Download the example ebs iam policy

```
curl -o iam-policy-example-ebs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json
```

Create the policy. You can change  `AmazonEKS_EBS_CSI_Driver_Policy` to a different name, but if you do, make sure to change it in later steps too.

```
aws iam create-policy \
--policy-name AmazonEKS_EBS_CSI_Driver_Policy \
--policy-document file://iam-policy-example-ebs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EBS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN5YOUAVX2V",
        "Arn": "arn:aws:iam::<ACCOUNT ID>:policy/AmazonEKS_EBS_CSI_Driver_Policy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-04-19T14:17:03+00:00",
        "UpdateDate": "2023-04-19T14:17:03+00:00"
    }
}

```
Take note of the `arn` entry for the policy that is returned above as you will need it below.

Create the service account
```
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster filenet-east \
  --attach-policy-arn arn:aws:iam::<ACCOUNT ID>:policy/AmazonEKS_EBS_CSI_Driver_Policy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```
Take note of the `arn` entry for the role that is returned above as you will need it below.

Create the addon for the cluster
```
eksctl create addon \
--name aws-ebs-csi-driver \
--cluster filenet-east \
--service-account-role-arn arn:aws:iam::<ACCOUNT ID>:role/AmazonEKS_EBS_CSI_DriverRole \
--force
```

Create the following StorageClass yaml to use gp3

`gp3-sc.yaml`
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

Create the storage class
```
kubectl apply -f gp3-sc.yaml
```

### Enable EFS on the cluster

By default when we create a cluster with eksctl it defines and installs `gp2` storage class which is backed by Amazon's EBS (elastic block storage). After that we installed the EBS CSI driver to support `gp3`. However, both `gp2` and `gp3` are both block storage. They will not support RWX in our cluster. We need to install an EFS storage class.

Download the IAM policy document from GitHub. You can also view the [policy document](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/iam-policy-example.json)
        
```tsx
curl -o iam-policy-example-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
```

Create the policy. You can change `AmazonEKS_EFS_CSI_Driver_Policy` to a different name, but if you do, make sure to change it in later steps too.

```
aws iam create-policy \
--policy-name AmazonEKS_EFS_CSI_Driver_Policy \
--policy-document file://iam-policy-example-efs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EFS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN7YGDYRWJT",
        "Arn": "arn:aws:iam::<ACCOUNT ID>:policy/AmazonEKS_EFS_CSI_Driver_Policy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2023-01-24T17:24:00+00:00",
        "UpdateDate": "2023-01-24T17:24:00+00:00"
    }
}
```
Take note of the returned policy `Arn` as you will need it in the next step.

Create an IAM role and attach the IAM policy to it. Annotate the Kubernetes service account with the IAM role ARN and the IAM role with the Kubernetes service account name. You can create the role using `eksctl` or the AWS CLI. We're going to use `eksctl`, Also our `Arn` is returned in the output above, so we'll use it here.

```tsx
eksctl create iamserviceaccount \
    --cluster filenet-east \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::<ACCOUNT ID>:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region us-east-1
```

Once created, check the iam service account is created running the following command.

```bash
eksctl get iamserviceaccount --cluster <cluster-name>

NAMESPACE	NAME				ROLE ARN
kube-system	aws-load-balancer-controller	arn:aws:iam::748107796891:role/AmazonEKSLoadBalancerControllerRole
kube-system	efs-csi-controller-sa		arn:aws:iam::748107796891:role/eksctl-filenet-cluster-east-addon-iamserviceaccount-ku-Role1-1SCBRU1DS52QY
```

Now we just need our add-on registry address. This can be found here: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

Let's install the driver add-on to our clusters. We're going to use `helm` for this.

```tsx
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/

helm repo update
```

Install a release of the driver using the Helm chart. Replace the repository address with the cluster's [container image address](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html).

```tsx
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

```
Now we need to create the filesystem in EFS so we can use it

```
export clustername=filenet-east
export region=us-east-1
```

Get our VPC ID
```tsx
vpc_id=$(aws eks describe-cluster \
    --name $clustername \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region $region \
    --output text)
```
Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.

```tsx
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```
Create a security group with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points.

```tsx
security_group_id=$(aws ec2 create-security-group \
    --group-name EFS4FileNetSecurityGroup \
    --description "EFS security group for Filenet Clusters" \
    --vpc-id $vpc_id \
    --region $region \
    --output text)
```

Create an inbound rule that allows inbound NFS traffic from the CIDR for your cluster's VPC.

```tsx
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --region $region \
    --cidr $cidr_range
```

Create a file system.
```tsx
file_system_id=$(aws efs create-file-system \
    --region $region \
    --encrypted \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)
```

Create mount targets.

Determine the IDs of the subnets in your VPC and which Availability Zone the subnet is in.
```tsx
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --region $region \
    --output table
```
Should output the following
```
----------------------------------------------------------------------
|                           DescribeSubnets                          |
+------------------+--------------------+----------------------------+
| AvailabilityZone |     CidrBlock      |         SubnetId           |
+------------------+--------------------+----------------------------+
|  us-east-1a      |  192.168.96.0/19   |  subnet-0fd12c21a45619f4e  |
|  us-east-1b      |  192.168.128.0/19  |  subnet-0025586d6737aba67  |
|  us-east-1b      |  192.168.32.0/19   |  subnet-0a437b71592c4cf58  |
|  us-east-1c      |  192.168.64.0/19   |  subnet-0475c77b9a7ba7d9e  |
|  us-east-1c      |  192.168.160.0/19  |  subnet-0b1178e74f7800166  |
|  us-east-1a      |  192.168.0.0/19    |  subnet-0db3c49d9c87a7437  |
+------------------+--------------------+----------------------------
```
Add mount targets for the subnets that your nodes are in.

Run the following command:
```bash
for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' --region $region --output text | awk '{print $3}') ; do aws efs create-mount-target --file-system-id $file_system_id --region $region --subnet-id $subnet --security-groups $security_group_id ; done
```

This wraps the below command in a for loop that will iterate through your subnet ids.
```tsx
aws efs create-mount-target \
    --file-system-id $file_system_id \
    --region $region \
    --subnet-id <SUBNETID> \
    --security-groups $security_group_id
```

Create a storage class for dynamic provisioning

Let's get our filesystem ID if we don't already have it above. However if you ran the above steps, `$file_system_id` should already be defined.
```tsx
aws efs describe-file-systems \
--query "FileSystems[*].FileSystemId" \
--region $region \
--output text

fs-071439ffb7e10b67b
```

Download a `StorageClass` manifest for Amazon EFS.
```tsx
curl -o EFSStorageClass.yaml https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/examples/kubernetes/dynamic_provisioning/specs/storageclass.yaml

```

Update it with the storage class id
```bash
sed -i 's/fileSystemId:.*/fileSystemId: fs-0f2f504e89fd0033f/' EFSStorageClass.yaml
```

Deploy the storage class.

```bash
kubectl apply -f EFSStorageClass.yaml
```

Finally, verify it's there
```tsx
kubectl get sc
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  13d
```

### Install the AWS Load Balancer Controller.

Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
```

Create an IAM policy using the policy downloaded in the previous step.

```tsx
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicy",
        "PolicyId": "ANPA24LVTCGNV55JFAAP5",
        "Arn": "arn:aws:iam::<ACCOUNT ID>:policy/AWSLoadBalancerControllerIAMPolicy",
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
Take note of the returned policy `arn` value from the policy above as you will need it in the next step.

Create a Kubernetes service account named `aws-load-balancer-controller` in the `kube-system` namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.

For our example, we are calling the cluster `filenet-east`

```bash
eksctl create iamserviceaccount \
  --cluster=filenet-east \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::748107796891:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

Now install the AWS Load Balancer Controller with helm

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=filenet-east \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

NAME: aws-load-balancer-controller
LAST DEPLOYED: Tue Jan 17 15:33:50 2023
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

### Install NGINX Controller

Pull down the NGINX controller deployment
```
wget -O nginx-deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Modify the deployment file and add the following annotations
```tsx
service.beta.kubernetes.io/aws-load-balancer-type: "external"
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

Also search for the following configmap entry in the deployment file:

```tsx
---
apiVersion: v1
data:
  allow-snippet-annotations: "false"
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.1
  name: ingress-nginx-controller
  namespace: ingress-nginx
---
```
We want to add the following annotations:

```tsx
allow-snippet-annotations: "true"
enable-underscores-in-headers: "true"
nginx.ingress.kubernetes.io/proxy-body-size: "0"
```
So now our config map should look like this
```
---
apiVersion: v1
data:
  allow-snippet-annotations: "false"
kind: ConfigMap
metadata:
  annotations:
    allow-snippet-annotations: "true"
    enable-underscores-in-headers: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "0" 
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.1
  name: ingress-nginx-controller
  namespace: ingress-nginx
---
```

Now apply the deployment
```bash
kubectl apply -f nginx-deploy.yaml
```
Verify the deployment

Command:

```bash
kubectl get ingressclass
```
Example output:

```plainText
NAME    CONTROLLER             PARAMETERS                             AGE 
alb     ingress.k8s.aws/alb    IngressClassParams.elbv2.k8s.aws/alb   19h 
nginx   k8s.io/ingress-nginx   none                                   15h
```

Once created, check the iam service account is created running the following command.

```bash
eksctl get iamserviceaccount --cluster <cluster-name>

NAMESPACE	NAME				ROLE ARN
kube-system	aws-load-balancer-controller	arn:aws:iam::748107796891:role/AmazonEKSLoadBalancerControllerRole
kube-system	efs-csi-controller-sa		arn:aws:iam::748107796891:role/eksctl-filenet-cluster-east-addon-iamserviceaccount-ku-Role1-1SCBRU1DS52QY
```
Now we just need our add-on registry address. This can be found here: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

Let's install the driver add-on to our clusters. We're going to use `helm` for this.
```
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/

helm repo update
```
Install a release of the driver using the Helm chart. Replace the repository address with the cluster's [container image address](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html).

```
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

Release "aws-efs-csi-driver" does not exist. Installing it now.
NAME: aws-efs-csi-driver
LAST DEPLOYED: Tue Jan 24 12:42:42 2023
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that aws-efs-csi-driver has started, run:

```
Apply the storage class with
```
kubectl apply -f StorageClass.yaml
```
Finally, verify it's there
```
kubectl get sc
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  13d
```
## Container Image preparation

If there is a requirement to pre-stage the FileNet images whether in a private registry or airgapped installs, the following steps should be taken. 

First retrieve your IBM ENTITLEMENT KEY from here 

[IBM Container Library](https://myibm.ibm.com/products-services/containerlibrary)

On a host with docker installed:

```
export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=[ENTITLEMENT KEY]
```

Also export your private registry credentials. You will need to know the values for "LOCAL REGISTRY ADDRESS," "LOCAL REGISTRY USER," and "LOCAL REGISTRY KEY". 

```
export LOCAL_REGISTRY=[LOCAL REGISTRY ADDRESS]
export LOCAL_REGISTRY_USER=[LOCAL REGISTRY USER]
export LOCAL_REGISTRY_KEY=[LOCAL REGISTRY KEY]
```

Login to IBM Entitled Registry with Docker

```
docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"
```

The following image list comes from the IBM FileNet Content Manager Case File ver 1.6.2. 

On your local host with docker installed, run the following pull commands:

```
docker pull cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001
docker pull cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64
docker pull cp.icr.io/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001
docker pull cp.icr.io/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64
docker pull cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001
docker pull cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64
docker pull cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103
docker pull cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64
docker pull cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102
docker pull cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64
docker pull cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001
docker pull cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64
docker pull cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102
docker pull cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64
docker pull cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102
docker pull cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64
docker pull cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102
docker pull cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64
docker pull icr.io/cpopen/icp4a-content-operator:22.0.2-IF003
docker pull icr.io/cpopen/icp4a-content-operator:22.0.2-IF003-amd64
docker pull icr.io/cpopen/ibm-fncm-operator-bundle:55.10.1
```

If including the IER operator and IER container, also pull those images:

:::note

As of this writing the latest IER version is [5.2.1.8-IER-IF005](https://www.ibm.com/support/fixcentral/swg/doSelectFixes?options.selectedFixes=5.2.1.8-IER-IF005&continue=1&source=dbluesearch&mhsrc=ibmsearch_a&mhq=enterprise+records)

:::

```
docker pull cp.icr.io/cp/cp4a/icp4a-operator:21.0.3-IF023
docker pull cp.icr.io/cp/cp4a/ier/ier:ga-5218-ier-if005
```


Docker login to your private registry

```
docker login "$LOCAL_REGISTRY" -u "$LOCAL_REGISTRY_USER" -p "$LOCAL_REGISTRY_KEY"
```

Let's tag the images we've pulled to be pushed to the private registry:

```
docker tag cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001
docker tag cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64
docker tag cp.icr.io/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001 
docker tag cp.icr.io/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64 
docker tag cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001
docker tag cp.icr.io/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64 
docker tag cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103 $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103
docker tag cp.icr.io/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64
docker tag cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102 $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102
docker tag cp.icr.io/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64
docker tag cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001 $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001
docker tag cp.icr.io/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64
docker tag cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102 $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102
docker tag cp.icr.io/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64
docker tag cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102 $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102
docker tag cp.icr.io/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64
docker tag cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102 $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102
docker tag cp.icr.io/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64 $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64
docker tag icr.io/cpopen/icp4a-content-operator:22.0.2-IF003 $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003
docker tag icr.io/cpopen/icp4a-content-operator:22.0.2-IF003-amd64 $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003-amd64 
docker tag icr.io/cpopen/ibm-fncm-operator-bundle:55.10.1 $LOCAL_REGISTRY/cpopen/ibm-fncm-operator-bundle:55.10.1
```

If including IER
```
docker tag cp.icr.io/cp/cp4a/icp4a-operator:21.0.3-IF023 $LOCAL_REGISTRY/cp/cp4a/icp4a-operator:21.0.3-IF023
docker tag cp.icr.io/cp/cp4a/ier/ier:ga-5218-ier-if005 $LOCAL_REGISTRY/cp/cp4a/ier/ier:ga-5218-ier-if005
```

Now let's push the images to the local or private registry

```
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001-amd64
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso,ga-5510-p8cpe-if001 
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cpe-sso:ga-5510-p8cpe-if001-amd64 
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/css:ga-5510-p8css-if001-amd64 
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/cmis:ga-307-cmis-la103-amd64
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/extshare:ga-3013-es-la102-amd64
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/graphql:ga-5510-p8cgql-if001-amd64
docker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102
docker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator:ga-3013-icn-la102-amd64
docker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102
docker push $LOCAL_REGISTRY/cp/cp4a/ban/navigator-sso:ga-3013-icn-la102-amd64
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102
docker push $LOCAL_REGISTRY/cp/cp4a/fncm/taskmgr:ga-3013-tm-la102-amd64
docker push $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003
docker push $LOCAL_REGISTRY/cpopen/icp4a-content-operator:22.0.2-IF003-amd64 
docker push $LOCAL_REGISTRY/cpopen/ibm-fncm-operator-bundle:55.10.1
```

If including IER
```
docker push $LOCAL_REGISTRY/cp/cp4a/icp4a-operator:21.0.3-IF023
docker push $LOCAL_REGISTRY/cp/cp4a/ier/ier:ga-5218-ier-if005
```

## Configuring RDS/DB on AWS (Optional)

If we are going to use RDS as our database provider in AWS, here's how we set that up

Create a security group. We're going to get our vpc for our filenet cluster first and use that here since we don't have any default vpc.

Let's export the following env vars

```
export clustername=filenet-cluster-east
export region=us-east-1

```
Now let's retrieve our vpc id
```
vpc_id=$(aws eks describe-cluster \
    --name $clustername \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region $region \
    --output text)
```
And with those vars set, let's now create our security group
```
security_group_id=$(aws ec2 create-security-group \
    --group-name RDSFilenetSecGroup \
    --description "RDS Access to Filenet Cluster" \
    --vpc-id $vpc_id \
    --region $region \
    --output text)
```
Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.
```
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```
Let's authorize access to that group for Oracle which uses port 1521
```
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 1521 \
    --region $region \
    --cidr $cidr_range
```
Let's create a db subnet group. First get our existing subnet ids from our vpc
```
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --region $region \
    --output table

----------------------------------------------------------------------
|                           DescribeSubnets                          |
+------------------+--------------------+----------------------------+
| AvailabilityZone |     CidrBlock      |         SubnetId           |
+------------------+--------------------+----------------------------+
|  us-east-1a      |  192.168.0.0/19    |  subnet-08ddff738c8fac2db  |
|  us-east-1b      |  192.168.32.0/19   |  subnet-0e11acfc0a427d52d  |
|  us-east-1b      |  192.168.128.0/19  |  subnet-0dd9067f0f828e49c  |
|  us-east-1c      |  192.168.160.0/19  |  subnet-0da98130d8b80f210  |
|  us-east-1a      |  192.168.96.0/19   |  subnet-02b159221adb9b790  |
|  us-east-1c      |  192.168.64.0/19   |  subnet-01987475cac20b583  |
+------------------+--------------------+----------------------------+
```
Now let's create our db subnet group
```
aws rds create-db-subnet-group \
--db-subnet-group-name "filenet-rds-subnet-group" \
--db-subnet-group-description "This is our cluster subnet ids authorized and grouped for RDS" \
--subnet-ids "subnet-08ddff738c8fac2db" "subnet-0e11acfc0a427d52d" "subnet-0dd9067f0f828e49c" "subnet-0da98130d8b80f210" "subnet-02b159221adb9b790" "subnet-01987475cac20b583"
```
Now with all those prerequisites completed, let's create the RDS instance:
```
aws rds create-db-instance \
    --engine postgresql \
    --db-instance-identifier filenet-east-db \
    --allocated-storage 300 \
    --multi-az \
    --db-subnet-group-name filenet-rds-subnet-group \
    --db-instance-class db.t3.large \
    --vpc-security-group-ids $security_group_id \
    --master-username filenetuser \
    --master-user-password filenetpass \
    --backup-retention-period 3
```
A default DB called `postgres` will be created