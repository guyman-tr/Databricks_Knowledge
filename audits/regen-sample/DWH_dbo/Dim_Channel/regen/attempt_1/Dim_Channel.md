# DWH_dbo.Dim_Channel

> 36-row marketing channel dimension table mapping every sub-channel to its parent channel and organic/paid classification. Sourced from the affiliate system's sub-channel unify-code reference table (`Ext_Dim_SubChannel_UnifyCode`) via `SP_Dim_Channel`. Truncated and reloaded daily by `SP_Dictionaries_DL_To_Synapse`. 20 distinct channels, 36 sub-channels.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel (truncate-and-reload) |
| **Refresh** | Daily (1440 min) — full truncate-and-reload via SP_Dictionaries_DL_To_Synapse |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (SubChannelID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, parquet → delta) |

---

## 1. Business Meaning

Dim_Channel is a small reference/dimension table (36 rows) that defines the marketing channel hierarchy used across eToro's acquisition and attribution reporting. Each row represents a unique sub-channel (e.g., "Google Search", "Taboola", "Direct Mobile") identified by `SubChannelID`, grouped under a parent `Channel` (e.g., "SEM", "Direct", "Affiliate"), and classified as either "Organic" or "Paid".

The table is sourced from `Ext_Dim_SubChannel_UnifyCode`, which is an external table loaded from the affiliate system (fiktivo `tblaff_Affiliates`). The writer SP (`SP_Dim_Channel`) performs a `SELECT DISTINCT` to deduplicate, then applies a CASE-based organic/paid classification before truncating and reloading the target.

SP_Dim_Channel also contains an alerting mechanism: when new sub-channels appear in the source that are not yet in `Dim_Channel`, an HTML email is sent to BI Data Solutions and the BI Analysis Team requesting immediate mapping.

The table is heavily referenced by downstream BI_DB reporting procedures (15+ SPs) for marketing attribution, acquisition funnels, and affiliate analytics.

---

## 2. Business Logic

### 2.1 Organic/Paid Classification

**What**: Each sub-channel is classified as "Organic" or "Paid" based on channel name and sub-channel name rules.
**Columns Involved**: Channel, SubChannel, Organic/Paid
**Rules**:
- Channel IN ('Friend Referral', 'Direct', 'SEO') → 'Organic'
- SubChannel = 'Google Brand' → 'Organic' (even though Channel = 'SEM')
- All other combinations → 'Paid'
- Current distribution: 30 Paid, 6 Organic

### 2.2 Channel Hierarchy

**What**: Two-level marketing hierarchy — Channel (parent) → SubChannel (child).
**Columns Involved**: Channel, SubChannel, SubChannelID
**Rules**:
- SubChannelID is the grain — one row per sub-channel
- A Channel can have 1–13 sub-channels (SEM has 13, most channels have 1)
- SubChannelID values are non-sequential (range 1–52, 36 active)
- Some sub-channels share the same name as their parent channel (e.g., Channel="Events", SubChannel="Events")

### 2.3 Unmapped Channel Alert

**What**: SP_Dim_Channel sends an email alert when new sub-channels appear in the source but are missing from Dim_Channel after load.
**Columns Involved**: SubChannelID, Channel, SubChannel
**Rules**:
- After INSERT, a LEFT JOIN check identifies rows in the source that have no matching SubChannelID in Dim_Channel
- If count > 0, an HTML email is generated listing the unmapped channels
- Recipients: bi-datasolutions@etoro.com, BIAnalysisTeam@etoro.com
- Subject: "New Channels in Affwizz - Need mapping ASAP"

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — appropriate for a 36-row dimension table. No skew concerns.
- **Index**: CLUSTERED INDEX on SubChannelID — supports point lookups when joining from fact tables on SubChannelID.
- At 36 rows, full table scans are negligible. No query optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What channel does SubChannelID X belong to? | `SELECT * FROM DWH_dbo.Dim_Channel WHERE SubChannelID = @id` |
| List all organic channels | `SELECT * FROM DWH_dbo.Dim_Channel WHERE [Organic/Paid] = 'Organic'` |
| How many sub-channels per channel? | `SELECT Channel, COUNT(*) AS SubChannels FROM DWH_dbo.Dim_Channel GROUP BY Channel ORDER BY SubChannels DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables with SubChannelID | `ON fact.SubChannelID = dc.SubChannelID` | Resolve marketing channel for customer acquisition |
| Dim_Customer (via SubChannelID) | `ON cust.SubChannelID = dc.SubChannelID` | Attribute customer to acquisition channel |
| BI_DB reporting tables | Various | Marketing cube, acquisition funnel, affiliate reporting |

### 3.4 Gotchas

- **Column name with special character**: `[Organic/Paid]` contains a forward slash — always wrap in square brackets in SQL queries.
- **Google Brand exception**: SubChannelID=4 ("Google Brand") is under Channel="SEM" but classified as "Organic" — the only SEM sub-channel that is organic.
- **Social Organic is Paid**: Despite the name "Social Organic" (SubChannelID=49), it is classified as "Paid" because the CASE logic only checks Channel-level names, not SubChannel names.
- **Non-sequential IDs**: SubChannelID values range from 1 to 52 with gaps — do not assume contiguity.
- **Truncate-and-reload**: All InsertDate/UpdateDate values are identical (the last load timestamp). These columns do NOT track when a channel was first created or last modified historically.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code or DDL with evidence |
| Tier 3 | No upstream traceable; grounded in DDL + naming |
| Tier 4 | Inferred from name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SubChannelID | int | NO | Primary key identifying a unique marketing sub-channel. Non-sequential integer (range 1–52, 36 active). Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannelID via SELECT DISTINCT. Clustered index key. Used as FK join key by downstream fact and BI_DB tables. (Tier 2 — SP_Dim_Channel) |
| 2 | Channel | nvarchar(50) | NO | Top-level marketing channel grouping (e.g., 'SEM', 'Direct', 'Affiliate', 'SEO', 'Friend Referral'). 20 distinct values. Passthrough from Ext_Dim_SubChannel_UnifyCode.Channel via SELECT DISTINCT. Also used as input to the Organic/Paid classification CASE logic. (Tier 2 — SP_Dim_Channel) |
| 3 | SubChannel | varchar(100) | NO | Granular marketing sub-channel name within a Channel (e.g., 'Google Search', 'Taboola', 'Direct Mobile', 'IBs'). 36 distinct values — one per row. Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannel via SELECT DISTINCT. Some sub-channels share their parent Channel name (e.g., Channel='Events', SubChannel='Events'). (Tier 2 — SP_Dim_Channel) |
| 4 | Organic/Paid | varchar(7) | YES | ETL-computed classification: 'Organic' when Channel IN ('Friend Referral', 'Direct', 'SEO') or SubChannel = 'Google Brand'; 'Paid' otherwise. 2 distinct values: Paid (30 rows), Organic (6 rows). NULL is allowed by DDL but not produced by current SP logic. (Tier 2 — SP_Dim_Channel) |
| 5 | InsertDate | datetime | YES | Row insert timestamp set to GETDATE() at SP execution time. Because the table uses truncate-and-reload, all rows share the same InsertDate equal to the last load run. Does not represent the original creation date of the channel. (Tier 2 — SP_Dim_Channel) |
| 6 | UpdateDate | datetime | YES | Row update timestamp set to GETDATE() at SP execution time. Identical to InsertDate on every load due to the truncate-and-reload pattern. Does not track incremental changes. (Tier 2 — SP_Dim_Channel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| SubChannelID | Ext_Dim_SubChannel_UnifyCode | SubChannelID | Passthrough (SELECT DISTINCT) |
| Channel | Ext_Dim_SubChannel_UnifyCode | Channel | Passthrough (SELECT DISTINCT) |
| SubChannel | Ext_Dim_SubChannel_UnifyCode | SubChannel | Passthrough (SELECT DISTINCT) |
| Organic/Paid | — (computed) | — | CASE on Channel + SubChannel values |
| InsertDate | — (computed) | — | GETDATE() |
| UpdateDate | — (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
fiktivo.dbo.tblaff_Affiliates (affiliate system, production)
  |-- External table load (SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) ---|
  v
DWH_dbo.Ext_Dim_SubChannel_UnifyCode (external/staging table)
  |-- SP_Dim_Channel (SELECT DISTINCT + CASE Organic/Paid) ---|
  v
DWH_dbo.Dim_Channel (36 rows, truncate-and-reload daily)
  |-- Generic Pipeline (Override, parquet → delta, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel (Unity Catalog Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | DWH_dbo.Ext_Dim_SubChannel_UnifyCode | Source external table providing channel/sub-channel reference data |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Key | Purpose |
|-------------------|----------|---------|
| BI_DB_dbo.SP_CIDFirstDates | SubChannelID | Customer first-date acquisition channel attribution |
| BI_DB_dbo.SP_Marketing_Cube | SubChannelID | Marketing analytics cube |
| BI_DB_dbo.SP_H_LiveAcquisitionDashboard | SubChannelID | Live acquisition dashboard |
| BI_DB_dbo.SP_LiveAcquisitionDashboard_Daily | SubChannelID | Daily acquisition dashboard |
| BI_DB_dbo.SP_CIDFunnelFlow | SubChannelID | Customer funnel flow analysis |
| BI_DB_dbo.SP_H_Deposits | SubChannelID | Deposit reporting by channel |
| BI_DB_dbo.SP_PI_Affiliate | SubChannelID | Popular Investor affiliate reporting |
| BI_DB_dbo.SP_VerificationStatus | SubChannelID | Verification status by channel |
| BI_DB_dbo.SP_AffiliatePaymentsReport | SubChannelID | Affiliate payment reporting |
| BI_DB_dbo.SP_M_Active_Affiliate_Monthly | SubChannelID | Monthly active affiliate reporting |
| BI_DB_dbo.SP_M_Compliance_CDIM_Report | SubChannelID | Compliance CDIM reporting |
| BI_DB_dbo.SP_W_Mon_Compliance_CDIM_Report | SubChannelID | Weekly/monthly compliance reporting |
| BI_DB_dbo.QST | SubChannelID | QST reporting |
| BI_DB_dbo.SP_CIDFirstDates_HistoricalRun | SubChannelID | Historical first-dates backfill |
| BI_DB_dbo.SP_M_Active_Aff_Monthly_Region_GroupAff | SubChannelID | Regional affiliate monthly reporting |

---

## 7. Sample Queries

### 7.1 Channel Distribution Summary

```sql
SELECT
    Channel,
    [Organic/Paid],
    COUNT(*) AS SubChannelCount
FROM DWH_dbo.Dim_Channel
GROUP BY Channel, [Organic/Paid]
ORDER BY SubChannelCount DESC;
```

### 7.2 Find All Organic Sub-Channels

```sql
SELECT SubChannelID, Channel, SubChannel
FROM DWH_dbo.Dim_Channel
WHERE [Organic/Paid] = 'Organic'
ORDER BY Channel, SubChannel;
```

### 7.3 Join to Customer First-Dates for Acquisition Attribution

```sql
SELECT
    dc.Channel,
    dc.SubChannel,
    dc.[Organic/Paid],
    COUNT(DISTINCT cfd.CID) AS Customers
FROM BI_DB_dbo.BI_DB_CIDFirstDates cfd
JOIN DWH_dbo.Dim_Channel dc ON cfd.SubChannelID = dc.SubChannelID
GROUP BY dc.Channel, dc.SubChannel, dc.[Organic/Paid]
ORDER BY Customers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-28 | Quality: pending/10 | Phases: 12/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 3/10*
*Object: DWH_dbo.Dim_Channel | Type: Table | Production Source: Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel*
