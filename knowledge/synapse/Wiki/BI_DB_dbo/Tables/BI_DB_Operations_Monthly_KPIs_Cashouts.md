# BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts

> 13.4M-row approved-withdrawal SLA compliance dataset (Nov 2021 -- Apr 2026), tracking end-to-end cashout processing speed (SLA/SLA48/SLA5days) per payment leg with region and regulation segmentation -- sourced daily from Fact_BillingWithdraw via SP_Operations_Monthly_KPIs_FullData (DELETE+INSERT by ModificationDate).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.SP_Operations_Monthly_KPIs_FullData |
| **Refresh** | Daily DELETE+INSERT by ModificationDate |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CI(ModificationDateID, CID) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Operations_Monthly_KPIs_Cashouts` is the Operations team's primary withdrawal SLA monitoring table. Each row represents one approved withdrawal payment leg, carrying three SLA compliance flags (1-day, 2-day, 5-day) that measure whether the payout was processed within threshold based on funding method, currency, regulation, and day of week.

- **Row count**: 13,436,769 rows
- **Date range**: November 2021 -- April 2026 (by ModificationDate)
- **Writer SP**: `SP_Operations_Monthly_KPIs_FullData` (authored by Guy Manova 2018-04-02, maintained by Pavlina Masoura)
- **Load pattern**: Daily DELETE+INSERT keyed on ModificationDate (`DELETE WHERE CAST(ModificationDate AS DATE) = @Date`, then INSERT)
- **Population filter**: CashoutStatusID=3 (approved) AND both Withdraw and Funding status=3, IsValidCustomer=1

---

## 2. Business Logic

### 2.1 Approved Withdrawal Population Filter

**What**: Only fully approved withdrawals from valid customers are included.
**Columns Involved**: CashoutStatusID, IsValidCustomer
**Rules**:
- `CashoutStatusID_Withdraw = 3 AND CashoutStatusID_Funding = 3` -- both request and payment leg must be Processed
- `IsValidCustomer = 1` from Dim_Customer (excludes PlayerLevelID=4, LabelID IN 26/30, CountryID=250)
- All rows have CashoutStatusID=3 (constant due to filter)

### 2.2 FundingTypeID Resolution

**What**: Resolves the effective funding type from two possible sources.
**Columns Involved**: FundingTypeID
**Rules**:
- `CASE WHEN FundingTypeID_Funding IS NULL THEN FundingTypeID_Withdraw ELSE FundingTypeID_Funding END`
- Prefers the funding instrument's type over the withdrawal request's type

### 2.3 Three-Tier SLA Classification

**What**: Three binary SLA flags using different threshold levels per funding method, currency, regulation, and day of week.
**Columns Involved**: SLA, SLA48, SLA5days, WD_ID_SLA, WD_ID_SLA48, WD_ID_SLA5days, HoursBetween
**Rules**:
- **Date era split**: Different CASE blocks for before/after 2019-12-22
- **Pending vs approved**: Pending withdrawals use GETDATE() instead of ModificationDate for elapsed time
- **Wire (FundingTypeID=2)**: Base thresholds vary; GBP (CurrencyID=3) and AUD (CurrencyID=5) have specific rules; ASIC (RegulationID=4) has distinct AUD handling
- **ACH (29) / PWMB (32)**: Most generous thresholds (5--8 calendar days)
- **Other methods**: Standard 1--3 day thresholds
- **Day of week**: Weekend requests may have extended thresholds
- SLA = 1-day standard; SLA48 = 2-day extended; SLA5days = 5-day extended
- In 2026 data: 99.8% of rows have SLA=1 (compliant)

### 2.4 Overall SLA per WithdrawID

**What**: Aggregates SLA compliance across all payment legs of a single withdrawal.
**Columns Involved**: WD_ID_SLA, WD_ID_SLA48, WD_ID_SLA5days
**Rules**:
- `WD_ID_SLA` = MIN(SLA) across all funding legs per WithdrawID -- varchar flag 'OverallSLA' or 'OverallNotSLA'
- Same pattern for WD_ID_SLA48 and WD_ID_SLA5days
- If any single leg fails SLA, the entire withdrawal is flagged as non-compliant

### 2.5 Duplicate Timestamp Columns

**What**: ReqCyTime and ModCyTime duplicate RequestDate and ModificationDate.
**Columns Involved**: RequestDate, ReqCyTime, ModificationDate, ModCyTime
**Rules**:
- `ReqCyTime = RequestDate` (alias, no timezone conversion)
- `ModCyTime = ModificationDate` (alias, no timezone conversion)
- Names suggest Cyprus-timezone intent but no conversion is applied

### 2.6 Processing Date Decomposition

**What**: Calendar components extracted from dates for pivot/grouping.
**Columns Involved**: RequestDay, Month, Year, ProcessMonth, ProcessYear, ProcessDay
**Rules**:
- `RequestDay` = DATEPART(dw, RequestDate)
- `Month` = DATEPART(month, ModificationDate)
- `Year` = DATEPART(year, ModificationDate)
- `ProcessMonth/Year/Day` = DATEPART components from ProcessorValueDate or ModificationDate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with clustered index on (ModificationDateID, CID). However, ModificationDateID is NULL in all rows (not populated by the INSERT statement), so the CI is effectively useless for ModificationDateID filtering. Filter on ModificationDate (datetime) or CAST(ModificationDate AS DATE) instead.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily SLA compliance rate | `WHERE CAST(ModificationDate AS DATE) = @date GROUP BY SLA` |
| SLA by funding method | `GROUP BY FundingTypeID, SLA` |
| SLA by region/regulation | `GROUP BY Region, Regulation, SLA` |
| Overall withdrawal SLA | `SELECT DISTINCT WithdrawID, WD_ID_SLA WHERE ...` |
| Monthly trend | `GROUP BY Year, Month` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer attributes |
| DWH_dbo.Dim_FundingType | ON FundingTypeID | Payment method name |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_CashoutReason | ON CashoutReasonID | Withdrawal reason name |

### 3.4 Gotchas

- **ModificationDateID is always NULL**: The DDL defines the column and it is part of the CI, but the INSERT statement does not populate it. Do not filter on it.
- **CashoutStatusID is always 3**: Constant due to WHERE filter. Not a useful analytics dimension.
- **ReqCyTime/ModCyTime are redundant**: Identical to RequestDate/ModificationDate. Use the primary columns.
- **SLA logic is era-dependent**: Pre-2019-12-22 data uses different thresholds. Trend analysis across this boundary requires awareness.
- **FundingTypeID may differ from source**: The CASE resolution means FundingTypeID here is the effective type, not necessarily the one the customer requested.

---

## 4. Elements

### Confidence Tier Legend
| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (verbatim) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 3 | Inferred from data | Medium |
| Tier 4 | Best guess / Confluence | Lower |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | bigint | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. (Tier 1 — Fact_BillingWithdraw.WithdrawID) |
| 2 | CurrencyID | int | YES | Currency of the withdrawal amount. FK to Dictionary.Currency. (Tier 1 — Fact_BillingWithdraw.CurrencyID) |
| 3 | FundingTypeID | int | YES | Effective payment method type resolved via CASE: IF FundingTypeID_Funding IS NULL THEN FundingTypeID_Withdraw ELSE FundingTypeID_Funding. FK to Dim_FundingType. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 4 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. (Tier 1 — Fact_BillingWithdraw.CID) |
| 5 | ManagerID | int | YES | Operations manager who processed this withdrawal. 0=automated. (Tier 1 — Billing.Withdraw) |
| 6 | CashoutStatusID | int | YES | Withdrawal request-level status. Always 3 (Processed) in this table due to population filter. FK to Dim_CashoutStatus. (Tier 1 — Fact_BillingWithdraw.CashoutStatusID_Withdraw) |
| 7 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. (Tier 1 — Fact_BillingWithdraw.RequestDate) |
| 8 | Amount | money | YES | Gross withdrawal amount in CurrencyID denomination. (Tier 1 — Fact_BillingWithdraw.Amount_Withdraw) |
| 9 | Commission | money | YES | Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers. (Tier 1 — Fact_BillingWithdraw.Commission) |
| 10 | Approved | int | YES | Whether the withdrawal has received required approval. 1=Approved, 0=Pending approval. DEFAULT=0. DWH note: CAST from bit to int. (Tier 1 — Fact_BillingWithdraw.Approved) |
| 11 | IPAddress | bigint | YES | Customer IP address at withdrawal time, as integer. (Tier 3 — inferred from DDL type bigint; Fact_BillingWithdraw does not expose this column directly) |
| 12 | ModificationDate | datetime | YES | UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 — Fact_BillingWithdraw.ModificationDate) |
| 13 | Remark | nvarchar(max) | YES | Free-text remark field on the withdrawal. (Tier 3 — inferred from column name; not documented in Fact_BillingWithdraw wiki) |
| 14 | Comment | nvarchar(max) | YES | Operations comment on the withdrawal request. Free-text field populated by back-office staff. (Tier 1 — Fact_BillingWithdraw.Comment) |
| 15 | Fee | money | YES | Platform fee charged for this withdrawal. Subtracted from the gross Amount. (Tier 1 — Fact_BillingWithdraw.Fee) |
| 16 | FundingID | bigint | YES | FK to Billing.Funding -- the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. (Tier 1 — Fact_BillingWithdraw.FundingID) |
| 17 | RequestorComments | nvarchar(max) | YES | Comments provided by the requestor (customer or internal). (Tier 3 — inferred from column name; not documented in Fact_BillingWithdraw wiki) |
| 18 | SessionID | bigint | YES | Application session ID at time of withdrawal request. (Tier 1 — Fact_BillingWithdraw.SessionID, implicit via Billing.Withdraw) |
| 19 | CashoutReasonID | int | YES | Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. (Tier 1 — Fact_BillingWithdraw.CashoutReasonID) |
| 20 | SuggestedBonusDeductionAmount | money | YES | Suggested bonus deduction amount for the withdrawal. (Tier 3 — inferred from column name; from Billing.Withdraw, not in Fact_BillingWithdraw wiki) |
| 21 | ActualBonusDeductionAmount | money | YES | Actual bonus deduction applied to the withdrawal. (Tier 3 — inferred from column name; from Billing.Withdraw, not in Fact_BillingWithdraw wiki) |
| 22 | ClientWithdrawReasonID | int | YES | Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). FK to Dim_ClientWithdrawReason. (Tier 1 — Fact_BillingWithdraw.ClientWithdrawReasonID) |
| 23 | ClientWithdrawReasonComment | nvarchar(max) | YES | Free-text comment from the customer about their withdrawal reason. (Tier 3 — inferred from column name; from Billing.Withdraw, not in Fact_BillingWithdraw wiki) |
| 24 | ReqCyTime | datetime | YES | Alias of RequestDate. Name suggests Cyprus-timezone intent but no timezone conversion is applied. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 25 | ModCyTime | datetime | YES | Alias of ModificationDate. Name suggests Cyprus-timezone intent but no timezone conversion is applied. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 26 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. (Tier 1 — Dim_Customer.VerificationLevelID) |
| 27 | RequestDay | int | YES | Day of week of RequestDate. DATEPART(dw, RequestDate). 1=Sunday through 7=Saturday. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 28 | Month | int | YES | Month component of ModificationDate. DATEPART(month, ModificationDate). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 29 | Year | int | YES | Year component of ModificationDate. DATEPART(year, ModificationDate). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 30 | UserFeedbackIssue | int | YES | Flag indicating user feedback issue associated with the withdrawal. (Tier 3 — inferred from column name; origin unclear) |
| 31 | Region | varchar(30) | YES | Marketing region label from Dim_Country, resolved via Dim_Customer.CountryID. 22 distinct values (e.g., French, ROW, Arabic Other). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_Country.Region) |
| 32 | Regulation | varchar(30) | YES | Regulation name from Dim_Regulation, resolved via Dim_Customer.RegulationID. Short code (e.g., CySEC, FCA, ASIC, BVI). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_Regulation.Name) |
| 33 | ProcessMonth | int | YES | Month component of ProcessorValueDate (or ModificationDate). DATEPART(month, ...). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 34 | ProcessYear | int | YES | Year component of ProcessorValueDate (or ModificationDate). DATEPART(year, ...). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 35 | ProcessDay | int | YES | Day of week of ProcessorValueDate (or ModificationDate). DATEPART(dw, ...). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 36 | HoursBetween | int | YES | Hours elapsed from RequestDate to ModificationDate (or GETDATE() for pending). DATEDIFF(hh, RequestDate, ModificationDate). (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 37 | SLA | int | YES | 1-day SLA compliance flag. 1=within threshold, 0=exceeded. Threshold varies by funding type, currency, regulation, day of week, and date era. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 38 | SLA48 | int | YES | 2-day extended SLA compliance flag. 1=within threshold, 0=exceeded. Uses stricter thresholds than SLA5days but more permissive than SLA. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 39 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution time. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 40 | WD_ID_SLA | varchar(50) | YES | Overall SLA flag per WithdrawID across all funding legs. MIN(SLA) aggregated: 'OverallSLA' if all legs pass, 'OverallNotSLA' if any fail. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 41 | WD_ID_SLA48 | varchar(50) | YES | Overall SLA48 flag per WithdrawID across all funding legs. MIN(SLA48) aggregated: 'OverallSLA48' or 'OverallNotSLA48'. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 42 | SLA5days | int | YES | 5-day extended SLA compliance flag. 1=within threshold, 0=exceeded. Most permissive SLA tier. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 43 | WD_ID_SLA5days | varchar(25) | YES | Overall SLA5days flag per WithdrawID across all funding legs. MIN(SLA5days) aggregated. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 44 | ModificationDateID | bigint | YES | Integer date key derived from ModificationDate. **NULL in all rows** -- column exists in DDL and CI but is not populated by the INSERT statement. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role |
|--------|------|
| DWH_dbo.Fact_BillingWithdraw | Primary: withdrawal requests + payment legs (WithdrawID, CID, Amount, Fee, dates, statuses) |
| DWH_dbo.Dim_Customer | Customer validation (IsValidCustomer filter) + VerificationLevelID lookup |
| DWH_dbo.Dim_Country | Region label resolved via customer's CountryID |
| DWH_dbo.Dim_Regulation | Regulation name resolved via customer's RegulationID |
| DWH_dbo.Dim_FundingType | FundingType name used in SLA branching logic |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (bw)
  + JOIN DWH_dbo.Dim_Customer (dc) ON bw.CID = dc.RealCID
  + JOIN DWH_dbo.Dim_Country (dco) ON dc.CountryID = dco.CountryID
  + JOIN DWH_dbo.Dim_Regulation (dr) ON dc.RegulationID = dr.ID
  |
  v [SP_Operations_Monthly_KPIs_FullData -- daily]
    1. DELETE WHERE CAST(ModificationDate AS DATE) = @Date
    2. INSERT approved withdrawals (CashoutStatusID=3 both levels, IsValidCustomer=1)
    3. Compute SLA/SLA48/SLA5days based on funding type + currency + regulation + day of week
    4. Compute WD_ID_SLA/WD_ID_SLA48/WD_ID_SLA5days as MIN across funding legs per WithdrawID
  |
  v
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts (13.4M rows)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer who made the withdrawal |
| CurrencyID | DWH_dbo.Dim_Currency | Withdrawal currency |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method type |
| CashoutStatusID | DWH_dbo.Dim_CashoutStatus | Always 3 (Processed) |
| CashoutReasonID | DWH_dbo.Dim_CashoutReason | Withdrawal reason |
| ClientWithdrawReasonID | DWH_dbo.Dim_ClientWithdrawReason | Customer withdrawal reason |
| VerificationLevelID | Dictionary.VerificationLevel | KYC level |

### 6.2 Referenced By

| Source Object | Description |
|--------------|-------------|
| Operations dashboards | SLA compliance monitoring |

---

## 7. Sample Queries

```sql
-- Daily SLA compliance rate for the last 30 days
SELECT CAST(ModificationDate AS DATE) AS ModDate,
       COUNT(*) AS TotalLegs,
       SUM(SLA) AS SLA_Pass,
       CAST(SUM(SLA) AS FLOAT) / COUNT(*) AS SLA_Rate
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts
WHERE ModificationDate >= DATEADD(day, -30, GETDATE())
GROUP BY CAST(ModificationDate AS DATE)
ORDER BY ModDate DESC;

-- SLA compliance by funding type and regulation
SELECT FundingTypeID, Regulation,
       COUNT(*) AS Legs,
       SUM(SLA) AS SLA_Pass,
       SUM(SLA48) AS SLA48_Pass
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts
WHERE Year = 2026
GROUP BY FundingTypeID, Regulation
ORDER BY Legs DESC;

-- Overall withdrawal-level SLA summary
SELECT WD_ID_SLA, COUNT(DISTINCT WithdrawID) AS Withdrawals
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts
WHERE Year = 2026
GROUP BY WD_ID_SLA;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources identified for this object during documentation.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 14 T1, 20 T2, 10 T3, 0 T4 | Elements: 44/44, All documented*
*Object: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts | Type: Table | Production Source: BI_DB_dbo.SP_Operations_Monthly_KPIs_FullData*
