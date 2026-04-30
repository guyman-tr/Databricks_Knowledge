# Trade.DeleteInstrumentGroup

> Removes instrument-to-group mappings from Trade.InstrumentGroups matching by ProviderID + GroupID + InstrumentID, with audit trail support.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DeleteInstrumentGroupsTable (TVP of instrument group mappings to delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteInstrumentGroup removes specific instrument-to-group assignments from Trade.InstrumentGroups. Instrument groups organize financial instruments into provider-specific categories used for fee calculation, execution routing, and risk management. This procedure is called by the Trading Operations admin tool when group assignments need to be updated or removed.

This procedure exists to provide bulk deletion of group assignments with an audit trail. The three-column composite key (ProviderID, GroupID, InstrumentID) uniquely identifies each assignment, and the TVP input allows multiple assignments to be removed in a single call.

Data flow: The caller provides a TVP with ProviderID, GroupID, InstrumentID combinations and an optional AppLoginName. If AppLoginName is provided, it is stored in CONTEXT_INFO for audit. The TVP is materialized into a temp table with a clustered index on the composite key, then a DELETE with INNER JOIN removes matching rows from Trade.InstrumentGroups.

---

## 2. Business Logic

### 2.1 Composite Key Matching

**What**: Deletes are matched on the full three-part composite key.

**Columns/Parameters Involved**: `ProviderID`, `GroupID`, `InstrumentID`

**Rules**:
- DELETE uses INNER JOIN on all three columns: ProviderID, GroupID, InstrumentID
- Temp table with clustered index (ProviderID, GroupID, InstrumentID) for efficient matching
- Only exact matches are deleted

### 2.2 Audit Trail via CONTEXT_INFO

**What**: Records the operator identity for change tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- When non-empty, cast to VARBINARY(128) and set as CONTEXT_INFO
- Available to triggers or temporal table history

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DeleteInstrumentGroupsTable | Trade.InstrumentGroupsTbl (READONLY) | NO | - | CODE-BACKED | TVP containing the instrument group assignments to delete. Each row has ProviderID, GroupID, InstrumentID. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Operator login name for audit trail. Stored in CONTEXT_INFO when non-empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.InstrumentGroups | DELETER | Removes instrument-to-group assignment rows matching the composite key |
| (@DeleteInstrumentGroupsTable) | Trade.InstrumentGroupsTbl | Type Reference | TVP type for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteInstrumentGroup (procedure)
+-- Trade.InstrumentGroups (table)
+-- Trade.InstrumentGroupsTbl (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroups | Table | DELETE target |
| Trade.InstrumentGroupsTbl | User Defined Type | Input parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove an instrument from a group

```sql
DECLARE @Groups Trade.InstrumentGroupsTbl
INSERT INTO @Groups (ProviderID, GroupID, InstrumentID) VALUES (1, 5, 1001)
EXEC Trade.DeleteInstrumentGroup @DeleteInstrumentGroupsTable = @Groups, @AppLoginName = 'admin@etoro.com'
```

### 8.2 Check group assignments before deletion

```sql
SELECT  ProviderID, GroupID, InstrumentID
FROM    Trade.InstrumentGroups WITH (NOLOCK)
WHERE   GroupID = 5
ORDER BY InstrumentID
```

### 8.3 Count instruments per group

```sql
SELECT  ProviderID, GroupID, COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentGroups WITH (NOLOCK)
GROUP BY ProviderID, GroupID
ORDER BY ProviderID, GroupID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteInstrumentGroup | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteInstrumentGroup.sql*
