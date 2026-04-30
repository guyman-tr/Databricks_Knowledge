# Trade.SetInstrumentSlippage

> Bulk-updates the slippage and unit quantity type configuration for a set of trading instruments in the provider-instrument mapping table, with optional ops-user audit context.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Instruments_NewSlippage (TVP of InstrumentIDs to update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates slippage and unit quantity type settings for one or more trading instruments simultaneously. Slippage defines the tolerated price deviation between the order rate and the execution rate on the hedge/liquidity provider side. Operations teams use this procedure to adjust execution tolerances for specific instruments — for example, widening slippage during volatile market conditions or after instrument configuration changes.

The procedure exists to provide a safe, validated batch operation for changing slippage. Without it, direct table updates could incorrectly target instruments that are not mapped to any provider, creating orphaned configuration entries. The validation guard ensures only legitimate provider-instrument pairs are modified.

When called, it sets CONTEXT_INFO to the caller's login name (enabling audit triggers to attribute changes), validates that every InstrumentID in the input TVP has a corresponding row in Trade.ProviderToInstrument, then performs a single bulk UPDATE on matching rows. If the new UnitsQuantityType is NULL for a given instrument, the existing value is preserved (ISNULL fallback). This procedure is referenced in the Trading Opstool API (Per Confluence: Trading Opstool API TDD).

---

## 2. Business Logic

### 2.1 Audit Context via CONTEXT_INFO

**What**: Embeds the operator login name into the SQL connection's context, enabling audit-aware triggers to capture who made the change.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- If `@AppLoginName` is not empty, it is CAST to VARBINARY(128) and SET as CONTEXT_INFO for the session
- CONTEXT_INFO is read by audit triggers (if any) on Trade.ProviderToInstrument
- Passing `@AppLoginName = ''` (the default) skips context assignment - used for automated/system calls

**Diagram**:
```
Caller provides @AppLoginName
  |
  +-- '' (empty) ---------> CONTEXT_INFO unchanged (system call)
  |
  +-- 'ops.user@...' -----> CONTEXT_INFO = CAST(@AppLoginName AS VARBINARY(128))
                             -> Audit triggers can capture this identity
```

### 2.2 Instrument Validation Before Update

**What**: Validates that every InstrumentID in the input TVP exists in Trade.ProviderToInstrument before any update is attempted.

**Columns/Parameters Involved**: `@Instruments_NewSlippage.InstrumentID`, `Trade.ProviderToInstrument.InstrumentID`

**Rules**:
- Uses an INNER JOIN with a NULL check on ProviderToInstrument.InstrumentID to detect missing entries
- If ANY instrument is missing, RAISERROR(60127, 16, 1) is raised and the procedure returns immediately
- No partial updates occur - the entire batch is rejected if one ID is invalid

**Diagram**:
```
@Instruments_NewSlippage (TVP)
  INNER JOIN Trade.ProviderToInstrument ON InstrumentID
  WHERE PTI.InstrumentID IS NULL  <-- catches left-only rows (missing in PTI)
    |
    +-- EXISTS? --> RAISERROR(60127) "One or more InstrumentIDs not found"
    |
    +-- NOT EXISTS? --> Proceed to UPDATE
```

### 2.3 Selective UnitsQuantityType Preservation

**What**: Allows partial updates where only Slippage is changed without overwriting UnitsQuantityType.

**Columns/Parameters Involved**: `UnitsQuantityType` in TVP and in `Trade.ProviderToInstrument`

**Rules**:
- `ISNULL(src.UnitsQuantityType, dest.UnitsQuantityType)` - if the TVP row has NULL for UnitsQuantityType, the existing value in the table is kept
- Both Slippage and UnitsQuantityType are always SET in the UPDATE statement, but UnitsQuantityType is effectively a no-op when NULL is passed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instruments_NewSlippage | Trade.InstrumentsIDListSetSlippageTbl | NO | - | CODE-BACKED | Table-valued parameter containing the list of instruments to update. Each row contains InstrumentID, Slippage, and optionally UnitsQuantityType. The READONLY modifier prevents the procedure from modifying the TVP. |
| 2 | @AppLoginName | varchar(50) | YES | '' | CODE-BACKED | Operations user login name for audit trail. When non-empty, is encoded as VARBINARY(128) and set as CONTEXT_INFO for the session. Audit triggers can read this to attribute the change. Pass empty string for system/automated calls. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Instruments_NewSlippage | Trade.InstrumentsIDListSetSlippageTbl | Type dependency | TVP type defining the input schema (InstrumentID, Slippage, UnitsQuantityType) |
| InstrumentID (via TVP) | Trade.ProviderToInstrument | Lookup / Modifier | Validates existence then updates Slippage and UnitsQuantityType for matching instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading Opstool API | - | CALLER | Used by ops tooling to configure instrument slippage (Per Confluence: Trading Opstool API TDD) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetInstrumentSlippage (procedure)
├── Trade.InstrumentsIDListSetSlippageTbl (type) [TVP schema]
└── Trade.ProviderToInstrument (table) [validated + updated]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentsIDListSetSlippageTbl | User Defined Type (TVP) | Defines the input table structure for @Instruments_NewSlippage |
| Trade.ProviderToInstrument | Table | Validated (all InstrumentIDs must exist) then updated (Slippage, UnitsQuantityType) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading Opstool API | External service | Calls this procedure to update instrument slippage settings |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Instrument existence check | Business validation | RAISERROR(60127) if any InstrumentID in TVP is not found in Trade.ProviderToInstrument |

---

## 8. Sample Queries

### 8.1 Execute slippage update for a single instrument

```sql
DECLARE @inputs Trade.InstrumentsIDListSetSlippageTbl;
INSERT INTO @inputs (InstrumentID, Slippage, UnitsQuantityType)
VALUES (1001, 5, NULL); -- NULL preserves existing UnitsQuantityType

EXEC Trade.SetInstrumentSlippage
    @Instruments_NewSlippage = @inputs,
    @AppLoginName = 'ops.admin@etoro.com';
```

### 8.2 Bulk-update slippage for multiple instruments

```sql
DECLARE @inputs Trade.InstrumentsIDListSetSlippageTbl;
INSERT INTO @inputs (InstrumentID, Slippage, UnitsQuantityType)
VALUES (1001, 5, 1),
       (1002, 10, 2),
       (1003, 3, 1);

EXEC Trade.SetInstrumentSlippage
    @Instruments_NewSlippage = @inputs,
    @AppLoginName = 'ops.admin@etoro.com';
```

### 8.3 Verify current slippage values after update

```sql
SELECT pti.InstrumentID, pti.Slippage, pti.UnitsQuantityType
FROM Trade.ProviderToInstrument pti WITH (NOLOCK)
WHERE pti.InstrumentID IN (1001, 1002, 1003);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Opstool API TDD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/) | Confluence | SetInstrumentSlippage is referenced as an endpoint in the Trading Operations API for managing instrument slippage |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetInstrumentSlippage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetInstrumentSlippage.sql*
