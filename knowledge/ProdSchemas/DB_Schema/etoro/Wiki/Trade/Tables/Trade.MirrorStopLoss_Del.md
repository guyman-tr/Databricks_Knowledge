# Trade.MirrorStopLoss_Del

> Minimal dump table for deleted mirror stop-loss configurations. "_Del" suffix = deletion/archive. MirrorID references Trade.Mirror. Amount is stop-loss dollar amount, Modification is deletion timestamp. No PK, no indexes. Used during one-time cleanup. Empty.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | None (no PK) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

Trade.MirrorStopLoss_Del is a minimal 3-column table whose "_Del" suffix indicates it stores records of deleted mirror stop-loss configurations. MirrorID references Trade.Mirror (the copy-trade table). Amount is the stop-loss dollar amount that was removed; Modification is when the deletion occurred. The table has no primary key, no indexes, and no constraints - a simple dump table used during a one-time cleanup of mirror stop-loss data. All columns are nullable. The live database reports EXISTS with 0 rows (empty).

This table exists as a staging/dump target when mirror stop-loss records were bulk-deleted or migrated. See Trade.Mirror for the main copy-trade table that tracks MirrorID relationships.

---

## 2. Business Logic

### 2.1 Deletion Dump

**What**: Temporary storage for mirror stop-loss records during cleanup. Each row = one deleted stop-loss config.

**Columns/Parameters Involved**: `MirrorID`, `Amount`, `Modification`

**Rules**:
- MirrorID maps to Trade.Mirror (copy relationship)
- Amount is the stop-loss dollar threshold that was removed
- Modification timestamp records when deletion occurred

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Live DB | EXISTS |
| Row count | 0 (empty) |
| Purpose | One-time cleanup dump |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | MirrorID | int | YES | - | FK to Trade.Mirror; copy relationship ID |
| 2 | Amount | money | YES | - | Stop-loss dollar amount that was deleted |
| 3 | Modification | datetime | YES | - | When the deletion occurred |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Implicit | Copy-trade relationship |

### 5.2 Referenced By

None in SSDT.

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | MirrorID implicitly references MirrorID |

### 6.2 Objects That Depend On This

None found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| (None) | - | - | No indexes in DDL |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| (None) | - | No constraints |

**Filegroup**: ON [PRIMARY]

---

*Generated: 2026-03-14 | Quality: 6.5/10*
*Object: Trade.MirrorStopLoss_Del | Type: Table | Cleanup dump table (empty)*
