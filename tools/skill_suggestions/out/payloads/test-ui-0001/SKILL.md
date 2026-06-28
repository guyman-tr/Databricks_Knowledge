---
name: domain-bizops
description: "Bizops customer-support automation analytics: multi-channel deflection
  (Web bot, WhatsApp, auto-resolved tickets), chatbot performance, bot per-message
  feedback (thumbs up/down), escalation and inactive-chat rates, and auto-resolution
  cost savings. Anchored on raw main.crm Salesforce silver tables (silver_crm_case,
  silver_crm_messagingsession, silver_crm_ai_session_entry__c) and the three Tableau
  dashboards Centralized Chatbot, Centralized Deflection (WhatsApp), and Autoresolved
  Cases. Load when users ask about deflection rate, chatbot/WhatsApp bot performance,
  auto-resolved or autosolved tickets, bot feedback, escalation rate, inactive chats,
  bot error/content-filter rate, or deflection cost savings. NOT the curated CRM case
  ledger / survey CSAT / agent QA / churn-winback — that is crm-cases-csat-and-churn."
triggers:
  - deflection
  - deflection rate
  - deflected chats
  - multi-channel deflection
  - contact deflection
  - chatbot performance
  - chatbot dashboard
  - bot performance
  - WhatsApp deflection
  - WhatsApp bot
  - WhatsApp chats
  - auto-resolved tickets
  - autosolved tickets
  - auto-resolution rate
  - ticket deflection
  - automation-eligible deflection
  - escalation rate
  - escalated chats
  - inactive chats
  - inactive-chat rate
  - bot error rate
  - content filtered
  - content-filter rate
  - bot feedback
  - chatbot feedback
  - bot CSAT
  - bot feedback score
  - contained vs escalated
  - deflection dashboard
  - centralized chatbot dashboard
  - autoresolved cases
  - deflection cost savings
  - silver_crm_messagingsession
  - silver_crm_ai_session_entry
  - Missed Whatsapp
required_tables:
  - main.crm.silver_crm_case
  - main.crm.silver_crm_messagingsession
  - main.crm.silver_crm_messagingchannel
  - main.crm.silver_crm_ai_session__c
  - main.crm.silver_crm_ai_session_entry__c
  - main.crm.silver_crm_livechattranscript
  - main.crm.silver_crm_accountidmappingtable
  - main.crm.silver_crm_calendlyaction__c
  - main.crm.silver_crm_task
sample_questions:
  - "What's our deflection rate last 90 days?"
  - "Web bot deflection rate for May 2026"
  - "WhatsApp deflection this quarter"
  - "How many tickets did we auto-resolve and how much did that save?"
  - "What's our ticket / auto-resolved deflection rate?"
  - "Bot feedback (CSAT) score for the chatbot last 30 days"
  - "Escalation rate and inactive-chat rate for the web bot"
  - "Case distribution by Origin / Country / Regulation for last month"
domain_tags:
  - bizops
  - chatbot
  - deflection
  - whatsapp
  - automation
  - contact-center
  - support
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-17"
---

# Bizops — Chatbot Performance & Multi-Channel Deflection

Answers natural-language questions about eToro's customer-support chatbot performance and
multi-channel deflection, backed by the Databricks `main.crm` Salesforce **silver** schema.
It encodes the canonical semantic layer for three Tableau dashboards that share one data
model: the **Centralized Chatbot Dashboard** (Web bot), the **Centralized Deflection
Dashboard** (Web + WhatsApp + Tickets), and **Autoresolved Cases Monitoring** (auto-closed
Portal/Email tickets).

The full source of truth — table definitions, join graph, every metric formula, and the
canonical `WA_Final` / `Ticket_Final` SQL — lives in
[`references/chatbot-deflection-semantic-layer.md`](references/chatbot-deflection-semantic-layer.md). This file is the operating
manual: how to run a query and which non-negotiable rules apply. Read the reference before
any non-trivial query, and **always** for WhatsApp or Ticket deflection (their SQL must be
adapted, never rebuilt from memory).

## When to Use

Use this skill for natural-language questions about customer-support **automation
performance** that map to the bizops chatbot / deflection dashboards, even when no table is
named:

- Deflection rate (overall, Web bot, WhatsApp, or auto-resolved tickets).
- Chatbot / WhatsApp bot performance: contained vs escalated, escalation rate, inactive-chat
  rate, bot error rate, content-filter rate.
- Bot per-message feedback (thumbs up/down) — the chatbot's own CSAT signal.
- Auto-resolved (autosolved) ticket economics and cost savings.
- Support contact distribution by Origin (Chatbot / Chat / Portal / Email / WhatsApp),
  Country, Regulation, Club level.

Do **NOT** use this skill for (these belong to
`domain-customer-and-identity/crm-cases-csat-and-churn.md`):

- The curated 110-column CRM case ledger (`vg_crm_case` in `etoro_kpi`) — per-customer case
  history, status, complaint/reopen flags, resolution times.
- **Survey** CSAT (`simplesurvey__Survey_Score__c`, 1–5 per case) or agent **QA** scoring.
- CRM agent / manager / RM hierarchy, churn-winback targeting, or KYC questionnaire answers.

The split in one line: **`domain-bizops` = contact-center automation KPIs on raw
`main.crm.silver_*` + messaging sessions; `crm-cases-csat-and-churn` = the customer-
relationship case ledger + survey CSAT + churn on curated `vg_crm_case`.**

## Scope

In scope: `main.crm.silver_crm_case` (support-case spine), `silver_crm_messagingsession` +
`silver_crm_messagingchannel` (Web chat + WhatsApp sessions), `silver_crm_livechattranscript`
(legacy quality gate), `silver_crm_ai_session__c` + `silver_crm_ai_session_entry__c` (bot
per-message feedback / CSAT), `silver_crm_etoro_assistant_bot_request__c` (legacy bot
errors/content-filter), `silver_crm_accountidmappingtable` + `silver_crm_calendlyaction__c` +
`silver_crm_task` (WhatsApp identity chain + leakage signals); the metrics deflection rate
(Web / WhatsApp / Ticket / Unified), escalation rate, inactive-chat rate, bot CSAT, bot
error/content-filter rate, auto-resolved ticket economics; and the Centralized Chatbot,
Centralized Deflection, and Autoresolved Cases dashboards.

Out of scope: the curated `vg_crm_case` ledger, survey CSAT, agent QA, agent/manager
hierarchy, churn-winback, and KYC answers (all `crm-cases-csat-and-churn.md`); the
`/feedback` agent command (`feedback-command`); revenue Ticket Fees (`domain-revenue-and-fees`);
product-usage login/event analytics (`domain-product-analytics`).

Last verified: 2026-06-17

## Critical Warnings

Ordered by severity. Each maps to a metric people get wrong; the SQL behind each is in
[`references/chatbot-deflection-semantic-layer.md`](references/chatbot-deflection-semantic-layer.md).

1. **WhatsApp deflection requires all five leakage signals — omitting #3–#5 is a silent wrong
   number (~17pp overstatement).** A WhatsApp session is deflected only if NONE fire:
   (1) escalated `AgentType <> 'Bot'`, (2) `Route_to_another_AM__c = TRUE`, (3) Calendly
   booking ≤14 days, (4) a `Missed Whatsapp` task referencing the session Id (the single
   largest, ~12% of eligible), (5) a same-customer Email/Portal case ≤24h. Signals #3–#5 need
   the identity chain (`EndUserAccountId` → `accountidmappingtable` → GCID/CID → PII email /
   case). A recent 30-day window read 90.7% with #1–#2 only vs 73.8% correct. Adapt the
   canonical `WA_Final` SQL; do not rebuild from prose. If the identity-chain joins cannot run,
   report WhatsApp deflection as **unavailable**, never a partial number.

2. **Per-channel qualifying filters are mandatory — raw counts are silently wrong by 2–5×.**
   WhatsApp needs `ChannelType='WhatsApp'` AND `EndUserMessageCount > 0` AND
   `Origin <> 'TriggeredOutbound'` AND `AgentType IN ('Bot','BotToAgent')` (without them raw
   session count is ~5× too high). Web chat needs the quality gate (exclude
   `visitormessagecount = 0` ghost chats and `Bot_Eligible__c = False`, and `Chat`-origin cases
   with no transcript/session).

3. **Ticket eligibility uses registration country, not `case.Country__c` — wrong join is a
   silent ~30× error.** Automation-Eligible tickets require a non-null automation
   `classification` AND non-US **registration** country joined via
   `general.bronze_etoro_customer_customer_masked` → `general.bronze_etoro_dictionary_country`.
   `case.Country__c` is NULL for ~80% of Portal/Email tickets — never use it for the US
   exclusion.

4. **Cast `case` date strings and use ranges — equality on ISO strings silently drops rows.**
   `silver_crm_case.CreatedDate` / `ClosedDate` are ISO-8601 strings; always
   `to_timestamp(col, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")`, and filter single days with
   `>= d AND < d+1`, never `=`.

5. **Treating raw `IsClosedOnCreate` as "autosolved" inflates the rate ~2×.** ~85% of
   Portal/Email tickets carry `IsClosedOnCreate=TRUE` (a system default); only ~6% are
   automation-eligible. The dashboard "autosolved rate" is the **Automation-Eligible
   Deflection** (~43%), not the raw auto-close rate.

6. **Report ticket deflection as BOTH rates, or the inflation/deflation misleads.** Give the
   All-Tickets rate (deflected ÷ all Portal/Email tickets, ≈0.8%) AND the Automation-Eligible
   rate (deflected ÷ EligibleAutomationTickets, ≈46.5%), and state the eligibility rate (~1.8%)
   linking them. Never report the All-Tickets figure alone.

7. **"CSAT" here is the bot's per-message thumbs up/down, Web-bot-only — do not conflate it
   with survey CSAT.** This skill's CSAT = positive ÷ (positive + negative) from
   `silver_crm_ai_session_entry__c.User_Feedback__c` (`Positive`/`Negative`/`NULL`). The
   survey-based 1–5 CSAT (`simplesurvey__Survey_Score__c`) is a different metric owned by
   `crm-cases-csat-and-churn.md`. WhatsApp carries no feedback; never use case-level
   `Chat_Score__c` / `SLA_Score__c` / `Score__c`.

8. **Dependency / edge case: error-rate and content-filter metrics are legacy-bot-era only
   (≈ valid through Oct 2025).** They rely on `silver_crm_etoro_assistant_bot_request__c`
   error text, which stopped populating after ~Oct 2025. Do not report them for later periods;
   there is no MessagingSession-era replacement.

9. **Dependency / edge case: apply standing data-quality exclusions and cross-era coverage.**
   Exclude `DATE(messagingsession.CreatedDate) = '2025-05-28'` (bad day); flag isolated one-day
   WhatsApp volume spikes (~7× baseline) before trending. For any cross-era feedback window,
   cover BOTH AI-session FKs (`Chat_Transcript__c` legacy and `Messaging_Session__c` new) via
   UNION ALL (architecture migrated ~Apr–Oct 2025).

## How to run a query

Queries run against Databricks (host `adb-6358342630366312.12.azuredatabricks.net`, primary
schema `main.crm`) using the read-only SQL tool. Write standalone queries with CTEs (do not
assume upstream views exist). Use Databricks SQL syntax: `CURRENT_DATE - INTERVAL 30 DAYS`,
`DATE(col)`, `to_timestamp(...)`, `IFNULL`, `get_json_object`.

**Always ask for a time period first if none is given.** Every metric is gated by a query-time
window; the hardcoded date floors in the reference SQL (`2024-01-01`, `2025-04-02`, …) are
extraction-weight guardrails, not metric start dates — never treat them as a default window.

## Non-negotiable definitions

- **Origin semantics:** `Chatbot` = contained (started and ended with the bot); `Chat` =
  started with bot, escalated to a human; `Portal` / `Email` = non-chat inbound. WhatsApp lives
  in `messagingsession` at session grain (no case, no feedback).
- **Unqualified "deflection rate"** = combined Web bot + WhatsApp, tickets excluded — and say
  so (offer Web-only / WhatsApp-only / tickets on request). The WhatsApp component must use the
  full five-signal logic (Warning 1).
- **Web deflection:** a Chatbot-origin case is deflected unless the same `CID__c` opened another
  case in the same `Category__c` with `Origin IN ('Email','Portal')` within 24h after.
- **Savings:** Amount Saved = deflected-and-closed-on-create cases × cost per case (default
  **$18**) — state the $18 default and that the user can override it.
- **ChannelType:** `EmbeddedMessaging` = Web chat; `WhatsApp` = WhatsApp.

## Where to look in the reference

[`references/chatbot-deflection-semantic-layer.md`](references/chatbot-deflection-semantic-layer.md) is the authority:

- **Data Sources / Table Definitions** — every table, grain, key columns, per-table gotchas.
- **Relationships** — the case+session spine, feedback linkage, the WhatsApp identity chain,
  ticket follow-up joins (exact keys and join types).
- **Business Metrics** — formulas for distribution, deflection (Web/WhatsApp/Ticket/Unified),
  CSAT, chatbot quality, ticket economics, engagement. Contains the canonical `WA_Final` and
  `Ticket_Final` SQL to adapt.
- **Business Rules / Migration / Glossary / MCP Query Guidance** — the eleven standing rules,
  LiveChatTranscript→MessagingSession eras, term definitions, and a question→answer-shape map.

## Answer style

State the time window and scope used, surface the relevant caveat (e.g. "Web bot + WhatsApp,
tickets excluded"), and give numbers with their denominators. When a figure cannot be computed
correctly (e.g. WhatsApp without the identity chain), say it is **unavailable** rather than
returning a number known to be biased.
