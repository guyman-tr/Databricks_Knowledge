# Trade.ValidateFixPerLotConfigurations

> Pre-insert validator for Trade.FixPerLotConfigurations that enforces the same 6 business rules as ValidateFeeInPercentageConfigurations, preventing conflicting IsSettled / FeeOperationTypeID combinations for a given instrument/type/group scope.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID / @InstrumentTypeID / @GroupID + @FeeOperationTypeID + @IsSettled; reads Trade.FixPerLotConfigurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the structural twin of `Trade.ValidateFeeInPercentageConfigurations`, but targets `Trade.FixPerLotConfigurations` instead of `Trade.FeeInPercentageConfigurations`. Where fee-in-percentage configurations express fees as a percentage of trade value, fix-per-lot configurations express fees as a fixed amount per lot (unit). Both fee tables use the same dimensional structure (InstrumentID / InstrumentTypeID / GroupID x IsSettled x FeeOperationTypeID), and both require the same 6-rule validation to prevent logical conflicts.

The procedure is called by `Trade.FixPerLotConfigurationsTblValidate` which iterates over a TVP batch, calling this procedure for each proposed row before inserting it. Any violation raises a RAISERROR that propagates up to stop the entire batch insert.

The logic, parameters, error messages, and rule set are identical to ValidateFeeInPercentageConfigurations. The only difference is the target table (FixPerLotConfigurations instead of FeeInPercentageConfigurations) in the scope-matching query.

---

## 2. Business Logic

### 2.1 Scope Matching (Exact NULL Handling)

**What**: Loads existing fix-per-lot configurations for the same instrument/type/group scope.

**Columns/Parameters Involved**: `@InstrumentID`, `@InstrumentTypeID`, `@GroupID`, `@tbl`

**Rules**:
- Each scope dimension uses NULL-safe matching: `(@param IS NULL AND col IS NULL) OR col = @param`
- Reads from Trade.FixPerLotConfigurations (not Trade.FeeInPercentageConfigurations)
- If no existing rows for this scope -> all 6 rules skipped (allow insert unconditionally)

### 2.2 Six Conflict Rules (Identical to ValidateFeeInPercentageConfigurations)

**What**: Same 6 sequential ELSE-IF rules as the percentage variant. First violation triggers RAISERROR.

**Columns/Parameters Involved**: `@IsSettled`, `@FeeOperationTypeID`, `@FeeOperationAll = 3`

**FeeOperationTypeID values**: 1 = Buy only, 2 = Sell only, 3 = ALL operations

**Rules**:

| Rule | Condition | Error |
|------|-----------|-------|
| 1 | Input IsSettled IS NULL + existing non-NULL IsSettled | RAISERROR - cannot mix NULL and non-NULL IsSettled |
| 2 | Input IsSettled IS NOT NULL + existing NULL IsSettled | RAISERROR - cannot mix NULL and non-NULL IsSettled |
| 3 | Input FeeOpType=3 (ALL) + existing specific FeeOpType (same IsSettled) | RAISERROR - ALL conflicts with specific op |
| 4 | Input specific FeeOpType + existing FeeOpType=3 (same IsSettled) | RAISERROR - specific op conflicts with ALL |
| 5 | Duplicate NULL IsSettled with same/covering FeeOpType | RAISERROR - duplicate NULL-scoped config |
| 6 | Exact duplicate (same IsSettled + same/covering FeeOpType) | RAISERROR - exact duplicate |

See `Trade.ValidateFeeInPercentageConfigurations` for the full rule documentation including diagrams - the logic is identical.

### 2.3 Error Format

**What**: Errors include the full parameter context for debugging.

**Rules**:
- @errorPrefix = "InstrumentID=X,InstrumentTypeID=Y,GroupID=Z,FeeOperationTypeID=N,IsSettled=N "
- RAISERROR severity 16

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | YES | NULL | CODE-BACKED | The specific instrument ID for the proposed fix-per-lot configuration. NULL means the configuration applies at the InstrumentType or Group level. Used in NULL-safe scope matching against Trade.FixPerLotConfigurations. |
| 2 | @InstrumentTypeID | int | YES | NULL | CODE-BACKED | The instrument type ID scope. NULL means not type-scoped. |
| 3 | @GroupID | int | YES | NULL | CODE-BACKED | The instrument group ID scope. NULL means not group-scoped. |
| 4 | @FeeOperationTypeID | tinyint | NO | - | CODE-BACKED | Fee operation type: 1=Buy only, 2=Sell only, 3=ALL. FeeOperationTypeID=3 conflicts with specific values (1 or 2) for the same IsSettled within the same scope. |
| 5 | @IsSettled | bit | YES | - | CODE-BACKED | Whether this fix-per-lot fee applies to settled (1), non-settled (0), or all (NULL) positions. NULL and non-NULL cannot coexist for the same scope. |

**Return values:**
- No RETURN value. Succeeds silently or raises RAISERROR severity 16.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Conflict check | Trade.FixPerLotConfigurations | Reader | Reads existing rows for the same scope to validate against the 6 conflict rules |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FixPerLotConfigurationsTblValidate | EXEC per row | Caller | Iterates a TVP of proposed fix-per-lot configurations, calling this procedure for each row; propagates any RAISERROR via THROW |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateFixPerLotConfigurations (procedure)
└── Trade.FixPerLotConfigurations (table - conflict check source)

Trade.FixPerLotConfigurationsTblValidate -> Trade.ValidateFixPerLotConfigurations
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurations | Table | Reads existing fix-per-lot configurations for the same scope to validate against the 6 conflict rules |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurationsTblValidate | Stored Procedure | Batch validator that calls this procedure once per row in the input TVP |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL-safe scope matching | Business logic | Same as ValidateFeeInPercentageConfigurations - each scope dimension uses `(@param IS NULL AND col IS NULL) OR col = @param` |
| ELSE-IF chain | Business logic | Rules evaluated sequentially; only the first triggered rule raises an error |
| FeeOperationTypeID=3 means ALL | Business logic | Constant @FeeOperationAll = 3. ALL conflicts with specific operations (Rules 3 and 4) |
| RAISERROR severity 16 | Design | Propagates as an error to the calling batch/procedure's CATCH block |

---

## 8. Sample Queries

### 8.1 View existing fix-per-lot configurations

```sql
SELECT
    InstrumentID,
    InstrumentTypeID,
    GroupID,
    FeeOperationTypeID,
    IsSettled
FROM Trade.FixPerLotConfigurations WITH (NOLOCK)
ORDER BY InstrumentID, InstrumentTypeID, GroupID, FeeOperationTypeID
```

### 8.2 Test the validator directly

```sql
-- Validate a new fix-per-lot config for InstrumentTypeID=10, Buy only (FeeOpType=1), non-settled
EXEC Trade.ValidateFixPerLotConfigurations
    @InstrumentID = NULL,
    @InstrumentTypeID = 10,
    @GroupID = NULL,
    @FeeOperationTypeID = 1,   -- Buy
    @IsSettled = 0
-- No output = success; RAISERROR = conflict detected
```

### 8.3 Find configurations that would conflict with a new entry

```sql
-- Check if FeeOperationTypeID=3 (ALL) would conflict for an instrument group
SELECT
    InstrumentID,
    InstrumentTypeID,
    GroupID,
    FeeOperationTypeID,
    IsSettled
FROM Trade.FixPerLotConfigurations WITH (NOLOCK)
WHERE GroupID = 5
  AND InstrumentID IS NULL
  AND InstrumentTypeID IS NULL
  AND FeeOperationTypeID <> 3  -- would conflict with ALL (Rule 3)
  AND IsSettled = 0             -- for the same IsSettled value
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (FixPerLotConfigurationsTblValidate) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateFixPerLotConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ValidateFixPerLotConfigurations.sql*
