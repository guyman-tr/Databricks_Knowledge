# Trade.InstrumentRateSourceEdit

> Updates the Priority of a specific instrument rate source mapping in Trade.InstrumentRateSources, returning error code 60000 if the record does not exist.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentRateSourceID - ID of the rate source mapping to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentRateSourceEdit updates the Priority of an existing instrument rate source mapping. Priority controls which liquidity account is preferred when multiple rate sources are configured for the same instrument. A lower or higher priority number (depending on consumer convention) means the source is selected first. Adjusting priorities allows operations teams to reorder rate source preferences without removing and recreating mappings.

Without this procedure there would be no safe, transactional way to change rate source priorities. It validates existence before the UPDATE, preventing silent no-ops. It is also called internally by Trade.InstrumentRateSourceAdd when an existing mapping is found and only the Priority needs to change (upsert pattern).

Data flow: Operations tools identify the InstrumentRateSourceID (via Trade.GetInstrumentRateSources view) and the desired new Priority, then call this procedure. Trade.InstrumentRateSourceAdd also calls this procedure when a duplicate (same InstrumentID + LiquidityAccountID + PriceServerID) is detected - rather than failing, it treats the call as a Priority update.

---

## 2. Business Logic

### 2.1 Existence Check + Transactional Update

**What**: Validates existence then updates Priority in a transaction. Uses old-style @@ERROR error handling.

**Columns/Parameters Involved**: `@InstrumentRateSourceID`, `@Priority`

**Rules**:
- If InstrumentRateSourceID does NOT exist: RAISERROR 60000, RETURN 60000 (no transaction opened).
- If exists: BEGIN TRAN, UPDATE Priority, check @@ERROR.
  - @@ERROR = 0: COMMIT, RETURN 0.
  - @@ERROR != 0: ROLLBACK, RAISERROR 60000 (no explicit RETURN in this branch - falls through to END).
- Error code 60000 is the platform-standard instrument management error code.
- Uses @@ERROR (legacy pre-TRY/CATCH pattern), consistent with InstrumentRateSourceDelete.

**Diagram**:
```
@InstrumentRateSourceID, @Priority
    |
    v
Does InstrumentRateSourceID exist?
    |
    +--[NO]--> RAISERROR(60000) + RETURN 60000
    |
    +--[YES]--> BEGIN TRAN
                    UPDATE Trade.InstrumentRateSources
                    SET Priority = @Priority
                    WHERE InstrumentRateSourceID = @InstrumentRateSourceID
                        |
                        +--[@@ERROR = 0]---> COMMIT + RETURN 0
                        |
                        +--[@@ERROR != 0]--> ROLLBACK + RAISERROR(60000)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentRateSourceID | int | NO | - | CODE-BACKED | Primary key of the Trade.InstrumentRateSources row to update. Identifies the specific instrument-to-liquidity-account mapping whose priority is being changed. |
| 2 | @Priority | int | NO | - | CODE-BACKED | The new Priority value for this rate source. Controls selection order when multiple rate sources exist for the same instrument. Lower values typically indicate higher preference (confirm with consuming system). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXISTS check + UPDATE | Trade.InstrumentRateSources | Modifier | Validates and updates the Priority of the specified rate source mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentRateSourceAdd | EXEC InstrumentRateSourceEdit | Internal caller | Called when InstrumentRateSourceAdd detects an existing mapping and only Priority update is needed (upsert pattern) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentRateSourceEdit (procedure)
└── Trade.InstrumentRateSources (table) - EXISTS check + UPDATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentRateSources | Table | EXISTS check and UPDATE target (Priority column) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentRateSourceAdd | Stored Procedure | Calls Edit when duplicate (InstrumentID + LiquidityAccountID + PriceServerID) exists |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error code 60000 | Convention | Platform-standard error code for both "not found" and "update failed" conditions |
| @@ERROR pattern | Legacy | Pre-TRY/CATCH error handling. No RETURN statement in the @@ERROR!=0 branch (falls through) |

---

## 8. Sample Queries

### 8.1 Update priority for a rate source

```sql
DECLARE @RC INT;
EXEC @RC = Trade.InstrumentRateSourceEdit
    @InstrumentRateSourceID = 42,
    @Priority               = 1;
SELECT @RC AS ReturnCode;
-- 0 = success, 60000 = not found or update error
```

### 8.2 Find the InstrumentRateSourceID and current priority

```sql
SELECT
    irs.InstrumentRateSourceID,
    irs.InstrumentID,
    irs.LiquidityAccountID,
    irs.PriceServerID,
    irs.Priority
FROM Trade.InstrumentRateSources irs WITH (NOLOCK)
WHERE irs.InstrumentID = @InstrumentID
ORDER BY irs.Priority;
```

### 8.3 Verify updated priority

```sql
SELECT InstrumentRateSourceID, Priority
FROM Trade.InstrumentRateSources WITH (NOLOCK)
WHERE InstrumentRateSourceID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentRateSourceEdit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InstrumentRateSourceEdit.sql*
