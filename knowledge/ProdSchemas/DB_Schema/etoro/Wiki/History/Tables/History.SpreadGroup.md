# History.SpreadGroup

> Trigger-managed application history table for Trade.SpreadGroup, recording all past spread group names and their effective time windows. Spread groups were used to assign custom spread configurations to specific customers or introducing brokers.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | SpreadGroupVersionID (IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (CLUSTERED PK on SpreadGroupVersionID; NONCLUSTERED on Name; NONCLUSTERED on SpreadGroupID) |

---

## 1. Business Meaning

This table is the **trigger-managed application history table** for `Trade.SpreadGroup`. History is maintained by triggers on `Trade.SpreadGroup`:
- `SpreadGroupInsert` trigger (INSERT): inserts a new row with ValidFrom=GETDATE(), ValidTo='3000-01-01'
- `SpreadGroupUpdate` trigger (UPDATE): closes the previous row (ValidTo=GETDATE()), inserts new row
- `TSpreadGroupDelete` trigger (DELETE): closes the active row (ValidTo=GETDATE())

`Trade.SpreadGroup` defines named spread group configurations. Each spread group has a SpreadGroupID and Name. Based on the observed data, spread groups were used to assign **custom spread configurations to specific customers (CID-based groups) or introducing brokers (e.g., "FaroFX_IB")**. The group Name often embeds the customer ID or IB identifier directly (e.g., "CID=174268", "CID=1025068 (Gold 50 pips)", "FaroFX_IB").

The table has only 17 rows with the most recent change in October 2011 - this is a **legacy feature** from eToro's early years. Custom per-customer spread groups are no longer actively maintained. All 17 rows have ValidTo='3000-01-01' (no group has ever been deleted or superseded).

`History.SpreadToGroup` (object #25 in this batch) links spread groups to their specific spread configurations.

---

## 2. Business Logic

### 2.1 Spread Group Versioning Pattern

**What**: Any change to a spread group's Name creates a new history version.

**Columns/Parameters Involved**: `SpreadGroupID`, `SpreadGroupVersionID`, `ValidFrom`, `ValidTo`

**Rules**:
- `ValidTo='3000-01-01'` = currently active version
- On INSERT to Trade.SpreadGroup: one row inserted into History.SpreadGroup
- On UPDATE: old row closed (ValidTo=NOW), new row inserted
- On DELETE: old row closed (ValidTo=NOW)
- SpreadGroupID 7 shows the only update: name changed from "low" to "instrument=spread, 1=2, 2=3, 4=3, 18=40, 17=10" (the new name encoded the actual spread mappings)

### 2.2 Customer-Specific Spread Groups

**What**: Spread groups could be created for individual high-value customers or IBs to provide custom pricing.

**Columns/Parameters Involved**: `Name`

**Rules**:
- Name convention `CID=<number>` indicates a group for a specific customer
- Name suffix `(Gold 50 pips)` indicates a specific per-instrument spread rule
- Name `FaroFX_IB` indicates an Introducing Broker group
- Name encoding like "instrument=spread, 1=2, 2=3..." directly describes the spread rules in the name

---

## 3. Data Overview

| SpreadGroupVersionID | SpreadGroupID | Name | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| 22 | 13 | FaroFX_IB | 2011-10-30 | 3000-01-01 (active) | Introducing broker "FaroFX" spread group |
| 21 | 12 | CID=1740420 | 2011-10-26 | 3000-01-01 (active) | Customer-specific spread group |
| 11 | 7 | instrument=spread, 1=2, 2=3, 4=3, 18=40, 17=10 | 2010-06-01 | 3000-01-01 (active) | Group with encoded per-instrument spreads |
| 10 | 7 | low | 2010-06-01 10:21 | 2010-06-01 10:22 | Previous name for group 7, changed within 18 seconds |
| 8 | 5 | CID=302302 | 2009-10-18 | 3000-01-01 (active) | Customer 302302's custom spread group |

Total: 17 rows | 16 distinct SpreadGroupIDs | Only 1 update (SpreadGroupID=7) | Last change: October 2011

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadGroupVersionID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Surrogate primary key for history rows. Auto-incremented. Uniquely identifies each version of each spread group. |
| 2 | SpreadGroupID | int | NO | - | VERIFIED | References the Trade.SpreadGroup row this version belongs to. Multiple versions can share the same SpreadGroupID across time. Indexed for lookup. |
| 3 | Name | varchar(50) | NO | - | VERIFIED | The spread group's identifier name. Convention: "CID=<number>" for customer-specific groups, "<IBName>_IB" for introducing broker groups, or a descriptive name encoding spread rules. UNIQUE in the source table - two active groups cannot share the same name. Indexed for lookup. |
| 4 | ValidFrom | datetime | NO | - | CODE-BACKED | UTC timestamp when this name became effective. Set to GETDATE() by the SpreadGroupInsert or SpreadGroupUpdate trigger. |
| 5 | ValidTo | datetime | NO | - | CODE-BACKED | UTC timestamp when this name was superseded. Sentinel '3000-01-01' = currently active. Set to GETDATE() by SpreadGroupUpdate or TSpreadGroupDelete trigger when the name changes or the group is deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SpreadGroupID | Trade.SpreadGroup | Trigger History | Each row is a past state of the source Trade.SpreadGroup row identified by SpreadGroupID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SpreadGroup | SpreadGroupInsert / SpreadGroupUpdate / TSpreadGroupDelete triggers | Trigger Writer | All changes to Trade.SpreadGroup are reflected here via triggers. |

---

## 6. Dependencies

No dependencies. Application-managed trigger history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HSPG | CLUSTERED PK | SpreadGroupVersionID ASC | - | - | Active |
| HSPG_NAME | NONCLUSTERED | Name ASC | - | - | Active |
| HSPG_SPREADGROUP | NONCLUSTERED | SpreadGroupID ASC | - | - | Active |

Note: All indexes on [HISTORY] filegroup with FILLFACTOR=90.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HSPG | PRIMARY KEY | Uniqueness on SpreadGroupVersionID. CLUSTERED. FILLFACTOR=90. NOT FOR REPLICATION. |

---

## 8. Sample Queries

### 8.1 Get all currently active spread groups
```sql
SELECT SpreadGroupID, Name, ValidFrom
FROM [History].[SpreadGroup] WITH (NOLOCK)
WHERE ValidTo = '30000101'
ORDER BY SpreadGroupID
```

### 8.2 Get spread group history for a specific group
```sql
SELECT SpreadGroupVersionID, SpreadGroupID, Name, ValidFrom, ValidTo
FROM [History].[SpreadGroup] WITH (NOLOCK)
WHERE SpreadGroupID = @SpreadGroupID
ORDER BY ValidFrom ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (trigger-driven) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SpreadGroup | Type: Table | Source: etoro/etoro/History/Tables/History.SpreadGroup.sql*
