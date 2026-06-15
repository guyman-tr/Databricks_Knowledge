# BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints

> Monthly finance audit table in tall/unpivot format: 12.9M rows (Jan 2023 – Mar 2026), 22 metric types × customer dimension combinations aggregated by YearMonth/Regulation/PlayerLevel/PlayerStatus/MifidCategory/Country/InstrumentType/IsCreditReportValidCB/IsSettled; consolidates 8 ETL inputs (commissions, overnight fees, dividends, conversion fees, cashout/dormant/interest fees, ticket fees, stock margin) via SP_M_Finance_Audit_Auxillary_Datapoints.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_DepositWithdrawFee, DWH_dbo.Fact_CustomerAction, BI_DB_Client_Balance_Breakdown_Instrument_Level, BI_DB_DDR_Daily_Aggregated, BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics, Function_Revenue_TicketFee, Function_Revenue_TicketFeeByPercent, BI_DB_Fact_Customer_Action_Position_Distribution via SP_M_Finance_Audit_Auxillary_Datapoints |
| **Refresh** | Monthly (SB_Daily Priority 20); DELETE WHERE YearMonth = YYYYMM + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | ~12.9M rows |
| **Date Range** | Jan 2023 – Mar 2026 (YearMonth 202301 – 202603) |

---

## 1. Business Meaning

`BI_DB_Finance_Audit_Auxillary_Datapoints` is a monthly finance audit fact table stored in **tall/unpivot format**. Rather than having one column per metric, each row contains a single `(Metric, Amount)` pair alongside a full set of customer dimension attributes. This design allows a single table to flexibly cover 22 distinct financial metric types without schema changes when new metrics are added.

Each row represents: *for this month, in this customer segment and instrument context, this particular metric had this Amount.*

**22 metric types** across four families:

| Family | Metrics | Source |
|--------|---------|--------|
| Commission (8) | TotalCommissionReal/CFD, FullTotalCommissionReal/CFD, RealizedCommissionReal/CFD, UnrealizedCommissionChangeReal/CFD | BI_DB_Client_Balance_Breakdown_Instrument_Level |
| Overnight/Dividend (5) | TotalOvernightFee, DividendPaid, RollOverFee, SDRT, AdminFee | DWH_dbo.Fact_CustomerAction |
| Fee/Adjustment (6) | SpotAdjustFee, TotalConversionFees, TotalCashoutFee, TotalDormantFee, TotalInterestFees, TransferCoinFee | Fact_CustomerAction, BI_DB_DepositWithdrawFee, BI_DB_DDR tables |
| Ticket/StockMargin (3) | TicketFee, TicketFeeByPercent (sign-flipped), StockMarginOvernightFee | TVFs + BI_DB_Fact_Customer_Action_Position_Distribution |

**Note**: The DDL and SP spell the name "Auxillary" (double-l) — this is a production typo preserved in both the table name and SP name for backward compatibility.

**Use case**: Finance team audit of revenue and cost components by customer segment, regulatory jurisdiction, instrument type, and club/player level. Enables month-over-month comparison of each metric across all dimensions without separate tables per metric type.

---

## 2. Business Logic

### 2.1 Tall/Unpivot Design

**What**: Each month's data is stored as (dimensions, Metric, Amount) rows rather than wide columns.
**Columns Involved**: `Metric`, `Amount`, `YearMonth`
**Rules**:
- The SP builds a `#final` temp table via a large UNION ALL of 22 branches, one per metric
- Each branch selects from its source temp table with a hardcoded `'MetricName' AS Metric` string
- This means `Metric` values are SP-hardcoded — they cannot be extended without SP modification
- `Amount` is always ISNULL(SUM(source_value), 0) — no NULLs in Amount column

### 2.2 Sign Convention for Ticket Fees

**What**: TicketFee and TicketFeeByPercent use negative amounts.
**Columns Involved**: `Metric`, `Amount`
**Rules**:
- The SP applies `-SUM()` for both TicketFee and TicketFeeByPercent branches
- Result: Amount is negative for these two metrics only
- Reason: These are costs charged to the company (not revenue), so the sign flip represents cost accounting convention
- All other 20 metrics have positive Amount values (or zero if no activity)

### 2.3 IsSettled Semantics

**What**: Position settlement flag — only meaningful for commission and certain fee metrics.
**Columns Involved**: `IsSettled`, `Metric`
**Rules**:
- `IsSettled = 1` for settled/real-money positions (stocks, ETFs) in commission and overnight-fee metrics
- `IsSettled = 0` for open/CFD positions in commission and overnight-fee metrics
- For non-commission fee metrics (TotalConversionFees, TotalCashoutFee, TotalDormantFee, TotalInterestFees, TransferCoinFee, DividendPaid, SDRT): the SP inserts `'' AS IsSettled` into the #final CTAS, which converts to `0` when written to the int target column
- **Caution**: IsSettled = 0 is ambiguous — it can mean "CFD commission" or "non-instrument fee". Use `Metric` to distinguish

### 2.4 IsRealFutures Semantics

**What**: Identifies futures instruments within the InstrumentType dimension.
**Columns Involved**: `IsRealFutures`, `InstrumentType`
**Rules**:
- `CASE WHEN IsFuture=1 THEN 1 ELSE 0 END` from DWH_dbo.Dim_Instrument
- NULL (not 0) for metrics that have no instrument breakdown: TotalDormantFee, TotalCashoutFee, TotalInterestFees, TotalConversionFees, TransferCoinFee, DividendPaid, SDRT
- For these NULL-IsRealFutures rows, `InstrumentType = 'NA'` as well

### 2.5 Monthly Refresh Pattern

**What**: Full delete-and-reload per YearMonth.
**Columns Involved**: `YearMonth`, `UpdateDate`
**Rules**:
- `@date` parameter drives the run; SP computes `@yearMonth = convert(VARCHAR(6), @date, 112)` = YYYYMM
- `DELETE WHERE YearMonth = @yearMonth` removes all rows for the month before re-inserting
- This allows re-running the SP mid-month to update figures; the current month's rows always reflect the latest run
- `UpdateDate = GETDATE()` at insert time records when each row was last refreshed
- StockMarginOvernightFee rows only appear from 2026-02-16 onward (data begins at the instrument's market launch)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. With 12.9M rows and heavy GROUP BY usage, query performance depends on metric-specific filtering to reduce scan volume. No partition pruning available (no partition column).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Total overnight fees by regulation/month | `WHERE Metric = 'TotalOvernightFee' GROUP BY YearMonth, Regulation` |
| Commission breakdown by IsSettled (Real vs CFD) | `WHERE Metric IN ('TotalCommissionReal','TotalCommissionCFD') AND IsSettled IS NOT NULL` |
| All commission metrics for a customer segment | `WHERE Metric LIKE '%Commission%' AND IsCreditReportValidCB = 1` |
| Ticket fee cost trend | `WHERE Metric IN ('TicketFee','TicketFeeByPercent') — note Amount is negative` |
| StockMargin fees since launch | `WHERE Metric = 'StockMarginOvernightFee' AND YearMonth >= '202602'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | `Regulation = dr.Name` | Validate regulation names |
| DWH_dbo.Dim_PlayerLevel | `PlayerLevel = dpl.Name` | Club/tier membership |
| DWH_dbo.Dim_Country | `Country = dc.Name` | Geographic analysis |

### 3.4 Gotchas

- **DDL typo**: The table and SP are both named "Aux**ill**ary" (double-l). Do not search for "Auxiliary" (correct spelling) — you will not find it.
- **Amount is never NULL**: ISNULL(Amount, 0) in the INSERT — safe to SUM without ISNULL wrapper.
- **Ticket fees are negative**: TicketFee and TicketFeeByPercent Amount values are negative. Do not mix with positive metrics without sign adjustment.
- **IsSettled ambiguity**: IsSettled = 0 means either "CFD commission" or "non-commission fee metric". Always filter on `Metric` first.
- **IsRealFutures NULL vs 0**: NULL means "not applicable to this metric" (not the same as IsFuture=0). Use `WHERE IsRealFutures IS NOT NULL` to restrict to instrument-level rows.
- **StockMarginOvernightFee history**: Added 2026-02-16 per SR-355284. Prior months have no rows for this metric.
- **YearMonth is varchar(10)**: Stored as 6-digit string ('202301'), not int. Cast for arithmetic comparisons.
- **No CID column**: Pre-aggregated to dimensions only. Join BI_DB_Client_Balance_Breakdown_Instrument_Level directly for CID-level data.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream DWH_dbo wiki (canonical source) |
| Tier 2 | Description derived from SP code, DDL, or ETL logic (high confidence) |
| Tier 3 | Description inferred from column name, data patterns (medium confidence) |
| Tier 4 | Description speculative — needs business SME review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | YearMonth | varchar(10) | YES | Reporting period in YYYYMM string format. Computed as `convert(VARCHAR(6), @date, 112)` in SP_M_Finance_Audit_Auxillary_Datapoints. Used as the DELETE key — all rows for this YearMonth are deleted before re-insertion. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 2 | InstrumentType | varchar(100) | YES | Instrument type name from DWH_dbo.Dim_Instrument (e.g., 'Stocks', 'CFDs', 'Crypto Currencies'). Set to 'NA' for metrics that have no instrument breakdown: TotalDormantFee, TotalCashoutFee, TotalInterestFees, TotalConversionFees, TransferCoinFee, DividendPaid, SDRT. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 3 | Regulation | varchar(100) | YES | Regulatory jurisdiction name from DWH_dbo.Dim_Regulation (e.g., 'FCA', 'CySEC', 'ASIC'). Passed through as a GROUP BY dimension — this table covers all regulations unlike BI_DB_FCA_Liabilities. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 4 | PlayerLevel | varchar(100) | YES | Customer club/tier name from DWH_dbo.Dim_PlayerLevel (e.g., 'Diamond', 'Platinum'). Maps to Club column in source temp tables. GROUP BY dimension. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 5 | PlayerStatus | varchar(100) | YES | Customer status name from DWH_dbo.Dim_PlayerStatus (e.g., 'Real', 'Demo'). GROUP BY dimension for all 22 metric types. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 6 | IsCreditReportValidCB | int | YES | Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). ETL-computed. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 7 | MifidCategory | varchar(100) | YES | MiFID II categorization name from DWH_dbo.Dim_MifidCategorization (e.g., 'Retail', 'Professional', 'Eligible Counterparty'). GROUP BY dimension. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 8 | Country | varchar(100) | YES | Customer country name from DWH_dbo.Dim_Country. GROUP BY dimension for all 22 metric types. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 9 | Metric | varchar(100) | YES | Hardcoded metric name identifying the UNION ALL branch (one of 22 values). See Metric Catalogue in Section 5. Never NULL — always explicitly set in each SP branch. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 10 | Amount | float | YES | Numeric metric value for this dimension combination. ISNULL(SUM(source), 0) — never NULL. Negative for TicketFee and TicketFeeByPercent (sign-flipped in SP). All other metrics are positive or zero. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 11 | UpdateDate | datetime | YES | ETL metadata: GETDATE() timestamp at INSERT time. Records when this row was last refreshed by the SP. Not the business date. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 12 | IsRealFutures | int | YES | 1 if instrument is a real futures contract (IsFuture=1 in Dim_Instrument), 0 otherwise. NULL (not 0) for metrics with no instrument breakdown: TotalDormantFee, TotalCashoutFee, TotalInterestFees, TotalConversionFees, TransferCoinFee, DividendPaid, SDRT. Distinguish NULL (not applicable) from 0 (non-futures instrument). (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |
| 13 | IsSettled | int | YES | Position settlement flag for commission and overnight-fee metrics: 1 = settled/real position (stocks), 0 = open/CFD position. For non-instrument fee metrics (TotalConversionFees, TotalCashoutFee, TotalDormantFee, TotalInterestFees, TransferCoinFee, DividendPaid, SDRT), SP inserts `''` which converts to 0 — not meaningful for these rows. Use `Metric` to distinguish commission/overnight rows (where IsSettled is interpretable) from fee rows. (Tier 2 — SP_M_Finance_Audit_Auxillary_Datapoints) |

---

## 5. Lineage

### 5.1 Metric Catalogue (22 metrics)

| Metric | Source | Description |
|--------|--------|-------------|
| TotalCommissionReal | BI_DB_Client_Balance_Breakdown_Instrument_Level | Commission on settled (real/stock) positions |
| TotalCommissionCFD | BI_DB_Client_Balance_Breakdown_Instrument_Level | Commission on open (CFD) positions |
| FullTotalCommissionReal | BI_DB_Client_Balance_Breakdown_Instrument_Level | Full commission including maker/taker on real positions |
| FullTotalCommissionCFD | BI_DB_Client_Balance_Breakdown_Instrument_Level | Full commission on CFD positions |
| RealizedCommissionReal | BI_DB_Client_Balance_Breakdown_Instrument_Level | Realized commission on settled positions |
| RealizedCommissionCFD | BI_DB_Client_Balance_Breakdown_Instrument_Level | Realized commission on open positions |
| UnrealizedCommissionChangeReal | BI_DB_Client_Balance_Breakdown_Instrument_Level | Unrealized commission change on real positions |
| UnrealizedCommissionChangeCFD | BI_DB_Client_Balance_Breakdown_Instrument_Level | Unrealized commission change on open positions |
| TotalConversionFees | BI_DB_DepositWithdrawFee | PIP conversion fees on deposits/withdrawals |
| TotalOvernightFee | DWH_dbo.Fact_CustomerAction (ActionTypeID=35) | Overnight/swap fees |
| DividendPaid | DWH_dbo.Fact_CustomerAction (IsFeeDividend=2) | Dividends paid to customers |
| RollOverFee | DWH_dbo.Fact_CustomerAction (IsFeeDividend=1) | Rollover fees charged |
| SDRT | DWH_dbo.Fact_CustomerAction (IsFeeDividend=3) | Stamp Duty Reserve Tax |
| AdminFee | DWH_dbo.Fact_CustomerAction (CompensationReasonID=117) | Islamic finance admin fees |
| SpotAdjustFee | DWH_dbo.Fact_CustomerAction (CompensationReasonID=118) | Spot adjustment fees |
| TotalCashoutFee | BI_DB_DDR_Daily_Aggregated | Cashout processing fees |
| TotalDormantFee | BI_DB_DDR_Daily_Aggregated | Dormant account fees |
| TotalInterestFees | BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics | Interest fees charged |
| TransferCoinFee | BI_DB_DDR_Daily_Aggregated | Crypto transfer fees (InstrumentType='Crypto Currencies') |
| TicketFee | Function_Revenue_TicketFee(@sdateID, @dateID, 0) | Fixed ticket fees — Amount is negative (-SUM) |
| TicketFeeByPercent | Function_Revenue_TicketFeeByPercent(@sdateID, @dateID, 0) | Percentage-based ticket fees — Amount is negative (-SUM) |
| StockMarginOvernightFee | BI_DB_Fact_Customer_Action_Position_Distribution | Stock margin loan overnight fees (data from 2026-02-16, SR-355284) |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DepositWithdrawFee (PIP conversion fees → #pips)
  + DWH_dbo.Fact_CustomerAction (overnight ActionTypeID=35, dividends IsFeeDividend=2,
    rollovers IsFeeDividend=1, SDRT IsFeeDividend=3, admin/spot CompensationReasonID 117/118
    → #overPlusDividend)
  + BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level (commissions → #commissions)
  + BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (cashout, dormant, transfer coin fees → #CashoutFee_DormantFee, #transfercoinfee)
  + BI_DB_dbo.BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics (interest fees → #InterestFees)
  + BI_DB_dbo.Function_Revenue_TicketFee(@sdateID, @dateID, 0) (fixed ticket fees → #ticketfeefixed)
  + BI_DB_dbo.Function_Revenue_TicketFeeByPercent(@sdateID, @dateID, 0) (% ticket fees → #ticketfeepercentage)
  + BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution (stock margin fees → #StockMargin)
  + DWH_dbo.Dim_PlayerLevel, Dim_Regulation, Dim_Country, Dim_MifidCategorization,
    Dim_PlayerStatus, Dim_Instrument (dimension enrichment in each temp table)
    |-- SP_M_Finance_Audit_Auxillary_Datapoints @date (Monthly, SB_Daily Priority 20) ---|
    |   CTAS #final = UNION ALL of 22 metric branches                                     |
    |   DELETE WHERE YearMonth = YYYYMM                                                   |
    |   INSERT INTO target FROM #final                                                     |
    v
BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints
  (~12.9M rows, Jan 2023 – Mar 2026, tall/unpivot format)
  UC Target: Not Migrated
```

### 5.3 Column Lineage

| # | Column | Source | Transform | Tier |
|---|--------|--------|-----------|------|
| 1 | YearMonth | SP parameter @date | convert(VARCHAR(6), @date, 112) — YYYYMM | Tier 2 |
| 2 | InstrumentType | DWH_dbo.Dim_Instrument | Name; 'NA' for non-instrument metrics | Tier 2 |
| 3 | Regulation | DWH_dbo.Dim_Regulation | Name — GROUP BY passthrough | Tier 2 |
| 4 | PlayerLevel | DWH_dbo.Dim_PlayerLevel | Club/Name — GROUP BY passthrough | Tier 2 |
| 5 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name — GROUP BY passthrough | Tier 2 |
| 6 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB — GROUP BY passthrough | Tier 1 |
| 7 | MifidCategory | DWH_dbo.Dim_MifidCategorization | Name — GROUP BY passthrough | Tier 2 |
| 8 | Country | DWH_dbo.Dim_Country | Name — GROUP BY passthrough | Tier 2 |
| 9 | Metric | SP hardcoded | UNION ALL branch label string | Tier 2 |
| 10 | Amount | Various (see Metric Catalogue) | ISNULL(SUM(source), 0); -SUM for TicketFee variants | Tier 2 |
| 11 | UpdateDate | SP at INSERT time | GETDATE() | Tier 2 |
| 12 | IsRealFutures | DWH_dbo.Dim_Instrument | CASE WHEN IsFuture=1 THEN 1 ELSE 0; NULL for fee metrics | Tier 2 |
| 13 | IsSettled | DWH_dbo.Fact_CustomerAction / source tables | Passthrough for commission/overnight; '' → 0 (int) for fee metrics | Tier 2 |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentType, IsRealFutures | DWH_dbo.Dim_Instrument | Instrument type name and futures flag |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction name |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Club/player tier name |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Customer status name |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | Customer eligibility flag |
| MifidCategory | DWH_dbo.Dim_MifidCategorization | MiFID II classification |
| Country | DWH_dbo.Dim_Country | Country name |
| TotalConversionFees | BI_DB_dbo.BI_DB_DepositWithdrawFee | PIP conversion fee source |
| Commission metrics (8) | BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level | Commission source by instrument/settlement |
| Overnight/dividend/SDRT/admin/spot metrics (5) | DWH_dbo.Fact_CustomerAction | Fee action source table |
| TotalCashoutFee, TotalDormantFee, TransferCoinFee | BI_DB_dbo.BI_DB_DDR_Daily_Aggregated | Cashout/dormant/crypto fees (blacklisted — deferred from UC migration) |
| TotalInterestFees | BI_DB_dbo.BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics | Interest fee source (blacklisted — deferred) |
| TicketFee | BI_DB_dbo.Function_Revenue_TicketFee | Fixed ticket fee TVF |
| TicketFeeByPercent | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | Percentage ticket fee TVF |
| StockMarginOvernightFee | BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution | Stock margin overnight fee source |

### 6.2 Referenced By (other objects point to this)

No downstream SP dependencies identified in OpsDB dependency scan. This table is consumed by finance audit reporting processes (Power BI / finance dashboards).

---

## 7. Sample Queries

### Monthly Overnight Fee by Regulation

```sql
SELECT YearMonth, Regulation, SUM(Amount) AS TotalOvernightFee
FROM [BI_DB_dbo].[BI_DB_Finance_Audit_Auxillary_Datapoints]
WHERE Metric = 'TotalOvernightFee'
GROUP BY YearMonth, Regulation
ORDER BY YearMonth DESC, TotalOvernightFee DESC;
```

### Commission Real vs CFD Comparison

```sql
SELECT YearMonth,
       Regulation,
       InstrumentType,
       SUM(CASE WHEN Metric = 'TotalCommissionReal' THEN Amount ELSE 0 END) AS CommissionReal,
       SUM(CASE WHEN Metric = 'TotalCommissionCFD'  THEN Amount ELSE 0 END) AS CommissionCFD
FROM [BI_DB_dbo].[BI_DB_Finance_Audit_Auxillary_Datapoints]
WHERE Metric IN ('TotalCommissionReal', 'TotalCommissionCFD')
GROUP BY YearMonth, Regulation, InstrumentType
ORDER BY YearMonth DESC;
```

### All Metrics for a Given Month (Finance Audit View)

```sql
SELECT Metric,
       Regulation,
       SUM(Amount) AS TotalAmount
FROM [BI_DB_dbo].[BI_DB_Finance_Audit_Auxillary_Datapoints]
WHERE YearMonth = '202603'
  AND IsCreditReportValidCB = 1
GROUP BY Metric, Regulation
ORDER BY Metric, Regulation;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this table. Finance audit context for individual metric types is documented in respective source table wikis (V_Liabilities, Fact_CustomerAction, Client_Balance_Breakdown_Instrument_Level).

---

*Generated: 2026-04-22 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 1 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 9/10, Evidence: 9/10*
*Object: BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints | Type: Table | Production Source: SP_M_Finance_Audit_Auxillary_Datapoints*
