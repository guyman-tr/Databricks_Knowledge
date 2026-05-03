# BI_DB_dbo.LTV_Conversions_Multipliers_Table

> 336-row static lookup table providing conversion-fee revenue multipliers for the LTV model, keyed by marketing region (14), behavioural cluster (8), and first-month deposit currency (USD/Non_USD/NULL). One-time load on 2024-10-30 via SP_BI_DB_LTV_Conversions_Multipliers_Table using FTD cohort 2019–2021 revenue accumulated through 2024-09-30.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Static Lookup) |
| **Production Source** | Multi-source ETL (Function_Revenue_Total, Dim_Customer, Dim_Country, BI_DB_CID_MonthlyPanel_FullData, Fact_BillingDeposit) via SP_BI_DB_LTV_Conversions_Multipliers_Table |
| **Refresh** | One-time (guarded by `GETDATE() <= '2024-10-30'`; will not re-execute after that date) |
| | |
| **Synapse Distribution** | HASH(Region) |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`LTV_Conversions_Multipliers_Table` is a static reference table that provides revenue adjustment multipliers used by the LTV (Lifetime Value) prediction model to incorporate conversion fee impact into revenue projections. It was designed by the Insights Team (Jan Iablunovskey) in September 2024 to answer: "by how much does including conversion fees change a customer's projected lifetime revenue, given their region, behavioural cluster, and deposit currency?"

The table contains 336 rows representing the complete cross-product of 14 marketing regions × 8 first-month behavioural clusters × 3 currency buckets (USD, Non_USD, NULL). For each combination, it stores:
- Accumulated revenue components (TotalFullCommission, RolloverFee, ConversionFee) from `Function_Revenue_Total` for depositors with FTDs in 2019–2021, accumulated through 2024-09-30
- The ratio by which conversion fees change total revenue (`Revenue_Change_Percentage`)
- A business-rule-adjusted version of that ratio (`Revenue_Change_Percentage_Fixed`) that caps extremes, zeroes out USA (no conversion fees), and falls back to regional averages for small groups (<100 clients) or NULL dimensions

The downstream consumer is `SP_LTV_BI_Actual`, which multiplies the base LTV predictions by `(1 + Revenue_Change_Percentage_Fixed)` to produce conversion-fee-inclusive LTV estimates (`LTV_*_Final` columns in `BI_DB_CID_MonthlyPanel_FullData`).

The SP is guarded by `IF CAST(GETDATE() AS DATE) <= '2024-10-30'`, meaning it executed once and will not run again unless the guard is removed. The table is therefore frozen as of 2024-10-30.

---

## 2. Business Logic

### 2.1 Revenue Change Percentage — Raw Ratio

**What**: The fractional increase in lifetime revenue when conversion fees are added to the base revenue (commissions + rollover fees).

**Columns Involved**: `Revenue_Change_Percentage`, `Revenue_LTV_WO_Conversions`, `Revenue_LTV_Incl_Conversions`

**Rules**:
- `Revenue_Change_Percentage = Revenue_LTV_Incl_Conversions / Revenue_LTV_WO_Conversions − 1`
- If `Revenue_LTV_WO_Conversions = 0`, the ratio is 0 (avoids division by zero)
- Computed per Region/First_Cluster/Currency group

### 2.2 Revenue Change Percentage Fixed — Business-Rule-Adjusted Multiplier

**What**: The production multiplier applied to LTV predictions. Applies caps, regional fallbacks, and NULL handling to the raw ratio.

**Columns Involved**: `Revenue_Change_Percentage_Fixed`, `Revenue_Change_Percentage`, `Region`, `Clients`, `First_Cluster`, `Currency`, `TotalFullCommission`

**Rules** (evaluated in CASE order, first match wins):
1. **Cap at 0.1**: If raw `Revenue_Change_Percentage > 0.1` → 0.1 (prevents extreme upward distortion)
2. **USA = 0**: No conversion fees apply in the USA region → multiplier is always 0
3. **Small groups (<100 clients)**: Use the region-level-only average (`#Region3.Revenue_Change_Percentage`) instead of the granular group value
4. **NULL Currency, non-NULL Cluster**: Use region+cluster average (`#Region2`)
5. **NULL Cluster, non-NULL Currency**: Use region+currency average (`#Region`)
6. **Both NULL**: Use region-only average (`#Region3`)
7. **NULL TotalFullCommission**: Use region-only average (combination had no revenue data)
8. **Otherwise**: Use the raw `Revenue_Change_Percentage` as-is

Observed range: 0.0 to 0.1 (cap enforced).

### 2.3 First Cluster Derivation

**What**: Customer's behavioural cluster at seniority month 1 (one month after FTD).

**Columns Involved**: `First_Cluster`

**Rules**:
- If `BI_DB_CID_MonthlyPanel_FullData.ClusterDetail IS NOT NULL` at Seniority=1 → use that cluster name
- Else if `FirstAction IS NOT NULL` AND `VerificationLevelID = 3` → 'No Cluster - Active'
- Else → 'No Cluster - Inactive'
- 8 distinct values: Diversified Traders, Equities Investors, Equities Traders, Crypto, Leveraged Traders, Equities Crypto, No Cluster - Active, No Cluster - Inactive

### 2.4 Currency Bucket Derivation

**What**: Whether the customer's primary first-month deposit currency was USD or not.

**Columns Involved**: `Currency`

**Rules**:
- For each customer, aggregate approved deposits (`PaymentStatusID=2`) in the first 30 days after FTD, grouped by CurrencyID
- Pick the CurrencyID with the highest total AmountUSD (ROW_NUMBER partitioned by CID, ordered by AmountUSD DESC)
- If `CurrencyID = 1` → 'USD'; else → 'Non_USD'
- Unmatched customers (no deposits in window) → NULL (empty string in the table)
- 3 buckets: USD (112 rows), Non_USD (112 rows), empty/NULL (112 rows)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(Region) on a 336-row table. The table is tiny — distribution choice has negligible performance impact. HEAP (no clustered index). All 14 regions have exactly 24 rows each (8 clusters × 3 currencies).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up multiplier for a customer segment | `WHERE Region = @r AND ISNULL(First_Cluster, 'N/A') = ISNULL(@c, 'N/A') AND ISNULL(Currency, 'N/A') = ISNULL(@cur, 'N/A')` |
| Average multiplier by region | `SELECT Region, AVG(Revenue_Change_Percentage_Fixed) FROM ... GROUP BY Region` |
| Which segments have the highest conversion fee impact? | `SELECT TOP 10 * ORDER BY Revenue_Change_Percentage_Fixed DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| SP_LTV_BI_Actual (#Temp3) | `ISNULL(a.Region,'N/A')=ISNULL(t.NewMarketingRegion,'N/A') AND ISNULL(a.First_Cluster,'N/A')=ISNULL(t.First_Month_Cluster,'N/A') AND ISNULL(a.Currency,'N/A')=ISNULL(t.Currency,'N/A')` | Apply conversion multiplier to LTV predictions |

### 3.4 Gotchas

- **Frozen table**: The SP guard (`GETDATE() <= '2024-10-30'`) means this data is static. It reflects FTD cohort 2019–2021 revenue through 2024-09-30. It will not update unless the guard date is changed.
- **NULL/empty Currency**: The third currency bucket is stored as an empty string (`''`), not SQL NULL. JOINs must use `ISNULL(Currency, 'N/A')` pattern to match correctly.
- **31 NULL revenue rows**: 31 of 336 rows have NULL in TotalFullCommission/RolloverFee/ConversionFee/Revenue_Change_Percentage — these represent Region/Cluster/Currency combinations with no customers in the FTD cohort. Their `Revenue_Change_Percentage_Fixed` is filled from the region-level fallback.
- **Revenue_Change_Percentage_Fixed cap**: The maximum value is 0.1 (10%). Any raw ratio above 10% is capped to prevent extreme LTV inflation.
- **USA always 0**: USA region gets a hardcoded 0 multiplier regardless of actual conversion fees, because conversion fees do not apply in the USA regulatory environment.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim |
| Tier 2 | SP/ETL code |
| Tier 3 | Live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Region | nvarchar(300) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country (renamed from MarketingRegionManualName). 14 distinct values: Arabic, Australia, CEE, French, German, Italian, Latam, Nordics, ROW, SEA, Spain, UK, Unknown, USA. (Tier 1 — Ext_Dim_Country) |
| 2 | First_Cluster | nvarchar(300) | YES | Customer behavioural cluster at seniority month 1. CASE: ClusterDetail from BI_DB_CID_MonthlyPanel_FullData if available; 'No Cluster - Active' if FirstAction exists and VerificationLevelID=3; else 'No Cluster - Inactive'. 8 distinct values: Crypto, Diversified Traders, Equities Crypto, Equities Investors, Equities Traders, Leveraged Traders, No Cluster - Active, No Cluster - Inactive. (Tier 2 — BI_DB_CID_MonthlyPanel_FullData) |
| 3 | Currency | nvarchar(300) | YES | First-month deposit currency preference: 'USD' if CurrencyID=1, 'Non_USD' otherwise, based on the highest-AmountUSD deposit currency in the first 30 days after FTD. Empty string for unmatched combinations. 3 values: USD, Non_USD, '' (empty). (Tier 2 — Fact_BillingDeposit) |
| 4 | TotalFullCommission | money | YES | Accumulated total full commission revenue (SUM of Amount where Metric='TotalFullCommission') from Function_Revenue_Total for the FTD 2019–2021 cohort through 2024-09-30, grouped by Region/First_Cluster/Currency. NULL for empty group combinations. (Tier 2 — Function_Revenue_Total) |
| 5 | RolloverFee | money | YES | Accumulated rollover (overnight swap) fee revenue (SUM of Amount where Metric='RolloverFee') from Function_Revenue_Total for the FTD 2019–2021 cohort through 2024-09-30, grouped by Region/First_Cluster/Currency. NULL for empty group combinations. (Tier 2 — Function_Revenue_Total) |
| 6 | ConversionFee | money | YES | Accumulated currency conversion fee revenue (SUM of Amount where Metric='ConversionFee') from Function_Revenue_Total for the FTD 2019–2021 cohort through 2024-09-30, grouped by Region/First_Cluster/Currency. NULL for empty group combinations. (Tier 2 — Function_Revenue_Total) |
| 7 | Revenue_LTV_WO_Conversions | money | YES | Revenue used in LTV model excluding conversion fees: TotalFullCommission + RolloverFee per group. NULL for empty group combinations. (Tier 2 — Function_Revenue_Total) |
| 8 | Revenue_LTV_Incl_Conversions | money | YES | Revenue used in LTV model including conversion fees: TotalFullCommission + RolloverFee + ConversionFee per group. NULL for empty group combinations. (Tier 2 — Function_Revenue_Total) |
| 9 | Revenue_Change_Percentage | float | YES | Raw fractional change when conversion fees are included: (Revenue_LTV_Incl_Conversions / Revenue_LTV_WO_Conversions) − 1. 0 when denominator is 0. NULL for empty group combinations. (Tier 2 — Function_Revenue_Total) |
| 10 | Clients | int | YES | Count of distinct depositors (FTD in 2019–2021, IsDepositor=1) in this Region/First_Cluster/Currency group. 0 for unmatched cross-join combinations. Range: 0–219,458. (Tier 2 — Dim_Customer) |
| 11 | Revenue_Change_Percentage_Fixed | float | YES | Business-rule-adjusted conversion fee multiplier used by SP_LTV_BI_Actual. Capped at 0.1; USA hardcoded to 0; groups with <100 clients fall back to region-level average; NULL dimensions fall back to coarser aggregation levels. Range: 0.0–0.1. (Tier 2 — Function_Revenue_Total / Dim_Country) |
| 12 | UpdateDate | date | NO | ETL execution timestamp. Set to GETDATE() at SP runtime. All rows show 2024-10-30 (the single execution date). (Tier 2 — SP_BI_DB_LTV_Conversions_Multipliers_Table) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Rename (dc1.MarketingRegionManualName AS Region) via Dim_Customer.CountryID JOIN |
| First_Cluster | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | ClusterDetail, FirstAction | CASE at Seniority=1; 3-branch logic with VerificationLevelID |
| Currency | DWH_dbo.Fact_BillingDeposit | CurrencyID | CASE (1→'USD', else→'Non_USD'); ROW_NUMBER by AmountUSD DESC in first 30 days |
| TotalFullCommission | BI_DB_dbo.Function_Revenue_Total | Amount (Metric='FullCommission'→'TotalFullCommission') | SUM, filtered to FTD 2019–2021 cohort |
| RolloverFee | BI_DB_dbo.Function_Revenue_Total | Amount (Metric='RolloverFee') | SUM, filtered to FTD 2019–2021 cohort |
| ConversionFee | BI_DB_dbo.Function_Revenue_Total | Amount (Metric='ConversionFee') | SUM, filtered to FTD 2019–2021 cohort |
| Revenue_LTV_WO_Conversions | Computed | TotalFullCommission + RolloverFee | SUM per group |
| Revenue_LTV_Incl_Conversions | Computed | TotalFullCommission + RolloverFee + ConversionFee | SUM per group |
| Revenue_Change_Percentage | Computed | Revenue_LTV_Incl_Conversions / Revenue_LTV_WO_Conversions − 1 | Division with zero guard |
| Clients | DWH_dbo.Dim_Customer | RealCID | COUNT(*) of depositors per group |
| Revenue_Change_Percentage_Fixed | Computed | Revenue_Change_Percentage + fallback logic | CASE with 7 business rules (cap, USA, small group, NULL handling) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.Function_Revenue_Total(20190101, 20241027, 1)
  → #Revenue (CID, Metric, Amount) — 3 metrics filtered
  |
DWH_dbo.Dim_Customer (FTD 2019–2021, IsDepositor=1)
  + DWH_dbo.Dim_Country (MarketingRegionManualName → Region)
  → #Flat_Revenue (CID, Region, revenue components)
  |
BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (Seniority=1)
  → #First_Cluster (CID, First_Cluster via CASE)
  |
DWH_dbo.Fact_BillingDeposit (first 30 days, PaymentStatusID=2)
  → #Currency (CID, Currency via CASE on CurrencyID)
  |
#Combinations (CROSS JOIN of all Region × Cluster × Currency)
  + #PreFinal (GROUP BY aggregation of revenue/clients)
  + #Region / #Region2 / #Region3 (fallback averages)
  → #Final1 (Revenue_Change_Percentage_Fixed via CASE)
  |
  v [TRUNCATE + INSERT]
BI_DB_dbo.LTV_Conversions_Multipliers_Table (336 rows, frozen 2024-10-30)
  |
  v [consumed by]
SP_LTV_BI_Actual → multiplies LTV predictions by (1 + Revenue_Change_Percentage_Fixed)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Region | DWH_dbo.Dim_Country.MarketingRegionManualName | Marketing region source |
| First_Cluster | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData.ClusterDetail | Behavioural cluster source |
| Currency | DWH_dbo.Fact_BillingDeposit.CurrencyID | Deposit currency source |
| Revenue columns | BI_DB_dbo.Function_Revenue_Total | Revenue metrics source |
| Clients | DWH_dbo.Dim_Customer | Customer population source |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_LTV_BI_Actual | Revenue_Change_Percentage_Fixed | Multiplied by (1 + Fixed) to produce conversion-fee-inclusive LTV predictions (Revenue1Y/3Y/8Y_LTV_New_Final) |

---

## 7. Sample Queries

### 7.1 Lookup conversion multiplier for a customer segment

```sql
SELECT Region, First_Cluster, Currency,
       Revenue_Change_Percentage_Fixed
FROM [BI_DB_dbo].[LTV_Conversions_Multipliers_Table]
WHERE Region = 'UK'
  AND First_Cluster = 'Equities Investors'
  AND Currency = 'USD';
```

### 7.2 Regional average multiplier

```sql
SELECT Region,
       AVG(Revenue_Change_Percentage_Fixed) AS AvgMultiplier,
       SUM(Clients) AS TotalClients
FROM [BI_DB_dbo].[LTV_Conversions_Multipliers_Table]
GROUP BY Region
ORDER BY AvgMultiplier DESC;
```

### 7.3 Segments with highest conversion fee impact

```sql
SELECT TOP 10 Region, First_Cluster, Currency,
       Revenue_Change_Percentage_Fixed,
       Clients
FROM [BI_DB_dbo].[LTV_Conversions_Multipliers_Table]
WHERE Clients >= 100
ORDER BY Revenue_Change_Percentage_Fixed DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 10/14 (no Atlassian)*
*Tiers: 1 T1, 11 T2, 0 T3, 0 T4 | Elements: 12/12, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.LTV_Conversions_Multipliers_Table | Type: Table (Static Lookup) | Production Source: Multi-source (Function_Revenue_Total, Dim_Customer, Dim_Country, BI_DB_CID_MonthlyPanel_FullData, Fact_BillingDeposit)*
