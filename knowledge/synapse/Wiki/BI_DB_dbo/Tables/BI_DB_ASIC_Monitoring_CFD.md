# BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD

> Daily per-customer ASIC regulatory monitoring snapshot for CFD-eligible customers, computing six alert indicators (concentration risk, loss/investment ratio, margin-call history, negative balance events, and high-leverage trading patterns) used for ongoing compliance reporting under ASIC/GAML regulations.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: DWH_dbo.Fact_SnapshotCustomer (population), BI_DB_dbo.BI_DB_PositionPnL (7-day equity), DWH_dbo.Dim_Position (6-month closed positions), DWH_dbo.Fact_CustomerAction (compensation events) |
| **Refresh** | Daily via SP_BI_DB_ASIC_Monitoring_CFD(@Date) — DELETE+INSERT per date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| | |
| **UC Target** | Not mapped in generic pipeline (BI_DB compliance table) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_ASIC_Monitoring_CFD` is the core ASIC regulatory compliance monitoring table for eToro's CFD business. Under Australian Securities and Investments Commission (ASIC) and GAML (Global Anti-Money Laundering) regulations, eToro must continuously monitor customer CFD trading behaviour to identify customers who may be at risk of harm from excessive leverage, concentrated exposure, or repeated losses.

The table holds one row per (Date, RealCID) pair for **ASIC-regulated customers** (RegulationID IN (4, 10)) who are **CFD_Allowed** (passed or exempt from appropriateness testing). Each row scores the customer against six named regulatory alerts:

- **Alert A1 — Concentration Risk**: Is the customer's manual CFD equity > 50% of their total portfolio equity (averaged over the last 7 trading days)?
- **Alert A2 — Loss/Investment Ratio**: Did the customer have any closed manual CFD position in the last 6 months where the loss exceeded 50% of the invested amount?
- **Alert A4 — BSL (Below Stop-Loss / Margin Call)**: Did any manual CFD position close via margin call (BSL, ClosePositionReasonID=16) in the last 6 months?
- **Alert A5 — Negative Balance**: Did the customer receive a negative-balance compensation event (CompensationReasonID=11) in the last 6 months?
- **Alert A6 — High Leverage Trading**: Did more than 50% of the customer's closed manual CFD positions in the last 6 months use leverage at or above the regulatory maximum thresholds per asset class?

Additionally, `TotalNetProfit` and `TotalManualCFD_NetProfit` provide cumulative P&L context to date.

**Population**: Only customers where `Fact_SnapshotCustomer.RegulationID IN (4, 10)` AND `BI_DB_Scored_Appropriateness_Negative_Market.CFD_Status = 'CFD_Allowed'` (or no record in that table) as of the snapshot date. Alert A3 (referenced in SP comments) is not computed in the current SP version.

**Data observed (2023-11-04)**: 483,559 customers from 215 countries, 119 account managers. A1 flagged: 6.6%, A2 flagged: 3.9%, A4 flagged: <0.01%, A5 flagged: <0.01%, A6 flagged: 1.9%. TotalNetProfit ranges from -$16.7M to +$11.5M. Date range in table: 2023-10-30 to 2023-11-04 (6 dates, ~2.9M rows total).

---

## 2. Business Logic

### 2.1 Population Filter

**What**: Determines which customers appear in this table each day.

**Rules**:
- `Fact_SnapshotCustomer` is filtered to the snapshot state on `@Date` using `Dim_Range` (FromDateID ≤ @DateID ≤ ToDateID).
- Only customers with `RegulationID IN (4, 10)` (ASIC and GAML regulation IDs).
- LEFT JOIN to `BI_DB_Scored_Appropriateness_Negative_Market` — only customers where `ISNULL(CFD_Status, 'CFD_Allowed') = 'CFD_Allowed'` are included. Customers explicitly blocked from CFD trading are excluded.

### 2.2 Alert A1 — Concentration Risk (7-Day Window)

**What**: Measures whether a customer's manual CFD positions dominate their total portfolio.

**Columns**: `A1_ConcentrationRisk_Ind`, `A1_FinalAvgEquity`

**Computation**:
```sql
-- Over the 7 days prior to @Date (DateID >= @DateID7DaysAgo AND < @DateID):
EquityManualCFD = SUM(Amount + PositionPnL) WHERE IsSettled=0 AND MirrorID=0
TotalEquity     = SUM(Amount + PositionPnL) for all positions

-- Per customer, averaged across days:
FinalAvgEquity = CASE WHEN AVG(TotalEquity)<>0 THEN AVG(EquityManualCFD)/AVG(TotalEquity) ELSE 0 END

A1_FinalAvgEquity        = ISNULL(FinalAvgEquity, 0)
A1_ConcentrationRisk_Ind = CASE WHEN FinalAvgEquity > 0.5 THEN 1 ELSE 0 END
```

Source: `BI_DB_dbo.BI_DB_PositionPnL`

### 2.3 Alert A2 — Loss/Investment Ratio (6-Month Window)

**What**: Flags customers with positions where losses exceeded 50% of the invested amount.

**Columns**: `A2_LossInvestmentRatio_Ind`, `A2_LossInvestmentRatio_CountPos`

**Computation**:
```sql
-- For closed manual CFD positions (IsSettled=0, MirrorID=0) in last 6 months:
LossInvestmentRatio = CASE WHEN NetProfit < 0 AND Amount > 0 THEN ABS(NetProfit)/Amount ELSE 0 END

A2_LossInvestmentRatio_Ind      = MAX(CASE WHEN LossInvestmentRatio > 0.5 THEN 1 ELSE 0 END)
A2_LossInvestmentRatio_CountPos = SUM(CASE WHEN LossInvestmentRatio > 0.5 THEN 1 ELSE 0 END)
```

Source: `DWH_dbo.Dim_Position`

### 2.4 Alert A4 — BSL (Margin Call) History (6-Month Window)

**What**: Detects whether the customer had any position forcibly closed at or below their stop-loss due to a gap event (margin call).

**Columns**: `A4_Last_BSL_Date_Ind`, `A4_Last_BSL_Date_MaxDate`

**Computation**:
```sql
A4_Last_BSL_Date_Ind     = MAX(CASE WHEN ClosePositionReasonID=16 THEN 1 ELSE 0 END)
A4_Last_BSL_Date_MaxDate = MAX(CASE WHEN ClosePositionReasonID=16 THEN CloseOccurred ELSE '1999-01-01' END)
```

`ClosePositionReasonID=16` = "BSL" (Below Stop Loss / gap margin call) per `Dim_ClosePositionReason`.
Sentinel value '1999-01-01' when never triggered. Source: `DWH_dbo.Dim_Position`

### 2.5 Alert A5 — Negative Balance (6-Month Window)

**What**: Detects customers who went into negative balance and required a compensation adjustment.

**Columns**: `A5_NegativeBalance_Ind`, `A5_Last_NegativeBalance_Date_MaxDate`

**Computation**:
```sql
-- From Fact_CustomerAction where ActionTypeID=36 (Compensation):
A5_NegativeBalance_Ind           = MAX(CASE WHEN CompensationReasonID=11 THEN 1 ELSE 0 END)
NegativeBalanceLastDateID        = MAX(CASE WHEN CompensationReasonID=11 THEN DateID ELSE 19990101 END)
A5_Last_NegativeBalance_Date_MaxDate = CAST(CAST(NegativeBalanceLastDateID AS char(8)) AS date)
```

`CompensationReasonID=11` = Negative Balance compensation. Sentinel '1999-01-01' when never triggered.
Source: `DWH_dbo.Fact_CustomerAction`

### 2.6 Alert A6 — High Leverage Trading (6-Month Window)

**What**: Flags customers using maximum regulatory leverage on a majority (>50%) of their closed manual CFD positions.

**Columns**: `A6_HighLeverageTrading_Ind`

**Max-leverage thresholds (from SP code)**:
| Asset Class | InstrumentTypeID | Threshold (IsMaxLeverage=1 if Leverage >=) |
|---|---|---|
| Crypto | 10 | 2× |
| Currencies (Forex) | 1 | 30× |
| Commodities | 2 | 20× |
| Indices | 4 | 20× |
| Stocks / ETF | 5, 6 | 5× |

**Computation**:
```sql
IsMaxLeverage per position = CASE WHEN (InstrumentTypeID=10 AND Leverage>=2) OR
                                       (InstrumentTypeID=1 AND Leverage>=30) OR
                                       (InstrumentTypeID=2 AND Leverage>=20) OR
                                       (InstrumentTypeID=4 AND Leverage>=20) OR
                                       (InstrumentTypeID IN (5,6) AND Leverage>=5) THEN 1 ELSE 0 END

A6_HighLeverageTrading_Ind = CASE WHEN TotalPosMaxLeverage/TotalPosManualCFD > 0 THEN 1 ELSE 0 END
-- (i.e., at least one position at max leverage AND the ratio is > 0, which effectively means any)
```

Source: `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Instrument`

### 2.7 Cumulative P&L Context

**What**: Provides lifetime P&L context for compliance analysts reviewing flagged customers.

**Columns**: `TotalNetProfit`, `TotalManualCFD_NetProfit`

```sql
TotalNetProfit          = SUM(dp.NetProfit) WHERE CloseDateID < @DateID (all positions)
TotalManualCFD_NetProfit = SUM(dp.NetProfit) WHERE CloseDateID < @DateID AND IsSettled=0 AND MirrorID=0
```

Source: `DWH_dbo.Dim_Position`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) distribution means per-customer queries are co-located. The CLUSTERED INDEX on `[Date] ASC` means date-range scans are efficient, but note there is no partition — full-table scans by Date alone may touch all distributions. Always combine `WHERE Date = @dt AND RealCID = @cid` for point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Customers flagged by any alert on a given date | `WHERE Date = @dt AND (A1_ConcentrationRisk_Ind=1 OR A2_LossInvestmentRatio_Ind=1 OR A4_Last_BSL_Date_Ind=1 OR A5_NegativeBalance_Ind=1 OR A6_HighLeverageTrading_Ind=1)` |
| Concentration risk customers | `WHERE Date = @dt AND A1_ConcentrationRisk_Ind = 1 ORDER BY A1_FinalAvgEquity DESC` |
| Customers with margin call history | `WHERE Date = @dt AND A4_Last_BSL_Date_Ind = 1` |
| Multi-alert customers (highest risk) | `WHERE Date = @dt` and sum the five indicator columns |
| Trend over time for a customer | `WHERE RealCID = @cid ORDER BY Date` |
| Country-level compliance breakdown | `WHERE Date = @dt GROUP BY Country` |

### 3.3 Common JOINs

| Join To | Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON RealCID = dc.RealCID | Full customer profile |
| DWH_dbo.Dim_Country | ON Country = dc.Name (or via Dim_Customer.CountryID) | Country attributes |
| BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | ON RealCID | Appropriateness test status |

### 3.4 Gotchas

- **Alert A3 not computed**: SP comments reference Alert #3 but no A3 columns exist in the DDL or SP output.
- **A4_Last_BSL_Date_MaxDate and A5_Last_NegativeBalance_Date_MaxDate default to '1999-01-01'** (not NULL) when the indicator is 0. Always use the `_Ind` flag to gate on these date columns.
- **Only 6 dates in table** (as of last ETL run 2023-11-04). The table accumulates one date per daily run. Older dates persist.
- **A6_HighLeverageTrading_Ind**: The denominator check `TotalPosManualCFD > 0 AND TotalPosMaxLeverage/TotalPosManualCFD > 0` means any customer with at least one max-leverage position (ratio > 0) is flagged, not strictly > 50%.
- **Table does not include CopyTrading positions**: All alerts are scoped to `ISNULL(MirrorID, 0) = 0` (manual positions only).
- **Population excludes CFD_Blocked customers**: Customers currently blocked from CFD trading are excluded from the population entirely.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|---|---|---|
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` |
| ★★★☆☆ | Tier 2 | `(Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Reporting date — the snapshot date for which ASIC monitoring alerts are computed. One row per (Date, RealCID). Injected by SP parameter @Date. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD) |
| 2 | RealCID | int | NO | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 — Fact_SnapshotCustomer) |
| 3 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Dim_Customer, Customer.CustomerStatic) |
| 4 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dim_Country, Dictionary.Country upstream wiki) |
| 5 | Club | varchar(50) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 — Dim_PlayerLevel, Dictionary.PlayerLevel) |
| 6 | AccountManager | nvarchar(50) | YES | Full name of the assigned BackOffice account manager — concatenated from Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via fsc.AccountManagerID. 119 distinct managers in current data. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Manager) |
| 7 | A1_ConcentrationRisk_Ind | bit | YES | Alert A1 — Concentration Risk indicator. 1 if the customer's average manual CFD equity exceeded 50% of total portfolio equity over the last 7 days (A1_FinalAvgEquity > 0.5). 6.6% of customers flagged. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD) |
| 8 | A1_FinalAvgEquity | decimal(16,4) | YES | Alert A1 — Average ratio of manual CFD equity to total equity over the 7 days prior to Date. Computed as AVG(Amount + PositionPnL for IsSettled=0, MirrorID=0) / AVG(Amount + PositionPnL for all positions) per day, then averaged across days. Range: 0 to ~1.0. 0 when TotalEquity is zero. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, BI_DB_PositionPnL) |
| 9 | A2_LossInvestmentRatio_Ind | bit | YES | Alert A2 — Loss/Investment Ratio indicator. 1 if any closed manual CFD position in the last 6 months had a loss exceeding 50% of the invested amount (ABS(NetProfit)/Amount > 0.5 where NetProfit < 0). 3.9% of customers flagged. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position) |
| 10 | A2_LossInvestmentRatio_CountPos | int | YES | Alert A2 — Count of closed manual CFD positions in the last 6 months where the loss/investment ratio exceeded 0.5. Observed range: 0 to 750. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position) |
| 11 | A4_Last_BSL_Date_Ind | bit | YES | Alert A4 — BSL (Below Stop-Loss / margin call) indicator. 1 if any manual CFD position closed with ClosePositionReasonID=16 (BSL/gap margin call) in the last 6 months. <0.01% of customers flagged. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position) |
| 12 | A4_Last_BSL_Date_MaxDate | date | YES | Alert A4 — Date of the most recent BSL margin call close within the last 6 months. '1999-01-01' sentinel when A4_Last_BSL_Date_Ind=0. Do not interpret '1999-01-01' as a real date — use the _Ind flag to gate on this column. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position) |
| 13 | A5_NegativeBalance_Ind | bit | YES | Alert A5 — Negative Balance indicator. 1 if the customer received a negative-balance compensation event (Fact_CustomerAction.CompensationReasonID=11, ActionTypeID=36) in the last 6 months. <0.01% of customers flagged. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Fact_CustomerAction) |
| 14 | A5_Last_NegativeBalance_Date_MaxDate | date | YES | Alert A5 — Date of the most recent negative-balance compensation event within the last 6 months. '1999-01-01' sentinel when A5_NegativeBalance_Ind=0. Do not interpret '1999-01-01' as a real date. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Fact_CustomerAction) |
| 15 | A6_HighLeverageTrading_Ind | bit | YES | Alert A6 — High Leverage Trading indicator. 1 if any closed manual CFD position in the last 6 months used leverage at or above the ASIC maximum thresholds: Crypto ≥2×, Forex ≥30×, Commodities/Indices ≥20×, Stocks/ETF ≥5×. 1.9% of customers flagged. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position + Dim_Instrument) |
| 16 | TotalNetProfit | decimal(16,4) | YES | Sum of NetProfit for all closed positions (all types: CFD, copy, real assets) up to but not including Date. Provides lifetime P&L context for compliance review. Range: -$16.7M to +$11.5M observed. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position) |
| 17 | TotalManualCFD_NetProfit | decimal(16,4) | YES | Sum of NetProfit for closed manual CFD positions only (IsSettled=0, MirrorID=0) up to but not including Date. Isolates the customer's direct leverage-trading P&L for regulatory assessment. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD, Dim_Position) |
| 18 | LastUpdateDate | datetime | YES | ETL execution timestamp. Set to GETDATE() when the SP inserts rows for the reporting date. Uniform across all rows for a given Date. (Tier 2 — SP_BI_DB_ASIC_Monitoring_CFD) |

---

## 5. Lineage

See [`BI_DB_ASIC_Monitoring_CFD.lineage.md`](BI_DB_ASIC_Monitoring_CFD.lineage.md) for full column-level lineage.

### Production Sources

| Source System | Objects | Role |
|---|---|---|
| DWH_dbo | Fact_SnapshotCustomer, Dim_Range, Dim_Customer, Dim_Country, Dim_PlayerLevel, Dim_Manager, Dim_Position, Dim_ClosePositionReason, Dim_Instrument, Fact_CustomerAction | Population, demographics, position history, compensation events |
| BI_DB_dbo | BI_DB_PositionPnL, BI_DB_Scored_Appropriateness_Negative_Market | 7-day equity snapshot, CFD eligibility filter |

### ETL Pipeline

```
Fact_SnapshotCustomer (@Date snapshot via Dim_Range)
  + Dim_Customer, Dim_Country, Dim_PlayerLevel, Dim_Manager
  + BI_DB_Scored_Appropriateness_Negative_Market (CFD_Allowed filter)
  → #pop (ASIC population, ~484K customers)

BI_DB_PositionPnL (last 7 days)
  → #7DaysDailyPnL → #AVG7DaysPnL (A1 alert)

Dim_Position + Dim_ClosePositionReason + Dim_Instrument (last 6 months, manual CFD)
  → #ClosedManualCFD6Months
  → #LossInvestmentRatio (A2)
  → #BSL_CloseReason (A4)
  → #TotalMaxLeverage → #RatioCalcMaxLeverage (A6)
  → #ClosedPosToDate (TotalNetProfit, TotalManualCFD_NetProfit)

Fact_CustomerAction (last 6 months, CompensationReasonID=11)
  → #Compensation (A5)

All above → #FinalTable
  → DELETE FROM BI_DB_ASIC_Monitoring_CFD WHERE Date = @Date
  → INSERT INTO BI_DB_ASIC_Monitoring_CFD (18 columns)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---|---|---|
| RealCID | DWH_dbo.Dim_Customer | Customer profile |
| Country | DWH_dbo.Dim_Country | Country dimension (join by Name or via Dim_Customer.CountryID) |
| Club | DWH_dbo.Dim_PlayerLevel | Loyalty tier |
| AccountManager | DWH_dbo.Dim_Manager | Account manager reference |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|---|---|---|
| Downstream ASIC compliance dashboards | — | ASIC monitoring views and reports consume this table directly |
| (Other SP dependencies — repo search recommended) | RealCID / Date | Other BI_DB SPs may JOIN or aggregate this table |

---

## 7. Sample Queries

### 7.1 Customers flagged by multiple alerts on a given date

```sql
SELECT
    Date,
    RealCID,
    Country,
    Club,
    AccountManager,
    A1_ConcentrationRisk_Ind + A2_LossInvestmentRatio_Ind
        + A4_Last_BSL_Date_Ind + A5_NegativeBalance_Ind
        + A6_HighLeverageTrading_Ind AS TotalAlerts,
    A1_FinalAvgEquity,
    A2_LossInvestmentRatio_CountPos,
    TotalManualCFD_NetProfit
FROM BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD
WHERE Date = '2023-11-04'
  AND (A1_ConcentrationRisk_Ind + A2_LossInvestmentRatio_Ind
       + A4_Last_BSL_Date_Ind + A5_NegativeBalance_Ind
       + A6_HighLeverageTrading_Ind) >= 2
ORDER BY TotalAlerts DESC, TotalManualCFD_NetProfit;
```

### 7.2 ASIC alert summary by country

```sql
SELECT
    Country,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(A1_ConcentrationRisk_Ind AS INT)) AS A1_Count,
    SUM(CAST(A2_LossInvestmentRatio_Ind AS INT)) AS A2_Count,
    SUM(CAST(A4_Last_BSL_Date_Ind AS INT)) AS A4_Count,
    SUM(CAST(A5_NegativeBalance_Ind AS INT)) AS A5_Count,
    SUM(CAST(A6_HighLeverageTrading_Ind AS INT)) AS A6_Count
FROM BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD
WHERE Date = '2023-11-04'
GROUP BY Country
ORDER BY TotalCustomers DESC;
```

### 7.3 Trend alert flags over time for a specific customer

```sql
SELECT
    Date,
    A1_ConcentrationRisk_Ind,
    A1_FinalAvgEquity,
    A2_LossInvestmentRatio_Ind,
    A2_LossInvestmentRatio_CountPos,
    A4_Last_BSL_Date_Ind,
    A4_Last_BSL_Date_MaxDate,
    A5_NegativeBalance_Ind,
    A6_HighLeverageTrading_Ind,
    TotalManualCFD_NetProfit
FROM BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD
WHERE RealCID = 12345678
ORDER BY Date;
```

---

## 8. Atlassian Knowledge Sources

Atlassian MCP not available this session. Phase 10 skipped.

---

*Generated: 2026-04-28 | Phases: 11/14 (no Atlassian)*
*Tiers: 4 T1, 14 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 18/18*
*Object: BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD | Type: Table | Production Source: Fact_SnapshotCustomer + BI_DB_PositionPnL + Dim_Position + Fact_CustomerAction*
