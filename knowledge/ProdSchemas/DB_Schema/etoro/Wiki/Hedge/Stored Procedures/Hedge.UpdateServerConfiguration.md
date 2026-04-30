# Hedge.UpdateServerConfiguration

> Upserts a hedge server's operational configuration: updates existing settings with partial overrides (NULL = keep current), or inserts a new row with all-zero defaults for new servers.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ServerID (PK of Hedge.ServerConfiguration) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.UpdateServerConfiguration` is the **upsert writer** for `Hedge.ServerConfiguration` - the table that governs how each hedge server instance executes orders and calculates exposure. Dealing Room operators or configuration management tools call this procedure to change individual settings on a running hedge server without disrupting other configuration values.

The procedure exists because `Hedge.ServerConfiguration` drives critical hedge server behaviors: whether the server auto-executes orders or holds them for manual review (`AutoExecutionMode`), which algorithm it uses for order execution (`ExecutionStrategy`), and how it measures and reports exposure (`ExposureStrategy`, `ExposureMode`, `ConvertToMajors`). These settings need to be updatable at runtime with granular control - changing one flag should not risk overwriting another.

Data flows through this object as follows: the caller passes a `@ServerID` and one or more configuration values (any combination, others left NULL). For existing servers, only the non-NULL parameters are applied. For new servers not yet in the table, a new row is inserted with 0 as the default for any NULL parameter. The procedure wraps in TRY/CATCH and re-throws errors to the caller.

---

## 2. Business Logic

### 2.1 Partial Update Pattern (NULL = Keep Existing)

**What**: All configuration parameters are optional (default NULL). NULL means "leave unchanged"; non-NULL means "override."

**Columns/Parameters Involved**: `@AutoExecutionMode`, `@ExposureStrategy`, `@ConvertToMajors`, `@ExposureMode`, `@ExecutionStrategy`

**Rules**:
- Each column in the UPDATE uses `CASE WHEN @Param IS NULL THEN ExistingValue ELSE @Param END`.
- Passing only `@ExecutionStrategy = 1` changes only ExecutionStrategy; all other columns remain untouched.
- On INSERT (new server), NULL parameters default to 0 (all fields): `CASE WHEN @Param IS NULL THEN 0 ELSE @Param END`.
- This means an INSERT with all NULLs creates a valid row with all zeros - the minimum viable configuration.

**Diagram**:
```
UPDATE path (server exists):
  @AutoExecutionMode = NULL  -> AutoExecutionMode unchanged
  @ExposureMode      = 2     -> ExposureMode updated to 2 (Portfolio)
  @ExecutionStrategy = 1     -> ExecutionStrategy updated to 1 (Smart)

INSERT path (new server):
  @AutoExecutionMode = NULL  -> AutoExecutionMode = 0 (default)
  @ExecutionStrategy = NULL  -> ExecutionStrategy = 0 (Normal)
```

### 2.2 IF EXISTS UPSERT Logic

**What**: The procedure uses IF EXISTS to decide whether to UPDATE or INSERT.

**Columns/Parameters Involved**: `@ServerID`

**Rules**:
- `IF EXISTS (SELECT 1 FROM Hedge.ServerConfiguration WHERE ServerID = @ServerID)` - determines UPDATE vs INSERT path.
- UPDATE path: updates all 5 configurable columns using the partial-update CASE logic.
- INSERT path: inserts all columns including ServerID using the default-zero CASE logic.
- No MERGE statement - this is a classic hand-coded upsert.

### 2.3 Configuration Semantics

**What**: The five configurable columns control distinct hedge server behaviors.

**Columns/Parameters Involved**: `@AutoExecutionMode`, `@ExposureStrategy`, `@ExposureMode`, `@ConvertToMajors`, `@ExecutionStrategy`

**Rules**:
- `AutoExecutionMode`: 0 = auto-execute hedge orders, non-zero = manual/semi-manual. No Dictionary FK.
- `ExposureStrategy`: No Dictionary FK. Numeric enum. Exact values defined externally.
- `ExposureMode` (FK to Dictionary.HedgeServerExposureMode): 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode.
- `ExecutionStrategy` (FK to Dictionary.HedgeServerExecutionStrategy): 0=Normal, 1=Smart execution algorithm.
- `ConvertToMajors` (BIT): 0=off, 1=decompose minor FX pairs into their major-pair components before hedging.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ServerID | INT | NO | - | CODE-BACKED | PK of Hedge.ServerConfiguration. Identifies which hedge server's configuration is being upserted. Implicit FK to Trade.HedgeServer.HedgeServerID. |
| 2 | @AutoExecutionMode | INT | YES | NULL | CODE-BACKED | Controls order execution mode. NULL = keep existing (UPDATE) or default to 0 (INSERT). 0=automatic execution (hedge orders sent to LP immediately). Non-zero = manual/semi-manual mode requiring dealing desk action. No Dictionary FK. |
| 3 | @ExposureStrategy | INT | YES | NULL | CODE-BACKED | Controls how the server aggregates and measures exposure. NULL = keep existing or default to 0. No Dictionary FK - values defined externally. |
| 4 | @ConvertToMajors | BIT | YES | NULL | CODE-BACKED | Controls whether minor FX cross pairs (e.g., EUR/JPY) are decomposed into major-pair equivalents (EUR/USD, USD/JPY) for hedging. NULL = keep existing or default to 0 (off). 1=enabled. |
| 5 | @ExposureMode | INT | YES | NULL | CODE-BACKED | Exposure calculation regime. FK to Dictionary.HedgeServerExposureMode. NULL = keep existing or default to 0. 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode. |
| 6 | @ExecutionStrategy | INT | YES | NULL | CODE-BACKED | Order execution algorithm. FK to Dictionary.HedgeServerExecutionStrategy. NULL = keep existing or default to 0. 0=Normal, 1=Smart (algorithmic execution). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ServerID | Trade.HedgeServer | Lookup | Identifies which hedge server is being configured |
| @ExposureMode | Dictionary.HedgeServerExposureMode | Lookup | Valid values: 0=Normal, 1=Major, 2=Portfolio, 3=SpotExposureMode (validated via FK on table) |
| @ExecutionStrategy | Dictionary.HedgeServerExecutionStrategy | Lookup | Valid values: 0=Normal, 1=Smart (validated via FK on table) |
| (UPDATE/INSERT target) | Hedge.ServerConfiguration | MODIFIER + WRITER | Upserts the server's configuration row |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by configuration management tools or the hedge server startup process.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.UpdateServerConfiguration (procedure)
+-- Hedge.ServerConfiguration (table) [MODIFIER + WRITER]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ServerConfiguration | Table | IF EXISTS check; UPDATE (existing rows) or INSERT (new rows) |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error handling | Re-throws original error to caller; no rollback logic (single-statement UPDATE/INSERT, implicitly transactional) |
| NULL = keep existing / default 0 | Partial update semantics | Every configurable parameter is nullable; NULL has different meanings for UPDATE (preserve) vs INSERT (zero default) |

---

## 8. Sample Queries

### 8.1 Enable smart execution for server 1 (change only ExecutionStrategy)
```sql
EXEC [Hedge].[UpdateServerConfiguration]
    @ServerID          = 1,
    @ExecutionStrategy = 1; -- Smart; all other params NULL (keep existing)
```

### 8.2 Set all configuration values for a new server
```sql
EXEC [Hedge].[UpdateServerConfiguration]
    @ServerID            = 5,
    @AutoExecutionMode   = 0,
    @ExposureStrategy    = 0,
    @ConvertToMajors     = 0,
    @ExposureMode        = 0,
    @ExecutionStrategy   = 0;
```

### 8.3 Verify current configuration after update
```sql
SELECT  ServerID,
        AutoExecutionMode,
        ExposureStrategy,
        ConvertToMajors,
        ExposureMode,
        ExecutionStrategy
FROM    [Hedge].[ServerConfiguration] WITH (NOLOCK)
WHERE   ServerID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.UpdateServerConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.UpdateServerConfiguration.sql*
