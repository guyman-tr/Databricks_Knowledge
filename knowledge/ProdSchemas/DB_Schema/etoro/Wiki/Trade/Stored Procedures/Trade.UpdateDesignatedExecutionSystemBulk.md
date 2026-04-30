# Trade.UpdateDesignatedExecutionSystemBulk

> Bulk-updates the DesignatedExecutionSystem column in Trade.ProviderToInstrument for a batch of instruments, controlling order routing (internal engine vs. DMA vs. liquidity provider); sets CONTEXT_INFO for audit tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ValuesToUpdate (TVP - Trade.DesignatedExecutionSystemUpdate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateDesignatedExecutionSystemBulk controls which execution system handles orders for each instrument. The `DesignatedExecutionSystem` value in `Trade.ProviderToInstrument` determines the routing path for a trade: whether it goes through eToro's internal dealing engine, direct market access (DMA), or a specific liquidity provider. This is critical for execution quality, regulatory compliance (best execution requirements), and cost control.

The procedure exists for bulk configuration changes — when an operations team needs to reassign multiple instruments from one execution pathway to another in a single atomic operation. A typical scenario: migrating a batch of US stocks from DMA to a new liquidity provider, or enabling internal matching for a set of FX pairs.

The `@AuditUser` parameter is stored via `SET CONTEXT_INFO` — this stamps the SQL Server session context with the identity of the operator making the change, allowing audit triggers on `Trade.ProviderToInstrument` and `History.AuditHistory` to record who initiated the routing change. The MERGE only updates matched instruments (WHEN MATCHED THEN UPDATE) and silently skips InstrumentIDs not found in `Trade.ProviderToInstrument`.

---

## 2. Business Logic

### 2.1 Execution System Routing via DesignatedExecutionSystem

**What**: DesignatedExecutionSystem determines the order routing path for each instrument through each provider.

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.DesignatedExecutionSystem`, `@ValuesToUpdate.DesignatedExecutionSystem`

**Rules**:
- MERGE matches on InstrumentID: each instrument in the TVP updates the matching ProviderToInstrument row
- Only WHEN MATCHED is handled - instruments in the TVP not present in ProviderToInstrument are silently skipped (no INSERT for missing instruments)
- DesignatedExecutionSystem (tinyint) encodes the routing destination (values defined in application enumerations)
- History.AuditHistory captures the change with the operator identity from CONTEXT_INFO

### 2.2 Audit Trail via CONTEXT_INFO

**What**: The @AuditUser is stored in the SQL Server session CONTEXT_INFO varbinary, making it available to triggers for audit logging without requiring an extra column parameter in every UPDATE.

**Columns/Parameters Involved**: `@AuditUser`, SQL Server `CONTEXT_INFO()`

**Rules**:
- `SET @binaryUsername = CAST(@AuditUser AS varbinary(128))` - converts the varchar to binary
- `SET CONTEXT_INFO @binaryUsername` - writes to the session's CONTEXT_INFO slot
- Audit triggers on Trade.ProviderToInstrument read this value via `CONTEXT_INFO()` to record the operator who made the change
- Maximum @AuditUser length effectively limited to 128 bytes after CAST

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ValuesToUpdate | Trade.DesignatedExecutionSystemUpdate READONLY | NO | - | CODE-BACKED | TVP containing the batch of instruments to update. Each row: InstrumentID (PK, required), DesignatedExecutionSystem (tinyint, the routing system code to assign). One row per instrument. Instruments not found in Trade.ProviderToInstrument are silently skipped. |
| 2 | @AuditUser | VARCHAR(500) | NO | - | CODE-BACKED | Identity of the operator performing the bulk update (e.g., username or service account). Stored in SQL Server CONTEXT_INFO for the session duration, allowing audit triggers on Trade.ProviderToInstrument to record who made the routing change without requiring a dedicated audit column. Cast to varbinary(128) - values longer than 128 bytes are truncated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ValuesToUpdate | Trade.DesignatedExecutionSystemUpdate | TVP | Input parameter type defining the batch structure |
| MERGE target | Trade.ProviderToInstrument | Modifier | Updates DesignatedExecutionSystem for matched InstrumentIDs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. Invoked by operations tooling or admin scripts for bulk execution system reassignments.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateDesignatedExecutionSystemBulk (procedure)
+-- Trade.DesignatedExecutionSystemUpdate (TVP type)
+-- Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DesignatedExecutionSystemUpdate | User Defined Type (TVP) | Input parameter shape: InstrumentID + DesignatedExecutionSystem per row |
| Trade.ProviderToInstrument | Table | MERGE target - DesignatedExecutionSystem updated WHERE InstrumentID matches |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (operations tooling / admin scripts) | - | Invoked for bulk execution system routing changes per instrument |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. MERGE silently skips unmatched instruments (no WHEN NOT MATCHED clause).

---

## 8. Sample Queries

### 8.1 Update execution system for a batch of instruments
```sql
DECLARE @Updates Trade.DesignatedExecutionSystemUpdate;

INSERT INTO @Updates (InstrumentID, DesignatedExecutionSystem)
VALUES (1001, 2), (1002, 2), (1003, 3);

EXEC Trade.UpdateDesignatedExecutionSystemBulk
    @ValuesToUpdate = @Updates,
    @AuditUser      = 'ops.team@etoro.com';
```

### 8.2 Check current execution system for a set of instruments
```sql
SELECT pti.InstrumentID,
       pti.DesignatedExecutionSystem,
       im.InstrumentDisplayName
FROM   Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN   Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = pti.InstrumentID
WHERE  pti.InstrumentID IN (1001, 1002, 1003)
ORDER  BY pti.InstrumentID;
```

### 8.3 Audit recent DesignatedExecutionSystem changes
```sql
SELECT TOP 20 *
FROM   History.AuditHistory WITH (NOLOCK)
WHERE  TableName = 'ProviderToInstrument'
  AND  ColumnName = 'DesignatedExecutionSystem'
ORDER  BY OccurredAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateDesignatedExecutionSystemBulk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateDesignatedExecutionSystemBulk.sql*
