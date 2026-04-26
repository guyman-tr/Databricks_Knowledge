# BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires

> 27.7M-row approved-deposit operations dataset (Nov 2021 -- Apr 2026), tracking deposit handling time (HandlingDays, FromStartToFinish) per payment method with region and regulation segmentation -- sourced daily from Fact_BillingDeposit via SP_Operations_Monthly_KPIs_FullData (DELETE+INSERT by ModificationDate).

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

`BI_DB_Operations_Monthly_KPIs_Wires` is the Operations team's primary deposit handling time monitoring table. Despite the name "Wires", this table includes ALL approved deposit types (not just wire transfers) -- the name is historical. Each row represents one approved deposit, with working-day handling time metrics from value date to modification and from payment date to modification.

- **Row count**: 27,739,405 rows
- **Date range**: November 2021 -- April 2026 (by ModificationDate)
- **Writer SP**: `SP_Operations_Monthly_KPIs_FullData` (authored by Guy Manova 2018-04-02, maintained by Pavlina Masoura)
- **Load pattern**: Daily DELETE+INSERT keyed on ModificationDate
- **Population filter**: PaymentStatusID=2 (approved deposits) AND PlayerLevelID<>4 (not Popular Investor)
- **Top funding types by volume (2025+)**: eToroMoney (5.3M), CreditCard (3.8M), PayPal (663K)

---

## 2. Business Logic

### 2.1 Approved Deposit Population Filter

**What**: Only approved deposits from non-PI customers are included.
**Columns Involved**: PaymentStatusID, PlayerLevelID
**Rules**:
- `PaymentStatusID = 2` -- only approved deposits (73% of all Fact_BillingDeposit)
- `PlayerLevelID <> 4` -- excludes Popular Investor accounts
- All rows have PaymentStatusID=2 (constant due to filter)

### 2.2 Amount Conversion

**What**: Amount is stored in USD-equivalent, not deposit currency.
**Columns Involved**: Amount, ExchangeRate
**Rules**:
- `Amount = bd.Amount * bd.ExchangeRate` -- converted to USD equivalent at deposit time
- This differs from Fact_BillingDeposit.Amount (which is in deposit currency)
- For USD deposits: ExchangeRate=1.0, so Amount equals source Amount

### 2.3 ValueDate Resolution

**What**: ValueDate logic differs by funding type.
**Columns Involved**: ValueDate, FundingTypeID, ProcessorValueDate, PaymentDate
**Rules**:
- For wire transfers (FundingTypeID=2): `ValueDate = ProcessorValueDate` (the date funds are considered available by the processor)
- For all other funding types: `ValueDate = PaymentDate` (the deposit submission date)
- This distinction matters because wire transfers have a processing delay between submission and availability

### 2.4 Working-Day Handling Time

**What**: Two handling time metrics using weekday-adjusted calculation.
**Columns Involved**: HandlingDays, FromStartToFinish
**Rules**:
- `HandlingDays` = working days from ValueDate to ModificationDate (weekday-adjusted, floor at 0)
- `FromStartToFinish` = working days from PaymentDate to ModificationDate (weekday-adjusted, floor at 0)
- Weekend days (Saturday, Sunday) are excluded from the count
- Negative results are clamped to 0

### 2.5 FundingTypeName Lookup

**What**: Denormalized payment method name from Dim_FundingType.
**Columns Involved**: FundingTypeName, FundingTypeID
**Rules**:
- `FundingTypeName` = Dim_FundingType.Name resolved via FundingTypeID
- Examples: CreditCard, Wire, PayPal, Skrill, Neteller, eToroMoney, ApplePay, GooglePay

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with clustered index on (ModificationDateID, CID). However, ModificationDateID is NULL in all rows (not populated by the INSERT statement), so the CI is effectively useless for ModificationDateID filtering. Filter on ModificationDate (datetime) instead.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily deposit processing volume | `WHERE CAST(ModificationDate AS DATE) = @date GROUP BY FundingTypeName` |
| Average handling time by method | `AVG(HandlingDays) GROUP BY FundingTypeName` |
| Handling time by region/regulation | `GROUP BY Region, Regulation, FundingTypeName` |
| Wire transfer processing time | `WHERE FundingTypeID = 2 GROUP BY CAST(ModificationDate AS DATE)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer attributes |
| DWH_dbo.Dim_FundingType | ON FundingTypeID | Payment method flags (IsCashoutActive, etc.) |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_BillingDepot | ON DepotID | Gateway/acquirer details |

### 3.4 Gotchas

- **ModificationDateID is always NULL**: The DDL defines the column and it is part of the CI, but the INSERT statement does not populate it. Do not filter on it.
- **PaymentStatusID is always 2**: Constant due to WHERE filter. Not a useful analytics dimension.
- **Amount is USD-converted**: Unlike Fact_BillingDeposit.Amount (deposit currency), this Amount = Amount * ExchangeRate. For original-currency amounts, join back to Fact_BillingDeposit.
- **Table name is misleading**: "Wires" in the name is historical -- the table contains ALL approved deposit types, not just wire transfers.
- **HandlingDays can be 0**: The weekday calculation floors at 0, so same-day processing shows as 0.
- **ValueDate differs by FundingTypeID**: Wire (FundingTypeID=2) uses ProcessorValueDate; others use PaymentDate. Comparing HandlingDays across funding types requires understanding this asymmetry.

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
| 1 | DepositID | bigint | YES | Primary distribution key (HASH in source). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). (Tier 1 — Fact_BillingDeposit.DepositID) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. (Tier 1 — Fact_BillingDeposit.CID) |
| 3 | FundingID | bigint | YES | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — Fact_BillingDeposit.FundingID) |
| 4 | CurrencyID | int | YES | Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc. (Tier 1 — Fact_BillingDeposit.CurrencyID) |
| 5 | PaymentStatusID | int | YES | Current deposit status. Always 2 (Approved) in this table due to population filter. (Tier 1 — Fact_BillingDeposit.PaymentStatusID) |
| 6 | Amount | money | YES | Deposit amount converted to USD: bd.Amount * bd.ExchangeRate. Not in deposit currency -- differs from Fact_BillingDeposit.Amount. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 7 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — Fact_BillingDeposit.PaymentDate) |
| 8 | ValueDate | datetime | YES | Effective value date: for wires (FundingTypeID=2) uses ProcessorValueDate; for all others uses PaymentDate. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 9 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — Fact_BillingDeposit.ModificationDate) |
| 10 | Approved | int | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. (Tier 1 — Fact_BillingDeposit.Approved) |
| 11 | DepotID | int | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. (Tier 1 — Fact_BillingDeposit.DepotID) |
| 12 | FundingTypeID | int | YES | Type of payment instrument. Categorizes the deposit by payment method (credit card, wire, ACH, etc.). FK to Dim_FundingType. (Tier 1 — Fact_BillingDeposit.FundingTypeID) |
| 13 | FundingTypeName | varchar(30) | YES | Payment method name denormalized from Dim_FundingType.Name (e.g., CreditCard, Wire, PayPal, eToroMoney). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_FundingType.Name) |
| 14 | Region | varchar(30) | YES | Marketing region label from Dim_Country, resolved via Dim_Customer.CountryID. 22 distinct values (e.g., French, ROW, Arabic Other). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_Country.Region) |
| 15 | Regulation | varchar(30) | YES | Regulation name from Dim_Regulation, resolved via Dim_Customer.RegulationID. Short code (e.g., CySEC, FCA, ASIC, BVI). (Tier 2 — SP_Operations_Monthly_KPIs_FullData via Dim_Regulation.Name) |
| 16 | HandlingDays | int | YES | Working days from ValueDate to ModificationDate. Weekday-adjusted (excludes weekends), floored at 0. For wires, measures processor-to-approval time; for others, measures submission-to-approval time. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 17 | FromStartToFinish | int | YES | Working days from PaymentDate to ModificationDate. Weekday-adjusted (excludes weekends), floored at 0. Measures full deposit lifecycle regardless of funding type. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 18 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution time. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |
| 19 | ModificationDateID | bigint | YES | Integer date key derived from ModificationDate. **NULL in all rows** -- column exists in DDL and CI but is not populated by the INSERT statement. (Tier 2 — SP_Operations_Monthly_KPIs_FullData) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role |
|--------|------|
| DWH_dbo.Fact_BillingDeposit | Primary: deposit transactions (DepositID, CID, Amount, dates, statuses) |
| DWH_dbo.Dim_FundingType | FundingTypeName lookup |
| DWH_dbo.Dim_Customer | Customer validation (PlayerLevelID filter) + CountryID/RegulationID for lookups |
| DWH_dbo.Dim_Country | Region label resolved via customer's CountryID |
| DWH_dbo.Dim_Regulation | Regulation name resolved via customer's RegulationID |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingDeposit (bd)
  + JOIN DWH_dbo.Dim_FundingType (dft) ON bd.FundingTypeID = dft.FundingTypeID
  + JOIN DWH_dbo.Dim_Customer (dc) ON bd.CID = dc.RealCID
  + JOIN DWH_dbo.Dim_Country (dco) ON dc.CountryID = dco.CountryID
  + JOIN DWH_dbo.Dim_Regulation (dr) ON dc.RegulationID = dr.ID
  |
  v [SP_Operations_Monthly_KPIs_FullData -- daily]
    1. DELETE WHERE CAST(ModificationDate AS DATE) = @Date
    2. INSERT approved deposits (PaymentStatusID=2, PlayerLevelID<>4)
    3. Compute Amount = bd.Amount * bd.ExchangeRate
    4. Compute ValueDate = CASE FundingTypeID WHEN 2 THEN ProcessorValueDate ELSE PaymentDate END
    5. Compute HandlingDays and FromStartToFinish (weekday-adjusted)
  |
  v
BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires (27.7M rows)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method type |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Always 2 (Approved) |
| DepotID | DWH_dbo.Dim_BillingDepot | Gateway/acquirer |
| FundingID | Billing.Funding | Payment instrument |

### 6.2 Referenced By

| Source Object | Description |
|--------------|-------------|
| Operations dashboards | Deposit handling time monitoring |

---

## 7. Sample Queries

```sql
-- Average handling time by funding type for 2026
SELECT FundingTypeName,
       COUNT(*) AS Deposits,
       AVG(CAST(HandlingDays AS FLOAT)) AS AvgHandlingDays,
       AVG(CAST(FromStartToFinish AS FLOAT)) AS AvgFullLifecycle
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires
WHERE YEAR(ModificationDate) = 2026
GROUP BY FundingTypeName
ORDER BY Deposits DESC;

-- Wire transfer handling time trend (daily)
SELECT CAST(ModificationDate AS DATE) AS ModDate,
       COUNT(*) AS WireDeposits,
       AVG(CAST(HandlingDays AS FLOAT)) AS AvgHandlingDays
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires
WHERE FundingTypeID = 2
  AND ModificationDate >= DATEADD(day, -30, GETDATE())
GROUP BY CAST(ModificationDate AS DATE)
ORDER BY ModDate DESC;

-- Deposit volume by region and regulation
SELECT Region, Regulation,
       COUNT(*) AS Deposits,
       SUM(Amount) AS TotalAmountUSD
FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires
WHERE YEAR(ModificationDate) = 2026
GROUP BY Region, Regulation
ORDER BY Deposits DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources identified for this object during documentation.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 9 T1, 10 T2, 0 T3, 0 T4 | Elements: 19/19, All documented*
*Object: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires | Type: Table | Production Source: BI_DB_dbo.SP_Operations_Monthly_KPIs_FullData*
