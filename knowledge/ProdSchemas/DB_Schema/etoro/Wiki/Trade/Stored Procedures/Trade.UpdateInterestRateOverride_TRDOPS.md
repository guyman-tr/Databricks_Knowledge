# Trade.UpdateInterestRateOverride_TRDOPS

> Set-based MERGE upsert of instrument-specific interest rate overrides into Dictionary.InterestRateOverride using a TRDOPS V2 TVP that includes SettlementTypeID and OverNightFeePatternID directly, replacing the cursor-based UpdateInterestRateOverride; sentinel value -1 signals insert-only intent.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateInterestRateOverrideTbl.(InterestRateOverrideID OR (InstrumentID, ExchangeID, InstrumentTypeID)) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the current, preferred procedure for managing per-instrument interest rate overrides. It replaces Trade.UpdateInterestRateOverride (cursor-based, backward-compat version) with a clean set-based MERGE approach. Key differences from the legacy version:

1. **SettlementTypeID passed directly** by the caller - no internal derivation from InstrumentGroups
2. **OverNightFeePatternID supported** - a newer field that controls which overnight fee pattern applies to the override
3. **Sentinel value -1** for InterestRateOverrideID signals "insert regardless of existence" (treated as NULL in the MERGE key)
4. **Validation guard**: Raises an error if any non-null, non-(-1) InterestRateOverrideID doesn't exist in the table
5. **Set-based MERGE** instead of row-by-row cursor

No internal SP callers were found. Called directly from TRDOPS (Trading Operations) rate management tooling.

---

## 2. Business Logic

### 2.1 InterestRateOverrideID Validation

**What**: Before the MERGE, validates that all provided InterestRateOverrideIDs (non-null, non-(-1)) actually exist in Dictionary.InterestRateOverride. Raises an error if any are missing.

**Columns/Parameters Involved**: `InterestRateOverrideID`, `Dictionary.InterestRateOverride.InterestRateOverrideID`

**Rules**:
- Check: `WHERE t.InterestRateOverrideID IS NOT NULL AND t.InterestRateOverrideID <> -1 AND NOT EXISTS (SELECT 1 FROM Dictionary.InterestRateOverride WHERE InterestRateOverrideID = t.InterestRateOverrideID)`
- If any such IDs are missing -> RAISERROR with severity 16: 'One or more InterestRateOverrideID values to update do not exist.'
- This prevents silent update failures where a caller provides a stale or wrong ID

### 2.2 Sentinel -1 -> INSERT-Only Path

**What**: InterestRateOverrideID = -1 is a sentinel value meaning "no existing ID, always insert."

**Columns/Parameters Involved**: `InterestRateOverrideID`, `EffectiveID`

**Rules**:
- CTE: `EffectiveID = IIF(t.InterestRateOverrideID = -1, NULL, t.InterestRateOverrideID)`
- MERGE key: `ON (trg.InterestRateOverrideID = src.EffectiveID)`
- When EffectiveID = NULL, the ON condition is always false (NULL != anything) -> always hits WHEN NOT MATCHED -> INSERT
- Callers creating new overrides pass -1 to guarantee insert behavior without a pre-existence check

### 2.3 MERGE Upsert Logic

**What**: Set-based MERGE handles both update and insert paths atomically.

**Columns/Parameters Involved**: All rate fields + OverNightFeePatternID + SettlementTypeID

**Rules**:
- WHEN MATCHED (by InterestRateOverrideID): UPDATE 4 rate fields + OverNightFeePatternID + SettlementTypeID + UpdatedByUser
- WHEN NOT MATCHED BY TARGET: INSERT all fields including SettlementTypeID and OverNightFeePatternID
- @@ROWCOUNT after MERGE = total rows affected (updated + inserted) -> returned as @UpdateRowCount

**Diagram**:
```
Validation: any non-null non-(-1) IDs missing from table? -> RAISERROR
  |
  v
CTE: EffectiveID = IIF(ID = -1, NULL, ID)
  |
  MERGE ON (InterestRateOverrideID = EffectiveID)
    MATCHED     -> UPDATE 6 fields + UpdatedByUser
    NOT MATCHED -> INSERT all fields
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateInterestRateOverrideTbl | Trade.UpdateInterestRateOverrideTbl_TRDOPS (TVP, READONLY) | NO | - | CODE-BACKED | TRDOPS V2 TVP. Key fields: InterestRateOverrideID (int NULL - NULL or -1 = insert, other values = update by this ID; validated pre-MERGE), InstrumentID (int NULL), ExchangeID (int NULL), InstrumentTypeID (int NULL). Rate fields (decimal(18,8) NOT NULL): InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell. Additional: OverNightFeePatternID (tinyint NULL - overnight fee pattern reference), SettlementTypeID (tinyint NOT NULL - passed directly by caller; 0=standard CFD, 4=crypto TRS). |
| 2 | @AppLoginName | nvarchar(100) | NO | - | CODE-BACKED | Username or service name written to Dictionary.InterestRateOverride.UpdatedByUser on all affected rows. |
| 3 | @UpdateRowCount | int (OUTPUT) | NO | - | CODE-BACKED | @@ROWCOUNT from the MERGE statement - total rows inserted or updated. Zero if no rows matched and no new rows inserted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InterestRateOverrideID (validation) | Dictionary.InterestRateOverride | Lookup SELECT | Pre-MERGE validation that non-null non-(-1) IDs exist |
| (InterestRateOverrideID as MERGE key) | Dictionary.InterestRateOverride | MERGE (UPDATE/INSERT) | Upserts rate override rows; UPDATE on match, INSERT on not-match |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TRDOPS rate management tooling | Application call | Caller | No internal SP callers found; called from Trading Operations rate management system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInterestRateOverride_TRDOPS (procedure)
+-- Dictionary.InterestRateOverride (table) [validation SELECT + MERGE upsert]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRateOverride | Table | Validation SELECT (pre-MERGE check) + MERGE target (UPDATE + INSERT) |
| Trade.UpdateInterestRateOverrideTbl_TRDOPS | User Defined Type | TVP type for @UpdateInterestRateOverrideTbl; includes SettlementTypeID and OverNightFeePatternID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TRDOPS application | Application | Preferred procedure for interest rate override management; replaces UpdateInterestRateOverride |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Pre-MERGE validation | Guard | RAISERROR if any non-null non-(-1) InterestRateOverrideID not found in table |
| Sentinel -1 | Design | InterestRateOverrideID = -1 converted to NULL for MERGE key -> always inserts |
| Atomic transaction | TRY/CATCH | BEGIN TRAN / COMMIT wraps the full operation; RAISERROR inside CATCH on failure |
| ROLLBACK on error | Catch | RAISERROR re-raises without explicit ROLLBACK - transaction is abandoned on caller's side |
| SET NOCOUNT ON | Session | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Update an existing override by ID

```sql
DECLARE @Overrides [Trade].[UpdateInterestRateOverrideTbl_TRDOPS]
INSERT INTO @Overrides (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID,
                        InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell,
                        OverNightFeePatternID, SettlementTypeID)
VALUES (101, 1234, 5, 1, 0.02000000, 0.02000000, 0.00500000, 0.00500000, 1, 0)

DECLARE @RowCount int = 0
EXEC Trade.UpdateInterestRateOverride_TRDOPS
    @UpdateInterestRateOverrideTbl = @Overrides,
    @AppLoginName = 'trdops_admin',
    @UpdateRowCount = @RowCount OUTPUT

SELECT @RowCount AS RowsModified
```

### 8.2 Insert a new override (sentinel -1)

```sql
DECLARE @Overrides [Trade].[UpdateInterestRateOverrideTbl_TRDOPS]
INSERT INTO @Overrides (InterestRateOverrideID, InstrumentID, ExchangeID, InstrumentTypeID,
                        InterestRateBuy, InterestRateSell, MarkupBuy, MarkupSell,
                        OverNightFeePatternID, SettlementTypeID)
VALUES (-1, 5678, 10, 1, 0.03000000, 0.03000000, 0.00800000, 0.00800000, 2, 4)

DECLARE @RowCount int = 0
EXEC Trade.UpdateInterestRateOverride_TRDOPS
    @UpdateInterestRateOverrideTbl = @Overrides,
    @AppLoginName = 'trdops_admin',
    @UpdateRowCount = @RowCount OUTPUT
```

### 8.3 Check current overrides

```sql
SELECT
    iro.InterestRateOverrideID,
    iro.InstrumentID,
    iro.SettlementTypeID,
    iro.OverNightFeePatternID,
    iro.InterestRateBuy,
    iro.InterestRateSell
FROM Dictionary.InterestRateOverride iro WITH (NOLOCK)
WHERE iro.InstrumentID = 1234
ORDER BY iro.SettlementTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInterestRateOverride_TRDOPS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInterestRateOverride_TRDOPS.sql*
