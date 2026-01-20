---
layout:     post
title:      "MCP Is Flawed. Build With It Anyway."
subtitle:   "Context has always been the hard problem. MCP forces you to solve it."
description: "The Model Context Protocol has real security issues, scalability limits, and rough edges. None of that changes the fact that building custom MCP servers for internal data platforms is the right call in 2026. Here's why."
date:       2026-01-20
author:     "Craig Johnston"
URL:        "mcp-defense/"
image:      "/img/post/cable-room.jpg"
twitter_image: "/img/post/cable-room_876_438.jpg"
tags:
- MCP
- AI
- Data
- Architecture
series:
- AI
---

## TL;DR

- **MCP has real flaws**: security CVEs, scalability limits, immature OAuth. The critics aren't wrong.
- **Most criticism targets implementations and deployment mistakes**, not the protocol itself. SQL injection didn't kill SQL; we learned parameterized queries.
- **For internal data platforms, the threat model changes entirely**. You control the server, the network, the access model.
- **Context and metadata have always been the hard problem in data**. MCP just makes the cost of bad metadata immediately visible.
- **Building MCP servers forces metadata investment that pays off regardless**. If MCP dies tomorrow, you still have documented, well-governed data.

---

I've been experimenting with MCP for about six months now, building custom servers for data platform clients. Recently I started converting POCs and various experiments into legitimate OSS projects: [mcp-trino](/mcp-trino/) for data warehouse access, [mcp-s3](/mcp-s3/) for object storage, [mcp-datahub](https://github.com/txn2/mcp-datahub) for semantic context. The three work together. mcp-datahub provides the metadata layer that makes mcp-trino and mcp-s3 useful. Not because the world needs another generic MCP server. I build them as composable Go libraries, and public repositories put me in a different mindset. With OSS I put more effort into things like keeping documentation up to date.

MCP has problems. Serious ones. The security model is immature. The context window math doesn't work at scale. The OAuth spec is a mess. I've read the criticism, and most of it is technically accurate.

I'm building with MCP anyway. Here's why.

<!--more-->

{{< toc >}}

## The criticism is real

The problems are real. [Simon Willison](https://simonwillison.net/), who created [Datasette](https://datasette.io/) and whose technical judgment I trust, has been documenting MCP's prompt injection vulnerabilities since April 2025. He demonstrated an exploit where a malicious GitHub MCP server could access private repositories. The attack vector is fundamental: LLMs can't distinguish between trusted commands and untrusted data.

The CVE list is ugly. [CVE-2025-49596](https://www.tenable.com/blog/how-tenable-research-discovered-a-critical-remote-code-execution-vulnerability-on-anthropic) scored 9.4 (critical) and enables remote code execution through MCP Inspector. [CVE-2025-6514](https://nvd.nist.gov/vuln/detail/CVE-2025-6514) allows arbitrary OS command injection. [Security researchers found 1,862 MCP servers](https://www.bitsight.com/blog/exposed-mcp-servers-reveal-new-ai-vulnerabilities) exposed to the internet, with 119 allowing tool access without any authentication.

Context window bloat is the other serious issue. A single GitHub MCP server exposes 90+ tools, burning 50,000+ tokens before the user even asks a question. [Anthropic's own engineering blog](https://www.anthropic.com/engineering/code-execution-with-mcp) acknowledges 72K tokens for tool definitions when you connect 50+ MCP tools. On [τ-bench (Tau-Bench)](https://github.com/sierra-research/tau-bench) benchmarks, Claude Sonnet 3.7 achieves a 16% success rate on tool-using tasks.

[Shrivu Shankar](https://blog.sshh.io/p/everything-wrong-with-mcp), who describes himself as an "MCP-fan" and uses it daily, documented tool poisoning attacks and rug pull vulnerabilities. [Victor Dibia](https://newsletter.victordibia.com/p/no-mcps-have-not-won-yet), who contributes to [AutoGen](https://github.com/microsoft/autogen) and has built extensively with MCP, wrote about the developer experience problems: 300 lines of code just for basic examples. The criticism comes from practitioners who want MCP to succeed.

## Is it the technology or the implementation?

Before dismissing MCP, separate protocol design flaws from implementation mistakes and deployment misconfigurations.

**All software can be misused.** SQL injection has existed for decades. We didn't abandon SQL. We learned to use parameterized queries. The CVEs being cited ([CVE-2025-49596](https://www.tenable.com/blog/how-tenable-research-discovered-a-critical-remote-code-execution-vulnerability-on-anthropic), CVE-2025-6514) are implementation bugs in specific tools, not protocol design flaws. The 1,862 exposed servers that [BitSight found](https://www.bitsight.com/blog/exposed-mcp-servers-reveal-new-ai-vulnerabilities) represent a deployment misconfiguration, same category as exposing a database port to the internet. We don't blame TCP/IP for that.

**Prompt injection is an LLM limitation, not an MCP limitation.** LLMs fundamentally can't distinguish between trusted commands and untrusted data. This affects all LLM tool use, not just MCP. If you replaced MCP with any other protocol that lets AI interact with external systems, you'd face the same problem. Simon Willison's [demonstration of MCP prompt injection](https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/) is good security research, but the vulnerability exists in the LLM layer, not the protocol layer. The [tool poisoning attacks](https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks) documented by Invariant Labs would work with any similar system.

**Security is always a spectrum.** More access means more capability means more risk. This is the same trade-off you face with every API key, database connection, and service account. Organizations choose their position on that spectrum: read-only vs read-write, internal vs external, narrowly scoped vs broadly permissive. MCP gives you the flexibility to implement at any point on that spectrum. The protocol doesn't force you to expose write access. It doesn't force you to skip authentication. Those are choices.

Tools like [MCP-Scan](https://github.com/invariantlabs-ai/mcp-scan) exist to identify these risks before deployment.

[Zack Korman](https://x.com/ZackKorman), CTO at Pistachio, recently [demonstrated a persistence attack](https://x.com/ZackKorman/status/2013509833991823621): a malicious MCP server instructs the AI to write a skill, that skill modifies mcp_config.json, and the evil server gets re-added. Clever attack. But the fix belongs in the harness (Claude Code, Cursor), not the protocol. Block MCP from writing skills, block skills from touching MCP configs. Simple isolation rules.

## Why none of that stops me

The critics often miss something: they're evaluating MCP as a general-purpose tool for connecting AI assistants to arbitrary third-party services. That's one use case, and for that use case, the security concerns are disqualifying. I wouldn't install random MCP servers from the internet any more than I'd run random npm packages in production without review.

But that's not what I'm building. I'm building custom MCP servers for internal data platforms. The threat model is completely different.

When I connect [mcp-trino](/mcp-trino/) to an internal data warehouse, I control the server implementation. I wrote it. The code goes through the same review process as any other infrastructure component. There's no supply chain risk because there's no third-party supply chain.

Network exposure? The MCP server runs inside our VPN, behind the same firewalls that protect the data warehouse itself. The 1,862 exposed servers TigerData found represent a configuration mistake I'm not going to make.

OAuth complexity? Internal deployments can use pre-registered clients through existing IAM. No Dynamic Client Registration, no complicated token flows. The server trusts requests that have valid internal credentials. Same pattern we've used for every internal service for the past decade.

The prompt injection concern is real even for internal deployments. Malicious content in table descriptions or query results can manipulate AI behavior. But the blast radius is contained. The AI can only do what the MCP server permits, and I control what the MCP server permits. Read-only access to metadata? That's the default in both mcp-trino and mcp-s3. The worst case is the AI misinterprets some data, not that it exfiltrates credentials or runs arbitrary code.

## Context was always the problem

Most commentary on MCP misses the point entirely. The discussion focuses on whether MCP is the right protocol, whether it'll survive, whether Anthropic will maintain it. Those questions matter for betting on ecosystem tooling. They don't matter for the underlying problem MCP is trying to solve.

Context is the hard problem in any data platform. It was the hard problem before AI. It'll be the hard problem after MCP gets replaced by whatever comes next.

Consider what happens when a new analyst joins your company. They have access to a data warehouse with 10,000 tables across 50 schemas. How do they know which tables to query? How do they know that `customer_id` in the sales schema refers to the same entity as `cust_id` in the legacy billing system? How do they know that the `revenue` column is in cents, not dollars, and excludes refunds processed after the 15th of each month?

The metadata problem. It predates AI by decades. Data catalogs like [DataHub](https://datahubproject.io/), [Alation](https://www.alation.com/), and [Atlan](https://atlan.com/) exist because organizations recognized they were drowning in data they couldn't understand. The entire field of data governance is basically "how do we make our data self-describing?"

MCP doesn't solve this problem. But it forces you to confront it.

## MCP as a metadata forcing function

When you build an MCP server for your data platform, you have to answer questions like:

- What tools should the AI have access to?
- What schemas and tables are relevant for which questions?
- What descriptions and metadata make tables discoverable?
- How should permissions work?

These are the same questions your data catalog should already be answering for human users. But most organizations have let their catalogs rot. Tables have no descriptions. Columns are named `col1` through `col47`. Business definitions exist only in the heads of analysts who quit two years ago.

Building an MCP server makes the cost of poor metadata immediate and obvious. When the AI can't answer questions because it doesn't know which table contains customer information, you feel it in real time. When it joins the wrong tables because nothing documents the relationships, the query returns garbage and you watch it happen.

This feedback loop is faster and more visceral than waiting for an analyst to complain about documentation. The AI's confusion shows you exactly where your metadata falls short.

[Block deployed DataHub's MCP Server](https://datahub.com/blog/datahub-mcp-server-block-ai-agents-use-case/) in production. Their Senior Software Engineer Sam Osborn said that "something that might have taken days turns into a few conversation messages." That speedup requires metadata that actually describes the data. Without it, the MCP server is useless.

## Composable libraries over turn-key packages

Most MCP servers are npm packages. Turn-key API wrappers with tool descriptions. They don't tell the LLM how those tools relate to your data. They don't say "use Trino for that, it's sales data" or "check S3 for generated reports, they sit in a bucket." If MCP is only about generic capabilities, you might as well [use skills instead](https://intuitionlabs.ai/articles/claude-skills-vs-mcp). The value of MCP is semantic context specific to your data.

I built [mcp-trino](/mcp-trino/) and [mcp-s3](/mcp-s3/) differently. They're Go libraries built on [mcp-go](https://github.com/mark3labs/mcp-go) that you can import and extend. The binary is just a thin wrapper for people who don't need customization.

Every organization's data platform is different. You probably need:

- Authentication that integrates with your IAM
- Audit logging that meets your compliance requirements
- Query filtering that enforces your access policies
- Custom tools that reflect your specific domain

A black-box MCP server can't do any of that without forking. A composable library lets you add middleware:

```go
// Add Trino tools with your policy layer
trinoTools := trino.NewTools(trinoConfig)
for _, tool := range trinoTools.GetTools() {
    s.AddTool(tool, withAuth(withAudit(withQueryFilter(trinoTools.Handler(tool)))))
}
```

This is the same pattern that made middleware successful in web frameworks. The core functionality is provided; the policy layer is yours to define.

## The 72K token problem

The scalability issue is real and affects how you should design MCP integrations.

72K tokens for tool definitions with 50+ MCP tools. The architecture requires it. The AI needs to understand what tools are available before it can decide which ones to use. More tools means more context spent on tool descriptions, leaving less context for actual reasoning.

The practical implication: don't connect everything to everything. A general-purpose AI assistant with access to GitHub, Slack, email, calendar, 10 databases, 5 data lakes, and your CRM is going to be mediocre at all of those tasks.

Build focused MCP servers for specific domains. A data platform MCP that connects Trino and S3 for analytics work. A separate development MCP with kubefwd for Kubernetes debugging. The analyst working with sales data doesn't need access to your CI/CD pipelines. The developer debugging pods doesn't need to query the data warehouse.

Anthropic's November 2025 guidance essentially acknowledges this. They recommend having agents write code to call tools rather than using direct MCP tool calls at scale. Some interpreted this as Anthropic backing away from MCP. I read it as honest guidance about where the technology works today.

## What if MCP dies?

Maybe MCP gets replaced. The protocol is young. Google and OpenAI could announce competing standards tomorrow. Five years from now, we might be using something completely different.

I don't think this changes the calculus.

There's also a practical benefit: having a protocol helps when working with less technical clients. "We're building on the Model Context Protocol" is easier than explaining a bespoke integration. Standards create shared vocabulary, even imperfect ones.

The value in building MCP servers comes from the work you do to expose your data in a structured, well-described, permission-controlled way. That work translates to whatever comes next.

If you build an MCP server that exposes your Trino data warehouse with proper metadata, audit logging, and access controls, you have:

- A clear inventory of what data exists and how it relates
- Documentation that both humans and machines can consume
- An access control model you've actually thought through
- Audit logging for compliance and debugging

When the next protocol comes along, you port the server. The hard work was understanding your data and defining the policies around it. The protocol is just wire format.

## The metadata investment pays off regardless

I keep coming back to this point because I think it's the most important and the least discussed.

Organizations have been promising to improve their data documentation for twenty years. The promise never gets fulfilled because the payoff is distant and diffuse. Better metadata means faster analyst onboarding and fewer incorrect reports. None of that is urgent enough to prioritize over shipping features.

AI changes the incentive structure. Bad metadata means your expensive AI assistant gives wrong answers in front of people who notice immediately. Good metadata means the AI actually works, and people see it work.

That's the forcing function. Not because MCP is technically superior. Because it puts the cost of bad metadata in your face, in real time, in a way you can't ignore.

I've watched this happen on teams. Someone connects an MCP server to a poorly documented database. The AI hallucinates relationships between tables that don't actually join. Everyone sees it fail. Suddenly, documenting the schema becomes a priority that actually gets staffing.

## Practical recommendations

If you're considering MCP for internal data platform integration, a few suggestions from the past few months of building:

Start read-only. Both mcp-trino and mcp-s3 default to read-only mode, and that's intentional. Let the AI explore and query before you give it write access. You'll learn a lot about how it interprets your metadata before you trust it to modify anything.

Version-pin and review MCP servers like any security-sensitive dependency. Even for internal servers you control, treat updates as changes that need review. The code that translates between AI intent and database queries is not the place for surprise changes.

Build governance before you need it. Centralized logging of every MCP tool call. Usage monitoring. Anomaly detection. These feel like overkill until they're not.

Assume internal data could be adversarial. Prompt injection from table descriptions is unlikely but possible. If someone can write to a column that the AI reads, they can influence AI behavior. Design accordingly.

Keep MCP integrations focused. Don't build one server that does everything. Build specialized servers for specific domains. The context window limitations make this necessary, and it's better architecture anyway.

Invest in metadata first. The MCP server is just a delivery mechanism. If your tables don't have descriptions, your columns aren't documented, your relationships aren't defined, the AI can't help you.

## The protocol doesn't matter. The context does.

MCP might not be the final answer. The security model needs work. The scalability math is challenging. The spec is evolving faster than documentation can keep up.

What matters: AI assistants are only as good as the context they have access to. For data platforms, context means metadata. Relationships, descriptions, business definitions, access policies.

MCP is one way to deliver that context to AI assistants. It's the way that has momentum right now, with adoption from OpenAI, Google, Microsoft, and most major AI tooling vendors. Building for it makes sense given the current state of the ecosystem.

But even if MCP disappears, the context problem remains. Every data platform will need some way to expose structured metadata to AI systems. The organizations that have their metadata in order will adapt quickly. The ones that don't will struggle with whatever protocol comes next, just like they're struggling now.

So yes, MCP has flaws. Build with it anyway. The investment in metadata pays off regardless of what happens to the protocol.

## Resources

My MCP OSS projects:
- [mcp-trino](/mcp-trino/) - data warehouse access
- [mcp-s3](/mcp-s3/) - object storage
- [mcp-datahub](https://github.com/txn2/mcp-datahub) - semantic context layer
- [kubefwd MCP](/kubefwd-mcp/) - Kubernetes development

MCP ecosystem:
- [Model Context Protocol specification](https://modelcontextprotocol.io)
- [mcp-go SDK](https://github.com/mark3labs/mcp-go)
- [DataHub MCP Server](https://github.com/acryldata/mcp-server-datahub)
- [MCP-Scan](https://github.com/invariantlabs-ai/mcp-scan) - security scanning

Critical perspectives worth reading:
- [Simon Willison on MCP prompt injection](https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/)
- [Shrivu Shankar: Everything Wrong with MCP](https://blog.sshh.io/p/everything-wrong-with-mcp)
- [Victor Dibia: No, MCPs have NOT won](https://newsletter.victordibia.com/p/no-mcps-have-not-won-yet)
- [HN: "The S in MCP Stands for Security"](https://news.ycombinator.com/item?id=43600192)
- [Palo Alto Unit 42 on MCP attack vectors](https://unit42.paloaltonetworks.com/model-context-protocol-attack-vectors/)

Security research:
- [Zack Korman on MCP/skill persistence attacks](https://x.com/ZackKorman/status/2013509833991823621)
- [promptfoo/evil-mcp-server](https://github.com/promptfoo/evil-mcp-server) - red team testing
- [CVE-2025-49596 writeup (Tenable)](https://www.tenable.com/blog/how-tenable-research-discovered-a-critical-remote-code-execution-vulnerability-on-anthropic)
- [BitSight on exposed MCP servers](https://www.bitsight.com/blog/exposed-mcp-servers-reveal-new-ai-vulnerabilities)
- [Invariant Labs on tool poisoning](https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks)

Data catalogs:
- [DataHub](https://datahubproject.io/), [Alation](https://www.alation.com/), [Atlan](https://atlan.com/)
