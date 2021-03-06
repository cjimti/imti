---
draft:    false
layout:   post
title:    "Ethereum Ethstats"
subtitle: "Learning the Ethereum Blockchain through its metrics."
date:     2018-09-22
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

The [eth-netstats] project provides a great dashboard interface for monitoring the status of an Ethereum Blockchain from the perspective of its nodes. The website https://ethstats.net/ reports statistics from an extensive list of Ethereum nodes on the public [Ethereum] Blockchain, however, the [eth-netstats] software that drives https://ethstats.net/ can also be used to monitor a [Private Ethereum Blockchchain] as I demonstrate in the previous article [Deploy a Private Ethereum Blockchain on a Custom Kubernetes Cluster][Private Ethereum Blockchchain].

The [eth-netstats] service consumes Ethereum statistical metrics provided by individual Ethereum nodes. Check out the documentation on [Geth] if you are interested in running an Ethereum miner or transaction only node and pointing it's statistical output to an [eth-netstats] instance.

In this article, I review each of the metrics displayed by [eth-netstats], as both a means to better understand the [eth-netstats] utility as well as Ethereum itself.

[![Ethstats Dashboard](/img/post/ethstats.jpg)](https://ethstats.net/)

{{< content-ad >}}

See Ethstats in action at [https://ethstats.net/](https://ethstats.net/) for a live example of Ethereum Blockchain metrics from miners on the public Ethereum blockchain.

The following table is a brief overview of the metrics displayed by [eth-netstats] starting from the top left, moving from left to right, row by row.

<table>
<thead>
    <tr>
        <th width="30%">Image</th>
        <th>Metric</th>
        <th>Description</th>
    </tr>
</thead>
    <tr>
        <td><img src="/img/post/ethstats/01_best_block.jpg" alt="best block"/></td>
        <td><h3>Best Block</h3></td>
        <td><p>The Best Block is last valid block with the highest amount of accumulated work in it on the main Ethereum Blockchain.</p>
        <ul>
            <li><a href="https://www.coindesk.com/information/ethereum-mining-works/">How Ethereum Mining Works</a></li>
            <li><a href="https://blockgeeks.com/guides/what-is-blockchain-technology/">What is Blockchain Technology? A Step-by-Step Guide For Beginners</a></li>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/02_uncles.jpg" alt="Ethereum Uncles"/></td>
        <td><h3>Uncles</h3></td>
        <td><p>Uncles are orphaned blocks that were mined just after someone else found the correct block header. Ethereum treats orphaned blocks different than other blockchain systems by including them in the blockchain and rewarding miner for them. Ethstats displays the current block's uncle count and uncle count of the last 50 blocks.</p>
        <ul>
            <li><a href="https://nulltx.com/what-are-ethereum-uncles/">What are Ethereum Uncles?</a></li>
            <li><a href="https://medium.com/ibbc-io/ethereum-uncles-how-family-makes-you-stronger-d6e7aaef7b2b">Ethereum & uncles: how family makes you stronger</a></li>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/03_last_block.jpg" alt="last block"/></td>
        <td><h3>Last Block</h3></td>
        <td><p>Ethstats displays the elapsed time since the last block was mined.</p>
        <ul>
        <li><a href="https://etherscan.io/chart/blocks">Ethereum Block Count</a></li>
        <li><a href="https://etherscan.io/chart/blocktime">Ethereum BlockTime History</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/04_avg_block_time.jpg" alt="average block time"/></td>
        <td><h3>Average Block Time</h3></td>
        <td><p>The average time between block generation, not including uncles.</p>
        <ul>
        <li><a href="https://medium.facilelogin.com/the-mystery-behind-block-time-63351e35603a">The Mystery Behind Block Time</a></li>
        <li><a href="https://www.etherchain.org/charts/blockTime">Average block time of the (Public) Ethereum Network</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/05_avg_network_hashrate.jpg" alt="Average Network Hashrate"/></td>
        <td><h3>Average Network Hashrate</h3></td>
        <td><p>The number of hashes per second processed by miners on the network in order to find a new block. The Network in this case being miners reporting to Ethstats.</p>
        <ul>
        <li><a href="https://github.com/ethereum/wiki/wiki/Mining">Mining</a></li>
        <li><a href="https://www.buybitcoinworldwide.com/mining/hash-rate/">What is Hash Rate?</a></li>
        <li><a href="https://ethereum.stackexchange.com/questions/18162/how-is-average-network-hashrate-determined">How is average network hashrate determined? - Ethereum Stack Exchange</a></li>
        <li><a href="https://etherscan.io/chart/hashrate">Ethereum Network HashRate Growth Chart - Etherscan</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/06_difficulty.jpg" alt="Ethereum Difficulty"/></td>
        <td><h3>Difficulty</h3></td>
        <td><p>The current difficulty to mine a new block by finding a matching hash.</p>
        <ul>
        <li><a href="https://en.bitcoin.it/wiki/Difficulty">Difficulty
 - Bitcoin Wiki</a></li>
        <li><a href="https://bitcoin.stackexchange.com/questions/23099/what-does-the-mining-difficulty-number-really-mean">What does the mining difficulty number really mean?
</a></li>
        <li><a href="https://www.investopedia.com/news/what-ethereums-difficulty-bomb/">What Is Ethereum's "Difficulty Bomb"?</a></li>
        <li><a href="https://ethereum.stackexchange.com/questions/1880/how-is-the-mining-difficulty-calculated-on-ethereum">How is the Mining Difficulty calculated on Ethereum?</a></li>
        </ul>
        </td>
    </tr>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/07_active_nodes.jpg" alt="Active Ethereum nodes"/></td>
        <td><h3>Active Nodes</h3></td>
        <td>
        <p>The number of nodes currently connected to the Ethstats service.</p>
        <ul>
        <li><a href="https://ethstats.net/">Public Ethstats</a></li>
        <li><a href="https://imti.co/ethereum-kubernetes/#ethstats-dashboard">Private Ethstats</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/08_gas_price.jpg" alt="Gas Price"/></td>
        <td><h3>Gas Price</h3></td>
        <td>
        <p>Gas Price is the current price miners will accept for processing a transaction.</p>
        <ul>
        <li><a href="https://kb.myetherwallet.com/gas/what-is-gas-ethereum.html">What is Gas?</a></li>
        <li><a href="https://www.cryptocompare.com/coins/guides/what-is-the-gas-in-ethereum/">What is the “Gas” in Ethereum?</a></li>
        <li><a href="https://medium.com/gitcoin/a-brief-history-of-gas-prices-on-ethereum-52e278a04306">A Brief History Of Gas Prices on Ethereum</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/09_page_latency.jpg" alt="Ethstats Page Latency"/></td>
        <td><h3>Page Latency</h3></td>
        <td>
        <p>The latency in time between a rendered Etherstats front-end dashboard (in your web browser) and it's backend data service.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/10_uptime.jpg" alt="Ethstatus Uptime"/></td>
        <td><h3>Uptime</h3></td>
        <td>
        <p>The amount of time Etherstats has been running since started or re-started.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/11_map.jpg" alt=""/></td>
        <td><h3>Geo Locations</h3></td>
        <td>
        <p>Location of Ethereum nodes reporting to Etherstats.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/12_blocktime.jpg" alt=""/></td>
        <td><h3>Blocktime Chart</h3></td>
        <td>
        <p>Blocktime averages over time.</p>
        <ul>
        <li><a href="https://bitinfocharts.com/comparison/ethereum-confirmationtime.html">Ethereum Block Time historical chart</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/13_difficulty.jpg" alt=""/></td>
        <td><h3>Difficulty Chart</h3></td>
        <td>
        <p>Difficulty over time.</p>
        <ul>
        <li><a href="https://dltlabs.com/how-difficulty-adjustment-algorithm-works-in-ethereum/">How Difficulty Adjustment Algorithm Works in Ethereum</a></li>
        <li><a href="https://etherscan.io/chart/difficulty">Ethereum Block Time historical chart</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/14_block_propagation.jpg" alt=""/></td>
        <td><h3>Block Propagation</h3></td>
        <td>
        <p>Block Propagation tracks the speed in which blocks are shared between nodes connected to Ethstats.</p>
        <ul>
        <li><a href="https://ethereum.stackexchange.com/questions/28666/whats-the-transaction-throughput-on-ethereum-how-fast-the-nodes-can-replicate">What's the transaction-throughput on Ethereum (how fast the nodes can replicate transactions, not transactions per second)</a></li>
        <li><a href="https://medium.com/blockchannel/life-cycle-of-an-ethereum-transaction-e5c66bae0f6e">Life Cycle of an Ethereum Transaction</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/15_last_blocks_miners.jpg" alt="Ethereum Ethstats Last Block Miners"/></td>
        <td><h3>Last Blocks Miners</h3></td>
        <td>
        <p>Nodes that found the most Block, not including Uncles. </p>
        <ul>
        <li><a href="https://www.etherchain.org/charts/topMiners">Top Miners over the last 24h</a></li>
        <li><a href="https://etherscan.io/blocks">Last Public Blocks</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/16_uncle_count.jpg" alt="Ethstats Uncle Count"/></td>
        <td><h3>Uncle Count</h3></td>
        <td>
        <p>Uncle Count displays the number of Uncles generated. Each bar represents 25 blocks.</p>
        <ul>
        <li><a href="https://etherscan.io/chart/uncles">Ethereum Uncles Count</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/17_transactions.jpg" alt="Ethstats Ethereum Transactions"/></td>
        <td><h3>Transactions</h3></td>
        <td>
        <p>Displays the number of transactions included in the latest blocks.</p>
        <ul>
        <li><a href="https://etherscan.io/txs">Ethereum Transactions</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/18_gas_spending.jpg" alt=""/></td>
        <td><h3>Gas Spending</h3></td>
        <td>
        <p>The amount of Gas spent on transactions in recent blocks.</p>
        <ul>
        <li><a href="https://ethgasstation.info/index.php">ETH Gas Station</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/19_node_name.jpg" alt="Ethereum Ethstats Node Name"/></td>
        <td><h3>Node Name</h3></td>
        <td>
        <p></p>
        <ul>The name of the node reporting to Ethstats.
        <li><a href="https://github.com/ethereum/go-ethereum/wiki/Command-Line-Options">Geth Documentation</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/20_node_type_arch.jpg" alt=""/></td>
        <td><h3>Node Type</h3></td>
        <td>
        <p>Type and architecture of connected Ethereum nodes. Common node types are Geth, Ethminer and Parity.</p>
        <ul>
        <li><a href="https://github.com/ethereum/go-ethereum/wiki/geth">Geth -  is the the command line interface for running a full ethereum node implemented in Go.</a></li>
        <li><a href="https://github.com/ethereum-mining/ethminer">ethminer - is an Ethash GPU mining worker: with ethminer you can mine every coin which relies on an Ethash Proof of Work thus including Ethereum, Ethereum Classic, Metaverse, Musicoin, Ellaism, Pirl, Expanse and others.</a></li>
        <li><a href="https://www.parity.io/">https://www.parity.io/ethereum/</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/21_node_latency.jpg" alt=""/></td>
        <td><h3>Node Latency</h3></td>
        <td>
        <p>The latency in time between the reporting node and Ethstats.</p>
        <ul>
        <li><a href="https://ethereum.stackexchange.com/questions/18201/does-network-latency-significantly-affect-mining-rewards">Does network latency significantly affect mining rewards?
</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/22_node_miner_hash_rate.jpg" alt=""/></td>
        <td><h3>Node Miner Hash Rate</h3></td>
        <td>
        <p>The hash rate the node reporting to Ethstats.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/23_node_peers.jpg" alt=""/></td>
        <td><h3>Node Peers</h3></td>
        <td>
        <p>Number of peers connected to a specific node.</p>
        <ul>
        <li><a href="https://github.com/ethereum/go-ethereum/wiki/Connecting-to-the-network">Connecting to the network</a></li>
        <li><a href="https://www.ethernodes.org/network/1">Ethereum Nodes</a></li>
        </ul>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/24_pending_transactions.jpg" alt=""/></td>
        <td><h3>Pending Transactions</h3></td>
        <td>
        <p>Number of transaction pending for a specific node.</p>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/25_node_last_block.jpg" alt=""/></td>
        <td><h3>Node Last Block</h3></td>
        <td>
        <p>The Last Bock a specific node is aware of.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/26_block_transactions.jpg" alt=""/></td>
        <td><h3>Block Transactions</h3></td>
        <td>
        <p>Number of transactions a blow is aware of and pending. These transactions will be added to the next block.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/27_uncles.jpg" alt=""/></td>
        <td><h3>Node Uncles</h3></td>
        <td>
        <p>Number of Uncles a node has reported creating.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/28_last_block_time.jpg" alt=""/></td>
        <td><h3>Last Block Time</h3></td>
        <td>
        <p>The last time a node was aware of a Block being created.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/29_propagation_time.jpg" alt=""/></td>
        <td><h3>Propagation Time</h3></td>
        <td>
        <p>How long block takes to propagate to a node over time.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/30_avg_propagation_time.jpg" alt=""/></td>
        <td><h3>Average Propagation Time</h3></td>
        <td>
        <p>The average time it takes to propagate a block to this node.</p>
        </td>
    </tr>
    <tr>
        <td><img src="/img/post/ethstats/31_node_uptime.jpg" alt=""/></td>
        <td><h3>Node Uptime</h3></td>
        <td>
        <p>Node Uptime reports the percentage of time a node has reported as running since connected to Ethstats.</p>
        </td>
    </tr>
</table>

[geth]:https://github.com/ethereum/go-ethereum/wiki/geth
[eth-netstats]:https://github.com/cubedro/eth-netstats
[Private Ethereum Blockchchain]: https://imti.co/ethereum-kubernetes/
[Ethereum]:https://ethereum.org