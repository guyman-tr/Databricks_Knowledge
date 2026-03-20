# DWH_dbo.Dim_Channel

> Marketing acquisition channel and sub-channel classification dimension, mapping affiliate traffic sources to a standardized channel taxonomy with an Organic/Paid split.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | fiktivo_dbo.tblaff_Affiliates (AffWizz affiliate system) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (SubChannelID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dim_Channel is the marketing acquisition channel dimension for eToro's DWH. It classifies every affiliate sub-channel into a standardized channel hierarchy with an Organic vs. Paid indicator. Each row represents a unique sub-channel (e.g., "Google Brand", "FB", "Taboola") mapped to a parent channel (e.g., "SEM", "Direct", "Affiliate"). The Organic/Paid flag enables marketing analysts to split spend and attribution without re-deriving the classification.

The data originates from the AffWizz affiliate management system (fiktivo database). The production source tables are `fiktivo_dbo.tblaff_Affiliates` joined with `fiktivo_dbo.tblaff_MarketingExpense` and `fiktivo_dbo.tblaff_AffiliatesGroups`. There is no upstream production wiki — AffWizz is an external affiliate platform with no semantic documentation in the DB_Schema repository. All column descriptions are derived from ETL SP code analysis (Tier 2).

The table is loaded daily via a two-step ETL chain: `SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse` (builds the raw affiliate-to-subchannel mapping via a massive CASE expression with 30+ sub-channel types) → `SP_Dim_Channel` (deduplicates and applies the Organic/Paid classification). Both steps use TRUNCATE + INSERT (full reload).

---

## 2. Business Logic

### 2.1 Sub-Channel Classification (SubChannelID Mapping)

**What**: Each affiliate is classified into one of ~30 sub-channel types based on the affiliate's Channel (from MarketingExpense) and the Contact string (campaign identifier).

**Columns Involved**: `SubChannelID`, `SubChannel`, `Channel`

**Rules**:
- SubChannelID is NOT a production FK — it is a DWH-derived classification computed via a CASE expression in SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse
- The mapping parses the affiliate Contact string (lowercased) to detect platforms: `sem.facebook%` → FB (32), `%taboola%` → Taboola (33), `sem.twitter%` → Twitter (34), `%outbrain%` → Outbrain (35)
- Google sub-channels are further split: Brand (4), Search (5), UAC (38), Discovery (50), GDN → SEM Other (11)
- SubChannelID=0 = "Unknown" (unmapped affiliates)
- Introducing Agents channel is reclassified to "Affiliate" at the Channel level

**Diagram**:
```
AffWizz MarketingExpense.Channel
  ├── Direct ─────────────► Direct (19) / Direct Mobile (1) / SMM (18)
  ├── SEM ────────────────► Google Brand (4) / Google Search (5) / FB (32) /
  │                         Taboola (33) / Twitter (34) / Outbrain (35) /
  │                         Bing Search (37) / Google UAC (38) / YT (22) /
  │                         ASA (36) / Discovery (50) / TikTok (51) / SEM Other (11)
  ├── SEO ────────────────► SEO (21)
  ├── Affiliate ──────────► Affiliate (31)
  ├── Introducing Agents ─► IBs (20) [Channel overridden to "Affiliate"]
  ├── Mobile Acquisition ─► Mobile CPA (40) / Mobile Non-CPA (39)
  ├── Media Programmatic ─► Media Programmatic (41)
  ├── Media CPA ──────────► Media CPA (45)
  ├── Media Performance ──► Media Performance (42)
  ├── Content Partnerships ► Content Partnerships (44)
  ├── Friend Referral ────► Friend Referral (43)
  ├── TV ─────────────────► TV (48)
  ├── Social Organic ─────► Social Organic (49)
  ├── Sponsorships ───────► Sponsorships (27)
  ├── OOH ────────────────► OOH (26)
  ├── PR ─────────────────► PR (24)
  ├── Events ─────────────► Events (25)
  ├── Club ───────────────► Club (29)
  ├── Productions ────────► Productions (30)
  ├── systems ────────────► systems (28)
  ├── Affiliate Branding ─► Affiliate Branding (52)
  └── (unmapped) ─────────► Unknown (0)
```

### 2.2 Organic/Paid Classification

**What**: A binary marketing spend classification applied on top of the Channel hierarchy.

**Columns Involved**: `Organic/Paid`

**Rules**:
- "Organic" if Channel IN ('Friend Referral', 'Direct', 'SEO')
- "Organic" if SubChannel = 'Google Brand' (brand searches treated as organic despite being SEM)
- All other channels = "Paid"
- This classification is computed in SP_Dim_Channel (second ETL step), NOT in the upstream source

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table uses ROUND_ROBIN distribution with a CLUSTERED INDEX on `SubChannelID`. The table is small (estimated ~50 rows) so distribution strategy has minimal performance impact. It is frequently JOINed via SubChannelID from Dim_Customer, Dim_Affiliate, and Fact_CustomerAction.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All organic channels | `WHERE [Organic/Paid] = 'Organic'` — note the special column name requires brackets |
| Customers by marketing channel | JOIN Dim_Customer ON SubChannelID = SubChannelID, GROUP BY Channel |
| SEM platform breakdown | `WHERE Channel = 'SEM'`, then GROUP BY SubChannel |
| FTD attribution by channel | JOIN Fact_CustomerAction (ActionTypeID=14 for FTD) ON SubChannelID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Channel.SubChannelID = Dim_Customer.SubChannelID | Resolve customer acquisition channel |
| DWH_dbo.Dim_Affiliate | ON Dim_Channel.SubChannelID = Dim_Affiliate.SubChannelID | Link affiliate to its channel classification |
| DWH_dbo.Fact_CustomerAction | ON Dim_Channel.SubChannelID = Fact_CustomerAction.SubChannelID | Channel attribution for customer events |

### 3.4 Gotchas

- **Column name with special character**: The `Organic/Paid` column contains a forward slash — always use square brackets `[Organic/Paid]` in queries
- **SubChannelID=0 = Unknown**: Unmapped affiliates get ID=0. Use LEFT JOIN or handle 0 explicitly in analytics
- **ROUND_ROBIN on a small table**: Consider that this table should likely be REPLICATE for better JOIN performance, but the current ROUND_ROBIN works given the tiny row count
- **Google Brand is Organic**: Despite being an SEM (paid search) sub-channel, Google Brand queries are classified as "Organic" — this is an intentional business decision, not a bug
- **Introducing Agents → Affiliate**: At the Channel level, "Introducing Agents" is overridden to "Affiliate", but SubChannel remains "IBs" (20)
- **No SubChannelID=0 row**: The SP filters `WHERE SubChannelID != 0`, so the sentinel row is excluded from the final table. Unknown affiliates have no matching dim row — use LEFT JOIN

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| ★★★★★ | Tier 5 — domain expert | `(Tier 5 — domain expert)` |
| ★★★★☆ | Tier 1 — upstream wiki | `(Tier 1 — upstream wiki)` |
| ★★★☆☆ | Tier 2 — SP code | `(Tier 2 — SP code)` |
| ★★☆☆☆ | Tier 3 — live data / DDL | `(Tier 3 — DDL)` |
| ★☆☆☆☆ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SubChannelID | int | NO | Primary key. DWH-derived sub-channel identifier assigned via a CASE expression in SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse. Maps affiliate contact strings to ~30 standardized sub-channel categories (e.g., 4=Google Brand, 5=Google Search, 32=FB, 33=Taboola). NOT a production FK — computed entirely in DWH ETL. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 2 | Channel | nvarchar(50) | NO | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' → 'Affiliate', AffiliateID IN (56662,56663) → 'Direct'. Common values: Direct, SEM, SEO, Affiliate, Mobile Acquisition, Friend Referral, Media Programmatic, TV, Social Organic. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 3 | SubChannel | varchar(100) | NO | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Taboola', 'Twitter', 'Outbrain', 'Bing Search', 'Direct', 'SEO', 'Affiliate', 'IBs'. Derived via parallel CASE expression alongside SubChannelID. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 4 | Organic/Paid | varchar(7) | YES | Binary marketing spend classification. 'Organic' for channels Friend Referral, Direct, SEO, and Google Brand. 'Paid' for all others. Computed in SP_Dim_Channel (second ETL step). Note: column name contains a slash — requires square brackets in queries. (Tier 2 — SP_Dim_Channel) |
| 5 | InsertDate | datetime | YES | ETL metadata: timestamp when this row was first inserted by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. (Tier 2 — SP_Dim_Channel) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. Same as InsertDate since table is TRUNCATE+INSERT. (Tier 2 — SP_Dim_Channel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| SubChannelID | fiktivo_dbo.tblaff_Affiliates + tblaff_MarketingExpense | Contact, MarketingExpenseName, AffiliatesGroupsName | CASE expression mapping 30+ patterns to integer IDs |
| Channel | fiktivo_dbo.tblaff_MarketingExpense | MarketingExpenseName | CASE with overrides (Introducing Agents → Affiliate) |
| SubChannel | fiktivo_dbo.tblaff_Affiliates + tblaff_MarketingExpense | Contact, MarketingExpenseName | Parallel CASE to SubChannelID, returns name strings |
| Organic/Paid | N/A | N/A | DWH-computed: CASE on Channel + SubChannel values |
| InsertDate | N/A | N/A | GETDATE() at ETL time |
| UpdateDate | N/A | N/A | GETDATE() at ETL time |

No upstream wiki exists for the fiktivo (AffWizz) database. All descriptions are derived from SP code analysis.

### 5.2 ETL Pipeline

```
fiktivo_dbo.tblaff_Affiliates → Generic Pipeline → DWH_staging.fiktivo_dbo_tblaff_Affiliates → SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse → Ext_Dim_SubChannel_UnifyCode → SP_Dim_Channel → Dim_Channel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | fiktivo_dbo.tblaff_Affiliates + tblaff_MarketingExpense + tblaff_AffiliatesGroups + tblaff_AffiliateTypes | AffWizz affiliate management system tables |
| Lake | DWH_staging.fiktivo_dbo_tblaff_* | Staging tables from data lake export |
| ETL 1 | SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse | Joins 7 staging tables, builds Ext_Dim_Channel_Affiliate_UnifyCode, then derives SubChannelID/SubChannel/Channel via massive CASE mapping into Ext_Dim_SubChannel_UnifyCode |
| ETL 2 | SP_Dim_Channel | SELECT DISTINCT from Ext_Dim_SubChannel_UnifyCode, applies Organic/Paid CASE, TRUNCATE+INSERT into Dim_Channel |
| Target | DWH_dbo.Dim_Channel | Final marketing channel dimension |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none) | — | Dim_Channel has no FK references to other Dim tables |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | SubChannelID | Customer acquisition sub-channel at registration |
| DWH_dbo.Dim_Affiliate | SubChannelID | Affiliate's assigned marketing sub-channel |
| DWH_dbo.Fact_CustomerAction | SubChannelID | Sub-channel attribution for customer events |
| DWH_dbo.Fact_SnapshotCustomer | SubChannelID | Point-in-time customer sub-channel snapshot |
| DWH_dbo.V_Dim_Customer | SubChannelID | Pass-through from Dim_Customer |

---

## 7. Sample Queries

### 7.1 Marketing channel performance: FTD count by Channel and Organic/Paid split

```sql
SELECT
    dc.Channel,
    dc.[Organic/Paid],
    COUNT(DISTINCT fca.RealCID) AS FTD_Customers
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Channel dc ON dc.SubChannelID = fca.SubChannelID
WHERE fca.ActionTypeID = 14  -- First Time Deposit
  AND fca.DateID >= 20260101
GROUP BY dc.Channel, dc.[Organic/Paid]
ORDER BY FTD_Customers DESC;
```

### 7.2 Sub-channel breakdown for SEM traffic

```sql
SELECT
    dc.SubChannelID,
    dc.SubChannel,
    dc.[Organic/Paid],
    COUNT(DISTINCT cust.RealCID) AS Registered_Customers
FROM DWH_dbo.Dim_Customer cust
JOIN DWH_dbo.Dim_Channel dc ON dc.SubChannelID = cust.SubChannelID
WHERE dc.Channel = 'SEM'
GROUP BY dc.SubChannelID, dc.SubChannel, dc.[Organic/Paid]
ORDER BY Registered_Customers DESC;
```

### 7.3 All channels with their Organic/Paid classification

```sql
SELECT
    SubChannelID,
    Channel,
    SubChannel,
    [Organic/Paid]
FROM DWH_dbo.Dim_Channel
ORDER BY Channel, SubChannel;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) | Confluence | AffWizz system overview: sub-affiliates up to 5 levels deep, campaigns are free-text marketing identifiers |
| [Affiliate Process - Details Change](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/13254492166/Affiliate+Process+-Details+Change) | Confluence | Manual process to change affiliate marketing channel in AffWiz — confirms Channel is an editable attribute |
| [Creating an Affiliate ID](https://etoro-jira.atlassian.net/wiki/spaces/MU/pages/12032574011/Creating+an+Affiliate+ID) | Confluence | Channel chosen during affiliate onboarding depending on activity type |
| [DWH Process Failure (DWH SP Failure + Delay) - 2023-11-17](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12143165455/DWH+Process+Failure+DWH+SP+Failure+Delay+-+2023-11-17.) | Confluence | Postmortem: fix **Channel/Sub Channel** logic in the relevant SP and rerun dependent SPs — validates that channel/sub-channel classification is business-critical DWH logic (same domain as `Dim_Channel`). |
| [Affiliate Attribution - Update Affiliate ID](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12050989066/Affiliate+Attribution+-+Update+Affiliate+ID) | Confluence | Describes **organic vs non-organic** attribution rules and channel IDs (e.g. Direct vs other channels) when updating affiliate mappings — business context for Organic/Paid and channel overrides. |

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 8/14 (P2,P3 skipped — Synapse MCP unavailable; P10 Atlassian refresh)*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7.5/10*
*Object: DWH_dbo.Dim_Channel | Type: Table | Production Source: fiktivo_dbo.tblaff_Affiliates (AffWizz)*
