# Customer.SetBalanceDataFixDebug

> Debug variant of SetBalanceDataFix - identical logic (absolute balance overwrites, optional BSLRealFunds recalculation, CreditTypeID=31 credit record) with one addition: the CATCH block emits SELECT ERROR_MESSAGE() to the result set for diagnostic purposes.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Credit MONEY, @RealizedEquity MONEY, @TotalCash MONEY; @CreditID BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceDataFixDebug` is the debug companion to `Customer.SetBalanceDataFix`. The two procedures are functionally identical in their balance update and credit logging logic. The only difference is in the error handling path:

- **SetBalanceDataFix** (production): `BEGIN CATCH ... IF @@TRANCOUNT=1 ROLLBACK ... THROW;`
- **SetBalanceDataFixDebug** (debug): `BEGIN CATCH ... SELECT ERROR_MESSAGE() Bonnie ... IF @@TRANCOUNT=1 ROLLBACK ... THROW;`

The `SELECT ERROR_MESSAGE() Bonnie` line returns the error message as a result set column named "Bonnie" (a developer's personal debug signature), allowing a caller to capture the error message text directly without relying on the THROW to propagate it.

Used in debugging scenarios where the calling context cannot easily capture thrown exceptions - for example, when called from SSMS ad-hoc scripts, debug harnesses, or temporary test procedures.

---

## 2. Business Logic

All business logic is identical to `Customer.SetBalanceDataFix`. Refer to that documentation for full details.

**Summary**:
- Absolute overwrite of CustomerMoney balance fields (NULL = keep current).
- Three-mode BSLRealFunds update: unchanged, explicit, or auto-calculated from Trade.PnL.
- Logs CreditTypeID=31 (DataFix) with @Payment=0, @TotalCashChange=0.
- Returns @CreditID OUTPUT.

**Only difference**:

```sql
-- SetBalanceDataFix CATCH:
BEGIN CATCH
    IF @@TRANCOUNT = 1 ROLLBACK TRAN;
    IF @@TRANCOUNT > 1 COMMIT;
    THROW;
END CATCH

-- SetBalanceDataFixDebug CATCH:
BEGIN CATCH
    SELECT ERROR_MESSAGE() Bonnie  -- <-- debug SELECT added
    IF @@TRANCOUNT = 1 ROLLBACK TRAN;
    IF @@TRANCOUNT > 1 COMMIT;
    THROW;
END CATCH
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

Identical to `Customer.SetBalanceDataFix`. See that documentation for the full parameter table.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose balance is being corrected. |
| 2 | @Credit | MONEY | YES | - | CODE-BACKED | Absolute new Credit value. NULL = keep current. |
| 3 | @RealizedEquity | MONEY | YES | - | CODE-BACKED | Absolute new RealizedEquity. NULL = keep current. |
| 4 | @TotalCash | MONEY | YES | - | CODE-BACKED | Absolute new TotalCash. NULL = keep current. |
| 5 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Description stored in the credit history record. |
| 6 | @BonusCredit | MONEY | YES | - | CODE-BACKED | Absolute new BonusCredit. NULL = keep current. |
| 7 | @ShouldChangeBSLRealFunds | TINYINT | YES | 0 | CODE-BACKED | 0=leave BSLRealFunds unchanged; 1=update (explicit or auto-calculated). |
| 8 | @BSLRealFunds | MONEY | YES | NULL | CODE-BACKED | Explicit BSLRealFunds value (used when @ShouldChangeBSLRealFunds=1). NULL triggers auto-calculation. |
| 9 | @CreditID | BIGINT | YES | 0 (OUTPUT) | CODE-BACKED | OUTPUT: CreditID of the DataFix credit record. |

---

## 5. Relationships

Identical to `Customer.SetBalanceDataFix`.

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | Absolute UPDATE of balance fields |
| @CID | Trade.PnL | READ (conditional) | SUM PnLInDollars for auto-BSLRealFunds calculation |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=31 DataFix record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PostMIMOOperationsDebug | EXEC | Caller | Debug variant of PostMIMOOperations calls this instead of SetBalanceDataFix |
| Debugging / manual correction sessions | External | Callers | Used when error message visibility is needed in the calling session |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceDataFixDebug (procedure)
+-- Customer.CustomerMoney (table) [absolute UPDATE]
+-- Trade.PnL (table/view) [conditional READ for BSLRealFunds calculation]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=31]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

Identical to `Customer.SetBalanceDataFix`.

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - absolute overwrite of balance fields |
| Trade.PnL | Table/View | SELECT (conditional) - BSLRealFunds auto-calculation |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=31 DataFix record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PostMIMOOperationsDebug | Procedure | Calls this for MIMO-recalculated balance corrections (debug mode) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SELECT ERROR_MESSAGE() Bonnie | Debug artifact | Debug result set column named "Bonnie" (developer debug signature). This SELECT fires on error before ROLLBACK, emitting the error message to the caller's result set. |
| All other constraints | Same as SetBalanceDataFix | See SetBalanceDataFix documentation for all balance update and BSL constraints. |

---

## 8. Sample Queries

See `Customer.SetBalanceDataFix` for equivalent sample queries. The debug variant produces identical output.

### 8.1 Use DataFixDebug to capture error details

```sql
-- Call debug variant when you need to see the error in the result set
EXEC Customer.SetBalanceDataFixDebug
    @CID = 12345,
    @Credit = 1000.00,
    @RealizedEquity = 1000.00,
    @TotalCash = 1000.00,
    @Description = 'Debug correction test',
    @BonusCredit = NULL,
    @ShouldChangeBSLRealFunds = 0;
-- On error: result set will contain SELECT ERROR_MESSAGE() column "Bonnie"
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceDataFixDebug | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceDataFixDebug.sql*
