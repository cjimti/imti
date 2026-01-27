---
draft: false
layout: post
title: "Apache NiFi: Dynamic HTTP Listeners with portpxy"
subtitle: "Apache NiFi Part 5"
date: 2023-04-20
author: "Craig Johnston"
URL: "nifi-portpxy/"
image: "/img/post/nifi.jpg"
twitter_image: "/img/post/nifi_876_438.jpg"
tags:
- Apache NiFi
- Kubernetes
- Webhooks
- Go
series:
- Apache NiFi
---

I wrote **[portpxy]** to solve an annoying problem: NiFi lets you spin up HTTP listeners at runtime, but Kubernetes makes you update manifests every time you want to expose a new port. This article shows how portpxy fixes that.

<!--more-->

{{< toc >}}
{{< content-ad >}}

## NiFi's HandleHttpRequest processor

NiFi's `HandleHttpRequest` processor starts a Jetty server on whatever port you specify. Pair it with `HandleHttpResponse` and you've got a web service. Each request becomes a FlowFile that flows through your pipeline.

### Setting up a webhook listener

1. Drag `HandleHttpRequest` onto the canvas
2. Set the listening port (e.g., `10001`)
3. Create a `StandardHttpContextMap` controller service - this links requests to responses
4. Build your processing flow
5. End with `HandleHttpResponse` using the same context map

<pre class="mermaid">
flowchart TD
    A[HandleHttpRequest<br/>port 10001] --> B[EvaluateJsonPath<br/>extract fields]
    B --> C[RouteOnAttribute<br/>route by event type]
    C --> D[JoltTransformJSON<br/>normalize payload]
    D --> E[PublishKafka<br/>send to topic]
    E --> F[HandleHttpResponse<br/>200 OK]
</pre>

On a standalone NiFi server, webhooks hit `http://nifi-server:10001/` directly. Simple.

## The Kubernetes problem

On Kubernetes, pods aren't directly accessible. To expose port 10001 you need to:

1. Add port 10001 to the Service spec
2. Add Ingress rules for that port
3. Run `kubectl apply` and wait

Now imagine 20 webhook endpoints for different integrations. That's 20 Service ports, 20 Ingress rules, and a deploy cycle every time someone creates a new listener in NiFi.

This is annoying. NiFi's whole point is that you can build and change data flows at runtime without deployments. Kubernetes undoes that.

## portpxy

**[portpxy]** encodes the target port in the URL path itself.

Instead of:
```
https://nifi.example.com:10001/webhook  ← requires exposing port 10001
```

You use:
```
https://nifi.example.com/10001/webhook  ← port is in the path
```

portpxy extracts `10001` from the URL, checks it's in the allowed range, and proxies to `nifi:10001/webhook`.

The workflow:

1. Create `HandleHttpRequest` on port 10005 in NiFi
2. Tell the external service to send webhooks to `https://nifi.example.com/10005/`
3. That's it

<pre class="mermaid">
sequenceDiagram
    participant Client as External Client
    participant portpxy
    participant NiFi as NiFi (HandleHttpRequest)

    Client->>portpxy: POST /10005/github/webhook
    Note over portpxy: Extract port 10005 from path
    Note over portpxy: Validate: 10000 ≤ 10005 ≤ 20000
    Note over portpxy: Rewrite path: /github/webhook
    portpxy->>NiFi: POST nifi:10005/github/webhook
    NiFi-->>portpxy: 200 OK
    portpxy-->>Client: 200 OK
</pre>

## Kubernetes deployment

Deploy these three manifests once. You won't need to touch them again.

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nifi-port-proxy
  namespace: nifi
  labels:
    app: nifi-port-proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nifi-port-proxy
  template:
    metadata:
      labels:
        app: nifi-port-proxy
    spec:
      containers:
        - name: portpxy
          image: txn2/portpxy:v0.0.5
          env:
            - name: IP
              value: "0.0.0.0"
            - name: PORT
              value: "8080"
            - name: BACKEND_HOST
              value: "nifi"
            - name: BACKEND_PROTO
              value: "http"
            - name: ALLOW_PORT_BEGIN
              value: "10000"
            - name: ALLOW_PORT_END
              value: "20000"
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
```

Environment variables:

| Variable | Description |
|----------|-------------|
| `BACKEND_HOST` | NiFi service name (`nifi` or `nifi-headless`) |
| `BACKEND_PROTO` | `http` or `https` |
| `ALLOW_PORT_BEGIN` | Lowest allowed port |
| `ALLOW_PORT_END` | Highest allowed port |
| `PORT` | Port portpxy listens on |

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nifi-port-proxy
  namespace: nifi
spec:
  ports:
    - port: 8080
      name: http
      targetPort: 8080
  selector:
    app: nifi-port-proxy
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nifi-port-proxy
  namespace: nifi
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  rules:
    - host: nifi.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nifi-port-proxy
                port:
                  number: 8080
  tls:
    - hosts:
       - nifi.example.com
      secretName: nifi-webhooks-tls
```

## Example: GitHub webhooks

### 1. Create the NiFi flow

1. Drag `HandleHttpRequest` to canvas, set listening port to `10001`
2. Create a `StandardHttpContextMap` controller service
3. Add `EvaluateJsonPath` to extract `$.action` and `$.repository.full_name`
4. Add `RouteOnAttribute` to route by event type
5. Add `JoltTransformJSON` to normalize the payload
6. End with `HandleHttpResponse`, status code `200`

### 2. Configure GitHub

In your repo settings, go to Webhooks and add:

- Payload URL: `https://nifi.example.com/10001/`
- Content type: `application/json`
- Secret: your HMAC secret
- Events: whatever you need

GitHub sends webhooks, portpxy routes them to port 10001, NiFi processes them.

### 3. Adding Stripe webhooks

Need Stripe too?

1. Add another `HandleHttpRequest` on port `10002`
2. Build the processing flow
3. Configure Stripe to send to `https://nifi.example.com/10002/`

No Kubernetes changes required.

## Path passthrough

The path after the port passes through to NiFi:

```
https://nifi.example.com/10001/github/push   → nifi:10001/github/push
https://nifi.example.com/10001/github/pr     → nifi:10001/github/pr
https://nifi.example.com/10001/github/issues → nifi:10001/github/issues
```

Use NiFi's "Allowed Paths" property on `HandleHttpRequest` to filter requests, or route based on `${http.request.uri}` in your flow.

## Port range conventions

With ports 10000-20000, you have 10,000 endpoints. Pick a convention:

| Range | Purpose |
|-------|---------|
| 10000-10099 | GitHub |
| 10100-10199 | Payment providers |
| 10200-10299 | Slack/Teams |
| 10300-10399 | Internal services |
| 10400+ | Ad-hoc |

NiFi is the source of truth. If nothing's listening on a port, the request fails.

## Adding JWT authentication

For endpoints that need JWT auth, chain [jwtpxy] in front of portpxy:

```yaml
containers:
  - name: portpxy
    image: txn2/portpxy:v0.0.5
    env:
      - name: PORT
        value: "8070"
      - name: BACKEND_HOST
        value: "nifi"
      - name: ALLOW_PORT_BEGIN
        value: "10000"
      - name: ALLOW_PORT_END
        value: "20000"

  - name: jwtpxy
    image: txn2/jwtpxy:v0.2.5
    env:
      - name: PORT
        value: "8080"
      - name: BACKEND
        value: "http://127.0.0.1:8070"
      - name: KEYCLOAK
        value: "https://auth.example.com/realms/myapp"
      - name: REQUIRE_TOKEN
        value: "false"
      - name: ALLOW_COOKIE_TOKEN
        value: "true"
    ports:
      - containerPort: 8080
        name: http
```

jwtpxy validates tokens and passes user info to NiFi via headers.

## Testing

```bash
# Test a webhook endpoint
curl -X POST https://nifi.example.com/10001/ \
  -H "Content-Type: application/json" \
  -d '{"event": "test", "data": {}}'

# Test with path
curl -X POST https://nifi.example.com/10001/github/push \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"ref": "refs/heads/main"}'

# Port out of range (should fail)
curl https://nifi.example.com/9999/test
```

## Summary

| Without portpxy | With portpxy |
|-----------------|--------------|
| Edit Service YAML for each port | Configure NiFi only |
| Edit Ingress for each endpoint | Configure NiFi only |
| kubectl apply, wait for rollout | Immediate |
| DevOps bottleneck | Self-service |

Deploy portpxy once, then create webhook endpoints through NiFi's UI whenever you need them.

## Resources

- [portpxy GitHub][portpxy]
- [jwtpxy GitHub][jwtpxy]
- [HandleHttpRequest documentation](https://nifi.apache.org/components/org.apache.nifi.processors.standard.HandleHttpRequest/)
- [HTTP communication with Apache NiFi](https://ddewaele.github.io/http-communication-with-apache-nifi/)

[portpxy]: https://github.com/txn2/portpxy
[jwtpxy]: https://github.com/txn2/jwtpxy
