# Billing.CashoutProcessToWireTransfer

> Wire transfer wrapper for Billing.CashoutProcess: processes a legacy cashout as a wire transfer payment (FundingTypeID=2) and records the bank transaction ID in Billing.WireTransferToCashout.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN @Answer (from CashoutProcess), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutProcessToWireTransfer` is the wire transfer-specific wrapper in the CashoutProcess family. It calls `Billing.CashoutProcess` with FundingTypeID=2 (WireTransfer) and then inserts a record into `Billing.WireTransferToCashout` linking the bank's transaction reference (TransactionID) to the processed cashout. This is a legacy procedure operating on the ~2007-2011 Billing.Cashout table.

Wire transfers are bank-to-bank fund movements; the TransactionID is the reference number from the processing bank that can be used to trace the wire through correspondent banking systems.

---

## 2. Business Logic

### 2.1 Wrapper Pattern

**What**: Calls CashoutProcess with FundingTypeID=2 (WireTransfer), then records the bank transaction reference.

**Rules**:
- `EXECUTE @Answer = Billing.CashoutProcess(@CashoutID, ..., 2 /* WireTransfer */, ...)`
- If @Answer != 0: RETURN @Answer.
- INSERT INTO Billing.WireTransferToCashout (CashoutID, TransactionID).
- On INSERT error: ROLLBACK + RAISERROR(60000) + RETURN @LocalError.
- On success: COMMIT + RETURN 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to process. Passed to CashoutProcess and written to WireTransferToCashout. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Operations manager authorizing the processing. Passed to CashoutProcess. |
| 3 | @ProcessCurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the wire transfer. Passed to CashoutProcess. |
| 4 | @CashoutActionStatusID | INTEGER | NO | - | CODE-BACKED | Legacy parameter passed to CashoutProcess but not used there (hardcodes 2). |
| 5 | @TransactionID | VARCHAR(20) | NO | - | CODE-BACKED | The bank's transaction reference number for this wire transfer. Used to trace the payment through correspondent banking. Written to Billing.WireTransferToCashout.TransactionID. Max 20 characters. |
| 6 | @ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate for currency conversion. Passed to CashoutProcess. |
| 7 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Processing description. Passed to CashoutProcess for history and balance records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Billing.CashoutProcess | EXEC (callee) | Core processing with FundingTypeID=2 |
| @CashoutID + @TransactionID | Billing.WireTransferToCashout | WRITER | Records bank transaction reference for this cashout |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutProcessToWireTransfer (procedure)
+-- Billing.CashoutProcess (procedure)      [EXEC - core processing with FundingTypeID=2]
+-- Billing.WireTransferToCashout (table)   [INSERT - bank transaction reference for cashout]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcess | Stored Procedure | EXEC - core cashout processing (FundingTypeID=2) |
| Billing.WireTransferToCashout | Table | INSERT - records TransactionID for this cashout |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **FundingTypeID=2 hardcoded**: This wrapper always sets WireTransfer (2) as the funding type.
- **TransactionID vs account identifiers**: Unlike card (CardID) or e-wallet (NetellerID, PayPalID) wrappers which reference account records, the wire transfer wrapper stores an opaque bank transaction reference string. This reflects wire transfer's nature as a one-time bank instruction rather than a stored payment method.
- **Part of a five-wrapper family**: See also CashoutProcessToCreditCard (1), CashoutProcessToPayPal (3), CashoutProcessToWesternUnion (5), CashoutProcessToNeteller (6).

---

## 8. Sample Queries

### 8.1 Process a cashout via wire transfer
```sql
DECLARE @Answer INT;
EXEC @Answer = Billing.CashoutProcessToWireTransfer
    @CashoutID             = 5004,
    @ManagerID             = 12345,
    @ProcessCurrencyID     = 1,
    @CashoutActionStatusID = 2,
    @TransactionID         = 'TXN20240315001',
    @ExchangeRate          = 1.0,
    @Description           = 'Wire transfer cashout approved';
SELECT @Answer AS ReturnCode;
```

### 8.2 Verify wire transfer reference was recorded
```sql
SELECT CashoutID, TransactionID
FROM Billing.WireTransferToCashout WITH (NOLOCK)
WHERE CashoutID = 5004;
```

### 8.3 View cashout processing history
```sql
SELECT CashoutID, PreviousCashoutStatusID, NewCashoutStatusID, UpdateDate, Remark
FROM History.Cashout WITH (NOLOCK)
WHERE CashoutID = 5004
ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutProcessToWireTransfer | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutProcessToWireTransfer.sql*
