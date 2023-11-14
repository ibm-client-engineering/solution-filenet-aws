---
id: solution-deploy-postgres
sidebar_position: 2
title: Postgresql
---

## Deploy Postgres

### Creating configmaps
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
### Create PVCs

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
### Create deployment

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
            // highlight-start
            - max_prepared_transactions=500
            // highlight-end
            - '-c'
            // highlight-start
            - max_connections=500
            // highlight-end
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

### Create the service

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

### Apply Yaml files to cluster
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

### Create initial databases and object store

Retrieve the postgres pod id with this command:
```tsx
kubectl get pods | grep postgres

// highlight-next-line
postgres-759fd876ff-d5fxd                     1/1     Running   0          6d10h
```

#### Prepare database table spaces and ceuser
Connect to the postgres pod and create the tablespace directories for all databases you plan to create. 

```tsx
kubectl exec -it postgres-759fd876ff-d5fxd -- mkdir /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb
kubectl exec -it postgres-759fd876ff-d5fxd -- chmod 700 /pgsqldata/osdb /pgsqldata/gcddb /pgsqldata/icndb
```

Connect to `defaultdb`. Our password will be `p@ssw0rd`.

```tsx
kubectl exec -it postgres-759fd876ff-d5fxd -- psql -h localhost -U admin --password -p 5432 defaultdb
```

Create the `ceuser`

```tsx
create role ceuser login password 'p@ssw0rd';
```

#### Create the databases

For this deployment, we will be creating the following databases:
- `gcddb`
- `icndb`

And one single object store for now

- `osdb`

At this point you should still be connected to `defaultdb`. 

Create the GCD database. When you run the `\connect` command, it will query you for the password. It will still be `p@ssw0rd`.

With these commands, we will be creating a new database, setting the owner to `ceuser`, locking it down from public and then creating the tablespace for that database to use the directories we created above. These tablespaces will live on a separate PVC.

```tsx
CREATE DATABASE gcddb OWNER ceuser TEMPLATE template0 ENCODING UTF8;
GRANT ALL ON DATABASE gcddb TO ceuser;
REVOKE CONNECT ON DATABASE gcddb FROM public;
// highlight-next-line
\connect gcddb
CREATE TABLESPACE gcddb_tbs OWNER ceuser LOCATION '/pgsqldata/gcddb';
GRANT CREATE ON TABLESPACE gcddb_tbs TO ceuser;
```

Create the ICN database. When you run the `\connect` command, it will query you for the password. It will still be `p@ssw0rd`.

```tsx
CREATE DATABASE icndb OWNER ceuser TEMPLATE template0 ENCODING UTF8;
GRANT ALL ON DATABASE icndb TO ceuser;
REVOKE CONNECT ON DATABASE gcddb FROM public;
// highlight-next-line
\connect icndb
CREATE TABLESPACE icndb_tbs OWNER ceuser LOCATION '/pgsqldata/icndb';
GRANT CREATE ON TABLESPACE icndb_tbs TO ceuser;
```

Create the Object Store database. When you run the `\connect` command, it will query you for the password. It will still be `p@ssw0rd`.

```tsx
CREATE DATABASE osdb OWNER ceuser TEMPLATE template0 ENCODING UTF8 ;
GRANT ALL ON DATABASE osdb TO ceuser;
REVOKE CONNECT ON DATABASE osdb FROM public;
// highlight-next-line
\connect osdb
CREATE TABLESPACE osdb_tbs OWNER ceuser LOCATION '/pgsqldata/osdb';
GRANT CREATE ON TABLESPACE osdb_tbs TO ceuser;
```