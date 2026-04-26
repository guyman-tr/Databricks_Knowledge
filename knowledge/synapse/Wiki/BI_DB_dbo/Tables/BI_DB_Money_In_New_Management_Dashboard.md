# BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard

> 6.23M-row deposit transaction table for the management dashboard, containing every deposit attempt (Approved, Declined, or Excluded) with customer geography, regulation, payment method, first-attempt indicators, eMoney eligibility, conversion fee revenue, and club tier — sourced from Fact_BillingDeposit enriched with 9 dimension tables. Rolling 7-month window. Refreshed daily via SP_Money_In_New_Management_Dashboard (Artyom Bogomolsky, 2022-03-27). SB_Daily, Priority 0.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingDeposit + 9 dimension tables via SP_Money_In_New_Management_Dashboard |
| **Refresh** | Daily DELETE+INSERT by DepositID+CID, plus DELETE older than 7 months. SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~6.23M |
| **Date Range** | PaymentDate 2025-10-01 to 2026-04-12 (rolling 7-month window) |
| **Author** | Artyom Bogomolsky (2022-03-27), Adi Meidan (2022-07/2022-11) |

---

## 1. Business Meaning

This table provides the **Money In (deposits) view for the management dashboard**. Each row represents a single deposit transaction (one DepositID per row), enriched with customer attributes at the time of the deposit (country, regulation, club tier) and operational metrics (first attempt indicator, 24-hour approval rate, eMoney eligibility, conversion fee revenue).

The SP runs daily and processes deposits from the previous day (PaymentDate or ModificationDate within the last 24 hours). It uses a **DELETE+INSERT merge** on DepositID+CID (existing rows for the same deposit are deleted before re-inserting), then purges data older than 7 months.

Key business dimensions:
- **DepositStatus**: Approved (86%), Declined (11%), Exclude (3%). "Exclude" covers specific PaymentStatusID + FundingTypeID combinations (e.g., PaymentStatusID=6 with FundingTypeID 35/37).
- **DepositMethod**: eToroMoney (56%), CreditCard (34%), PayPal (5%), WireTransfer (2.5%).
- **DepositFundingType**: Automatic (98%) vs Manual (2% — wire transfers only).
- **eMoneyEligible**: 1 if the customer meets all eligibility criteria (>14 days since first deposit, verified L3, active status, country rolled out for eMoney).

---

## 2. Business Logic

### 2.1 Deposit Status Classification

**What**: Categorizes each deposit into Approved, Declined, or Exclude.
**Columns Involved**: DepositStatus, PaymentStatusID, FundingTypeID
**Rules**:
- PaymentStatusID = 2 → Approved
- PaymentStatusID IN (1, 5, 11, 12) → Exclude
- PaymentStatusID = 6 AND FundingTypeID IN (35, 37) → Exclude
- PaymentStatusID = 13 AND FundingTypeID IN (1, 34, 11, 28) → Exclude
- All other combinations → Declined

### 2.2 First Attempt Indicator

**What**: Identifies if this is the customer's very first deposit attempt.
**Columns Involved**: FirstAttempt_Ind, FA_Approve_Rate
**Rules**:
- Find MIN(PaymentDate) per CID from Fact_BillingDeposit — if it falls within the last 2 days, mark that deposit as FirstAttempt_Ind=1
- FA_Approve_Rate=1 if first attempt AND first approval (PaymentStatusID=2) occurred within 24 hours of the attempt

### 2.3 eMoney Eligibility

**What**: Determines if the customer is eligible for eMoney services at the time of deposit.
**Columns Involved**: eMoneyEligible
**Rules**:
- DATEDIFF(dd, FirstDepositDate, PaymentDate) > 14 (more than 14 days since first deposit)
- IsDepositor = 1 (from Fact_SnapshotCustomer)
- VerificationLevelID = 3 (fully verified)
- PlayerStatusID NOT IN (2, 4, 14, 15) (active, not blocked/suspended)
- CountryID exists in eMoney_Dim_Country_Rollout AND PaymentDate >= RolloutDate

### 2.4 Conversion Fee Revenue

**What**: Calculates the FX conversion fee earned on the deposit.
**Columns Involved**: ConversionFeeRevenue
**Rules**:
- (BaseExchangeRate - ExchangeRate) * Amount
- Positive when the customer's exchange rate is worse than the base rate (eToro earns the spread)

### 2.5 Rolling Window Cleanup

**What**: Maintains a 7-month rolling window by deleting old data.
**Columns Involved**: PaymentDate
**Rules**:
- DELETE WHERE PaymentDate < DATEADD(MONTH, -7, DATEADD(DAY, 1, EOMONTH(@Date)))
- This keeps approximately 7 full calendar months of data

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** + **HEAP**: No clustered index. Full table scans on every query.
- For frequent date-filtered queries, consider adding a clustered index on DepositDate or PaymentDate.
- DepositID is unique per row but NOT enforced as a constraint.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily deposit volume | `WHERE DepositDate = @date AND DepositStatus = 'Approved' GROUP BY DepositDate` |
| FTD (first-time depositor) rate | `WHERE IsFTD = 1 AND DepositStatus = 'Approved'` |
| Approval rate by method | `GROUP BY DepositMethod, DepositStatus` |
| Revenue from FX conversion | `SUM(ConversionFeeRevenue) WHERE DepositStatus = 'Approved'` |
| eMoney-eligible deposits | `WHERE eMoneyEligible = 1 AND DepositStatus = 'Approved'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer attributes |
| BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard | CID | Pair deposits with withdrawals |
| DWH_dbo.Dim_Country | CountryID | Extended country attributes |

### 3.4 Gotchas

- **7-month rolling window**: Data older than 7 months is deleted daily. For historical analysis, use Fact_BillingDeposit directly.
- **"Exclude" is not "Declined"**: Exclude means the deposit is filtered out for dashboard metrics (specific status+method combos). It is not a failed deposit.
- **PaymentDate vs DepositDate**: PaymentDate is datetime (includes time), DepositDate is date-only (CAST). For WireTransfer (FundingTypeID=2), PaymentDate may be replaced with ProcessorValueDate if ProcessorValueDate > PaymentDate.
- **FirstAttempt_Ind is per-CID lifetime**: It identifies the customer's FIRST EVER deposit attempt, not the first attempt in the window.
- **Customer attributes are snapshot-based**: Country, Regulation, Club are from Fact_SnapshotCustomer at the time of the deposit (via DateRangeID), not the customer's current attributes.
- **Duplicate deposits possible**: The DELETE+INSERT logic matches on DepositID+CID, so modified deposits are refreshed but the same deposit appears only once.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | Standard ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | int | NO | Unique deposit transaction identifier from Fact_BillingDeposit. One row per deposit. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 2 | AmountUSD | decimal(11,2) | YES | Deposit amount in USD. From Fact_BillingDeposit.AmountUSD. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 3 | Country | varchar(100) | YES | Customer's country name at the time of deposit. From Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 4 | Region | varchar(100) | YES | Marketing region name. From Dim_Country.MarketingRegionManualName. E.g., UK, German, French, Italian, CEE, Latam, Spain. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 5 | Regulation | varchar(100) | YES | Regulatory jurisdiction. From Dim_Regulation.Name via Dim_Country.RegulationID. E.g., FCA, CySEC, FSA Seychelles. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 6 | CID | int | NO | Customer ID. From Fact_BillingDeposit.CID. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 7 | PaymentDate | datetime | YES | Payment date and time of the deposit. For WireTransfer, may be replaced with ProcessorValueDate if later. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 8 | DepositDate | date | YES | Date-only portion of PaymentDate. CAST(PaymentDate AS Date). (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 9 | ModificationDate | datetime | YES | Last modification date of the deposit record. From Fact_BillingDeposit. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 10 | PaymentStatusID | int | YES | Payment status code from Fact_BillingDeposit. 2=Approved, 1/5/11/12=Excluded statuses, 6/13=conditional exclude based on FundingTypeID. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 11 | IsFTD | int | YES | First-time deposit flag. 1=this is the customer's first-ever approved deposit. From Fact_BillingDeposit.IsFTD. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 12 | DepositStatus | varchar(100) | YES | Derived deposit status classification. Approved, Declined, or Exclude. See Business Logic 2.1 for CASE rules. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 13 | DepositMethod | varchar(100) | YES | Payment method name. From Dim_FundingType.Name. Top values: eToroMoney, CreditCard, PayPal, WireTransfer, GCCInstantBankTransfer, iDEAL, PWMB. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 14 | PaymentStatus | varchar(100) | YES | Payment status label. From Dim_PaymentStatus.Name. E.g., Approved, InProcess, Declined. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 15 | DepositFundingType | varchar(100) | YES | Funding type classification. Manual (FundingTypeID=2, wire transfers), Error (FundingTypeID=0), Automatic (all others). 2 values in practice: Automatic, Manual. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 16 | FirstAttempt_Ind | int | YES | 1 if this deposit is the customer's very first deposit attempt (MIN PaymentDate per CID in last 2 days), 0 otherwise. Lifetime per-CID, not per-window. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 17 | FA_Approve_Rate | int | YES | 1 if first attempt AND first approval (PaymentStatusID=2) occurred within 24 hours. 0 otherwise. Measures first-attempt-to-approval speed. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 18 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_Money_In_New_Management_Dashboard) |
| 19 | ProcessorValueDate | datetime | YES | Date the payment processor recorded the value. From Fact_BillingDeposit.ProcessorValueDate. For WireTransfer, used as PaymentDate if later than original PaymentDate. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 20 | Currency | varchar(20) | YES | Deposit currency abbreviation. From Dim_Currency.Abbreviation. E.g., USD, EUR, GBP, MXN. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 21 | CountryID | int | YES | Country identifier from Fact_SnapshotCustomer.CountryID. FK to Dim_Country. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 22 | Club | varchar(50) | YES | eToro Club tier at the time of deposit. From Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID. E.g., Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 23 | DepositDateID | int | YES | Date key (YYYYMMDD int) for DepositDate. Computed from PaymentDate. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 24 | ModificationDateID | int | YES | Date key (YYYYMMDD int) for ModificationDate. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 25 | ConversionFeeRevenue | money | YES | FX conversion fee revenue. (BaseExchangeRate - ExchangeRate) * Amount. Positive when eToro earns a spread on the FX conversion. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 26 | eMoneyEligible | int | YES | 1 if customer meets all eMoney eligibility criteria at deposit time (>14d since FTD, verified L3, active status, country in eMoney rollout). 0 otherwise. (Tier 2 — SP_Money_In_New_Management_Dashboard) |
| 27 | DepositProvider | varchar(100) | YES | Deposit processing provider name. From Dim_BillingDepot.Name. E.g., Tribe, IXOPAY-Nuvei, WorldPay, Wire(DeutscheBank). (Tier 2 — SP_Money_In_New_Management_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| DepositID, AmountUSD, CID, PaymentDate, ModificationDate, PaymentStatusID, IsFTD, ProcessorValueDate | DWH_dbo.Fact_BillingDeposit | Direct columns | Direct passthrough |
| Country, Region, CountryID | DWH_dbo.Dim_Country via Fact_SnapshotCustomer | Name, MarketingRegionManualName | Snapshot-based lookup |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Country.RegulationID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Via Fact_SnapshotCustomer.PlayerLevelID |
| DepositMethod | DWH_dbo.Dim_FundingType | Name | Via FundingTypeID |
| DepositProvider | DWH_dbo.Dim_BillingDepot | Name | Via DepotID |
| Currency | DWH_dbo.Dim_Currency | Abbreviation | Via CurrencyID |
| PaymentStatus | DWH_dbo.Dim_PaymentStatus | Name | Via PaymentStatusID |
| DepositStatus, DepositFundingType, ConversionFeeRevenue, eMoneyEligible, FirstAttempt_Ind, FA_Approve_Rate | Computed | Multiple sources | CASE logic / aggregation |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingDeposit (deposit transactions)
  + Dim_Country, Dim_Regulation, Dim_Currency, Dim_FundingType,
    Dim_PaymentStatus, Dim_PlayerLevel, Dim_BillingDepot, Dim_Customer,
    Fact_SnapshotCustomer, eMoney_Dim_Country_Rollout
  |-- SP_Money_In_New_Management_Dashboard @Date ---|
  |   (DELETE matching DepositID+CID, INSERT, DELETE >7 months)
  v
BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard (6.23M rows, 7-month window)
  |-- Management Dashboard (Money In view) ---|
  v
Management Dashboard
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DepositID | DWH_dbo.Fact_BillingDeposit.DepositID | Source deposit transaction |
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |
| CountryID | DWH_dbo.Dim_Country.CountryID | Country dimension |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus.PaymentStatusID | Status dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard | Companion table — Money Out (withdrawals) for the same dashboard |

---

## 7. Sample Queries

### 7.1 Daily Approved Deposit Volume and Amount

```sql
SELECT DepositDate,
       COUNT(*) AS deposit_count,
       SUM(AmountUSD) AS total_usd,
       SUM(CASE WHEN IsFTD = 1 THEN 1 ELSE 0 END) AS ftd_count,
       SUM(CASE WHEN IsFTD = 1 THEN AmountUSD ELSE 0 END) AS ftd_amount
FROM [BI_DB_dbo].[BI_DB_Money_In_New_Management_Dashboard]
WHERE DepositStatus = 'Approved'
  AND DepositDate >= '2026-04-01'
GROUP BY DepositDate
ORDER BY DepositDate DESC
```

### 7.2 Deposit Method Breakdown by Regulation

```sql
SELECT Regulation, DepositMethod,
       COUNT(*) AS cnt,
       SUM(AmountUSD) AS total_usd
FROM [BI_DB_dbo].[BI_DB_Money_In_New_Management_Dashboard]
WHERE DepositStatus = 'Approved'
  AND DepositDate >= '2026-04-01'
GROUP BY Regulation, DepositMethod
ORDER BY Regulation, total_usd DESC
```

### 7.3 First Attempt 24-Hour Approval Rate

```sql
SELECT DepositDate,
       COUNT(*) AS first_attempts,
       SUM(FA_Approve_Rate) AS approved_within_24h,
       SUM(FA_Approve_Rate) * 100.0 / NULLIF(COUNT(*), 0) AS approval_rate_pct
FROM [BI_DB_dbo].[BI_DB_Money_In_New_Management_Dashboard]
WHERE FirstAttempt_Ind = 1
  AND DepositDate >= '2026-04-01'
GROUP BY DepositDate
ORDER BY DepositDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 1 T5 | Elements: 27/27, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard | Type: Table | Production Source: Fact_BillingDeposit + 9 dimension tables*
