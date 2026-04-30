# Billing.GetMoneyInTransactionsByCID

> Returns all money-in (deposit-type) credit transactions for a customer since a given start time, joining History.Credit and History.ActiveCreditRecentMemoryBucket with Billing.Deposit and Billing.Funding, and appending a ConversionCost (PIPs in USD) via BackOffice.CalculateDepositPIPsUSD.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid + @startTime - returns deposit-type credit transactions with funding details and conversion costs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMoneyInTransactionsByCID` retrieves a customer's inbound money transactions - deposits and related credit events that brought funds into their account. It is named "money in" because it filters to `CreditTypeID IN (1, 11, 12, 16, 17)`, which are deposit-related credit types (not bonuses, compensation, or other credit events).

The procedure queries two Credit tables:
- `History.Credit` - the primary credit history table (disk-based)
- `History.ActiveCreditRecentMemoryBucket` - an in-memory table containing recent active credits (added for performance: recent transactions are in-memory for fast access)

Both sources are combined into a temp table (`#Result`) ordered by PaymentDate, then enriched with funding method details and a calculated FX conversion cost (the "PIP cost" of any currency conversion). This gives a complete view of each deposit including: what payment method was used, what the original currency was, the exchange rate applied, and how much FX conversion cost was incurred.

The result is ordered by PaymentDate DESC (newest first), making it suitable for displaying a customer's recent deposit history in the portfolio/wallet views.

Evolving over time:
- Shay Oren 03/01/2021: Split query to first access History.Credit then in-memory ActiveCreditRecentMemoryBucket
- Shay Oren 21/01/2021: Added Billing.Funding join (PAYUA-1611)
- Maksym M. 26/05/2021: Added Payment Data (PAYUA-1934)
- Denys M. 05/01/2022: Added ConversionCost calculation (PAYUA-3088)
- Katem 23/01/2024: Added CurrencyID parameter to CalculateDepositPIPsUSD for AED formula (MIMOPS2-239)

---

## 2. Business Logic

### 2.1 Dual Credit Source: Disk + In-Memory

**What**: Queries both the persistent credit history and the recent in-memory bucket, inserting both into `#Result`.

**Columns/Parameters Involved**: `History.Credit`, `History.ActiveCreditRecentMemoryBucket`, `@cid`, `@startTime`

**Rules**:
- Both tables have the same relevant columns (CreditID, DepositID, CreditTypeID, Occurred, Payment, CID)
- Two separate INSERT...SELECT statements - one per source
- `AND (c.Payment <> 0)` - excludes zero-amount credit events (technical entries with no financial value)
- `AND (d.PaymentDate >= @startTime)` - date filter applied via the joined Billing.Deposit row
- `AND c.CreditTypeID IN (1, 11, 12, 16, 17)` - deposit-type credits only (see CreditTypeID section)
- `OPTION (OPTIMIZE FOR (@startTime = '20010101'))` on the disk table query - forces the optimizer to assume a wide date range and use the CID index (prevents bad plans when future dates are accidentally passed)
- Temp table has a CLUSTERED INDEX on PaymentDate for efficient final ordering

### 2.2 CreditTypeID Filter: Deposit-Type Credits Only

**What**: Only 5 CreditTypeID values are included - those representing money arriving into the account.

**Columns/Parameters Involved**: `c.CreditTypeID`

**Rules**:
- `CreditTypeID IN (1, 11, 12, 16, 17)` - deposit-related inflows
- CreditTypeID 1: Standard deposit credit (the primary money-in event)
- CreditTypeIDs 11, 12, 16, 17: Other deposit-adjacent credit types (e.g., deposit reversals, re-deposits, multi-currency deposit variants)
- Excludes: bonus credits (6, 7), position close credits, compensation, or other financial events
- Note: `History.Credit` has `Payment` (not `Amount`) - this is the credit amount applied to the customer's balance

### 2.3 Funding Enrichment

**What**: Joins the temp table to Billing.Funding to retrieve the payment method details used for each deposit.

**Columns/Parameters Involved**: `R.FundingID`, `f.FundingTypeID`, `f.FundingData`

**Rules**:
- `INNER JOIN Billing.Funding f ON R.FundingID = f.FundingID` - FundingID from the deposit record
- Returns `f.FundingTypeID` (payment method category: 1=credit card, 2=wire, etc.)
- Returns `f.FundingData` (XML with payment instrument details - masked for non-privileged users)

### 2.4 ConversionCost (CalculateDepositPIPsUSD)

**What**: Calculates the FX conversion cost for non-USD deposits as a USD PIP amount.

**Columns/Parameters Involved**: `BackOffice.CalculateDepositPIPsUSD`, `f.FundingTypeID`, `R.ExchangeRate`, `R.BaseExchangeRate`, `R.ExchangeFee`, `R.AmountInCurrency`, `R.CurrencyID`

**Rules**:
- `OUTER APPLY BackOffice.CalculateDepositPIPsUSD(...)` - applied per row, NULL if no conversion cost
- Returns `ConversionCost.Value` as `ConversionCost`
- For USD deposits: ConversionCost = 0 (no FX conversion)
- For non-USD: ConversionCost = the cost of converting to USD, expressed in USD PIPs

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Filters both Credit tables and Billing.Deposit to this customer's transactions. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Earliest payment date to include (applied via Billing.Deposit.PaymentDate >= @startTime). NULL means no date filter (all history). The OPTIMIZE FOR hint ensures efficient plans even when a future date is passed. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | CreditID | bigint | NO | - | CODE-BACKED | PK of the credit record in History.Credit or History.ActiveCreditRecentMemoryBucket. |
| 4 | DepositID | int | YES | NULL | CODE-BACKED | FK to Billing.Deposit - the deposit that generated this credit. |
| 5 | CreditTypeID | int | NO | - | CODE-BACKED | Type of credit event. Values: 1 (standard deposit), 11, 12, 16, 17 (deposit variants). |
| 6 | PaymentDate | datetime | NO | - | CODE-BACKED | When the associated deposit was processed (from Billing.Deposit.PaymentDate). Used for ordering. |
| 7 | Amount | money | NO | - | CODE-BACKED | The credit amount applied to the customer's balance (from History.Credit.Payment column, aliased as Amount). The actual USD amount credited. |
| 8 | PaymentStatusID | int | NO | - | CODE-BACKED | Current status of the deposit (from Billing.Deposit). From Dictionary.PaymentStatus. |
| 9 | CurrencyID | int | NO | - | CODE-BACKED | Currency of the original deposit (from Billing.Deposit.CurrencyID). |
| 10 | ExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | FX rate applied when converting the deposit currency to USD (from Billing.Deposit). |
| 11 | AmountInCurrency | money | NO | - | CODE-BACKED | The deposit amount in the original currency (from Billing.Deposit.Amount). |
| 12 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method category (from Billing.Funding). 1=credit card, 2=wire transfer, etc. |
| 13 | FundingData | xml | YES | NULL | CODE-BACKED | Payment instrument XML data (from Billing.Funding). Schema varies by FundingTypeID. DDM-masked for non-privileged users. |
| 14 | PaymentData | xml | YES | NULL | CODE-BACKED | Additional payment payload XML from Billing.Deposit.PaymentData. Provider-specific transaction data. |
| 15 | ConversionCost | money/decimal | YES | NULL | CODE-BACKED | FX conversion cost in USD PIPs, calculated by BackOffice.CalculateDepositPIPsUSD. NULL or 0 for USD deposits. Non-zero for deposits requiring currency conversion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT 1 (FROM) | History.Credit | Direct Read | Disk-based credit history for deposit-type transactions (CreditTypeID IN 1,11,12,16,17) |
| INSERT 2 (FROM) | History.ActiveCreditRecentMemoryBucket | Direct Read | In-memory recent credits for same filter (avoids disk I/O for recent transactions) |
| JOIN (both inserts) | Billing.Deposit | Direct Read | Enriches credits with deposit status, currency, exchange rate, funding reference |
| JOIN (final SELECT) | Billing.Funding | Direct Read | Retrieves payment method type and instrument data for each deposit |
| OUTER APPLY | BackOffice.CalculateDepositPIPsUSD | Function Call | Calculates FX conversion cost per deposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Called from application code for customer portfolio/wallet views. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMoneyInTransactionsByCID (procedure)
├── History.Credit (table)
├── History.ActiveCreditRecentMemoryBucket (in-memory table)
├── Billing.Deposit (table)
├── Billing.Funding (table)
└── BackOffice.CalculateDepositPIPsUSD (function)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | INSERT SELECT - deposit-type credits (CreditTypeID IN 1,11,12,16,17), non-zero Payment, date filter via Billing.Deposit |
| History.ActiveCreditRecentMemoryBucket | Table (in-memory) | INSERT SELECT - same filter as History.Credit; covers recent active credits for performance |
| Billing.Deposit | Table | INNER JOIN - enriches credits with deposit status, currency, exchange rate, funding reference, PaymentData |
| Billing.Funding | Table | INNER JOIN - retrieves FundingTypeID and FundingData XML for the deposit's payment instrument |
| BackOffice.CalculateDepositPIPsUSD | Function | OUTER APPLY - calculates FX conversion cost in USD PIPs per deposit row |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Internal temp table**: `#Result` with CLUSTERED INDEX on PaymentDate - enables efficient final ORDER BY.

---

## 8. Sample Queries

### 8.1 Get all money-in transactions for a customer

```sql
EXEC Billing.GetMoneyInTransactionsByCID @cid = 12345678, @startTime = NULL
-- Returns all deposit-type credits ever for this customer, newest first
```

### 8.2 Get recent transactions (last 90 days)

```sql
EXEC Billing.GetMoneyInTransactionsByCID
    @cid       = 12345678,
    @startTime = DATEADD(DAY, -90, GETDATE())
-- Returns deposit transactions where the deposit PaymentDate >= 90 days ago
```

### 8.3 Equivalent simplified ad-hoc query

```sql
SELECT c.CreditID, c.DepositID, c.CreditTypeID, c.Occurred AS PaymentDate,
       c.Payment AS Amount, d.PaymentStatusID, d.CurrencyID
FROM History.Credit c WITH (NOLOCK)
INNER JOIN Billing.Deposit d WITH (NOLOCK) ON c.DepositID = d.DepositID
WHERE c.CID = 12345678
  AND c.Payment <> 0
  AND c.CreditTypeID IN (1, 11, 12, 16, 17)
ORDER BY d.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMoneyInTransactionsByCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMoneyInTransactionsByCID.sql*
