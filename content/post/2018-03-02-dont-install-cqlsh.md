---
layout:     post
title:      "Don't Install cqlsh"
subtitle:   "Containers as utility applications"
date:       2018-03-01
author:     "Craig Johnston"
URL:        "dont-install-cqlsh/"
aliases:
  - "/post/149439588728/cassandra-keyspaces-tables"
  - "/post/152084743878/cassandra-install-cassandra-39-on-centos-6x"
image:      "/img/post/eye.jpg"
twitter_image: "/img/post/eye_876_438.jpg"
tags:
- Cassandra
- Docker
- Data
series:
- Cassandra
---

We live in a world of process isolation and tools that make utilizing it extremely simple, with apps like [Docker] we can perform dependency management with **dependency isolation**. As I am slowly becoming a fanboy of containerization, I look forward to the day when typing `ps` on my local workstation or remote server is nearly synonymous with commands like `docker ps` or `kubectl get services`.

Case: **Cassandra development and your local workstation.**

{{< content-ad >}}

I use [Apache Cassandra] almost daily for my job. A lot of our services require this high performance, highly available database. The command line tool [`cqlsh`] is the official tool for interacting with Cassandra. [`cqlsh`] is an easy and intuitive terminal into [Apache Cassandra], but it has dependencies, one of which is [Python]. Over the years of local development on my MacBook Pro, I have had many tools that require [Python] and Python libraries. Some of these tools I installed years ago require older versions of Python, or older Python libraries not able to run in newer Python versions. [Python] is a great language, but sooner or later you run into dependency nightmares, (see [The Nine Circles of Python Dependency Hell]) including missing libs, version conflicts, and the list goes on. It makes sense to resolve these issues or use a [Python version manager](https://github.com/pyenv/pyenv) like Ruby's [RVM](https://rvm.io/) if you are actively developing locally in [Python]. But wait, **I'm not developing in Python at the moment**, I just want to run [`cqlsh`], and it is not the weekend, so I am not motivated to Google my Python version conflicts and library dependency errors because I have a ton of work to get done. Yes, my problems, likely caused by something dumb I did playing around with the questionable code I found in the far-off corners of Github.

So I'm going to ignore my confused local install of `cqlsh`, the broken state of my Python and the mess I made of its libraries. I'm just going to run:

```bash
docker run -it --rm cassandra cqlsh node1.example.com -u itsme -p mypassword`
```

It's a one time pull of the [Cassandra Docker] image and once done the `--rm` flag cleans up the stopped container. 

But that's a lot of command for me to think about when I just need my `cqlsh` so I add a simple alias to my `.bashrc`

```bash
alias cqlsh='docker run -it --rm cassandra cqlsh` 
```

From now on I run the command `cqlsh` and get just that, will all its dependencies in isolation, not worried about Python versions or state of my local workstation. Just keep Docker running well, and I'm good.

The alias above is helpful for the times I just want a cqlsh terminal to issue a few commands. However, I often need to pass cql scripts into [`cqlsh`]. So I updated my alias to always mount my current directory into a `/src` directory in the container. All I have have to remember is that that path to a local file is `./src` and not `./`. 

```bash
alias cqlsh='docker run -it --rm -v "$(pwd)":/src cassandra cqlsh
```

This allows me to run commands that pass in files, like:

```bash
$ cqlsh node1.example.com 9042 -f /src/setup_some_keyspace_and_tables.cql
```

The [Cassandra Docker] image is 323MB, and when run without a command will start up a fully functional Cassandra node, which is useful for testing. However, if this is not something you need, then a 323MB image is a bit overkill. You can always make a small Docker image using [Alpine Linux], adding only the packages you need. However, that is a subject of another article I suppose.

[Docker]: https://www.docker.com/
[Apache Cassandra]: http://cassandra.apache.org/
[Python]: https://www.python.org/
[`cqlsh`]: http://cassandra.apache.org/doc/latest/tools/cqlsh.html
[Cassandra Docker]: https://hub.docker.com/_/cassandra/
[The Nine Circles of Python Dependency Hell]: https://medium.com/knerd/the-nine-circles-of-python-dependency-hell-481d53e3e025

{{< content-ad >}}