# Trade.DesignatedExecutionSystemUpdate

> Table-valued parameter for bulk-updating the designated execution system per instrument, controlling order routing (internal engine, DMA, or liquidity provider).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (Primary Key) |
| **Partition** | N/A |
| **Indexes** | 1 clustered (PK on InstrumentID) |

---

## 1. Business Meaning

Trade.DesignatedExecutionSystemUpdate is a TVP for bulk-updating which execution system handles each instrument. The DesignatedExecutionSystem value determines order routing - whether orders go through the internal matching engine, direct market access (DMA), or a specific liquidity provider. This is critical for compliance, cost control, and execution quality.

The type exists to support Trade.UpdateDesignatedExecutionSystemBulk, which applies many instrument-to-execution-system assignments in one call. Without it, each instrument would require a separate UPDATE, increasing latency and transaction overhead.

Configuration or admin processes load instrument-to-system mappings (e.g., from config files or operator input), populate this TVP, and pass it to UpdateDesignatedExecutionSystemBulk. The PK on InstrumentID ensures one assignment per instrument; IGNORE_DUP_KEY = OFF causes duplicate InstrumentIDs to fail the operation.

---

## 2. Business Logic

### 2.1 One Execution System Per Instrument

**What**: Each instrument has exactly one designated execution system.

**Columns/Parameters Involved**: `InstrumentID`, `DesignatedExecutionSystem`

**Rules**:
- InstrumentID is the primary key - one row per instrument in the TVP
- DesignatedExecutionSystem (tinyint) encodes the routing destination
- IGNORE_DUP_KEY = OFF ensures duplicates in the TVP cause a clear error rather than silent overwrite

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument whose execution system is being updated. Primary key - one row per instrument. Links to Dictionary.InstrumentTbl. |
| 2 | DesignatedExecutionSystem | tinyint | NO | - | CODE-BACKED | Execution system identifier. Determines order routing: internal matching engine, DMA, or specific liquidity provider. Value map would be in a lookup/dictionary table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Dictionary.InstrumentTbl | Implicit | Instrument identifier |
| DesignatedExecutionSystem | Lookup/dictionary | Implicit | Execution system routing code |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateDesignatedExecutionSystemBulk | Parameter (TVP) | Parameter (TVP) | Receives instrument-to-system mappings for bulk UPDATE |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateDesignatedExecutionSystemBulk | Stored Procedure | READONLY parameter for bulk UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (clustered) | CLUSTERED | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | InstrumentID - one execution system per instrument. IGNORE_DUP_KEY = OFF. |

---

## 8. Sample Queries

### 8.1 Bulk update execution system for multiple instruments

```sql
DECLARE @Updates Trade.DesignatedExecutionSystemUpdate;
INSERT INTO @Updates (InstrumentID, DesignatedExecutionSystem)
VALUES (100, 1), (101, 2), (102, 1);

EXEC Trade.UpdateDesignatedExecutionSystemBulk @Updates = @Updates;
```

### 8.2 Update from a query (e.g., all crypto to DMA)

```sql
DECLARE @Updates Trade.DesignatedExecutionSystemUpdate;
INSERT INTO @Updates (InstrumentID, DesignatedExecutionSystem)
SELECT  InstrumentID, 2
FROM    Dictionary.InstrumentTbl WITH (NOLOCK)
WHERE   InstrumentTypeID = 5;

EXEC Trade.UpdateDesignatedExecutionSystemBulk @Updates = @Updates;
```

### 8.3 Single instrument update

```sql
DECLARE @Updates Trade.DesignatedExecutionSystemUpdate;
INSERT INTO @Updates (InstrumentID, DesignatedExecutionSystem) VALUES (200, 1);
EXEC Trade.UpdateDesignatedExecutionSystemBulk @Updates = @Updates;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DesignatedExecutionSystemUpdate | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DesignatedExecutionSystemUpdate.sql*
