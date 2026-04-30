# Billing.CashoutProcessToNeteller

> Neteller wrapper for Billing.CashoutProcess: processes a legacy cashout as a Neteller payment (FundingTypeID=6) and records the Neteller account link in Billing.NetellerToCashout.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN @Answer (from CashoutProcess), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutProcessToNeteller` is the Neteller-specific wrapper in the CashoutProcess family. It calls `Billing.CashoutProcess` with FundingTypeID=6 (Neteller) and then inserts a record into `Billing.NetellerToCashout` linking the Neteller account (by NetellerID) to the processed cashout. This is a legacy procedure operating on the ~2007-2011 Billing.Cashout table.

---

## 2. Business Logic

### 2.1 Wrapper Pattern

**What**: Calls CashoutProcess with FundingTypeID=6 (Neteller), then records the Neteller account link.

**Rules**:
- `EXECUTE @Answer = Billing.CashoutProcess(@CashoutID, ..., 6 /* Neteller */, ...)`
- If @Answer != 0: RETURN @Answer.
- INSERT INTO Billing.NetellerToCashout (NetellerID, CashoutID).
- On INSERT error: ROLLBACK + RAISERROR(60000) + RETURN @LocalError.
- On success: COMMIT + RETURN 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to process. Passed to CashoutProcess and written to NetellerToCashout. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Operations manager authorizing the processing. Passed to CashoutProcess. |
| 3 | @ProcessCurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the Neteller payment. Passed to CashoutProcess. |
| 4 | @CashoutActionStatusID | INTEGER | NO | - | CODE-BACKED | Legacy parameter passed to CashoutProcess but not used there (hardcodes 2). |
| 5 | @NetellerID | INTEGER | NO | - | CODE-BACKED | The Neteller account record ID (from Billing.NetellerToPayment or equivalent Neteller account table) to which this cashout is being sent. Written to Billing.NetellerToCashout.NetellerID. |
| 6 | @ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate for currency conversion. Passed to CashoutProcess. |
| 7 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Processing description. Passed to CashoutProcess for history and balance records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Billing.CashoutProcess | EXEC (callee) | Core processing with FundingTypeID=6 |
| @NetellerID + @CashoutID | Billing.NetellerToCashout | WRITER | Links Neteller account to this cashout |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutProcessToNeteller (procedure)
+-- Billing.CashoutProcess (procedure)   [EXEC - core processing with FundingTypeID=6]
+-- Billing.NetellerToCashout (table)    [INSERT - Neteller account to cashout link]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcess | Stored Procedure | EXEC - core cashout processing (FundingTypeID=6) |
| Billing.NetellerToCashout | Table | INSERT - records Neteller account used for this cashout |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Process a cashout via Neteller
```sql
DECLARE @Answer INT;
EXEC @Answer = Billing.CashoutProcessToNeteller
    @CashoutID             = 5001,
    @ManagerID             = 12345,
    @ProcessCurrencyID     = 1,
    @CashoutActionStatusID = 2,
    @NetellerID            = 7777,
    @ExchangeRate          = 1.0,
    @Description           = 'Neteller cashout approved';
SELECT @Answer AS ReturnCode;
```

### 8.2 Verify Neteller-to-cashout link
```sql
SELECT NetellerID, CashoutID
FROM Billing.NetellerToCashout WITH (NOLOCK)
WHERE CashoutID = 5001;
```

### 8.3 View cashout history
```sql
SELECT CashoutID, PreviousCashoutStatusID, NewCashoutStatusID, UpdateDate, Remark
FROM History.Cashout WITH (NOLOCK)
WHERE CashoutID = 5001
ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutProcessToNeteller | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutProcessToNeteller.sql*
