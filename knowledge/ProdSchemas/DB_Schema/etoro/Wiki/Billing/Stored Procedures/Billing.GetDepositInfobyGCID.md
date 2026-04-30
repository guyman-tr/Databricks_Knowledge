# Billing.GetDepositInfobyGCID

> Returns a financial summary for a customer (looked up by GCID) including total deposits, last-year deposits/withdrawals, since-FTD withdrawals, current balance, copy trading activity flag, and yearly deposit total - used for KYC aggregated info and compliance assessment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single summary row for the customer identified by @GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositInfobyGCID` produces a concise financial profile of a customer for compliance and KYC (Know Your Customer) purposes. It accepts a GCID (global customer ID, the external-facing identifier), resolves it to the internal CID, then computes seven financial metrics: deposit totals (all-time, last year, current calendar year), withdrawal totals (last year, since FTD), current account balance, and whether the customer has ever copied another trader.

This SP appears to back the `/KycAggregatedInfo/` API endpoint (referenced in Confluence investigations), which is used by compliance teams and automated KYC assessment workflows to evaluate a customer's financial behavior. The GCID-based input is typical of external/public API calls where the consumer uses the public customer identifier.

Created by Geri Reshef, January 2018, ticket 50232. Uses five temporary tables to assemble complex aggregations before joining them into a single output row.

---

## 2. Business Logic

### 2.1 Last-Year Deposit Aggregation (USD-equivalent)

**What**: Total approved deposits in the last 12 rolling months, converted to USD.

**Columns/Parameters Involved**: `Billing.Deposit.Amount`, `Billing.Deposit.ExchangeRate`, `Billing.Deposit.PaymentDate`, `DepositsLastYear (output)`

**Rules**:
- Filter: `PaymentStatusID=2` (Approved only) AND `PaymentDate > DATEADD(Year, -1, GETUTCDATE())` (last 12 months rolling)
- Computation: `SUM(Amount * ExchangeRate)` = USD-equivalent deposit amount
- Joined to `BackOffice.CustomerAllTimeAggregatedData` to scope to the correct CID (defensive join)
- Returns 0 if no qualifying deposits (ISNULL)

### 2.2 Last-Year Withdrawal Aggregation

**What**: Total completed cashouts in the last 12 rolling months.

**Columns/Parameters Involved**: `Billing.Withdraw.Amount`, `Billing.Withdraw.RequestDate`, `WithdrawsLastYear (output)`

**Rules**:
- Filter: `CashoutStatusID=3` (completed/approved cashout) AND `RequestDate > DATEADD(Year, -1, GETUTCDATE())`
- Amount is in the withdraw currency (not USD-converted, unlike deposits)
- Returns 0 if no qualifying withdrawals

### 2.3 Withdrawals Since FTD

**What**: Total completed cashouts from the date of the customer's first deposit to today.

**Columns/Parameters Involved**: `BackOffice.CustomerAllTimeAggregatedData.FirstTimeDepositSuccessDate`, `Billing.Withdraw.Amount`, `WithdrawsSinceFtd (output)`

**Rules**:
- Filter: `CashoutStatusID=3` AND `RequestDate > FirstTimeDepositSuccessDate` (from BackOffice aggregated data)
- Measures total cashout behavior across the customer's lifetime on eToro (from FTD to present)
- Returns 0 if no qualifying withdrawals

### 2.4 Copy Trading Activity Detection

**What**: Checks whether the customer has ever held a copy trading position (mirrored another trader).

**Columns/Parameters Involved**: `History.Mirror.CID`, `HasCopies (output)`

**Rules**:
- `SELECT TOP 1 CID INTO #hasCopiedSomeone FROM History.Mirror JOIN Customer.CustomerStatic ON CID WHERE GCID=@GCID AND CID=@CID`
- If a row is found in History.Mirror -> `HasCopies = 1`
- If no row found -> `HasCopies = 0`
- Uses History.Mirror (not Trade.Mirror) - captures historical copy activity, including closed copies

### 2.5 Current Calendar Year Deposits

**What**: Total approved deposits within the current calendar year (from Jan 1 of this year to now), plus the first-ever deposit date.

**Columns/Parameters Involved**: `Billing.Deposit.Amount`, `Billing.Deposit.ExchangeRate`, `Billing.Deposit.PaymentDate`, `YearlyDeposits (output)`, `PaymentDate (output)`

**Rules**:
- Calendar year: `PaymentDate BETWEEN DATEADD(Year, DATEDIFF(Year,'19000101', GETUTCDATE()), '19000101') AND GETUTCDATE()` - from Jan 1 of current year
- First deposit: `MIN(PaymentDate)` over ALL approved deposits for the customer (not just current year)
- Both computed from the same CTE; `PaymentDate` in the output = `FirstPayment` = earliest deposit ever

**Diagram**:
```
@GCID
  |
  +-> Customer.CustomerStatic -> @CID
  |
  +-> #depositsLastYear: SUM(Amount*ExchangeRate) WHERE PaymentStatus=2, last 12 months
  +-> #withdrawsLastYear: SUM(Amount) WHERE CashoutStatus=3, last 12 months
  +-> #withdrawsSinceFtd: SUM(Amount) WHERE CashoutStatus=3, since FirstTimeDepositSuccessDate
  +-> #hasCopiedSomeone: EXISTS check in History.Mirror
  +-> #currentYearDeposits: SUM(Amount*ExchangeRate) WHERE PaymentStatus=2, current year
                            + MIN(PaymentDate) AS FirstPayment (all-time first deposit)
  |
  v
Final SELECT joins all 5 temp tables + Customer.Customer + BackOffice.CustomerAllTimeAggregatedData
  -> Single row with 8 fields
  -> WHERE: GCID=@GCID AND (FirstPayment IS NOT NULL OR catad.CID IS NOT NULL)
  -> Excludes customers with no deposits AND not in aggregated data
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID (external/public identifier). Resolved to internal CID via Customer.CustomerStatic.GCID. |
| 2 | PaymentDate (output) | DATETIME | YES | - | CODE-BACKED | The customer's first-ever approved deposit date (MIN(PaymentDate) from all-time approved deposits). Named PaymentDate in output but represents the historical first deposit timestamp. NULL if customer has no deposits. |
| 3 | TotalDeposit (output) | MONEY | YES | - | CODE-BACKED | All-time total deposits in USD. Sourced from BackOffice.CustomerAllTimeAggregatedData.TotalDeposit - the pre-aggregated lifetime deposit total. 0 if not in aggregated data. |
| 4 | DepositsLastYear (output) | MONEY | YES | - | CODE-BACKED | Sum of Amount*ExchangeRate for approved deposits in the last 12 rolling months (USD-equivalent). Computed in #depositsLastYear temp table. 0 if no qualifying deposits. |
| 5 | WithdrawsLastYear (output) | MONEY | YES | - | CODE-BACKED | Sum of withdrawal amounts for completed cashouts in the last 12 rolling months. From #withdrawsLastYear. 0 if no qualifying withdrawals. Note: in withdraw currency, not necessarily USD. |
| 6 | WithdrawsSinceFtd (output) | MONEY | YES | - | CODE-BACKED | Sum of completed cashout amounts since the customer's first deposit (FirstTimeDepositSuccessDate from BackOffice.CustomerAllTimeAggregatedData). Measures lifetime cashout behavior. 0 if no qualifying withdrawals. |
| 7 | Balance (output) | MONEY | YES | - | CODE-BACKED | Customer's current account credit balance. From Customer.Customer.Credit. The live account balance at query time. |
| 8 | HasCopies (output) | INT | NO | - | CODE-BACKED | Whether the customer has ever held a copy-trade position (CopyTrader activity). 0=no copy history, 1=has copy history. Derived from History.Mirror: 0 if no rows found, 1 if any row exists. |
| 9 | YearlyDeposits (output) | MONEY | YES | - | CODE-BACKED | Sum of Amount*ExchangeRate for approved deposits in the current calendar year (Jan 1 to now, USD-equivalent). 0 if no deposits this calendar year. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerStatic.GCID | Lookup | Resolves GCID to internal CID |
| @CID (derived) | Billing.Deposit.CID | Lookup | Aggregates approved deposit history |
| @CID (derived) | Billing.Withdraw.CID | Lookup | Aggregates completed withdrawal history |
| @CID (derived) | BackOffice.CustomerAllTimeAggregatedData.CID | Lookup | Gets TotalDeposit and FirstTimeDepositSuccessDate |
| @CID (derived) | Customer.Customer.CID | Lookup | Gets current Credit balance |
| @GCID + @CID | History.Mirror.CID | Lookup | Checks for copy trading history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| /KycAggregatedInfo/ API endpoint | Application call | Functional | Called by the KYC aggregated info API (Per Confluence investigation references); used for compliance assessment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositInfobyGCID (procedure)
├── Customer.CustomerStatic (table)
├── Billing.Deposit (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── Billing.Withdraw (table)
├── History.Mirror (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Resolves @GCID -> @CID at the start |
| Billing.Deposit | Table | READ NOLOCK - aggregates approved deposits for last-year, current-year, and first-deposit metrics |
| BackOffice.CustomerAllTimeAggregatedData | Table | READ NOLOCK - provides TotalDeposit and FirstTimeDepositSuccessDate for since-FTD calculations |
| Billing.Withdraw | Table | READ NOLOCK - aggregates completed cashouts for last-year and since-FTD metrics |
| History.Mirror | Table | READ NOLOCK - checks for copy trading activity |
| Customer.Customer | Table | READ NOLOCK - provides current Credit balance |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC Aggregated Info API (/KycAggregatedInfo/) | Application | Calls to retrieve customer financial profile for KYC/compliance workflows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table cleanup | Safety | Each temp table is dropped if exists before creation (defensive cleanup for reuse) |
| Calendar year logic | Design | `DATEADD(Year, DATEDIFF(Year, '19000101', GETUTCDATE()), '19000101')` computes Jan 1 of the current year without timezone issues |
| WHERE filter on output | Design | `FirstPayment IS NOT NULL OR catad.CID IS NOT NULL` - returns no row for customers with zero deposit history and not in aggregated data (guards against empty profiles) |
| No GCID permissions grant found | Note | No SQL grant found in UsersPermissions files; likely called by an application service with a custom connection, or access is managed outside the SSDT permissions files |

---

## 8. Sample Queries

### 8.1 Get deposit info for a customer by GCID

```sql
EXEC Billing.GetDepositInfobyGCID @GCID = 7000000;
```

### 8.2 Check what TotalDeposit will come from

```sql
SELECT CID, TotalDeposit, FirstTimeDepositSuccessDate
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE CID = (SELECT CID FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = 7000000);
```

### 8.3 Verify copy trading history for a customer

```sql
SELECT TOP 1 hm.CID, hm.MirrorID
FROM History.Mirror hm WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = hm.CID
WHERE cs.GCID = 7000000;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Investigation: /KycAggregatedInfo/ (inaccessible) | Confluence | Title suggests this SP backs the /KycAggregatedInfo/ API endpoint used for KYC compliance assessment |
| KYC Improvement (inaccessible) | Confluence | Context for KYC aggregation workflows that likely use this SP |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.9/10 (Elements: 9/10, Logic: 10/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 accessible Confluence + 0 Jira (2 pages inaccessible) | Procedures: 0 SQL callers | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositInfobyGCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositInfobyGCID.sql*
