# Billing.UserMoneyInTransactionsGet

> Returns a customer's money-in (deposit) transaction history by unioning History.Credit and the in-memory History.ActiveCreditRecentMemoryBucket for recent records, joining to Billing.Deposit for payment details and Billing.Funding for method info, and computing ConversionCost via BackOffice.CalculateDepositPIPsUSD.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid + @startTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UserMoneyInTransactionsGet` is the primary procedure for retrieving a customer's deposit transaction history, used when displaying the "Money In" section of a customer's transaction history. It returns all approved deposit credits for a customer since `@startTime`, enriched with funding method details and a conversion cost metric.

The procedure uses a two-part INSERT-into-temp-table architecture (introduced by Shay Oren 03/01/2021) to handle the split between historical and recent credits:
- `History.Credit`: the permanent audit log of all credit events
- `History.ActiveCreditRecentMemoryBucket`: an in-memory optimized table holding recent credits not yet flushed to History.Credit

By querying both and inserting into a temp table `#Result`, the procedure guarantees complete coverage of all credits regardless of which store they reside in.

The filter `CreditTypeID IN (1, 11, 12, 16, 17)` limits results to deposit-related credit types. The `ConversionCost` column (added PAYUA-3088) represents the exchange/conversion cost in USD for the deposit, calculated by `BackOffice.CalculateDepositPIPsUSD`.

Change history: Shay Oren 03/01/2021 (split to dual-store), 21/01/2021 PAYUA-1611 (join to Billing.Funding), Maksym M. 26/05/2021 PAYUA-1934 (PaymentData), Denys M. 05/01/2022 PAYUA-3088 (ConversionCost), Elrom B. 18/12/2023 (return FundingID).

---

## 2. Business Logic

### 2.1 Dual-Store Credit Query (History.Credit + In-Memory Bucket)

**What**: Reads from both the persistent credit history and the in-memory recent credits bucket to ensure complete coverage.

**Columns/Parameters Involved**: `@cid`, `@startTime`, `History.Credit.CreditTypeID`, `History.ActiveCreditRecentMemoryBucket`

**Rules**:
- Creates temp table `#Result` with a clustered index on `PaymentDate` for efficient ordering
- INSERT #1: FROM `History.Credit` JOIN `Billing.Deposit` WHERE `c.CID = @cid AND c.Payment <> 0 AND d.PaymentDate >= @startTime AND c.CreditTypeID IN (1, 11, 12, 16, 17)` with `OPTIMIZE FOR (@startTime = '20010101')` hint
- INSERT #2: Same query from `History.ActiveCreditRecentMemoryBucket` - catches credits not yet in History.Credit
- Both INSERTs use the same WHERE predicate; combined result in #Result covers all time ranges

**OPTIMIZE FOR hint**: Forces the query optimizer to use an index plan based on the minimum possible @startTime, ensuring the CID-based index is always used even if a future date is accidentally passed.

**CreditTypeID filter values**:

| CreditTypeID | Description |
|--------------|-------------|
| 1 | Standard deposit (FTD and subsequent) |
| 11 | Deposit bonus |
| 12 | FTD bonus |
| 16 | Recurring deposit |
| 17 | ACH deposit |

### 2.2 Final SELECT with Funding Enrichment and ConversionCost

**What**: Joins #Result with Billing.Funding for method details and applies BackOffice.CalculateDepositPIPsUSD via OUTER APPLY.

**Columns Returned**:
- `CreditID`, `DepositID`, `CreditTypeID`, `PaymentDate`, `Amount`, `PaymentStatusID`
- `CurrencyID`, `ExchangeRate`, `AmountInCurrency` (amount in deposit currency)
- `FundingID`, `FundingTypeID`, `FundingData` (from Billing.Funding)
- `PaymentData` (XML from Billing.Deposit - raw provider response data)
- `DepositTypeID`
- `ConversionCost` - decimal value from `BackOffice.CalculateDepositPIPsUSD(FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, AmountInCurrency, CurrencyID)` - the exchange spread cost in USD units

**Note**: OUTER APPLY means ConversionCost is NULL if CalculateDepositPIPsUSD returns no row for a given funding type/exchange combination.

### 2.3 @startTime Default Behavior

**Rules**:
- `@startTime DATETIME = NULL` (default)
- When NULL, the WHERE clause `d.PaymentDate >= NULL` evaluates to unknown/false for all rows - returning no results
- Callers should always pass a valid @startTime; NULL is treated as "no results" rather than "all time"
- Typical call: pass 1-3 years back depending on the UI context

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INTEGER | NO | - | CODE-BACKED | Customer ID. Used as the primary filter in both History.Credit and History.ActiveCreditRecentMemoryBucket queries. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Start of the transaction history window. NULL results in no rows returned (PaymentDate >= NULL = false). Callers should always provide a meaningful date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | History.Credit | SELECT (JOIN source) | Permanent credit audit log |
| @cid | History.ActiveCreditRecentMemoryBucket | SELECT (JOIN source) | In-memory recent credits not yet in History.Credit |
| c.DepositID | Billing.Deposit | JOIN | Provides PaymentStatusID, CurrencyID, ExchangeRate, Amount, PaymentData, DepositTypeID |
| d.FundingID | Billing.Funding | JOIN | Provides FundingTypeID, FundingData |
| f.FundingTypeID | BackOffice.CalculateDepositPIPsUSD | OUTER APPLY | Calculates ConversionCost (exchange spread) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal Service (application) | Transaction history EP | Application call | Called to show customer's deposit transaction history |
| Back Office / customer view (application) | Money In display | Application call | Renders deposit history in customer card |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UserMoneyInTransactionsGet (procedure)
+-- History.Credit (table) [SELECT - permanent credit log]
+-- History.ActiveCreditRecentMemoryBucket (in-memory table) [SELECT - recent credits]
+-- Billing.Deposit (table) [JOIN - payment details]
+-- Billing.Funding (table) [JOIN - funding method details]
+-- BackOffice.CalculateDepositPIPsUSD (function) [OUTER APPLY - conversion cost]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Primary credit log; provides CreditID, CreditTypeID, Payment, Occurred |
| History.ActiveCreditRecentMemoryBucket | In-Memory Table | Recent credits not yet archived to History.Credit |
| Billing.Deposit | Table | JOIN on DepositID for PaymentStatusID, ExchangeRate, Amount, PaymentData, DepositTypeID |
| Billing.Funding | Table | JOIN on FundingID for FundingTypeID, FundingData |
| BackOffice.CalculateDepositPIPsUSD | Function | OUTER APPLY for ConversionCost in USD units |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Transaction history endpoints (application) | Application | Calls to retrieve customer deposit history for display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @startTime = NULL returns no rows | Design | `d.PaymentDate >= NULL` is always false; callers must provide a valid start date |
| OPTIMIZE FOR hint | Performance | Forces index plan based on earliest possible @startTime; prevents bad plan if future date passed accidentally |
| Clustered index on #Result(PaymentDate) | Performance | Final ORDER BY PaymentDate DESC uses this index for efficient sort |
| OUTER APPLY ConversionCost | Design | Returns NULL ConversionCost if CalculateDepositPIPsUSD has no result for the given parameters |
| SET NOCOUNT ON | Performance | Suppresses row count messages from temp table operations |

---

## 8. Sample Queries

### 8.1 Get last 2 years of money-in transactions for a customer
```sql
EXEC Billing.UserMoneyInTransactionsGet
    @cid       = 123456,
    @startTime = '2024-03-18';
```

### 8.2 Check result structure
```sql
-- #Result has columns matching the final SELECT:
-- CreditID, DepositID, CreditTypeID, PaymentDate, Amount, PaymentStatusID
-- CurrencyID, ExchangeRate, AmountInCurrency, FundingID, FundingTypeID, FundingData
-- PaymentData, DepositTypeID, ConversionCost
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UserMoneyInTransactionsGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UserMoneyInTransactionsGet.sql*
