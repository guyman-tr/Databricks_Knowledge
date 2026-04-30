# Billing.CashoutProcessToPayPal

> PayPal wrapper for Billing.CashoutProcess: processes a legacy cashout as a PayPal payment (FundingTypeID=3) and records the PayPal account link in Billing.PayPalToCashout.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN @Answer (from CashoutProcess), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutProcessToPayPal` is the PayPal-specific wrapper in the CashoutProcess family. It calls `Billing.CashoutProcess` with FundingTypeID=3 (PayPal) and then inserts a record into `Billing.PayPalToCashout` linking the PayPal account (by PayPalID) to the processed cashout. This is a legacy procedure operating on the ~2007-2011 Billing.Cashout table.

---

## 2. Business Logic

### 2.1 Wrapper Pattern

**What**: Calls CashoutProcess with FundingTypeID=3 (PayPal), then records the PayPal account link.

**Rules**:
- `EXECUTE @Answer = Billing.CashoutProcess(@CashoutID, ..., 3 /* PayPal */, ...)`
- If @Answer != 0: RETURN @Answer.
- INSERT INTO Billing.PayPalToCashout (PayPalID, CashoutID).
- On INSERT error: ROLLBACK + RAISERROR(60000) + RETURN @LocalError.
- On success: COMMIT + RETURN 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to process. Passed to CashoutProcess and written to PayPalToCashout. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Operations manager authorizing the processing. Passed to CashoutProcess. |
| 3 | @ProcessCurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the PayPal payment. Passed to CashoutProcess. |
| 4 | @CashoutActionStatusID | INTEGER | NO | - | CODE-BACKED | Legacy parameter passed to CashoutProcess but not used there (hardcodes 2). |
| 5 | @PayPalID | INTEGER | NO | - | CODE-BACKED | The PayPal account record ID (from Billing.PayPalToPayment or equivalent PayPal account table) to which this cashout is being sent. Written to Billing.PayPalToCashout.PayPalID. |
| 6 | @ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate for currency conversion. Passed to CashoutProcess. |
| 7 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Processing description. Passed to CashoutProcess for history and balance records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Billing.CashoutProcess | EXEC (callee) | Core processing with FundingTypeID=3 |
| @PayPalID + @CashoutID | Billing.PayPalToCashout | WRITER | Links PayPal account to this cashout |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutProcessToPayPal (procedure)
+-- Billing.CashoutProcess (procedure)   [EXEC - core processing with FundingTypeID=3]
+-- Billing.PayPalToCashout (table)      [INSERT - PayPal account to cashout link]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcess | Stored Procedure | EXEC - core cashout processing (FundingTypeID=3) |
| Billing.PayPalToCashout | Table | INSERT - records PayPal account used for this cashout |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **FundingTypeID=3 hardcoded**: This wrapper always sets PayPal (3) as the funding type.
- **Part of a five-wrapper family**: See also CashoutProcessToCreditCard (1), CashoutProcessToWireTransfer (2), CashoutProcessToWesternUnion (5), CashoutProcessToNeteller (6).

---

## 8. Sample Queries

### 8.1 Process a cashout via PayPal
```sql
DECLARE @Answer INT;
EXEC @Answer = Billing.CashoutProcessToPayPal
    @CashoutID             = 5002,
    @ManagerID             = 12345,
    @ProcessCurrencyID     = 1,
    @CashoutActionStatusID = 2,
    @PayPalID              = 8888,
    @ExchangeRate          = 1.0,
    @Description           = 'PayPal cashout approved';
SELECT @Answer AS ReturnCode;
```

### 8.2 Verify PayPal-to-cashout link
```sql
SELECT PayPalID, CashoutID
FROM Billing.PayPalToCashout WITH (NOLOCK)
WHERE CashoutID = 5002;
```

### 8.3 View cashout history
```sql
SELECT CashoutID, PreviousCashoutStatusID, NewCashoutStatusID, UpdateDate, Remark
FROM History.Cashout WITH (NOLOCK)
WHERE CashoutID = 5002
ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutProcessToPayPal | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutProcessToPayPal.sql*
