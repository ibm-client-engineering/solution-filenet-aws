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

`openldap-schemas-configmap.yaml`

```yaml showLineNumbers
kind: ConfigMap
apiVersion: v1
metadata:
  name: openldap-customschema
  labels:
    app: filenet-openldap
data:
  custom.ldif: |-
    dn: cn=sds,cn=schema,cn=config
    objectClass: olcSchemaConfig
    cn: sds
    olcAttributeTypes: {0}( 1.3.6.1.4.1.42.2.27.4.1.6 NAME 'ibm-entryuuid' DESC 
      'Uniquely identifies a directory entry throughout its life.' EQUALITY caseIgnoreMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 SINGLE-VALUE )
    olcObjectClasses: {0}( 1.3.6.1.4.1.42.2.27.4.2.1 NAME 'sds' DESC 'sds' SUP top AUXILIARY MUST ( cn $ ibm-entryuuid ) )
```

```
kubectl apply -f openldap-schemas-configmap.yaml
```

`openldap-ldif-configmap.yaml`

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: openldap-customldif
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
    objectClass: sds
    cn: cpadmin
    sn: cpadmin
    uid: cpadmin
    mail: cpadmin@cp.internal
    userpassword: Password
    employeeType: admin
    ibm-entryuuid: e6c41859-ced3-4772-bfa3-6ebbc58ec78a

    dn: uid=cpuser,ou=Users,dc=filenet,dc=internal
    objectClass: inetOrgPerson
    objectClass: top
    objectClass: sds
    cn: cpuser
    sn: cpuser
    uid: cpuser
    mail: cpuser@cp.internal
    userpassword: Password
    ibm-entryuuid: 30183bb0-1012-4d23-8ae2-f94816b91a75

    # Groups
    dn: cn=cpadmins,ou=Groups,dc=filenet,dc=internal
    objectClass: groupOfNames
    objectClass: top
    objectClass: sds
    cn: cpadmins
    ibm-entryuuid: 4196cb9e-1ed7-4c02-bb0d-792cb7bfa768
    member: uid=cpadmin,ou=Users,dc=filenet,dc=internal

    dn: cn=cpusers,ou=Groups,dc=filenet,dc=internal
    objectClass: groupOfNames
    objectClass: top
    objectClass: sds
    cn: cpusers
    ibm-entryuuid: fc4ded27-8c6a-4a8c-ad9e-7be65369758c
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

`ldap_secrets.yaml`

```yaml showLineNumbers
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

```tsx
kubectl apply -f ldap_secrets.yaml
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
              add:
                - NET_BIND_SERVICE
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            seccompProfile:
              type: RuntimeDefault
          volumeMounts:
            - name: custom-schema-files
              mountPath: /schemas/
            - name: custom-ldif-files
              mountPath: /ldifs/
          terminationMessagePolicy: File
          envFrom:
            - configMapRef:
                name: openldap-env
            - secretRef:
                name: openldap
      # If you have a custom pull secret and have staged the image somewhere
#      imagePullSecrets:
#        - name: <CUSTOM PULL SECRET>
      #
      volumes:
        - name: custom-schema-files
          configMap:
            name: openldap-customschema
            defaultMode: 420
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

```bash
kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
openldap-deploy-67888c7868-9ncrc   1/1     Running   0          5m15s
```

Run an ldapsearch in the pod

```bash
kubectl exec -it openldap-deploy-67888c7868-9ncrc -- ldapsearch -x -b "dc=filenet,dc=internal" -H ldap://localhost:1389 -D 'cn=admin,dc=filenet,dc=internal' -w p@ssw0rd
```

It should return a list of the users and groups configured in the config map.


:::info

If users are not being created in the ldap instance, you can verify the ldifs are valid with the following command in the ldap pod:

```
ldapadd -x -D "cn=admin,dc=filenet,dc=internal" -w p@ssw0rd -H ldapi:/// -f /ldifs/01-default-users.ldif
```
:::

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

Now lets create a pair of ebs storage device PVCs for the database data and tablespaces.

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

Create a deployment for postgres. As per the IBM recommendations we are setting the following args for postgres to 500:

- `max_prepared_transactions=500`
- `max_connections=500`

`postgres-deploy.yaml`

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
          args:
            - '-c'
            - max_prepared_transactions=500
            - '-c'
            - max_connections=500
          image: postgres:latest # Sets Image
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 5432  # Exposes container port
          envFrom:
            - configMapRef:
                name: postgres-config
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgres-data
            - mountPath: /pgsqldata
              name: postgres-tablespaces
      volumes:
        - name: postgresdb
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

These yaml files are not set to any specific namespace, so make sure you've set your kubectl context accordingly to the namespace you want to deploy them in. As a default, we should have set our namespace context to `filenet`.

Now apply the above yaml files to the cluster:

```bash
kubectl apply -f postgres_configmap.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deploy.yaml
kubectl apply -f postgres-service.yaml
```

Verify the postgres default database we configured above is up. You can get the pod name from `kubectl get pods`

```tsx
kubectl exec -it postgres-POD-ID -- psql -h localhost -U admin --password -p 5432 defaultdb
```

### Create databases

Connect to the postgres pod

```tsx
kubectl exec -it postgres-POD-ID -- bash
```

Create the tablespace directories

```tsx
mkdir /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb

chmod 700 /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb

```

Connect to the default db. Our password will be `p@ssw0rd`.

```tsx
psql -h localhost -U admin --password -p 5432 defaultdb
```

Create the `ceuser`

```tsx
create role ceuser login password 'p@ssw0rd';
```

Create the GCD database. When you run the `\connect` command, it will query you for the password. It will still be `p@ssw0rd`.

```tsx
CREATE DATABASE gcddb OWNER ceuser TEMPLATE template0 ENCODING UTF8;
GRANT ALL ON DATABASE gcddb TO ceuser;
REVOKE CONNECT ON DATABASE gcddb FROM public;
\connect gcddb
CREATE TABLESPACE gcddb_tbs OWNER ceuser LOCATION '/pgsqldata/gcddb';
GRANT CREATE ON TABLESPACE gcddb_tbs TO ceuser;
```

Create the Object Store database. When you run the `\connect` command, it will query you for the password. It will still be `p@ssw0rd`.

```tsx
CREATE DATABASE osdb OWNER ceuser TEMPLATE template0 ENCODING UTF8 ;
GRANT ALL ON DATABASE osdb TO ceuser;
REVOKE CONNECT ON DATABASE osdb FROM public;
\connect osdb
CREATE TABLESPACE osdb_tbs OWNER ceuser LOCATION '/pgsqldata/osdb';
GRANT CREATE ON TABLESPACE osdb_tbs TO ceuser;
```

Create the ICN database. When you run the `\connect` command, it will query you for the password. It will still be `p@ssw0rd`.

```tsx
CREATE DATABASE icndb OWNER ceuser TEMPLATE template0 ENCODING UTF8;
GRANT ALL ON DATABASE icndb TO ceuser;
REVOKE CONNECT ON DATABASE gcddb FROM public;
\connect icndb
CREATE TABLESPACE icndb_tbs OWNER ceuser LOCATION '/pgsqldata/icndb';
GRANT CREATE ON TABLESPACE icndb_tbs TO ceuser;
```

## Deploy Operator

Download the IBM Case file for FileNet Content Manager. As of this writing it is **v1.7.1**. You can check for newer versions by going [here](https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-fncm-case)

```
wget https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-fncm-case/1.7.1/ibm-cp-fncm-case-1.7.1.tgz
```

Extract the case file

```
tar zxvf ibm-cp-fncm-case-1.7.1.tgz
```

Change into the operator directory and extract the container samples file

```tsx
cd ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/

tar xvf container-samples-5.5.11.tar
```

### Scripted Operator deployment

```tsx
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

### Manual Operator deployment

If you cannot run the deployment script, follow these steps to deploy the operator manually.

:::info

Available as of 22.0.2-IF004 and greater

If your cluster has resource limits required via cluster policy, you will need to update the `operator.yaml` to set those limits for the operator's init containers.

```yaml
      initContainers:
        - name: folder-prepare-container
          image: "docker-cotsimage-gts-dev.gslb.thc.travp.net/cpopen/icp4a-content-operator:23.0.1-IF003"
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
              - ALL
          resources:
            limits:
              cpu: "1"
              memory: "2Gi"
            requests:
              cpu: "500m"
              memory: "512Mi"

```
:::

From the `container-samples` directory:

```tsx
cd ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/container-samples
kubectl apply -f ./descriptors/fncm_v1_fncm_crd.yaml
kubectl apply -f ./descriptors/service_account.yaml
kubectl apply -f ./descriptors/role.yaml
kubectl apply -f ./descriptors/role_binding.yaml
kubectl apply -f ./descriptors/operator.yaml
```

### Create the `ibm-fncm-secret`

```tsx
kubectl create secret generic ibm-fncm-secret \
--from-literal=gcdDBUsername="ceuser" \
--from-literal=gcdDBPassword="p@ssw0rd" \
--from-literal=osDBUsername="ceuser" \
--from-literal=osDBPassword="p@ssw0rd" \
--from-literal=appLoginUsername="cpadmin" \
--from-literal=appLoginPassword="Password" \
--from-literal=keystorePassword="p@ssw0rd" \
--from-literal=ltpaPassword="p@ssw0rd"
```

### Create the `ibm-ban-secret` for Navigator

```tsx
kubectl create secret generic ibm-ban-secret \
  --from-literal=navigatorDBUsername="ceuser" \
  --from-literal=navigatorDBPassword="p@ssw0rd" \
  --from-literal=keystorePassword="p@ssw0rd" \
  --from-literal=ltpaPassword="p@ssw0rd" \
  --from-literal=appLoginUsername="cpadmin" \
  --from-literal=appLoginPassword="Password" \
  --from-literal=jMailUsername="mailadmin" \
  --from-literal=jMailPassword="{xor}GDoxNiosbg=="
```

Create a secret in the filenet namespace for the ldap-bind secret

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

```bash
kubectl apply -f ldap_secrets.yaml
```

## Deploying CR

Here is our example CR. Use it as reference. It would be applied with the following command to the cluster. Make sure you're in your correct namespace or have your namespace context set.

```bash
kubectl apply -f ibm_fncm_cr_production_abrv.yaml
```

`ibm_fncm_cr_production_abrv.yaml`
```yaml
apiVersion: fncm.ibm.com/v1
kind: FNCMCluster
metadata:
  name: fncmdeploy
  labels:
    app.kubernetes.io/instance: ibm-fncm
    app.kubernetes.io/managed-by: ibm-fncm
    app.kubernetes.io/name: ibm-fncm
    release: 5.5.10
spec:
  appVersion: 22.0.2
  var_setlog_true: false
  var_navigator_no_log: false
  var_fncm_no_log: false
  license:
    accept: true
  content_optional_components:
    cmis: true
    css: true
    es: false
    tm: true

  shared_configuration:
    sc_service_type: NodePort
    sc_ingress_enable: true
# Set the sc_ingress_hostname_alias only if you have an FQDN already.
    sc_ingress_hostname_alias: "filenet.filenet-east.frwd-labs.link"
# Set the tls secret name if you have a pre-existing cert already in the cluster or you are using cert-manager.
    sc_ingress_tls_secret_name: "letsencrypt-filenet-east-prod-cluster-cert"
    sc_ingress_annotations:
      - nginx.ingress.kubernetes.io/affinity: cookie
# Set cert-manager.io/issuer if you've configured cert-manager in your cluster and have set a namespace scoped issuer for it. If you created a cluster-scoped issuer, this would be cert-manager.io/cluster-issuer
      - cert-manager.io/issuer: "letsencrypt-prod"
      - nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      - nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      - nginx.ingress.kubernetes.io/secure-backends: "true"
      - nginx.ingress.kubernetes.io/session-cookie-name: route
      - nginx.ingress.kubernetes.io/session-cookie-hash: sha1
      - kubernetes.io/ingress.class: nginx
    no_log: false
    sc_deployment_context: FNCM
    image_pull_secrets:
    - ibm-entitlement-key
    sc_image_repository: cp.icr.io
    root_ca_secret: fncm-root-ca
    sc_deployment_patterns: content
    sc_deployment_type: production
    sc_fncm_license_model: "FNCM.PVUNonProd"
    sc_deployment_profile_size: "medium"
    sc_run_as_user:
    sc_deployment_platform: "other"
    # If you are using an FQDN, set it here for sc_deployment_hostname_suffix. Else comment this.
    sc_deployment_hostname_suffix: "filenet.filenet-east.frwd-labs.link" 
    trusted_certificate_list: []
    sc_content_initialization:
      cpe: true
      css: false
      ban: false
    sc_content_verification: false
    storage_configuration:
      sc_slow_file_storage_classname: "efs-sc"
      sc_medium_file_storage_classname: "efs-sc"
      sc_fast_file_storage_classname: "efs-sc"

  ldap_configuration:
  # Our example is actually using OpenLDAP, but this seems to be the only way to get it to work
    lc_selected_ldap_type: "IBM Security Directory Server"
    lc_ldap_precheck: true
  # Should be the cluster-ip of the ldap service
    lc_ldap_server: "10.100.217.46"
    lc_ldap_port: "389"
    lc_bind_secret: ldap-bind-secret
    lc_ldap_base_dn: "dc=filenet,dc=internal"
    lc_ldap_ssl_enabled: false
    lc_ldap_ssl_secret_name: "ldap"
    #lc_ldap_user_name_attribute: "*:uid"
    lc_ldap_user_name_attribute: "*:cn"
    lc_ldap_user_display_name_attr: "cn"
    lc_ldap_group_base_dn: "ou=Groups,dc=filenet,dc=internal"
    lc_ldap_group_name_attribute: "*:cn"
    lc_ldap_group_display_name_attr: "cn"
    lc_ldap_group_membership_search_filter: "(|(&(objectclass=groupofnames)(member={0}))(&(objectclass=groupofuniquenames)(uniquemember={0})))"
    lc_ldap_group_member_id_map: "groupofnames:member"
    tds:
      lc_user_filter: "(&(cn=%v)(objectclass=inetOrgPerson))"
      lc_group_filter: "(&(cn=%v)(|(objectclass=groupOfNames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"

  datasource_configuration:
    dc_ssl_enabled: false
    database_precheck: true
    dc_gcd_datasource:
      dc_database_type: "postgresql"
      dc_common_gcd_datasource_name: "FNGCDDS"
      dc_common_gcd_xa_datasource_name: "FNGCDDSXA"
  # Should be the cluster-ip of your postgresql service if running postgres in a pod, or the ip of your RDS instance
      database_servername: "10.100.80.28"
      database_name: "gcddb"
      database_port: "5432"
      database_ssl_secret_name: "<Required>"
      dc_oracle_gcd_jdbc_url: "<Required>"
      dc_hadr_validation_timeout: 15
      dc_hadr_standby_servername: "<Required>"
      dc_hadr_standby_port: "<Required>"
      dc_hadr_retry_interval_for_client_reroute: 15
      dc_hadr_max_retries_for_client_reroute: 3
    dc_os_datasources:
    - dc_database_type: "postgresql"
      dc_os_label: "os"
      dc_common_os_datasource_name: "FNOS1DS"
      dc_common_os_xa_datasource_name: "FNOS1DSXA"
  # Should be the cluster-ip of your postgresql service if running postgres in a pod, or the ip of your RDS instance
      database_servername: "10.100.80.28"
      database_name: "osdb"
      database_port: "5432"
      database_ssl_secret_name: "<Required>"
      dc_oracle_os_jdbc_url: "<Required>"
      dc_hadr_validation_timeout: 15
      dc_hadr_standby_servername: "<Required>"
      dc_hadr_standby_port: "<Required>"
      dc_hadr_retry_interval_for_client_reroute: 15
      dc_hadr_max_retries_for_client_reroute: 3
    dc_icn_datasource:
      dc_database_type: "postgresql"
      dc_common_icn_datasource_name: "ECMClientDS"
  # Should be the cluster-ip of your postgresql service if running postgres in a pod, or the ip of your RDS instance
      database_servername: "10.100.80.28"
      database_port: "5432"
      database_name: "icndb"
      database_ssl_secret_name: "<Required>"
      dc_oracle_icn_jdbc_url: "<Required>"
      dc_hadr_validation_timeout: 15
      dc_hadr_standby_servername: "<Required>"
      dc_hadr_standby_port: "<Required>"
      dc_hadr_retry_interval_for_client_reroute: 15
      dc_hadr_max_retries_for_client_reroute: 3
  initialize_configuration:
    ic_ldap_creation:
      ic_ldap_admin_user_name:
        - "cpadmin" # user name for P8 domain admin, for example, "CEAdmin".  This parameter accepts a list of values.
      ic_ldap_admins_groups_name:
        - "cpadmins" # group name for P8 domain admin, for example, "P8Administrators".  This parameter accepts a list of values.
      ic_ldap_name: ldap
    ic_domain_creation:
      domain_name: "P8DOMAIN"
      encryption_key: "128"
    ic_obj_store_creation:
      object_stores:
        - oc_cpe_obj_store_display_name: "OS01" # Required display name of the object store, for example, "OS01"
          oc_cpe_obj_store_symb_name: "OS01" # Required symbolic name of the object store, for example, "OS01"
          oc_cpe_obj_store_conn:
            name: "OS01_dbconnection"
            dc_os_datasource_name: "FNOS1DS" # This value must match with the non-XA datasource name in the "datasource_configuration" above.
            dc_os_xa_datasource_name: "FNOS1DSXA" # This value must match with the XA datasource name in the "datasource_configuration" above.
          oc_cpe_obj_store_admin_user_groups:
            - "cpadmins" # user name and group name for object store admin, for example, "CEAdmin" or "P8Administrators".  This parameter accepts a list of values.
  ecm_configuration:
    fncm_secret_name: ibm-fncm-secret
    route_ingress_annotations:
    disable_fips: true
    node_affinity:
      custom_node_selector_match_expression: [ ]
    custom_annotations: { }
    custom_labels: { }

    cpe:
      arch:
        amd64: "3 - Most preferred"
      replica_count: 2
      image:
        ## The default repository is the IBM Entitled Registry.
        repository: cp.icr.io/cp/cp4a/fncm/cpe
        tag: ga-5510-p8cpe-if001
        pull_policy: IfNotPresent
      log:
       format: json
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
          ephemeral_storage: "4Gi"
        limits:
          cpu: "1"
          memory: "3072Mi"
          ephemeral_storage: "4Gi"
      auto_scaling:
        enabled: false
        max_replicas: "<Required>"
        min_replicas: "<Required>"
        target_cpu_utilization_percentage: "<Required>"
      cpe_production_setting:
        time_zone: Etc/UTC
        jvm_initial_heap_percentage: 18
        jvm_max_heap_percentage: 33
        jvm_customize_options:
        gcd_jndi_name: FNGCDDS
        gcd_jndixa_name: FNGCDDSXA
        # The license must be set to "accept" in order for the component to install.  This is the default value.
        license: accept
      monitor_enabled: false
      logging_enabled: false
      collectd_enable_plugin_write_graphite: false
      datavolume:
        existing_pvc_for_cpe_cfgstore: 
          name: "cpe-cfgstore"
          size: 1Gi
        existing_pvc_for_cpe_logstore: 
          name: "cpe-logstore"
          size: 1Gi
        existing_pvc_for_cpe_filestore: 
          name: "cpe-filestore"
          size: 1Gi
        existing_pvc_for_cpe_icmrulestore: 
          name: "cpe-icmrulesstore"
          size: 1Gi
        existing_pvc_for_cpe_textextstore: 
          name: "cpe-textextstore"
          size: 1Gi
        existing_pvc_for_cpe_bootstrapstore: 
          name: "cpe-bootstrapstore"
          size: 1Gi
        existing_pvc_for_cpe_fnlogstore: 
          name: "cpe-fnlogstore"
          size: 1Gi
      probe:
        startup:
          initial_delay_seconds: 120
          period_seconds: 30
          timeout_seconds: 10
          failure_threshold: 16
        readiness:
          period_seconds: 30
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          period_seconds: 30
          timeout_seconds: 5
          failure_threshold: 6
      ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
      image_pull_secrets:
        name: "ibm-entitlement-key"

    css:
      arch:
        amd64: "3 - Most preferred"
      replica_count: 2
      image:
        ## The default repository is the IBM Entitled Registry.
        repository: cp.icr.io/cp/cp4a/fncm/css
        tag: ga-5510-p8css-if001
        pull_policy: IfNotPresent
      log:
        format: json
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
          ephemeral_storage: "500Mi"
        limits:
          cpu: "1"
          memory: "4096Mi"
          ephemeral_storage: "1.5Gi"
      css_production_setting:
        jvm_max_heap_percentage: 50
        license: accept
        icc:
          icc_enabled: false
          icc_secret_name: "ibm-icc-secret"
          p8domain_name: "P8DOMAIN"
          secret_masterkey_name: "icc-masterkey-txt"
      monitor_enabled: false
      logging_enabled: false
      collectd_enable_plugin_write_graphite: false
      datavolume:
        existing_pvc_for_css_cfgstore: 
          name: "css-cfgstore"
          size: 1Gi
        existing_pvc_for_css_logstore: 
          name: "css-logstore"
          size: 1Gi
        existing_pvc_for_css_tmpstore: 
          name: "css-tempstore"
          size: 1Gi
        existing_pvc_for_index: 
          name: "css-indexstore"
          size: 1Gi
        existing_pvc_for_css_customstore: 
          name: "css-customstore"
          size: 1Gi
      probe:
        startup:
          initial_delay_seconds: 60
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        readiness:
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          period_seconds: 10
          timeout_seconds: 5
          failure_threshold: 6
      ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
      image_pull_secrets:
        name: "ibm-entitlement-key"

    cmis:
      arch:
        amd64: "3 - Most preferred"
      replica_count: 2
      image:
        ## The default repository is the IBM Entitled Registry.
        repository: cp.icr.io/cp/cp4a/fncm/cmis
        tag: ga-307-cmis-la103
        pull_policy: IfNotPresent
      log:
        format: json
      resources:
        requests:
          cpu: "500m"
          memory: "256Mi"
          ephemeral_storage: "1Gi"
        limits:
          cpu: "1"
          memory: "1536Mi"
          ephemeral_storage: "1Gi"
      auto_scaling:
        enabled: false
        max_replicas: "<Required>"
        min_replicas: "<Required>"
        target_cpu_utilization_percentage: "<Required>"
      cmis_production_setting:
        cpe_url:
        time_zone: Etc/UTC
        jvm_initial_heap_percentage: 40
        jvm_max_heap_percentage: 66
        jvm_customize_options:
        ws_security_enabled: false
        checkout_copycontent: true
        default_maxitems: 25
        cvl_cache: true
        secure_metadata_cache: false
        filter_hidden_properties: true
        querytime_limit: 180
        resumable_queries_forrest: true
        escape_unsafe_string_characters: false
        max_soap_size: 180
        print_pull_stacktrace: false
        folder_first_search: false
        ignore_root_documents: false
        supporting_type_mutability: false
        license: accept
      monitor_enabled: false
      logging_enabled: false
      collectd_enable_plugin_write_graphite: false
      datavolume:
        existing_pvc_for_cmis_cfgstore: 
          name: "cmis-cfgstore"
          size: 1Gi
        existing_pvc_for_cmis_logstore: 
          name: "cmis-logstore"
          size: 1Gi
      probe:
        startup:
          initial_delay_seconds: 90
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        readiness:
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          period_seconds: 10
          timeout_seconds: 5
          failure_threshold: 6
      ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
      image_pull_secrets:
        name: "ibm-entitlement-key"

    graphql:
      arch:
        amd64: "3 - Most preferred"
      replica_count: 2
      image:
        ## The default repository is the IBM Entitled Registry.
        repository: cp.icr.io/cp/cp4a/fncm/graphql
        tag: ga-5510-p8cgql-if001
        pull_policy: IfNotPresent
      log:
        format: json
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
          ephemeral_storage: "1Gi"
        limits:
          cpu: "1"
          memory: "1536Mi"
          ephemeral_storage: "1Gi"
      auto_scaling:
        enabled: false
        max_replicas: "<Required>"
        min_replicas: "<Required>"
        target_cpu_utilization_percentage: "<Required>"
      graphql_production_setting:
        time_zone: Etc/UTC
        jvm_initial_heap_percentage: 40
        jvm_max_heap_percentage: 66
        jvm_customize_options:
        license_model: FNCM.PVUNonProd
        license: accept
        enable_graph_iql: false
      monitor_enabled: false
      logging_enabled: false
      collectd_enable_plugin_write_graphite: false
      datavolume:
        existing_pvc_for_graphql_cfgstore: 
          name: "graphql-cfgstore"
          size: 1Gi
        existing_pvc_for_graphql_logstore: 
          name: "graphql-logstore"
          size: 1Gi
      probe:
        startup:
          initial_delay_seconds: 120
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        readiness:
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          period_seconds: 10
          timeout_seconds: 5
          failure_threshold: 6
      ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
      image_pull_secrets:
        name: "ibm-entitlement-key"

    es:
      arch:
        amd64: "3 - Most preferred"
      replica_count: 2
      image:
        ## The default repository is the IBM Entitled Registry.
        repository: cp.icr.io/cp/cp4a/fncm/extshare
        tag: ga-3013-es-la102
        pull_policy: IfNotPresent
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
          ephemeral_storage: "1Gi"
        limits:
          cpu: "1"
          memory: "1536Mi"
          ephemeral_storage: "1Gi"
      auto_scaling:
        enabled: false
        max_replicas: "<Required>"
        min_replicas: "<Required>"
        target_cpu_utilization_percentage: "<Required>"
      es_production_setting:
        time_zone: Etc/UTC
        jvm_initial_heap_percentage: 40
        jvm_max_heap_percentage: 66
        jvm_customize_options:
        license_model: FNCM.PVUNonProd
        license: accept
        allowed_origins:
      monitor_enabled: false
      logging_enabled: false
      collectd_enable_plugin_write_graphite: false
      datavolume:
        existing_pvc_for_es_cfgstore: 
          name: "es-cfgstore"
          size: 1Gi
        existing_pvc_for_es_logstore: 
          name: "es-logstore"
          size: 1Gi
      probe:
        startup:
          initial_delay_seconds: 180
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        readiness:
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          period_seconds: 10
          timeout_seconds: 5
          failure_threshold: 6
      ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
      image_pull_secrets:
        name: "ibm-entitlement-key"

    tm:
      arch:
        amd64: "3 - Most preferred"
      replica_count: 2
      image:
        ## The default repository is the IBM Entitled Registry.
        repository: cp.icr.io/cp/cp4a/fncm/taskmgr
        tag: ga-3013-tm-la102
        pull_policy: IfNotPresent
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
          ephemeral_storage: "1Gi"
        limits:
          cpu: "1"
          memory: "1536Mi"
          ephemeral_storage: "1Gi"
      auto_scaling:
        enabled: false
        max_replicas: "<Required>"
        min_replicas: "<Required>"
        target_cpu_utilization_percentage: "<Required>"
      tm_production_setting:
        time_zone: Etc/UTC
        jvm_initial_heap_percentage: 40
        jvm_max_heap_percentage: 66
        jvm_customize_options: "-Dcom.ibm.ecm.task.StartUpListener.defaultLogLevel=FINE"
        license: accept
        security_roles_to_group_mapping:
           task_admins:
             groups: [taskAdmins]
             users: []
           task_users:
             groups: [taskUsers]
             users: []
           task_auditors:
             groups: [taskAuditors]
             users: []
      monitor_enabled: false
      logging_enabled: false
      collectd_enable_plugin_write_graphite: false
      datavolume:
        existing_pvc_for_tm_cfgstore: 
          name: "tm-cfgstore"
          size: 1Gi
        existing_pvc_for_tm_logstore: 
          name: "tm-logstore"
          size: 1Gi
        existing_pvc_for_tm_pluginstore: 
          name: "tm-pluginstore"
          size: 1Gi
      probe:
        startup:
          initial_delay_seconds: 120
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        readiness:
          period_seconds: 10
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          period_seconds: 10
          timeout_seconds: 5
          failure_threshold: 6
      ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
      image_pull_secrets:
        name: "ibm-entitlement-key"

  navigator_configuration:
    ban_secret_name: ibm-ban-secret
    arch:
      amd64: "3 - Most preferred"
    replica_count: 2
    image:
      ## The default repository is the IBM Entitled Registry
      repository: cp.icr.io/cp/cp4a/ban/navigator
      tag: ga-3013-icn-la102
      pull_policy: IfNotPresent
    log:
      format: json
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
        ephemeral_storage: "1Gi"
      limits:
        cpu: "1"
        memory: "3072Mi"
        ephemeral_storage: "2.5Gi"
      auto_scaling:
        enabled: false
        max_replicas: "<Required>"
        min_replicas: "<Required>"
        target_cpu_utilization_percentage: "<Required>"
    node_affinity:
      custom_node_selector_match_expression: [ ]
    custom_annotations: { }
    custom_labels: { }
    java_mail:
      host: "fncm-exchange1.ibm.com"
      port: "25"
      sender: "MailAdmin@fncmexchange.com"
      ssl_enabled: false
    disable_fips: true
    icn_production_setting:
      timezone: Etc/UTC
      gdfontpath: "/opt/ibm/java/jre/lib/fonts"
      jvm_initial_heap_percentage: 40
      jvm_max_heap_percentage: 66
      jvm_customize_options:
      icn_jndids_name: ECMClientDS
      icn_schema: ICNDB
      icn_table_space: ICNDB
      allow_remote_plugins_via_http: false
    monitor_enabled: false
    logging_enabled: false
    datavolume:
      existing_pvc_for_icn_cfgstore: 
        name: "icn-cfgstore"
        size: 1Gi
      existing_pvc_for_icn_logstore: 
        name: "icn-logstore"
        size: 1Gi
      existing_pvc_for_icn_pluginstore: 
        name: "icn-pluginstore"
        size: 1Gi
      existing_pvc_for_icnvw_cachestore: 
        name: "icn-vw-cachestore"
        size: 1Gi
      existing_pvc_for_icnvw_logstore: 
        name: "icn-vw-logstore"
        size: 1Gi
      existing_pvc_for_icn_aspera: 
        name: "icn-asperastore" 
        size: 1Gi
    probe:
      startup:
        initial_delay_seconds: 120
        period_seconds: 10
        timeout_seconds: 10
        failure_threshold: 6
      readiness:
        period_seconds: 10
        timeout_seconds: 10
        failure_threshold: 6
      liveness:
        period_seconds: 10
        timeout_seconds: 5
        failure_threshold: 6
    ## Only use this parameter if you want to override the image_pull_secrets setting in the shared_configuration above.
    image_pull_secrets:
      name: "ibm-entitlement-key"

    ## Optional entry only if you have the open_id_connect_providers enabled.
    ## if not specified it will be set to false.
    ## Enabling this will give the user the option to sign-in using the LDAP.
    #enable_ldap: true
```
## Upgrading FNCM in the cluster

Download the most recent IBM Case file for FileNet Content Manager. As of this writing it is v1.7.1. You can check for newer versions by going [here](https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-fncm-case)

```
wget https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-fncm-case/1.7.1/ibm-cp-fncm-case-1.7.1.tgz
```

Extract the case file

```
tar zxvf ibm-cp-fncm-case-1.7.1.tgz
```

Change into the operator directory and extract the container samples file

```tsx
cd ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/

tar xvf container-samples-5.5.11.tar
```

### Upgrading the operator manually

:::info
It's important to note that if you are running airgapped and you have already staged the operator image to your repository, you will need to update the image path in the `operator.yaml` file. The below example uses `sed` and updates every `image:` entry.
```
sed -i "s/image:.*/image: \"<REPO URL>\/path\/to\/icp4a-content-operator:23.0.1-IF003\"/" operator.yaml
```
This needs to be done **before** applying the `operator.yaml`! 

:::

If you cannot run the deployment script, follow these steps to deploy the operator manually.

From the `container-samples` directory:

```tsx
cd ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/container-samples
kubectl apply -f ./descriptors/operator.yaml
```

Wait for the operator to come back online after upgrading and completes its reconciliation. 

### Upgrading FNCM containers

Once the operator has been upgraded, update your CR file to the latest image tags. You can also grab the latest CR from the case directory you extracted above:

```
cd ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/container-samples/descriptors/ibm_fncm_cr_production_FC_content.yaml

```

Now apply your updated CR to the cluster:

```
kubectl apply -f ibm_fncm_cr_production.yaml
```

### Secret menu items

:::info
As of [23.0.1-IF003](https://www.ibm.com/support/pages/node/7032026) the secret menu item for disabling readonly root fs on FNCM and BAN components is available. Simply add the following to your CR:
```
shared_configuration:
  sc_disable_read_only_root_filesystem: true
``` 
This helps when you have agents like Dynatrace that inject certain configs into each container rootfs as they come up.
:::

## Deploy IER

If IBM Enterprise Records is required, you should have already staged the image per the previous instructions in Staging.

Clone the ier-samples github repo https://github.com/ibm-ecm/ier-samples

```
git clone git@github.com:ibm-ecm/ier-samples.git
```

### Create the `ibm-ier-secret`

If deploying IER, create the following
```
kubectl create secret generic ibm-ier-secret \
--from-literal=appLoginUsername="cpadmin" \
--from-literal=appLoginPassword="Password" \
--from-literal=keystorePassword="p@ssw0rd" \
--from-literal=ltpaPassword="p@ssw0rd"
```

### Updating CR for IER deployment


The following is an example CR for the IER operator.

Make sure to set the following secret name in the CR:
```
     ier_secret_name: ibm-ier-secret
```
This is important if you've already installed the FileNet operator in the cluster.

Also be sure to update the image repository paths to point to the correct registry if you are pre-staging the images in a private registry. Also make sure the correct image tag is set. As of this writing it is `ga-5218-if004-ier-2301-if003`.

In the filenet CR you used to deploy the cluster, make the following changes and additions:
```yaml
  content_optional_components:
    cpe: true
    graphql: true
    cmis: false
    css: false
    es: false
    tm: false
    ban: true
    // highlight-start
    ier: true
    // highlight-end

```
After the `navigator_configuration` entry in the CR, add the following section
```yaml
  ier_configuration:
    arch:
      amd64: "3 - Most preferred"
      replica_count: 1
      ier_ext_tls_secret_name:
      ier_auth_ca_secret_name:
      
      image:
      // highlight-start
      # This should point to whatever repo you staged the image in. Leave this as default if using IBM's registry
        repository: cp.icr.io/cp/cp4a/ier/ier
      // highlight-end
        tag: ga-5218-ier-if005
        pull_policy: IfNotPresent
      ier_secret_name: ibm-fncm-secret
      log:
        format: json
      resources:
        requests:
          cpu: 500m
          memory: 512Mi
        limits:
          cpu: 1
          memory: 1536Mi
      auto_scaling:
        enabled: false
        max_replicas: 3
        min_replicas: 1
        target_cpu_utilization_percentage: 80
      ier_production_setting:
        license: accept
      collectd_enable_plugin_write_graphite: false
      run_as_user: 
      datavolume:
        existing_pvc_for_ier_instance: ""
        
      probe:
        readiness:
          initial_delay_seconds: 120
          period_seconds: 5
          timeout_seconds: 10
          failure_threshold: 6
        liveness:
          initial_delay_seconds: 600
          period_seconds: 5
          timeout_seconds: 5
          failure_threshold: 6
```

Apply the CR after making these updates

```bash
kubectl apply -f ibm_fncm_cr_production.yaml
```

Wait for about five minutes or so and then check to see if the pod has spun up.

```
kubectl get pods
NAME                                          READY   STATUS    RESTARTS   AGE
fncmdeploy-cmis-deploy-654774fd5f-5xtnr       1/1     Running   0          6d6h
fncmdeploy-cpe-deploy-7d7dbffc94-n86tt        1/1     Running   0          3d9h
fncmdeploy-css-deploy-1-66bbd484b-qzrl9       1/1     Running   0          6d7h
fncmdeploy-es-deploy-58f9659b8b-klmjh         1/1     Running   0          6d6h
fncmdeploy-graphql-deploy-775766b99d-cx899    1/1     Running   0          6d6h
// highlight-start
fncmdeploy-ier-deploy-6f7465cd5d-sxp9d        1/1     Running   0          7h55m
// highlight-end
fncmdeploy-navigator-deploy-58b9c95c4-k9gx7   1/1     Running   0          157m
fncmdeploy-tm-deploy-7d4fd64759-x28qw         1/1     Running   0          6d6h
ibm-fncm-operator-748884b478-qkd4f            1/1     Running   0          4d2h
postgres-759fd876ff-d5fxd                     1/1     Running   0          6d9h

```
