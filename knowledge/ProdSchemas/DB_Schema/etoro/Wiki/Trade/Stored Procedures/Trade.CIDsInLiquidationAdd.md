# Trade.CIDsInLiquidationAdd

> Inserts a customer into the Trade.CIDsInLiquidation table to mark them as currently undergoing account liquidation with a specific action type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CIDsInLiquidationAdd marks a customer account as being in an active liquidation process. Account liquidation occurs when the system needs to force-close all of a customer's positions, typically due to insufficient margin (margin call), regulatory action, or account closure. The CIDsInLiquidation table acts as a semaphore: while a CID is present, no new positions can be opened and the liquidation engine processes the account.

The @LiquidationActionTypeID parameter distinguishes between different liquidation triggers (e.g., BSL liquidation, margin call, manual dealer action). StartTime is recorded as GETUTCDATE() to track how long the account has been in liquidation.

---

## 2. Business Logic

### 2.1 Liquidation Registration

**What**: Inserts a row into Trade.CIDsInLiquidation to flag the account.

**Columns/Parameters Involved**: `@CID`, `@LiquidationActionTypeID`, `GETUTCDATE()`

**Rules**:
- Direct INSERT, no duplicate check - relies on table constraints to prevent duplicates
- StartTime = GETUTCDATE() (UTC timestamp)
- Column name is AccountLiquidationAcionTypeID (typo for "ActionTypeID")

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to place into liquidation. |
| 2 | @LiquidationActionTypeID | INT | NO | - | CODE-BACKED | Type of liquidation action (e.g., BSL, margin call). Maps to AccountLiquidationAcionTypeID column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, @LiquidationActionTypeID | Trade.CIDsInLiquidation | INSERT | Registers account in liquidation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Liquidation engine | (external) | EXEC | Called when liquidation is triggered |
| Trade.CIDsInLiquidationRemove | (paired) | DELETE | Removes the CID when liquidation completes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CIDsInLiquidationAdd (procedure)
+-- Trade.CIDsInLiquidation (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CIDsInLiquidation | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Liquidation engine | External | Initiates liquidation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No duplicate protection | Risk | No IF NOT EXISTS check before INSERT; relies on table PK/UK |
| No transaction | Atomicity | Single INSERT, no explicit transaction needed |
| No error handling | Risk | No TRY/CATCH block |

---

## 8. Sample Queries

### 8.1 Add CID to liquidation

```sql
EXEC Trade.CIDsInLiquidationAdd @CID = 12345, @LiquidationActionTypeID = 1;
```

### 8.2 Check current liquidations

```sql
SELECT CID, StartTime, AccountLiquidationAcionTypeID
FROM   Trade.CIDsInLiquidation WITH (NOLOCK)
WHERE  CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CIDsInLiquidationAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CIDsInLiquidationAdd.sql*
