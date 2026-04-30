# Trade.InsertTradingInstrumentGroupName

> Bulk-inserts new instrument group definitions from a TVP into Dictionary.TradingInstrumentGroups, with optional audit context injection via CONTEXT_INFO.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GroupsNamesTable TVP (Trade.InstrumentGroupNameTbl) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertTradingInstrumentGroupName is the write endpoint for creating new trading instrument group categories. Instrument groups (e.g., "Crypto", "Commodities", "Technology Stocks") are classification labels used throughout the trading platform to organize instruments for display, filtering, fee configuration, and trading rule application. When operations teams need to introduce a new group category, they call this procedure with a batch of group name/description rows.

Without this procedure there would be no consistent, auditable mechanism for adding instrument groups. The @AppLoginName parameter allows the caller to stamp the SQL Server context_info with the service/user identity, which triggers audit log enrichment in Dictionary.TradingInstrumentGroups (if that table has an audit trigger reading context_info). The procedure does not generate GroupIDs - those are assigned by the target table's IDENTITY column.

Data flow: Operations tooling (OpsFlowAPI) or back-office applications build a Trade.InstrumentGroupNameTbl TVP with one or more new group names, then call this procedure. The INSERT executes atomically. Dictionary.TradingInstrumentGroups receives the new rows with auto-generated GroupIDs. These groups then appear in instrument administration screens and become available for assignment to instruments.

---

## 2. Business Logic

### 2.1 Audit Context Injection

**What**: When @AppLoginName is provided, the caller's identity is written to SQL Server CONTEXT_INFO, enabling downstream audit captures.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- If @AppLoginName is '' (empty string, the default) - no CONTEXT_INFO is set, database audit uses the Windows/SQL login only.
- If @AppLoginName is non-empty - CAST to VARBINARY(128) and SET CONTEXT_INFO. The CONTEXT_INFO value (up to 128 bytes) is visible to any trigger or procedure running in the same session. Audit triggers on Dictionary.TradingInstrumentGroups can read this to capture the application-level user identity.
- @AppLoginName is VARCHAR(50) so values longer than 50 characters are truncated before the CAST.

**Diagram**:
```
@AppLoginName = 'ops-api-user'
    |
    v
CAST('ops-api-user' AS VARBINARY(128)) = @OpsUserInfo
SET CONTEXT_INFO @OpsUserInfo
    |
    v
INSERT Dictionary.TradingInstrumentGroups
    -> audit trigger can now read context_info for app identity
```

### 2.2 TVP-Based Batch Insert

**What**: Multiple instrument groups can be created in a single call via the TVP.

**Columns/Parameters Involved**: `@GroupsNamesTable.GroupName`, `@GroupsNamesTable.Description`

**Rules**:
- All rows in @GroupsNamesTable are inserted in a single INSERT..SELECT - no row-by-row logic.
- GroupName uses Latin1_General_BIN collation (case-sensitive, byte-level comparison).
- Description is optional (nullable in the target).
- GroupID is NOT supplied - Dictionary.TradingInstrumentGroups generates it via IDENTITY.
- No explicit error handling - if the INSERT fails (e.g., duplicate GroupName), the error propagates to the caller.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GroupsNamesTable | Trade.InstrumentGroupNameTbl | NO | - | CODE-BACKED | READONLY TVP. Each row has GroupName (required) and Description (optional). These become new rows in Dictionary.TradingInstrumentGroups. See Trade.InstrumentGroupNameTbl for element details. |
| 2 | @AppLoginName | varchar(50) | NO | '' | CODE-BACKED | Application or service account name for audit context. When non-empty, written to CONTEXT_INFO so audit triggers on the target table can record the application-level caller identity. Default '' disables this. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GroupsNamesTable | Trade.InstrumentGroupNameTbl | Parameter (TVP) | Source of group names to insert. |
| INSERT target | Dictionary.TradingInstrumentGroups | Writer | New group categories are inserted here. |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase - called from OpsFlowAPI (permissions grant in OpsFlowAPI.sql) or other operations tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertTradingInstrumentGroupName (procedure)
├── Trade.InstrumentGroupNameTbl (type) - TVP parameter type
└── Dictionary.TradingInstrumentGroups (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroupNameTbl | User Defined Type | TVP parameter @GroupsNamesTable |
| Dictionary.TradingInstrumentGroups | Table | INSERT target - new group rows written here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OpsFlowAPI (permissions) | Security | EXECUTE permission granted to OpsFlowAPI role |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @AppLoginName length | Design | VARCHAR(50) truncates application identity before VARBINARY cast - caller must keep app login names under 50 chars for full fidelity |

---

## 8. Sample Queries

### 8.1 Insert a new instrument group

```sql
DECLARE @Groups Trade.InstrumentGroupNameTbl;
INSERT INTO @Groups (GroupName, Description)
VALUES ('Technology', 'Technology sector stocks and ETFs');

EXEC Trade.InsertTradingInstrumentGroupName
    @GroupsNamesTable = @Groups,
    @AppLoginName     = 'ops-api-user';
```

### 8.2 Insert multiple groups in one call

```sql
DECLARE @Groups Trade.InstrumentGroupNameTbl;
INSERT INTO @Groups (GroupName, Description)
VALUES ('Crypto', 'Cryptocurrency instruments'),
       ('Indices', 'Market index instruments'),
       ('Commodities', NULL);

EXEC Trade.InsertTradingInstrumentGroupName
    @GroupsNamesTable = @Groups;
-- No @AppLoginName - uses default ''
```

### 8.3 Verify inserted groups

```sql
SELECT TOP 10
    GroupID,
    GroupName,
    Description
FROM Dictionary.TradingInstrumentGroups WITH (NOLOCK)
ORDER BY GroupID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Opstool API TDD](https://etoro-jira.atlassian.net/wiki/spaces/NOC1/pages/13503792101) | Confluence | Mentions trading configuration management via Opstool API including instrument group operations |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertTradingInstrumentGroupName | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertTradingInstrumentGroupName.sql*
