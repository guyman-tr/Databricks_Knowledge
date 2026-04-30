# Trade.ValidateFeeInPercentageConfigurations

> Pre-insert validator for Trade.FeeInPercentageConfigurations that enforces 6 business rules preventing conflicting IsSettled / FeeOperationTypeID combinations for a given instrument/type/group scope.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID / @InstrumentTypeID / @GroupID + @FeeOperationTypeID + @IsSettled; reads Trade.FeeInPercentageConfigurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FeeInPercentageConfigurations stores fee-in-percentage configurations that apply to instruments by different scoping levels: individual instrument, instrument type, or instrument group. Each configuration row is also keyed by IsSettled (whether the fee applies to settled or non-settled positions) and FeeOperationTypeID (which operations the fee applies to - buy, sell, or ALL).

The problem this procedure solves is preventing conflicting configuration rows. Because the fee lookup logic follows a hierarchical precedence and because NULL vs. specific values and "ALL operations" vs. "specific operation" combinations create logical conflicts, this procedure enforces 6 rules to ensure each new configuration row is unambiguous and non-conflicting.

This procedure is called by `Trade.FeeInPercentageConfigurationsTblValidate` which iterates over a TVP batch, calling this procedure for each proposed row before inserting it. Any violation causes a RAISERROR that propagates up to stop the entire batch.

---

## 2. Business Logic

### 2.1 Scope Matching (Exact NULL Handling)

**What**: Loads existing configurations for the same instrument/type/group scope to check for conflicts.

**Columns/Parameters Involved**: `@InstrumentID`, `@InstrumentTypeID`, `@GroupID`, `@tbl`

**Rules**:
- Each scope dimension (InstrumentID, InstrumentTypeID, GroupID) uses NULL-safe matching:
  - If input is NULL -> match only rows where column IS NULL
  - If input is non-NULL -> match rows where column = input value
- This means the validation checks the exact same scope level being inserted (not broader scopes)
- If @tbl is empty (no existing rows for this scope) -> skip all 6 rules (allow insert unconditionally)

### 2.2 Six Conflict Rules

**What**: 6 sequential ELSE-IF rules check for specific conflict conditions. First violation that matches triggers RAISERROR.

**Columns/Parameters Involved**: `@IsSettled`, `@FeeOperationTypeID`, `@FeeOperationAll = 3`

**FeeOperationTypeID values**: 1 = Buy only, 2 = Sell only, 3 = ALL operations

**Rules**:

| Rule | Condition | Error Message |
|------|-----------|---------------|
| 1 | Input IsSettled IS NULL AND existing row has IsSettled IS NOT NULL | "unable to set IsSettled NULL because non-NULL IsSettled already exists" |
| 2 | Input IsSettled IS NOT NULL AND existing row has IsSettled IS NULL | "unable to set specific IsSettled value because NULL IsSettled already exists" |
| 3 | Input FeeOperationTypeID=3 (ALL) AND existing row has same IsSettled AND FeeOperationTypeID != 3 | "unable to set FeeOperationTypeID 3 because specific FeeOperationTypeID with same IsSettled already exists" |
| 4 | Input FeeOperationTypeID != 3 AND existing row has same IsSettled AND FeeOperationTypeID = 3 (ALL) | "unable to set specific FeeOperationTypeID because FeeOperationTypeID 3 with same IsSettled already exists" |
| 5 | Input IsSettled IS NULL AND duplicate NULL: (input FeeOpType=3 AND existing NULL), OR (input FeeOpType!=3 AND existing NULL with same FeeOpType or FeeOpType=3) | "unable to set IsSettled NULL because configuration with NULL IsSettled already exists" |
| 6 | Input IsSettled IS NOT NULL AND existing row has same IsSettled AND (same FeeOperationTypeID OR existing FeeOperationTypeID=3) | "unable to set specific IsSettled value because same configuration already exists" |

**The core invariants being enforced**:
- You cannot mix NULL and non-NULL IsSettled for the same scope
- You cannot mix "ALL operations" (FeeOperationTypeID=3) with specific operations (1 or 2) for the same IsSettled value within the same scope
- You cannot insert an exact duplicate configuration

**Diagram**:
```
@tbl has existing rows for this scope?
  NO -> allow (skip all rules)
  YES ->
    Rule 1: NULL input + non-NULL exists?  -> RAISERROR
    Rule 2: non-NULL input + NULL exists?  -> RAISERROR
    Rule 3: ALL input + specific exists (same IsSettled)?  -> RAISERROR
    Rule 4: specific input + ALL exists (same IsSettled)?  -> RAISERROR
    Rule 5: NULL input + NULL exists (same or covering FeeOpType)? -> RAISERROR
    Rule 6: exact duplicate (same IsSettled + same/covering FeeOpType)? -> RAISERROR
    No rule fired -> allow
```

### 2.3 Error Format

**What**: Error messages include the full input parameter context for debugging.

**Columns/Parameters Involved**: `@errorPrefix`, `@fullErrorMessage`

**Rules**:
- @errorPrefix = "InstrumentID=X,InstrumentTypeID=Y,GroupID=Z,FeeOperationTypeID=N,IsSettled=N "
- Full error = @errorPrefix + specific rule violation message
- RAISERROR severity 16 (non-fatal to the server; terminates the procedure in the caller's catch block)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | YES | NULL | CODE-BACKED | The specific instrument ID for the proposed configuration. NULL means the configuration applies at the InstrumentType or Group level, not a specific instrument. Used in NULL-safe scope matching against Trade.FeeInPercentageConfigurations. |
| 2 | @InstrumentTypeID | int | YES | NULL | CODE-BACKED | The instrument type ID for the proposed configuration. NULL means not scoped to a type. Mutually exclusive with @InstrumentID in practice (a row typically scopes to one level). |
| 3 | @GroupID | int | YES | NULL | CODE-BACKED | The instrument group ID for the proposed configuration. NULL means not scoped to a group. The three scope dimensions (InstrumentID, InstrumentTypeID, GroupID) define the specificity level of the fee configuration. |
| 4 | @FeeOperationTypeID | tinyint | NO | - | CODE-BACKED | Fee operation type being inserted. 1=Buy only, 2=Sell only, 3=ALL operations. The value 3 (ALL) conflicts with specific values (1 or 2) for the same IsSettled - Rules 3 and 4 prevent this combination. |
| 5 | @IsSettled | bit | YES | - | CODE-BACKED | Whether this configuration applies to settled (1) or non-settled (0) positions, or both (NULL). NULL and non-NULL values cannot coexist for the same scope (Rules 1 and 2). |

**Return values:**
- No RETURN value. Either succeeds silently (no error) or raises an error via RAISERROR severity 16.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Conflict check | Trade.FeeInPercentageConfigurations | Reader | Reads existing rows for the same scope (InstrumentID/TypeID/GroupID combination) to check for conflicts |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FeeInPercentageConfigurationsTblValidate | EXEC per row | Caller | Iterates a TVP of proposed configurations, calling this procedure for each row; propagates any RAISERROR via THROW |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateFeeInPercentageConfigurations (procedure)
└── Trade.FeeInPercentageConfigurations (table - conflict check source)

Trade.FeeInPercentageConfigurationsTblValidate -> Trade.ValidateFeeInPercentageConfigurations
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeInPercentageConfigurations | Table | Reads existing configurations for the same scope to validate against the 6 conflict rules |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeInPercentageConfigurationsTblValidate | Stored Procedure | Batch validator that calls this procedure once per row in the input TVP |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL-safe scope matching | Business logic | Each of the three scope dimensions uses `(@param IS NULL AND col IS NULL) OR col = @param` to precisely match the same scope level being inserted |
| ELSE-IF chain | Business logic | Rules are evaluated in sequence; only the first triggered rule raises an error. Rules are mutually exclusive in their pre-conditions. |
| FeeOperationTypeID=3 means ALL | Business logic | Hardcoded @FeeOperationAll = 3 constant. FeeOperationTypeID 3 conflicts with 1 or 2 for the same IsSettled value (Rules 3 and 4). |
| RAISERROR severity 16 | Design | Non-fatal to the SQL Server instance but terminates the current batch/procedure in the caller. Caller's TRY/CATCH should handle it with THROW to propagate. |

---

## 8. Sample Queries

### 8.1 View existing fee-in-percentage configurations

```sql
SELECT
    InstrumentID,
    InstrumentTypeID,
    GroupID,
    FeeOperationTypeID,
    IsSettled,
    FeePercentage
FROM Trade.FeeInPercentageConfigurations WITH (NOLOCK)
ORDER BY InstrumentID, InstrumentTypeID, GroupID, FeeOperationTypeID
```

### 8.2 Test the validator directly (should succeed - new scope)

```sql
-- Test: validate a new configuration for InstrumentTypeID=10 (Crypto), ALL operations, settled
EXEC Trade.ValidateFeeInPercentageConfigurations
    @InstrumentID = NULL,
    @InstrumentTypeID = 10,
    @GroupID = NULL,
    @FeeOperationTypeID = 3,   -- ALL
    @IsSettled = 1
-- No output = success; RAISERROR output = conflict
```

### 8.3 Find configurations that would conflict with a new ALL-operations entry

```sql
-- Check if adding FeeOperationTypeID=3 would conflict for InstrumentTypeID=10
SELECT
    InstrumentID,
    InstrumentTypeID,
    GroupID,
    FeeOperationTypeID,
    IsSettled
FROM Trade.FeeInPercentageConfigurations WITH (NOLOCK)
WHERE InstrumentTypeID = 10
  AND InstrumentID IS NULL
  AND GroupID IS NULL
  AND FeeOperationTypeID <> 3  -- would conflict with ALL (Rule 3)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (FeeInPercentageConfigurationsTblValidate) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateFeeInPercentageConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ValidateFeeInPercentageConfigurations.sql*
