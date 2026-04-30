# Trade.CidToMirrorIdElad

> A memory-optimized table-valued parameter type mapping CID to MirrorID with a composite primary key. An optimized variant of CidToMirrorId for high-throughput scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID, MirrorID (composite PK) |
| **Partition** | N/A |
| **Indexes** | 1 (PK nonclustered) |

---

## 1. Business Meaning

Trade.CidToMirrorIdElad is a memory-optimized table-valued parameter (TVP) type that pairs Customer IDs with Mirror IDs - the same conceptual pairing as Trade.CidToMirrorId. The "Elad" suffix indicates a developer-created optimized variant. Memory-optimized TVPs reduce latch contention and improve throughput when large batches are passed frequently.

This type exists for high-throughput scenarios where the standard CidToMirrorId disk-based TVP would become a bottleneck. Memory-optimized TVPs are ideal for procedures that process many CID-mirror pairs in rapid succession.

No direct procedure references were found via grep - this type may be used in development, test, or memory-optimized (MOT) procedures not yet discovered, or it may be a prepared optimization for future migration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The composite PK enforces uniqueness on (CID, MirrorID) pairs; duplicate pairs are rejected at INSERT time.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - the primary account identifier. Paired with MirrorID to identify a copy-trade relationship. |
| 2 | MirrorID | int | NO | - | CODE-BACKED | Mirror ID - identifies a specific copy-trade relationship. Composite PK with CID prevents duplicate CID-mirror pairs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID and MirrorID semantically reference customer and mirror entities; no declared FKs on the type.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No direct procedure references found via grep; likely used in MOT or internal procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found via grep.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CidToMirrorIdElad | NC PK | CID, MirrorID | - | - | Active |

Nonclustered primary key on (CID, MirrorID). Memory-optimized types use nonclustered indexes only.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CidToMirrorIdElad | PRIMARY KEY | Enforces unique (CID, MirrorID) pairs; rejects duplicates |

---

## 8. Sample Queries

### 8.1 Declare and populate memory-optimized CidToMirrorIdElad

```sql
DECLARE @Pairs Trade.CidToMirrorIdElad;
INSERT INTO @Pairs (CID, MirrorID) VALUES (12345, 100), (12345, 101), (67890, 200);
-- Use with MOT-compatible procedure when available
```

### 8.2 Build from positions (ensure no duplicates for PK)

```sql
DECLARE @CidMirrors Trade.CidToMirrorIdElad;
INSERT INTO @CidMirrors (CID, MirrorID)
SELECT  DISTINCT CID, MirrorID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   MirrorID IS NOT NULL;
```

### 8.3 Single pair for testing

```sql
DECLARE @Pair Trade.CidToMirrorIdElad;
INSERT INTO @Pair (CID, MirrorID) VALUES (50001, 42);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CidToMirrorIdElad | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CidToMirrorIdElad.sql*
