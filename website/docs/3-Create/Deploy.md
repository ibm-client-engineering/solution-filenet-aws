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

### Create configmaps and secrets
Let's create some configmaps for the ldap service

`openldap-ldif-configmap.yaml`

```yaml showLineNumbers
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

```yaml showLineNumbers
kind: Secret
apiVersion: v1
metadata:
  name: openldap
  labels:
    app: filenet-openldap
stringData:
  LDAP_ADMIN_PASSWORD: p@ssw0rd
```
Apply it to the cluster
```bash
kubectl apply -f openldap-admin-secret.yaml
```
Add an `ldap-bind-secret`

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
### Create PVC for OpenLdap
Let's create our storage pvc using EFS

`openldap-pvc.yaml`

```yaml showLineNumbers
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

### Create Openldap Deployment
Now let's create a deployment.

`openldap-deploy.yaml`

```yaml showLineNumbers
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

```bash
kubectl apply -f openldap-deploy.yaml
```

### Create Service for Openldap
Create a service for openldap

`openldap-service.yaml`

```yaml showLineNumbers
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

### Verifying openldap pod

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

## Deploy Postgres

### Create Configmap
Let's create a configmap for the PGSQL database to use:

`postgres_configmap.yaml`

```yaml showLineNumbers
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
### Create Storage PVCs
Now lets create a couple of ebs storage device PVCs for the database to use. We'll make them 5Gi for now.

`postgres-pvc.yaml`

```yaml showLineNumbers
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: postgres-data
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
### Create Deployment
Create a deployment for postgres

```yaml showLineNumbers
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
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
### Create Postgres Service
Create the service for postgres
`postgres-service.yaml`

```yaml showLineNumbers
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

Verify the postgres default database we configured above is up by connecting to the service.
```tsx
kubectl exec -it service/postgres -- psql -h localhost -U admin --password -p 5432 defaultdb
```

### Create and configure databases

Connect to the postgres pod

```tsx
kubectl exec -it postgres-POD-ID -- bash
```

Create the tablespace directories

```tsx
mkdir -p /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb

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
exit
```

## Deploy FilNet Operator

:::note

These steps **need to be run** on a host that has `docker` or `podman` available and active.

:::

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

```tsx showLineNumbers
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

```tsx showLineNumbers
kubectl create secret generic ibm-fncm-secret \
--from-literal=gcdDBUsername="ceuser" --from-literal=gcdDBPassword="p@ssw0rd" \
--from-literal=osDBUsername="ceuser" --from-literal=osDBPassword="p@ssw0rd" \
--from-literal=icnDBUsername="ceuser" --from-literal=
--from-literal=appLoginUsername="filenet_admin" --from-literal=appLoginPassword="p@ssw0rd" \
--from-literal=keystorePassword="p@ssw0rd" \
--from-literal=ltpaPassword="p@ssw0rd"
```

### Create the `ibm-ban-secret`

```tsx showLineNumbers
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

## Deploying CR

The annotated CR file can be found in the extracted containers samples file in the case file directory. If you have been following the directions up to this point, the path to the file below should exist.

```
ibm-cp-fncm-case/inventory/fncmOperator/files/deploy/crs/container-samples/descriptors/ibm_fncm_cr_production.yaml
```
### Modify CR File

Below is the `ibm_fncm_cr_production.yaml` as modified. Important lines have been highlighted.

```yaml showLineNumbers
###############################################################################
##
##Licensed Materials - Property of IBM
##
##(C) Copyright IBM Corp. 2022. All Rights Reserved.
##
##US Government Users Restricted Rights - Use, duplication or
##disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##
###############################################################################
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
  ##########################################################################
  ## This section contains the shared configuration for all FNCM components #
  ##########################################################################
  appVersion: 22.0.2

  ## MUST exist, used to accept ibm license, valid value only can be "true"
  license:
    accept: true

  ## The optional components to be installed if listed here.  The user can choose what components to be installed.
  ## The optional components are: css (Content Search Services), cmis, es (External Share) and tm (Task Manager)
// highlight-start
  content_optional_components:
    cmis: true
    css: true
    es: false
    tm: true
// highlight-end

  ecm_configuration:
    fncm_secret_name: ibm-fncm-secret

  shared_configuration:

    ## The deployment context as selected.
    sc_deployment_context: FNCM
    show_sensitive_log: true
// highlight-start
    sc_ingress_enable: true
    sc_service_type: ClusterIP
    sc_ingress_annotations:
      - nginx.ingress.kubernetes.io/affinity: cookie
      - nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      - nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      - nginx.ingress.kubernetes.io/secure-backends: "true"
      - nginx.ingress.kubernetes.io/session-cookie-name: route
      - nginx.ingress.kubernetes.io/session-cookie-hash: sha1
      - kubernetes.io/ingress.class: nginx
// highlight-end
    ## All FNCM components must use/share the image_pull_secrets to pull images
    image_pull_secrets:
    - ibm-entitlement-key

    ## All FNCM components must use/share the same docker image repository.  For example, if IBM Entitlement Registry is used, then
    ## it should be "cp.icr.io".  Otherwise, it will be a local docker registry.
// highlight-start
    sc_image_repository: cp.icr.io
// highlight-end
    ## All FNCM components must use/share the root_ca_secret in order for integration
    root_ca_secret: fncm-root-ca

    ## FNCM capabilities to be deployed.  This CR represents the "content" pattern (aka FileNet Content Manager), which includes the following
    ## mandatory components: cpe, icn (Navigator), graphql and optional components: css, cmis, es (External Share) and tm (Task Manager)
// highlight-next-line
    sc_deployment_patterns: content

    ## The deployment type as selected.
// highlight-next-line
    sc_deployment_type: production

    ## Choose the licensing model for the Product you are installing.
    ## IBM Content Foundation:
    ## - ICF.PVUNonProd
    ## - ICF.PVUProd
    ## - ICF.UVU
    ## - ICF.CU
    ## IBM Filenet Content Manager:
    ## - FNCM.PVUNonProd
    ## - FNCM.PVUProd
    ## - FNCM.UVU
    ## - FNCM.CU
    ## IBM Cloud Pak for Business Automation:
    ## - CP4BA.NonProd
    ## - CP4BA.Prod
    ## - CP4BA.User
// highlight-start
    sc_fncm_license_model: "FNCM.PVUNonProd"
// highlight-end
    ## Optional: You can specify a profile size for CloudPak - valid values are small,medium,large - default is small.
// highlight-next-line
    sc_deployment_profile_size: "medium"

    ## Specify the RunAsUser for the security context of the pod.  This is usually a numeric value that corresponds to a user ID.
    ## For non-OCP (e.g., CNCF platforms such as AWS, GKE, etc), this parameter is optional. It is not supported on OCP and ROKS.
    sc_run_as_user:

    ## The platform to be deployed specified by the user.  Possible values are: OCP, ROKS and other.
    ## based on input from the user.
// highlight-start
    sc_deployment_platform: "other"
// highlight-end

    ## This is the deployment hostname suffix, this is optional and the default hostname suffix will be used as {meta.namespace}.router-canonicalhostname
    # sc_deployment_hostname_suffix: "{{ meta.namespace }}.<Required>"


    ## If the root certificate authority (CA) key of the external service is not signed by the operator root CA key, provide the TLS certificate of
    ## the external service to the component's truststore.
    trusted_certificate_list: []

    ## This is necessary if you want to use your own JDBC drivers and/or need to provide ICCSAP drivers.  If you are providing multiple JDBC drivers and ICCSAP drivers,
    ## all the files must be compressed in a single file.
    ## First you need to package your drivers into a compressed package in the format of "saplibs/drivers_files" and/or
    ## "jdbc/db2|oracle|postgresql|sqlserver/driver_files". For example, if you are providing your own DB2 and Oracle JDBC drivers and ICCSAP drivers, then the compressed
    ## file should have the following structure and content:
    ##   /jdbc/db2/db2jcc4.jar
    ##   /jdbc/db2/db2jcc_license_cu.jar
    ##   /jdbc/oracle/ojdbc8.jar
    ##   /saplibs/libicudata.so.50
    ##   /saplibs/...
    ## Then you need to put the compressed package on an anonymously accessible web server and provide the link here.
    ## The CR can handle .zip files using unzip as well as .tar, .tar.gz, .tar.bz2, .tar.xz. Does not handle .gz files, .bz2 files, .xz, or .zst files that do not contain a .tar archive.
    #sc_drivers_url:

    ## Enable/disable ECM (FNCM) / BAN initialization (e.g., creation of P8 domain, creation/configuration of object stores,
    ## creation/configuration of CSS servers, and initialization of Navigator (ICN)).  If the "initialize_configuration" section
    ## is defined with the required parameters in the CR (below) and sc_content_initialization is set to "true" (or the parameter doesn't exist), then the initialization will occur.
    ## However, if sc_content_initialization is set to "false", then the initialization will not occur (even with the "initialize_configuration" section defined)
    sc_content_initialization: true
    ## OR
    ## If you want to enable the initialize for a specific product for ECM (FNCM) / BAN, you will need to use
    ## these fields instead.  Otherwise, use the default sc_content_initialization: false
    # sc_content_initialization:
    #  cpe: false
    #  css: false
    #  ban: false


    ## Enable/disable the ECM (FNCM) / BAN verification (e.g., creation of test folder, creation of test document,
    ## execution of CBR search, and creation of Navigator demo repository and desktop).  If the "verify_configuration"
    ## section is defined in the CR, then that configuration will take precedence overriding this parameter.  Note that if you are upgrading or
    ## migrating, set this parameter to "false" since the env has been previously verified.
    sc_content_verification: false
    ## OR
    ## If you want to enable the verification for a specific product for ECM (FNCM) / BAN, you will need to use
    ## these fields instead.  Otherwise, use the default sc_content_verification: false
    # sc_content_verification:
    #  cpe: false
    #  css: false
    #  ban: false


   ## Provide the storage class names for the storage. It can be one storage class for all storage classes or can provide different one for each.
   ## Operator will use the provided storage classes to provision required PVC volumes.
    storage_configuration:
// highlight-start
      sc_slow_file_storage_classname: "efs-sc"
      sc_medium_file_storage_classname: "efs-sc"
      sc_fast_file_storage_classname: "efs-sc"
// highlight-end
    ## Uncomment out this section if you have OpenId Connect identity providers.
    #open_id_connect_providers:
    ## Set a provider name that will be used in your redirect URL.
    #- provider_name: ""
      ## Set a display name for the sign-in button in Navigator.
      #display_name: "Single Sign on"
      ## Enter your OIDC secret names for the ECM and Navigator Components.
      #client_oidc_secret:
         #nav: "" # Points to a secret with client_id and client_secret in that format.
         #cpe: "" # Points to a secret with client_id and client_secret in that format.
      #issuer_identifier: ""
      ## COMMON REQUIRED PROPERTIES AND VALUES
      ## If no value is set, the default value is taken. Uncomment or add new parameters as applicable for your provider.
      #response_type: "code"
      #scope: "openid email profile"
      #map_identity_to_registry_user: "false"
      #authn_session_disabled: "false"
      #inbound_propagation: "supported"
      #https_required: "true"
      #validation_method: "introspect"
      #disable_ltpa_cookie: "true"
      #signature_algorithm: "RS256"
      #user_identifier: "sub"
      #unique_user_identifier: "sub"
      #user_identity_to_create_subject: "sub"
      ### Uncomment out discovery_endpoint_url
      ##discovery_endpoint_url:
      ###
      ### Optional parameters
      ###
      ##authorization_endpoint_url: ""
      ##token_endpoint_url: ""
      ##validation_endpoint_url: ""
      ##trust_alias_name: "secret name you created"
      ##disables_iss_checking: "true"
      ##jwk_client_oidc_secret:
      ##  nav: "" # Points to a secret with client_id and client_secret in that format.
      ##  cpe: "" # Points to a secret with client_id and client_secret in that format.
      ##token_reuse: "true"

      ###
      ### User defined parameters.
      ### If you do not see a parameter that is needed for your OpenId Connect identity provider,
      ### you can use this section to define key value pairs separated by the delimiter `:`.
      ### If you want to change the default delimiter, add `DELIM=<NEW_DELIMITER>` in-front of your
      ### key value pair. Ex: 'DELIM=;myKey;myValue'.  In this example, the new delimiter is `;` and
      ### the key value pair is set to `myKey;myValue` instead of `myKey:myValue`.
      ####
      ##oidc_ud_param:
      ##- "DELIM=;revokeEndpointUrl;https://xxx/yyy"
      ##- "DELIM=;introspectEndpointUrl;https:/xxx/zzz"
      ##- 'DELIM=;myKey;myValue'
      ##- "myKey2:myValue2"
      ##- "myKey3:myValue3"

  ## The beginning section of LDAP configuration for FNCM
  ldap_configuration:
    ## The possible values are: "IBM Security Directory Server"
    ## or "Microsoft Active Directory"
    ## or "NetIQ eDirectory"
    ## or "Oracle Internet Directory"
    ## or "Oracle Directory Server Enterprise Edition"
    ## or "Oracle Unified Directory"
    ## or "CA eTrust"
// highlight-start
    lc_selected_ldap_type: "Custom"
// highlight-end
    ## The lc_ldap_precheck parameter is used to enable or disable LDAP connection check.
    ## If set to "true", then LDAP connection check will be enabled.
    ## if set to "false", then LDAP connection check will not be enabled.
    lc_ldap_precheck: true

    ## The name of the LDAP server to connect
// highlight-start
    lc_ldap_server: "10.100.217.46"
// highlight-end
    ## The port of the LDAP server to connect.  Some possible values are: 389, 636, etc.
    lc_ldap_port: "389"

    ## The LDAP bind secret for LDAP authentication.  The secret is expected to have ldapUsername and ldapPassword keys.  Refer to Knowledge Center for more info.
    lc_bind_secret: ldap-bind-secret

    ## The LDAP base DN.  For example, "dc=example,dc=com", "dc=abc,dc=com", etc
// highlight-start
    lc_ldap_base_dn: "dc=filenet,dc=internal"
// highlight-end

    ## Enable SSL/TLS for LDAP communication. Refer to Knowledge Center for more info.
    lc_ldap_ssl_enabled: false

    ## The name of the secret that contains the LDAP SSL/TLS certificate.
    lc_ldap_ssl_secret_name: "ldap"

    ## The LDAP user name attribute. Semicolon-separated list that must include the first RDN user distinguished names. One possible value is "*:uid" for TDS and "user:sAMAccountName" for AD. Refer to Knowledge Center for more info.
    lc_ldap_user_name_attribute: "*:uid"

    ## The LDAP user display name attribute. One possible value is "cn" for TDS and "sAMAccountName" for AD. Refer to Knowledge Center for more info.
    lc_ldap_user_display_name_attr: "cn"

    ## The LDAP group base DN.  For example, "dc=example,dc=com", "dc=abc,dc=com", etc
// highlight-next-line
    lc_ldap_group_base_dn: "ou=Groups,dc=filenet,dc=internal"

    ## The LDAP group name attribute.  One possible value is "*:cn" for TDS and "*:cn" for AD. Refer to Knowledge Center for more info.
    lc_ldap_group_name_attribute: "*:cn"

    ## The LDAP group display name attribute.  One possible value for both TDS and AD is "cn". Refer to Knowledge Center for more info.
    lc_ldap_group_display_name_attr: "cn"

    ## The LDAP group membership search filter string.  One possible value is "(|(&(objectclass=groupofnames)(member={0}))(&(objectclass=groupofuniquenames)(uniquemember={0})))" for TDS and AD
// highlight-start
    lc_ldap_group_membership_search_filter: "(|(&(objectclass='groupOfNames')(member={0}))(&(objectclass=groupofuniquenames)(uniquemember={0})))')"
// highlight-end
    ## The LDAP group membership ID map.  One possible value is "groupofnames:member" for TDS and "memberOf:member" for AD.
    lc_ldap_group_member_id_map: "groupofnames:member"

// highlight-start
    custom:
      lc_user_filter: "(&(uid=%v)(objectclass=inetOrgPerson))"
      lc_group_filter: "(&(cn=%v)(|(objectclass=groupOfNames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"
// highlight-end
    ## Uncomment the necessary section (depending on if you are using Active Directory (ad) or Tivoli Directory Service (tds)) accordingly.
    ## NetIQ eDirectory (ed)
    ## Oracle (oracle) - OID, OUD and ODSEE
    ## CA eTrust (caet)
    #ad:
    #  lc_ad_gc_host: "<Required>"
    #  lc_ad_gc_port: "<Required>"
    #  lc_user_filter: "(&(samAccountName=%v)(objectClass=user))"
    #  lc_group_filter: "(&(samAccountName=%v)(objectclass=group))"
    #tds:
    #  lc_user_filter: "(&(cn=%v)(objectclass=person))"
    #  lc_group_filter: "(&(cn=%v)(|(objectclass=groupofnames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"
    #ed:
    #  lc_user_filter: "(&(objectclass=Person)(cn=%v))"
    #  lc_group_filter: "(&(objectclass=groupOfNames)(cn=%v))"
    #oracle:
    #  lc_user_filter: "(&(objectClass=person)(cn=%v))"
    #  lc_group_filter:  "(&(objectClass=group)(cn=%v))"
    #caet:
    #  lc_user_filter: "(&(objectClass=person)(cn=%v))"
    #  lc_group_filter:  "(&(objectClass=group)(cn=%v))"


  ## The beginning section of multi ldap configuration for FNCM
  #ldap_configuration_<id_name>:
    #lc_ldap_id: <id_name>
    ## The possible values are: "IBM Security Directory Server"
    ## or "Microsoft Active Directory"
    ## or "NetIQ eDirectory"
    ## or "Oracle Internet Directory"
    ## or "Oracle Directory Server Enterprise Edition"
    ## or "Oracle Unified Directory"
    ## or "CA eTrust"
    #lc_selected_ldap_type: "<Required>"

    ## The lc_ldap_precheck parameter is used to enable or disable LDAP connection check.
    ## If set to "true", then LDAP connection check will be enabled.
    ## if set to "false", then LDAP connection check will not be enabled.
    #lc_ldap_precheck: true

    ## The name of the LDAP server to connect
    #lc_ldap_server: "<Required>"

    ## The port of the LDAP server to connect.  Some possible values are: 389, 636, etc.
    #lc_ldap_port: "<Required>"

    ## The LDAP base DN.  For example, "dc=example,dc=com", "dc=abc,dc=com", etc
    #lc_ldap_base_dn: "<Required>"

    ## Enable SSL/TLS for LDAP communication. Refer to Knowledge Center for more info.
    #lc_ldap_ssl_enabled: true

    ## The name of the secret that contains the LDAP SSL/TLS certificate.
    #lc_ldap_ssl_secret_name: "<Required>"

    ## The LDAP user name attribute.  One possible value is "*:cn" for TDS and "user:sAMAccountName" for AD. Refer to Knowledge Center for more info.
    #lc_ldap_user_name_attribute: "<Required>"

    ## The LDAP user display name attribute. One possible value is "cn" for TDS and "sAMAccountName" for AD. Refer to Knowledge Center for more info.
    #lc_ldap_user_display_name_attr: "<Required>"

    ## The LDAP group base DN.  For example, "dc=example,dc=com", "dc=abc,dc=com", etc
    #lc_ldap_group_base_dn: "<Required>"

    ## The LDAP group name attribute.  One possible value is "*:cn" for TDS and "*:cn" for AD. Refer to Knowledge Center for more info.
    #lc_ldap_group_name_attribute: "*:cn"

    ## The LDAP group display name attribute.  One possible value for both TDS and AD is "cn". Refer to Knowledge Center for more info.
    #lc_ldap_group_display_name_attr: "cn"

    ## The LDAP group membership search filter string.  One possible value is "(|(&(objectclass=groupofnames)(member={0}))(&(objectclass=groupofuniquenames)(uniquemember={0})))" for TDS and AD
    #lc_ldap_group_membership_search_filter: "<Required>"

    ## The LDAP group membership ID map.  One possible value is "groupofnames:member" for TDS and "memberOf:member" for AD.
    #lc_ldap_group_member_id_map: "<Required>"

    ## Uncomment the necessary section (depending on if you are using Active Directory (ad) or Tivoli Directory Service (tds)) accordingly.
    ## NetIQ eDirectory (ed)
    ## Oracle (oracle) - OID, OUD and ODSEE
    ## CA eTrust (caet)
    #ad:
    #  lc_ad_gc_host: "<Required>"
    #  lc_ad_gc_port: "<Required>"
    #  lc_user_filter: "(&(sAMAccountName=%v)(objectcategory=user))"
    #  lc_group_filter: "(&(cn=%v)(objectcategory=group))"
    #tds:
    #  lc_user_filter: "(&(cn=%v)(objectclass=person))"
    #  lc_group_filter: "(&(cn=%v)(|(objectclass=groupofnames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"
    #ed:
    #  lc_user_filter: "(&(objectclass=Person)(cn=%v))"
    #  lc_group_filter: "(&(objectclass=groupOfNames)(cn=%v))"
    #oracle:
    #  lc_user_filter: "(&(objectClass=person)(cn=%v))"
    #  lc_group_filter:  "(&(objectClass=group)(cn=%v))"
    #caet:
    #  lc_user_filter: "(&(objectClass=person)(cn=%v))"
    #  lc_group_filter:  "(&(objectClass=group)(cn=%v))"

  ## The beginning section of external LDAP configuration for FNCM if External Share is deployed
  #ext_ldap_configuration:
    ## The possible values are: "IBM Security Directory Server"
    ## or "Microsoft Active Directory"
    ## or "NetIQ eDirectory"
    ## or "Oracle Internet Directory"
    ## or "Oracle Directory Server Enterprise Edition"
    ## or "Oracle Unified Directory"
    ## or "CA eTrust"
    #lc_selected_ldap_type: "<Required>"

    ## The lc_ldap_precheck parameter is used to enable or disable LDAP connection check.
    ## If set to "true", then LDAP connection check will be enabled.
    ## if set to "false", then LDAP connection check will not be enabled.
    #lc_ldap_precheck: true

    ## The name of the LDAP server to connect
    #lc_ldap_server: "<Required>"

    ## The port of the LDAP server to connect.  Some possible values are: 389, 636, etc.
    #lc_ldap_port: "<Required>"

    ## The LDAP bind secret for LDAP authentication.
    #lc_bind_secret: ibm-ext-ldap-secret

    ## The LDAP base DN.  For example, "dc=example,dc=com", "dc=abc,dc=com", etc
    #lc_ldap_base_dn: "<Required>"

    ## Enable SSL/TLS for LDAP communication. Refer to Knowledge Center for more info.
    #lc_ldap_ssl_enabled: true

    ## The name of the secret that contains the LDAP SSL/TLS certificate.
    #lc_ldap_ssl_secret_name: "<Required>"

    ## The LDAP user name attribute.  One possible value is "*:cn" for TDS and "user:sAMAccountName" for AD. Refer to Knowledge Center for more info.
    #lc_ldap_user_name_attribute: "<Required>"

    ## The LDAP user display name attribute. One possible value is "cn" for TDS and "sAMAccountName" for AD. Refer to Knowledge Center for more info.
    #lc_ldap_user_display_name_attr: "<Required>"

    ## The LDAP group base DN.  For example, "dc=example,dc=com", "dc=abc,dc=com", etc
    #lc_ldap_group_base_dn: "<Required>"

    ## The LDAP group name attribute.  One possible value is "*:cn" for TDS and "*:cn" for AD. Refer to Knowledge Center for more info.
    #lc_ldap_group_name_attribute: "*:cn"

    ## The LDAP group display name attribute.  One possible value for both TDS and AD is "cn". Refer to Knowledge Center for more info.
    #lc_ldap_group_display_name_attr: "cn"

    ## The LDAP group membership search filter string.  One possible value is "(|(&(objectclass=groupofnames)(member={0}))(&(objectclass=groupofuniquenames)(uniquemember={0})))" for TDS and AD
    #lc_ldap_group_membership_search_filter: "<Required>"

    ## The LDAP group membership ID map.  One possible value is "groupofnames:member" for TDS and "memberOf:member" for AD.
    #lc_ldap_group_member_id_map: "<Required>"

    ## Uncomment the necessary section (depending on if you are using Active Directory (ad) or Tivoli Directory Service (tds)) accordingly.
    ## NetIQ eDirectory (ed)
    ## Oracle (oracle) - OID, OUD and ODSEE
    ## CA eTrust (caet)
    #ad:
    #  lc_ad_gc_host: "<Required>"
    #  lc_ad_gc_port: "<Required>"
    #  lc_user_filter: "(&(sAMAccountName=%v)(objectcategory=user))"
    #  lc_group_filter: "(&(cn=%v)(objectcategory=group))"
    #tds:
    #  lc_user_filter: "(&(cn=%v)(objectclass=person))"
    #  lc_group_filter: "(&(cn=%v)(|(objectclass=groupofnames)(objectclass=groupofuniquenames)(objectclass=groupofurls)))"
    #ed:
    #  lc_user_filter: "(&(objectclass=Person)(cn=%v))"
    #  lc_group_filter: "(&(objectclass=groupOfNames)(cn=%v))"
    #oracle:
    #  lc_user_filter: "(&(objectClass=person)(cn=%v))"
    #  lc_group_filter:  "(&(objectClass=group)(cn=%v))"
    #caet:
    #  lc_user_filter: "(&(objectClass=person)(cn=%v))"
    #  lc_group_filter:  "(&(objectClass=group)(cn=%v))"

  ## The beginning section of database configuration for FNCM
  datasource_configuration:
    ## The dc_ssl_enabled parameter is used to support database connection over SSL for DB2/Oracle/SQLServer/PostgrSQL.
    dc_ssl_enabled: false
    ## The database_precheck parameter is used to enable or disable CPE/Navigator database connection check.
    ## If set to "true", then CPE/Navigator database connection check will be enabled.
    ## if set to "false", then CPE/Navigator database connection check will not be enabled.
   # database_precheck: true
    ## The database configuration for the GCD datasource for CPE
    dc_gcd_datasource:
      ## Provide the database type from your infrastructure.  The possible values are "db2" or "db2HADR" or "oracle" or "sqlserver" or "postgresql".
// highlight-next-line
      dc_database_type: "postgresql"
      ## The GCD non-XA datasource name.  The default value is "FNGCDDS".
      dc_common_gcd_datasource_name: "FNGCDDS"
      ## The GCD XA datasource name. The default value is "FNGCDDSXA".
      dc_common_gcd_xa_datasource_name: "FNGCDDSXA"
      ## Provide the database server name or IP address of the database server.
// highlight-next-line
      database_servername: "10.100.80.28"
      ## Provide the name of the database for the GCD for CPE.  For example: "GCDDB"
// highlight-next-line
      database_name: "gcddb"
      ## Provide the database server port.  For Db2, the default is "50000".  For Oracle, the default is "1521"
// highlight-next-line
      database_port: "5432"
      ## The name of the secret that contains the DB2/Oracle/PostgreSQL/SQLServer SSL certificate.
      database_ssl_secret_name: "<Required>"
      ## If the database type is Oracle, provide the Oracle DB connection string.  For example, "jdbc:oracle:thin:@//<oracle_server>:1521/orcl"
      dc_oracle_gcd_jdbc_url: "<Required>"
      ## Provide the validation timeout.  If not preference, keep the default value.
      dc_hadr_validation_timeout: 15
      ######################################################################################
      ## If the database type is "Db2HADR", then complete the rest of the parameters below.
      ## Otherwise, remove or comment out the rest of the parameters below.
      ######################################################################################.
      dc_hadr_standby_servername: "<Required>"
      ## Provide the standby database server port.  For Db2, the default is "50000".
      dc_hadr_standby_port: "<Required>"
      ## Provide the retry internal.  If not preference, keep the default value.
      dc_hadr_retry_interval_for_client_reroute: 15
      ## Provide the max # of retries.  If not preference, keep the default value.
      dc_hadr_max_retries_for_client_reroute: 3
    ## The database configuration for the object store 1 (OS1) datasource for CPE
    dc_os_datasources:
      ## Provide the database type from your infrastructure.  The possible values are "db2" or "db2HADR" or "oracle" or "sqlserver" or "postgresql".  This should be the same as the
      ## GCD configuration above.
    - dc_database_type: "postgresql"
      ## Provide the object store label for the object store.  The default value is "os" or not defined.
      ## This label must match the OS secret you define in ibm-fncm-secret.
      ## For example, if you define dc_os_label: "abc", then your OS secret must be defined as:
      ## --from-literal=abcDBUsername="<your os db username>" --from-literal=abcDBPassword="<your os db password>"
      ## If you don't define dc_os_label, then your secret will be defined as:
      ## --from-literal=osDBUsername="<your os db username>" --from-literal=osDBPassword="<your os db password>".
      ## If you have multiple object stores, then you need to define multiple datasource sections starting
      ## at "dc_database_type" element.
      ## If all the object store databases share the same username and password, then dc_os_label value should be the same
      ## in all the datasource sections.
// highlight-next-line
      dc_os_label: "os"
      ## The OS1 non-XA datasource name.  The default value is "FNOS1DS".
      dc_common_os_datasource_name: "FNOS1DS"
      ## The OS1 XA datasource name.  The default value is "FNOS1DSXA".
      dc_common_os_xa_datasource_name: "FNOS1DSXA"
      ## Provide the database server name or IP address of the database server.  This should be the same as the
      ## GCD configuration above.
// highlight-start
      database_servername: "10.100.80.28"
      ## Provide the name of the database for the object store 1 for CPE.  For example: "OS1DB"
      database_name: "osdb"
// highlight-end
      ## Provide the database server port.  For Db2, the default is "50000".  For Oracle, the default is "1521"
// highlight-next-line
      database_port: "5432"
      ## The name of the secret that contains the DB2/Oracle/PostgreSQL/SQLServer SSL certificate.
      database_ssl_secret_name: "<Required>"
      ## If the database type is Oracle, provide the Oracle DB connection string.  For example, "jdbc:oracle:thin:@//<oracle_server>:1521/orcl"
      dc_oracle_os_jdbc_url: "<Required>"
      ## Provide the validation timeout.  If not preference, keep the default value.
      dc_hadr_validation_timeout: 15
      ######################################################################################
      ## If the database type is "Db2HADR", then complete the rest of the parameters below.
      ## Otherwise, remove or comment out the rest of the parameters below.
      ######################################################################################
      dc_hadr_standby_servername: "<Required>"
      ## Provide the standby database server port.  For Db2, the default is "50000".
      dc_hadr_standby_port: "<Required>"
      ## Provide the retry internal.  If not preference, keep the default value.
      dc_hadr_retry_interval_for_client_reroute: 15
      ## Provide the max # of retries.  If not preference, keep the default value.
      dc_hadr_max_retries_for_client_reroute: 3
    ## The database configuration for ICN (Navigator) - aka BAN (Business Automation Navigator)
    dc_icn_datasource:
      ## Provide the database type from your infrastructure.  The possible values are "db2" or "db2HADR" or "oracle" or "sqlserver" or "postgresql".  This should be the same as the
      ## GCD and object store configuration above.
      dc_database_type: "postgresql"
      ## Provide the ICN datasource name.  The default value is "ECMClientDS".
      dc_common_icn_datasource_name: "ECMClientDS"
// highlight-start
      database_servername: "10.100.80.28"
// highlight-end
      ## Provide the database server port.  For Db2, the default is "50000".  For Oracle, the default is "1521"
      database_port: "5432"
      ## Provide the name of the database for ICN (Navigator).  For example: "ICNDB"
// highlight-next-line
      database_name: "icndb"
      ## The name of the secret that contains the DB2/Oracle/PostgreSQL/SQLServer SSL certificate.
      database_ssl_secret_name: "<Required>"
      ## If the database type is Oracle, provide the Oracle DB connection string.  For example, "jdbc:oracle:thin:@//<oracle_server>:1521/orcl"
      dc_oracle_icn_jdbc_url: "<Required>"
      ## Provide the validation timeout.  If not preference, keep the default value.
      dc_hadr_validation_timeout: 15
      ######################################################################################
      ## If the database type is "Db2HADR", then complete the rest of the parameters below.
      ## Otherwise, remove or comment out the rest of the parameters below.
      ######################################################################################
      dc_hadr_standby_servername: "<Required>"
      ## Provide the standby database server port.  For Db2, the default is "50000".
      dc_hadr_standby_port: "<Required>"
      ## Provide the retry internal.  If not preference, keep the default value.
      dc_hadr_retry_interval_for_client_reroute: 15
      ## Provide the max # of retries.  If not preference, keep the default value.
      dc_hadr_max_retries_for_client_reroute: 3
      ## Connection manager for a data source.
#  ########################################################################
#  ######## IBM FileNet Content Manager Initialization configuration ######
#  ########################################################################
#  ## This section is required when initializing the P8 domain and object store
#  ## Please fill out the "<Required>" parameters
#  initialize_configuration:
#    ic_ldap_creation:
#      ic_ldap_admin_user_name:
#        - "<Required>" # user name for P8 domain admin, for example, "CEAdmin".  This parameter accepts a list of values.
#      ic_ldap_admins_groups_name:
#        - "<Required>" # group name for P8 domain admin, for example, "P8Administrators".  This parameter accepts a list of values.
#    ic_obj_store_creation:
#      object_stores:
#        - oc_cpe_obj_store_display_name: "OS01" # Required display name of the object store, for example, "OS01"
#          oc_cpe_obj_store_symb_name: "OS01" # Required symbolic name of the object store, for example, "OS01"
#          oc_cpe_obj_store_conn:
#            name: "OS01_dbconnection"
#            dc_os_datasource_name: "FNOS1DS" # This value must match with the non-XA datasource name in the "datasource_configuration" above.
#            dc_os_xa_datasource_name: "FNOS1DSXA" # This value must match with the XA datasource name in the "datasource_configuration" above.
#          oc_cpe_obj_store_admin_user_groups:
#            - "<Required>" # user name and group name for object store admin, for example, "CEAdmin" or "P8Administrators".  This parameter accepts a list of values.
#
#  ########################################################################
#  ######## IBM FileNet Content Manager Verification configuration ######
#  ########################################################################
#  ## After the initialization process (see section above), the verification process will take place.
#  ## The verification process ensures that the FNCM and BAN components are functioning correctly.  The verification
#  ## process includes creation of a CPE folder, a CPE document, a CBR search, verifying the workflow configuration,
#  ## and validation of the ICN desktop.
#  verify_configuration:
#    vc_cpe_verification:
#      vc_cpe_folder:
#        - folder_cpe_obj_store_name: "OS01"
#          folder_cpe_folder_path: "/TESTFOLDER"
#      vc_cpe_document:
#        - doc_cpe_obj_store_name: "OS01"
#          doc_cpe_folder_name: "/TESTFOLDER"
#          doc_cpe_doc_title: "test_title"
#          DOC_CPE_class_name: "Document"
#          doc_cpe_doc_content: "This is a simple document test"
#          doc_cpe_doc_content_name: "doc_content_name"
#      vc_cpe_cbr:
#        - cbr_cpe_obj_store_name: "OS01"
#          cbr_cpe_class_name: "Document"
#          cbr_cpe_search_string: "is a simple"
#      vc_cpe_workflow:
#        - workflow_cpe_enabled: false
#          workflow_cpe_connection_point: "pe_conn_os1"
#    vc_icn_verification:
#      - vc_icn_repository: "OS01repo"
#        vc_icn_desktop_id: "desktop1"

```

Once the CR file has been appropriately modified, it is applied to the cluster:

```
kubectl apply -f ibm_fncm_cr_production.yaml
```
