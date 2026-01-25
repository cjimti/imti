---
draft: false
layout: post
title: "Apache NiFi: Production Kubernetes Deployment"
subtitle: "Apache NiFi Part 1"
date: 2022-07-30
author: "Craig Johnston"
URL: "nifi-kubernetes-deployment/"
image: "/img/post/server-room.jpg"
twitter_image: "/img/post/server-room_876_438.jpg"
tags:
- Apache NiFi
- Kubernetes
- Data Engineering
- DevOps
series:
- Apache NiFi
---

This article covers deploying **Apache NiFi** on Kubernetes for production workloads: a clustered deployment with ZooKeeper, persistent storage, and proper ingress handling.

<!--more-->

{{< toc >}}
{{< content-ad >}}

## Architecture Overview

A production NiFi cluster on Kubernetes consists of:

- **NiFi StatefulSet**: 3+ nodes for high availability
- **ZooKeeper Ensemble**: Cluster coordination (3 nodes)
- **Persistent Volumes**: Flow storage and repositories
- **Ingress Controller**: External access with TLS

## Namespace

Start with a dedicated namespace:

```yaml
# 00-namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: nifi
  labels:
    app: nifi
```

## ConfigMap

NiFi configuration stored in a ConfigMap:

```yaml
# 20-configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nifi-config
  namespace: nifi
data:
  nifi.properties: |
    nifi.flow.configuration.file=./conf/flow.xml.gz
    nifi.flow.configuration.archive.enabled=true
    nifi.flow.configuration.archive.dir=./conf/archive/
    nifi.flow.configuration.archive.max.count=30

    nifi.web.http.host=
    nifi.web.http.port=8080

    nifi.cluster.is.node=true
    nifi.cluster.node.address=${HOSTNAME}.nifi-headless.nifi.svc.cluster.local
    nifi.cluster.node.protocol.port=11443

    nifi.zookeeper.connect.string=zk-0.zk-headless.nifi.svc.cluster.local:2181,zk-1.zk-headless.nifi.svc.cluster.local:2181,zk-2.zk-headless.nifi.svc.cluster.local:2181
    nifi.zookeeper.root.node=/nifi

    nifi.state.management.embedded.zookeeper.start=false

    nifi.sensitive.props.key=${NIFI_SENSITIVE_PROPS_KEY}

  bootstrap.conf: |
    java.arg.2=-Xms2g
    java.arg.3=-Xmx2g
    java.arg.4=-Djava.net.preferIPv4Stack=true

  state-management.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <stateManagement>
      <local-provider>
        <id>local-provider</id>
        <class>org.apache.nifi.controller.state.providers.local.WriteAheadLocalStateProvider</class>
        <property name="Directory">./state/local</property>
      </local-provider>
      <cluster-provider>
        <id>zk-provider</id>
        <class>org.apache.nifi.controller.state.providers.zookeeper.ZooKeeperStateProvider</class>
        <property name="Connect String">zk-0.zk-headless.nifi.svc.cluster.local:2181,zk-1.zk-headless.nifi.svc.cluster.local:2181,zk-2.zk-headless.nifi.svc.cluster.local:2181</property>
        <property name="Root Node">/nifi/components</property>
        <property name="Session Timeout">10 seconds</property>
        <property name="Access Control">Open</property>
      </cluster-provider>
    </stateManagement>
```

## ZooKeeper

Deploy ZooKeeper for cluster coordination. First, the headless service:

```yaml
# zookeeper/10-service-headless.yml
apiVersion: v1
kind: Service
metadata:
  name: zk-headless
  namespace: nifi
  labels:
    app: zk
spec:
  ports:
  - port: 2888
    name: server
  - port: 3888
    name: leader-election
  - port: 2181
    name: client
  clusterIP: None
  selector:
    app: zk
```

Then the StatefulSet:

```yaml
# zookeeper/40-statefulset.yml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zk
  namespace: nifi
spec:
  serviceName: zk-headless
  replicas: 3
  selector:
    matchLabels:
      app: zk
  template:
    metadata:
      labels:
        app: zk
    spec:
      containers:
      - name: zookeeper
        image: zookeeper:3.8
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        env:
        - name: ZOO_MY_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: ZOO_SERVERS
          value: "server.1=zk-0.zk-headless.nifi.svc.cluster.local:2888:3888;2181 server.2=zk-1.zk-headless.nifi.svc.cluster.local:2888:3888;2181 server.3=zk-2.zk-headless.nifi.svc.cluster.local:2888:3888;2181"
        command:
        - bash
        - -c
        - |
          ZK_ID=$((${HOSTNAME##*-}+1))
          echo $ZK_ID > /data/myid
          exec zkServer.sh start-foreground
        volumeMounts:
        - name: data
          mountPath: /data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        readinessProbe:
          exec:
            command:
            - bash
            - -c
            - "echo ruok | nc localhost 2181 | grep imok"
          initialDelaySeconds: 10
          periodSeconds: 10
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

## NiFi StatefulSet

Deploy NiFi nodes as a StatefulSet. First, the headless service for inter-node communication:

```yaml
# nifi/10-service-headless.yml
apiVersion: v1
kind: Service
metadata:
  name: nifi-headless
  namespace: nifi
  labels:
    app: nifi
spec:
  ports:
  - port: 8080
    name: http
  - port: 11443
    name: cluster
  clusterIP: None
  selector:
    app: nifi
```

The ClusterIP service for external access:

```yaml
# nifi/10-service.yml
apiVersion: v1
kind: Service
metadata:
  name: nifi
  namespace: nifi
  labels:
    app: nifi
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    name: http
  selector:
    app: nifi
```

Then the StatefulSet:

```yaml
# nifi/40-statefulset.yml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nifi
  namespace: nifi
spec:
  serviceName: nifi-headless
  replicas: 3
  podManagementPolicy: Parallel
  selector:
    matchLabels:
      app: nifi
  template:
    metadata:
      labels:
        app: nifi
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      initContainers:
      - name: wait-for-zookeeper
        image: busybox:1.35
        command:
        - sh
        - -c
        - |
          until nc -z zk-0.zk-headless.nifi.svc.cluster.local 2181; do
            echo "Waiting for ZooKeeper..."
            sleep 5
          done
      containers:
      - name: nifi
        image: apache/nifi:1.20.0
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 11443
          name: cluster
        env:
        - name: NIFI_WEB_HTTP_PORT
          value: "8080"
        - name: NIFI_CLUSTER_IS_NODE
          value: "true"
        - name: NIFI_CLUSTER_NODE_PROTOCOL_PORT
          value: "11443"
        - name: NIFI_ZK_CONNECT_STRING
          value: "zk-0.zk-headless.nifi.svc.cluster.local:2181,zk-1.zk-headless.nifi.svc.cluster.local:2181,zk-2.zk-headless.nifi.svc.cluster.local:2181"
        - name: NIFI_ELECTION_MAX_WAIT
          value: "1 min"
        - name: NIFI_SENSITIVE_PROPS_KEY
          valueFrom:
            secretKeyRef:
              name: nifi-secrets
              key: sensitive-props-key
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: data
          mountPath: /opt/nifi/nifi-current/flowfile_repository
          subPath: flowfile_repository
        - name: data
          mountPath: /opt/nifi/nifi-current/content_repository
          subPath: content_repository
        - name: data
          mountPath: /opt/nifi/nifi-current/provenance_repository
          subPath: provenance_repository
        - name: data
          mountPath: /opt/nifi/nifi-current/database_repository
          subPath: database_repository
        - name: conf
          mountPath: /opt/nifi/nifi-current/conf
          subPath: conf
        - name: logs
          mountPath: /opt/nifi/nifi-current/logs
        resources:
          requests:
            memory: "4Gi"
            cpu: "1"
          limits:
            memory: "8Gi"
            cpu: "2"
        readinessProbe:
          httpGet:
            path: /nifi
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 20
          timeoutSeconds: 5
        livenessProbe:
          httpGet:
            path: /nifi
            port: 8080
          initialDelaySeconds: 120
          periodSeconds: 30
          timeoutSeconds: 10
      volumes:
      - name: logs
        emptyDir: {}
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 50Gi
  - metadata:
      name: conf
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 1Gi
```

## Secrets

Create secrets for sensitive configuration:

```yaml
# 15-secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: nifi-secrets
  namespace: nifi
type: Opaque
stringData:
  sensitive-props-key: "your-32-char-sensitive-props-key"
```

Generate a secure key:

```bash
openssl rand -hex 16
```

## Ingress Configuration

Expose NiFi through an Ingress controller:

```yaml
# nifi/50-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nifi-ingress
  namespace: nifi
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "nifi-affinity"
    nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - nifi.example.com
    secretName: nifi-tls
  rules:
  - host: nifi.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nifi
            port:
              number: 8080
```

Session affinity is important because NiFi UI maintains state on specific cluster nodes.

## Horizontal Pod Autoscaler

Optional autoscaling based on CPU usage:

```yaml
# nifi/60-hpa.yml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nifi-hpa
  namespace: nifi
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: nifi
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Pods
        value: 1
        periodSeconds: 300
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60
```

## Pod Disruption Budget

Maintain availability during updates:

```yaml
# nifi/70-pdb.yml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nifi-pdb
  namespace: nifi
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: nifi
```

## Deployment Order

Deploy resources in this order:

```bash
# Create namespace, secrets, and config
kubectl apply -f 00-namespace.yml
kubectl apply -f 15-secret.yml
kubectl apply -f 20-configmap.yml

# Deploy ZooKeeper first
kubectl apply -f zookeeper/10-service-headless.yml
kubectl apply -f zookeeper/40-statefulset.yml

# Wait for ZooKeeper to be ready
kubectl -n nifi rollout status statefulset/zk

# Deploy NiFi services and statefulset
kubectl apply -f nifi/10-service-headless.yml
kubectl apply -f nifi/10-service.yml
kubectl apply -f nifi/40-statefulset.yml

# Wait for NiFi to be ready
kubectl -n nifi rollout status statefulset/nifi

# Configure ingress
kubectl apply -f nifi/50-ingress.yml

# Optional: HPA and PDB
kubectl apply -f nifi/60-hpa.yml
kubectl apply -f nifi/70-pdb.yml
```

## Verification

Check cluster status:

```bash
# Check pods
kubectl -n nifi get pods

# Check cluster connectivity
kubectl -n nifi exec nifi-0 -- /opt/nifi/nifi-current/bin/nifi.sh cluster-status

# View logs
kubectl -n nifi logs nifi-0 -f

# Port forward for local testing
kubectl -n nifi port-forward svc/nifi 8080:8080
```

Access the NiFi UI at `http://localhost:8080/nifi` or through your ingress hostname.

## Troubleshooting

### Common Issues

**Cluster nodes not connecting:**
```bash
# Check ZooKeeper connectivity
kubectl -n nifi exec nifi-0 -- nc -zv zk-0.zk-headless.nifi.svc.cluster.local 2181

# Check cluster protocol port
kubectl -n nifi exec nifi-0 -- nc -zv nifi-1.nifi-headless.nifi.svc.cluster.local 11443
```

**Flow synchronization issues:**
```bash
# Force flow refresh
kubectl -n nifi exec nifi-0 -- rm /opt/nifi/nifi-current/conf/flow.xml.gz
kubectl -n nifi delete pod nifi-0
```

**Memory issues:**
```bash
# Check JVM memory
kubectl -n nifi exec nifi-0 -- jstat -gc 1
```

## Summary

This article deployed:

- **ZooKeeper ensemble** for cluster coordination
- **NiFi StatefulSet** with persistent storage
- **Ingress** with session affinity
- **HPA** and **PDB** for resilience

The next article covers **securing NiFi deployments** with authentication and TLS.

## Resources

- [Apache NiFi Documentation](https://nifi.apache.org/docs.html)
- [NiFi System Administrator's Guide](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html)

## Next: Securing Your Data Flows

Check out the next article in this series, [Apache NiFi: Securing Your Data Flows](https://imti.co/nifi-security/).
