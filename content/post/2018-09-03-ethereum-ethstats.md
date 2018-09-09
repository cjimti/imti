---
draft: true
layout:   post
title:    "Ethereum Ethstats"
subtitle: "Describing the metrics."
date:     2018-09-04
author:   "Craig Johnston"
URL:      "ethereum-ethstats/"
image:    "/img/post/ethstatsbg.jpg"
twitter_image:  "/img/post/ethstats_876_438.jpg"
tags:
- Ethereum
- Blockchain
series:
- Blockchain
---

The [eth-netstats] project provides an incredible dashboard interface for monitoring Ethereum nodes. [eth-netstats] consumes stats provided by the Ethereum [geth] nodes. [Geth] is the the command line interface for running a full Ethereum node implemented in Go and often deployed as **miner** and **transaction only** nodes.

[![Ethstats Dashboard](/img/post/ethstats.jpg)](https://ethstats.net/)

See Ethstats in action at [https://ethstats.net/](https://ethstats.net/).

Ethstats is a great tool for monitoring a private Ethereum network. The following table is brief overview of the displayed metrics if you are new to Blockchain or Ethereum terminology.

<table>
<thead>
    <tr>
        <th width="30%">Image</th>
        <th>Metric</th>
        <th>Description</th>
    </tr>
</thead>
    <tr>
        <td><img src="/img/post/ethstats_best_block.jpg" alt="best block"/></td>
        <td>Best Block</td>
        <td>Is the heaviest block regarding the cummultative difficulty, or in simple words: the highest block number of the longest valid chain.</td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats_uncles.jpg" alt="uncles"/></td>
        <td>Uncles</td>
        <td>are orphaned blocks, but in oposite to other blockchain systems, uncles are rewarded and included in the blockchain. Shows current bloc's uncle count and uncle count of last 50 blocks.</td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats_last_block.jpg" alt="last block"/></td>
        <td>Last Block</td>
        <td>shows the time since the last block was mined, usually in seconds.</td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats_avg_block_time.jpg" alt="average block time"/></td>
        <td>Average Block Time</td>
        <td>is, well, the average time between two blocks, excluding uncles, in seconds. Should be something around 15 seconds.</td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats_avg_network_hashrate.jpg" alt="average network hashrate"/></td>
        <td>Average Network Hashrate</td>
        <td>is the number of hashes bruteforced by the network miners to find a new block. 5 TH/s means the network power is at five trillion hashes per second.</td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats_difficulty.jpg" alt="difficulty"/></td>
        <td>Difficulty</td>
        <td>is the current mining difficulty to find a new block which basicly means how hard it is to find a matching hash. </td>
    </tr>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats_active_nodes.jpg" alt="active nodes"/></td>
        <td></td>
        <td></td>
    </tr>
</table>

|| Metric | Description |
|---|---|---|
|| Active Nodes  | is the number of connected nodes to the Ethstats dashboard, (not the whole ethereum network!) |
|| Gas Price | is the price miners accept for gas. While gas is used to calculate fees. 20 gwei is the current default, which stands for 20 Giga-Wei which are twenty billion wei that is 0.00000002 ETH. |
|| Gas Limit  | is the block gas limit. It defaults to 1.5 pi million gas (4,712,388) and miner can only include transactions until the gas limit is met (and the block is full). The gas limit is the analogy to bitcoin's block size limit, but not fixed in size. |
||  Page Latency and Uptime | are specific stats for the dashboard. |
|| Block Time Chart | shows the actual time between the last blocks. |
|| Difficulty Chart  | shows the actual difficulty of the last blocks. |
|| Block Propagation Chart  | shows how fast blocks are shared among the nodes connected to the dashboard. |
|| Last Block Miners  | are the public keys of the miners who found most of the last blocks. |
|| Uncle Count Chart | shows numbers of uncles per 25 blocks per bar. |
|| Transactions Chart | shows numbers of transactions included in last blocks. |
|| Gas Spending Chart | shows how much gas was spent on transactions in each block, note the correlation to the transactions chart. |
|| Gas Limit Chart | shows the dynamicly adjusted block gas limit for each block. |

[geth]:https://github.com/ethereum/go-ethereum/wiki/geth
[eth-netstats]:https://github.com/cubedro/eth-netstats
