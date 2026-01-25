---
draft: false
layout: post
title: "Apache NiFi: Securing Your Data Flows"
subtitle: "Apache NiFi Part 2"
date: 2022-10-05
author: "Craig Johnston"
URL: "nifi-security/"
image: "/img/post/nifi.jpg"
twitter_image: "/img/post/nifi_876_438.jpg"
tags:
- Apache NiFi
- Security
- Kubernetes
- Authentication
series:
- Apache NiFi
---

This article covers **securing Apache NiFi** deployments with TLS encryption, authentication providers, and role-based access control, including LDAP, OIDC, and certificate-based authentication.

<!--more-->

This continues from [Part 1: Production Kubernetes Deployment](https://imti.co/nifi-kubernetes-deployment/).

{{< toc >}}
{{< content-ad >}}

## TLS Configuration

### Generate Certificates

Use the NiFi Toolkit to generate certificates:

```bash
# Download NiFi Toolkit
wget https://archive.apache.org/dist/nifi/1.20.0/nifi-toolkit-1.20.0-bin.zip
unzip nifi-toolkit-1.20.0-bin.zip
cd nifi-toolkit-1.20.0

# Generate certificates for cluster
./bin/tls-toolkit.sh standalone \
  -n 'nifi-0.nifi-headless.nifi.svc.cluster.local,nifi-1.nifi-headless.nifi.svc.cluster.local,nifi-2.nifi-headless.nifi.svc.cluster.local' \
  -C 'CN=admin,OU=NIFI' \
  -o ./certs \
  --subjectAlternativeNames 'nifi.example.com,localhost'
```

### Create Kubernetes Secrets

```bash
# Create secrets for each node
for i in 0 1 2; do
  kubectl -n nifi create secret generic nifi-${i}-certs \
    --from-file=keystore.jks=certs/nifi-${i}.nifi-headless.nifi.svc.cluster.local/keystore.jks \
    --from-file=truststore.jks=certs/nifi-${i}.nifi-headless.nifi.svc.cluster.local/truststore.jks \
    --from-literal=keystore-password=$(cat certs/nifi-${i}.nifi-headless.nifi.svc.cluster.local/config.json | jq -r '.keyStorePassword') \
    --from-literal=truststore-password=$(cat certs/nifi-${i}.nifi-headless.nifi.svc.cluster.local/config.json | jq -r '.trustStorePassword') \
    --from-literal=key-password=$(cat certs/nifi-${i}.nifi-headless.nifi.svc.cluster.local/config.json | jq -r '.keyPassword')
done

# Admin certificate for CLI access
kubectl -n nifi create secret generic nifi-admin-cert \
  --from-file=admin-cert.p12=certs/CN=admin_OU=NIFI.p12 \
  --from-literal=password=$(cat certs/CN=admin_OU=NIFI.password)
```

### Secure NiFi Configuration

Update the ConfigMap for HTTPS:

```yaml
# nifi-secure-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nifi-secure-config
  namespace: nifi
data:
  nifi.properties: |
    # Web properties
    nifi.web.http.host=
    nifi.web.http.port=
    nifi.web.https.host=0.0.0.0
    nifi.web.https.port=8443
    nifi.web.proxy.host=nifi.example.com

    # Security properties
    nifi.security.keystore=/opt/nifi/certs/keystore.jks
    nifi.security.keystoreType=JKS
    nifi.security.keystorePasswd=${KEYSTORE_PASSWORD}
    nifi.security.keyPasswd=${KEY_PASSWORD}
    nifi.security.truststore=/opt/nifi/certs/truststore.jks
    nifi.security.truststoreType=JKS
    nifi.security.truststorePasswd=${TRUSTSTORE_PASSWORD}

    # Cluster security
    nifi.cluster.protocol.is.secure=true
    nifi.cluster.is.node=true
    nifi.cluster.node.address=${HOSTNAME}.nifi-headless.nifi.svc.cluster.local
    nifi.cluster.node.protocol.port=11443

    # ZooKeeper
    nifi.zookeeper.connect.string=zk-0.zk-headless.nifi.svc.cluster.local:2181,zk-1.zk-headless.nifi.svc.cluster.local:2181,zk-2.zk-headless.nifi.svc.cluster.local:2181
    nifi.zookeeper.root.node=/nifi

    nifi.sensitive.props.key=${NIFI_SENSITIVE_PROPS_KEY}
```

## LDAP Authentication

Configure LDAP for user authentication:

```yaml
# login-identity-providers.xml in ConfigMap
data:
  login-identity-providers.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <loginIdentityProviders>
      <provider>
        <identifier>ldap-provider</identifier>
        <class>org.apache.nifi.ldap.LdapProvider</class>
        <property name="Authentication Strategy">SIMPLE</property>
        <property name="Manager DN">cn=admin,dc=example,dc=com</property>
        <property name="Manager Password">${LDAP_MANAGER_PASSWORD}</property>
        <property name="TLS - Keystore"></property>
        <property name="TLS - Keystore Password"></property>
        <property name="TLS - Keystore Type"></property>
        <property name="TLS - Truststore"></property>
        <property name="TLS - Truststore Password"></property>
        <property name="TLS - Truststore Type"></property>
        <property name="TLS - Client Auth"></property>
        <property name="TLS - Protocol"></property>
        <property name="TLS - Shutdown Gracefully"></property>
        <property name="Referral Strategy">FOLLOW</property>
        <property name="Connect Timeout">10 secs</property>
        <property name="Read Timeout">10 secs</property>
        <property name="Url">ldap://ldap.example.com:389</property>
        <property name="User Search Base">ou=users,dc=example,dc=com</property>
        <property name="User Search Filter">uid={0}</property>
        <property name="Identity Strategy">USE_USERNAME</property>
        <property name="Authentication Expiration">12 hours</property>
      </provider>
    </loginIdentityProviders>
```

Update `nifi.properties` to use LDAP:

```properties
nifi.login.identity.provider.configuration.file=./conf/login-identity-providers.xml
nifi.security.user.login.identity.provider=ldap-provider
```

## OIDC Authentication

Configure OpenID Connect for SSO:

```yaml
# nifi.properties for OIDC
data:
  nifi.properties: |
    # OIDC Configuration
    nifi.security.user.oidc.discovery.url=https://auth.example.com/.well-known/openid-configuration
    nifi.security.user.oidc.client.id=nifi-client
    nifi.security.user.oidc.client.secret=${OIDC_CLIENT_SECRET}
    nifi.security.user.oidc.preferred.jwsalgorithm=RS256
    nifi.security.user.oidc.claim.identifying.user=email
    nifi.security.user.oidc.additional.scopes=profile,email
```

Create a secret for OIDC credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nifi-oidc-secret
  namespace: nifi
type: Opaque
stringData:
  client-secret: "your-oidc-client-secret"
```

## Authorizers Configuration

Configure file-based or LDAP-based authorization:

```yaml
data:
  authorizers.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <authorizers>
      <userGroupProvider>
        <identifier>file-user-group-provider</identifier>
        <class>org.apache.nifi.authorization.FileUserGroupProvider</class>
        <property name="Users File">./conf/users.xml</property>
        <property name="Legacy Authorized Users File"></property>
        <property name="Initial User Identity 1">CN=admin, OU=NIFI</property>
        <property name="Initial User Identity 2">CN=nifi-0.nifi-headless.nifi.svc.cluster.local, OU=NIFI</property>
        <property name="Initial User Identity 3">CN=nifi-1.nifi-headless.nifi.svc.cluster.local, OU=NIFI</property>
        <property name="Initial User Identity 4">CN=nifi-2.nifi-headless.nifi.svc.cluster.local, OU=NIFI</property>
      </userGroupProvider>

      <accessPolicyProvider>
        <identifier>file-access-policy-provider</identifier>
        <class>org.apache.nifi.authorization.FileAccessPolicyProvider</class>
        <property name="User Group Provider">file-user-group-provider</property>
        <property name="Authorizations File">./conf/authorizations.xml</property>
        <property name="Initial Admin Identity">CN=admin, OU=NIFI</property>
        <property name="Legacy Authorized Users File"></property>
        <property name="Node Identity 1">CN=nifi-0.nifi-headless.nifi.svc.cluster.local, OU=NIFI</property>
        <property name="Node Identity 2">CN=nifi-1.nifi-headless.nifi.svc.cluster.local, OU=NIFI</property>
        <property name="Node Identity 3">CN=nifi-2.nifi-headless.nifi.svc.cluster.local, OU=NIFI</property>
        <property name="Node Group"></property>
      </accessPolicyProvider>

      <authorizer>
        <identifier>managed-authorizer</identifier>
        <class>org.apache.nifi.authorization.StandardManagedAuthorizer</class>
        <property name="Access Policy Provider">file-access-policy-provider</property>
      </authorizer>
    </authorizers>
```

### LDAP User Group Provider

For LDAP-based groups:

```xml
<userGroupProvider>
  <identifier>ldap-user-group-provider</identifier>
  <class>org.apache.nifi.ldap.tenants.LdapUserGroupProvider</class>
  <property name="Authentication Strategy">SIMPLE</property>
  <property name="Manager DN">cn=admin,dc=example,dc=com</property>
  <property name="Manager Password">${LDAP_MANAGER_PASSWORD}</property>
  <property name="Url">ldap://ldap.example.com:389</property>
  <property name="User Search Base">ou=users,dc=example,dc=com</property>
  <property name="User Object Class">inetOrgPerson</property>
  <property name="User Search Scope">ONE_LEVEL</property>
  <property name="User Search Filter"></property>
  <property name="User Identity Attribute">uid</property>
  <property name="User Group Name Attribute">memberOf</property>
  <property name="Group Search Base">ou=groups,dc=example,dc=com</property>
  <property name="Group Object Class">groupOfNames</property>
  <property name="Group Search Scope">ONE_LEVEL</property>
  <property name="Group Search Filter"></property>
  <property name="Group Name Attribute">cn</property>
  <property name="Group Member Attribute">member</property>
</userGroupProvider>
```

## Updated StatefulSet

Modify the StatefulSet to include certificates:

```yaml
# nifi-secure-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nifi
  namespace: nifi
spec:
  serviceName: nifi-headless
  replicas: 3
  selector:
    matchLabels:
      app: nifi
  template:
    metadata:
      labels:
        app: nifi
    spec:
      initContainers:
      - name: init-certs
        image: busybox:1.35
        command:
        - sh
        - -c
        - |
          cp /certs-secret/* /certs/
          chmod 600 /certs/*
        volumeMounts:
        - name: certs-secret
          mountPath: /certs-secret
          readOnly: true
        - name: certs
          mountPath: /certs
      containers:
      - name: nifi
        image: apache/nifi:1.20.0
        ports:
        - containerPort: 8443
          name: https
        - containerPort: 11443
          name: cluster
        env:
        - name: NIFI_WEB_HTTPS_PORT
          value: "8443"
        - name: KEYSTORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: nifi-certs
              key: keystore-password
        - name: KEY_PASSWORD
          valueFrom:
            secretKeyRef:
              name: nifi-certs
              key: key-password
        - name: TRUSTSTORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: nifi-certs
              key: truststore-password
        - name: NIFI_SENSITIVE_PROPS_KEY
          valueFrom:
            secretKeyRef:
              name: nifi-secrets
              key: sensitive-props-key
        volumeMounts:
        - name: certs
          mountPath: /opt/nifi/certs
          readOnly: true
        - name: config
          mountPath: /opt/nifi/nifi-current/conf/nifi.properties
          subPath: nifi.properties
        - name: config
          mountPath: /opt/nifi/nifi-current/conf/authorizers.xml
          subPath: authorizers.xml
        - name: config
          mountPath: /opt/nifi/nifi-current/conf/login-identity-providers.xml
          subPath: login-identity-providers.xml
        - name: data
          mountPath: /opt/nifi/nifi-current/flowfile_repository
          subPath: flowfile_repository
        - name: data
          mountPath: /opt/nifi/nifi-current/content_repository
          subPath: content_repository
        - name: data
          mountPath: /opt/nifi/nifi-current/provenance_repository
          subPath: provenance_repository
        readinessProbe:
          httpGet:
            path: /nifi
            port: 8443
            scheme: HTTPS
          initialDelaySeconds: 90
          periodSeconds: 20
      volumes:
      - name: certs-secret
        projected:
          sources:
          - secret:
              name: nifi-0-certs
          - secret:
              name: nifi-1-certs
          - secret:
              name: nifi-2-certs
      - name: certs
        emptyDir: {}
      - name: config
        configMap:
          name: nifi-secure-config
```

## Secure Ingress

Update ingress for HTTPS backend:

```yaml
# nifi-secure-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nifi-ingress
  namespace: nifi
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "off"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "nifi-affinity"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - nifi.example.com
    secretName: nifi-ingress-tls
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
              number: 8443
```

## Audit Logging

Enable comprehensive audit logging:

```properties
# In nifi.properties
nifi.provenance.repository.implementation=org.apache.nifi.provenance.WriteAheadProvenanceRepository
nifi.provenance.repository.directory.default=./provenance_repository
nifi.provenance.repository.max.storage.time=30 days
nifi.provenance.repository.max.storage.size=10 GB
nifi.provenance.repository.rollover.time=10 mins
nifi.provenance.repository.rollover.size=100 MB

# User action audit
nifi.security.user.authorizer=managed-authorizer
```

Configure logback for security events:

```xml
<!-- logback.xml -->
<appender name="SECURITY_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>${org.apache.nifi.bootstrap.config.log.dir}/nifi-user.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <fileNamePattern>${org.apache.nifi.bootstrap.config.log.dir}/nifi-user_%d{yyyy-MM-dd}.log</fileNamePattern>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
    <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
        <pattern>%date %level [%thread] %logger{40} %msg%n</pattern>
    </encoder>
</appender>

<logger name="org.apache.nifi.web.security" level="INFO" additivity="false">
    <appender-ref ref="SECURITY_FILE"/>
</logger>

<logger name="org.apache.nifi.authorization" level="INFO" additivity="false">
    <appender-ref ref="SECURITY_FILE"/>
</logger>
```

## Network Policies

Restrict pod communication:

```yaml
# nifi-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nifi-network-policy
  namespace: nifi
spec:
  podSelector:
    matchLabels:
      app: nifi
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow ingress traffic
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8443
  # Allow cluster communication
  - from:
    - podSelector:
        matchLabels:
          app: nifi
    ports:
    - protocol: TCP
      port: 11443
  egress:
  # Allow ZooKeeper
  - to:
    - podSelector:
        matchLabels:
          app: zk
    ports:
    - protocol: TCP
      port: 2181
  # Allow cluster communication
  - to:
    - podSelector:
        matchLabels:
          app: nifi
    ports:
    - protocol: TCP
      port: 11443
  # Allow DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
```

## Summary

This article secured NiFi with:

- **TLS encryption** for web UI and cluster communication
- **LDAP authentication** for user login
- **OIDC integration** for SSO
- **Authorization policies** with file and LDAP providers
- **Audit logging** for compliance
- **Network policies** for pod isolation

The next article explores **JOLT transformations** for JSON data processing.

## Resources

- [NiFi Security Configuration](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#security_configuration)
- [NiFi TLS Toolkit](https://nifi.apache.org/docs/nifi-docs/html/toolkit-guide.html#tls_toolkit)