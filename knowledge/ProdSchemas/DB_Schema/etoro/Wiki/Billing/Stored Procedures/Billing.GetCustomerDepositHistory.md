# Billing.GetCustomerDepositHistory

> Returns a paginated slice of a customer's deposit history within a date range, with an OUTPUT parameter for total count, using 0-based position indexing and amount scaled by 100 (dollars to cents units).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + date range + page position (@From/@To); @NumberOfDeposits OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerDepositHistory` is a paginated deposit history retrieval procedure used for displaying a customer's past deposits. It loads all matching deposits from `Billing.Deposit` into a temporary result set, reports the total count via an OUTPUT parameter, then returns a specific page of results defined by a 0-based position range.

The procedure pre-dates modern API pagination patterns - it uses a table variable with `IDENTITY(0,1)` to assign sequential 0-based position numbers, enabling the caller to request positions 0-9 (first 10), 10-19 (second 10), etc. The `CAST(Amount*100 AS INTEGER)` conversion scales the deposit amount from decimal dollars to integer cents (or similar 100x unit), suggesting the caller expects amounts in the smallest currency unit.

Granted only to PROD_BIadmins, suggesting this is a reporting or back-office tool procedure rather than a customer-facing API procedure.

---

## 2. Business Logic

### 2.1 Two-Pass Pagination Pattern

**What**: The procedure performs two passes over the result set: first to count all matching deposits, then to return a specific page.

**Columns/Parameters Involved**: `@From`, `@To`, `@NumberOfDeposits`, `Position`

**Rules**:
- All matching deposits are loaded into @Results table variable (no row limit on the INSERT).
- `@NumberOfDeposits = COUNT(*) FROM @Results`: total count before pagination. Allows the caller to render pagination controls (e.g., "Showing 1-10 of 47 deposits").
- `SELECT * FROM @Results WHERE Position BETWEEN @From AND @To`: returns the page. Position is 0-based IDENTITY(0,1).
  - Page 1 (first 10): @From=0, @To=9
  - Page 2 (next 10): @From=10, @To=19
  - Single record: @From=N, @To=N
- ORDER BY PaymentDate DESC on INSERT assigns positions in reverse chronological order (newest deposit = Position 0).

**Diagram**:
```
Billing.Deposit (all for @CID in date range, ORDER BY PaymentDate DESC)
          |
          v
@Results table (Position=0 = most recent deposit)
  Position | DepositID | ... | Amount (x100)
  ---------|-----------|-----|--------
  0        | 7654321   | ... | 10000  (= $100.00)
  1        | 7654320   | ... | 5000   (= $50.00)
  ...
          |
  @NumberOfDeposits = total row count
          |
  SELECT WHERE Position BETWEEN @From AND @To
```

### 2.2 Amount Scaling (x100)

**What**: The Amount column from Billing.Deposit is multiplied by 100 and cast to INTEGER before being stored in the result set.

**Columns/Parameters Involved**: `Amount`, `CAST(Amount*100 AS INTEGER)`

**Rules**:
- `CAST(Amount*100 AS INTEGER)`: converts the decimal Amount to a 100x integer representation.
- Example: Amount=$100.00 -> returned as 10000; Amount=$50.50 -> returned as 5050.
- The calling system expects amounts in the smallest currency unit (cents for USD, pence for GBP, etc.).
- ExchangeRate is NOT scaled - returned as-is with full decimal precision (DECIMAL(16,8)).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose deposit history to retrieve. Filters Billing.Deposit.CID. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range (inclusive - BETWEEN @DateFrom AND @DateTo). Filters on Billing.Deposit.PaymentDate. |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range (inclusive). Defines the upper bound of the deposit history window. |
| 4 | @From | INT | NO | - | CODE-BACKED | 0-based start position for the page (inclusive). Combined with @To to define which records to return. First page: @From=0. |
| 5 | @To | INT | NO | - | CODE-BACKED | 0-based end position for the page (inclusive). Combined with @From. Page size = @To - @From + 1. |
| 6 | @NumberOfDeposits | INTEGER | NO | OUTPUT | CODE-BACKED | OUTPUT parameter. Returns the total count of deposits matching the CID + date range filter BEFORE pagination. Enables caller to render total count and pagination controls. |

**Returns** (SELECT output columns from @Results):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Position | INTEGER | NO | CODE-BACKED | 0-based sequential position assigned by IDENTITY(0,1). Position=0 is the most recent deposit (ORDER BY PaymentDate DESC). Used by caller to request specific pages. |
| 2 | DepositID | INTEGER | NO | CODE-BACKED | Primary key of the Billing.Deposit record. Inherited from Billing.Deposit. |
| 3 | CurrencyID | INTEGER | NO | CODE-BACKED | Currency of the deposit. 1=USD, 2=EUR, 3=GBP, etc. Inherited from Billing.Deposit. |
| 4 | CID | INTEGER | NO | CODE-BACKED | Customer ID (same as @CID). Inherited from Billing.Deposit. |
| 5 | PaymentStatusID | INTEGER | NO | CODE-BACKED | Current status of the deposit. 2=Approved, 1=New, 3=Declined, etc. Full state machine in Dictionary.PaymentStatusStateMachine. Inherited from Billing.Deposit. |
| 6 | FundingID | INTEGER | YES | CODE-BACKED | Payment instrument used for the deposit. FK to Billing.Funding. Inherited from Billing.Deposit. |
| 7 | Amount | INTEGER | NO | CODE-BACKED | Deposit amount scaled by 100 (CAST(Amount*100 AS INTEGER)). A $100.00 deposit is returned as 10000. Caller must divide by 100 to recover the original amount. |
| 8 | ExchangeRate | DECIMAL(16,8) | YES | CODE-BACKED | Exchange rate applied at the time of deposit. Not scaled - returned as full decimal. Inherited from Billing.Deposit. |
| 9 | PaymentDate | DATETIME | YES | CODE-BACKED | Date and time the deposit was processed. The ORDER BY column - Position 0 = most recent PaymentDate. Inherited from Billing.Deposit. |
| 10 | TransactionID | CHAR(6) | YES | CODE-BACKED | 6-character transaction identifier from the payment provider. Inherited from Billing.Deposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentDate | Billing.Deposit | Direct read (SELECT) | Source of deposit records - filtered by CID + date range, ordered by PaymentDate DESC |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE grant | Permission | BI admin reporting tool - paginated deposit history viewer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerDepositHistory (procedure)
└── Billing.Deposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT all columns WHERE CID = @CID AND PaymentDate BETWEEN dates, ORDER BY PaymentDate DESC |

### 6.2 Objects That Depend On This

No dependents found. Called directly by BI admin tooling (PROD_BIadmins).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Table variable with IDENTITY | @Results uses IDENTITY(0,1) for 0-based position numbering enabling keyset-free pagination |
| Amount scaling | Amount multiplied by 100 and cast to INTEGER before returning - caller receives amounts in smallest currency unit |

---

## 8. Sample Queries

### 8.1 Get first page of deposit history

```sql
DECLARE @Count INT
EXEC [Billing].[GetCustomerDepositHistory]
    @CID = 1234567,
    @DateFrom = '2024-01-01',
    @DateTo = '2024-12-31',
    @From = 0,
    @To = 9,
    @NumberOfDeposits = @Count OUTPUT
SELECT @Count AS TotalDeposits
-- Result set: first 10 deposits; @Count = total in date range
```

### 8.2 Get second page

```sql
DECLARE @Count INT
EXEC [Billing].[GetCustomerDepositHistory]
    @CID = 1234567,
    @DateFrom = '2024-01-01',
    @DateTo = '2024-12-31',
    @From = 10,
    @To = 19,
    @NumberOfDeposits = @Count OUTPUT
-- Returns deposits at positions 10-19 (records 11-20)
```

### 8.3 Verify the Amount scaling

```sql
-- Compare raw Amount vs. procedure output Amount
SELECT TOP 5 DepositID, Amount AS RawAmount, Amount * 100 AS ScaledAmount
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE CID = 1234567
ORDER BY PaymentDate DESC
-- ScaledAmount matches what GetCustomerDepositHistory returns
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerDepositHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerDepositHistory.sql*
