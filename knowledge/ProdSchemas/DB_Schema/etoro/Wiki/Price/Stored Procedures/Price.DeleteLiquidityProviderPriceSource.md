# Price.DeleteLiquidityProviderPriceSource

> Validated DELETE procedure that removes a liquidity provider to price source mapping from Price.LiquidityProviderPriceSource, with optional audit identity capture and temporal history archival.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityProviderID (identifies the mapping to delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.DeleteLiquidityProviderPriceSource removes a liquidity provider's price source attribution from the system. Because Price.LiquidityProviderPriceSource uses temporal system versioning (SYSTEM_VERSIONING=ON), the DELETE does not permanently destroy the data - it is automatically moved to History.LiquidityProviderPriceSource where it becomes part of the historical record with a SysEndTime timestamp.

The procedure validates existence before deleting (rather than silently succeeding on a no-op) and returns the affected row count. The optional @AppLoginName parameter allows operations tooling to attribute the deletion to a specific operator by setting SQL Server CONTEXT_INFO - this populates the AppLoginName audit column captured by the temporal table's history mechanism.

---

## 2. Business Logic

### 2.1 Existence Guard Before Delete

**What**: Validates that a mapping for the given LiquidityProviderID exists before attempting the DELETE.

**Columns/Parameters Involved**: `@LiquidityProviderID`

**Rules**:
- IF NOT EXISTS check on Price.LiquidityProviderPriceSource WHERE LiquidityProviderID = @LiquidityProviderID
- On failure: RAISERROR('Mapping for LiquidityProviderID %d does not exist', 16, 1, @LiquidityProviderID) using the ID value in the message
- On failure: RETURN (no delete attempted)
- This prevents silent no-ops and ensures callers know when they've referenced a non-existent mapping

### 2.2 Optional Audit Identity via CONTEXT_INFO

**What**: When @AppLoginName is provided, the calling application's identity is captured in SQL Server's CONTEXT_INFO for the current session, which the temporal table records in the AppLoginName audit column during the DELETE operation.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- Default: @AppLoginName = '' (empty string = no identity capture)
- When non-empty: DECLARE @OpsUserInfo VARBINARY(128) = CAST(@AppLoginName AS VARBINARY(128)); SET CONTEXT_INFO @OpsUserInfo
- The temporal trigger/mechanism uses context_info() to populate AppLoginName in the history record
- Caller identity is preserved in History.LiquidityProviderPriceSource for audit purposes

### 2.3 Temporal Archival on Delete

**What**: The DELETE moves the row to History.LiquidityProviderPriceSource automatically via SQL Server temporal system versioning.

**Rules**:
- Price.LiquidityProviderPriceSource has SYSTEM_VERSIONING = ON
- A DELETE does not destroy the data - the row is moved to History.LiquidityProviderPriceSource with SysEndTime = delete timestamp
- The comment "automatically moves to history table" in the DDL confirms this behavior
- Full audit trail of all LP-price-source mappings is preserved

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderID | INT | IN | - | CODE-BACKED | The liquidity provider identifier whose price source mapping should be deleted. Must exist in Price.LiquidityProviderPriceSource (validated via EXISTS check). References Trade.LiquidityProviders implicitly. |
| 2 | @AppLoginName | varchar(50) | IN | '' | CODE-BACKED | Optional audit identity: the name of the operator or application performing the delete. When non-empty, set into SQL Server CONTEXT_INFO for this session, which is captured in the temporal history record. Default = empty string (no identity override). |

**Output result set (on success):**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | AffectedRows | INT | NO | CODE-BACKED | Number of rows deleted: SELECT @@ROWCOUNT. Will be 1 on success (PK ensures at most one row per LiquidityProviderID). Used by callers to confirm the delete executed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityProviderID | Price.LiquidityProviderPriceSource | DELETE target | Removes the LP-to-price-source mapping; row moves to History table via temporal versioning |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external pricing management API).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.DeleteLiquidityProviderPriceSource (procedure)
└── Price.LiquidityProviderPriceSource (table) - DELETE target (temporal: history in History.LiquidityProviderPriceSource)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityProviderPriceSource | Table | EXISTS check (validation) + DELETE target; temporal history automatic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external pricing management API |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. SET NOCOUNT ON suppresses row-count messages. Single DELETE with no explicit transaction (the DELETE is effectively atomic). RAISERROR severity 16 is a non-fatal error that is returned to the caller. @AppLoginName type is varchar(50) - truncates to 50 characters; VARBINARY(128) cast truncates to 128 bytes if the name is longer.

---

## 8. Sample Queries

### 8.1 Delete a liquidity provider price source mapping with audit identity

```sql
EXEC Price.DeleteLiquidityProviderPriceSource
    @LiquidityProviderID = 5,
    @AppLoginName = 'admin.user';
-- Returns: AffectedRows = 1 on success
```

### 8.2 Delete without audit identity capture

```sql
EXEC Price.DeleteLiquidityProviderPriceSource
    @LiquidityProviderID = 5;
-- @AppLoginName defaults to '' - no CONTEXT_INFO set
```

### 8.3 Verify deletion and check history

```sql
-- Confirm row no longer in active table
SELECT LiquidityProviderID, PriceSourceID FROM Price.LiquidityProviderPriceSource WITH (NOLOCK)
WHERE LiquidityProviderID = 5;

-- Check temporal history for the deleted row
SELECT LiquidityProviderID, PriceSourceID, SysStartTime, SysEndTime, AppLoginName
FROM History.LiquidityProviderPriceSource WITH (NOLOCK)
WHERE LiquidityProviderID = 5
ORDER BY SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.DeleteLiquidityProviderPriceSource | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.DeleteLiquidityProviderPriceSource.sql*
