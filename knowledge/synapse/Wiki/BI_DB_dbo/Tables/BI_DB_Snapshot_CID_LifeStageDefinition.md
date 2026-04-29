# BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition

> 1.48B-row monthly snapshot of every customer's Life Stage Definition (LSD), cluster classification, sales desk, and country as of the end of each month. Built by SP_M_Snapshot_CID_LifeStageDefinition (Ben Einav, 2023-08-03) joining BI_DB_CID_LifeStageDefinition, BI_DB_CID_DailyCluster, Dim_Customer, and Dim_Country. Data from January 2023 to present, one row per CID per month-end.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_M_Snapshot_CID_LifeStageDefinition (BI_DB_dbo) — Ben Einav, 2023-08-03 |
| **Refresh** | Monthly — DELETE+INSERT by DateID (one month-end per run) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([RealCID] ASC, [DateID] ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_snapshot_cid_lifestagedefinition` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This table captures a monthly point-in-time snapshot of every customer's Life Stage Definition (LSD) classification. The LSD is a CRM/analytics segmentation framework that categorizes customers into lifecycle stages such as "Dump Lead", "Dump Churn", and active trading stages. Each row represents one customer on the last day of a month.

The snapshot is taken at the end of each month by looking up which LSD was valid for the customer at that date (using date-range-based SCD tables BI_DB_CID_LifeStageDefinition and BI_DB_CID_DailyCluster). With ~38M customers and 38 months of data (Jan 2023 – Mar 2026), the table holds approximately 1.48 billion rows.

Key fields: LSD gives the lifecycle stage name, Classification gives the Salesforce cluster category (e.g., "Traders", "Leveraged Traders"), ClusterDetail gives the sub-cluster, and Desk/Country provide the geographic segmentation.

---

## 2. Business Logic

### 2.1 Month-End Snapshot Logic

**What**: Captures the LSD and cluster valid at the end of the previous month.
**Columns Involved**: DateID, Date, LSD, Classification, ClusterDetail
**Rules**:
- DateID = EOMONTH(@Date - 1 month) as INT YYYYMMDD
- LSD from BI_DB_CID_LifeStageDefinition WHERE @endofmonthINT BETWEEN DateID AND ToDateID (SCD2 date range)
- Classification/ClusterDetail from BI_DB_CID_DailyCluster WHERE @endofmonthINT BETWEEN FromDateID AND ToDateID (SCD2 date range)
- LEFT JOIN on both tables — NULL if no active record at month-end

### 2.2 Geographic Enrichment

**What**: Adds country and sales desk from Dim_Country via Dim_Customer.
**Columns Involved**: Country, Desk
**Rules**:
- Dim_Customer.CountryID → Dim_Country.Name (Country) and Dim_Country.Desk
- LEFT JOIN — NULL if no customer record or no country mapping

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on [RealCID, DateID]. Very large table (1.48B rows). Always filter by DateID and/or RealCID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer lifecycle at month-end | `WHERE RealCID = X AND DateID = 20260331` |
| LSD distribution for a month | `WHERE DateID = 20260331 GROUP BY LSD` |
| Customer lifecycle over time | `WHERE RealCID = X ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Full customer attributes |
| BI_DB_dbo.BI_DB_CID_LifeStageDefinition | RealCID + DateID range | Full SCD2 history |

### 3.4 Gotchas

- **1.48B rows**: Always include DateID in WHERE clause — full scan is extremely expensive
- **Classification and ClusterDetail can be empty**: LEFT JOIN from BI_DB_CID_DailyCluster — many customers have no cluster assignment
- **LSD values include "Dump" prefix**: "Dump Lead" = dormant lead, "Dump Churn" = churned customer — "Dump" is a lifecycle stage prefix, not data quality issue
- **Monthly granularity only**: Data is end-of-month snapshots — no intra-month resolution

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 3 | Live data observation | Medium |
| Tier 5 | ETL metadata | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NOT NULL | End-of-month date as YYYYMMDD integer. Clustered index key (with RealCID). One snapshot per month. Range: 20230131 to 20260331. (Tier 2 — SP_M_Snapshot_CID_LifeStageDefinition) |
| 2 | Date | varchar(10) | YES | End-of-month date as string (e.g., '2026-03-31'). Redundant with DateID for display convenience. (Tier 2 — SP_M_Snapshot_CID_LifeStageDefinition) |
| 3 | RealCID | int | YES | Customer ID. References Dim_Customer.RealCID. Clustered index key (with DateID). (Tier 2 — SP_M_Snapshot_CID_LifeStageDefinition) |
| 4 | LSD | varchar(29) | YES | Life Stage Definition — lifecycle segmentation label active at month-end. From BI_DB_CID_LifeStageDefinition (SCD2 date range lookup). Examples: "Dump Lead", "Dump Churn". (Tier 2 — SP_M_Snapshot_CID_LifeStageDefinition) |
| 5 | Classification | varchar(255) | YES | Salesforce cluster classification active at month-end. From BI_DB_CID_DailyCluster.ClusterSF. Examples: "Traders", "Leveraged Traders". NULL if no cluster assignment. (Tier 2 — SP_M_Snapshot_CID_LifeStageDefinition) |
| 6 | ClusterDetail | varchar(255) | YES | Detailed cluster sub-category active at month-end. From BI_DB_CID_DailyCluster.ClusterDetail. Examples: "Leveraged Traders". NULL if no cluster assignment. (Tier 2 — SP_M_Snapshot_CID_LifeStageDefinition) |
| 7 | Desk | nvarchar(50) | YES | Sales/support desk assignment for the customer's country. From Dim_Country.Desk via Dim_Customer.CountryID. Examples: "Other EU", "USA", "Arabic", "ROW". NULL if no desk mapping. (Tier 3 — Ext_Dim_Country_Region_Desk via SP) |
| 8 | Country | varchar(50) | YES | Full country name in English. From Dim_Country.Name via Dim_Customer.CountryID. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 9 | UpdateDate | datetime | YES | ETL metadata: row insert timestamp (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| DateID, Date | Parameter | EOMONTH calculation | Computed |
| RealCID | BI_DB_CID_LifeStageDefinition | RealCID | Passthrough |
| LSD | BI_DB_CID_LifeStageDefinition | LSD | SCD2 lookup |
| Classification | BI_DB_CID_DailyCluster | ClusterSF | SCD2 lookup |
| ClusterDetail | BI_DB_CID_DailyCluster | ClusterDetail | SCD2 lookup |
| Desk | Dim_Country | Desk | Dim-lookup |
| Country | Dictionary.Country | Name | Dim-lookup |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CID_LifeStageDefinition (SCD2 lifecycle stages)
BI_DB_dbo.BI_DB_CID_DailyCluster (SCD2 cluster assignments)
DWH_dbo.Dim_Customer + Dim_Country (geographic enrichment)
  |-- SP_M_Snapshot_CID_LifeStageDefinition @Date (monthly DELETE+INSERT) ---|
  v
BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition (1.48B rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_snapshot_cid_lifestagedefinition
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Date dimension |
| LSD | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | Source SCD2 table |
| Classification | BI_DB_dbo.BI_DB_CID_DailyCluster | Source SCD2 table |

### 6.2 Referenced By (other objects point to this)

No known direct consumers in the documented wiki set.

---

## 7. Sample Queries

### 7.1 LSD Distribution for Latest Month

```sql
SELECT LSD, COUNT(*) AS customer_count
FROM BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition
WHERE DateID = 20260331
GROUP BY LSD
ORDER BY customer_count DESC
```

### 7.2 Customer Lifecycle Journey

```sql
SELECT DateID, LSD, Classification, ClusterDetail
FROM BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition
WHERE RealCID = 23631558
ORDER BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 6 T2, 1 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition | Type: Table | Production Source: SP_M_Snapshot_CID_LifeStageDefinition*
