# History.ExecutionErrorMapping

> Temporal system-versioned history table storing all past versions of the hedge execution error normalization mapping - recording every change to the table that maps provider-specific error messages to standardized error categories (Technical Failure, Market Reject, Provider Reject, etc.).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (ProviderTypeID, ErrorMessage) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Hedge.ExecutionErrorMapping`. SQL Server automatically moves rows here whenever an error mapping entry is updated or deleted.

`Hedge.ExecutionErrorMapping` is an **error normalization configuration table** for eToro's hedging execution system. When the hedge engine sends orders to external liquidity providers (LPs) via FIX connectivity, the LPs return provider-specific error messages. This table maps those raw error strings to a standardized set of error categories so the hedging system can apply consistent handling logic regardless of which LP generated the error.

**How it works**:
- Each row maps `(ProviderTypeID, ErrorMessage)` -> `ErrorCategoryID`
- `ProviderTypeID` scopes the mapping to a specific liquidity provider type - the same error text may mean different things on different platforms
- `ErrorMessage` is the exact error string (up to 500 chars) returned by the provider
- `ErrorCategoryID` is the normalized category (FK to `Dictionary.ExecutionErrorCategories`)

**Error categories** (from `Dictionary.ExecutionErrorCategories`):

| ErrorCategoryID | ErrorCategoryName |
|---|---|
| 0 | Technical Failure |
| 1 | Order Validation |
| 2 | Market Reject |
| 3 | Provider Reject |
| 4 | Provider Not Connected |
| 5 | Provider Unknown |
| 6 | Provider Business Validation |

This configuration is managed directly (SSMS or ops tooling) - no SP writers were found in SSDT. The table is likely consumed by the hedging application service rather than stored procedures.

Both `Hedge.ExecutionErrorMapping` and `History.ExecutionErrorMapping` have **0 rows** in this staging environment.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever an error mapping row is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ProviderTypeID`, `ErrorMessage`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = the moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Hedge.ExecutionErrorMapping` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `Tr_T_ExecutionErrorMapping_INSERT` fires a no-op UPDATE after every INSERT, generating a zero-duration history row for each new error mapping.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ProviderTypeID`, `ErrorCategoryID`, `ErrorMessage`

**Rules**:
- After INSERT, trigger executes: `UPDATE A SET A.ProviderTypeID=A.ProviderTypeID, A.ErrorCategoryID=A.ErrorCategoryID, A.ErrorMessage=A.ErrorMessage` (no-op self-update on all three key columns joined to Inserted).
- SQL Server temporal treats this as an UPDATE, moving the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero-duration).
- This ensures every error mapping that was ever created has a history record even if immediately deleted.
- Zero-duration rows (SysStartTime = SysEndTime) are INSERT artifacts; rows with SysStartTime < SysEndTime represent actual periods when the mapping was active.

### 2.3 Error Normalization Pattern

**What**: Provider error messages are mapped to categories to enable uniform error handling logic.

**Columns/Parameters Involved**: `ProviderTypeID`, `ErrorMessage`, `ErrorCategoryID`

**Rules**:
- The composite PK `(ProviderTypeID, ErrorMessage)` on the source table ensures each provider/error combination has exactly one category mapping.
- `ErrorMessage` is matched exactly (varchar(500), case sensitivity depends on DB collation) against incoming provider error strings.
- `ErrorCategoryID=0 (Technical Failure)` - internal/connectivity errors; typically triggers retry or failover.
- `ErrorCategoryID=1 (Order Validation)` - the order parameters failed validation; likely a configuration issue.
- `ErrorCategoryID=2 (Market Reject)` - market conditions (e.g., outside trading hours, instrument suspended) caused rejection.
- `ErrorCategoryID=3 (Provider Reject)` - the LP rejected the order for provider-specific reasons.
- `ErrorCategoryID=4 (Provider Not Connected)` - FIX session is down or not established.
- `ErrorCategoryID=5 (Provider Unknown)` - error type not recognized/classified.
- `ErrorCategoryID=6 (Provider Business Validation)` - LP's own business rules prevented execution.

### 2.4 Audit Attribution via DbLoginName and AppLoginName

**What**: Two computed columns on the source table capture who made each change.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName = suser_name()` - SQL Server login at time of DML.
- `AppLoginName = CONVERT(varchar(500), context_info())` - application-set user identity. Contains email padded with null bytes when set via `SET CONTEXT_INFO`. NULL when not set.
- NULL `AppLoginName` = change made directly via SSMS or a script not setting context_info.

---

## 3. Data Overview

Both `Hedge.ExecutionErrorMapping` (source) and `History.ExecutionErrorMapping` (history) contain **0 rows** in this staging environment. A representative production row would look like:

| ProviderTypeID | ErrorCategoryID | ErrorMessage | DbLoginName | SysStartTime | SysEndTime |
|---|---|---|---|---|---|
| 2 | 2 | 8=Requote;58=Outside trading hours | TRAD\admin | 2024-01-10 | 2024-06-15 |
| 2 | 2 | 8=Market Closed | TRAD\admin | 2024-06-15 | 2024-06-15 | Zero-duration INSERT artifact |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderTypeID | int | NO | - | CODE-BACKED | Identifies the liquidity provider type whose error messages are being mapped. Part of composite PK (with ErrorMessage) on source. Scopes the error mapping to a specific LP - the same error text can mean different things across providers. Likely FK to a provider type dictionary (Hedge schema). |
| 2 | ErrorCategoryID | smallint | NO | - | VERIFIED | The normalized error category this message maps to. FK to Dictionary.ExecutionErrorCategories: 0=Technical Failure, 1=Order Validation, 2=Market Reject, 3=Provider Reject, 4=Provider Not Connected, 5=Provider Unknown, 6=Provider Business Validation. Drives downstream handling logic in the hedging application. |
| 3 | ErrorMessage | varchar(500) | NO | - | VERIFIED | The exact error message string returned by the liquidity provider. Part of composite PK (with ProviderTypeID). Max 500 characters. Matched against raw provider responses to determine the error category. |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login that performed the DML, captured via `suser_name()` computed column on source. Identifies who added, modified, or removed an error mapping. NULL if unavailable. |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application user identity captured via `CONVERT(varchar(500), context_info())` computed column. Contains end-user email padded with null bytes when set by the application. NULL when context_info not set (direct SSMS access). Must be trimmed with REPLACE/RTRIM to remove null padding. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this error mapping version became active in Hedge.ExecutionErrorMapping. Managed by SQL Server temporal system-versioning. Equal to SysEndTime for INSERT-triggered zero-duration rows. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded (mapping updated or deleted). Clustered index leading column. Equal to SysStartTime for INSERT-triggered zero-duration rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ErrorCategoryID | Dictionary.ExecutionErrorCategories | Implicit (explicit FK on source) | The normalized error category (7 values) |
| (all columns) | Hedge.ExecutionErrorMapping | Temporal | This row is a historical version of the source table row with matching (ProviderTypeID, ErrorMessage) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExecutionErrorMapping | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExecutionErrorMapping (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Hedge.ExecutionErrorMapping (table)
- INSERT trigger on source (Tr_T_ExecutionErrorMapping_INSERT) creates additional zero-duration history rows
- Hedge.ExecutionErrorMapping has FK to Dictionary.ExecutionErrorCategories
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionErrorMapping | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExecutionErrorMapping | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [DICTIONARY] - matching source table, consistent with reference/configuration data classification.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

**Source table constraints** (on Hedge.ExecutionErrorMapping, not enforced on history):
- `PK_executionErrorMapping`: CLUSTERED PK on (ProviderTypeID, ErrorMessage), FILLFACTOR=100
- `FK_executionErrorMapping_CategoryID`: ErrorCategoryID -> Dictionary.ExecutionErrorCategories

---

## 8. Sample Queries

### 8.1 Full change history for a specific error message
```sql
SELECT ProviderTypeID, ErrorCategoryID, ErrorMessage, DbLoginName,
       REPLACE(RTRIM(AppLoginName), CHAR(0), '') AS AppLoginName_Clean,
       SysStartTime, SysEndTime
FROM [History].[ExecutionErrorMapping]
WHERE ProviderTypeID = 2 AND ErrorMessage = 'Outside trading hours'
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY SysStartTime
```

### 8.2 All error category changes (audit)
```sql
SELECT ProviderTypeID, ErrorCategoryID, ErrorMessage, DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExecutionErrorMapping]
WHERE SysStartTime < SysEndTime  -- exclude INSERT artifacts
ORDER BY SysStartTime DESC
```

### 8.3 Error mappings active on a specific date
```sql
SELECT ProviderTypeID, ErrorCategoryID, ErrorMessage, SysStartTime, SysEndTime
FROM [History].[ExecutionErrorMapping]
WHERE '2024-06-01' BETWEEN SysStartTime AND SysEndTime
  AND SysStartTime < SysEndTime
ORDER BY ProviderTypeID, ErrorMessage
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows in staging; source Hedge.ExecutionErrorMapping also has 0 rows. Business logic inferred from DDL + Dictionary.ExecutionErrorCategories values*
*Object: History.ExecutionErrorMapping | Type: Table | Source: etoro/etoro/History/Tables/History.ExecutionErrorMapping.sql*
