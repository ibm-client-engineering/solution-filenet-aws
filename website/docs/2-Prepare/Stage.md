---
id: stage
sidebar_position: 3
title: Stage
---
# Stage

## Hardware

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

### Sizing

#### Small (targets development)

|Component |CPU Request (m)|CPU Limit (m)|Memory Request (Mi)|Memory Limit (Mi)|Number of replicas|
|---|----|---|---|---|--|
|CPE|1000|1000|3072|3072|1|
|CSS|1000|1000|4096|4096|1|
|CSGraphQL|500|1000|1536|1536|1|
|Navigator|1000|1000|3072|3072|1|
|External Share|500|1000|1536|1536|1|
|Task Manager|500|1000|1536|1536|1|
|CMIS|500|1000|1536|1536|1|

#### Medium (targets production with high-availability)

|Component |CPU Request (m)|CPU Limit (m)|Memory Request (Mi)|Memory Limit (Mi)|Number of replicas|
|---|----|---|---|---|--|
|CPE|1500|2000|3072|3072|2|
|CSS|1000|2000|8192|8192|2|
|CSGraphQL|500|2000|3072|3072|2|
|Navigator|2000|3000|4096|4096|2|
|External Share|500|1000|1536|1536|2|
|Task Manager|500|1000|1536|1536|2|
|CMIS|500|1000|1536|1536|2|

#### Large (targets production with high-availability)

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

## AWS Account

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

## AWS VPC and EKS Cluster

### Installing or updating `eksctl`

For this we are going to use homebrew on MacOS.

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
-   Define a minimum of one node (`--nodes-min 1`) and a maximum of six-node (`--nodes-max 6`) for this node group managed by EKS. The node group is named `filenet-workers`.
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
Associate an IAM oidc provider with the cluster if you didn't include `--with-oidc` above. Make sure to use the region you created the cluster in.
```
eksctl utils associate-iam-oidc-provider --region=us-west-1 --cluster=filenet-east --approve
```

Once the cluster is up, add it to your kube config. `eksctl` will probably do this for you.

```
aws eks update-kubeconfig --name filenet-east --region us-east-1
```

## Prepare the cluster
### Install the EKS helm repo

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```
### Install the EBS driver to the cluster

Download the example ebs iam policy

```
curl -o iam-policy-example-ebs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json
```

Create the policy. You can change  `AmazonEKS_EBS_CSI_Driver_Policy` to a different name, but if you do, make sure to change it in later steps too.

```tsx
aws iam create-policy \
--policy-name AmazonEKS_EBS_CSI_Driver_Policy \
--policy-document file://iam-policy-example-ebs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EBS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN5YOUAVX2V",
        "Arn": "arn:aws:iam::748107796891:policy/AmazonEKS_EBS_CSI_Driver_Policy",
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

Create the service account using the `arn` returned above.

```tsx
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster filenet-east \
  --attach-policy-arn arn:aws:iam::748107796891:policy/AmazonEKS_EBS_CSI_Driver_Policy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

Create the addon for the cluster using the `arn` returned from the command above.
```tsx
eksctl create addon \
--name aws-ebs-csi-driver \
--cluster filenet-east \
--service-account-role-arn arn:aws:iam::748107796891:role/AmazonEKS_EBS_CSI_DriverRole \
--force
```

Create the following StorageClass yaml to use gp3

`gp3-sc.yaml`
```yaml
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
```tsx
kubectl apply -f gp3-sc.yaml
```
## Prepare EFS storage for the cluster

By default when we create a cluster with eksctl it defines and installs `gp2` storage class which is backed by Amazon's EBS (elastic block storage). Being block storage, it's not super happy supporting RWX in our cluster. We need to install an EFS storage class.

### Create an IAM policy and role

Create an IAM policy and assign it to an IAM role. The policy will allow the Amazon EFS driver to interact with your file system.

Download the example policy.
```tsx
curl -o iam-policy-example-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
```
Create the policy

```tsx
aws iam create-policy \
--policy-name AmazonEKS_EFS_CSI_Driver_Policy \
--policy-document file://iam-policy-example-efs.json

{
    "Policy": {
        "PolicyName": "AmazonEKS_EFS_CSI_Driver_Policy",
        "PolicyId": "ANPA24LVTCGN7YGDYRWJT",
        "Arn": "arn:aws:iam::748107796891:policy/AmazonEKS_EFS_CSI_Driver_Policy",
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
Create an IAM role and attach the IAM policy to it. Annotate the Kubernetes service account with the IAM role ARN and the IAM role with the Kubernetes service account name. You can create the role using `eksctl` or the AWS CLI. We're going to use `eksctl`, Also our `Arn` is returned in the output above, so we'll use it here.

```tsx
eksctl create iamserviceaccount \
    --cluster filenet-east \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::748107796891:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region us-east-1
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

```tsx
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

## Install the Loadbalancer controller

Let's install the loadbalancer controller to the cluster

### Create the IAM Policy

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


```bash
eksctl create iamserviceaccount \
  --cluster=filenet-east \
  --namespace=kube-system \
  --name=aws-load-balancer-controller-filenet \
  --role-name AmazonEKSFileNetLoadBalancerControllerRoleFileNet \
  --attach-policy-arn=arn:aws:iam::748107796891:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

### Install the AWS Load Balancer Controller.

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=filenet-east \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller-filenet

NAME: aws-load-balancer-controller
LAST DEPLOYED: Tue Jan 17 15:33:50 2023
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!

```

## Install the NGINX Controller

### Get the NGINX controller deployment
Pull down the NGINX controller deployment

```bash
wget -O nginx-deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Modify the deployment file and add the following annotations

```tsx
service.beta.kubernetes.io/aws-load-balancer-type: "external"
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

### Apply the deployment

```bash
kubectl apply -f nginx-deploy.yaml
```

### Verify the deployment

Command:

```bash
kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
alb     ingress.k8s.aws/alb    <none>       6d10h
nginx   k8s.io/ingress-nginx   <none>       7d
```

