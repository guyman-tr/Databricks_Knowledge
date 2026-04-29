# BI_DB_dbo.BI_DB_ReturnCalculation

> 5.9M-row snapshot table of customer return metrics across 5 time windows (30 days, YTD, 12 months, 24 months, lifetime). One row per customer. Daily TRUNCATE+INSERT via SP_BI_DB_ReturnCalculation. Aggregates Daily_Data closed-position net profit + open-position PnL, computes Return = NetProfitPnL / AverageRealizedEquity, and enriches with population attributes from Fact_SnapshotCustomer + dimension tables.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data + BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Fact_SnapshotCustomer via `SP_BI_DB_ReturnCalculation` |
| **Refresh** | Daily (TRUNCATE+INSERT — full refresh) |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Yarden Sabadra (2024-03-26) |
| **Row Count** | ~5,873,958 (as of 2026-04-11) |

---

## 1. Business Meaning

`BI_DB_ReturnCalculation` provides a single-snapshot view of customer investment returns across five time windows: Last 30 Days, Year-to-Date, Last 12 Months, Last 24 Months, and Lifetime. Each row represents one customer (RealCID) and includes their computed return percentage, net profit + PnL, average realized equity, and total revenue for each window, along with population attributes (regulation, country, club tier, cluster, LTV, KYC data).

The return calculation combines closed-position net profit (from Daily_Data) with current open-position PnL (from BI_DB_PositionPnL). The formula is: `Return = NetProfitPnL / AverageRealizedEquity`, where AverageRealizedEquity excludes days with zero or negative equity. If AverageRealizedEquity is zero, Return defaults to 0.

Population: Valid depositing customers (IsValidCustomer=1, IsDepositor=1, PlayerLevelID<>4 from Fact_SnapshotCustomer), enriched with attributes from Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_Customer, BI_DB_CID_DailyCluster, BI_DB_LTV_Predictions, and BI_DB_KYC_Panel.

---

## 2. Business Logic

### 2.1 Return Calculation

**What**: Customer return as a ratio of net profit to average equity, computed per time window.
**Columns Involved**: `Return_Last30Days`, `Return_YearToDate`, `Return_Last12Months`, `Return_Last24Months`, `Return_Lifetime`
**Rules**:
- Return_{window} = NetProfitPnL_{window} / AverageRealizedEquity_{window}
- If AverageRealizedEquity_{window} = 0, then Return_{window} = 0
- NetProfitPnL = SUM(closed position NetProfit in window) + current open position PnL from BI_DB_PositionPnL
- AverageRealizedEquity = AVG(RealizedEquity) from V_Liabilities, excluding days where equity is zero or negative

### 2.2 Revenue Aggregation

**What**: Total revenue per customer per time window.
**Columns Involved**: `TotalRevenue_Last30Days`, `TotalRevenue_YearToDate`, `TotalRevenue_Last12Months`, `TotalRevenue_Last24Months`, `TotalRevenue_Lifetime`
**Rules**:
- TotalRevenue_{window} = SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport for dates in window
- Sourced via BI_DB_ReturnCalculation_Daily_Data.Revenue column

### 2.3 Population Enrichment

**What**: Each customer row is enriched with dimension attributes for segmentation.
**Columns Involved**: `Regulation`, `Country`, `Club`, `ClusterDetail`, `LTV`, `IsCreditReportValidCB`, `RiskApetite`
**Rules**:
- Regulation from Dim_Regulation
- Country from Dim_Country
- Club tier from Dim_PlayerLevel
- ClusterDetail from BI_DB_CID_DailyCluster (date-bounded)
- LTV from BI_DB_LTV_Predictions (LTV_8Y_VolFix)
- RiskApetite from BI_DB_KYC_Panel (Q9_AnswerText); 'N/A' if no KYC record

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) with CLUSTERED INDEX on RealCID — optimized for per-customer lookups and joins on RealCID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top returners last 12 months | `WHERE Return_Last12Months > 0 ORDER BY Return_Last12Months DESC` |
| Revenue vs return comparison | `SELECT RealCID, TotalRevenue_Lifetime, Return_Lifetime` |
| Segment by regulation | `GROUP BY Regulation` on return/revenue columns |
| Customers with negative lifetime return | `WHERE Return_Lifetime < 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | `RealCID = RealCID` | Daily breakdown behind aggregated metrics |
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_PositionPnL | `RealCID = RealCID` | Open position PnL detail |

### 3.4 Gotchas

- **Single snapshot**: Only one ReportDate exists at any time (TRUNCATE+INSERT). No historical snapshots are retained
- **RiskApetite typo**: Column name is `RiskApetite` (missing second 'p' — should be "Appetite"). Preserved from SP
- **Zero-equity handling**: Return = 0 when AverageRealizedEquity = 0, not NULL. This masks customers with no equity data
- **Open PnL included**: NetProfitPnL includes unrealized gains from open positions (BI_DB_PositionPnL), making it a mark-to-market figure

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata (system-generated) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportDate | date | NO | Snapshot date parameter (@Date). Single value per refresh cycle. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 2 | RealCID | int | NO | Customer ID. HASH distribution key and clustered index key. (Tier 2 — SP_BI_DB_ReturnCalculation, Fact_SnapshotCustomer) |
| 3 | Regulation | varchar(50) | YES | Regulation name from Dim_Regulation. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 4 | Country | varchar(50) | YES | Country name from Dim_Country. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 5 | RegisteredReal | datetime2 | YES | Customer registration date from Dim_Customer. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 6 | FirstDepositDate | datetime2 | YES | First deposit date from Dim_Customer. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 7 | Club | varchar(50) | YES | Club tier from Dim_PlayerLevel. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 8 | ClusterDetail | varchar(50) | YES | Customer cluster from BI_DB_CID_DailyCluster (date-bounded lookup). (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 9 | LTV | float | YES | LTV prediction (LTV_8Y_VolFix) from BI_DB_LTV_Predictions. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 10 | IsCreditReportValidCB | int | YES | Credit report validity flag from Fact_SnapshotCustomer. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 11 | RiskApetite | varchar(50) | YES | KYC risk appetite answer (Q9_AnswerText) from BI_DB_KYC_Panel. 'N/A' if no KYC record. Note: typo in column name (should be "Appetite"). (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 12 | Return_Last30Days | money | YES | Customer return percentage over last 30 days: NetProfitPnL_Last30Days / AverageRealizedEquity_Last30Days. 0 if no equity. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 13 | Return_YearToDate | money | YES | Customer return percentage year-to-date. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 14 | Return_Last12Months | money | YES | Customer return percentage over last 12 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 15 | Return_Last24Months | money | YES | Customer return percentage over last 24 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 16 | Return_Lifetime | money | YES | Customer return percentage over entire lifetime. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 17 | TotalRevenue_Last30Days | money | YES | Sum of FullCommissions + RollOverFee over last 30 days. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 18 | TotalRevenue_YearToDate | money | YES | Total revenue year-to-date. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 19 | TotalRevenue_Last12Months | money | YES | Total revenue over last 12 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 20 | TotalRevenue_Last24Months | money | YES | Total revenue over last 24 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 21 | TotalRevenue_Lifetime | money | YES | Total revenue over entire lifetime. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 22 | NetProfitPnL_Last30Days | money | YES | Net profit from closed positions plus open position PnL over last 30 days. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 23 | NetProfitPnL_YearToDate | money | YES | Net profit plus PnL year-to-date. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 24 | NetProfitPnL_Last12Months | money | YES | Net profit plus PnL over last 12 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 25 | NetProfitPnL_Last24Months | money | YES | Net profit plus PnL over last 24 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 26 | NetProfitPnL_Lifetime | money | YES | Net profit plus PnL over entire lifetime. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 27 | AverageRealizedEquity_Last30Days | money | YES | Average realized equity over last 30 days, excluding zero and negative equity days. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 28 | AverageRealizedEquity_YearToDate | money | YES | Average realized equity year-to-date. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 29 | AverageRealizedEquity_Last12Months | money | YES | Average realized equity over last 12 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 30 | AverageRealizedEquity_Last24Months | money | YES | Average realized equity over last 24 months. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 31 | AverageRealizedEquity_Lifetime | money | YES | Average realized equity over entire lifetime. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 32 | UpdateDate | datetime2 | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via Fact_SnapshotCustomer |
| Regulation | Dictionary.Regulation | RegulationName | dim-lookup via Dim_Regulation |
| Country | Dictionary.Country | CountryName | dim-lookup via Dim_Country |
| RegisteredReal | Customer.CustomerStatic | RegisteredReal | passthrough via Dim_Customer |
| FirstDepositDate | Customer.CustomerStatic | FirstDepositDate | passthrough via Dim_Customer |
| Club | Dictionary.PlayerLevel | PlayerLevelName | dim-lookup via Dim_PlayerLevel |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | date-bounded lookup |
| LTV | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_8Y_VolFix | passthrough |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | passthrough |
| RiskApetite | BI_DB_dbo.BI_DB_KYC_Panel | Q9_AnswerText | passthrough; 'N/A' if no KYC |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data (10.6B rows, daily metrics)
  + BI_DB_dbo.BI_DB_PositionPnL (open position PnL)
  + DWH_dbo.Fact_SnapshotCustomer (population: IsValidCustomer=1, IsDepositor=1, PlayerLevelID<>4)
  + DWH_dbo.Dim_Regulation (regulation name)
  + DWH_dbo.Dim_Country (country name)
  + DWH_dbo.Dim_PlayerLevel (club tier)
  + DWH_dbo.Dim_Customer (RegisteredReal, FirstDepositDate)
  + BI_DB_dbo.BI_DB_CID_DailyCluster (cluster detail)
  + BI_DB_dbo.BI_DB_LTV_Predictions (LTV)
  + BI_DB_dbo.BI_DB_KYC_Panel (risk appetite)
  |
  |-- SP_BI_DB_ReturnCalculation Phase 2 (daily TRUNCATE+INSERT)
  |   Step 1: TRUNCATE BI_DB_ReturnCalculation
  |   Step 2: Aggregate Daily_Data across 5 windows (30d, YTD, 12m, 24m, lifetime)
  |   Step 3: Add open position PnL from BI_DB_PositionPnL
  |   Step 4: Compute Return = NetProfitPnL / AverageRealizedEquity (0 if no equity)
  |   Step 5: Enrich with population attributes from dims
  |   Step 6: INSERT into BI_DB_ReturnCalculation
  v
BI_DB_dbo.BI_DB_ReturnCalculation (5.9M rows, HASH(RealCID) CI(RealCID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| RealCID | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data (RealCID) | Daily breakdown source |
| RealCID | BI_DB_dbo.BI_DB_PositionPnL (RealCID) | Open position PnL |
| Regulation | DWH_dbo.Dim_Regulation | Regulation lookup |
| Country | DWH_dbo.Dim_Country | Country lookup |
| Club | DWH_dbo.Dim_PlayerLevel | Club tier lookup |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | Cluster classification |
| LTV | BI_DB_dbo.BI_DB_LTV_Predictions | LTV prediction |
| RiskApetite | BI_DB_dbo.BI_DB_KYC_Panel | KYC risk appetite |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Top Returning Customers (Last 12 Months)

```sql
SELECT RealCID, Regulation, Country, Club,
       Return_Last12Months, NetProfitPnL_Last12Months, AverageRealizedEquity_Last12Months
FROM BI_DB_dbo.BI_DB_ReturnCalculation
WHERE Return_Last12Months > 0
ORDER BY Return_Last12Months DESC
```

### 7.2 Revenue vs Return by Regulation

```sql
SELECT Regulation,
       AVG(Return_Lifetime) AS AvgReturn,
       SUM(TotalRevenue_Lifetime) AS TotalRev,
       COUNT(*) AS CustomerCount
FROM BI_DB_dbo.BI_DB_ReturnCalculation
GROUP BY Regulation
ORDER BY TotalRev DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 31 T2, 0 T3, 0 T4, 1 T5 | Elements: 32/32, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_ReturnCalculation | Type: Table | Production Source: Daily_Data + PositionPnL + Fact_SnapshotCustomer via SP_BI_DB_ReturnCalculation*
