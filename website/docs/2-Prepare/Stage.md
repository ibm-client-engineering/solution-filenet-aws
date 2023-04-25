---
id: stage
sidebar_position: 3
title: Stage
---
# Stage


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

Sizing

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

Associated an IAM oidc provider with the cluster if you didn't include `--with-oidc` above.
```
eksctl utils associate-iam-oidc-provider --region=us-west-1 --cluster=filenet-east --approve
```


#### Configure `kubectl`

Once the cluster is up, add it to your kube config. `eksctl` will probably do this for you.

```
aws eks update-kubeconfig --name filenet-east --region us-east-1
```

### Prepare the cluster for Ingress, Loadbalancer, EBS, and EFS

Install the EKS helm repo

```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

#### Install the EBS driver to the cluster

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
Take note of the `arn` entry for the policy that is returned above as you will need it below.

Create the service account
```
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster filenet-east \
  --attach-policy-arn arn:aws:iam::748107796891:policy/AmazonEKS_EBS_CSI_Driver_Policy \
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
--service-account-role-arn arn:aws:iam::748107796891:role/AmazonEKS_EBS_CSI_DriverRole \
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

### Prepare EFS storage for the cluster

#### Enable EFS on the cluster

By default when we create a cluster with eksctl it defines and installs `gp2` storage class which is backed by Amazon's EBS (elastic block storage). After that we installed the EBS CSI driver to support `gp3`. However, both `gp2` and `gp3` are both block storage. They will not support RWX in our cluster. We need to install an EFS storage class.

Download the IAM policy document from GitHub. You can also view the [policy document](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/iam-policy-example.json)
        
```
curl -o iam-policy-example-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
```

Create the policy. You can change `` `AmazonEKS_EFS_CSI_Driver_Policy` `` to a different name, but if you do, make sure to change it in later steps too.

```
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
Take note of the returned policy arn as you will need it in the next step.

Create an IAM role and attach the IAM policy to it. Annotate the Kubernetes service account with the IAM role ARN and the IAM role with the Kubernetes service account name. You can create the role using `eksctl` or the AWS CLI. We're gonna use `eksctl`, Also our `Arn` is returned in the output above, so we'll use it here.

```
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

```
Now we need to create the filesystem in EFS so we can use it

```
export clustername=filenet-east
export region=us-east-1
```



### Create an IAM policy and role

Create an IAM policy and assign it to an IAM role. The policy will allow the Amazon EFS driver to interact with your file system.


Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```
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
Take note of the returned policy `arn` value from the policy above as you will need it in the next step.

### Create an IAM role. 

Create a Kubernetes service account named `aws-load-balancer-controller` in the `kube-system` namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.

For our example, we are calling the cluster `filenet-east`

```
eksctl create iamserviceaccount \
  --cluster=filenet-east \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::748107796891:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```
### Install the AWS Load Balancer Controller.
```
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
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Modify the deployment file and add the following annotations
```
service.beta.kubernetes.io/aws-load-balancer-type: "external"
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

Apply the deployment
```
kubectl apply -f deploy.yaml
```
Verify the deployment

Command:

```plainText
kubectl get ingressclass
```

Example output:

```plainText
NAME    CONTROLLER             PARAMETERS                             AGE 
alb     ingress.k8s.aws/alb    IngressClassParams.elbv2.k8s.aws/alb   19h 
nginx   k8s.io/ingress-nginx   none                                   15h
```

### Configure EFS

 Create an IAM policy that allows the CSI driver's service account to make calls to AWS APIs on your behalf. This will also allow it to create access points on the fly.

 Download the IAM policy document from GitHub.

 ```
 curl -o iam-policy-example-efs.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
 ```

 Create the policy. 

 ```
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
Pay attention to the `Arn` value above.

Create an IAM role and attach the IAM policy to it. Annotate the Kubernetes service account with the IAM role ARN and the IAM role with the Kubernetes service account name. You can create the role using `eksctl` or the AWS CLI. We're going to use `eksctl`, Also our `Arn` is returned in the output above, so we'll use it here.

```
eksctl create iamserviceaccount \
    --cluster filenet-cluster-east \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::748107796891:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region us-east-1
```

Copy the following contents to a file named `` `trust-policy`.json ``. Replace `` `111122223333` `` with your account ID. Replace `` `EXAMPLED539D4633E53DE1B71EXAMPLE` `` and `` `region-code` `` with the values returned in the previous step. 

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }
  ]
}
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

    kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=aws-efs-csi-driver"
```
Now we need to create the filesystem in EFS so we can use it

Retrieve the VPC ID that your cluster is in and store it in a variable for use in a later step. Replace `` `my-cluster` `` with your cluster name. We'll have to wash, rinse, repeat for both of our clusters. 

Let's make life easier and just export the clustername as `$clustername` and the region as `$region`

```
export clustername=filenet-cluster-east
export region=us-east-1
```

```
vpc_id=$(aws eks describe-cluster \
    --name $clustername \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --region $region \
    --output text)
```

Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step. Replace `` `region-code` `` with the AWS Region that your cluster is in.

```
cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region $region)
```

Create a security group with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points.

```
security_group_id=$(aws ec2 create-security-group \
    --group-name EFS4MQSecurityGroup \
    --description "MQ EFS security group latest" \
    --vpc-id $vpc_id \
    --region $region \
    --output text)
```

Create an inbound rule that allows inbound NFS traffic from the CIDR for your cluster's VPC.

```
aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --region $region \
    --cidr $cidr_range
```

Create a file system. Replace `` `region-code` `` with the AWS Region that your cluster is in.
```
file_system_id=$(aws efs create-file-system \
    --region $region \
    --encrypted \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)
```
Create mount targets.

Determine the IP address of your cluster nodes.
```
kubectl get nodes
NAME                             STATUS   ROLES    AGE   VERSION
ip-192-168-20-100.ec2.internal   Ready    <none>   13d   v1.21.14-eks-fb459a0
ip-192-168-27-120.ec2.internal   Ready    <none>   13d   v1.21.14-eks-fb459a0
ip-192-168-39-167.ec2.internal   Ready    <none>   13d   v1.21.14-eks-fb459a0
ip-192-168-51-132.ec2.internal   Ready    <none>   13d   v1.21.14-eks-fb459a0
```

Determine the IDs of the subnets in your VPC and which Availability Zone the subnet is in.
```
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --region $region \
    --output table

---------------------------------------------------------------------
|                          DescribeSubnets                          |
+------------------+-------------------+----------------------------+
| AvailabilityZone |     CidrBlock     |         SubnetId           |
+------------------+-------------------+----------------------------+
|  us-east-1b      |  192.168.96.0/19  |  subnet-0fab8f4f18bd31c1a  |
|  us-east-1d      |  192.168.64.0/19  |  subnet-06f1d5a671338af2f  |
|  us-east-1b      |  192.168.32.0/19  |  subnet-0a648663fc5c847b8  |
|  us-east-1d      |  192.168.0.0/19   |  subnet-06717fbaf2d8a0e52  |
+------------------+-------------------+----------------------------+
```

Add mount targets for the subnets that your nodes are in. Basically, for each SubnetId above, run the following command:

```
aws efs create-mount-target \
    --file-system-id $file_system_id \
    --region $region \
    --subnet-id <SUBNETID> \
    --security-groups $security_group_id
```
Create a storage class for dynamic provisioning

Let's get our filesystem ID if we don't already have it. If we ran the above commands, it should already be an exported variable in our env.
```
aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --region $region --output text

```
Create the following storage class manifest. Make sure the `fileSystemId` is set to the filesystem id you just created.

`StorageClass.yaml`
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
mountOptions:
  - tls
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-02371262af220c220
  directoryPerms: "775"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "3000" # optional
  basePath: "/efs/dynamic_provisioning" # optional
```
As a note for above, for MQ to work happily with EFS you need to specify the uid/gid in the storage class. Otherwise you will get permission errors when the container comes up and the process tries to update the `mq.ini` file.

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
### Container Image preparation

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




### Configuring RDS/DB on AWS
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

Create an IAM role. Create a Kubernetes service account named `aws-load-balancer-controller` in the `kube-system` namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role.
---

id: stage
sidebar_position: 3
title: Stage
---

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


- IBM Entitled Registry entitlement key
  - Can be retrieved here <https://myibm.ibm.com/products-services/containerlibrary>

### Stage Requirements
>>>>>>> f27988dfd0d207b9cb1241cbf068b26c19cbf0b9:website/docs/3-Build/Prepare.md

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

```tsx
export AWS_PROFILE=xxxxxxx_AWSAdmin
```

You may also copy the following out of the aws portal and paste it into your shell

```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

## Create AWS VPC and EKS Cluster

- Installing or updating `eksctl`

For this we are going to use homebrew

```tsx
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

```tsx
eksctl create cluster \
--name filenet-cluster-east \
--version 1.24 \
--region us-east-1 \
--nodegroup-name standard-workers \
--node-type m5.xlarge \
--nodes 6 \
--nodes-min 1 \
--nodes-max 7 \
--managed
```

## Configure `kubectl`

Once the cluster is up, add it to your kube config

```
aws eks update-kubeconfig --name filenet-cluster-east --region us-east-1
Added new context arn:aws:eks:us-east-1:748107796891:cluster/filenet-cluster-east to /Users/user/.kube/config
```

## Prepare the cluster for Ingress, Loadbalancer, and EFS

Associated an IAM oidc provider with the cluster. Assuming our region is `us-east-1`.

```
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=filenet-cluster-east --approve
```

Install the EKS helm repo

```tsx
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.

```tsx
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
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
