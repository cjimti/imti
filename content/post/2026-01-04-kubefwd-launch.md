---
layout:     post
title:      "kubefwd: Forward Kubernetes Services to Localhost by Name"
subtitle:   "One command, no configuration, automatic reconnection"
description: "kubefwd bulk-forwards Kubernetes services so they're accessible by their real hostnames. Your app connects to postgres:5432 and redis:6379 locally, using the same hostnames it would use inside the cluster."
date:       2026-01-04T12:02:00
author:     "Craig Johnston"
URL:        "kubefwd-launch/"
image:      "/img/post/patchbay.jpg"
twitter_image: "/img/post/patchbay_876_438.jpg"
tags:
- Kubernetes
- Development
- kubefwd
series:
- Kubernetes
---

## The Problem

`kubectl port-forward` works fine for one service. Two services? Three? A microservices app with a dozen dependencies? You end up with a terminal full of port-forward commands, each needing different local ports to avoid conflicts, and connection strings that differ between local and production.

## The Solution

[kubefwd] bulk-forwards Kubernetes services so they're accessible by their real hostnames:

```bash
brew install txn2/tap/kubefwd
sudo -E kubefwd svc -n mynamespace
```

Your app connects to `postgres:5432` and `redis:6379` locally, using the same hostnames it would use inside the cluster.

<!--more-->

## How It Works

```
Your App → postgres:5432
         → /etc/hosts: postgres = 127.1.27.1
         → kubefwd listens on 127.1.27.1:5432
         → forwards to pod in Kubernetes cluster
```

kubefwd creates unique loopback IPs for each service (127.1.27.1, 127.1.27.2, ...) so multiple services can use the same port. It adds entries to `/etc/hosts` and cleans them up on exit.

## Why Sudo?

kubefwd modifies `/etc/hosts` and binds to loopback addresses. Both require root on Unix systems. Unlike `kubectl port-forward` which uses unprivileged high ports, kubefwd preserves the real service ports so your configuration matches production.

All modifications are temporary. kubefwd removes `/etc/hosts` entries and releases network bindings when it exits.

## New in 2026

- **Auto-reconnect**: Survives pod restarts, deployments, VPN drops, and laptop sleep/wake
- **Interactive TUI**: Browse namespaces, forward services, view pod logs (`--tui`)
- **REST API**: 40+ endpoints for programmatic control
- **MCP server**: AI assistants can manage forwarding

[Full feature guide](/kubefwd-2026/)

## vs. Telepresence

Different tools for different problems:

- **kubefwd**: Local app connects to cluster services. Traffic flows local → cluster. Simple.
- **Telepresence**: Cluster traffic routes to your local machine. Traffic interception, preview URLs, debugging with real traffic.

kubefwd is one binary, one command, no cluster components. Telepresence does more, but requires more. Choose based on what you need.

## Install

**macOS**: `brew install txn2/tap/kubefwd`

**Linux**: Download from [releases][kubefwd releases]

**Windows**: `scoop install kubefwd`

## Links

- [GitHub][kubefwd]
- [Documentation][kubefwd docs]
- [Releases][kubefwd releases]

[kubefwd]: https://github.com/txn2/kubefwd
[kubefwd docs]: https://kubefwd.com
[kubefwd releases]: https://github.com/txn2/kubefwd/releases
