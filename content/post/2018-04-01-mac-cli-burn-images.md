---
layout:     post
title:      "Burn SD Images on MacOs"
subtitle:   "Use the command line to burn SD cards, easy and fast."
date:       2018-04-01
author:     "Craig Johnston"
URL:        "mac-cli-burn-images/"
image:      "/img/post/foundry.jpg"
twitter_image: "/img/post/foundry_876_438.jpg"
tags:
- MacOS
- Utils
---

Use your terminal to burn images fast and easy with **[dd]**. I do a lot of professional and hobby development for projects using devices such as [Raspberry Pi], [Orange Pi], [Libre Computer], [Tinker Board], etc. I run across a lot of tutorials with people downloading and using big GUI apps with clunky drag and drop interfaces to burn images.

It's one command in your terminal. Technically, it's three, but I don't count listing and unmounting as the final act of burning.

## 1 - List Disks

Insert your SD card and from the command line use [diskUtil] to lists all your drives.

```bash
diskUtil list
```
<script src="https://gist.github.com/cjimti/059b841f492506936f2950c463b46d50.js"></script>

You are going to want to stay away from disk0 and disk1. You don't want to kill your hard drive. Also, watch out for other attached storage. I can see my 32g mounted as **/dev/disk3**.

## 2 - Unmount Disks

Unmount the SD card. In my case, it's **/dev/disk3**. If you have additional attached storage, your SD card might be disk 4, 5, or higher.

```bash
diskUtil unmounDisk /dev/disk3
```

## 3 - Burn Image

The last step is the fantastic little utility **[dd]**. [dd] copies any file to almost anywhere. We can use dd to stream the raw bytes from the image directed to our unmounted disk. On a Mac, the raw disk is accessed with an **r** in front of the device name. Raw access to my /dev/disk3 is /dev/**r**disk3. Give three arguments.

| Arg | Description / Value |
| --- | ---------------- |
| if= | **In file**: Specify the path to the file you want to send |
| of= | **Out file**: Specify the path to the file to be written. Yes, the device is a file. Remember in Unil/Linux/Max everything is a file. So /dev/rdisk99 is a file (it's a device, but we operate on it as a file) |
| bs= | **Block size**: dd streams the data it reads from if= in chunks. Depending on the capabilities of the device writing larger chunks will speed up the write. |

Example dd command to burn images:

```bash
sudo dd if=Armbian.img of=/dev/rdisk3 bs=5m
```

I find that a block size of 5m is the sweet spot for my card reader and the SD cards I use (SanDisk Ultra 32G).

You need to use **sudo** as only a privileged user can write directly to a device in this manner, which is good since you can easily overwrite your hard drive on disk 0 or 1.

Wait for **dd** to finish or hit Control-T from time-to-time for some status.

An 8GB image takes about 10-15 minutes on my workstation depending on the quality of the SD card. Cheap or damaged cards will take a very long time to write.

I have tried a few of the full GUI apps for burning but don't seem to get the speed and control of just typing a few commands.

### Resources

- [dd] on Wikipedia
- [diskUtil] official Manpage
- [Everything is a file] / "Everything is a file descriptor"
- [How do you monitor the progress of dd?]
- [Libre Computer Site]
- [Tinker Board Site]
- [Orange Pi Site]

{{< content-ad >}}

[Raspberry Pi]: https://amzn.to/2JwJeEu
[Libre Computer Site]: https://libre.computer/
[Libre Computer]: https://amzn.to/2GLp8Vg
[Tinker Board]: https://amzn.to/2HiX9NZ
[Tinker Board Site]: https://www.asus.com/us/Single-Board-Computer/Tinker-Board/
[Orange Pi]: https://amzn.to/2H5DL9v
[Orange Pi Site]: http://www.orangepi.org/
[How do you monitor the progress of dd?]: https://askubuntu.com/questions/215505/how-do-you-monitor-the-progress-of-dd
[Everything is a file]: https://en.wikipedia.org/wiki/Everything_is_a_file
[dd]: https://en.wikipedia.org/wiki/Dd_(Unix)
[diskUtil]: https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/diskutil.8.html
