# BI_DB_dbo.BI_DB_SF_Cases_Panel

> 4.8M-row Salesforce customer support case panel table covering January 2020 through April 2024. Each row represents one support ticket with dual-snapshot attributes captured at ticket open (`_AtOpen`) and at the latest update (`_Last`), plus boolean classification flags and case metrics. Loaded externally via SP_SF_Cases (not in SSDT repo). Last updated 2024-04-08; appears dormant since then.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Salesforce CRM Cases (external ETL via SP_SF_Cases — SP not in SSDT repo) |
| **Refresh** | Unknown (dormant since 2024-04-08; loaded via OpsDB "COPY DATA" process) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CaseNumber ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a **Salesforce Cases panel** containing 4,794,836 support tickets created between 2020-01-01 and 2024-04-07. Each row represents a single customer support case from the Salesforce CRM system, identified by CaseNumber (clustered index) and TicketID (Salesforce 18-character ID).

The table uses a **dual-snapshot pattern**: for each case, 22 attribute columns are captured both at ticket creation time (`_AtOpen` suffix) and at the latest status update (`_Last` suffix). This allows analysts to compare the customer's state when they opened the ticket versus their current/final state (e.g., regulation changes, club tier upgrades, country changes).

The writer SP `SP_SF_Cases` is registered in OpsDB under the "COPY DATA" process but its source code is not present in the SSDT repository, indicating an external Salesforce ETL pipeline. The table sits at dependency depth 0 (no upstream Synapse dependencies) and feeds into downstream AML/compliance SPs including SP_AML_ASIC_Dashboard, SP_AML_KYC_SOF, SP_AML_Periodic_Review, SP_M_AML_Account_Closed, SP_CID_MonthlyPanel_FullData, and SP_US_Apex_Rejected_Accounts.

The majority of tickets (85%) are Closed, with the remainder in states like "created" (12%), "Solved" (1.7%), "Rejected", "In Routing", "Open", "New", "Pending", and "On-hold". Top case types include Other, Finance/Operations, General Platform, and Technical. Cases span 200+ countries with the UK, Germany, US, France, and Italy leading.

---

## 2. Business Logic

### 2.1 Dual-Snapshot Pattern (_AtOpen vs _Last)

**What**: Each case carries two snapshots of customer and ticket attributes — one frozen at ticket creation, one reflecting the latest state.
**Columns Involved**: All `*_AtOpen` and `*_Last` paired columns (HistoryID, IsVisitor, DepositorType, Regulation, ClubTier, Role, SubRole, ServiceLanguage, ServiceDesk, Phase, Source, Priority, Product, Type, ActionType, SubType, SubType2, Country, PlayerStatus, AccountManagerID, ActiveAgentID, Owner, VerificationLevelID).
**Rules**:
- `_AtOpen` values are frozen at ticket creation and never change
- `_Last` values update as the ticket progresses through its lifecycle
- Comparing the two reveals customer state changes during the support interaction (e.g., regulation migration, tier upgrades)
- CID is only captured in the `_Last` snapshot (CID_Last); there is no CID_AtOpen column

### 2.2 Case Classification Flags

**What**: Boolean flags categorize cases into operational buckets for reporting.
**Columns Involved**: IsSupervisorCall, IsT3, IsTechnicalTeam, IsPPReport, IsTmail, IsCOCall, IsCHBCase, IsCOCase, IsRisk, IsOfficial, IsSpam, IsReopened, IsInternal, IsKYcMonitoring, IsTechnicalRefund, IsSocial, IsGoodwill, IsOneTouch.
**Rules**:
- Flags are not mutually exclusive — a case can be flagged as both IsRisk and IsCOCase
- IsTechnicalRefund and IsGoodwill are numeric(18,0) rather than bit, allowing non-boolean values
- IsOneTouch = 1 when the case was resolved in a single interaction (NumberOfTocuhes = 1)
- IsReopened tracks whether the case was closed and then reopened

### 2.3 Case Type Hierarchy

**What**: Three-level categorization hierarchy for ticket classification.
**Columns Involved**: Type_AtOpen/Type_Last, ActionType_AtOpen/ActionType_Last, SubType_AtOpen/SubType_Last, SubType2_AtOpen/SubType2_Last.
**Rules**:
- Type is the top-level category (Finance/Operations, General Platform, Technical, Trading Information, etc.)
- ActionType is the second level (KYC, Risk, Withdrawal, Trading, etc.)
- SubType and SubType2 provide progressively finer classification
- NULL/empty SubType2 is common — many cases only classify to SubType depth

### 2.4 CSAT Scoring

**What**: Customer satisfaction scores captured for the case.
**Columns Involved**: FirstCSAT, LastCSAT.
**Rules**:
- FirstCSAT is the first CSAT survey response received for the case
- LastCSAT is the most recent CSAT survey response
- Both are frequently NULL — not all cases receive CSAT surveys
- Values are integer scores (exact scale not documented in DDL)

### 2.5 Complaint Escalation Phases

**What**: Regulatory complaint escalation tracking.
**Columns Involved**: IsNormal, IsComplaint, IsPhase2, IsPhase3.
**Rules**:
- IsNormal = 1 for standard (non-complaint) cases
- IsComplaint = 1 for cases classified as formal complaints
- IsPhase2 and IsPhase3 track escalation levels within the complaint process
- These flags are integers (not bit), allowing NULL values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no co-location benefit for JOINs; all JOINs require data movement
- **Clustered Index**: CaseNumber ASC — point lookups and range scans on CaseNumber are efficient
- **No partition**: The table is not partitioned; full scans on date ranges will read all 4.8M rows

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Find all open AML cases for a customer | `WHERE CID_Last = @CID AND UPPER(ActionType_AtOpen) LIKE '%AML%' AND TicketStatus NOT IN ('Closed','Solved')` |
| Count tickets by status | `SELECT TicketStatus, COUNT(*) FROM BI_DB_SF_Cases_Panel GROUP BY TicketStatus` |
| Identify customer state changes during case lifecycle | Compare `Regulation_AtOpen` vs `Regulation_Last`, `ClubTier_AtOpen` vs `ClubTier_Last`, etc. |
| Find last AML ticket date per customer | `SELECT CID_Last, MAX(CreatedDate) WHERE UPPER(ActionType_AtOpen) LIKE '%AML%' GROUP BY CID_Last` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | CID_Last = Dim_Customer.RealCID | Enrich case data with full customer profile |
| BI_DB_dbo.BI_DB_KYC_Panel | CID_Last = KYC_Panel.CID | Cross-reference KYC and support case history |
| BI_DB_dbo.BI_DB_PositionPnL | CID_Last = PositionPnL.CID | Correlate trading activity with support tickets |

### 3.4 Gotchas

- **NumberOfTocuhes** has a typo (should be "Touches") — use the exact misspelled name in queries
- **IsVisitor_Atopen** uses mixed casing (`_Atopen` not `_AtOpen`) — inconsistent with other `_AtOpen` columns; similarly `ActiveAgentID_Atopen` and `Owner_Atopen`
- **CID_Last** has no `_AtOpen` counterpart — customer ID is only captured at the latest snapshot
- **IsTechnicalRefund** and **IsGoodwill** are `numeric(18,0)` not `bit` — filter with `= 1` not `= True`
- **Data appears dormant since April 2024** — max UpdateDate is 2024-04-08. Recent ticket data may not be present
- **TicketStatus "created"** is lowercase while other statuses are title-cased — use case-insensitive comparison or check for both

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source documented) |
| Tier 2 | Derived from SP code or ETL logic with identifiable source table |
| Tier 3 | Grounded in DDL + live data evidence; no upstream wiki or SP source available |
| Tier 4 | Inferred from column name only (banned in this wiki) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CreatedDate | datetime | YES | Timestamp when the Salesforce support case was created. Range: 2020-01-01 to 2024-04-07. (Tier 3 — Salesforce Cases, external ETL) |
| 2 | LastStatusDate | datetime | YES | Timestamp of the most recent status change on the case. (Tier 3 — Salesforce Cases, external ETL) |
| 3 | TicketStatus | nvarchar(255) | YES | Current status of the support ticket. Values observed: Closed, created, Solved, Rejected, In Routing, Open, New, Pending, On-hold, Approved, On-hold 2 weeks, On-hold 3 days, Verification, On-hold 1 week, Canceled, On it, In Development (17 distinct). (Tier 3 — Salesforce Cases, external ETL) |
| 4 | CaseNumber | int | YES | Unique Salesforce case number. Clustered index key. Range observed: 755826–3423143+. (Tier 3 — Salesforce Cases, external ETL) |
| 5 | TicketID | nvarchar(18) | YES | Salesforce 18-character record ID for the case object. (Tier 3 — Salesforce Cases, external ETL) |
| 6 | HistoryID_AtOpen | nvarchar(18) | YES | Salesforce 18-character record ID for the customer history snapshot at the time the case was opened. (Tier 3 — Salesforce Cases, external ETL) |
| 7 | IsVisitor_Atopen | int | NO | Whether the customer was a visitor (non-depositor) at the time the case was opened. 0 = not a visitor, 1 = visitor. (Tier 3 — Salesforce Cases, external ETL) |
| 8 | DepositorType_AtOpen | varchar(4) | YES | Customer depositor classification at case open. Observed values include MTD (multi-time depositor), OTD (one-time depositor), Lead. NULL for visitors. (Tier 3 — Salesforce Cases, external ETL) |
| 9 | Regulation_AtOpen | nvarchar(1300) | YES | Regulatory jurisdiction applicable to the customer at case open. Observed values: FCA, CySEC, ASIC, BVI, FSA Seychelles, ASIC & GAML, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 10 | ClubTier_AtOpen | varchar(50) | YES | Customer club/loyalty tier at case open. Observed values: Bronze, Gold, and others. NULL for visitors. (Tier 3 — Salesforce Cases, external ETL) |
| 11 | Role_AtOpen | nvarchar(255) | YES | Agent or team role assigned to the case at open. Observed values: OPS Teams, Tier 3, and others. NULL when unassigned. (Tier 3 — Salesforce Cases, external ETL) |
| 12 | SubRole_AtOpen | nvarchar(1300) | YES | Sub-role classification for the handling team at case open. Observed values: OPS, OPS CS World Check, CS Spanish, CS Chinese, CS English, CS German, CS Italian, Admin, Customer Service, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 13 | ServiceLanguage_AtOpen | nvarchar(255) | YES | Language of service provided at case open. Observed values: English, Spanish, Chinese, Italian, German, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 14 | ServiceDesk_AtOpen | nvarchar(1300) | YES | Service desk or queue handling the case at open. Observed values: English, Spanish, Chinese, Italian, Australia, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 15 | Phase_AtOpen | nvarchar(255) | YES | Case handling phase at open. Observed values: Normal, and others. NULL when not applicable. (Tier 3 — Salesforce Cases, external ETL) |
| 16 | Source_AtOpen | nvarchar(255) | YES | Channel through which the case was created. Observed values: Manually, Chat, Portal, Email, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 17 | Priority_AtOpen | nvarchar(40) | YES | Case priority level at open. Observed values: Normal, Low, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 18 | Product_AtOpen | nvarchar(255) | YES | Product the case relates to at open. Observed values: eToro Trading Platform, Customer, and others. NULL when not specified. (Tier 3 — Salesforce Cases, external ETL) |
| 19 | Type_AtOpen | nvarchar(255) | YES | Top-level case type category at open. Observed values: Finance/Operations, General Platform, Technical, Trading Information, Other, Account queries, Wallet, Partner Account, Risk and Compliance, and others (18 distinct). (Tier 3 — Salesforce Cases, external ETL) |
| 20 | ActionType_AtOpen | nvarchar(255) | YES | Second-level case action type at open. Observed values: Risk, KYC, Withdrawal, Trading, Account Details, How To, General Technical Issue, PEP/EPF, Redeems, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 21 | SubType_AtOpen | nvarchar(255) | YES | Third-level case sub-type at open. Observed values: Status of the withdrawal, My Profile / KYC, Login issues, Copy, PEP/EPF, Trading - Other, Fee charging, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 22 | SubType2_AtOpen | nvarchar(255) | YES | Fourth-level case sub-type at open. Observed values: WCH Hit - Docs Needed, Can't Login, Copy trader - Can't stop copying, and others. Frequently NULL. (Tier 3 — Salesforce Cases, external ETL) |
| 23 | Country_AtOpen | varchar(50) | YES | Customer country at case open. 223 distinct countries observed in data. Top values: United Kingdom, Germany, United States, France, Italy. (Tier 3 — Salesforce Cases, external ETL) |
| 24 | PlayerStatus_AtOpen | varchar(50) | YES | Customer player status at case open. Observed values: Normal, Pending Verification, and others. (Tier 3 — Salesforce Cases, external ETL) |
| 25 | AccountManagerID_AtOpen | int | YES | Internal account manager ID assigned to the customer at case open. (Tier 3 — Salesforce Cases, external ETL) |
| 26 | ActiveAgentID_Atopen | nvarchar(18) | YES | Salesforce 18-character ID of the agent actively handling the case at open. Note: column uses mixed casing `_Atopen`. (Tier 3 — Salesforce Cases, external ETL) |
| 27 | Owner_Atopen | nvarchar(50) | YES | Salesforce ID of the case owner at open. May be an individual agent ID or a queue ID. Note: column uses mixed casing `_Atopen`. (Tier 3 — Salesforce Cases, external ETL) |
| 28 | CID_Last | int | YES | Customer ID (CID) at the latest case snapshot. No `_AtOpen` counterpart exists. Used as the primary JOIN key to Dim_Customer and downstream AML SPs. (Tier 3 — Salesforce Cases, external ETL) |
| 29 | HistoryID_Last | nvarchar(18) | YES | Salesforce 18-character record ID for the customer history snapshot at the latest case update. (Tier 3 — Salesforce Cases, external ETL) |
| 30 | IsVisitor_Last | int | YES | Whether the customer is a visitor (non-depositor) at the latest case snapshot. 0 = not a visitor, 1 = visitor. (Tier 3 — Salesforce Cases, external ETL) |
| 31 | DepositorType_Last | varchar(4) | YES | Customer depositor classification at latest snapshot. Same domain as DepositorType_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 32 | Regulation_Last | varchar(50) | YES | Regulatory jurisdiction applicable to the customer at latest snapshot. Same domain as Regulation_AtOpen but narrower type (varchar(50) vs nvarchar(1300)). (Tier 3 — Salesforce Cases, external ETL) |
| 33 | ClubTier_Last | varchar(50) | YES | Customer club/loyalty tier at latest snapshot. Same domain as ClubTier_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 34 | Role_Last | nvarchar(255) | YES | Agent or team role assigned to the case at latest snapshot. Same domain as Role_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 35 | SubRole_Last | nvarchar(1300) | YES | Sub-role classification for the handling team at latest snapshot. Same domain as SubRole_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 36 | ServiceLanguage_Last | nvarchar(255) | YES | Language of service provided at latest snapshot. Same domain as ServiceLanguage_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 37 | ServiceDesk_Last | nvarchar(1300) | YES | Service desk or queue handling the case at latest snapshot. Same domain as ServiceDesk_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 38 | Phase_Last | nvarchar(255) | YES | Case handling phase at latest snapshot. Same domain as Phase_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 39 | Source_Last | nvarchar(255) | YES | Channel through which the case was created, at latest snapshot. Same domain as Source_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 40 | Priority_Last | nvarchar(40) | YES | Case priority level at latest snapshot. Same domain as Priority_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 41 | Product_Last | nvarchar(255) | YES | Product the case relates to at latest snapshot. Same domain as Product_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 42 | Type_Last | nvarchar(255) | YES | Top-level case type category at latest snapshot. Same domain as Type_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 43 | ActionType_Last | nvarchar(255) | YES | Second-level case action type at latest snapshot. Same domain as ActionType_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 44 | SubType_Last | nvarchar(255) | YES | Third-level case sub-type at latest snapshot. Same domain as SubType_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 45 | SubType2_Last | nvarchar(255) | YES | Fourth-level case sub-type at latest snapshot. Same domain as SubType2_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 46 | Country_Last | varchar(50) | YES | Customer country at latest snapshot. Same domain as Country_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 47 | PlayerStatus_Last | varchar(50) | YES | Customer player status at latest snapshot. Same domain as PlayerStatus_AtOpen. (Tier 3 — Salesforce Cases, external ETL) |
| 48 | AccountManagerID_Last | int | YES | Internal account manager ID assigned to the customer at latest snapshot. (Tier 3 — Salesforce Cases, external ETL) |
| 49 | ActiveAgentID_Last | nvarchar(18) | YES | Salesforce 18-character ID of the agent actively handling the case at latest snapshot. (Tier 3 — Salesforce Cases, external ETL) |
| 50 | Owner_Last | nvarchar(50) | YES | Salesforce ID of the case owner at latest snapshot. May be an individual agent ID or a queue ID. (Tier 3 — Salesforce Cases, external ETL) |
| 51 | FirstCSAT | int | YES | First customer satisfaction (CSAT) survey score recorded for this case. NULL when no survey was completed. (Tier 3 — Salesforce Cases, external ETL) |
| 52 | LastCSAT | int | YES | Most recent customer satisfaction (CSAT) survey score recorded for this case. NULL when no survey was completed. (Tier 3 — Salesforce Cases, external ETL) |
| 53 | IsSupervisorCall | bit | YES | Whether the case involved a supervisor call escalation. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 54 | IsT3 | bit | YES | Whether the case was escalated to Tier 3 support. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 55 | IsTechnicalTeam | bit | YES | Whether the case was handled by or escalated to the technical team. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 56 | IsPPReport | bit | YES | Whether the case is flagged as a Popular Investor (PP) report. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 57 | IsTmail | bit | YES | Whether the case originated from or involved a T-mail (internal messaging). 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 58 | IsCOCall | bit | YES | Whether the case involved a compliance officer call. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 59 | IsCHBCase | bit | YES | Whether the case is a chargeback-related case. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 60 | IsCOCase | bit | YES | Whether the case is a compliance officer case. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 61 | IsRisk | bit | YES | Whether the case is flagged as risk-related. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 62 | IsOfficial | bit | YES | Whether the case is an official complaint or formal inquiry. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 63 | IsSpam | bit | YES | Whether the case has been classified as spam. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 64 | IsReopened | bit | YES | Whether the case was closed and subsequently reopened. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 65 | IsInternal | bit | YES | Whether the case is an internal-only case (not customer-facing). 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 66 | IsKYcMonitoring | bit | YES | Whether the case is related to KYC monitoring activities. 0 = no, 1 = yes. Note: mixed casing in column name (KYc). (Tier 3 — Salesforce Cases, external ETL) |
| 67 | IsTechnicalRefund | numeric(18,0) | YES | Whether the case involves a technical refund. 0 = no, 1 = yes. Stored as numeric(18,0) rather than bit. (Tier 3 — Salesforce Cases, external ETL) |
| 68 | IsSocial | bit | YES | Whether the case originated from a social media channel. 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 69 | IsGoodwill | numeric(18,0) | YES | Whether the case involves a goodwill gesture or compensation. 0 = no, 1 = yes. Stored as numeric(18,0) rather than bit. (Tier 3 — Salesforce Cases, external ETL) |
| 70 | IsOneTouch | bit | YES | Whether the case was resolved in a single customer interaction (one-touch resolution). 0 = no, 1 = yes. (Tier 3 — Salesforce Cases, external ETL) |
| 71 | NumberOfTocuhes | numeric(18,0) | YES | Total number of customer touches/interactions for this case. Note: column name contains a typo ("Tocuhes" instead of "Touches"). (Tier 3 — Salesforce Cases, external ETL) |
| 72 | FirstResponse | datetime2(7) | YES | Timestamp of the first agent response to the customer on this case. NULL if no response was sent. (Tier 3 — Salesforce Cases, external ETL) |
| 73 | TotalTimeSpent | numeric(18,0) | YES | Total time spent on the case in minutes (or seconds — unit not confirmed from DDL). Observed values mostly 0 in sample. (Tier 3 — Salesforce Cases, external ETL) |
| 74 | NumberIncomingMessages | numeric(18,0) | YES | Count of incoming messages (customer to agent) on this case. NULL when not tracked. (Tier 3 — Salesforce Cases, external ETL) |
| 75 | NumberOutgoingMessages | numeric(18,0) | YES | Count of outgoing messages (agent to customer) on this case. (Tier 3 — Salesforce Cases, external ETL) |
| 76 | UpdateDate | datetime | NO | Timestamp of the last ETL update for this row. NOT NULL. Range: 2021-12-23 to 2024-04-08. (Tier 3 — Salesforce Cases, external ETL) |
| 77 | CloseDateTime | datetime | YES | Timestamp when the case was closed. NULL for cases that are still open or were never closed. (Tier 3 — Salesforce Cases, external ETL) |
| 78 | IsNormal | int | YES | Flag indicating the case is a standard (non-complaint) case. 1 = normal case, 0 or NULL = not a normal case. (Tier 3 — Salesforce Cases, external ETL) |
| 79 | IsComplaint | int | YES | Flag indicating the case is a formal complaint. 1 = complaint, 0 or NULL = not a complaint. (Tier 3 — Salesforce Cases, external ETL) |
| 80 | IsPhase2 | int | YES | Flag indicating the complaint has escalated to Phase 2 of the regulatory complaint process. 1 = escalated, 0 or NULL = not escalated. (Tier 3 — Salesforce Cases, external ETL) |
| 81 | IsPhase3 | int | YES | Flag indicating the complaint has escalated to Phase 3 of the regulatory complaint process. 1 = escalated, 0 or NULL = not escalated. (Tier 3 — Salesforce Cases, external ETL) |
| 82 | VerificationLevelID_AtOpen | int | YES | Customer verification level ID at case open. FK target unknown — no matching Dim table found in SSDT. (Tier 3 — Salesforce Cases, external ETL) |
| 83 | VerificationLevelID_Last | int | YES | Customer verification level ID at latest snapshot. FK target unknown — no matching Dim table found in SSDT. (Tier 3 — Salesforce Cases, external ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 83 columns | Salesforce CRM Cases | Corresponding Salesforce Case fields | External ETL via SP_SF_Cases (SP not in SSDT repo) |

### 5.2 ETL Pipeline

```
Salesforce CRM (Cases object)
  |-- SP_SF_Cases (external, not in SSDT; OpsDB "COPY DATA") ---|
  v
BI_DB_dbo.BI_DB_SF_Cases_Panel (4.8M rows, ROUND_ROBIN)
  |-- Read by SP_CID_MonthlyPanel_FullData ---|
  |-- Read by SP_AML_ASIC_Dashboard ---|
  |-- Read by SP_AML_KYC_SOF ---|
  |-- Read by SP_AML_Periodic_Review ---|
  |-- Read by SP_M_AML_Account_Closed ---|
  |-- Read by SP_US_Apex_Rejected_Accounts ---|
  v
BI_DB_dbo.BI_DB_CID_DailyPanel_FullData (downstream)
BI_DB_dbo.BI_DB_AML_ASIC_Dashboard (downstream)
BI_DB_dbo.BI_DB_AML_KYC_SOF (downstream)
BI_DB_dbo.BI_DB_AML_Periodic_Review (downstream)
BI_DB_dbo.BI_DB_M_AML_Account_Closed (downstream)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID_Last | DWH_dbo.Dim_Customer | Customer ID — joins to Dim_Customer.RealCID for full customer profile |
| AccountManagerID_AtOpen / AccountManagerID_Last | Unknown | Account manager lookup — FK target not identified in SSDT |
| VerificationLevelID_AtOpen / VerificationLevelID_Last | Unknown | Verification level lookup — FK target not identified in SSDT |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Purpose |
|---|---|---|
| SP_CID_MonthlyPanel_FullData | CID_Last = CID, ActionType_AtOpen LIKE '%AML%' | Extract last AML ticket date per customer for monthly panel |
| SP_AML_ASIC_Dashboard | CID_Last = CID | Join case data for ASIC AML dashboard |
| SP_AML_KYC_SOF | CID_Last = CID, ActionType_AtOpen LIKE 'AML', TicketStatus NOT IN ('Closed','Solved') | Filter active AML cases for KYC source-of-funds reporting |
| SP_AML_Periodic_Review | CID_Last = CID | Join case data for periodic AML review |
| SP_M_AML_Account_Closed | CID_Last = CID | Join case data for closed-account AML analysis |
| SP_US_Apex_Rejected_Accounts | Source table | US Apex rejected account analysis |

---

## 7. Sample Queries

### 7.1 Count Open AML Cases by Country

```sql
SELECT Country_Last,
       COUNT(*) AS open_aml_cases
FROM BI_DB_dbo.BI_DB_SF_Cases_Panel
WHERE UPPER(ActionType_AtOpen) LIKE '%AML%'
  AND TicketStatus NOT IN ('Closed', 'Solved')
GROUP BY Country_Last
ORDER BY open_aml_cases DESC;
```

### 7.2 Identify Cases Where Customer Regulation Changed

```sql
SELECT CaseNumber,
       CID_Last,
       Regulation_AtOpen,
       Regulation_Last,
       CreatedDate,
       CloseDateTime
FROM BI_DB_dbo.BI_DB_SF_Cases_Panel
WHERE Regulation_AtOpen <> Regulation_Last
  AND Regulation_AtOpen IS NOT NULL
  AND Regulation_Last IS NOT NULL
ORDER BY CreatedDate DESC;
```

### 7.3 Average Touches and CSAT by Case Type

```sql
SELECT Type_AtOpen,
       COUNT(*) AS total_cases,
       AVG(CAST(NumberOfTocuhes AS FLOAT)) AS avg_touches,
       AVG(CAST(LastCSAT AS FLOAT)) AS avg_csat
FROM BI_DB_dbo.BI_DB_SF_Cases_Panel
WHERE CreatedDate >= '2023-01-01'
  AND TicketStatus = 'Closed'
GROUP BY Type_AtOpen
ORDER BY total_cases DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness — Phase 10 skipped).

---

*Generated: 2026-04-30 | Quality: 6/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 83 T3, 0 T4, 0 T5 | Elements: 83/83, Logic: 7/10, Lineage: 5/10*
*Object: BI_DB_dbo.BI_DB_SF_Cases_Panel | Type: Table | Production Source: Salesforce CRM Cases (external ETL via SP_SF_Cases)*
