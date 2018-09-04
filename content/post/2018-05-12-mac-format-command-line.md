---
layout:     post
title:      "Formatting Drives on MacOS"
subtitle:   "A stack of old drives, a terminal and diskutil."
date:       2018-05-12
author:     "Craig Johnston"
URL:        "mac-format-command-line/"
image:      "/img/post/drives.jpg"
twitter_image: "/img/post/drives_876_438.jpg"
tags:
- MacOs
- Utils
---

I have had this collection of old external drives hanging around for years. There was a time I was having terrible luck with hard drives. It turned out I managed to amass a collection of about eight drives from one terabyte to four terabytes.

Fortunately, I keep copies of nearly all my files on cloud drives, split between [Amazon](https://amzn.to/2KiZ31d), Google and DropBox. I had a sneaking suspicion that the discs themselves were ok and somehow my Mac was communicating with the RAID controllers in a way that caused them to fail.

This weekend I received a [Cable Matters USB 3.0 SATA HDD/SSD Docking Station](https://amzn.to/2Ge0aNb) I ordered a few days ago. I removed all my drives from their old cases and plugged them directly into my new dock. Out of my eight drives, only two were unusable.

I did quick work of re-setting my stack of drives. I do my work on the command line when I can, and the MacOs command `diskutil` works great for this.

My Mac complained about most of the drives I plugged in, but `diskutil` was able to see them fine.

Run `diskutil list` for a listing of internal and external drives and their partitions.

```bash
$ diskutil list

/dev/disk0 (internal):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                         1.0 TB     disk0
   1:                        EFI EFI                     314.6 MB   disk0s1
   2:                 Apple_APFS Container disk1         1.0 TB     disk0s2

/dev/disk1 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +1.0 TB     disk1
                                 Physical Store disk0s2
   1:                APFS Volume Macintosh HD            376.2 GB   disk1s1
   2:                APFS Volume Preboot                 21.7 MB    disk1s2
   3:                APFS Volume Recovery                517.8 MB   disk1s3
   4:                APFS Volume VM                      7.5 GB     disk1s4

/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *3.0 TB     disk2
   1:                        EFI EFI                     314.6 MB   disk2s1
   2:                  Apple_HFS                         3.0 TB     disk2s2
   
```

Mounted on `/dev/disk2` is a [three terabyte Seagate](https://amzn.to/2KV0u7b) that was part of a failed RAID. The data is corrupt, but the disk is in working order. It just needs a new format.

`diskutility` has a ton of options and [OSX Daily has a great article and cheatsheet](http://osxdaily.com/2016/08/30/erase-disk-command-line-mac/) for some of the most common commands.

I used the following command to format my stack of drives and now have a ton of extra backup storage.

**Mac OS Extended Journaled (JHFS+)**:

```bash
diskutil eraseDisk JHFS+ 3TBackup /dev/disk2
```

I'll probably stick with just using bare hard drives and a dock from now on. Drives are pretty cheap these days, and if you don't need to keep your drive in a backpack, then I can attest they sit nicely on my bookshelf neatly labeled on their sides.


