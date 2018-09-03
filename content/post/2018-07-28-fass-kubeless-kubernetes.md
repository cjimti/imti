---
layout:     post
title:      "FaaS on Kubernetes"
subtitle:   "Kubeless, Python and Elasticsearch"
date:       2018-07-28
author:     "Craig Johnston"
URL:        "fass-kubeless-kubernetes/"
image:      "/img/post/balloon.jpg"
tags:
- Elasticsearch
- Python
- Kubernetes
- Serverless
series:
- Kubernetes
---


FaaS or [Function as a Service] also known as [Serverless computing] implementations are gaining popularity. Discussed often are the cost savings and each implementations relationship to the physical and network architecture of a specific platform or vendor. While many of the [cost and infrastructure] advantages of FaaS are compelling, its only one of many advantages. Below, I hope to demonstrate how easy it is to develop and deploy FaaS components into a custom Kubernetes cluster. The functions I develop are nearly all business logic, and I believe therein lies the advantage, **high-density business logic**. Functions can have a higher degree of focus directly on business logic and communication with other services. Functions can communicate with other functions, microservices or monoliths. In this article, I demonstrate this with [Elasticsearch].

![](/images/content/faas_architecture.png)

{{< toc >}}

## Architecture

Lately, I have been seeing a trend of comparisons for choosing between developing applications with Monoliths, Microservices, or FaaS. I believe this comparison in some context, is flawed. Unless you are on a desert island and can only choose one implementation in which to develop your application, you sill have a problem of definition. Even if you did have to limit your architecture to one concept, you would first need to define a standard of comparison, determining where a bloated Microservice is a monolith, or if a prewarmed FaaS is just a small Microservice. If you are following my point, they can all have a place regardless of definition, that is if the underlying platform can support them equally. All these concepts can work together seamlessly in one platform, by operating in networked containers, orchestrated by Kubernetes.

![](/images/content/k8s_micro_mono_func.png)

## Terminology

In this article I will use the term **Function** to describe a [Kubeless Function]. [Kubeless] is an implementation of FaaS [Function as a Service] also known as [Serverless computing], [Serverless], [lambda][AWS lambda], [Google functions] or even [Nano Services].

## Motivation

While our industry sorts out the distinctive and vocabulary of these new architectures, please bear with me while I show you a simplified example, extracted from implementation I find successful. There are exciting and innovative ways to trigger and chain FaaS services. Implementations like Amazon's Alexa and its use of AWS lambdas are one successful example. However in this article I demonstrate a basic implementation; the everyday needs of an HTTP API stack.

At this point most of my legacy systems are Monoliths; however they are containerized and live in the cluster as they would any hosting environment. I design most of my Microservices for generic or reusable functionality or more complex business logic not appropriate for pure functions. Functions are a great addition to data flow, and it's pipeline between monoliths, microservices and other functions. Kubeless Functions give me the **ability to quickly inject business logic at any point in the platform without significant architectural changes.**

## Kubeless for FaaS

I appreciate the simplicity and elegance of [Kubeless] and its seamless integration into Kubernetes. [Kubeless] is an extension of the Kubernetes API and takes advantage of its stability and architecture. This integration with Kubernetes makes [Kubeless] incredibly easy if you are already familiar with Kubernetes.

![](/images/content/kubeless-overview.png)

[Kubeless] comes with its own CLI for interacting with Functions, providing commands such as `kubeless function ls`:

 ```bash
 kubeless function ls -n the-project

NAME        NAMESPACE      HANDLER           RUNTIME      DEPENDENCIES                STATUS
wx-stats    the-project    wx-stats.stats     python3.6    python-dateutil==2.7.3     1/1 READY
                                                            elasticsearch==6.3.0
                                                            elasticsearch-dsl==6.2.1
```

 However, due to  [Kubeless] deep integration with Kubernetes, I often find myself executing kubectl commands simply out of habit:

```bash
kubectl get functions -n the-project
```

These commands are nearly synonymous, because Kubless Function are merely Kubernetes objects, or Custom Resources to be accurate, and many operations on them are as they would be with other resources in the cluster, like services, deployment or pods.

### Install Kubeless

[Kubeless] installs in the `kubeless` namespace by default and can be used to create functions in any namespace. I use [RBAC] for all my clusters, and if you are looking to set up a custom Kubernetes cluster, I recommend spending about an hour following my article [Production Hobby Cluster].

Setting up Kubeless in your [Production Hobby Cluster] or hosted solution is easy, and the [official installation instructions] are clear.

If you have a [Kubeless] cluster already available and only need the CLI, then I suggest a `brew install kubeless` for the MacOs users.

### Toolchain and Local Development

Developing [Kubeless] Functions can be performed with the same tools as any other services. I build my [Golang] and [Python] functions with the commercial [Jet Brains] IDEs [Goland] and [PyCharm] however free IDEs such as [Visual Studio Code] and [Atom] work great as well.

In this demo, my Functions are API endpoints that query [Elasticsearch], check out my article [Remote Query Elasticsearch on Kubernetes] on how I port-forward Kubernetes [Services] for remote access. If your Kubernetes cluster needs set up for remote access, I suggest reading [Kubernetes Team Access - RBAC for developers and QA].

## Python Function

The following Python code demonstrates a function that returns the last 24 hours of weather data for Los Angeles, specifically temperatures. The Elasticsearch query aggregates the data into buckets of two-degree Fahrenheit intervals for later use in histograms and further analysis.

The [Elasticsearch DSL] is an excellent library for working with Elasticsearch in [Python]. Although most of my Microservices are written in [Golang], [Python] provides a tremendous number of mature and well-documented libraries for working with data.

### Script `wx-stats.py`

The following script `wx-stats.py` contains the function `stats`. Further down, I issue a [Kubeless] deployment using this file and the function name to call.

`wx-stats.py`:
```python
#!/usr/bin/env python3
"""
Wx Stats from Elasticsearch

Local testing:
    kubectl port-forward service/elasticsearch 9200:9200 -n the-project
    HOST=localhost:9200 python ./wx-stats.py
"""
__author__ = "Craig Johnston"
__version__ = "0.0.1"
__license__ = "MIT"

import os
from elasticsearch import Elasticsearch
from elasticsearch_dsl import Search, connections

host = os.environ['HOST']
connections.create_connection(hosts=[host], timeout=20)
client = Elasticsearch()
s = Search(using=client)


def stats(event, context):
    """
        Return wx stats
        Uses the Python Elasticsearch DSL
        https://elasticsearch-dsl.readthedocs.io/en/latest/search_dsl.html
    """
    global s

    res = s.from_dict({
        "size": 0,
        "aggs": {
            "temps": {
                "histogram": {
                    "field": "rxtxMsg.payload.currently.temperature",
                    "interval": 2
                }
            }
        },
        "query": {
            "range": {
                "@timestamp": {
                    "gt": "now-24h"
                }
            }
        }
    }).execute()

    return res.to_dict()


if __name__ == '__main__':
    """
    Mock event and context for development
    See: https://kubeless.io/docs/kubeless-functions/
    """
    event = {}
    context = {}
    
    # json is needed only for development and testing
    # not necessary to import for Kubeless functions
    import json
    
    json_string = json.dumps(stats(event, context), indent=2)
    print(json_string)

```

At this point I am not taking advantage of the [Elasticsearch DSL], being flexible it allows me to write raw Elasticsearch queries. The [Elasticsearch DSL] is excellent for quick ports from other systems or experimenting while you are learning the syntax.

### Dependencies `requirements.txt`

Python's [pip] package manager can generate and use a `requirements.txt` file to manage dependencies.

`requirements.txt`:
```text
elasticsearch==6.3.0
elasticsearch-dsl==6.2.1
```

Ensure you meet these dependencies by issuing the `pip install` command:

```bash
pip install -r requirements.txt
```

The `requirements.txt` file is given to the Kubeless function on deployment and updates, to ensure the [Kubeless runtime] for Python contains the required packages.

## Local Development and Testing

The python script `wx-stats.py` can be run on the command line. In a separate terminal you need to port-forward the Elasticsearch service to your local workstation:

```bash
kubectl port-forward service/elasticsearch 9200:9200 -n the-project
```

At this point **localhost:9200** responds as a local Elasticsearch would. In another terminal you can run the python script, when run as a script the function specified in the **if __name__ == '__main__':** conditional is executed, in this case **stats(event, context)**.

I wrap the returned [python dict] in **json.dumps** to encode as json as Kubeless will when called in the cluster.

Running the following command sets the environment variable **HOST** to the location of the Elasticsearch service. Kubless supports any number of environment variables specified in the function's deployment.

```bash
HOST=localhost:9200 python ./wx-stats.py
```

## Deploy and Update

As of now, using the `kubeless` command is one of the easiest ways to deploy and update the Kubless function.

```bash
kubeless function deploy wx-stats --runtime python3.6 \
                                  --from-file wx-stats.py \
                                  --dependencies requirements.txt \
                                  --handler wx-stats.stats \
                                  --env HOST=elasticsearch:9200 \
                                  -n the-project
```

The `kubeless` command provides many options for a function **deploy** and **update**, along with help for any sub-command:

```bash
kubeless function deploy -h
```

While it is acceptable to avoid the `kubeless` command and write [Kubless Function resources in yml], I find it easy enough to add `kubeless function update` to my build scripts. Want the best of both imperative and declarative and configuration? Add `kubeless function deploy` and `kubeless function update` command to a [Makefile].

## Testing

Now that we have deployed the Kubless function, disconnect from port-forwarding the Elasticsearch service and test the new function by port-forward the new service pointing to it.

```bash
kubectl port-forward service/wx-stats 8080:8080 -n the-project
```

Now that I have port 8080 on my local workstation forwarding to port 8080 on the Kubernetes service **wx-stats** in `the-project` namespace, I use curl (or a web browser) to call the new **wx-stats** function.

```bash
curl -s localhost:8080 | jsonpp
```

Piping the curl output to [jsonpp] makes the JSON output a bit more readable for debugging.

```json
{
  "took": 61,
  "timed_out": false,
  "_shards": {
    "total": 31,
    "successful": 31,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 719,
    "max_score": 0.0,
    "hits": []
  },
  "aggregations": {
    "temps": {
      "buckets": [
        {
          "key": 68.0,
          "doc_count": 24
        },
        {
          "key": 70.0,
          "doc_count": 101
        },
        {
          "key": 72.0,
          "doc_count": 81
        },
        {
          "key": 74.0,
          "doc_count": 93
        },
        {
          "key": 76.0,
          "doc_count": 50
        },
        {
          "key": 78.0,
          "doc_count": 38
        },
        {
          "key": 80.0,
          "doc_count": 39
        },
        {
          "key": 82.0,
          "doc_count": 44
        },
        {
          "key": 84.0,
          "doc_count": 50
        },
        {
          "key": 86.0,
          "doc_count": 88
        },
        {
          "key": 88.0,
          "doc_count": 110
        },
        {
          "key": 90.0,
          "doc_count": 1
        }
      ]
    }
  }
}
```

## Python Resources

Kubless supports a variety of [runtimes][Kubeless runtime]. In my case, most of my functions work with numbers, and It's tough to beat Python in simplifying the areas of statistics, analytics, and machine learning. Using [Kubeless] means you don't need to become an expert on writing large Python stacks. You can spend more time focusing on individual packages that help you develop your business logic directly. I believe Python does a great job in supporting the advantage of FaaS its support of **high-density business logic**.

- [Elasticsearch DSL] delivers a clean [pythonic] syntax for working with Elasticsearch.
- [Python Data Essentials - Numpy] provides a wide variety of options for working with numbers, extraordinarily powerful N-dimensional array objects in which we can perform linear algebra.
- [Python Data Essentials - Pandas] is a data type equivalent to super-charged spreadsheets. Pandas add two highly expressive data structures to Python, Series, and DataFrame.

[Python Data Essentials - Pandas]:https://mk.imti.co/python-data-essentials-pandas/
[Python Data Essentials - Numpy]:https://mk.imti.co/python-data-essentials-numpy/
[python dict]:https://docs.python.org/3/tutorial/datastructures.html#dictionaries
[Elasticsearch DSL]:https://elasticsearch-dsl.readthedocs.io/en/latest/search_dsl.html
[Services]:https://kubernetes.io/docs/concepts/services-networking/service/
[Remote Query Elasticsearch on Kubernetes]:https://mk.imti.co/remote-query-kubernetes-elasticsearch/
[Elasticsearch]:https://mk.imti.co/kubernetes-production-elasticsearch/
[Atom]:https://atom.io/
[Visual Studio Code]:https://code.visualstudio.com/
[PyCharm]:https://www.jetbrains.com/pycharm/
[Goland]:https://www.jetbrains.com/go/
[Jet Brains]:https://www.jetbrains.com/
[Python]:https://www.python.org/
[Golang]:https://golang.org/
[Production Hobby Cluster]:https://mk.imti.co/hobby-cluster/
[official installation instructions]:https://kubeless.io/docs/quick-start/
[Function as a Service]:https://en.wikipedia.org/wiki/Function_as_a_service
[Serverless computing]:https://en.wikipedia.org/wiki/Serverless_computing
[cost and infrastructure]:https://martinfowler.com/articles/serverless.html#ReducedOperationalCost
[AWS lambda]:https://aws.amazon.com/lambda/
[Google functions]:https://cloud.google.com/functions/
[kubeless]:https://kubeless.io/
[Nano Services]:https://www.infoq.com/news/2014/05/nano-services
[Kubeless Function]:https://kubeless.io/docs/quick-start/
[RBAC]:https://kubernetes.io/docs/reference/access-authn-authz/rbac/
[Serverless]:https://serverless.com/
[Kubernetes Team Access - RBAC for developers and QA]:https://mk.imti.co/team-kubernetes-remote-access/
[pip]:https://pypi.org/project/pip/
[Kubeless runtime]:https://github.com/kubeless/kubeless/blob/master/docs/runtimes.md
[Kubless Function resources in yml]:https://github.com/kubeless/kubeless/blob/master/examples/python/function.yaml
[Makefile]:https://en.wikipedia.org/wiki/Makefile
[pythonic]:https://blog.startifact.com/posts/older/what-is-pythonic.html
[jsonpp]:https://jmhodges.github.io/jsonpp/