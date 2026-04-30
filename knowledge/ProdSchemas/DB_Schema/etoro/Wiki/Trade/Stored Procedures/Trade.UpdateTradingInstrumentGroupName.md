# Trade.UpdateTradingInstrumentGroupName

> Updates the GroupName and Description of trading instrument groups in Dictionary.TradingInstrumentGroups based on a batch input from the OPS tool.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UpdateInstrumentGroupsTable (TVP input); modifies Dictionary.TradingInstrumentGroups |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure allows operations teams to rename trading instrument groups and update their descriptions in bulk. Trading instrument groups are high-level categorizations used across the platform to group instruments by asset class, trading behavior, or regulatory category (e.g., "Crypto", "US Stocks", "Commodities"). The GroupName and Description fields are surfaced to users on the trading platform UI and used in business reporting.

Without this procedure, renaming instrument groups would require direct database modifications. This procedure provides a controlled, audited path: callers can identify themselves via @AppLoginName which is recorded in CONTEXT_INFO for audit trail purposes. The procedure is exposed to the OpsFlowAPI and trading-opstool-api (per permissions grants), meaning it is invoked by the operations tooling layer when an asset management workflow updates group metadata.

The procedure is called when the asset team needs to update how instrument groups are labeled - for example, when a new regulatory classification is introduced or when an asset class is renamed for marketing or compliance reasons. It is a straightforward MODIFIER of a relatively static configuration table.

---

## 2. Business Logic

### 2.1 Audit Trail via CONTEXT_INFO

**What**: The caller can identify themselves by passing @AppLoginName, which is stored in the SQL Server session CONTEXT_INFO and can be read by triggers or auditing queries.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- If @AppLoginName is not empty (''), it is cast to VARBINARY(128) and set as CONTEXT_INFO for the session
- Triggers on Dictionary.TradingInstrumentGroups (if any) can read CONTEXT_INFO to capture which OPS user made the change
- If empty (default), CONTEXT_INFO is not set (preserves any existing context)
- This is a standard eToro OPS pattern for passing caller identity into the SQL layer without adding a column to the target table

**Diagram**:
```
@AppLoginName != '' ?
      |
      YES -> CAST to VARBINARY(128) -> SET CONTEXT_INFO
      |
      NO  -> Skip (CONTEXT_INFO unchanged)
      |
      -> UPDATE Dictionary.TradingInstrumentGroups SET GroupName, Description
         WHERE GroupID matches input TVP
```

### 2.2 Batch Update via TVP

**What**: The update is driven by a table-valued parameter allowing multiple group updates in a single call.

**Columns/Parameters Involved**: `@UpdateInstrumentGroupsTable`, `GroupID`, `GroupName`, `Description`

**Rules**:
- The TVP is INNER JOINed to Dictionary.TradingInstrumentGroups on GroupID
- Only groups present in BOTH the TVP and the table are updated (INNER JOIN = non-matching GroupIDs silently skipped)
- GroupID is the match key - it is the immutable identifier; GroupName and Description are the mutable display fields
- The procedure is QUOTED_IDENTIFIER OFF, which is a legacy SQL Server setting affecting some string literal handling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateInstrumentGroupsTable | Trade.InstrumentGroupNameAndIDTbl READONLY | NO | - | CODE-BACKED | Table-valued parameter of type Trade.InstrumentGroupNameAndIDTbl. Each row specifies a GroupID with the new GroupName and Description to apply. Non-matching GroupIDs are silently ignored (INNER JOIN). See Trade.InstrumentGroupNameAndIDTbl for the TVP type definition. |
| 2 | @AppLoginName | varchar(50) | YES | '' | CODE-BACKED | OPS user login name for audit purposes. When non-empty, recorded in SQL Server CONTEXT_INFO for the session duration so that any triggers on the target table can capture the responsible caller. Standard eToro OPS auditing pattern. Defaults to empty string (no audit context set). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UpdateInstrumentGroupsTable | Trade.InstrumentGroupNameAndIDTbl | User Defined Type (TVP) | Input TVP type defining GroupID, GroupName, Description columns for the update batch |
| UPDATE target | Dictionary.TradingInstrumentGroups | Modifier | Updates GroupName and Description fields. Matched via GroupID (INNER JOIN). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OpsFlowAPI | EXECUTE permission | Permission grant | Invoked by the OPS flow API when asset team updates group names |
| trading-opstool-api | EXECUTE permission | Permission grant | Invoked by the trading OPS tool API for asset management workflows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateTradingInstrumentGroupName (procedure)
├── Trade.InstrumentGroupNameAndIDTbl (type - TVP input)
└── Dictionary.TradingInstrumentGroups (table - UPDATE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroupNameAndIDTbl | User Defined Type (TVP) | Input parameter type - carries GroupID, GroupName, Description per update |
| Dictionary.TradingInstrumentGroups | Table | UPDATE target - GroupName and Description updated for matching GroupIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OpsFlowAPI | External service | Calls this procedure to update instrument group names via OPS workflows |
| trading-opstool-api | External service | Calls this procedure for asset management configuration updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| QUOTED_IDENTIFIER OFF | Session setting | Legacy SQL Server setting - affects how double-quote characters are interpreted in the session. Inherited from the original creation script; has no functional impact given the simple UPDATE statement. |
| INNER JOIN | Business logic | Only groups present in both the input TVP and the target table are updated. Unrecognized GroupIDs in the input are silently ignored without error. |

---

## 8. Sample Queries

### 8.1 View current trading instrument group names and descriptions

```sql
SELECT
    GroupID,
    GroupName,
    Description
FROM Dictionary.TradingInstrumentGroups WITH (NOLOCK)
ORDER BY GroupID
```

### 8.2 Find instruments belonging to a specific group

```sql
SELECT
    imd.InstrumentID,
    imd.Symbol,
    imd.InstrumentDisplayName,
    tig.GroupName,
    tig.Description
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN Dictionary.TradingInstrumentGroups tig WITH (NOLOCK)
    ON imd.GroupID = tig.GroupID
WHERE tig.GroupName LIKE '%Crypto%'
ORDER BY imd.Symbol
```

### 8.3 Prepare an input batch to rename a group (example TVP usage pattern)

```sql
-- Example of the data that would be passed in @UpdateInstrumentGroupsTable
-- GroupID 5 renamed from old name to new name
DECLARE @updates Trade.InstrumentGroupNameAndIDTbl
INSERT INTO @updates (GroupID, GroupName, Description)
VALUES
    (5, 'Digital Assets', 'Cryptocurrency and digital asset instruments'),
    (12, 'US Equities', 'Stocks listed on US exchanges (NYSE, NASDAQ)')

EXEC Trade.UpdateTradingInstrumentGroupName
    @UpdateInstrumentGroupsTable = @updates,
    @AppLoginName = 'ops_user@etoro.com'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| "eToro OPS DBs related to Asset Insertion" (body inaccessible) | Confluence | Page title suggests context around instrument/asset insertion workflows that use this procedure - body could not be retrieved |

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence (body inaccessible) + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateTradingInstrumentGroupName | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateTradingInstrumentGroupName.sql*
