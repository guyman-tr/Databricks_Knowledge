# Semantic Layer: CRM Chatbot Performance & Multi-Channel Deflection

> **Audience:** This document is written for an AI agent that queries eToro's Databricks
> environment in natural language via MCP. It is self-contained — an agent reading it cold
> should be able to write correct Databricks SQL (DBSQL syntax) without further questions.
> **Catalog/host:** `adb-6358342630366312.12.azuredatabricks.net`, primary schema `main.crm`.

---

## Purpose

This domain measures **customer-support contact distribution across channels** and
**chatbot / automation performance** at eToro. The three headline concerns are:

1. **Case (contact) distribution** across origins/channels — Chatbot, Chat, Portal, Email, WhatsApp.
2. **Deflection** — how often an automated interaction resolves a customer's need without a
   human agent or a follow-up human contact.
3. **Customer feedback / CSAT** — per-message thumbs up/down on bot responses.

It also covers secondary metrics: bot error rate, content-filtering rate, inactive-chat rate,
WhatsApp volume, auto-resolved ticket economics, and chatbot engagement versus platform logins.

The domain is realized across **three Tableau dashboards that share one underlying data model**:

| Dashboard | Scope | Role in this semantic layer |
|---|---|---|
| **Centralized Chatbot Dashboard** | Web bot only (Chat/Chatbot cases) + bot errors, content filtering, feedback, inactivity, logins | Defines the **Web-chat deflection** and chatbot-performance metrics |
| **Centralized Deflection Dashboard (with WhatsApp)** | Web Chat + WhatsApp + auto-resolved Tickets, unified | **Extends** the Web-chat definition with WhatsApp and Ticket deflection |
| **Autoresolved Cases Monitoring** | Auto-resolved (closed-on-create) Portal/Email tickets only | **Deep-dive** on the Ticket channel + cost-savings economics |

The deflection dashboard is the canonical **superset**: its `Web_*` block reproduces the Web-chat
logic exactly, and its `Ticket_*` block reproduces the Autoresolved logic. There is **one** Web
deflection definition shared across all three.

---

## Data Sources

All tables are Salesforce-CRM objects landed in the Databricks **silver** layer under `main.crm`
unless noted. Logins come from the DWH gold layer; some WhatsApp identity resolution uses
`main.pii_data` and `general`.

| Source object | Path | Feeds |
|---|---|---|
| Case | `main.crm.silver_crm_case` | Contact distribution, Web + Ticket deflection, the spine |
| Live Chat Transcript | `main.crm.silver_crm_livechattranscript` | Legacy bot-eligibility gate, legacy session linkage |
| Messaging Session | `main.crm.silver_crm_messagingsession` | New-architecture chat + WhatsApp sessions |
| Messaging Channel | `main.crm.silver_crm_messagingchannel` | Channel label (Web Chat vs WhatsApp) |
| Conversation | `main.crm.silver_crm_conversation` | Conversation-level timing |
| Messaging Session History | `main.crm.silver_crm_messagingsessionhistory` | Inactivity-ended flag |
| AI Session | `main.crm.silver_crm_ai_session__c` | Bridge from session/transcript to feedback |
| AI Session Entry | `main.crm.silver_crm_ai_session_entry__c` | Per-message user feedback (CSAT) |
| Bot Request | `main.crm.silver_crm_etoro_assistant_bot_request__c` | Bot errors + blocked words (**legacy-only, see §Business Rules**) |
| Account ID Mapping | `main.crm.silver_crm_accountidmappingtable` | WhatsApp `EndUserAccountId` → CID/GCID |
| Calendly Action | `main.crm.silver_crm_calendlyaction__c` | WhatsApp deflection leakage signal (#3) |
| Task | `main.crm.silver_crm_task` | WhatsApp "Missed Whatsapp" leakage signal (#4 — largest) |
| Customer (PII) | `main.pii_data.bronze_etoro_customer_customer` | WhatsApp GCID → email for Calendly match |
| Customer (masked) | `general.bronze_etoro_customer_customer_masked` | Ticket → registration country |
| Country dictionary | `general.bronze_etoro_dictionary_country` | Ticket registration-country `Name` column (US exclusion) |
| Customer Action (DWH) | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Daily login count (standalone context) |

---

## Table Definitions

### `main.crm.silver_crm_case`
- **Grain:** one support case (ticket). Primary entity / spine of the domain.
- **Key columns:** `Id` (string PK), `CaseNumber` (string, business key used for dedup/joins),
  `CID__c` (string, customer ID), `GCID__c` (string, global customer ID).
- **Important fields:**
  - `Origin` — channel of entry. Canonical values for this domain: **`Chatbot`** (started and
    ended with the bot — contained), **`Chat`** (started with bot, escalated to a human agent),
    **`Portal`** and **`Email`** (non-chat inbound). See Glossary.
  - `CreatedDate` (string ISO8601 `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'` — **must** be cast with
    `to_timestamp(..., "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")`), `ClosedDate` (same format).
  - `IsClosedOnCreate` (boolean) — case auto-closed at creation; the basis of "auto-resolved tickets".
  - `Category__c`, `Type__c`, `Sub_Type__c`, `Initial_Sub_Type__c`, `Initial_Sub_Type_2__c`,
    `Sub_Type_2__c` — classification hierarchy. The Ticket channel maps these into automation
    `classification` buckets (see §Ticket eligibility).
  - Segmentation: `Country__c`, `Regulation__c`, `Club_Level_on_Creation__c`, `Service_Desk__c`,
    `Lead_or_FTD__c`, `Product__c`, `Selected_Chat_Language__c`, `Service_Language__c`.
  - **Do NOT use for CSAT:** `Chat_Score__c`, `SLA_Score__c`, `Score__c` are present but
    **not trusted** — CSAT comes only from AI Session Entry feedback.
- **Update pattern:** silver snapshot of the Salesforce object (overwrite/refresh).
- **Gotchas:** `Chat` origin is a **mixed population** — only a subset are true bot→human
  escalations; the model excludes `Chat` cases with no linked chat session (see §Relationships).

### `main.crm.silver_crm_livechattranscript`
- **Grain:** one legacy live-chat transcript, linked to a case via `CaseId`.
- **Key columns:** `Id` (PK), `CaseId` (FK → case).
- **Important fields:** `visitormessagecount` (int), `Bot_Eligible__c` (boolean).
- **Update pattern:** snapshot. **Legacy** — being phased out (see §Migration).
- **Gotchas:** Used purely as a **quality gate** in the case model: a transcript could be created
  even with no customer message (a "ghost chat"). The gate excludes `visitormessagecount = 0`
  and `Bot_Eligible__c = False`.

### `main.crm.silver_crm_messagingsession`
- **Grain:** one messaging session (new architecture). May or may not link to a case.
- **Key columns:** `Id` (PK), `CaseId` (FK → case, **NULL for WhatsApp**),
  `EndUserAccountId` (FK → account mapping), `ConversationId`, `MessagingChannelId`.
- **Important fields:** `ChannelType` (**`EmbeddedMessaging`** = Web chat, **`WhatsApp`** = WhatsApp),
  `AgentType` (`Bot`, `BotToAgent`, …), `Origin` (e.g. `TriggeredOutbound`), `EndUserMessageCount`,
  `AgentMessageCount`, `Status`, `AcceptTime`, `EndTime`, `Route_to_another_AM__c` (boolean),
  `Country__c`, `Regulation__c`, `Customer_Level__c`, `Desk__c`.
- **Update pattern:** snapshot. **Current** architecture (replaced LiveChatTranscript).
- **Gotchas:** Under the new architecture a session is created **only after the customer sends a
  message**, so the ghost-chat problem does not occur here. **WhatsApp sessions have no linked
  case** — they are measured at session grain. One specific date, `2025-05-28`, is excluded as a
  data-quality bad day. Watch for occasional one-day volume spikes (e.g. ~7× baseline) that can
  reflect bulk/triggered events slipping past the `Origin <> 'TriggeredOutbound'` filter — flag
  and verify such days before trending them.

### `main.crm.silver_crm_messagingchannel`
- **Grain:** one messaging channel definition.
- **Key columns:** `Id` (PK, joined from `messagingsession.MessagingChannelId`).
- **Important fields:** `MasterLabel` (e.g. `Customer Service Web Chat`, contains `eToro WhatsApp`),
  `MessageType`, `IsActive`, `IsoCountryCode`. Prefer `messagingsession.ChannelType` for Web-vs-WhatsApp
  splits in pure SQL; `MasterLabel` is the Tableau-era string.
- **Update pattern:** snapshot / slowly changing.

### `main.crm.silver_crm_conversation`
- **Grain:** one conversation. **Key:** `Id` (joined from `messagingsession.ConversationId`).
- **Important fields:** `StartTime`, `EndTime`, `ConversationChannelid`. Update pattern: snapshot.

### `main.crm.silver_crm_messagingsessionhistory`
- **Grain:** one field-change history row for a messaging session.
- **Important fields:** `messagingsessionid`, `field`, `OldValue`, `newvalue`, `CreatedDate`.
- **Use:** detect inactivity-ended sessions: `field='Status' AND OldValue='Inactive' AND newvalue='Ended'`.
- **Update pattern:** append-only history.

### `main.crm.silver_crm_ai_session__c`
- **Grain:** one AI (bot) session. Bridges sessions/transcripts to message-level feedback.
- **Key columns:** `Id` (PK), `Messaging_Session__c` (FK → messagingsession, **new era**),
  `Chat_Transcript__c` (FK → livechattranscript, **legacy era**), `Case__c`.
- **Important fields:** `Number_of_Messages__c`. Update pattern: snapshot.
- **Gotcha:** the FK used depends on era — see §Migration. A session links via *one* of the two FKs.

### `main.crm.silver_crm_ai_session_entry__c`
- **Grain:** **one bot message** within an AI session (the CSAT atom).
- **Key columns:** `Id` (PK), `AI_Session__c` (FK → ai_session).
- **Important fields:** **`User_Feedback__c`** — the thumbs up/down the customer leaves on a
  specific bot message. Values observed: **`Positive`**, **`Negative`**, or **NULL** (no rating).
  Case-insensitive in formulas (`lower(...)`). Also `Message__c`, `Sender__c`, `Type__c`,
  `Bot_Message__c`, `IsDeleted`.
- **Update pattern:** snapshot.

### `main.crm.silver_crm_etoro_assistant_bot_request__c`
- **Grain:** one bot request/response payload (JSON in `Response__c`).
- **Use:** `get_json_object(Response__c,'$.sessionId')`, `'$.errorText'`; blocked words via
  `regexp_extract(... 'Blocked word(.*)detected' ...)`.
- **Update pattern:** append-only.
- **Gotcha (critical):** the table keeps receiving rows, but **`errorText` stopped populating after
  ~October 2025** (0 error rows every month since Nov 2025). All error / content-filter metrics
  built on this table are **legacy-bot-era only** (see §Business Rules → Deprecated metrics).

### `main.crm.silver_crm_accountidmappingtable`
- **Grain:** account mapping row. **Use:** WhatsApp `messagingsession.EndUserAccountId = Id` →
  `GCID__c`, `Customer_Unique_ID_CID__c` (CID). Needed because WhatsApp sessions carry no case/CID directly.
  This is the **entry point to the WhatsApp identity chain** that powers leakage signals #3–#5 — without
  it those signals cannot be evaluated (see §Deflection → WhatsApp and the ★ WhatsApp rule).

### `main.crm.silver_crm_calendlyaction__c`, `main.crm.silver_crm_task`
- WhatsApp deflection **leakage signals** (a deflection is broken if these exist). These are **part
  of the WhatsApp definition, not optional refinements** — see the ★ WhatsApp deflection rule.
  - **Calendly (signal #3):** booking via `InviteeEmail__c` matched to the session's customer
    (`accountidmappingtable` → `GCID__c` → `pii_data...customer.Email`) with
    `EventCreatedAt__c` within **14 days** of the session. Removes ~5% of eligible sessions.
  - **Task (signal #4 — the single largest leakage signal):** a Task with `Type = 'Missed Whatsapp'`
    on the same `AccountId` (= `messagingsession.EndUserAccountId`) whose `Description` contains the
    session `Id` (`Description LIKE '%' || sessionId || '%'`). Removes **~12%** of eligible sessions —
    historically the most commonly omitted signal, and the one that caused the largest error.

### `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- **Grain:** one customer action event. **Login** = `ActionTypeID = 14`.
- **Use:** `SELECT DATE(Occurred) AS LoginDate, COUNT(DISTINCT gcid) FROM ... WHERE ActionTypeID=14 GROUP BY 1`.
- **Role:** standalone engagement-vs-DAU context panel — **not** a denominator for any deflection/CSAT metric.

---

## Relationships

### The case + session spine (Centralized Chatbot Dashboard, Query 1)
```
silver_crm_case  (fc)
  └─LEFT JOIN  silver_crm_livechattranscript (t)   ON t.caseid = case.id        -- quality gate
  └─LEFT JOIN  DeflectedCases (dc)                 ON fc.casenumber = dc.casenumber
  └─FULL OUTER JOIN silver_crm_messagingsession (ms) ON fc.id_case = ms.caseid  -- see note
       └─LEFT JOIN silver_crm_messagingchannel (mc)  ON ms.messagingchannelid = mc.Id
       └─LEFT JOIN silver_crm_conversation         ON ms.conversationid = conversation.Id
       └─LEFT JOIN MessagingSessionHistory (msh)    ON msh.messagingsessionid = ms.Id
WHERE COALESCE(fc.Origin,'') <> 'Chat' OR fc.Id_chattranscript IS NOT NULL OR ms.Id IS NOT NULL
```
- **Case ↔ LiveChatTranscript:** 1:many (a case can have several transcripts); used only to read
  `Bot_Eligible__c` / `visitormessagecount`. **Join type LEFT** so non-chat cases survive.
- **Case ↔ MessagingSession:** **FULL OUTER on purpose.** Cases with no session (legacy/email) and
  **WhatsApp sessions with no case** must both appear. Cardinality is 1:many on the case side.
  When the case side is NULL, use `Unified Date = IFNULL(CreatedDate_Case, CreatedDate_MessagingSession)`.
- **Final WHERE — the relevance gate:** keep a row if it is *not* a `Chat`-origin case, **or** it has
  a linked transcript, **or** it has a linked messaging session. This drops `Chat`-origin cases with
  no chat artifact (the mislabeled-origin population).
- **MessagingSession ↔ MessagingChannel:** many:1. **↔ Conversation:** many:1. **↔ History:** 1:many,
  used as an existence check (`DISTINCT messagingsessionid`).

### Feedback linkage (AI Session → AI Session Entry)
```
ai_session (ais)
  ├─ new era:    JOIN messagingsession (ms) ON ais.messaging_session__c = ms.id
  └─ legacy era: JOIN livechattranscript (t) ON ais.Chat_Transcript__c = t.id
  └─LEFT JOIN ai_session_entry (aise) ON ais.id = aise.AI_Session__c     -- feedback rows
```
- The two branches are **UNION ALL**'d to cover both architectures. Feedback `Interaction_ID` is the
  **CaseId** for web (legacy `t.CaseId` or new `ms.CaseId`); the deflection dashboard uses
  `CASE WHEN ms.ChannelType='WhatsApp' THEN ms.Id ELSE ms.CaseId END` — but **no WhatsApp feedback
  exists** (verified zero), so in practice CSAT is Web-only and keys on CaseId.

### Bot errors
- `bot_request.sessionId` (from JSON) ↔ `messagingsession.Id` (string key). Errors are blended into
  the session grain. Legacy-era only.

### WhatsApp identity chain (deflection dashboard, WA block)
```
messagingsession (ChannelType='WhatsApp')
  └─LEFT JOIN accountidmappingtable  ON ms.EndUserAccountId = amp.Id     -> GCID, CID
  └─(GCID) JOIN pii_data...customer  ON GCID                              -> email   -> signal #3 (Calendly)
  └─(email) JOIN calendlyaction__c   within 14 days                       -> leakage #3
  └─(EndUserAccountId) JOIN task (Type='Missed Whatsapp', Desc LIKE %sessionId%) -> leakage #4 (largest)
  └─(CID) JOIN case (Email/Portal within 24h)                             -> leakage #5
```
- **This chain is required, not optional.** Leakage signals #3 (Calendly), #4 (Missed-Whatsapp task)
  and #5 (cross-channel ticket) can only be evaluated through it. A WhatsApp deflection number computed
  without this chain (i.e. using only `AgentType`/`Route_to_another_AM__c`) is **wrong by ~17pp** — see
  the ★ WhatsApp deflection rule.

### Ticket (auto-resolved) follow-up
- `Ticket_FilteredCases` (Portal/Email) ↔ `Ticket_FollowUpCases` via `CID__c` + 24h window. A
  follow-up breaks deflection if it is the **same Category OR** arrived via **Chatbot/Chat** (broader
  than the chat rule). Registration country via `customer_masked` → `dictionary_country` (US excluded).

---

## Business Metrics

> **Period note:** every count below is gated by a current-period flag (`CP Valid`,
> `CP Valid ms`, or `CP Valid unified`) driven by a `Date Comparison` parameter
> (Last 30/60/90 Days, Last 6 Months, Last Year, Custom). The hardcoded date floors in the SQL
> (`2024-01-01`, etc.) are **extraction-weight guardrails, not metric start dates**. See §Business Rules.

### Channel / contact distribution
- **#CountofChats** — `COUNTD(IF Origin IN ('Chat','Chatbot') AND CP Valid THEN id_Case END)`.
- **#CountofChatsBot** — Chatbot only. **#CountofChatsHumanAgents** — Chat only.
- **#CountOfInboundCases** — `COUNTD(IF Origin IN ('Chat','Chatbot','Portal') AND CP Valid THEN id_Case END)`.
- **WhatsApp Chats** — `COUNTD(IF MasterLabel CONTAINS 'etoro whatsapp' AND CP Valid ms THEN Id_MessagingSession END)`.
- **#AllChats** — `#CountofChats + WhatsApp Chats`.

### Deflection — the canonical definition

**Web-chat deflection (the single Web definition, used in all three dashboards):**
A **Chatbot**-origin interaction is **deflected** unless the *same customer* (`CID__c`) opened
another case in the *same* `Category__c` with `Origin IN ('Email','Portal')` **within 24 hours after**.
```sql
-- per distinct Chatbot case:
IsDeflected = NOT EXISTS (
  follow-up p WHERE p.CID = c.CID AND p.Category = c.Category
    AND p.CreatedDate >  c.CreatedDate
    AND p.CreatedDate <= c.CreatedDate + INTERVAL '24 hour'
    AND p.Origin IN ('Email','Portal') )
```
- **#CountofDeflectedChats** = `COUNTD(IF IsDeflected AND Origin='Chatbot' AND CP Valid THEN id_Case END)`.
- **%DeflectionRate** (Web) = `#CountofDeflectedChats / #CountofChats`.
- **#CountofEscalatedChats** = `COUNTD(IF Origin='Chat' AND CP Valid THEN CaseNumber END)`;
  **%Escalation Rate** = escalated `/ #CountofChats`.

**WhatsApp deflection (session grain) — all five leakage signals are MANDATORY:**
A *qualifying* WhatsApp session (`ChannelType='WhatsApp'`, `EndUserMessageCount > 0`,
`Origin <> 'TriggeredOutbound'`, `AgentType IN ('Bot','BotToAgent')`) is `Is_Eligible = TRUE` and
counts in the denominator. It is **deflected only if NONE of these five leakage signals fire**:

| # | Leakage signal | How to detect | ~Share of eligible (rolling 30d) |
|---|---|---|---|
| 1 | Escalated to a human | `AgentType <> 'Bot'` | ~9% |
| 2 | Routed to another AM | `Route_to_another_AM__c = TRUE` | <1% |
| 3 | Calendly booking ≤ 14 days | identity chain (GCID → email) → `calendlyaction__c.InviteeEmail__c`, `EventCreatedAt__c` within 14 days | ~5% |
| 4 | "Missed Whatsapp" task | `task.Type='Missed Whatsapp'` on `EndUserAccountId`, `Description LIKE '%sessionId%'` | **~12% — the single largest** |
| 5 | Same-customer Email/Portal case ≤ 24h | identity chain (CID) → `case` with `Origin IN ('Email','Portal')` within 24h | ~2% |

Signals #3–#5 require the WhatsApp identity chain (`EndUserAccountId` → `accountidmappingtable` →
GCID/CID → PII email / case). **They are not optional.** Computing WhatsApp deflection from signals
#1–#2 only **overstates the rate by ~17 percentage points** (a recent 30-day window read **90.7%**
with #1–#2 only versus **73.8%** with all five), driven mostly by the "Missed Whatsapp" task (#4).

Canonical `WA_Final` SQL (adapt the date window only — this is the source of truth, do not rebuild it):
```sql
WITH WA_target_whatsapp_sessions AS (
  SELECT ms.Id AS Id_MS_Inbound, ms.EndUserAccountId,
         ms.CreatedDate AS CreatedDate_MS_Inbound,
         ms.AgentType AS AgentType_MS,
         ms.Route_to_another_AM__c AS Route_to_another_AM__c_MS,
         ms.Country__c AS Country__c_MS, ms.Regulation__c AS Regulation__c_MS,
         ms.Customer_Level__c AS Customer_Level__c_MS, ms.Desk__c AS Desk__c_MS,
         amp.GCID__c AS GCID_MS, amp.Customer_Unique_ID_CID__c AS CID_MS
  FROM main.crm.silver_crm_messagingsession ms
  LEFT JOIN main.crm.silver_crm_accountidmappingtable amp
    ON ms.EndUserAccountId = amp.Id
  WHERE ms.ChannelType = 'WhatsApp'
    AND ms.EndUserMessageCount > 0
    AND ms.Origin <> 'TriggeredOutbound'
    AND ms.AgentType IN ('Bot','BotToAgent')
    AND ms.CreatedDate >= <window_start>            -- e.g. CURRENT_DATE - INTERVAL 30 DAYS
),
WA_calendly_matched AS (                             -- signal #3
  SELECT b.Id_MS_Inbound,
         ROW_NUMBER() OVER (PARTITION BY b.Id_MS_Inbound ORDER BY cal.EventCreatedAt__c ASC) AS rnk_cal
  FROM WA_target_whatsapp_sessions b
  JOIN main.pii_data.bronze_etoro_customer_customer cust
    ON CAST(b.GCID_MS AS STRING) = CAST(cust.GCID AS STRING)
  JOIN main.crm.silver_crm_calendlyaction__c cal
    ON cal.InviteeEmail__c = cust.Email
   AND cal.EventCreatedAt__c >= b.CreatedDate_MS_Inbound
   AND cal.EventCreatedAt__c <= b.CreatedDate_MS_Inbound + INTERVAL 14 DAY
),
WA_task_matched AS (                                 -- signal #4 (largest)
  SELECT b.Id_MS_Inbound,
         ROW_NUMBER() OVER (PARTITION BY b.Id_MS_Inbound ORDER BY tk.CreatedDate ASC) AS rnk_task
  FROM WA_target_whatsapp_sessions b
  JOIN main.crm.silver_crm_task tk
    ON b.EndUserAccountId = tk.AccountId
   AND tk.Type = 'Missed Whatsapp'
   AND tk.CreatedDate >= b.CreatedDate_MS_Inbound
   AND tk.Description LIKE CONCAT('%', b.Id_MS_Inbound, '%')
),
WA_ticket_matched AS (                               -- signal #5
  SELECT b.Id_MS_Inbound,
         ROW_NUMBER() OVER (PARTITION BY b.Id_MS_Inbound ORDER BY c.CreatedDate ASC) AS rnk_ticket
  FROM WA_target_whatsapp_sessions b
  JOIN main.crm.silver_crm_case c
    ON c.CID__c = b.CID_MS
   AND c.CreatedDate >= b.CreatedDate_MS_Inbound
   AND c.CreatedDate <= b.CreatedDate_MS_Inbound + INTERVAL '24 hour'
   AND c.Origin IN ('Email','Portal')
)
SELECT
  b.Id_MS_Inbound AS Interaction_ID,
  b.CreatedDate_MS_Inbound AS Interaction_Date,
  'WhatsApp' AS Channel,
  b.CID_MS AS Customer_CID,
  CASE
    WHEN b.AgentType_MS <> 'Bot'             THEN FALSE   -- #1 escalated
    WHEN cal.Id_MS_Inbound IS NOT NULL       THEN FALSE   -- #3 Calendly
    WHEN tk.Id_MS_Inbound  IS NOT NULL       THEN FALSE   -- #4 Missed Whatsapp task
    WHEN tm.Id_MS_Inbound  IS NOT NULL       THEN FALSE   -- #5 cross-channel ticket
    WHEN b.Route_to_another_AM__c_MS = TRUE  THEN FALSE   -- #2 routed to AM
    ELSE TRUE
  END AS Is_Deflected,
  TRUE AS Is_Eligible,
  1 AS Total_Interactions
FROM WA_target_whatsapp_sessions b
LEFT JOIN WA_calendly_matched cal ON b.Id_MS_Inbound = cal.Id_MS_Inbound AND cal.rnk_cal = 1
LEFT JOIN WA_task_matched     tk  ON b.Id_MS_Inbound = tk.Id_MS_Inbound  AND tk.rnk_task = 1
LEFT JOIN WA_ticket_matched   tm  ON b.Id_MS_Inbound = tm.Id_MS_Inbound  AND tm.rnk_ticket = 1;
```

> ### ★ WhatsApp deflection rule (MANDATORY)
> WhatsApp deflection **requires all five leakage signals** above — escalation (`AgentType <> 'Bot'`),
> `Route_to_another_AM__c = TRUE`, a Calendly booking within 14 days, a `Missed Whatsapp` task
> referencing the session Id, and a same-customer Email/Portal case within 24h. They are **part of the
> definition, not optional refinements.** Signals #3–#5 need the identity-chain joins
> (`EndUserAccountId` → `accountidmappingtable` → GCID/CID → PII email / case).
> **Do not skip them and do not approximate** — omitting #3–#5 overstates the rate by ~17pp
> (e.g. 90.7% vs the correct 73.8% over a recent 30-day window), with the "Missed Whatsapp" task (#4)
> the dominant cause at ~12% of eligible sessions. **If you cannot run the identity-chain joins, do not
> report a WhatsApp deflection number — state that the calculation is unavailable** rather than
> returning a partial figure. Adapt the canonical `WA_Final` SQL above; do not reconstruct it from prose.

**Ticket / auto-resolved deflection:** a Portal/Email case that is `IsClosedOnCreate = TRUE`,
falls into an automation `classification` bucket, has non-US registration country, and has **no
follow-up within 24h** where (same `Category__c` **OR** follow-up `Origin IN ('Chatbot','Chat')`).
This four-part condition is the canonical `Ticket_Final.Is_Deflected` flag (note it already
requires `IsClosedOnCreate = TRUE`) and is the **fixed numerator** for every ticket-deflection
rate below.

> ### ⚠️ Ticket Anti-Pattern Warning (CRITICAL)
> **Do NOT approximate ticket deflection** by just checking `IsClosedOnCreate = TRUE` + no follow-up.
> That approach gives ~99% "deflection" (meaningless) because it skips the eligibility gate.
> The eligibility gate (classification bucket + non-US registration country) reduces the
> relevant population from ~62K total tickets to ~4K eligible tickets (~6% eligibility rate).
> Without eligibility, the deflection numerator is wrong by ~30×.
>
> **Registration country join:** The US exclusion requires joining through
> `general.bronze_etoro_customer_customer_masked` (on CID/GCID) →
> `general.bronze_etoro_dictionary_country` (on country key → `Name != 'United States'`).
> Do NOT use `case.Country__c` — it is NULL for ~80% of Portal/Email tickets.
>
> **Classification bucket:** The automation `classification` is derived from a mapping of
> `Category__c` / `Type__c` / `Sub_Type__c` to recognized automation template categories.
> A ticket with no matching classification is NOT eligible. The exact mapping is maintained
> by the Autoresolved Cases team — query it dynamically or reference the Tableau workbook
> calculated field. TODO: Add the canonical classification CASE WHEN mapping here.

The Tickets tile shows the **same deflected numerator** over **two different denominators** — they
answer different questions, and the whole gap between them is the eligibility rate:

| Rate | Formula | What it measures | Recent 30-day value |
|---|---|---|---|
| **All-Tickets Deflection** | deflected ÷ all Portal/Email tickets (Total Tickets) | Of all inbound non-chat tickets, share auto-resolved-and-deflected | ≈ 0.8% |
| **Automation-Eligible Deflection** (`% DeflectedEligibleTickets`) | deflected ÷ EligibleAutomationTickets (classified + non-US, any close status) | Of tickets that could be automated, share auto-resolved-and-deflected | ≈ 46.5% |

The eligible rate further decomposes into two stages (this is the intended reading — keep it):

- **auto-close rate** = (eligible AND `IsClosedOnCreate`) ÷ eligible — fraction of eligible tickets the templates actually auto-closed (≈ 51%).
- **deflection quality (stick rate)** = deflected ÷ (eligible AND `IsClosedOnCreate`) — of those auto-closed, fraction with no qualifying 24h re-contact (≈ 90%).
- So Automation-Eligible Deflection = auto-close rate × deflection quality, and
- All-Tickets Deflection = eligibility rate × auto-close rate × deflection quality
  (eligibility rate ≈ 1.8% — only ~1 in 55 inbound Portal/Email tickets is automation-eligible).

> ### ★ Ticket deflection rule (MANDATORY)
> When a user asks about ticket / auto-resolved deflection, report **both** the All-Tickets rate
> and the Automation-Eligible rate, and explicitly state the eligibility rate that connects them
> (the deflected numerator is identical; only the denominator differs). Never present the All-Tickets
> figure (~0.8%) on its own — without the eligibility context it reads as "almost nothing deflects,"
> when the reality is "almost nothing is eligible, but ~half of what is eligible deflects." Keep the
> decomposition framing (eligible deflection = auto-close rate × deflection quality). Use the canonical
> Ticket_Final SQL; the numerator must require `IsClosedOnCreate = TRUE`. Do not report
> "deflected ÷ closed-on-create cases" as a standalone rate: ~96% of Portal/Email tickets are
> `IsClosedOnCreate = TRUE`, so that denominator is essentially the whole population (not a
> template-specific subset) and collapses to ~0.9% — meaningless as a "template deflection" figure. The
> numeric values above are from a recent 30-day window and are illustrative, not fixed (period is
> always query-time).

**Unified deflection (deflection dashboard output):** all three channels UNION'd into
`Interaction_ID / Channel ('Web Chat'|'WhatsApp'|'Ticket') / Is_Deflected / Is_Eligible`.
- **deflected inquiries** = `COUNTD(IF Is_Deflected THEN Interaction_ID END)`.
- **all inquiries** = `COUNTD(Interaction_ID)`. **% Deflected Inquiries** = deflected `/ all`.
- **EligibleAutomationTickets** = `COUNTD(IF Is_Eligible THEN Interaction_ID END)`;
  **% DeflectedEligibleTickets** = `deflected inquiries / EligibleAutomationTickets`.

> ### ★ Headline "deflection rate" rule (MANDATORY)
> When a user asks for **"the deflection rate"** with **no channel specified**, return the
> **combined Web bot + WhatsApp** rate (deflected Web+WhatsApp ÷ all Web+WhatsApp inquiries),
> **excluding auto-resolved Tickets**. The answer **must** state: "this includes Web bot and
> WhatsApp and excludes auto-resolved tickets; ask if you want Web-only, WhatsApp-only, or
> tickets specifically." Note the WhatsApp component **must** use the full five-signal logic
> (see the ★ WhatsApp deflection rule) — a combined rate built on a partial WhatsApp number is wrong.

### Customer feedback / CSAT
- **#Positive Feedback** = `COUNTD(IF User_Feedback__c='Positive' THEN feedback_entry_id END)`;
  **#Negative Feedback** = same for `'Negative'`; **Neutral/Null** = `COUNTD(IF User_Feedback__c IS NULL ...)`.
- **CSAT Score** = `#Positive / (#Positive + #Negative) * 100` (a.k.a. *session entry feedback score*).
- **%Positive / %Negative session entry feedbacks** = each over `(#Positive + #Negative)`.
- **%Userfeedback response rate** = `(#Positive + #Negative) / (Neutral + #Positive + #Negative)`.
- **#CustomersWithFeedback** = `COUNTD(IF User_Feedback__c IS NOT NULL THEN CID/Customer_CID END)`.

> ### ★ CSAT scope rule (MANDATORY)
> CSAT/feedback is **Web-bot-only** — verified that **no WhatsApp sessions carry feedback**.
> The headline feedback/CSAT answer must state it covers the **Web bot only** (WhatsApp has no
> feedback signal). "Feedback score" = totals: positive ÷ (positive + negative).

### Chatbot quality (legacy-era only — see §Deprecated)
- **#CountofSessions** = `COUNTD(IF CP Valid AND MasterLabel='Customer Service Web Chat' THEN Id_MessagingSession END)`.
- **#ChatsWithErrors** = sessions with a non-null `Messaging_session_id_bw` (i.e. a bot_request error).
  **%ChatsWithErrors** = `#ChatsWithErrors / #CountofSessions`.
- **% content filtered** = blocked-word sessions ÷ sessions (uses `Blocked_word_bw`).
- **#Inactive chats** = `COUNTD(IF IsEndedDueToInactivity AND CP Valid THEN Id_MessagingSession END)`;
  **%Inactive chats** = `#Inactive chats / #CountofChats`.

### Auto-resolved ticket economics (Autoresolved dashboard)
- **# cases closed on creation** = `COUNTD(IF IsClosedOnCreate AND CP Valid THEN CaseNumber END)`.
- **count deflected cases (and closed on creation)** = `COUNTD(IF IsDeflected AND IsClosedOnCreate AND CP Valid THEN CaseNumber END)`.
- **%DeflectionRate (closed on creation cases)** = deflected-and-closed ÷ `# cases closed on creation`.
- **Amount Saved** = `count deflected cases (and closed on creation) × Cost per case`.
- **Cost per case** = parameter, **default $18**.
- **IsVisitor** = `ISNULL(CID__c)` (anonymous / non-logged-in submitter).

> ### ★ Savings rule (MANDATORY)
> When asked about savings, you **may** use **$18/case** as the default, but the answer **must**
> state that $18 was the value used and that the user can supply a different per-case cost.

### Engagement context
- **Daily_Login_Count** = `COUNT(DISTINCT gcid)` where `ActionTypeID = 14`, per day. Presented
  standalone alongside chat volume to look for engagement-vs-logins correlation. Not a denominator.

---

## Business Rules and Edge Cases

1. **Time period is always a query-time question.** The date floors hardcoded in the SQL
   (`2024-01-01`, `date_trunc('year', current_date) - interval '1 year'`, `2024-11-22`,
   `2026-02-10`, `2025-04-02`) are **extraction-weight guardrails, not the date a metric becomes
   meaningful — relevant data often exists earlier**. **Whenever a user asks about any metric without
   naming a time period, ask which period they mean before running anything.** Never assume a default window.

2. **Origin semantics:** `Chatbot` = started **and** ended with the bot (contained);
   `Chat` = started with bot, **escalated** to a human agent; `Portal`/`Email` = non-chat inbound.
   No other origins are in scope for chat metrics.

3. **Deflection re-contact window** is **24 hours**, same `CID__c` + same `Category__c`, follow-up
   `Origin IN ('Email','Portal')` for **chat**. **Tickets** additionally count a `Chatbot`/`Chat`
   follow-up as breaking deflection. WhatsApp uses the leakage-signal set instead.

4. **Quality gates:** legacy chat excludes `visitormessagecount = 0` ("ghost chats") and
   `Bot_Eligible__c = False`. New MessagingSession needs none — a session is created only after the
   customer sends a message. WhatsApp deflection requires `EndUserMessageCount > 0` and excludes
   `Origin = 'TriggeredOutbound'`.

5. **`Chat`-origin mixed population:** drop `Chat` cases that have neither a transcript nor a
   messaging session (the relevance gate in the final WHERE).

6. **WhatsApp has no case and no feedback.** Measure WhatsApp at **session grain** via
   `messagingsession`; resolve CID via `accountidmappingtable`. WhatsApp is **excluded from CSAT**.

7. **Deprecated / time-boxed metrics:** **error rate** and **% content filtered** rely on
   `etoro_assistant_bot_request__c.Response__c.errorText`, which **stopped populating after ~Oct 2025**.
   Treat these as **legacy-bot-era only (≈ valid through Oct 2025)** and do not report them for later
   periods. No replacement error signal exists in the MessagingSession architecture at this time.

8. **Data-quality exclusion:** `date(messagingsession.CreatedDate) <> '2025-05-28'` (bad day). Also
   watch for isolated one-day WhatsApp volume spikes (~7× baseline) that may be bulk/triggered events;
   flag and verify before reporting them as a trend.

9. **Timestamp casting:** `case.CreatedDate`/`ClosedDate` are ISO-8601 **strings** — always
   `to_timestamp(col, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")`. For single-day filters on timestamps use a
   range (`>= d AND < d+1`), never equality.

10. **US exclusion** applies to the **Ticket** channel: registration country must be non-US, and a
    case needs a non-null automation `classification` to be eligible.

11. **WhatsApp leakage is all-or-nothing (MANDATORY).** WhatsApp deflection is defined by **all five**
    leakage signals (#1 escalation, #2 route-to-AM, #3 Calendly ≤14d, #4 Missed-Whatsapp task,
    #5 cross-channel Email/Portal ≤24h). Signals #3–#5 require the identity-chain joins. **Never report
    a WhatsApp deflection figure that omits any of them** — doing so overstated a recent 30-day window
    by ~17pp (90.7% reported vs 73.8% correct). If the identity-chain tables/joins are unavailable,
    report WhatsApp deflection as **unavailable**, not approximate. Use the canonical `WA_Final` SQL.

---

## Migration: LiveChatTranscript → MessagingSession

The chat architecture moved from Salesforce **LiveChatTranscript** to **MessagingSession**. Verified
from row counts of case→artifact linkage:

| Period | State |
|---|---|
| Before **~Apr 2025** | Exclusively LiveChatTranscript-linked; **zero** MessagingSession links |
| **~Apr – Sep 2025** | Transition / overlap — both populated simultaneously |
| **From ~Oct 2025** | Fully on MessagingSession; LCT links drop to near-zero stragglers |

Implications for queries:
- For chat sessions/feedback, an `ai_session__c` links via `Chat_Transcript__c` (legacy) **or**
  `Messaging_Session__c` (new). Always cover **both** (UNION ALL) for any cross-era window.
- `ChannelType` value for Web chat in MessagingSession is **`EmbeddedMessaging`**.
- The error/content-filter feed dying (~Oct 2025) coincides with the legacy bot being retired.

---

## Glossary of Domain Terms

| Term | Meaning |
|---|---|
| **Origin = Chatbot** | Contact handled start-to-finish by the bot (contained) |
| **Origin = Chat** | Contact that started with the bot and escalated to a human agent |
| **Origin = Portal / Email** | Non-chat inbound contact |
| **Deflected** | Automated interaction resolved with no human agent and no qualifying follow-up |
| **Escalated** | A chat that was handed to a human agent (`Origin='Chat'`) |
| **CSAT / feedback score** | `positive / (positive + negative) × 100`, from per-message `User_Feedback__c`; **Web bot only** |
| **Auto-resolved / autosolved ticket** | Portal/Email case `IsClosedOnCreate=TRUE`, classified, non-US, not re-contacted in 24h |
| **EligibleAutomationTickets** | Tickets meeting classification + non-US criteria (deflection denominator for tickets) |
| **All-Tickets Deflection** | deflected ÷ all Portal/Email tickets (Total Tickets); the headline ~0.8% tile. Only meaningful when reported with the eligibility rate (see ★ Ticket deflection rule) |
| **Automation-Eligible Deflection** | `% DeflectedEligibleTickets` = deflected ÷ EligibleAutomationTickets; the ~46.5% tile = auto-close rate × deflection quality |
| **auto-close rate / deflection quality** | Ticket decomposition: auto-close rate = (eligible AND `IsClosedOnCreate`) ÷ eligible (≈51%); deflection quality / stick rate = deflected ÷ (eligible AND `IsClosedOnCreate`) (≈90%). Their product = Automation-Eligible Deflection |
| **eligibility rate (tickets)** | EligibleAutomationTickets ÷ all Portal/Email tickets (≈1.8%); the factor separating All-Tickets Deflection from Automation-Eligible Deflection |
| **CP Valid / CP Valid ms / CP Valid unified** | Current-period filter on case date / messaging-session date / unified date |
| **Unified Date** | `IFNULL(CreatedDate_Case, CreatedDate_MessagingSession)` — handles the FULL OUTER null side |
| **IsEndedDueToInactivity** | Session whose Status changed `Inactive → Ended` |
| **IsVisitor** | `ISNULL(CID__c)` — anonymous / non-logged-in contact |
| **leakage (WhatsApp)** | Any signal that a WhatsApp bot session did not actually deflect. There are **exactly five, all mandatory**: (1) escalation `AgentType<>'Bot'`, (2) `Route_to_another_AM__c=TRUE`, (3) Calendly booking ≤14d, (4) `Missed Whatsapp` task referencing the session (largest, ~12% of eligible), (5) same-customer Email/Portal case ≤24h. Omitting any of #3–#5 invalidates the rate (~17pp overstatement). |
| **WhatsApp identity chain** | `EndUserAccountId` → `accountidmappingtable` → GCID/CID → PII email / case; required to evaluate leakage signals #3–#5 |
| **Bot_Eligible__c** | Legacy transcript flag; `False` rows excluded from the chat model |
| **ghost chat** | Legacy transcript with `visitormessagecount = 0` (no customer message) — excluded |
| **ChannelType** | `EmbeddedMessaging` = Web chat; `WhatsApp` = WhatsApp |
| **Cost per case** | Per-case savings constant, default **$18**, user-overridable |

---

## MCP Query Guidance

### Questions this layer supports
- "What's our deflection rate **last 90 days**?" → combined **Web bot + WhatsApp**, exclude tickets,
  and **state that scope** (offer Web-only / WhatsApp-only / tickets on request). The WhatsApp part
  **must** use the full five-signal logic.
- "Web bot deflection rate for **May 2026**." → `%DeflectionRate` (Web), Chatbot deflected ÷ all Chat+Chatbot cases.
- "WhatsApp deflection **this quarter**." → session-grain WhatsApp logic with **all five** leakage
  signals (escalation, route-to-AM, Calendly ≤14d, Missed-Whatsapp task, cross-channel ticket ≤24h);
  use the canonical `WA_Final` SQL.
- "How many tickets did we auto-resolve, and how much did that save?" → closed-on-create deflected
  cases × **$18** (state the $18 assumption and override option).
- "What's our **ticket / auto-resolved deflection rate**?" → report **both** All-Tickets (≈0.8%) and
  Automation-Eligible (≈46.5%) and state the connecting eligibility rate (~1.8%); **never give the
  All-Tickets number alone** (see the ★ Ticket deflection rule).
- "What's our **CSAT / feedback** score **last 30 days**?" → positive ÷ (positive + negative),
  **Web bot only** (state that WhatsApp has no feedback).
- "Case distribution by Origin / Country / Regulation / Club level for period X."
- "Escalation rate", "inactive-chat rate", "chat volume vs daily logins" for period X.
- Bot error rate / content-filter rate — **only if the period is within ≈ Apr–Oct 2025**; otherwise
  explain the signal is deprecated.

### Mandatory behaviors before/within an answer
1. **No time period given → ask for one** (extraction-weight guardrails are not metric start dates).
2. **Unqualified "deflection rate" → Web bot + WhatsApp combined, tickets excluded, and say so.**
3. **Unqualified "CSAT/feedback" → Web bot only, and say so.**
4. **Savings → default $18/case, state the value used and that it's overridable.**
5. Always cast `case` date strings with `to_timestamp(...)`; use date **ranges**, not equality, for single days.
6. Cover **both** AI-session FKs (transcript + messaging session) for any cross-era feedback window.
7. **WhatsApp deflection → all five leakage signals are required.** Never approximate by escalation
   (and route-to-AM) alone; signals #3–#5 need the identity-chain joins. If those joins can't run,
   report the WhatsApp figure as **unavailable** rather than partial. Adapt the canonical `WA_Final` SQL.
8. **Ticket / auto-resolved deflection → report both rates with the eligibility rate.** Give the
   All-Tickets rate (≈0.8%) and the Automation-Eligible rate (≈46.5%) and state the eligibility
   rate (~1.8%) that links them; never report the All-Tickets figure alone. Keep the
   eligible = auto-close rate × deflection-quality decomposition. Numerator must require
   `IsClosedOnCreate = TRUE`; adapt the canonical Ticket_Final SQL (see the ★ Ticket deflection rule).

### Known limitations / out of scope
- Bot **error rate** and **% content filtered** after ~Oct 2025 (signal discontinued).
- WhatsApp **CSAT/feedback** (no feedback rows exist for WhatsApp).
- Case-level `Chat_Score__c` / `SLA_Score__c` / `Score__c` as CSAT (not trusted — do not use).
- Cross-channel CSAT (CSAT is Web-only by data availability).
- Any contact origin outside `Chatbot / Chat / Portal / Email / WhatsApp`.
- A WhatsApp deflection figure computed **without** leakage signals #3–#5 (Calendly / Missed-Whatsapp
  task / cross-channel ticket) is **invalid**, not a rounding approximation — it overstates by ~17pp.
  Report "unavailable" instead of a partial number when the identity chain can't be joined.
- "deflected ÷ closed-on-create cases" reported **alone** as a "ticket deflection rate" is meaningless
  (~96% of Portal/Email tickets are `IsClosedOnCreate = TRUE`, so it collapses to ~0.9%). Always pair
  the All-Tickets rate with the Automation-Eligible rate and the eligibility rate.
