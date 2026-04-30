# Trade.CIDsInLiquidationRemove

> Removes a customer from the liquidation queue, recalculates their BSLRealFunds balance via Customer.SetBalanceDataFix, and archives the liquidation record to History.CIDsInLiquidation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CIDsInLiquidationRemove is the counterpart to Trade.CIDsInLiquidationAdd. When a customer's account liquidation process completes (all positions closed, funds settled), this procedure:

1. **Reads current balance data** (Credit, RealizedEquity, TotalCash, BonusCredit) from Customer.CustomerMoney
2. **Calls Customer.SetBalanceDataFix** with @ShouldChangeBSLRealFunds=1 to recalculate the Balance Stop Loss real funds based on post-liquidation balances
3. **Archives and deletes** the CIDsInLiquidation record using DELETE...OUTPUT INTO History.CIDsInLiquidation, preserving the CID, StartTime, ActionTypeID, and adding the end timestamp

The entire operation runs within an explicit transaction with TRY/CATCH error handling and proper rollback semantics.

---

## 2. Business Logic

### 2.1 Balance Recalculation

**What**: Reads current balances and triggers BSLRealFunds recalculation.

**Columns/Parameters Involved**: `Customer.CustomerMoney.Credit`, `RealizedEquity`, `TotalCash`, `BonusCredit`

**Rules**:
- Reads current Credit, RealizedEquity, TotalCash, BonusCredit from Customer.CustomerMoney
- Passes all values to Customer.SetBalanceDataFix with Description='Remove from CIDsInLiquidation table'
- @ShouldChangeBSLRealFunds=1 forces BSL recalculation: BSLRealFunds = RealizedEquity - BonusCredit

### 2.2 Archive and Delete

**What**: Atomically deletes from Trade.CIDsInLiquidation and archives to History.CIDsInLiquidation.

**Columns/Parameters Involved**: `CID`, `StartTime`, `AccountLiquidationAcionTypeID`

**Rules**:
- DELETE...OUTPUT pattern ensures atomic archive: deleted.CID, deleted.StartTime, deleted.AccountLiquidationAcionTypeID, GETUTCDATE() (end time) inserted into History
- History record preserves full liquidation duration (StartTime to EndTime)

### 2.3 Transaction Handling

**Rules**:
- Explicit BEGIN TRAN / COMMIT TRAN
- On error: ROLLBACK if @@TRANCOUNT=1, COMMIT if @@TRANCOUNT>1 (nested transaction support)
- THROW re-raises the original error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to remove from liquidation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | SELECT | Reads current balances |
| @CID | Customer.SetBalanceDataFix | EXEC | Recalculates BSLRealFunds |
| @CID | Trade.CIDsInLiquidation | DELETE | Removes liquidation flag |
| @CID | History.CIDsInLiquidation | INSERT (via OUTPUT) | Archives liquidation record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Liquidation engine | (external) | EXEC | Called when liquidation completes |
| Trade.CIDsInLiquidationAdd | (paired) | INSERT | Adds the CID that this procedure removes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CIDsInLiquidationRemove (procedure)
+-- Customer.CustomerMoney (table)
+-- Customer.SetBalanceDataFix (procedure)
+-- Trade.CIDsInLiquidation (table)
+-- History.CIDsInLiquidation (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | SELECT current balances |
| Customer.SetBalanceDataFix | Procedure | Balance recalculation |
| Trade.CIDsInLiquidation | Table | DELETE source |
| History.CIDsInLiquidation | Table | Archive target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Liquidation engine | External | Post-liquidation cleanup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Atomicity | Balance update + delete + archive are atomic |
| Nested transaction support | Pattern | @@TRANCOUNT check handles being called within outer transaction |
| THROW | Error propagation | Re-raises original error after rollback |

---

## 8. Sample Queries

### 8.1 Remove CID from liquidation

```sql
EXEC Trade.CIDsInLiquidationRemove @CID = 12345;
```

### 8.2 Check liquidation history

```sql
SELECT CID, StartTime, AccountLiquidationAcionTypeID, EndTime
FROM   History.CIDsInLiquidation WITH (NOLOCK)
WHERE  CID = 12345
ORDER BY StartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CIDsInLiquidationRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CIDsInLiquidationRemove.sql*
