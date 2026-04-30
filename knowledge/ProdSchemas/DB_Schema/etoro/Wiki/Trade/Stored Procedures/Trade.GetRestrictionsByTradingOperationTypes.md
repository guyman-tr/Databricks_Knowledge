# Trade.GetRestrictionsByTradingOperationTypes

> Returns paginated trading restriction records from Customer.BlockedCustomerOperations, optionally filtered to specific operation types. Uses dynamic SQL with STRING_AGG IN clause for optimal index usage.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OperationTypeIDs, @PageNumber, @PageSize |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary data reader for the **Trading Restriction Service** - the eToro system that controls which trading operations each customer is allowed to perform. It reads from `Customer.BlockedCustomerOperations`, the table that records active restrictions per customer, and returns them in pages.

Each row in the output represents one restriction: a customer (CID) is blocked from performing a specific operation type (OperationTypeID) for a specific reason (BlockReasonID). For example, a customer might be blocked from Opening Positions (OperationTypeID=5) because their account is in Liquidation (BlockReasonID=9).

The TVP parameter `@OperationTypeIDs` allows the caller to request restrictions for specific operation types only (e.g., "give me all customers blocked from copy trading"). If the TVP is empty, all restrictions across all operation types are returned. This dual-mode behavior supports both targeted queries (for a specific restriction check) and full-table exports (for cache loading or reporting).

**Key design decision - dynamic SQL**: A comment in the code explains this explicitly: *"Improved performance by replacing the JOIN with a dynamic IN clause, reducing execution plan complexity and optimizing index usage."* The `IX_OperationTypeID` index on `Customer.BlockedCustomerOperations` is most efficiently used with an IN list (which compiles to seeks) rather than a JOIN to a TVP (which may produce a nested loop or hash join). The `STRING_AGG` approach converts the TVP into a literal IN list for the best possible query plan.

**WITH EXECUTE AS OWNER**: Required because the TVP type `Trade.TradingOperationTypeIDs` is in the Trade schema, and executing dynamic SQL via `sp_executesql` requires the execution context to resolve the schema permissions correctly. `EXECUTE AS OWNER` elevates the context to the procedure owner for the duration of the call.

**Caller**: `PortfolioAlignmentService` (EXECUTE permission confirmed in SSDT) as part of copy portfolio synchronization.

---

## 2. Business Logic

### 2.1 Filtered vs. Unfiltered Mode

**What**: If the caller provides specific operation type IDs, only restrictions for those types are returned. If the TVP is empty, all restrictions are returned.

**Columns/Parameters Involved**: `@OperationTypeIDs`, `@OperationTypeList`, `OperationTypeID`

**Rules**:
- `IF EXISTS (SELECT 1 FROM @OperationTypeIDs)` -> filtered mode: builds `WHERE OperationTypeID IN (1,4,5)` clause
- `ELSE` -> unfiltered mode: no WHERE clause, returns all operation types
- Both modes use identical ORDER BY, OFFSET/FETCH pagination, and index hint
- `WITH (INDEX = IX_OperationTypeID)` forces the index seek path in both cases

**Diagram**:
```
@OperationTypeIDs TVP:
  Empty (no rows)       -> ELSE branch: return ALL restrictions, all operation types
  Has rows (e.g. 1,4,5) -> IF branch: WHERE OperationTypeID IN (1,4,5) only

Application use cases:
  "Load all Trading restrictions"  -> pass OperationTypeID=4 only
  "Sync all restrictions to cache" -> pass empty TVP -> get everything
```

### 2.2 Dynamic SQL for Index Optimization

**What**: Converts the TVP to a comma-separated string to generate a literal IN clause instead of a JOIN.

**Columns/Parameters Involved**: `@OperationTypeList`, `STRING_AGG`, `sp_executesql`

**Rules**:
- `STRING_AGG(CAST(TradingOperationTypeID AS NVARCHAR(10)), ',')` -> produces e.g. `'1,4,5,21'`
- Dynamic SQL string built with inline integer literals (not parameterized) - safe because values come from a typed INT column in a TVP (no user-provided strings)
- `OPTION(RECOMPILE)` embedded inside the dynamic SQL -> fresh plan per execution, critical since page size affects row estimation
- `sp_executesql @SQL` executes the final query string

### 2.3 Pagination

**What**: OFFSET/FETCH standard SQL Server pagination, 1-based page numbers.

**Columns/Parameters Involved**: `@PageNumber`, `@PageSize` (default 1000)

**Rules**:
- Page 1: OFFSET 0 ROWS FETCH NEXT 1000 ROWS
- Page 2: OFFSET 1000 ROWS FETCH NEXT 1000 ROWS
- Formula: `OFFSET (@PageNumber - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY`
- Default @PageSize=1000 if not provided
- ORDER BY CID ensures stable pagination across calls

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationTypeIDs | Trade.TradingOperationTypeIDs READONLY | NO | - | CODE-BACKED | TVP of operation type IDs to filter by. Each row has TradingOperationTypeID INT NULL. If empty, all restriction types returned. Maps to TradeRestrictionType enum (see section 2.1). |
| 2 | @PageNumber | INT | NO | - | CODE-BACKED | 1-based page number. Page 1 returns rows 1-@PageSize, page 2 returns @PageSize+1 to @PageSize*2, etc. Must be >= 1. |
| 3 | @PageSize | INT | NO | 1000 | CODE-BACKED | Rows per page. Defaults to 1000. Controls both OFFSET calculation and FETCH size. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CID | INT | NO | - | ATLASSIAN | Customer ID with an active restriction. FK to Customer.Customer. Records are ordered by CID for stable pagination. |
| 5 | OperationTypeID | INT | NO | - | ATLASSIAN | The type of trading operation that is restricted. Maps to TradeRestrictionType enum: CopyUser=1, Copied=2, PublicPortfolioVisible=3, Trading=4, PositionOpen=5, ManualPositionClose=6, ManualOpenExitOrder=7, OpenEntryOrder=8, OpenOrder=9, OpenOpen=10, ManualUnregisterMirror=11, ManualEditSL=12, ManualEditTP=13, ManualEditTSL=14, ManualCloseEntryOrder=15, ManualCloseExitOrder=16, CloseOrder=17, ManualEditMirrorSL=18, ManualEditMirrorSLPercentage=19, ManualPauseCopy=20, ManualExecutionBlock=21. |
| 6 | Occurred | DATETIME | NO | - | ATLASSIAN | Timestamp when this restriction was applied. From Customer.BlockedCustomerOperations.Occurred. |
| 7 | BlockReasonID | INT | NO | - | ATLASSIAN | The reason this restriction was applied. Maps to BlockUnBlockReason enum: NONE=0, RequestedByBOAdmin=1, HighRiskScore=2, EmployeeAccount=3, OPT_OUT=4, OPT_IN=5, NotVerified=6, Verified=7, RequestedByKYC=8, Liquidation=9, LiquidationRemove=10, ManualExecutionBlock=11, ManualExecutionBlockRemove=12, AumLimit=13, Regulation=14, NonResponsive=15, AbusiveTrading=16, LowEquity=17, BreachComunityGuidelines=18, NonLaunchedCopyFund=19, NotAcceptUsersCopyFund=20, AumLimitPopular=21, MaxCopiers=22, MaxAumPerTier=23. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID, Occurred, BlockReasonID | Customer.BlockedCustomerOperations | Reader (cross-schema) | Primary source; filtered by OperationTypeID IN clause; index-hinted with IX_OperationTypeID |
| @OperationTypeIDs | Trade.TradingOperationTypeIDs | UDT reference | TVP type for operation type filter input |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PortfolioAlignmentService | @OperationTypeIDs, @PageNumber, @PageSize | Application call | Paged bulk retrieval of trading restrictions for portfolio alignment decisions |
| Trade.GetRestrictionsByTradingOperationTypes_Debug | - | Sibling | Identical procedure kept for debugging; `-- print @SQL` available to uncomment |
| Trade.GetRestrictionsByTradingOperationTypesTest | - | Sibling | Alternative temp table + JOIN implementation used for performance comparison |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRestrictionsByTradingOperationTypes (procedure)
+-- Customer.BlockedCustomerOperations (table - cross-schema)
+-- Trade.TradingOperationTypeIDs (UDT - same schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (Customer schema) | SELECT CID, OperationTypeID, Occurred, BlockReasonID; index hint IX_OperationTypeID; dynamic SQL IN clause filter |
| Trade.TradingOperationTypeIDs | UDT (Trade schema) | TVP type for @OperationTypeIDs parameter; single column TradingOperationTypeID INT NULL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PortfolioAlignmentService | External application | Paged restriction data retrieval for copy portfolio synchronization |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH EXECUTE AS OWNER | Security context | Elevates to procedure owner for cross-schema TVP resolution in dynamic SQL |
| STRING_AGG -> IN clause | Dynamic SQL pattern | Converts TVP to literal IN list; avoids JOIN overhead; safe because values are typed INT, not user strings |
| WITH (INDEX = IX_OperationTypeID) | Index hint | Forces index seek on OperationTypeID in both filtered and unfiltered branches |
| OPTION(RECOMPILE) | Query hint (inside dynamic SQL) | Fresh execution plan per call; critical because @PageNumber affects row estimates |
| OFFSET/FETCH | Pagination | 1-based page number; default page size 1000 |
| sp_executesql @SQL | Dynamic execution | Executes the constructed query string in the owner security context |

---

## 8. Sample Queries

### 8.1 Get all PositionOpen restrictions (page 1)

```sql
DECLARE @OpTypes Trade.TradingOperationTypeIDs;
INSERT INTO @OpTypes VALUES (5);  -- PositionOpen
EXEC Trade.GetRestrictionsByTradingOperationTypes
    @OperationTypeIDs = @OpTypes,
    @PageNumber = 1,
    @PageSize = 1000;
```

### 8.2 Get all copy-related restrictions (page 1)

```sql
DECLARE @OpTypes Trade.TradingOperationTypeIDs;
INSERT INTO @OpTypes VALUES (1), (2), (20);  -- CopyUser, Copied, ManualPauseCopy
EXEC Trade.GetRestrictionsByTradingOperationTypes
    @OperationTypeIDs = @OpTypes,
    @PageNumber = 1,
    @PageSize = 500;
```

### 8.3 Get all restrictions across all operation types (page 1)

```sql
DECLARE @OpTypes Trade.TradingOperationTypeIDs;
-- Empty TVP -> returns all operation types
EXEC Trade.GetRestrictionsByTradingOperationTypes
    @OperationTypeIDs = @OpTypes,
    @PageNumber = 1,
    @PageSize = 1000;
```

### 8.4 Equivalent static query for debugging

```sql
-- Equivalent to calling with OperationTypeID IN (4, 5) - Trading and PositionOpen restrictions
SELECT B.[CID], B.[OperationTypeID], B.[Occurred], B.[BlockReasonID]
FROM [Customer].[BlockedCustomerOperations] B WITH (INDEX = IX_OperationTypeID)
WHERE B.OperationTypeID IN (4, 5)
ORDER BY B.[CID]
OFFSET 0 ROWS FETCH NEXT 1000 ROWS ONLY
OPTION(RECOMPILE);
```

---

## 9. Atlassian Knowledge Sources

**Confluence: "Trading Restriction Service TDD"** (TRAD space, page ID 12992446514, 2025-03-02)
- Defines **TradeRestrictionType** enum (21 values): full mapping used in OperationTypeID column description above
- Defines **BlockUnBlockReason** enum (23 values): full mapping used in BlockReasonID column description above
- Architecture: ASP.NET Core service on AKS, RabbitMQ messaging, SQL Server backend
- CustomerRestrictionSet flow: calls `[Trade].[CustomerRestrictionsSet]` to write restrictions
- CustomerRestrictionRemove flow: calls `[Trade].[CustomerRestrictionsRemove]` to remove restrictions
- Customer.BlockedCustomerOperations data model confirmed: CID INT, OperationTypeID INT, Occurred DATETIME, BlockReasonID INT, RequestGUID NVARCHAR

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 4 ATLASSIAN, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence (Trading Restriction Service TDD) + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRestrictionsByTradingOperationTypes | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRestrictionsByTradingOperationTypes.sql*
