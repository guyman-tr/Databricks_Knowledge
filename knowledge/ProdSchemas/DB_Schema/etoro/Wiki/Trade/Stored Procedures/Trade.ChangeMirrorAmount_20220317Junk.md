# Trade.ChangeMirrorAmount_20220317Junk

> DEPRECATED junk/snapshot procedure - a frozen copy of Trade.ChangeMirrorAmount from 2022-03-17, retained in SSDT for reference but not intended for production use.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeMirrorAmount_20220317Junk is a frozen snapshot of the Trade.ChangeMirrorAmount procedure as it existed on 2022-03-17. It adjusts the allocated funds in a CopyTrader mirror (copy-trade relationship) by moving money between the customer's general balance and a specific mirror's balance.

This "Junk" suffix indicates it is a historical copy retained for debugging or rollback reference. The production version of this logic lives in Trade.ChangeMirrorAmount (or Trade.ChangeMirrorAmountForMoe). This procedure should not be called in production workflows.

When called, it validates the mirror exists and is active, checks balance sufficiency, recalculates the mirror stop-loss amount based on the new equity, updates Trade.Mirror financial columns, logs to History.Mirror with MirrorOperationID=3 (Change mirror balance), and adjusts the customer's credit via Customer.SetBalanceChangeMirrorAmount. All within a transaction.

---

## 2. Business Logic

### 2.1 Mirror Balance Adjustment

**What**: Moves funds between a customer's general balance and a CopyTrader mirror allocation.

**Columns/Parameters Involved**: `@DeltaAmountInCents`, `@MirrorID`, `@CID`, `Trade.Mirror.Amount`, `Trade.Mirror.RealizedEquity`

**Rules**:
- Positive @DeltaAmountInCents: moves money FROM general balance TO mirror (CreditTypeID=18)
- Negative @DeltaAmountInCents: moves money FROM mirror TO general balance (CreditTypeID=19)
- Amounts converted from cents to dollars internally (@DeltaAmountInDollars = @DeltaAmountInCents / 100.00)
- Updates Mirror.Amount, RealizedEquity, DepositSummary/WithdrawalSummary accordingly

### 2.2 Validation and Error Codes

**What**: Multiple business validations before allowing the transfer.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`, `@ValidateUserBalance`, `@ExpectedMirrorAmountInCents`

**Rules**:
- 60050: MirrorID does not exist
- 60051: Mirror is not active (IsActive=0)
- 60052: Withdrawal amount exceeds mirror balance
- 60054: Deposit amount exceeds customer credit
- 60064: @CID mismatch with mirror's CID
- 60097: New mirror amount would trigger mirror stop-loss closure
- @ExpectedMirrorAmountInCents: Optimistic concurrency check - if provided, current + delta must equal expected

### 2.3 Stop-Loss Recalculation

**What**: Recalculates mirror stop-loss when @EditMirrorSL=1.

**Columns/Parameters Involved**: `@EditMirrorSL`, `@NewSLAmountCents`, `Trade.Mirror.MirrorSLPercentage`, `Trade.Mirror.RealizedEquity`

**Rules**:
- When @EditMirrorSL=1: NewSLAmountCents = (RealizedEquity * 100 + @DeltaAmountInCents) * MirrorSLPercentage / 100
- When @EditMirrorSL=0: Keeps existing MirrorSL unchanged
- @NewSLAmountCents is an OUTPUT parameter returned to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must match Trade.Mirror.CID for the given @MirrorID. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | The CopyTrader mirror to adjust. Identifies the copy-trade relationship in Trade.Mirror. |
| 3 | @DeltaAmountInCents | dtPrice | NO | - | CODE-BACKED | Amount to add/remove in cents. Positive = deposit into mirror, negative = withdraw to general balance. |
| 4 | @MirrorCalculatedUnrealized | MONEY | NO | - | CODE-BACKED | Current unrealized PnL of the mirror in cents. Used to validate that the new amount won't trigger stop-loss. |
| 5 | @NewSLAmountCents | MONEY | NO (OUT) | - | CODE-BACKED | OUTPUT: Recalculated mirror stop-loss amount in cents after the balance change. |
| 6 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for audit trail. Written to History.Mirror. |
| 7 | @MIMOOperationTypeIID | TINYINT | YES | 0 | CODE-BACKED | Mirror In/Mirror Out operation type. Default 0 (standard). Written to History.Mirror. |
| 8 | @MirrorDividendID | INT | YES | 0 | CODE-BACKED | Dividend event ID if this change is triggered by a dividend. Passed to Customer.SetBalanceChangeMirrorAmount. |
| 9 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation GUID from the client request. Written to History.Mirror for tracing. |
| 10 | @ValidateUserBalance | TINYINT | YES | 1 | CODE-BACKED | 1=enforce balance validations (default), 0=skip validations (used by Reopen Trade feature). |
| 11 | @EditMirrorSL | BIT | YES | 1 | CODE-BACKED | 1=recalculate mirror stop-loss based on new equity (default), 0=keep existing MirrorSL. |
| 12 | @ExpectedMirrorAmountInCents | MONEY | YES | NULL | CODE-BACKED | Optimistic concurrency check. If provided, current mirror amount + delta must equal this value, else error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | UPDATE + SELECT | Reads mirror state, updates Amount/RealizedEquity/DepositSummary/WithdrawalSummary/MirrorSL |
| @CID | Customer.Customer | SELECT | Reads Credit for balance validation |
| (writes) | History.Mirror | INSERT | Logs the balance change with MirrorOperationID=3 |
| (calls) | Customer.SetBalanceChangeMirrorAmount | EXEC | Adjusts customer's general balance (inverse of mirror delta) |

### 5.2 Referenced By (other objects point to this)

This is a deprecated junk procedure. No production code should reference it.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeMirrorAmount_20220317Junk (procedure)
+-- Trade.Mirror (table)
+-- Customer.Customer (table)
+-- History.Mirror (table)
+-- Customer.SetBalanceChangeMirrorAmount (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT state, UPDATE financial columns |
| Customer.Customer | Table | SELECT Credit for validation |
| History.Mirror | Table | INSERT audit record |
| Customer.SetBalanceChangeMirrorAmount | Stored Procedure | EXEC to adjust general balance |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | Deprecated - no callers expected |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error Handling | Two TRY/CATCH blocks - one for validation, one for execution. Rollback on error. |

---

## 8. Sample Queries

### 8.1 Check if this junk procedure is referenced anywhere

```sql
SELECT OBJECT_NAME(referencing_id) AS ReferencingObject
FROM   sys.sql_expression_dependencies WITH (NOLOCK)
WHERE  referenced_entity_name = 'ChangeMirrorAmount_20220317Junk'
       AND referenced_schema_name = 'Trade';
```

### 8.2 Compare with current production procedure

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('Trade.ChangeMirrorAmount_20220317Junk')) AS JunkVersion;
```

### 8.3 View mirror balance history for a specific mirror

```sql
SELECT MirrorID, Amount, MirrorOperationID, Occurred
FROM   History.Mirror WITH (NOLOCK)
WHERE  MirrorID = @MirrorID
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The procedure's header references multiple FogBugz tickets (FB 23569, 31696, 35218, 35806, 51445, 52839) documenting its evolution history.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeMirrorAmount_20220317Junk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeMirrorAmount_20220317Junk.sql*
