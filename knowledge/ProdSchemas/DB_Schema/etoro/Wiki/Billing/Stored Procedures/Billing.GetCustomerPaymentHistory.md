# Billing.GetCustomerPaymentHistory

> Paginated retrieval of pre-2011 payment history from Billing.Payment using 0-based position indexing (IDENTITY(0,1)) with an OUTPUT parameter for total count - the Payment-table equivalent of GetCustomerDepositHistory for the legacy deposit archive.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + date range (@DateFrom/@DateTo) + page position (@From/@To); @NumberOfPayments OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerPaymentHistory` retrieves paginated deposit history from `Billing.Payment`, eToro's pre-2011 legacy deposit archive (388,522 records, all migrated to Billing.Deposit by January 2011). It is the Payment-table equivalent of `GetCustomerDepositHistory` (which queries the modern `Billing.Deposit` table).

The procedure implements the same two-pass pagination pattern as `GetCustomerDepositHistory`: all matching records are loaded into a table variable with 0-based IDENTITY positions, a total count is returned via OUTPUT parameter, and then a specific page is returned by position range. This allows callers to render "Showing records 1-10 of 23" UI controls.

**Key distinction from GetCustomerDepositHistory**:
- Queries `Billing.Payment` (pre-2011), not `Billing.Deposit` (post-2011/current).
- Amount is already stored as INTEGER in Billing.Payment (amounts in cents, no scaling needed) - no x100 CAST.
- No status filter: returns ALL payment records regardless of status (all 388,522 are status=27/Migrated).
- Returns TerminalID (old routing model) and PaymentTypeID instead of FundingID and PaymentData.
- Always returns 0 records for post-2011 customers (no data in Payment table).

Used by BILLING_MANAGER for back-office support views of historical deposits. Called by legacy back-office tooling that needs to surface the customer's pre-2011 transaction history alongside the modern deposit history.

---

## 2. Business Logic

### 2.1 Two-Pass Pagination Pattern (0-Based Position)

**What**: Same pagination mechanism as GetCustomerDepositHistory - load all matching records, count them, return a page.

**Columns/Parameters Involved**: `@DateFrom`, `@DateTo`, `@From`, `@To`, `@NumberOfPayments`, `Position`

**Rules**:
- INSERT into @Results (IDENTITY(0,1)) with `ORDER BY PaymentDate DESC`: Position 0 = most recent payment in date range.
- No status filter on INSERT: all Payment records for the CID in the date range are included regardless of PaymentStatusID.
- `SELECT @NumberOfPayments = COUNT(*) FROM @Results`: total count before pagination.
- `SELECT * FROM @Results WHERE Position BETWEEN @From AND @To ORDER BY Position`: returns the requested page.
  - Page 1 (first 10): @From=0, @To=9
  - Page 2: @From=10, @To=19
- Since all Billing.Payment records are status=27 (migrated), the results are purely historical records.

**Diagram**:
```
Billing.Payment (all for @CID in date range, ORDER BY PaymentDate DESC)
          |
          v
@Results table (IDENTITY(0,1) position, Position 0 = most recent)
  Position | PaymentID | Amount (already in cents) | ...
          |
  @NumberOfPayments = total row count
          |
  SELECT WHERE Position BETWEEN @From AND @To
```

### 2.2 Amount Storage in Payment Table (Already Integer Cents)

**What**: Unlike GetCustomerDepositHistory (which CASTs Amount x100), Billing.Payment already stores amounts as integer cents.

**Rules**:
- `Amount` in Billing.Payment is an INT type already representing smallest currency unit (cents for USD, pence for GBP).
- No scaling in this SP - Amount is selected as-is.
- A value of 100000 = $1,000.00 USD; 5000 = $50.00 USD.
- Callers should be aware of the unit difference vs. Billing.Deposit (which stores as MONEY decimal).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose payment history to retrieve. Filters Billing.Payment.CID. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range (inclusive - BETWEEN @DateFrom AND @DateTo). Filters on Billing.Payment.PaymentDate. |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range (inclusive). Defines the upper bound of the history window. |
| 4 | @From | INT | NO | - | CODE-BACKED | 0-based start position for the page (inclusive). First page: @From=0. |
| 5 | @To | INT | NO | - | CODE-BACKED | 0-based end position for the page (inclusive). Page size = @To - @From + 1. |
| 6 | @NumberOfPayments | INTEGER | NO | OUTPUT | CODE-BACKED | OUTPUT parameter. Returns the total count of records matching the CID + date range filter BEFORE pagination. |

**Returns** (SELECT output columns from @Results):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Position | INTEGER | NO | CODE-BACKED | 0-based sequential position assigned by IDENTITY(0,1). Position=0 is the most recent payment (ORDER BY PaymentDate DESC). |
| 2 | PaymentID | INTEGER | NO | CODE-BACKED | Primary key of the Billing.Payment record. Pre-2011 payment identifier. Billing.Deposit.OldPaymentID may reference this. |
| 3 | CurrencyID | INTEGER | NO | CODE-BACKED | Currency of the payment. 1=USD, 2=EUR, 3=GBP, etc. FK to Dictionary.Currency. |
| 4 | CID | INTEGER | NO | CODE-BACKED | Customer ID (same as @CID). |
| 5 | PaymentStatusID | INTEGER | NO | CODE-BACKED | Always 27 (MigratedToDepositTable) for all records in Billing.Payment. No status filter applied. |
| 6 | PaymentTypeID | INTEGER | NO | CODE-BACKED | Payment direction. All 388,522 records have PaymentTypeID=1 (Deposit). |
| 7 | FundingTypeID | INTEGER | NO | CODE-BACKED | Payment method type. Historical distribution: 1=CreditCard (63%), 3=PayPal (28%), 2=Wire (5%), 5=WesternUnion (2%), 6=Neteller (1%). |
| 8 | TerminalID | INTEGER | YES | CODE-BACKED | Pre-2011 routing configuration ID. FK to Billing.Terminal. Encodes the (Protocol, PaymentType, Currency, FundingType) routing combination used at the time. No modern equivalent in Billing.Deposit (which uses DepotID). |
| 9 | Amount | INTEGER | NO | CODE-BACKED | Deposit amount in smallest currency unit (integer cents). Already stored as integer in Billing.Payment - no x100 scaling applied. A value of 100000 = $1,000.00 USD. |
| 10 | ExchangeRate | DECIMAL(16,8) | YES | CODE-BACKED | Exchange rate at the time of the payment. Same precision as Billing.Deposit. |
| 11 | PaymentDate | DATETIME | YES | CODE-BACKED | Date and time of the payment. ORDER BY column for Position assignment. Position 0 = most recent PaymentDate. |
| 12 | TransactionID | CHAR(6) | YES | CODE-BACKED | 6-character payment provider transaction reference (same as in Billing.Deposit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentDate | Billing.Payment | Direct read (SELECT) | Source of pre-2011 payment records - filtered by CID + date range, no status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | EXECUTE grant | Permission | Back-office billing management tool for viewing historical pre-2011 payment records |
| PROD_BIadmins | VIEW DEFINITION grant | Permission | BI admins can inspect the procedure definition |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerPaymentHistory (procedure)
└── Billing.Payment (table - frozen archive, pre-2011)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | SELECT all columns WHERE CID + date range, ORDER BY PaymentDate DESC |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Table variable with IDENTITY | @Results uses IDENTITY(0,1) for 0-based position - same pattern as GetCustomerDepositHistory |
| No status filter | Returns ALL records regardless of status (all are 27=Migrated) |
| Amount already integer | Billing.Payment.Amount is INT in cents; no x100 scaling needed unlike GetCustomerDepositHistory |
| Always empty for post-2011 customers | No Billing.Payment records for post-2011 customers - @NumberOfPayments OUTPUT = 0 |

---

## 8. Sample Queries

### 8.1 Get first page of pre-2011 payment history

```sql
DECLARE @Count INT
EXEC [Billing].[GetCustomerPaymentHistory]
    @CID = 1234567,
    @DateFrom = '2007-01-01',
    @DateTo = '2011-12-31',
    @From = 0,
    @To = 9,
    @NumberOfPayments = @Count OUTPUT
SELECT @Count AS TotalPayments
-- Returns pre-2011 payments; @Count = total in range
-- Note: Amount is already in cents (no x100 conversion needed)
```

### 8.2 Compare pagination behavior with GetCustomerDepositHistory

```sql
-- GetCustomerDepositHistory (modern Billing.Deposit, Amount needs /100 to get dollars):
DECLARE @DepCount INT
EXEC [Billing].[GetCustomerDepositHistory]
    @CID = 1234567, @DateFrom = '2011-01-01', @DateTo = '2024-12-31',
    @From = 0, @To = 9, @NumberOfDeposits = @DepCount OUTPUT

-- GetCustomerPaymentHistory (legacy Billing.Payment, Amount already in cents):
DECLARE @PayCount INT
EXEC [Billing].[GetCustomerPaymentHistory]
    @CID = 1234567, @DateFrom = '2007-01-01', @DateTo = '2011-12-31',
    @From = 0, @To = 9, @NumberOfPayments = @PayCount OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerPaymentHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerPaymentHistory.sql*
