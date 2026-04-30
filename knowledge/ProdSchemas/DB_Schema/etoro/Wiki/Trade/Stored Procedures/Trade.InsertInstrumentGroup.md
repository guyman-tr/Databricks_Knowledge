# Trade.InsertInstrumentGroup

> Bulk-inserts instrument-to-provider-group mappings from a TVP into Trade.InstrumentGroups, with optional operator audit via CONTEXT_INFO.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentGroupsTable Trade.InstrumentGroupsTbl (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentGroup is the **write entrypoint for instrument group assignments**. It takes a batch of (ProviderID, InstrumentID, GroupID) tuples via a TVP and inserts them into `Trade.InstrumentGroups`, which maps instruments to provider groups used for trading operations, rate routing, and instrument categorization.

This SP is called by operations flow and trading ops tool APIs when instruments are assigned to or reassigned between groups as part of instrument configuration management.

---

## 2. Business Logic

### 2.1 Operator Audit via CONTEXT_INFO

**What**: Propagates the caller's login name to the session context for audit trail.

**Rules**:
- If `@AppLoginName != ''`: `CAST(@AppLoginName AS VARBINARY(128))` -> SET CONTEXT_INFO
- Enables system-versioning triggers and auditing to record who made the change

### 2.2 Bulk Insert from TVP

**What**: Inserts all rows from the TVP into Trade.InstrumentGroups.

**Columns Inserted**: `ProviderID`, `InstrumentID`, `GroupID`

**Rules**:
- Direct INSERT-SELECT from @InstrumentGroupsTable
- No deduplication check - duplicate rows would violate any unique constraints on the target table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentGroupsTable | Trade.InstrumentGroupsTbl | NO | - | CODE-BACKED | TVP (READONLY) of instrument group mappings to insert. Provides ProviderID, InstrumentID, GroupID for each mapping. |
| 2 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Operator login name for audit. When non-empty, written to CONTEXT_INFO for system-versioning audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (inserts into) | Trade.InstrumentGroups | WRITER | Target table for instrument group mappings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OpsFlowAPI service | EXEC Trade.InsertInstrumentGroup | Caller | Operations flow API assigns instruments to groups |
| trading-opstool-api service | EXEC Trade.InsertInstrumentGroup | Caller | Trading ops tool API assigns instruments to groups |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentGroup (procedure)
|- Trade.InstrumentGroups (table, write target)
`-- Trade.InstrumentGroupsTbl (UDT, TVP type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroups | Table | Insert destination |
| Trade.InstrumentGroupsTbl | User-Defined Table Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OpsFlowAPI | Application | Assigns instruments to groups via this SP |
| trading-opstool-api | Application | Assigns instruments to groups via this SP |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CONTEXT_INFO | Session-level | Operator identity propagation for audit |
| No deduplication | N/A | No WHERE NOT EXISTS check - duplicates may cause constraint violations on target |

---

## 8. Sample Queries

### 8.1 Insert instrument group mappings

```sql
DECLARE @Groups Trade.InstrumentGroupsTbl
INSERT INTO @Groups (ProviderID, InstrumentID, GroupID) VALUES (1, 1001, 5)
EXEC Trade.InsertInstrumentGroup @InstrumentGroupsTable = @Groups, @AppLoginName = 'ops_user'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 permissions files analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentGroup | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentGroup.sql*
