# Trade.PositionAdjustmentAudit

> Audit table linking closed positions to their replacement positions after the position adjustment (close-and-reopen) process, used for rate corrections and corporate actions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint, PK) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (PK CLUSTERED) |

---

## 1. Business Meaning

**WHAT**: Trade.PositionAdjustmentAudit tracks the close-and-reopen pairs created by the position adjustment process (Trade.PositionAdjustment). When a position needs adjustment-for example, rate correction after a data error, corporate action handling, or manual operational fix-the original position is closed and a new position is opened to replace it. This table stores the mapping between the closed (old) position and the opened (new) position so the lineage is auditable and traceable.

**WHY**: Without this table, there would be no durable record linking the closed position to its replacement. Operations teams, support, and compliance need to trace why a position disappeared and where its replacement went. The adjustment process is rare (emergency corrections only); the live database contains only 2 rows, indicating this is used sparingly when manual or automated corrections are required.

**HOW**: Trade.PositionAdjustment (or related procedures) inserts a row into PositionAdjustmentAudit after successfully closing the original position and opening the replacement. Both ClosedPositionID and OpenedPositionID reference Trade.PositionTbl.PositionID. The table resides on the DICTIONARY filegroup, suited for low-volume reference data.

---

## 2. Business Logic

### 2.1 Close-and-Reopen Pair Recording

**What**: When the position adjustment process executes, it records the closed-to-opened position mapping.

**Columns/Parameters Involved**: ClosedPositionID, OpenedPositionID

**Rules**:
- ClosedPositionID: The PositionID of the position that was closed (StatusID=2). Must be unique (PK).
- OpenedPositionID: The PositionID of the replacement position that was opened. NULL if the new position was not yet created at insert time (unlikely in same transaction).
- Both IDs reference Trade.PositionTbl.PositionID.

### 2.2 Audit Trail Usage

**What**: Operators and support use this table to trace position corrections.

**Rules**:
- Query by ClosedPositionID to find the replacement position.
- Query by OpenedPositionID to find which closed position this one replaced.

---

## 3. Data Overview

| ClosedPositionID | OpenedPositionID | Meaning |
|------------------|------------------|---------|
| 2149665338 | 2149665597 | Original position 2149665338 was closed and replaced by 2149665597 |
| 2149676649 | 2149694308 | Original position 2149676649 was closed and replaced by 2149694308 |

**Selection criteria**: All rows in the table (2 rows total). The small row count indicates this process is rarely used-typically for emergency corrections only.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | PK. PositionID of the closed (original) position. References Trade.PositionTbl.PositionID. |
| 2 | OpenedPositionID | bigint | YES | - | CODE-BACKED | PositionID of the replacement (newly opened) position. References Trade.PositionTbl.PositionID. NULL if not yet populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | Trade.PositionTbl | Implicit | The closed position being replaced |
| OpenedPositionID | Trade.PositionTbl | Implicit | The replacement position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionAdjustment | INSERT | Writer | Inserts close-and-reopen pairs after adjustment |
| Trade.GetDataForPositionAdjustment | SELECT | Reader | May read for adjustment context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionAdjustmentAudit (table)
├── Trade.PositionTbl (implicit via ClosedPositionID, OpenedPositionID)
└── Trade.PositionAdjustment (procedure - writer)
```

### 6.1 Objects This Depends On

No explicit FKs. Implicit: Trade.PositionTbl (both columns reference PositionID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionAdjustment | Procedure | INSERT after close-and-reopen |
| Trade.GetDataForPositionAdjustment | Procedure | May SELECT for context |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (CLUSTERED) | CLUSTERED PK | ClosedPositionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | ClosedPositionID |

### 7.3 Filegroup

Table is on [DICTIONARY] filegroup.

---

## 8. Sample Queries

### 8.1 Find replacement for a closed position
```sql
SELECT pa.ClosedPositionID, pa.OpenedPositionID
FROM   Trade.PositionAdjustmentAudit pa WITH (NOLOCK)
WHERE  pa.ClosedPositionID = @ClosedPositionID;
```

### 8.2 Find which closed position was replaced by an open one
```sql
SELECT pa.ClosedPositionID, pa.OpenedPositionID
FROM   Trade.PositionAdjustmentAudit pa WITH (NOLOCK)
WHERE  pa.OpenedPositionID = @OpenedPositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Object: Trade.PositionAdjustmentAudit | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionAdjustmentAudit.sql*
