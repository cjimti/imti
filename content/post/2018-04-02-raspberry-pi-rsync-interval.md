---
layout:     post
title:      "rSync Files on Interval"
subtitle:   "Sync media to Raspberry Pi or any ARM SoC."
date:       2018-04-02
author:     "Craig Johnston"
URL:        "raspberry-pi-rsync-interval/"
image:      "/img/post/blocks.jpg"
twitter_image: "/img/post/blocks_876_438.jpg"
tags:
- Raspberry Pi
- Utils
---

A recurring requirement for my [IOT] projects involves keeping a set of files synced with a central server. Many of these projects include media players, kiosk systems, or applications that need frequently updated configuration files, all while entirely unattended, and in most cases unreachable through firewalls. I have one project that alone has 2000+ devices pulling media continuously from an [rsync] server. Many of these devices are on doggy wifi networks.

The [rsync] utility works excellent on [Raspberry Pi] as well as an assortment of [Armbian] installed devices. However, writing scripts to manage [rsync] when it fails, or restarting it on some interval when it finishes can be a pain. I have a dozen rickety, cobbled-together [bash] hacks that have somewhat worked in the past. I needed something more stable, portable and upgradeable.


Open Source: https://github.com/txn2/irsync

[![irsync: interval rsync](https://raw.githubusercontent.com/cjimti/irsync/master/irsync-mast.jpg)](https://github.com/cjimti/irsync)

I built [irsync] to operate on any ([amd64/x86-64] or [armhf]) system that has [Docker] running on it.

If we stick with the defaults, the interval duration is 30 seconds and the activity timeout is 2 hours.

**An example [Docker] run command local to local:**

```bash
docker run --rm -v "$(pwd)"/data:/data cjimti/irsync \
    -pvrt --delete /data/source/ /data/dest/
```

**An example [Docker] run to sync server to local:**

```bash
docker run --rm -e RSYNC_PASSWORD=password \
    -v "$(pwd)"/data:/data cjimti/irsync \
    -pvrt --delete rsync://user@example.com:873/data/ /data/dest/
```

**docker-compose example:**

```yaml
# Use for testing Interval rSync
#
# This docker compose file creates server and
# client services, mounting ./data/dest and ./data/source
# respectivly.
#
# source: https://hub.docker.com/r/cjimti/irsync/
# irsync docker image: https://hub.docker.com/r/cjimti/irsync/
# rsyncd docker image: https://hub.docker.com/r/cjimti/rsyncd/ (or use any rsync server)
#
version: '3'

# Setting up an internal network allow us to use the
# default port and not wory about exposing ports on our
# host.
#
networks:
  sync-net:

services:
  server:
    image: "txn2/rsyncd"
    container_name: rsyncd-server
    environment:
      - USERNAME=test
      - PASSWORD=password
      - VOLUME_PATH=/source_data
      - READ_ONLY=true
      - CHROOT=yes
      - VOLUME_NAME=source_data
      - HOSTS_ALLOW=0.0.0.0/0
    volumes:
      - ./data/source:/source_data
    networks:
      - sync-net
  client:
    image: "txn2/irsync"
    container_name: irsync-client
    environment:
      - RSYNC_PASSWORD=password

    # irsync and rsync options can be intermixed.
    #
    # irsync - has two configuration directives:
    #     --irsync-interval-seconds=SECONDS  number of seconds between intervals
    #     --irsync-timeout-seconds=SECONDS   number of seconds allowed for inactivity
    #
    # rsync has over one hundred options:
    #     see: https://download.samba.org/pub/rsync/rsync.html
    #
    command: [
      "--irsync-interval-seconds=30",
      "-pvrt",
      "--delete",
      "--modify-window=2",
      "rsync://test@rsyncd-server:873/source_data/",
      "/data/"
    ]
    volumes:
      - ./data/dest:/data
    depends_on:
      - server
    networks:
      - sync-net
```

Say you need to ensure your device (or another server) always has the latest files from the server. However, syncing hundreds or even thousands of files could take hours or days. First, [rsync] will only grab the data you don't have, or may have an outdated version of, you can never assume the state of the data on your device. [irsync] will use it's built-in [rsync] to do the heavy lifting of determining your state versus the server. But [rsync] is not perfect, and dealing with an unstable network can sometimes cause it to hang or fail. The good news is that, if restarted, [rsync] will pick up where it left off.

In the IOT device world you can't sit watch the transfer and restart it when needed, this is what [irsync] was built for.

[irsync] manages the output of it's internal [rsync] and will restart a synchronization process if the timeout exceeds the specified directive. Most of the files I need to be synchronized are under 200 megabytes, so I sent my timeout to 2 hours per file. If a file takes longer than 2 hours to sync then I assume, there is a network or connection failure and let [irsync] start the process over.

[irsync] allows me to start a file synchronization on an interval. In other words, I want my device to sync every 2 minutes, but I don't want to start an [rsync] every 2 minutes. So if the sync takes 2 hours, then 2 hours and 2 minutes later another synchronization attempt will be made. When my device is up-to-date, these calls are relatively light on the device, and my client knows that only 2 minutes after they update their media it will likely be on it's way to their devices.

## Demo

You can run a simple little demo on your local workstation using a docker-compose file I put together.

```bash
# create a source and dest directories (mounted from the docker-compose)
mkdir -p ./data/source
mkdir -p ./data/dest

# make a couple of sample files
touch ./data/source/test1.txt
touch ./data/source/test2.txt

# get the docker-compose.yml
curl https://raw.githubusercontent.com/txn2/irsync/master/docker-compose.yml >docker-compose.yml

# run docker-compose in the background (-d flag)
docker-compose up -d

# view logs
docker-compose logs -f

# drop some more files in the ./data/source directory
# irsync is configured to check every 30 seconds in this demo.

#### Cleanup

# stop containers
# docker-compose stop

# remove containers
# docker-compose rm

```

I recorded a video performing the demo above:

<style>.embed-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; } .embed-container iframe, .embed-container object, .embed-container embed { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }</style><div class='embed-container'><iframe src='https://www.youtube.com/embed/gT_P2a-xpPw?rel=0' frameborder='0' allowfullscreen></iframe></div>

## Custom Docker Container

Another useful implementation method involves creating a custom Docker image for each source and destination synchronizations you want to keep running. See the following example Dockerfile:

```Dockerfile
FROM txn2/irsync
LABEL vendor="txn2.com"
LABEL com.txn2.irsync="https://github.com/txn2/irsync"

# if the rsync server requires a password
ENV RSYNC_PASSWORD=password

# exampe: keep local synchronized with server
# interval default: --irsync-interval-seconds=120
# activity timout default: --irsync-timeout-seconds=7200
CMD ["-pvrt", "--modify-window=30", "--delete", "--exclude='fun'", "rsync://sync@imti.co:873/data/", "/media"]
```

**Build:**

```bash
docker build -t custom-sync .
```

**Run:**

```bash
docker run -d --name custom-sync --restart on-failure \
    -v "$(pwd)"/data:/data custom-sync
```


## Wear it

If you have read this far, you might be be the kind of person to appreciate a high-end fashion statement:

<a target="_blank"  href="https://www.amazon.com/gp/product/B07BZ8R8B2/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B07BZ8R8B2&linkCode=as2&tag=imti-20&linkId=2ae79aaf417450259d43834db6c71e74"><img border="0" src="//ws-na.amazon-adsystem.com/widgets/q?_encoding=UTF8&MarketPlace=US&ASIN=B07BZ8R8B2&ServiceVersion=20070822&ID=AsinImage&WS=1&Format=_SL250_&tag=imti-20" ></a><img src="//ir-na.amazon-adsystem.com/e/ir?t=imti-20&l=am2&o=1&a=B07BZ8R8B2" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />

### Resources

- [Raspberry Pi]
- [Backup & Recovery: Inexpensive Backup Solutions for Open Systems] by O'Reilly Media
- [irsync]
- [rsync] on Wikipedia
- [Armbian]
- [Docker]
- [irsync t-shirt]

[Backup & Recovery: Inexpensive Backup Solutions for Open Systems]: https://amzn.to/2Esq5jq
[armhf]: https://en.wikipedia.org/wiki/ARM_architecture
[amd64/x86-64]: https://en.wikipedia.org/wiki/X86-64
[irsync]: https://github.com/cjimti/irsync
[rsync]: https://en.wikipedia.org/wiki/Rsync
[Raspberry Pi]: https://amzn.to/2qlJT3d
[Armbian]: https://www.armbian.com/
[bash]: https://www.gnu.org/software/bash/
[IOT]: https://en.wikipedia.org/wiki/Internet_of_things
[Docker]: https://www.docker.com/
[irsync t-shirt]: https://amzn.to/2ErshYH