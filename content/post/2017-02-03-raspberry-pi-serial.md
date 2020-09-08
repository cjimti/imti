---
layout:     page
title:      "Raspberry Pi - Serial Number"
subtitle:   "Getting the unique serial number from a Raspberry Pi."
date:       2017-02-13
author:     "Craig Johnston"
URL:        "raspberry-pi-serial/"
aliases:
  - "/post/145472439098/raspberry-pi-serial-number"
image:      "/img/pi.jpg"
twitter_image: "/img/post/pi_876_438.jpg"
tags:
- Raspberry Pi
- Development
- IOT
series:
- Raspberry Pi
---

Getting the unique serial number from a Raspberry Pi.

    cat /proc/cpuinfo | grep ^Serial | cut -d":" -f2

Example output:

     00000000e215b4a2

An interesting use for this is "binding" software, encryption or other servcies to a specific Pi. Found this in a suggestion on the Stack Overflow question ["Securing data on SD card Raspberry Pi"](http://stackoverflow.com/questions/27730877/securing-data-on-sd-card-raspberry-pi)

{{< content-ad >}}