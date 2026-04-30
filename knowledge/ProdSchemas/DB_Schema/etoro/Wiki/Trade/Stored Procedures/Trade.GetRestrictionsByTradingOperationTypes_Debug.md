# Trade.GetRestrictionsByTradingOperationTypes_Debug

> Debug variant of Trade.GetRestrictionsByTradingOperationTypes - identical SQL, kept with `-- print @SQL` available to uncomment for dynamic SQL inspection during troubleshooting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OperationTypeIDs, @PageNumber, @PageSize |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the debug twin of `Trade.GetRestrictionsByTradingOperationTypes`. The DDL is byte-for-byte identical to the production procedure, including `WITH EXECUTE AS OWNER`, the `STRING_AGG` dynamic SQL pattern, the `IX_OperationTypeID` index hint, and OFFSET/FETCH pagination.

The only intended difference is a `-- print @SQL` line that can be uncommented during a debug session to print the generated dynamic SQL to the client output - useful for inspecting the exact IN clause that was constructed from the `@OperationTypeIDs` TVP.

**When to use**: When diagnosing an unexpected result set or performance issue with the production procedure. Developer uncomments `-- print @SQL`, executes the debug variant against a non-production environment, observes the generated SQL string, then re-comments before promoting.

For full business logic, parameters, output columns, enum value mappings, Atlassian context, and dependency chain, see: `Trade.GetRestrictionsByTradingOperationTypes.md`.

---

## 2. Business Logic

See `Trade.GetRestrictionsByTradingOperationTypes` - logic is identical.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

Identical to `Trade.GetRestrictionsByTradingOperationTypes`:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationTypeIDs | Trade.TradingOperationTypeIDs READONLY | NO | - | CODE-BACKED | Same as production variant. TVP of operation type IDs to filter by (TradeRestrictionType enum values). If empty, all restrictions returned. |
| 2 | @PageNumber | INT | NO | - | CODE-BACKED | 1-based page number. |
| 3 | @PageSize | INT | NO | 1000 | CODE-BACKED | Rows per page, defaults to 1000. |

**Output Columns** - identical to production variant:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CID | INT | NO | - | ATLASSIAN | Customer ID with an active restriction. Ordered by CID for stable pagination. |
| 5 | OperationTypeID | INT | NO | - | ATLASSIAN | TradeRestrictionType: CopyUser=1 ... ManualExecutionBlock=21. See production doc for full enum. |
| 6 | Occurred | DATETIME | NO | - | ATLASSIAN | Timestamp when the restriction was applied. |
| 7 | BlockReasonID | INT | NO | - | ATLASSIAN | BlockUnBlockReason: NONE=0, RequestedByBOAdmin=1 ... MaxAumPerTier=23. See production doc for full enum. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID, Occurred, BlockReasonID | Customer.BlockedCustomerOperations | Reader (cross-schema) | Same as production variant |
| @OperationTypeIDs | Trade.TradingOperationTypeIDs | UDT reference | Same as production variant |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetRestrictionsByTradingOperationTypes | - | Sibling (debug copy) | Production variant; this proc is the debug companion |
| Trade developers | Manual EXEC | Debugging use | Uncomment `-- print @SQL` to inspect generated dynamic SQL |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRestrictionsByTradingOperationTypes_Debug (procedure)
+-- Customer.BlockedCustomerOperations (table - cross-schema)
+-- Trade.TradingOperationTypeIDs (UDT - same schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (Customer schema) | Identical to production variant |
| Trade.TradingOperationTypeIDs | UDT (Trade schema) | Identical to production variant |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none - debug only) | - | Not called by application services; debug/testing use only |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Same as `Trade.GetRestrictionsByTradingOperationTypes`. Additionally:

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| `-- print @SQL` | Debug hook | Commented out; uncomment to print the generated dynamic SQL string during debugging |

---

## 8. Sample Queries

### 8.1 Debug with dynamic SQL printing

```sql
-- Uncomment the print @SQL line in the procedure, then:
DECLARE @OpTypes Trade.TradingOperationTypeIDs;
INSERT INTO @OpTypes VALUES (4), (5);  -- Trading, PositionOpen
EXEC Trade.GetRestrictionsByTradingOperationTypes_Debug
    @OperationTypeIDs = @OpTypes,
    @PageNumber = 1;
-- Output: prints the generated SQL string before executing it
```

---

## 9. Atlassian Knowledge Sources

See `Trade.GetRestrictionsByTradingOperationTypes` - same Confluence TDD source applies.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 4 ATLASSIAN, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 1 Confluence (inherited from sibling doc) + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRestrictionsByTradingOperationTypes_Debug | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRestrictionsByTradingOperationTypes_Debug.sql*
