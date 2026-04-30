# Hedge.ExecutionErrorMapping

> Mapping table that classifies provider-specific execution error messages into standardized error categories, enabling the hedge engine to apply consistent retry logic and alerting based on error type rather than raw error strings.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (ProviderTypeID, ErrorMessage) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup, FILLFACTOR=100) |
| **Indexes** | 1 (composite PK only) |

---

## 1. Business Meaning

`Hedge.ExecutionErrorMapping` translates provider-specific raw error messages into standardized `Dictionary.ExecutionErrorCategories` categories. When the hedge engine receives an error from a liquidity provider (such as "Order size exceeds limit" or "Market closed"), it uses this table to determine the category (e.g., Market Reject, Provider Business Validation) and apply the appropriate response.

This abstraction is important because different providers return different error message formats for the same underlying failure type. By mapping raw strings to categories, the hedge engine can implement category-specific logic (retry for Technical Failure, discard for Market Reject, escalate for Provider Unknown) without maintaining per-provider code paths.

**Composite PK design**: `(ProviderTypeID, ErrorMessage)` - the same error message text can mean different things from different providers, so the same string from ProviderTypeID=1 may map to a different category than from ProviderTypeID=2.

**Current state**: The table has 0 rows in both current and history tables, and no stored procedures in the Hedge schema currently read from it. The table is designed but not yet operationally populated.

---

## 2. Business Logic

### 2.1 Error Message Classification

**What**: Maps a provider-specific error message string to a standard error category, allowing the hedge engine to determine appropriate handling.

**Columns/Parameters Involved**: `ProviderTypeID`, `ErrorMessage`, `ErrorCategoryID`

**Rules**:
- PK (ProviderTypeID, ErrorMessage): one classification per provider/message pair
- Same error text from different providers can map to different categories (provider-aware classification)
- `ErrorCategoryID` references `Dictionary.ExecutionErrorCategories`:
  - 0=Technical Failure (retryable - transient infrastructure issue)
  - 1=Order Validation (not retryable - invalid order parameters)
  - 2=Market Reject (not retryable - market/exchange rejected)
  - 3=Provider Reject (may need review - provider explicitly refused)
  - 4=Provider Not Connected (retryable - connectivity issue)
  - 5=Provider Unknown (investigate - unrecognized error, update mapping)
  - 6=Provider Business Validation (may need review - provider business rule violation)
- `ProviderTypeID` identifies the liquidity provider type (implicit reference to Trade.LiquidityProviderType)
- `ErrorMessage` is the raw error string received from the provider (up to 500 chars)
- No FK constraint on ProviderTypeID - application-managed

### 2.2 Retry Logic Determination

**What**: The error category determines the hedge engine's automated response to execution failures.

**Rules** (inherited from Dictionary.ExecutionErrorCategories):
- Categories 0 (Technical Failure) and 4 (Provider Not Connected): typically retryable - transient issues that may succeed on retry
- Categories 1 (Order Validation) and 2 (Market Reject): not retryable - permanent rejections; order should be cancelled
- Categories 3 (Provider Reject) and 6 (Business Validation): manual review may be needed
- Category 5 (Provider Unknown): requires operator investigation and a new mapping row to be inserted

---

## 3. Data Overview

| ProviderTypeID | ErrorCategoryID | ErrorMessage | Meaning |
|---|---|---|---|
| (no rows) | - | - | Table currently empty - no error message mappings configured |

Both current table and history table have 0 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderTypeID | int | NO | - | CODE-BACKED | Identifies the liquidity provider type whose error messages are being classified. Part of composite PK. No FK constraint - implicit reference to Trade.LiquidityProviderType. Enables provider-specific error interpretation. |
| 2 | ErrorCategoryID | smallint | NO | - | VERIFIED | FK to Dictionary.ExecutionErrorCategories(ErrorCategoryID). The standardized error category: 0=Technical Failure, 1=Order Validation, 2=Market Reject, 3=Provider Reject, 4=Provider Not Connected, 5=Provider Unknown, 6=Provider Business Validation. Drives retry and alerting logic. |
| 3 | ErrorMessage | varchar(500) | NO | - | VERIFIED | The raw error message string received from the provider. Part of composite PK. Up to 500 characters. Must be an exact match to the provider's error text for classification to work. |
| 4 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 5 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 6 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 7 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.ExecutionErrorMapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ErrorCategoryID | Dictionary.ExecutionErrorCategories | FK (FK_executionErrorMapping_CategoryID) | Each mapping row classifies the error into a category defined in the Dictionary |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ExecutionErrorMapping | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

Note: No stored procedures in the Hedge schema currently read from this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionErrorMapping (table)
  └── Dictionary.ExecutionErrorCategories (table) [FK - ErrorCategoryID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExecutionErrorCategories | Table | FK_executionErrorMapping_CategoryID - every ErrorCategoryID must reference a valid category |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ExecutionErrorMapping | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_executionErrorMapping | CLUSTERED PK | ProviderTypeID ASC, ErrorMessage ASC | - | - | Active (FILLFACTOR=100) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_executionErrorMapping | PRIMARY KEY | (ProviderTypeID, ErrorMessage) - one category per provider/message pair |
| FK_executionErrorMapping_CategoryID | FOREIGN KEY | ErrorCategoryID must reference Dictionary.ExecutionErrorCategories(ErrorCategoryID) |
| DF_ExecutionErrorMapping_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ExecutionErrorMapping_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ExecutionErrorMapping |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_ExecutionErrorMapping_INSERT | INSERT | No-op self-UPDATE to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all error mappings with category names

```sql
SELECT
    eem.ProviderTypeID,
    eem.ErrorMessage,
    eem.ErrorCategoryID,
    eec.ErrorCategoryName
FROM Hedge.ExecutionErrorMapping eem WITH (NOLOCK)
JOIN Dictionary.ExecutionErrorCategories eec WITH (NOLOCK)
    ON eem.ErrorCategoryID = eec.ErrorCategoryID
ORDER BY eem.ProviderTypeID, eem.ErrorCategoryID
```

### 8.2 Find all retryable error mappings

```sql
SELECT
    eem.ProviderTypeID,
    eem.ErrorMessage,
    eec.ErrorCategoryName
FROM Hedge.ExecutionErrorMapping eem WITH (NOLOCK)
JOIN Dictionary.ExecutionErrorCategories eec WITH (NOLOCK)
    ON eem.ErrorCategoryID = eec.ErrorCategoryID
WHERE eem.ErrorCategoryID IN (0, 4)  -- Technical Failure or Provider Not Connected
ORDER BY eem.ProviderTypeID
```

### 8.3 Count error mappings per category per provider

```sql
SELECT
    eem.ProviderTypeID,
    eec.ErrorCategoryName,
    COUNT(*) AS MappingCount
FROM Hedge.ExecutionErrorMapping eem WITH (NOLOCK)
JOIN Dictionary.ExecutionErrorCategories eec WITH (NOLOCK)
    ON eem.ErrorCategoryID = eec.ErrorCategoryID
GROUP BY eem.ProviderTypeID, eec.ErrorCategoryName
ORDER BY eem.ProviderTypeID, eec.ErrorCategoryName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no reader procedure found) | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionErrorMapping | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExecutionErrorMapping.sql*
