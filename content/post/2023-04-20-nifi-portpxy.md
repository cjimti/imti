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

This article demonstrates using **portpxy** to enable dynamic HTTP listeners in NiFi on Kubernetes, configuring HandleHttpRequest processors with path-based routing through a Go-based reverse proxy sidecar.

<!--more-->

This continues from [Part 4: JOLT Transformations Part 2](https://imti.co/nifi-jolt-2/).

{{< toc >}}
{{< content-ad >}}

## The Challenge

NiFi's `HandleHttpRequest` processor binds to a specific port. On Kubernetes, exposing multiple ports requires Service modifications and Ingress rules for each endpoint. This becomes unwieldy when you need dozens of webhook endpoints.

**portpxy** solves this by:
- Running as a sidecar container
- Routing requests by path to different NiFi ports
- Enabling dynamic endpoint creation without infrastructure changes

For background on Go reverse proxies, see [Golang Reverse Proxy](https://imti.co/golang-reverse-proxy/).

## portpxy Configuration

### ConfigMap for Routes

Define path-to-port mappings:

```yaml
# portpxy-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: portpxy-config
  namespace: nifi
data:
  config.yaml: |
    listen: ":8888"
    routes:
      - path: "/webhooks/github"
        target: "http://localhost:9001"
        methods: ["POST"]
      - path: "/webhooks/stripe"
        target: "http://localhost:9002"
        methods: ["POST"]
      - path: "/webhooks/slack"
        target: "http://localhost:9003"
        methods: ["POST"]
      - path: "/api/ingest"
        target: "http://localhost:9004"
        methods: ["POST", "PUT"]
      - path: "/health"
        target: "http://localhost:9005"
        methods: ["GET"]
    healthCheck:
      enabled: true
      path: "/healthz"
    logging:
      level: "info"
      format: "json"
```

### Sidecar Deployment

Add portpxy as a sidecar to your NiFi pods:

```yaml
# nifi-with-portpxy.yaml
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
      containers:
      - name: nifi
        image: apache/nifi:1.20.0
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9001
          name: webhook-github
        - containerPort: 9002
          name: webhook-stripe
        - containerPort: 9003
          name: webhook-slack
        - containerPort: 9004
          name: api-ingest
        - containerPort: 9005
          name: health
        # ... rest of NiFi config
      - name: portpxy
        image: ghcr.io/txn2/portpxy:latest
        ports:
        - containerPort: 8888
          name: proxy
        args:
        - "--config=/config/config.yaml"
        volumeMounts:
        - name: portpxy-config
          mountPath: /config
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8888
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8888
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: portpxy-config
        configMap:
          name: portpxy-config
```

### Service Configuration

Expose only the proxy port:

```yaml
# nifi-webhook-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nifi-webhooks
  namespace: nifi
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8888
    name: webhooks
  selector:
    app: nifi
```

### Ingress for Webhooks

Route external traffic to the proxy:

```yaml
# nifi-webhook-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nifi-webhooks
  namespace: nifi
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - webhooks.example.com
    secretName: webhooks-tls
  rules:
  - host: webhooks.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nifi-webhooks
            port:
              number: 80
```

## NiFi Flow Configuration

### HandleHttpRequest Processor

Configure a processor for each webhook endpoint:

**GitHub Webhook (Port 9001):**

1. Add `HandleHttpRequest` processor
2. Configure properties:
   - Listening Port: `9001`
   - Base Path: `/`
   - HTTP Context Map: Create new `StandardHttpContextMap`

3. Connect to `HandleHttpResponse` for acknowledgment

### Basic Webhook Flow

```
HandleHttpRequest (9001)
    ↓
EvaluateJsonPath (extract event type)
    ↓
RouteOnAttribute (route by event)
    ↓ (push event)
JoltTransformJSON (normalize payload)
    ↓
PublishKafka (send to topic)
    ↓
HandleHttpResponse (200 OK)
```

### Flow Template

Export this flow as a template for reuse:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<template>
  <name>Webhook Handler Template</name>
  <processors>
    <processor>
      <name>HandleHttpRequest</name>
      <type>org.apache.nifi.processors.standard.HandleHttpRequest</type>
      <properties>
        <property name="Listening Port">${webhook.port}</property>
        <property name="HTTP Context Map">http-context-map</property>
      </properties>
    </processor>
    <processor>
      <name>EvaluateJsonPath</name>
      <type>org.apache.nifi.processors.standard.EvaluateJsonPath</type>
      <properties>
        <property name="Destination">flowfile-attribute</property>
        <property name="event.type">$.event</property>
        <property name="event.id">$.id</property>
      </properties>
    </processor>
    <processor>
      <name>HandleHttpResponse</name>
      <type>org.apache.nifi.processors.standard.HandleHttpResponse</type>
      <properties>
        <property name="HTTP Status Code">200</property>
        <property name="HTTP Context Map">http-context-map</property>
      </properties>
    </processor>
  </processors>
</template>
```

## portpxy Implementation

Here's a simplified Go implementation showing the core routing logic:

```go
package main

import (
    "log"
    "net/http"
    "net/http/httputil"
    "net/url"
    "strings"

    "gopkg.in/yaml.v3"
)

type Route struct {
    Path    string   `yaml:"path"`
    Target  string   `yaml:"target"`
    Methods []string `yaml:"methods"`
}

type Config struct {
    Listen string  `yaml:"listen"`
    Routes []Route `yaml:"routes"`
}

func main() {
    config := loadConfig("config.yaml")

    mux := http.NewServeMux()

    for _, route := range config.Routes {
        target, _ := url.Parse(route.Target)
        proxy := httputil.NewSingleHostReverseProxy(target)

        methods := make(map[string]bool)
        for _, m := range route.Methods {
            methods[m] = true
        }

        path := route.Path
        mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
            if len(methods) > 0 && !methods[r.Method] {
                http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
                return
            }

            // Strip the matched prefix for the backend
            r.URL.Path = strings.TrimPrefix(r.URL.Path, path)
            if r.URL.Path == "" {
                r.URL.Path = "/"
            }

            log.Printf("Proxying %s %s -> %s", r.Method, path, target)
            proxy.ServeHTTP(w, r)
        })
    }

    // Health check
    mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    })

    log.Printf("Starting portpxy on %s", config.Listen)
    log.Fatal(http.ListenAndServe(config.Listen, mux))
}

func loadConfig(path string) *Config {
    // Load and parse YAML config
    // ... implementation
    return &Config{}
}
```

## Request Validation

Add validation before routing to NiFi:

```go
func validateWebhook(next http.Handler, secretHeader string) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Verify signature for GitHub webhooks
        if secretHeader != "" {
            signature := r.Header.Get("X-Hub-Signature-256")
            if !verifySignature(r, signature) {
                http.Error(w, "Invalid signature", http.StatusUnauthorized)
                return
            }
        }
        next.ServeHTTP(w, r)
    })
}

func verifySignature(r *http.Request, signature string) bool {
    // Read body and compute HMAC
    // Compare with provided signature
    return true // Simplified
}
```

## Dynamic Route Updates

Reload routes without restarting:

```go
import "github.com/fsnotify/fsnotify"

func watchConfig(configPath string, reloadCh chan<- *Config) {
    watcher, _ := fsnotify.NewWatcher()
    defer watcher.Close()

    watcher.Add(configPath)

    for {
        select {
        case event := <-watcher.Events:
            if event.Op&fsnotify.Write == fsnotify.Write {
                config := loadConfig(configPath)
                reloadCh <- config
                log.Println("Config reloaded")
            }
        case err := <-watcher.Errors:
            log.Println("Watcher error:", err)
        }
    }
}
```

Update the ConfigMap and the sidecar picks up changes:

```bash
kubectl -n nifi edit configmap portpxy-config
```

## Metrics and Observability

Add Prometheus metrics to portpxy:

```go
import "github.com/prometheus/client_golang/prometheus"

var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "portpxy_requests_total",
            Help: "Total requests by route and status",
        },
        []string{"route", "method", "status"},
    )

    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "portpxy_request_duration_seconds",
            Help:    "Request duration by route",
            Buckets: prometheus.DefBuckets,
        },
        []string{"route"},
    )
)

func init() {
    prometheus.MustRegister(requestsTotal, requestDuration)
}
```

Expose metrics endpoint:

```go
mux.Handle("/metrics", promhttp.Handler())
```

## Testing Webhooks

Test your webhook endpoints:

```bash
# GitHub webhook simulation
curl -X POST https://webhooks.example.com/webhooks/github \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"ref": "refs/heads/main", "commits": []}'

# Stripe webhook simulation
curl -X POST https://webhooks.example.com/webhooks/stripe \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: t=123,v1=abc" \
  -d '{"type": "payment_intent.succeeded", "data": {}}'

# Check health
curl https://webhooks.example.com/healthz
```

## Summary

This article configured:

- **portpxy sidecar** for path-based routing
- **Multiple HandleHttpRequest** processors on different ports
- **Single Ingress** for all webhook endpoints
- **Dynamic configuration** via ConfigMap
- **Metrics** for observability

## Resources

- [portpxy GitHub](https://github.com/txn2/portpxy)
- [Golang Reverse Proxy](https://imti.co/golang-reverse-proxy/)
- [NiFi HandleHttpRequest](https://nifi.apache.org/docs/nifi-docs/components/org.apache.nifi/nifi-standard-nar/1.20.0/org.apache.nifi.processors.standard.HandleHttpRequest/)

