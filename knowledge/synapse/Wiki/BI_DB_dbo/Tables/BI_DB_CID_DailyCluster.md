# BI_DB_dbo.BI_DB_CID_DailyCluster

> Customer clustering SCD2 history table — 13 columns tracking the evolution of each customer's cluster assignment over time. One row per change period (FromDate → ToDate). Built daily from BI_DB_ClusteringLog + BI_DB_ClusteringDailyPrepData via SP_CID_DailyCluster. Currently 5.1M active (open) customer clusters across 6 types.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_ClusteringLog (ML cluster assignments) |
| **Refresh** | Daily (SP_CID_DailyCluster @Date, SCD2 MERGE + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED (FromDateID ASC) + NONCLUSTERED (UpdateDateIDSF) |
| | |
| **OpsDB Priority** | 0 (declared) — note: SP reads from BI_DB_ClusteringDailyPrepData which is P20; LEFT JOIN makes ClusterDynamic gracefully degrade to ClusterDetail if ratios unavailable |
| **OpsDB Process** | SB_Daily, ProcessType=SQL |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_CID_DailyCluster` is a **Slowly Changing Dimension Type 2 (SCD2)** table recording the full history of each eToro customer's behavioral cluster assignment. Customers are segmented daily by a machine learning model into behavioral profiles based on their trading activity. This table captures when a customer changed clusters, enabling time-series analysis of behavioral evolution.

**Six cluster types** (current active distribution):
- **Crypto** — 1.65M customers (32%): predominantly cryptocurrency traders
- **Equities Traders** — 989K (19%): active equity position traders
- **Equities Crypto** — 824K (16%): equity investors with high crypto exposure (CryptoRatio ≥ 40%)
- **Equities Investors** — 678K (13%): buy-and-hold equity investors
- **Leveraged Traders** — 624K (12%): traders using CFD leverage
- **Diversified Traders** — 350K (7%): mixed-strategy traders (low crypto exposure)

**Three derived labels**:
- `ClusterDetail` — the ML model's precise cluster name (6 values above)
- `ClusterDynamic` — enhanced label: Diversified Traders with CryptoRatio ≥ 0.4 become 'Equities Crypto'
- `ClusterSF` — simplified 3-way Salesforce grouping: Investors / Traders / Crypto

**SCD2 semantics**: Each row covers one contiguous period. The open/current period has `ToDateID = 99991231` and `IsLastCluster = 1`. When a cluster changes, the old row is closed (ToDateID = yesterday) and a new row is inserted. This allows `AS OF DATE` queries to reconstruct any customer's cluster at any historical point.

**Salesforce sync**: `IsSFCluster` is set to 1 on even-month runs (bi-monthly) for recently changed active clusters, enabling selective sync to Salesforce CRM. `UpdateDateIDSF` records the date of the last SF sync processing pass.

---

## 2. Business Logic

### 2.1 Cluster Change Detection (SCD2 MERGE)

**What**: A new cluster row is only inserted when the customer's cluster actually changed (no-change days produce no new rows).

**Rule**:
- `#lastcluster` = current open cluster (IsLastCluster=1) for each CID
- `#finalcluster` = new cluster assignments WHERE `lc.CID IS NULL` — i.e., no matching open cluster with same ClusterDetail AND ClusterDynamic
- MERGE: if a match EXISTS (same CID, different ClusterDetail or ClusterDynamic) AND ToDateID=99991231 → close it: `IsLastCluster=0, ToDate=yesterday, ToDateID=yesterday_ID`
- INSERT: new open period from #finalcluster

Result: periods only advance when cluster label changes. A customer who stays in 'Equities Investors' for 2 years has one row covering that entire span.

### 2.2 ClusterSF Simplification

**What**: `ClusterSF` maps the 6-value ClusterDetail into 3 Salesforce-compatible buckets.

**Rule** (applied at INSERT):
```
ClusterSF = CASE
  WHEN ClusterDetail = 'Equities Investors'                              → 'Investors'
  WHEN ClusterDetail IN ('Equities Traders', 'Diversified Traders',
                         'Leveraged Traders')                            → 'Traders'
  WHEN ClusterDetail IN ('Crypto', 'Equities Crypto')                   → 'Crypto'
END
```
Note: All 6 ClusterDetail values are covered; ClusterSF will be NULL only for unknown future ClusterDetail values.

### 2.3 ClusterDynamic — Crypto-Adjusted Label

**What**: `ClusterDynamic` adds a refinement for Diversified Traders with high cryptocurrency exposure.

**Rule**:
```
ClusterDynamic = CASE
  WHEN ClusterDetail = 'Diversified Traders'
   AND CryptoRatio >= 0.4    → 'Equities Crypto'
  ELSE                       → ClusterDetail
END
```
`CryptoRatio` sourced from `BI_DB_ClusteringDailyPrepData.CryptoRatio` via LEFT JOIN. If ClusteringDailyPrepData has no row for the date (LEFT JOIN miss), CryptoRatio = NULL → condition false → ClusterDynamic = ClusterDetail.

### 2.4 IsFirstCluster Flag

**What**: Marks the customer's very first cluster assignment — they had no prior cluster record.

**Rule**: In `#finalcluster`, `IsFirstCluster = CASE WHEN fc.CID IS NULL THEN 1 ELSE 0 END`, where `fc` is a LEFT JOIN back to `#lastcluster` on CID only (no ClusterDetail match required). If no row at all exists for this CID in the current last-cluster set → this is their first cluster.

### 2.5 IsSFCluster — Bi-Monthly Salesforce Sync

**What**: Identifies cluster records that should be synced to Salesforce CRM. Updated bi-monthly (even months).

**Rule**:
- `@LoadInd = 1` when `@LoadDate` is the first day of an even-numbered month
- On even-month runs: find all open clusters (`ToDateID=99991231, IsLastCluster=1`) with `FromDateID` within the past 2 months where `IsSFCluster=0` → set `IsSFCluster=1`
- Simultaneously: set `IsSFCluster=0` on all older (closed) periods for those CIDs

Effect: IsSFCluster=1 marks exactly the current active cluster for CIDs whose cluster changed recently (bi-monthly window). Stale records get IsSFCluster=0.

### 2.6 Re-load Correction (Deleted CID Repair)

**What**: When a date range is re-loaded (e.g., historical correction), the SP repairs IsSFCluster and IsLastCluster for affected CIDs.

**Rule**:
- `#del` = CIDs whose rows will be deleted (FROM DateID >= @Date)
- For deleted CIDs: re-find their last SF indicator date and last open period before the reload window
- UPDATE existing historical rows to restore correct IsSFCluster and IsLastCluster=1 (open) state

---

## 3. Query Advisory

### 3.1 Distribution and Index

ROUND_ROBIN — no co-location benefit. Clustered index on `FromDateID` makes date-range queries fast. NC index on `UpdateDateIDSF` supports SF sync queries.

### 3.2 Querying Current Cluster Assignments

Always use `WHERE IsLastCluster = 1` to get the active cluster per customer. ToDateID=99991231 and IsLastCluster=1 are equivalent filters (both identify the open period), but IsLastCluster=1 is indexed-friendly with the clustered structure.

```sql
-- Current cluster for all active customers
SELECT CID, ClusterDetail, ClusterDynamic, ClusterSF, FromDateID
FROM BI_DB_dbo.BI_DB_CID_DailyCluster
WHERE IsLastCluster = 1
```

### 3.3 Historical AS-OF Queries

To find a customer's cluster on a specific date:
```sql
SELECT CID, ClusterDetail, FromDateID, ToDateID
FROM BI_DB_dbo.BI_DB_CID_DailyCluster
WHERE CID = @CID
  AND FromDateID <= @DateID
  AND ToDateID >= @DateID
```

### 3.4 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current cluster mix | WHERE IsLastCluster=1, GROUP BY ClusterDetail |
| Cluster migration analysis | GROUP BY ClusterDetail, FromDateID range |
| New cluster assignments today | WHERE IsFirstCluster=1 AND FromDateID = @TodayID |
| Salesforce sync candidates | WHERE IsSFCluster=1 AND IsLastCluster=1 |
| ClusterDynamic vs ClusterDetail differences | WHERE ClusterDynamic != ClusterDetail (Diversified Traders with CryptoRatio≥40%) |

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP_CID_DailyCluster ETL logic | (Tier 2 — SP_CID_DailyCluster) |
| Tier 2 — ETL metadata | (Tier 2 — ETL metadata) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NULL | Customer ID. One or more rows per customer — each row represents a distinct cluster period. (Tier 2 — SP_CID_DailyCluster) |
| 2 | ClusterDetail | varchar(?) | NULL | Precise ML cluster name for this period. 6 values: 'Crypto', 'Equities Traders', 'Equities Crypto', 'Equities Investors', 'Leveraged Traders', 'Diversified Traders'. Sourced from BI_DB_ClusteringLog.ClusterDesc. (Tier 2 — SP_CID_DailyCluster) |
| 3 | ClusterSF | varchar(?) | NULL | Simplified Salesforce cluster bucket. 3 values: 'Investors' (Equities Investors), 'Traders' (Equities/Diversified/Leveraged Traders), 'Crypto' (Crypto + Equities Crypto). Computed at INSERT from ClusterDetail CASE logic. (Tier 2 — SP_CID_DailyCluster) |
| 4 | FromDateID | int | NULL | Start date of this cluster period as YYYYMMDD integer. Clustered index key. Sourced from BI_DB_ClusteringLog.DateID. (Tier 2 — SP_CID_DailyCluster) |
| 5 | ToDateID | int | NULL | End date of this cluster period as YYYYMMDD integer. 99991231 = open/current period (IsLastCluster=1). Set to yesterday's DateID when MERGE closes this period on cluster change. (Tier 2 — SP_CID_DailyCluster) |
| 6 | FromDate | date | NULL | Start date of this cluster period. Sourced from BI_DB_ClusteringLog.Date. (Tier 2 — SP_CID_DailyCluster) |
| 7 | ToDate | date | NULL | End date of this cluster period. '9999-12-31' for open periods; set to DATEADD(DAY,-1,@LoadDate) when cluster changes. (Tier 2 — SP_CID_DailyCluster) |
| 8 | IsLastCluster | int | NULL | 1 = this is the customer's currently active cluster period (ToDateID=99991231). 0 = historical closed period. Primary filter for current-state queries. (Tier 2 — SP_CID_DailyCluster) |
| 9 | IsFirstCluster | int | NULL | 1 = this is the customer's very first cluster assignment (no prior cluster record existed). 0 = customer had prior cluster history. (Tier 2 — SP_CID_DailyCluster) |
| 10 | IsSFCluster | int | NULL | Salesforce sync flag. 1 = this cluster record should be synced to Salesforce CRM. Updated bi-monthly (even months) for recent active clusters. 0 for historical/stale periods. (Tier 2 — SP_CID_DailyCluster) |
| 11 | UpdateDate | datetime | NULL | ETL load timestamp. GETDATE() at INSERT or subsequent UPDATE (IsLastCluster/IsSFCluster corrections). (Tier 2 — ETL metadata) |
| 12 | UpdateDateIDSF | int | NULL | YYYYMMDD integer of the SP run date for this row's last SF processing pass. NC index key. Supports SF sync batch identification. (Tier 2 — SP_CID_DailyCluster) |
| 13 | ClusterDynamic | varchar(?) | NULL | Enhanced cluster label with crypto-adjustment. Same as ClusterDetail for all types except: 'Diversified Traders' with CryptoRatio ≥ 0.4 becomes 'Equities Crypto'. Enables finer segmentation of crypto-heavy diversified traders. NULL if ClusteringDailyPrepData has no ratio for the customer on that date (LEFT JOIN miss). (Tier 2 — SP_CID_DailyCluster) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role | Columns |
|--------|------|---------|
| BI_DB_dbo.BI_DB_ClusteringLog | Primary — daily ML cluster assignments | CID, ClusterDesc→ClusterDetail, DateID→FromDateID, Date→FromDate |
| BI_DB_dbo.BI_DB_ClusteringDailyPrepData | Ratio data — CryptoRatio for ClusterDynamic | InvestingRatio, TradingRatio, CryptoRatio (LEFT JOIN on CalculationDateID) |

### 5.2 ETL Pipeline

```
[ML Model output]
BI_DB_dbo.BI_DB_ClusteringLog (daily cluster assignments)
  + BI_DB_dbo.BI_DB_ClusteringDailyPrepData (P20 — asset ratios)
  |
  v [SP_CID_DailyCluster @Date — Priority 0, Daily, SB_Daily]
    WHILE @LoadDate <= @Date:
      1. DELETE FROM BI_DB_CID_DailyCluster WHERE FromDateID >= @Date
      2. Fix IsSFCluster + IsLastCluster for affected CIDs (CROSS APPLY lookback)
      3. For each load date:
         - #ratio: CryptoRatio from ClusteringDailyPrepData
         - #cid: ClusteringLog + ratios → ClusterDetail + ClusterDynamic
         - #finalcluster: only changed clusters (LEFT JOIN to last open cluster)
         - MERGE: close old periods for changed CIDs
         - INSERT new open periods
         - Even-month: UPDATE IsSFCluster for recent active clusters
BI_DB_dbo.BI_DB_CID_DailyCluster (SCD2, ROUND_ROBIN, CLUSTERED FromDateID)
```

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID, ClusterDetail, FromDateID, FromDate | BI_DB_dbo.BI_DB_ClusteringLog | Primary daily cluster assignments |
| ClusterDynamic (CryptoRatio) | BI_DB_dbo.BI_DB_ClusteringDailyPrepData | Asset ratio data for crypto-adjustment |
| IsFirstCluster (CID lookup) | BI_DB_dbo.BI_DB_CID_DailyCluster (self-join) | Self-reference to check prior history |
| @DateID lookups | DWH_dbo.Dim_Date | IsFirstDayOfMonth + MonthNumberOfYear for SF sync scheduling |

### 6.2 Referenced By (downstream objects)

| Source Object | Description |
|--------------|-------------|
| BI_DB_dbo.BI_DB_ReturnCalculation | Joins cluster history for return analysis |
| BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Daily return data enriched with cluster |
| BI_DB_dbo.BI_DB_Investors | Investor reports using cluster assignment |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | LTV actuals segmented by cluster |
| BI_DB_dbo.BI_DB_LTV_Predictions | LTV predictions use cluster as feature |
| BI_DB_dbo.BI_DB_AffiliateScore | Affiliate scoring uses customer cluster |
| BI_DB_dbo.BI_DB_Snapshot_CID_LifeStageDefinition | Life stage definition uses cluster |
| BI_DB_dbo.BI_DB_MarketingCloudDaily | Marketing Cloud daily feed includes cluster |

---

## 7. Sample Queries

### 7.1 Current cluster distribution

```sql
SELECT
    ClusterDetail,
    ClusterSF,
    COUNT(*) AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_CID_DailyCluster]
WHERE IsLastCluster = 1
GROUP BY ClusterDetail, ClusterSF
ORDER BY CustomerCount DESC
```

### 7.2 Cluster changes in last 30 days

```sql
SELECT
    ClusterDetail AS NewCluster,
    COUNT(*) AS NewPeriods,
    SUM(IsFirstCluster) AS BrandNewCustomers
FROM [BI_DB_dbo].[BI_DB_CID_DailyCluster]
WHERE FromDateID >= CAST(CONVERT(VARCHAR(8), DATEADD(day,-30,GETDATE()), 112) AS INT)
  AND IsLastCluster = 1
GROUP BY ClusterDetail
ORDER BY NewPeriods DESC
```

### 7.3 Cluster history for a specific customer

```sql
SELECT
    CID, ClusterDetail, ClusterDynamic, ClusterSF,
    FromDate, ToDate, IsFirstCluster, IsSFCluster
FROM [BI_DB_dbo].[BI_DB_CID_DailyCluster]
WHERE CID = 12345678
ORDER BY FromDateID DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence pages identified for this table. Cluster methodology and ML model documentation may exist in internal data science documentation.

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Batch: 63 | Object: 2/4*
*Tiers: 0 T1, 13 T2 | Elements: 9.0/10, Logic: 9.5/10, Lineage: 9.0/10, Relationships: 9.0/10*
*Object: BI_DB_dbo.BI_DB_CID_DailyCluster | Type: Table | Production Source: BI_DB_ClusteringLog (ML cluster assignments)*
