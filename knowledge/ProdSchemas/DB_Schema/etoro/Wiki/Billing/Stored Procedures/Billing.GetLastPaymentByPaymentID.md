# Billing.GetLastPaymentByPaymentID

> Returns the full payment record for a specific PaymentID belonging to a customer - a CID-scoped lookup of Billing.Payment with TOP 1 / ORDER BY PaymentDate DESC as a defensive guard.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PaymentID - returns all columns of the matching payment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetLastPaymentByPaymentID` retrieves the complete `Billing.Payment` record for a given customer and payment ID. `Billing.Payment` stores completed payment transactions (both deposits and withdrawals) that have been processed by the payment network; it is distinct from `Billing.Deposit` (which tracks the full deposit lifecycle).

The `@CID` parameter serves as an ownership guard - the query filters by both `CID` and `PaymentID`, ensuring a customer can only retrieve their own payment record. Since `PaymentID` is an `IDENTITY` primary key, there is at most one row per `PaymentID`, making the `TOP 1 ORDER BY PaymentDate DESC` redundant in practice but defensive in design (guards against any theoretical duplicate or edge case).

All 19 columns of `Billing.Payment` are returned via `SELECT *`, giving the caller the full payment snapshot including amounts, fees, exchange rates, status, and timestamps.

---

## 2. Business Logic

### 2.1 CID-Scoped Payment Lookup

**What**: Returns the single payment record matching (CID, PaymentID), with the most recent PaymentDate first as a tiebreaker.

**Columns/Parameters Involved**: `@CID`, `@PaymentID`, all Billing.Payment columns

**Rules**:
- `WHERE CID = @CID AND PaymentID = @PaymentID` - dual-key filter
- `@CID` is a security scope: the caller cannot retrieve payments belonging to another customer even if they know the PaymentID
- `TOP 1 ORDER BY PaymentDate DESC` - defensive pattern; in practice PaymentID is IDENTITY PK so at most one row matches
- Returns empty set (no rows) if the PaymentID does not exist or belongs to a different CID
- `SELECT *` returns all 19 Billing.Payment columns

**Billing.Payment columns returned**:

| Column | Type | Description |
|--------|------|-------------|
| PaymentID | int IDENTITY | PK - unique payment record |
| CurrencyID | int | Payment currency (FK Dictionary.Currency) |
| CID | int | Customer ID (FK Customer.CustomerStatic) |
| PaymentStatusID | int | Payment status at this snapshot (FK Dictionary.PaymentStatus) |
| PaymentTypeID | int | Payment type: deposit or withdrawal direction (FK Dictionary.PaymentType) |
| FundingTypeID | int | Payment method used (FK Dictionary.FundingType) |
| TerminalID | int | Processing terminal (FK Billing.Terminal) |
| ManagerID | int | Admin who processed, if any (FK BackOffice.Manager, NULL for automated) |
| Amount | int | Amount in cents (integer; divide by 100 for display) |
| ExchangeRate | dtPrice | FX rate applied if non-USD currency |
| TotalFee | int | Total fee in cents |
| DirectAcceptFee | int | Direct acceptance fee in cents |
| PaymentDate | datetime | When the payment was processed |
| ModificationDate | datetime | Last update timestamp (DEFAULT getdate()) |
| Approved | bit | Whether approved (NULL if not yet determined) |
| TransactionID | char(6) | Clearing house transaction reference |
| IPAddress | numeric(18,0) | Customer IP at time of payment (stored as numeric) |
| Commission | money | Commission amount (DEFAULT 0) |
| ClearingHouseEffectiveDate | datetime | When clearing house settled the transaction |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Scopes the lookup to the customer's own payments. FK to Customer.CustomerStatic.CID. |
| 2 | @PaymentID | INT | NO | - | CODE-BACKED | The specific payment to retrieve. FK to Billing.Payment.PaymentID (IDENTITY PK). Combined with @CID as an ownership check. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | * (all columns) | various | mixed | - | CODE-BACKED | All 19 columns of Billing.Payment. See Business Logic section for full column list. Amount/TotalFee/DirectAcceptFee are in cents (divide by 100 for display). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Billing.Payment | Direct Read | Full payment record retrieval by (CID, PaymentID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Called from application code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetLastPaymentByPaymentID (procedure)
└── Billing.Payment (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | SELECT * - full row retrieval for (CID, PaymentID) |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get a customer's payment record

```sql
EXEC Billing.GetLastPaymentByPaymentID
    @CID = 12345678,
    @PaymentID = 99001234
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT TOP 1 *
FROM Billing.Payment WITH (NOLOCK)
WHERE CID = 12345678
  AND PaymentID = 99001234
ORDER BY PaymentDate DESC
```

### 8.3 Verify payment belongs to customer (ownership check)

```sql
-- If this returns 0 rows, the PaymentID doesn't exist for this customer
DECLARE @result TABLE (PaymentID INT, CID INT, Amount INT, PaymentStatusID INT)
INSERT @result
EXEC Billing.GetLastPaymentByPaymentID @CID = 12345678, @PaymentID = 99001234
SELECT COUNT(*) AS Found FROM @result
-- 0 = payment not found or belongs to a different customer
-- 1 = payment found and confirmed owned by this customer
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetLastPaymentByPaymentID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetLastPaymentByPaymentID.sql*
