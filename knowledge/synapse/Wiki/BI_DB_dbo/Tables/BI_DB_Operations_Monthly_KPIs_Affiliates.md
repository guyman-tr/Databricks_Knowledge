# BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates

> 7,733-row rolling 6-month SLA compliance dataset for affiliate and PI payment withdrawals (Oct 2025 – Apr 2026, daily TRUNCATE+INSERT), tracking end-to-end processing speed (SLA/SLA48/SLA5days) per payment leg across 6 regulations and 20 regions — sourced from Fact_BillingWithdraw filtered to CashoutReasonID IN (14=PI Payment, 15=Affiliate Payment).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw (CashoutReasonID IN 14,15) + Dim_Customer + Dim_Country + Dim_Regulation |
| **Refresh** | Daily — SP_OperationsMonthlyAffiliateKPIsFullData; TRUNCATE+INSERT; 6-month rolling window (@StartDate = 6 months before GETDATE()) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

Rolling 6-month withdrawal SLA dataset restricted to affiliate-channel and Popular Investor (PI) payment withdrawals. Each row represents one payment leg of an approved affiliate-type withdrawal, with three SLA compliance flags (SLA/SLA48/SLA5days) measuring whether the bank or processor delivered the payout within threshold. The table is used by the Operations team to track partner payment processing performance across funding methods, regions, and regulations.

The SP filters strictly to partner payment types: CashoutReasonID=14 (PI Payment) and CashoutReasonID=15 (Affiliate Payment), approved withdrawals only (CashoutStatusID_Withdraw=3 AND CashoutStatusID_Funding=3), verified customers (VerificationLevelID=3), non-Popular-Investor (PlayerLevelID≠4), non-US (CountryID≠250), and excludes bonus-only labels (LabelID NOT IN 26,30). The 6-month window means data older than ~6 months is not retained.

As of 2026-04-13: 7,733 rows covering 1,539 distinct customers. The dominant payment methods are eToroMoney (52.4%, FundingTypeID=33) and WireTransfer (43.0%, FundingTypeID=2). CySEC (49.6%), BVI (23.2%), and FCA (22.4%) account for 95.2% of the volume. SLA compliance is near-perfect: 99.97% of rows meet all three SLA thresholds.

**CRITICAL: `ModificationDate` in this table maps to `ModificationDate_WithdrawToFunding` (the payment leg's bank clearing date), NOT to `Billing.Withdraw.ModificationDate`. These are different columns with different semantics.**

---

## 2. Business Logic

### 2.1 Affiliate/PI Population Filter

**What**: Table is restricted to partner-payment withdrawals only.
**Columns Involved**: CashoutReasonID, CashoutStatusID, VerificationLevelID
**Rules**:
- `CashoutReasonID IN (14, 15)` — only PI Payment and Affiliate Payment reason codes
- `CashoutStatusID_Withdraw = 3 AND CashoutStatusID_Funding = 3` — both the request level and payment leg must be Processed (approved)
- `VerificationLevelID = 3` — fully verified customers only
- `PlayerLevelID ≠ 4` — excludes Popular Investors as customers (not relevant since PI=14 is the PI payment type)
- `CountryID NOT IN (250)` — excludes USA
- `LabelID NOT IN (26, 30)` — excludes bonus-only and specific internal labels

All three constant-value columns (`CashoutStatusID`, `VerificationLevelID`, `CashoutReasonID`) are always 14 or 15 / always 3 / always 3 in all rows — filter values rather than analytics dimensions.

### 2.2 Three-Tier SLA Classification

**What**: Three binary SLA flags using different threshold levels per funding method and currency.
**Columns Involved**: SLA, SLA48, SLA5days, WD_ID_SLA, WD_ID_SLA48, WD_ID_SLA5days
**Rules**:
- SLA thresholds vary by: `FundingTypeID`, `CurrencyID`, `Regulation` (RegulationID numeric), `DATEPART(dw, RequestDate)` (day of week)
- ACH/PWMB (FundingTypeID 29/32): 5–8 calendar-day thresholds (most generous) — measured RequestDate → ProcessorValueDate
- Non-wire, non-ACH methods: 1–3 calendar-day thresholds — measured RequestDate → ProcessorValueDate
- WireTransfer (FundingTypeID=2, default): 1–5 calendar-day thresholds — measured RequestDate → ProcessorValueDate
- GBP wire (CurrencyID=3, FundingTypeID=2): stricter 2–4 day thresholds
- AUD wire non-ASIC (CurrencyID=5, Regulation≠ASIC RegID, FundingTypeID=2): 4–7 day thresholds measured differently (ProcessorValueDate → ModificationDate)
- SLA48 uses stricter thresholds than SLA; SLA5days uses the most permissive (always 1 in current data)
- `WD_ID_SLA` = MIN(SLA) across all legs of a WithdrawID: 'OverallSLA' if all legs pass, 'OverallNotSLA' if any fail
- SP contains both pre- and post-2021-01-01 CASE blocks; the pre-2021 block is inert with the 6-month rolling window

### 2.3 Duplicate Timestamp Columns

**What**: ReqCyTime and ModCyTime carry the same values as RequestDate and ModificationDate respectively.
**Columns Involved**: RequestDate, ReqCyTime, ModificationDate, ModCyTime
**Rules**:
- `ReqCyTime` = `bw.RequestDate AS ReqCyTime` — identical value to RequestDate
- `ModCyTime` = `bw.ModificationDate_WithdrawToFunding AS ModCyTime` — identical value to ModificationDate
- Names suggest Cyprus-timezone monitoring intent, but no timezone conversion is applied in the SP — values are UTC-equivalent production timestamps
- In queries, use RequestDate and ModificationDate; ReqCyTime/ModCyTime add no additional information

### 2.4 Processing Date Decomposition

**What**: ProcessorValueDate is broken into day-of-week, month, and year components.
**Columns Involved**: ProcessMonth, ProcessYear, ProcessDay, HoursBetween
**Rules**:
- `ProcessMonth` = DATEPART(month, ProcessorValueDate)
- `ProcessYear` = DATEPART(year, ProcessorValueDate)
- `ProcessDay` = DATEPART(dw, ProcessorValueDate) — stored as int; 1=Sunday…7=Saturday
- `HoursBetween` = DATEDIFF(hour, RequestDate, ProcessorValueDate) — end-to-end hours; range 1–128 (avg 9.9 hours)
- `RequestDay` = DATEPART(dw, RequestDate) — stored as datetime (DDL is `[datetime] NULL`); DATEPART int result is implicitly cast to datetime via 1900-01-0N base. Cast to int before arithmetic.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no skew risk, but all multi-table JOINs require data movement. HEAP index — full scans only. With 7,733 rows the table is small enough that scan overhead is negligible. Use `WHERE RequestDate >= DATEADD(month,-6,GETDATE())` defensively but data is pre-filtered.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| SLA rate by regulation (current window) | `SELECT Regulation, COUNT(*) AS Total, SUM(SLA) AS Pass, CAST(SUM(SLA)*100.0/COUNT(*) AS DECIMAL(5,2)) AS SLAPct FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates] GROUP BY Regulation ORDER BY Total DESC` |
| Month-over-month SLA trend | `GROUP BY Year, Month ORDER BY Year, Month` |
| Wire transfer SLA breakdown | `WHERE FundingTypeID = 2 GROUP BY Regulation, Region` |
| PI vs Affiliate payment volume | `SELECT CashoutReasonID, COUNT(*) AS Rows, SUM(Amount) AS TotalAmount FROM ... GROUP BY CashoutReasonID` |
| Per-withdrawal overall SLA | Use `WD_ID_SLA` grouped by `WithdrawID` — these are pre-aggregated across legs |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_FundingType | FundingTypeID = FundingTypeID | Decode payment method name |
| DWH_dbo.Dim_CashoutReason | CashoutReasonID = CashoutReasonID | Decode withdrawal reason label |
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile attributes |
| DWH_dbo.Fact_BillingWithdraw | WithdrawID = WithdrawID | Drill to full withdrawal detail |

### 3.4 Gotchas

- **ModificationDate ≠ Withdraw.ModificationDate**: This column maps to `ModificationDate_WithdrawToFunding` (the payment leg's bank clearing date). Do NOT use it as the withdrawal modification timestamp.
- **ReqCyTime = RequestDate and ModCyTime = ModificationDate**: Both pairs carry identical values. Do not include both in the same query expecting independent signals.
- **RequestDay is datetime, not int**: DDL type is `datetime`. `DATEPART(dw, RequestDate)` was stored implicitly (1900-01-01=Sunday, 1900-01-02=Monday…). Use `CAST(RequestDay AS int)` or `DATEPART(dw, RequestDay)` to get the numeric day.
- **ProcessDay is int, not datetime**: Opposite of RequestDay — stored correctly as int (1–7).
- **6-month rolling window**: Data before ~6 months before UpdateDate is not retained. Never query for historical withdrawals older than the window.
- **CashoutStatusID, VerificationLevelID are constants**: Always 3 — do not use as filters or dimensions, they carry no analytical value.
- **WD_ID_SLA\* are leg-level duplicates**: Each row is a payment leg. WD_ID_SLA is the rollup for the whole WithdrawID. If a WithdrawID appears multiple times (multiple legs), WD_ID_SLA is repeated identically per leg.
- **FundingID is NULL for eToroMoney**: Most eToroMoney (FundingTypeID=33) withdrawals show NULL FundingID. JOINs on FundingID will miss 52%+ of rows.
- **Pre-2021 SLA CASE block is inert**: SP has duplicate CASE logic for pre-2021-01-01 thresholds. Since the rolling window covers only the past 6 months, this branch never fires. Reported SLA=0 rows (2 total) are post-2021 threshold breaches, not pre-2021 cases.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production or DWH wiki |
| Tier 2 | Description derived from SP code analysis |
| Tier 3 | Description inferred from context and data patterns |
| Tier 4 | Description is best-available estimate; low confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | bigint | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column in source Fact_BillingWithdraw. (Tier 1 — Fact_BillingWithdraw wiki) |
| 2 | CurrencyID | int | YES | Currency of the withdrawal amount. FK to Dictionary.Currency. (Tier 1 — Fact_BillingWithdraw wiki) |
| 3 | FundingTypeID | int | YES | Payment method type of the withdrawal request (FundingTypeID_Withdraw from Fact_BillingWithdraw). In this table: eToroMoney=33 (52.4%), WireTransfer=2 (43.0%), MoneyBookers=8 (2.2%), CreditCard=1 (1.6%), Neteller=6 (0.7%), Trustly=35 (1 row). FK to Dim_FundingType. (Tier 1 — Fact_BillingWithdraw wiki) |
| 4 | CID | int | YES | Customer identifier. FK to Dim_Customer. (Tier 1 — Fact_BillingWithdraw wiki) |
| 5 | CashoutStatusID | int | YES | Withdrawal request-level status. Always 3 (Processed) in this table — SP requires CashoutStatusID_Withdraw=3 AND CashoutStatusID_Funding=3. FK to Dim_CashoutStatus. (Tier 1 — Fact_BillingWithdraw wiki) |
| 6 | RequestDate | datetime | YES | Date and time the withdrawal was requested by the customer. Rolling 6-month window: 2025-10-02 to 2026-04-07 in live data. (Tier 1 — Fact_BillingWithdraw wiki) |
| 7 | Amount | money | YES | Gross withdrawal amount in CurrencyID currency. Maps to Amount_Withdraw in Fact_BillingWithdraw. Range: $21–$115,395 (avg $1,980). (Tier 1 — Fact_BillingWithdraw wiki) |
| 8 | ModificationDate | datetime | YES | Payment leg processing completion date. Maps to ModificationDate_WithdrawToFunding in Fact_BillingWithdraw — NOT Billing.Withdraw.ModificationDate. Represents when the bank/processor marked the payout leg complete. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 9 | FundingID | bigint | YES | FK to Billing.Funding instrument. NULL for withdrawals not linked to a saved payment instrument (common for eToroMoney withdrawals). (Tier 1 — Fact_BillingWithdraw wiki) |
| 10 | CashoutReasonID | int | YES | Withdrawal reason classifier. In this table: 14=PI Payment (75.9%), 15=Affiliate Payment (24.1%) — SP filters CashoutReasonID IN (14,15). FK to Dim_CashoutReason. (Tier 1 — Dim_CashoutReason wiki) |
| 11 | ReqCyTime | datetime | YES | Duplicate of RequestDate. SP assigns `bw.RequestDate AS ReqCyTime`. Name suggests Cyprus-timezone monitoring intent but no timezone conversion is applied — value is identical to RequestDate. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 12 | ModCyTime | datetime | YES | Duplicate of ModificationDate. SP assigns `bw.ModificationDate_WithdrawToFunding AS ModCyTime`. Value is identical to ModificationDate column; name suggests Cyprus-timezone monitoring. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 13 | VerificationLevelID | int | YES | Customer KYC verification level. Always 3 (fully verified) in this table per SP filter VerificationLevelID=3. FK to Dictionary.VerificationLevel. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 14 | RequestDay | datetime | YES | Day of week of the withdrawal request. Derived as DATEPART(dw, RequestDate) but stored as datetime via implicit cast (1900-01-01=Sunday…1900-01-07=Saturday). Used in SLA threshold CASE expressions. Cast to int before arithmetic. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 15 | Month | int | YES | Calendar month of the withdrawal request. DATEPART(month, RequestDate). Range 1–12. Current data: months 10–12 (2025) and 1–4 (2026). (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 16 | Year | int | YES | Calendar year of the withdrawal request. DATEPART(year, RequestDate). Current data: 2025 and 2026. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 17 | Region | varchar(30) | YES | Geographic market region from Dim_Country. 20 distinct values: Eastern Europe (15.3%), UK (14.0%), Italian (12.3%), German (10.4%), Spain (10.0%), North Europe (8.1%), French (7.1%), Other Asia (3.9%), South & Central America (3.9%), Australia (3.4%), Arabic GCC (3.2%), ROE (3.0%), China (2.7%), Others. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData via Dim_Country) |
| 18 | Regulation | varchar(30) | YES | Regulatory entity short code. Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. 6 values: CySEC (49.6%), BVI (23.2%), FCA (22.4%), ASIC & GAML (2.7%), FSRA (1.1%), eToroUS (1.0%). (Tier 1 — Dictionary.Regulation via Dim_Regulation) |
| 19 | ProcessMonth | int | YES | Calendar month of the processor value date. DATEPART(month, ProcessorValueDate). Allows grouping by when funds were cleared, not when requested. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 20 | ProcessYear | int | YES | Calendar year of the processor value date. DATEPART(year, ProcessorValueDate). (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 21 | ProcessDay | int | YES | Day of week of the processor value date. DATEPART(dw, ProcessorValueDate) stored as int (1=Sunday…7=Saturday). Used in SLA CASE expressions. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 22 | HoursBetween | int | YES | End-to-end processing hours from request submission to bank clearing. DATEDIFF(hour, RequestDate, ProcessorValueDate). Range: 1–128 hours (avg 9.9 hours). Key SLA input metric. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 23 | SLA | int | YES | SLA compliance flag per payment leg: 1=within SLA threshold, 0=breach. Thresholds vary by FundingTypeID, CurrencyID, Regulation, and day of week. 7,731 rows=1 (99.97%), 2 rows=0. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 24 | SLA48 | int | YES | 48-hour SLA compliance flag per payment leg: 1=within threshold, 0=breach. Stricter thresholds than SLA. Same inputs. 7,731 rows=1 (99.97%), 2 rows=0. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 25 | SLA5days | int | YES | 5-business-day SLA compliance flag per payment leg: 1=within threshold, 0=breach. Most permissive threshold. Always 1 in current data (7,733 rows). (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 26 | WD_ID_SLA | varchar(50) | YES | Overall SLA outcome for the entire withdrawal (across all payment legs). MIN(SLA) per WithdrawID: 'OverallSLA' (7,731 rows, 99.97%) or 'OverallNotSLA' (2 rows). (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 27 | WD_ID_SLA48 | varchar(50) | YES | Overall 48-hour SLA outcome per withdrawal. MIN(SLA48) per WithdrawID: 'OverallSLA48' (7,731) or 'OverallNotSLA48' (2). (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 28 | WD_ID_SLA5days | varchar(50) | YES | Overall 5-day SLA outcome per withdrawal. MIN(SLA5days) per WithdrawID: always 'OverallSLA5days' in current data. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |
| 29 | UpdateDate | datetime | YES | GETDATE() at time of ETL run. Single timestamp per load. Current: 2026-04-13 04:13:56. (Tier 2 — SP_OperationsMonthlyAffiliateKPIsFullData) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Direct |
| CurrencyID | DWH_dbo.Fact_BillingWithdraw | CurrencyID | Direct |
| FundingTypeID | DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Withdraw | Withdrawal request method |
| CID | DWH_dbo.Fact_BillingWithdraw | CID | Direct |
| CashoutStatusID | DWH_dbo.Fact_BillingWithdraw | CashoutStatusID_Withdraw | Always 3 (Processed) |
| RequestDate | DWH_dbo.Fact_BillingWithdraw | RequestDate | Direct |
| Amount | DWH_dbo.Fact_BillingWithdraw | Amount_Withdraw | Gross withdrawal amount |
| ModificationDate | DWH_dbo.Fact_BillingWithdraw | ModificationDate_WithdrawToFunding | Payment leg completion date |
| FundingID | DWH_dbo.Fact_BillingWithdraw | FundingID | Direct |
| CashoutReasonID | DWH_dbo.Fact_BillingWithdraw | CashoutReasonID | Direct (14 or 15 only) |
| ReqCyTime | DWH_dbo.Fact_BillingWithdraw | RequestDate | Duplicate alias |
| ModCyTime | DWH_dbo.Fact_BillingWithdraw | ModificationDate_WithdrawToFunding | Duplicate alias |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Always 3 |
| RequestDay | DWH_dbo.Fact_BillingWithdraw | RequestDate | DATEPART(dw,…) → datetime |
| Month | DWH_dbo.Fact_BillingWithdraw | RequestDate | DATEPART(month,…) |
| Year | DWH_dbo.Fact_BillingWithdraw | RequestDate | DATEPART(year,…) |
| Region | DWH_dbo.Dim_Country | Region | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough short code |
| ProcessMonth | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | DATEPART(month,…) |
| ProcessYear | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | DATEPART(year,…) |
| ProcessDay | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | DATEPART(dw,…) → int |
| HoursBetween | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate | DATEDIFF(hour,…) |
| SLA | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate, FundingTypeID, CurrencyID | Complex CASE |
| SLA48 | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate, FundingTypeID, CurrencyID | Complex CASE (48h variant) |
| SLA5days | DWH_dbo.Fact_BillingWithdraw | RequestDate, ProcessorValueDate, FundingTypeID, CurrencyID | Complex CASE (5d variant) |
| WD_ID_SLA | SP-computed | SLA per leg | MIN across WithdrawID legs |
| WD_ID_SLA48 | SP-computed | SLA48 per leg | MIN across WithdrawID legs |
| WD_ID_SLA5days | SP-computed | SLA5days per leg | MIN across WithdrawID legs |
| UpdateDate | SP-computed | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (CashoutReasonID IN 14,15 — affiliate/PI payments)
DWH_dbo.Dim_Customer (VerificationLevelID=3, PlayerLevelID≠4, LabelID NOT IN 26,30, CountryID≠250)
DWH_dbo.Dim_Country (Region)
DWH_dbo.Dim_Regulation (Regulation name)
  |-- SP_OperationsMonthlyAffiliateKPIsFullData (daily, no parameters) ---|
  |   @StartDate = DATEADD(month,-6,GETDATE())                            |
  |   TRUNCATE + INSERT (6-month rolling window retained)                  |
  v
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates (7,733 rows, daily refresh)
  |-- UC: Not Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Primary key — source withdrawal event |
| CID | DWH_dbo.Dim_Customer | Customer profile |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method dimension |
| CashoutStatusID | DWH_dbo.Dim_CashoutStatus | Withdrawal status dimension |
| CashoutReasonID | DWH_dbo.Dim_CashoutReason | Withdrawal reason dimension |
| Regulation | DWH_dbo.Dim_Regulation | Regulation short code passthrough |
| Region | DWH_dbo.Dim_Country | Geographic region passthrough |

### 6.2 Referenced By

No downstream consumers found in SSDT repo. This is an Operations reporting leaf table.

---

## 7. Sample Queries

### SLA Rate by Regulation and Funding Method

```sql
SELECT
    Regulation,
    FundingTypeID,
    COUNT(*) AS TotalLegs,
    SUM(SLA) AS SLAPass,
    CAST(SUM(SLA) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SLAPct,
    AVG(CAST(HoursBetween AS FLOAT)) AS AvgHours
FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates]
GROUP BY Regulation, FundingTypeID
ORDER BY TotalLegs DESC;
```

### Month-over-Month SLA Trend

```sql
SELECT
    Year,
    Month,
    COUNT(*) AS TotalLegs,
    SUM(SLA) AS SLAPass,
    SUM(SLA48) AS SLA48Pass,
    SUM(SLA5days) AS SLA5Pass,
    CAST(SUM(SLA) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SLAPct
FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates]
GROUP BY Year, Month
ORDER BY Year, Month;
```

### PI Payment vs Affiliate Payment Volume Comparison

```sql
SELECT
    CashoutReasonID,
    COUNT(DISTINCT WithdrawID) AS UniqueWithdrawals,
    COUNT(*) AS TotalLegs,
    SUM(Amount) AS TotalAmount,
    AVG(CAST(HoursBetween AS FLOAT)) AS AvgProcessingHours,
    CAST(SUM(SLA) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SLAPct
FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates]
GROUP BY CashoutReasonID;
```

### Wire Transfer SLA Breakdown by Region

```sql
SELECT
    Region,
    COUNT(*) AS WireLegs,
    CAST(SUM(SLA) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SLAPct,
    CAST(SUM(SLA48) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SLA48Pct,
    MIN(HoursBetween) AS MinHrs,
    MAX(HoursBetween) AS MaxHrs,
    AVG(CAST(HoursBetween AS FLOAT)) AS AvgHrs
FROM [BI_DB_dbo].[BI_DB_Operations_Monthly_KPIs_Affiliates]
WHERE FundingTypeID = 2
GROUP BY Region
ORDER BY WireLegs DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Operations SLA reporting context may exist under Operations or Finance spaces in Confluence (not queried).

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 10 T1, 19 T2, 0 T3, 0 T4, 0 T5 | Elements: 29/29, Logic: 9/10*
*Object: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates | Type: Table | Production Source: DWH_dbo.Fact_BillingWithdraw (CashoutReasonID IN 14,15)*
