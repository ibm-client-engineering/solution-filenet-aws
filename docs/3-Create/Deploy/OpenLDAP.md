---
id: solution-deploy-openldap
sidebar_position: 1
title: OpenLDAP
---
## Deploy OpenLDAP

Let's create a namespace for openldap (This is optional. For the rest of this, we'll just stick openldap into our filenet namespace)

```tsx
kubectl create namespace filenet-openldap
kubectl label namespace filenet-openldap app=filenet-openldap
```

Set our context to the new namespace (only if you created a separate namespace to run openldap in)

```tsx
kubectl config set-context --current --namespace=filenet-openldap
```

### Create the config maps
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

```tsx
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

```tsx
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

```tsx
kubectl apply -f openldap-env-configmap.yaml
```

### Create the LDAP Secret

And finally create a secret for the LDAP_ADMIN_PASSWORD. In this example we are setting the default admin password to `p@ssw0rd`

`openldap-admin-secret.yaml`

```yaml
kind: Secret
apiVersion: v1
metadata:
  name: openldap
  labels:
    app: filenet-openldap
stringData:
  LDAP_ADMIN_PASSWORD: p@ssw0rd
```

```tsx
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

### Create the deployment

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

```tsx
kubectl apply -f openldap-deploy.yaml
```

### Create a service for openldap

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

```tsx
kubectl apply -f openldap-service.yaml
```

### Verifying installation
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

```tsx
ldapadd -x -D "cn=admin,dc=filenet,dc=internal" -w p@ssw0rd -H ldapi:/// -f /ldifs/01-default-users.ldif
```
:::

## Extra Tasks
### Adding more users

In order to add extra users, you must update the openldap-ldif. This is best done by updating our openldap-ldif-configmap.yaml from above.

Additional users are highlighted below:

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

// highlight-start
    dn: uid=user1,ou=Users,dc=filenet,dc=internal
    objectClass: inetOrgPerson
    objectClass: top
    objectClass: sds
    cn: user1
    sn: user1
    uid: user1
    mail: user1@cp.internal
    userpassword: Password
    ibm-entryuuid: 30183bb1-1013-5d23-9ae2-f94816bou812

    dn: uid=user2,ou=Users,dc=filenet,dc=internal
    objectClass: inetOrgPerson
    objectClass: top
    objectClass: sds
    cn: user2
    sn: user2
    uid: user2
    mail: user2@cp.internal
    userpassword: Password
    ibm-entryuuid: 30184bb1-1014-6d23-9ae2-f94816bou813
// highlight-end

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
:::note
`ibm-entryuuid`` needs to be unique per user. There’s no mechanism for generating that uuid at the moment… so I made them up.
:::

Apply the updated ldif to the cluster

```tsx
kubectl apply -f openldap-ldif-configmap.yaml
```

Now scale openldap deployment down and back up.

```tsx
kubectl scale deploy openldap-deploy —replicas=0
kubectl scale deploy openldap-deploy —replicas=1
```

You should see the following in the pod logs:

```tsx
15:47:56.45 INFO  ==> Loading custom LDIF files...
 15:47:56.45 WARN  ==> Ignoring LDAP_USERS, LDAP_PASSWORDS, LDAP_USER_DC and LDAP_GROUP environment variables...
65047cac.1bb88f36 0x7f36ddeb1700 conn=1000 fd=12 ACCEPT from PATH=/opt/bitnami/openldap/var/run/ldapi (PATH=/opt/bitnami/openldap/var/run/ldapi)
65047cac.1bbaca3f 0x7f36ddeb1700 conn=1000 op=0 BIND dn="cn=admin,dc=filenet,dc=internal" method=128
65047cac.1bbb76dd 0x7f36ddeb1700 conn=1000 op=0 BIND dn="cn=admin,dc=filenet,dc=internal" mech=SIMPLE bind_ssf=0 ssf=71
65047cac.1bbd7f8f 0x7f36ddeb1700 conn=1000 op=0 RESULT tag=97 err=0 qtime=0.000013 etime=0.000221 text=
65047cac.1bbe0c82 0x7f36dd6b0700 connection_input: conn=1000 deferring operation: binding
65047cac.1bbfcf39 0x7f36ddeb1700 conn=1000 op=1 ADD dn="dc=filenet,dc=internal"
65047cac.1be17747 0x7f36ddeb1700 conn=1000 op=1 RESULT tag=105 err=0 qtime=0.000107 etime=0.002325 text=
65047cac.1be350f4 0x7f36dd6b0700 conn=1000 op=2 ADD dn="ou=Users,dc=filenet,dc=internal"
65047cac.1bfad443 0x7f36dd6b0700 conn=1000 op=2 RESULT tag=105 err=0 qtime=0.000012 etime=0.001574 text=
65047cac.1bfbfc3a 0x7f36dd6b0700 conn=1000 op=3 ADD dn="ou=Groups,dc=filenet,dc=internal"
65047cac.1c15023f 0x7f36dd6b0700 conn=1000 op=3 RESULT tag=105 err=0 qtime=0.000012 etime=0.001661 text=
65047cac.1c166e75 0x7f36ddeb1700 conn=1000 op=4 ADD dn="uid=cpadmin,ou=Users,dc=filenet,dc=internal"
65047cac.1c2ebc18 0x7f36ddeb1700 conn=1000 op=4 RESULT tag=105 err=0 qtime=0.000014 etime=0.001624 text=
65047cac.1c3019bb 0x7f36dd6b0700 conn=1000 op=5 ADD dn="uid=cpuser,ou=Users,dc=filenet,dc=internal"
65047cac.1c4aa25f 0x7f36dd6b0700 conn=1000 op=5 RESULT tag=105 err=0 qtime=0.000014 etime=0.001773 text=
65047cac.1c4c41e2 0x7f36ddeb1700 conn=1000 op=6 ADD dn="uid=user1,ou=Users,dc=filenet,dc=internal"
65047cac.1c6b50ba 0x7f36ddeb1700 conn=1000 op=6 RESULT tag=105 err=0 qtime=0.000012 etime=0.002063 text=
65047cac.1c6ccfd1 0x7f36dd6b0700 conn=1000 op=7 ADD dn="uid=user2,ou=Users,dc=filenet,dc=internal"
65047cac.1c88b8e6 0x7f36dd6b0700 conn=1000 op=7 RESULT tag=105 err=0 qtime=0.000012 etime=0.001858 text=
65047cac.1c8a9710 0x7f36dd6b0700 conn=1000 op=8 ADD dn="cn=cpadmins,ou=Groups,dc=filenet,dc=internal"
65047cac.1c9e27d3 0x7f36dd6b0700 conn=1000 op=8 RESULT tag=105 err=0 qtime=0.000036 etime=0.001332 text=
65047cac.1c9faeb8 0x7f36ddeb1700 conn=1000 op=9 ADD dn="cn=cpusers,ou=Groups,dc=filenet,dc=internal"
65047cac.1cb3a85f 0x7f36ddeb1700 conn=1000 op=9 RESULT tag=105 err=0 qtime=0.000012 etime=0.001335 text=
65047cac.1cb4e3b8 0x7f36dd6b0700 conn=1000 op=10 UNBIND
65047cac.1cb58551 0x7f36dd6b0700 conn=1000 fd=12 closed
adding new entry "dc=filenet,dc=internal"

adding new entry "ou=Users,dc=filenet,dc=internal"

adding new entry "ou=Groups,dc=filenet,dc=internal"

adding new entry "uid=cpadmin,ou=Users,dc=filenet,dc=internal"

adding new entry "uid=cpuser,ou=Users,dc=filenet,dc=internal"

// highlight-next-line
adding new entry "uid=user1,ou=Users,dc=filenet,dc=internal"

// highlight-next-line
adding new entry "uid=user2,ou=Users,dc=filenet,dc=internal"

adding new entry "cn=cpadmins,ou=Groups,dc=filenet,dc=internal"

adding new entry "cn=cpusers,ou=Groups,dc=filenet,dc=internal"

65047cac.1d163005 0x7f36de6b2700 daemon: shutdown requested and initiated.
65047cac.1d197f74 0x7f36de6b2700 slapd shutdown: waiting for 0 operations/tasks to finish
65047cac.1d22105d 0x7f371ec53740 slapd stopped.
 15:47:57.50 INFO  ==> ** LDAP setup finished! **

 15:47:57.52 INFO  ==> ** Starting slapd **
65047cad.1fc3a637 0x7ff24732d740 @(#) $OpenLDAP: slapd 2.6.6 (Aug 18 2023 23:33:58) $
        @a67812f7d14b:/bitnami/blacksmith-sandox/openldap-2.6.6/servers/slapd
65047cad.2048d01e 0x7ff24732d740 slapd starting
```