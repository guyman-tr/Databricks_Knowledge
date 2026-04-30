# Trade.SetBalanceOpenPosition_MOT

> A memory-optimized table-valued type used as an OUTPUT container for balance and equity values when opening positions, populated by Customer.SetBalanceOpenPosition from UPDATE OUTPUT clauses.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OldCredit (indexed) |
| **Partition** | N/A |
| **Indexes** | 1: IX_OldCredit (NONCLUSTERED on OldCredit) |

---

## 1. Business Meaning

Trade.SetBalanceOpenPosition_MOT is a memory-optimized table type used as an OUTPUT target when opening positions. Customer.SetBalanceOpenPosition updates Customer.CustomerMoney (credit, equity, bonus, BSL real funds) and captures the before/after values via OUTPUT INTO this type. The type holds NewCredit, OldCredit, RealizedEquity, TotalCash, BonusCredit, and BSLRealFunds - the balance snapshot for the open-position flow.

This type exists to support the open-position balance update. The procedure needs to pass balance deltas or snapshots to callers or downstream logic; the MOT type provides a structured OUTPUT target that persists for the duration of the call.

Customer.SetBalanceOpenPosition declares @Output Trade.SetBalanceOpenPosition_MOT and populates it from UPDATE ... OUTPUT. The memory-optimized design reduces locking and supports high-throughput open-position flows.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The type is a snapshot container; business rules are in the consuming procedure.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NewCredit | money | YES | - | CODE-BACKED | Credit balance after the open-position update. |
| 2 | OldCredit | money | YES | - | CODE-BACKED | Credit balance before the update. Indexed for lookups. |
| 3 | RealizedEquity | money | YES | - | CODE-BACKED | Realized equity after the update. |
| 4 | TotalCash | decimal(16, 8) | YES | - | CODE-BACKED | Total cash balance. |
| 5 | BonusCredit | money | YES | - | CODE-BACKED | Bonus credit portion. |
| 6 | BSLRealFunds | money | YES | - | CODE-BACKED | BSL (Bonus/Structured) real funds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Values semantically reflect Customer.CustomerMoney; no declared FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalanceOpenPosition | @Output | Local OUTPUT variable | Populated from UPDATE OUTPUT when opening positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceOpenPosition | Stored Procedure | OUTPUT variable for balance snapshot on open |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| IX_OldCredit | NONCLUSTERED | OldCredit ASC | Supports lookups by previous credit value |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 How SetBalanceOpenPosition populates the type

```sql
-- Inside Customer.SetBalanceOpenPosition, UPDATE ... OUTPUT populates @Output:
-- UPDATE Customer.CustomerMoney SET ... OUTPUT INSERTED.Credit, DELETED.Credit, ...
--   INTO @Output (NewCredit, OldCredit, RealizedEquity, TotalCash, BonusCredit, BSLRealFunds)
```

### 8.2 Inspect output after open (conceptual - call from app)

```sql
EXEC Customer.SetBalanceOpenPosition @CID = 12345, @Amount = -1000, ...;
-- @Output is internal; callers receive balance via OUTPUT params or result sets
```

### 8.3 Declare type for testing (structure only)

```sql
DECLARE @Output Trade.SetBalanceOpenPosition_MOT;
-- Populated by procedure internals, not by caller INSERT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetBalanceOpenPosition_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.SetBalanceOpenPosition_MOT.sql*
