---
id: solution-deploy
sidebar_position: 1
title: Deploy
---
# Deploy

:::info

** Manually deploy to learn. Automatically deploy to scale.**

This section goes through the deployment of FileNet on AWS EKS _step-by-step_

:::

## Deploy OpenLDAP

Let's create a namespace for openldap (This is optional. For the rest of this, we'll just stick openldap into our filenet namespace)

```
kubectl create namespace filenet-openldap
kubectl label namespace filenet-openldap app=filenet-openldap
```

Set our context to the new namespace (only if you created a separate namespace to run openldap in)

```
kubectl config set-context --current --namespace=filenet-openldap
```

Let's create some configmaps for the ldap service

`openldap-ldif-configmap.yaml`

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: openldap-customldif
  namespace: filenet
  labels:
    app: filenet-openldap
data:
  01-default-users.ldif: |-
    # cp.internal
    dn: dc=filenet,dc=internal
    objectClass: top
    objectClass: dcObject
    objectClass: organization
    o: filenet.internal
    dc: filenet

    # Units
    dn: ou=Users,dc=filenet,dc=internal
    objectClass: organizationalUnit
    ou: Users

    dn: ou=Groups,dc=filenet,dc=internal
    objectClass: organizationalUnit
    ou: Groups

    # Users
    dn: uid=cpadmin,ou=Users,dc=filenet,dc=internal
    objectClass: inetOrgPerson
    objectClass: top
    cn: cpadmin
    sn: cpadmin
    uid: cpadmin
    mail: cpadmin@cp.internal
    userpassword: Password
    employeeType: admin

    dn: uid=cpuser,ou=Users,dc=filenet,dc=internal
    objectClass: inetOrgPerson
    objectClass: top
    cn: cpuser
    sn: cpuser
    uid: cpuser
    mail: cpuser@cp.internal
    userpassword: Password

    # Groups
    dn: cn=cpadmins,ou=Groups,dc=filenet,dc=internal
    objectClass: groupOfNames
    objectClass: top
    cn: cpadmins
    member: uid=cpadmin,ou=Users,dc=filenet,dc=internal

    dn: cn=cpusers,ou=Groups,dc=filenet,dc=internal
    objectClass: groupOfNames
    objectClass: top
    cn: cpusers
    member: uid=cpadmin,ou=Users,dc=filenet,dc=internal
    member: uid=cpuser,ou=Users,dc=filenet,dc=internal
```

```
kubectl apply -f openldap-ldif-configmap.yaml
```

Create an env configmap

`openldap-env-configmap.yaml`

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: openldap-env
  labels:
    app: filenet-openldap
data:
  BITNAMI_DEBUG: 'true'
  LDAP_ORGANISATION: filnet.internal
  LDAP_ROOT: 'dc=filenet,dc=internal'
  LDAP_DOMAIN: filenet.internal
  LDAP_CUSTOM_LDIF_DIR: /ldifs
  LDAP_ADMIN_USERNAME: admin
```

```
kubectl apply -f openldap-env-configmap.yaml
```

And finally create a secret for the LDAP_ADMIN_PASSWORD. In this example we are setting the default admin password to `p@ssw0rd`

`openldap-admin-secret.yaml`

```
kind: Secret
apiVersion: v1
metadata:
  name: openldap
  labels:
    app: filenet-openldap
stringData:
  LDAP_ADMIN_PASSWORD: p@ssw0rd
```

```
kubectl apply -f openldap-admin-secret.yaml
```

Let's create our storage pvc using EFS

`openldap-pvc.yaml`

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: openldap-data
  labels:
    app: filenet-openldap
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: efs-sc
  volumeMode: Filesystem
```

```
kubectl apply -f openldap-pvc.yaml
```

Now let's create a deployment.

`openldap-deploy.yaml`

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: openldap-deploy
  labels:
    app: filenet-openldap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: filenet-openldap
  template:
    metadata:
      labels:
        app: filenet-openldap
    spec:
      containers:
        - name: openldap
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          startupProbe:
            tcpSocket:
              port: ldap-port
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 30
          readinessProbe:
            tcpSocket:
              port: ldap-port
            initialDelaySeconds: 60
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 10
          livenessProbe:
            tcpSocket:
              port: ldap-port
            initialDelaySeconds: 60
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 10
          terminationMessagePath: /dev/termination-log
          ports:
            - name: ldap-port
              containerPort: 1389
              protocol: TCP
          image: 'bitnami/openldap:latest'
          imagePullPolicy: Always
          securityContext:
            capabilities:
              drop:
                - ALL
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            seccompProfile:
              type: RuntimeDefault
          volumeMounts:
            - name: data
              mountPath: /bitnami/openldap/
            - name: custom-ldif-files
              mountPath: /ldifs/
          terminationMessagePolicy: File
          envFrom:
            - configMapRef:
                name: openldap-env
            - secretRef:
                name: openldap
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: openldap-data
        - name: custom-ldif-files
          configMap:
            name: openldap-customldif
            defaultMode: 420
```

```
kubectl apply -f openldap-deploy.yaml
```

Create a service for openldap

`openldap-service.yaml`

```yaml
kind: Service
apiVersion: v1
metadata:
  name: openldap
  labels:
    app: filenet-openldap
spec:
  ports:
    - name: ldap-port
      protocol: TCP
      port: 389
      targetPort: ldap-port
  type: NodePort
  selector:
    app: filenet-openldap
```

```
kubectl apply -f openldap-service.yaml
```

Verifying on the openldap pod

Retrieve the ldap pod name

```
kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
openldap-deploy-67888c7868-9ncrc   1/1     Running   0          5m15s
```

Run an ldapsearch in the pod

```
kubectl exec -it openldap-deploy-67888c7868-9ncrc -- ldapsearch -x -b "dc=filenet,dc=internal" -H ldap://localhost:1389 -D 'cn=admin,dc=filenet,dc=internal' -w p@ssw0rd
```

It should return a list of the users and groups configured in the config map.

- Validate

```
ldapadd -x -D "cn=admin,dc=filenet,dc=internal" -w p@ssw0rd -H ldapi:/// -f /ldifs/01-default-users.ldif
```

## Deploy Postgres

Let's create a configmap for the PGSQL database to use:

`postgres_configmap.yaml`

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: postgres-config
  labels:
    app: postgres
data:
  POSTGRES_DB: defaultdb
  POSTGRES_USER: admin
  POSTGRES_PASSWORD: p@ssw0rd
  PGDATA: /var/lib/postgresql/data/pgdata

```

Now lets create an ebs storage device PVC for the database to use. We'll make it 50gig for now.

`postgres-pvc.yaml`

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-data
  namespace: filenet
  labels:
    app: postgres
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: ebs-gp3-sc
  volumeMode: Filesystem
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-tablespaces
  labels:
    app: postgres
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ebs-gp3-sc
  volumeMode: Filesystem
```

Create a deployment for postgres

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres  # Sets Deployment name
  namespace: filenet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      securityContext:
        runAsUser: 2000
        runAsGroup: 2000
        fsGroup: 65536
      containers:
        - name: postgres
          image: postgres:latest # Sets Image
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 5432  # Exposes container port
          envFrom:
            - configMapRef:
                name: postgres-config
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgredb
            - mountPath: /pgsqldata
              name: postgres-tablespaces
      volumes:
        - name: postgredb
          persistentVolumeClaim:
            claimName: postgres-data
     - name: postgres-tablespaces
    persistentVolumeClaim:
      claimName: postgres-tablespaces
```

Create the service for postgres
`postgres-service.yaml`

```yaml
kind: Service
apiVersion: v1
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  ports:
    - name: pgsql-port
      protocol: TCP
      port: 5432
      targetPort: 5432
  type: NodePort
  selector:
    app: postgres

```

Verify the postgres default database we configured above is up. You can get the pod name from `kubectl get pods`

```tsx
kubectl exec -it postgres-POD-ID -- psql -h localhost -U admin --password -p 5432 defaultdb
```

### Create databases

Connect to the database in the pod

```tsx
kubectl exec -it postgres-POD-ID -- bash
```

Create the tablespace directories

```tsx
mkdir /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb

chmod 700 /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb

```

Connect to the default db

```tsx
psql -h localhost -U admin --password -p 5432 defaultdb
```

Create the `ceuser`

```tsx
create role ceuser login password 'p@ssw0rd';
```

For GCD

```tsx
CREATE DATABASE gcddb OWNER ceuser TEMPLATE template0 ENCODING UTF8;
GRANT ALL ON DATABASE gcddb TO ceuser;
REVOKE CONNECT ON DATABASE gcddb FROM public;
\connect gcddb
CREATE TABLESPACE gcddb_tbs OWNER ceuser LOCATION '/pgsqldata/gcddb';
GRANT CREATE ON TABLESPACE gcddb_tbs TO ceuser;
```

Create the Object Store

```tsx
CREATE DATABASE osdb OWNER ceuser TEMPLATE template0 ENCODING UTF8 ;
GRANT ALL ON DATABASE osdb TO ceuser;
REVOKE CONNECT ON DATABASE osdb FROM public;
\connect osdb
CREATE TABLESPACE osdb_tbs OWNER ceuser LOCATION '/pgsqldata/osdb';
GRANT CREATE ON TABLESPACE osdb_tbs TO ceuser;
```

For ICN

```tsx
CREATE DATABASE icndb OWNER ceuser TEMPLATE template0 ENCODING UTF8;
GRANT ALL ON DATABASE icndb TO ceuser;
REVOKE CONNECT ON DATABASE gcddb FROM public;
\connect icndb
CREATE TABLESPACE icndb_tbs OWNER ceuser LOCATION '/pgsqldata/icndb';
GRANT CREATE ON TABLESPACE icndb_tbs TO ceuser;
```

Create the Object Store

```tsx
CREATE DATABASE osdb OWNER ceuser TEMPLATE template0 ENCODING UTF8 ;
GRANT ALL ON DATABASE osdb TO ceuser;
REVOKE CONNECT ON DATABASE osdb FROM public;
\connect osdb
CREATE TABLESPACE osdb_tbs OWNER ceuser LOCATION '/pgsqldata/osdb';
GRANT CREATE ON TABLESPACE osdb_tbs TO ceuser;
```

## Deploy Operator

Download the IBM Case file for FileNet Content Manager. As of this writing it is **v1.6.2**. You can check for newer versions by going [here](https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-fncm-case)

```
wget https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-fncm-case/1.6.2/ibm-cp-fncm-case-1.6.2.tgz
```

Extract the case file

```
tar zxvf ibm-cp-fncm-case-1.6.2.tgz
```

Change into the operator directory and extract the container samples file

```tsx
cd ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/

tar xvf container-samples-5.5.10.tar

cd container-samples/scripts
```

Create `filenetvars.sh`

```tsx
#!/bin/bash
# set -x
###############################################################################
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
###############################################################################

export FNCM_PLATFORM="other"
export FNCM_NAMESPACE="filenet"
export FNCM_LICENSE_ACCEPT="Accept"
export FNCM_STORAGE_CLASS="efs-sc"
export FNCM_ENTITLEMENT_KEY="<ENTITLEMENT_KEY>"
```

You can retrieve your entitlement key from this URL:
<https://myibm.ibm.com/products-services/containerlibrary>

Source the `filenetvars.sh` file and then run the installation script from that directory:

```tsx
source ./filenetvars.sh
./deployOperator.sh
```

### Create the `ibm-fncm-secret`

```tsx
kubectl create secret generic ibm-fncm-secret \
--from-literal=gcdDBUsername="ceuser" --from-literal=gcdDBPassword="p@ssw0rd" \
--from-literal=osDBUsername="ceuser" --from-literal=osDBPassword="p@ssw0rd" \
--from-literal=icnDBUsername="ceuser" --from-literal=
--from-literal=appLoginUsername="filenet_admin" --from-literal=appLoginPassword="p@ssw0rd" \
--from-literal=keystorePassword="p@ssw0rd" \
--from-literal=ltpaPassword="p@ssw0rd"
```

### Create the `ibm-ban-secret`

```tsx
kubectl create secret generic ibm-ban-secret \
  --from-literal=navigatorDBUsername="ceuser" \
  --from-literal=navigatorDBPassword="p@ssw0rd" \
  --from-literal=keystorePassword="p@ssw0rd" \
  --from-literal=ltpaPassword="p@ssw0rd" \
  --from-literal=appLoginUsername=“cpadmin” \
  --from-literal=appLoginPassword=“Password” \
  --from-literal=jMailUsername="mailadmin" \
  --from-literal=jMailPassword="{xor}GDoxNiosbg=="
```

### Deploying CR

Create a secret in the filenet namespace

`ldap_secrets.yaml`

```yaml
kind: Secret
apiVersion: v1
metadata:
  name: ldap-bind-secret
  namespace: filenet
  labels:
    app: filenet-openldap
stringData:
  ldapUsername: "cn=admin,dc=filenet,dc=internal"
  ldapPassword: p@ssw0rd
  externalLdapUsername: "cn=admin,dc=filenet,dc=internal"
  externalLdapPassword: p@ssw0rd
```

Apply it to the cluster

NOTES

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
        - name: test-container
          image: docker-sbx-cotsimage-gts.dvllb.travp.net/cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001
       volumeMounts:
        - name: data
          mountPath: /testmount
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: efs-claim
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
    - name: app
      image: docker-cotsimage-gts-dev.gslb.thc.travp.net/cp.icr.io/cp/cp4a/fncm/cpe:ga-5510-p8cpe-if001
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo $(date -u) >> /data/out; sleep 5; done"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: ebs-claim
```
