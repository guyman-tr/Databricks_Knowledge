# BI_DB_dbo.BI_DB_Investors

> 132.9M-row daily investor activity report aggregating customer count, net money invested (Amount), and AUM/AUA by AccountManagerID × CountryID × RegulationID × ActionType (Manual/Copy/Balance) × InstrumentType × AssetType (Investment/Trade) × Salesforce ClusterSF. Date range: Jul 2019 – Apr 2026 (2,100 daily snapshots). Sourced from BI_DB_Investors_STG (pre-aggregated streams) enriched with BI_DB_CID_DailyCluster (Salesforce cluster assignment). Daily delete-insert via SP_InvestorReport_Cluster.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Investor Activity Report — Daily Aggregate) |
| **Production Source** | Derived — BI_DB_Investors_STG + BI_DB_CID_DailyCluster by SP_InvestorReport_Cluster |
| **Refresh** | Daily delete-insert by DateID (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_Investors` is a **daily investor activity report** that provides a multi-dimensional aggregation of customer engagement across the eToro platform. Each row represents a unique combination of Date × AccountManager × Country × Regulation × ActionType × InstrumentType × AssetType × ClusterSF, with counts of customers, net money invested, and assets under management (AUM) or administration (AUA).

The table holds 132.9M rows across 2,100 daily snapshots from July 2019 to April 2026. The SP processes three source streams from the staging table:

1. **Manual**: Direct (non-copy) investments — customer trades instruments directly
2. **Copy**: Copy-trading activity — customer copies a PI or Smart Portfolio
3. **Balance**: Cash balance positions — customer's uninvested cash

Each stream is aggregated by the same dimensional axes, then UNION'd into the final table.

### Salesforce Cluster Enrichment

The SP LEFT JOINs `BI_DB_CID_DailyCluster` to assign each customer to a Salesforce-defined behavioral cluster (e.g., 'Traders', 'Crypto', 'Investors'). The cluster is date-ranged (FromDateID/ToDateID) to capture cluster transitions over time.

---

## 2. Business Logic

### 2.1 Three Source Streams

**What**: Activity is segmented into Manual, Copy, and Balance streams.
**Columns Involved**: ActionType, Customers, Amount, AUM_AUA
**Rules**:
- Manual: SourceTable='Manual' — direct trades, Customers = COUNT(DISTINCT CID)
- Copy: SourceTable='Copy' — copy-trading activity, Customers = COUNT(DISTINCT CID)
- Balance: SourceTable='Balance' — cash positions, Customers = COUNT(CID)
- UNION of all three streams into final table

### 2.2 Asset Type Classification

**What**: Distinguishes investment vs trading activity.
**Columns Involved**: AssetType
**Rules**:
- 'Investment' — long-term asset holding (stocks, ETFs)
- 'Trade' — short-term/leveraged trading (forex, commodities, CFDs)

### 2.3 Salesforce Cluster

**What**: Behavioral segmentation from Salesforce.
**Columns Involved**: ClusterSF
**Rules**:
- LEFT JOIN from BI_DB_CID_DailyCluster on CID + date range
- NULL for CIDs without a Salesforce cluster assignment
- Example values: 'Traders', 'Crypto', 'Investors'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC. Large table (132.9M rows). Always filter on DateID for efficient index seeks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily investor activity by regulation | `WHERE DateID = @date GROUP BY RegulationID` |
| AUM trend by cluster | `SELECT DateID, ClusterSF, SUM(AUM_AUA) GROUP BY DateID, ClusterSF` |
| Net money invested by country | `WHERE DateID = @date GROUP BY CountryID` |
| Manual vs Copy activity | `WHERE DateID = @date GROUP BY ActionType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | RegulationID | Regulation name |
| DWH_dbo.Dim_Country | CountryID | Country name |
| DWH_dbo.Dim_AccountManager | AccountManagerID | Account manager details |

### 3.4 Gotchas

- **Large table**: 132.9M rows — always filter on DateID. Without it, queries can take minutes
- **Amount = NetMI**: The DDL column "Amount" is populated from the SP's "NetMI" (Net Money Invested) field. The naming mismatch can be confusing
- **AUM_AUA**: Maps to AUM for Copy streams and AUA for Manual/Balance streams. The semantic distinction is collapsed into one column
- **Customers count inconsistency**: Manual/Copy use COUNT(DISTINCT CID), Balance uses COUNT(CID) — potential double-counting in Balance if a CID appears in multiple balance rows
- **13 columns, not 14**: DDL has 13 columns

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date for this daily snapshot. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 2 | DateID | int | YES | Date identifier in YYYYMMDD integer format. Clustered index column. Used for delete-insert partitioning and efficient date-range queries. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 3 | AccountManagerID | int | YES | Salesforce account manager ID. FK to DWH_dbo.Dim_AccountManager. Identifies which AM manages the customers in this bucket. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 4 | CountryID | int | YES | Country of customer registration. FK to DWH_dbo.Dim_Country. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 5 | RegulationID | tinyint | YES | Regulatory entity ID. FK to DWH_dbo.Dim_Regulation. 1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, etc. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 6 | ActionType | varchar(50) | YES | Activity source stream: 'Manual' (direct trades), 'Copy' (copy-trading), 'Balance' (cash positions). From BI_DB_Investors_STG.SourceTable. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 7 | InstrumentType | varchar(50) | YES | Instrument category: Stocks, ETF, Crypto Currencies, Commodities, Indices, Currencies. From BI_DB_Investors_STG. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 8 | AssetType | varchar(50) | YES | Investment classification: 'Investment' (long-term holding), 'Trade' (short-term/leveraged). (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 9 | Customers | decimal(38,2) | YES | Count of customers in this dimensional bucket. Manual/Copy: COUNT(DISTINCT CID). Balance: COUNT(CID). Stored as decimal for aggregation flexibility. (Tier 2 — SP_InvestorReport_Cluster) |
| 10 | Amount | decimal(38,2) | YES | Net money invested (NetMI) for this bucket. SUM of net investment flows. In USD. Note: DDL column name is "Amount" but populated from SP's "NetMI" field. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 11 | AUM_AUA | decimal(38,2) | YES | Assets Under Management (for Copy stream) or Assets Under Administration (for Manual/Balance streams). SUM of position values. In USD. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_Investors_STG) |
| 12 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_InvestorReport_Cluster. Set to GETDATE(). (Tier 5 — SP_InvestorReport_Cluster) |
| 13 | ClusterSF | varchar(50) | YES | Salesforce behavioral cluster assignment for the customers in this bucket. From BI_DB_CID_DailyCluster (date-ranged SCD). Example values: 'Traders', 'Crypto', 'Investors'. NULL if no cluster assigned. (Tier 2 — SP_InvestorReport_Cluster, from BI_DB_CID_DailyCluster) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date, DateID, AccountManagerID, CountryID, RegulationID, ActionType, InstrumentType, AssetType | BI_DB_Investors_STG | Same columns | Passthrough (dimension columns) |
| Customers | BI_DB_Investors_STG | CID | COUNT(DISTINCT CID) or COUNT(CID) |
| Amount | BI_DB_Investors_STG | NetMI | SUM(NetMI) |
| AUM_AUA | BI_DB_Investors_STG | AUA/AUM | SUM — varies by source stream |
| ClusterSF | BI_DB_CID_DailyCluster | ClusterSF | LEFT JOIN on CID + date range |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Investors_STG (pre-aggregated: Manual/Copy/Balance streams)
  + BI_DB_dbo.BI_DB_CID_DailyCluster (Salesforce cluster, date-ranged SCD)
    |-- SP_InvestorReport_Cluster @dd (daily, delete-insert by DateID) --|
    |   LEFT JOIN STG to DailyCluster on CID + date range                |
    |   3 branches: Manual (COUNT DISTINCT CID), Copy (COUNT DISTINCT),  |
    |               Balance (COUNT CID)                                  |
    |   UNION all 3 → GROUP BY all dimensions                           |
    v
BI_DB_dbo.BI_DB_Investors (132.9M rows, daily, 2100 dates)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountManagerID | DWH_dbo.Dim_AccountManager | AM details |
| CountryID | DWH_dbo.Dim_Country | Country name |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation name |
| All columns | BI_DB_dbo.BI_DB_Investors_STG | Pre-aggregated staging source |
| ClusterSF | BI_DB_dbo.BI_DB_CID_DailyCluster | Salesforce cluster |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Daily AUM by Regulation and Cluster

```sql
SELECT RegulationID, ClusterSF,
       SUM(AUM_AUA) AS total_aum,
       SUM(Customers) AS total_customers
FROM [BI_DB_dbo].[BI_DB_Investors]
WHERE DateID = 20260411
GROUP BY RegulationID, ClusterSF
ORDER BY total_aum DESC
```

### 7.2 Monthly Net Investment Trend by ActionType

```sql
SELECT DateID / 100 AS year_month,
       ActionType,
       SUM(Amount) AS net_investment,
       SUM(Customers) AS customer_buckets
FROM [BI_DB_dbo].[BI_DB_Investors]
WHERE DateID >= 20260101
GROUP BY DateID / 100, ActionType
ORDER BY year_month, ActionType
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Investors | Type: Table | Production Source: Derived — BI_DB_Investors_STG + BI_DB_CID_DailyCluster*
