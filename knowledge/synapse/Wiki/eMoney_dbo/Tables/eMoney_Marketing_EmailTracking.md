# eMoney_dbo.eMoney_Marketing_EmailTracking

> Campaign-grain email marketing performance table tracking eToro Money acquisition campaigns sent via Salesforce Marketing Cloud (SFMC). Each row represents one campaign email on one send date for one country/club segment, aggregating delivery, engagement, and 3-day conversion metrics (account creation and card activation). Currently empty (0 rows) — the ETL SP is suspended (commented out in orchestration).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_SFMC_Report (Salesforce Marketing Cloud) via SP_eMoney_Marketing_EmailTracking |
| **Refresh** | Full DELETE + INSERT; currently suspended (SP commented out in SP_eMoney_Execute_Group_One SP 12); **table is empty** |
| **Synapse Distribution** | HASH(CampaignNumber) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`eMoney_Marketing_EmailTracking` is the eToro Money marketing campaign performance table. Each row represents **one email campaign on one send date for one country × club segment**, aggregating email engagement and 3-day conversion funnel metrics.

The table tracks eToro Money acquisition campaigns — marketing emails sent to existing eToro trading customers to encourage them to open an eToro Money account (FMI: First Money In) or activate an eTM card. Data is sourced from **Salesforce Marketing Cloud (SFMC)** via `BI_DB_dbo.BI_DB_SFMC_Report` which ingests email delivery and engagement events.

Key metrics captured:
- **Email delivery and engagement**: Delivered (distinct recipients), UniqueOpen, CountOpen, UniqueClicks, CountClicks
- **3-day account creation conversion**: CreatedAccount_Open (opened email → created eTM account within 3 days), CreateAccount_Clicks (clicked → created account), CreateAccount (open or click → created account)
- **3-day card activation conversion**: CardActivations (opened email → activated eTM card within 3 days; applicable to campaign 2208210977 only)

**Scope**: A hardcoded whitelist of ~20 specific campaign numbers is included (UK, UK IBAN, and EU IBAN acquisition campaigns from 2022 onward). The Country/Club values reflect the customer's status at send date (point-in-time from Fact_SnapshotCustomer), not current status.

**Current status (2026-04-21)**: The table is empty (0 rows). The SP (`SP_eMoney_Marketing_EmailTracking`) is commented out in `SP_eMoney_Execute_Group_One` (SP 12). Created by the eMoney & Wallet Data Analytics Team (Adi Meidan) on 2022-11-16. The table may be deprecated or temporarily suspended.

---

## 2. Business Logic

### 2.1 Campaign Whitelist Filter

**What**: Only a fixed set of ~20 campaign numbers are included. These represent eToro Money acquisition campaigns (UK, UK IBAN not yet live, EU IBAN).

**Columns Involved**: `CampaignNumber`, `CampaignName`, `EmailName`

**Rules**:
- UK campaigns: 5989, 9841, 9239, 8744, 2412, 4627
- UK IBAN (not yet live at time of SP creation): 1544, 7043, 6341, 4929, 0715
- EU IBAN campaigns: 3221, 9327, 5043, 6552, 7268, 8633, 2411212738, 2208211604, 2208210977
- A UNION brings in ALL campaigns from SFMC (not just the whitelist) for the second set — so the final data includes both whitelist-filtered and general SFMC data
- Filter: `Delivered = 1` (only delivered emails), `TriggeredSendExternalKey IS NOT NULL` (triggered sends only)

### 2.2 3-Day Conversion Window

**What**: Conversion attribution uses a 3-day window from first email open date.

**Columns Involved**: `CreatedAccount_Open`, `CreateAccount_Clicks`, `CreateAccount`, `CardActivations`

**Rules**:
- `FirstOpen` = MIN(OpenDate) for the recipient; '1900-01-01' sentinel if no open recorded
- **Account creation**: eTM account in `eMoney_Dim_Account` with `IsValidETM=1` AND `AccountCreateDate` within [FirstOpen, FirstOpen+3 days]
- **CreatedAccount_Open**: attributed to email opens (UniqueOpen=1)
- **CreateAccount_Clicks**: attributed to email clicks (UniqueClicks=1)
- **CreateAccount**: UNION of open+click attribution (attributed to either channel)
- **CardActivations**: `eMoney_Panel_FirstDates.CardActivationTime` within [FirstOpen, FirstOpen+3 days]; applies only to campaign 2208210977
- Only specific campaign numbers qualify for account creation tracking (12 campaigns hardcoded)

### 2.3 Point-in-Time Country/Club Snapshot

**What**: Country and Club reflect customer segmentation at the time of send date, not current state.

**Columns Involved**: `Country`, `Club`

**Rules**:
- Join to `Fact_SnapshotCustomer` using `DateRangeID` where `SendDateID BETWEEN FromDateID AND ToDateID`
- This ensures the customer's country and club tier are the values as of the email send date
- Customer eligibility filter: `IsValidCustomer=1`, `VerificationLevelID=3`, `PlayerLevelID<>4` (excludes demo accounts / unverified)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CampaignNumber) ensures campaign-level aggregations are single-node. The table is currently empty — validate data availability before querying. When populated, the table is expected to be small-to-medium (campaign × date × country × club granularity).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Campaign performance by date | `GROUP BY CampaignNumber, CampaignName, [Send Date]` |
| Conversion rate (account creation) | `SUM(CreateAccount) / NULLIF(SUM(Delivered), 0)` |
| UK vs EU campaign engagement | `WHERE Country LIKE '%United Kingdom%'` vs EU countries |
| Card activation effectiveness | `WHERE CardActivations > 0 AND CampaignNumber = '2208210977'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | `CID = (customer from campaign)` | Enrich with eTM account details |
| eMoney_dbo.eMoney_Panel_FirstDates | `CID` | Card activation events |

### 3.4 Gotchas

- **Table is currently empty**: SP is commented out in orchestration — verify data availability before use
- **Fixed campaign whitelist**: Only ~20 campaign numbers are tracked; newer campaigns added after the SP was frozen will not appear
- **1900-01-01 sentinel in FirstOpen**: Records with no email open have `FirstOpen='1900-01-01'`; the card activation step explicitly excludes these (`pp.FirstOpen <> '1900-01-01'`)
- **Point-in-time country/club**: Country and Club reflect values at send date — not current customer state
- **CardActivations scope**: Only campaign 2208210977 contributes to CardActivations; other campaigns will show 0
- **CreateAccount double-counting risk**: `CreateAccount` is a UNION of open and click conversions — a customer who both opened AND clicked is counted once

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description sourced verbatim from upstream production database wiki (highest confidence) |
| Tier 2 | Description derived from SP code, DDL, or DWH wiki (high confidence) |
| Tier 3 | Inferred from column name, data pattern, or business context (medium confidence) |
| Tier 4 | Best available knowledge — limited upstream documentation (lower confidence) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Send Date | date | YES | Email campaign send date. Converted from SendDateID (integer YYYYMMDD) from BI_DB_SFMC_Report. The primary partitioning dimension. Note: column name contains a space (use brackets in SQL). (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 2 | Country | varchar(50) | YES | Customer country name at the time of email send, sourced from DWH_dbo.Dim_Country via point-in-time Fact_SnapshotCustomer snapshot. Reflects country classification on the send date, not current state. (Tier 2 — SP_eMoney_Marketing_EmailTracking via Fact_SnapshotCustomer) |
| 3 | Club | varchar(50) | YES | Customer eToro loyalty club tier at time of email send (Silver, Gold, Platinum, Platinum Plus, Diamond). Sourced from Dim_PlayerLevel via Fact_SnapshotCustomer snapshot. (Tier 2 — SP_eMoney_Marketing_EmailTracking via Fact_SnapshotCustomer) |
| 4 | CampaignNumber | varchar(50) | YES | Salesforce Marketing Cloud campaign identifier. Distribution key. A hardcoded whitelist of ~20 campaign numbers is tracked (UK, UK IBAN, EU IBAN acquisition campaigns). (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 5 | CampaignName | varchar(250) | YES | Human-readable campaign name from SFMC. Describes the marketing campaign theme or target audience. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 6 | EmailName | varchar(250) | YES | Specific email template or variant name from SFMC. A campaign may use multiple email templates. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 7 | Delivered | int | YES | Count of distinct GCID recipients who received this campaign email (Delivered=1 filter in SFMC report). Aggregated per Send Date × Country × Club × CampaignNumber × EmailName group. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 8 | UniqueOpen | int | YES | Sum of unique email opens per group (SUM of SFMC UniqueOpen flag). Counts recipients who opened the email at least once. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 9 | CountOpen | int | YES | Sum of total email open events per group (including repeated opens by the same recipient). SUM of SFMC CountOpen. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 10 | UniqueClicks | int | YES | Sum of unique click events (recipients who clicked at least one link). SUM of SFMC UniqueClicks. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 11 | CountClicks | int | YES | Sum of total click events including multiple clicks by the same recipient. SUM of SFMC CountClicks. (Tier 2 — SP_eMoney_Marketing_EmailTracking via BI_DB_SFMC_Report) |
| 12 | CreatedAccount_Open | int | YES | Count of distinct customers who created a valid eTM account (IsValidETM=1 in eMoney_Dim_Account) within 3 days of first email open. Attribution channel: email open (UniqueOpen=1). Only specific campaign numbers qualify. (Tier 2 — SP_eMoney_Marketing_EmailTracking via eMoney_Dim_Account) |
| 13 | CreateAccount_Clicks | int | YES | Count of customers who created a valid eTM account within 3 days attributed to an email click (UniqueClicks=1, 3-day window from FirstOpen). (Tier 2 — SP_eMoney_Marketing_EmailTracking via eMoney_Dim_Account) |
| 14 | CreateAccount | int | YES | Total account creation conversions — UNION of open-attributed and click-attributed creations. Counts each converting customer once (deduplication via UNION). (Tier 2 — SP_eMoney_Marketing_EmailTracking via eMoney_Dim_Account) |
| 15 | CardActivations | int | YES | Count of distinct customers who activated an eTM card within 3 days of first email open. Applies only to campaign 2208210977; all other campaigns will show 0. Sources from eMoney_Panel_FirstDates.CardActivationTime. (Tier 2 — SP_eMoney_Marketing_EmailTracking via eMoney_Panel_FirstDates) |
| 16 | UpdateDate | datetime | YES | ETL run timestamp (GETDATE() at time of SP execution). All rows share the same UpdateDate since the SP does a full DELETE + INSERT in a single run. (Tier 2 — SP_eMoney_Marketing_EmailTracking) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Send Date | BI_DB_dbo.BI_DB_SFMC_Report | SendDateID | Date conversion from YYYYMMDD int |
| Country | DWH_dbo.Fact_SnapshotCustomer + Dim_Country | CountryID → Name | Point-in-time snapshot join |
| Club | DWH_dbo.Fact_SnapshotCustomer + Dim_PlayerLevel | PlayerLevelID → Name | Point-in-time snapshot join |
| CampaignNumber | BI_DB_dbo.BI_DB_SFMC_Report | CampaignNumber | Passthrough (whitelist filter) |
| CampaignName | BI_DB_dbo.BI_DB_SFMC_Report | CampaignName | Passthrough |
| EmailName | BI_DB_dbo.BI_DB_SFMC_Report | EmailName | Passthrough |
| Delivered | BI_DB_dbo.BI_DB_SFMC_Report | GCID | COUNT(DISTINCT GCID) where Delivered=1 |
| UniqueOpen, CountOpen | BI_DB_dbo.BI_DB_SFMC_Report | UniqueOpen, CountOpen | SUM per group |
| UniqueClicks, CountClicks | BI_DB_dbo.BI_DB_SFMC_Report | UniqueClicks, CountClicks | SUM per group |
| CreatedAccount_Open | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | 3-day attribution window |
| CreateAccount_Clicks | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | 3-day click attribution |
| CreateAccount | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | UNION open+click 3-day |
| CardActivations | eMoney_dbo.eMoney_Panel_FirstDates | CardActivationTime | 3-day open attribution (campaign 2208210977 only) |
| UpdateDate | SP | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_SFMC_Report (SFMC email delivery/engagement)
  + BI_DB_dbo.BI_DB_SFMC_SendJobs (filter: TriggeredSendExternalKey IS NOT NULL)
  + DWH_dbo.Dim_Customer (eligibility: IsValidCustomer=1, VerificationLevelID=3, PlayerLevelID<>4)
  + DWH_dbo.Fact_SnapshotCustomer (point-in-time country/club at SendDate)
  + DWH_dbo.Dim_Country + Dim_PlayerLevel (name lookups)
  + eMoney_dbo.eMoney_Dim_Account (3-day account creation conversion)
  + eMoney_dbo.eMoney_Panel_FirstDates (3-day card activation tracking)
    |-- SP_eMoney_Marketing_EmailTracking (full DELETE + INSERT) ---|
    |   Orchestrated via: SP_eMoney_Execute_Group_One (SP 12)        |
    |   STATUS: Currently commented out — table is empty             |
    v
eMoney_dbo.eMoney_Marketing_EmailTracking
  (0 rows — suspended as of 2026-04-21)
    |
    |-- UC Gold: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | DWH_dbo.Dim_Country | Country name via Fact_SnapshotCustomer (via ETL) |
| Club | DWH_dbo.Dim_PlayerLevel | Club tier via Fact_SnapshotCustomer (via ETL) |
| CreatedAccount_Open | eMoney_dbo.eMoney_Dim_Account | Account creation 3-day conversion (via ETL) |
| CreateAccount_Clicks | eMoney_dbo.eMoney_Dim_Account | Click-attributed account creation (via ETL) |
| CardActivations | eMoney_dbo.eMoney_Panel_FirstDates | Card activation conversion (via ETL) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers documented in existing wikis.

---

## 7. Sample Queries

### Campaign Engagement Summary (when populated)

```sql
SELECT CampaignNumber,
       CampaignName,
       [Send Date],
       SUM(Delivered) AS total_delivered,
       SUM(UniqueOpen) AS unique_opens,
       ROUND(100.0 * SUM(UniqueOpen) / NULLIF(SUM(Delivered), 0), 1) AS open_rate_pct,
       SUM(UniqueClicks) AS unique_clicks,
       SUM(CreateAccount) AS account_conversions,
       ROUND(100.0 * SUM(CreateAccount) / NULLIF(SUM(Delivered), 0), 2) AS conversion_rate_pct
FROM [eMoney_dbo].[eMoney_Marketing_EmailTracking]
GROUP BY CampaignNumber, CampaignName, [Send Date]
ORDER BY [Send Date] DESC;
```

### Country-Level Conversion Performance

```sql
SELECT Country,
       Club,
       SUM(Delivered) AS total_delivered,
       SUM(CreateAccount) AS accounts_created,
       SUM(CardActivations) AS cards_activated,
       ROUND(100.0 * SUM(CreateAccount) / NULLIF(SUM(Delivered), 0), 2) AS account_conv_rate
FROM [eMoney_dbo].[eMoney_Marketing_EmailTracking]
GROUP BY Country, Club
ORDER BY accounts_created DESC;
```

---

## 8. Atlassian Knowledge Sources

SP header note: Created 2022-11-16 by eMoney & Wallet Data Analytics Team (Adi Meidan). Change history mentions campaign 2941 added 2022-11-08 and new column `CreateAccount` added 2022-11-28. No Confluence sources found beyond this inline documentation.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 16 T2, 0 T3, 0 T4, 0 T5 | Elements: 16/16, Logic: 3 sections*
*Object: eMoney_dbo.eMoney_Marketing_EmailTracking | Type: Table | Production Source: SP_eMoney_Marketing_EmailTracking (BI_DB_SFMC_Report)*
