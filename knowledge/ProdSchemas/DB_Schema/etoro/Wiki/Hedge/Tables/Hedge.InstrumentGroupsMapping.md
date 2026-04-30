# Hedge.InstrumentGroupsMapping

> Junction table that assigns individual instruments to instrument groups, enabling the hedge engine to apply group-level execution routing rules to all member instruments simultaneously.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, GroupID) - composite PK CLUSTERED |
| **Partition** | No (on [MAIN] filegroup) |
| **Indexes** | 2 (PK + IX on IsActive) |

---

## 1. Business Meaning

`Hedge.InstrumentGroupsMapping` is the many-to-many assignment table between instruments and instrument groups. When the hedge system needs to apply a routing policy (e.g., "route these 20 US stocks directly to Virtu"), it does so by placing those instruments into a named group and configuring the policy against the group. This table records which InstrumentID belongs to which GroupID.

The `IsActive` flag allows instruments to be logically removed from a group without deleting the historical record of their membership. An inactive mapping means the instrument was once in the group but is no longer governed by that group's routing rules - the temporal history table captures exactly when the assignment changed.

Data flows: `Hedge.GetInstrumentGroupsMapping` JOINs this table to `Hedge.InstrumentGroups` (WHERE IsActive=1) to return the current active group assignments to the hedge engine. `Hedge.GetOrderTypeConfiguration` also uses this table to expand group-level order type configurations into per-instrument rules.

---

## 2. Business Logic

### 2.1 Active vs Inactive Membership

**What**: IsActive controls whether a group membership is currently enforced without requiring deletion of the historical assignment.

**Columns/Parameters Involved**: `IsActive`, `InstrumentID`, `GroupID`

**Rules**:
- IsActive=1: instrument is currently a member of this group; group routing rules apply
- IsActive=0: instrument was previously in this group but has been removed; no routing rules applied; historical record preserved
- Only active rows (IsActive=1) are returned by `GetInstrumentGroupsMapping` and used by `GetOrderTypeConfiguration`
- A non-clustered index on IsActive supports efficient filtering for the common query pattern (WHERE IsActive=1)
- DEFAULT IsActive=1 - new mappings are active by default

### 2.2 Group Membership Scale

**What**: Current data shows 135 total rows across 74 distinct instruments and 6 groups; 61 rows are inactive (deactivated assignments).

**Columns/Parameters Involved**: `InstrumentID`, `GroupID`, `IsActive`

**Rules**:
- Futures instruments use InstrumentIDs in the 200000+ range
- Each active instrument typically belongs to exactly one group (no double-counting for routing purposes)
- The composite PK (InstrumentID, GroupID) prevents duplicate assignments to the same group, but allows one instrument to be in multiple groups simultaneously
- All instruments in the Futures group (GroupID=1) have InstrumentIDs starting at 200000, reflecting the Futures instrument ID allocation scheme in Trade.Instrument

---

## 3. Data Overview

| InstrumentID | GroupID | GroupName | IsActive | Meaning |
|---|---|---|---|---|
| 200000 | 1 | Futures | 1 | A futures contract instrument assigned to the Futures group - routed through the RealFutures business flow (SLTPBehavior=1, SpreadLogic=0). |
| (US stock) | 100 | Virtu UnManaged US Flow Direct | 1 | A US-listed stock in the direct-to-Virtu unmanaged flow group. Executes via PathToVirtu business flow. |
| (EU stock) | 101 | Virtu UnManaged EU flow Direct | 1 | An EU-listed stock routing directly to Virtu. Separate from US group due to different exchange jurisdiction. |
| (EU stock) | 201 | OMS-Virtu Unmanged EU flow | 1 | An EU stock in the OMS-mediated path to Virtu (OMS_CFDs flow), as opposed to the direct path (GroupID=101). |
| (any) | (any) | - | 0 | Deactivated assignment - instrument was previously in this group but is no longer governed by its routing rules. History preserved via temporal versioning. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The instrument being assigned to a group. References Trade.Instrument(InstrumentID). Part of the composite PK. Futures instruments appear in the 200000+ ID range. |
| 2 | GroupID | int | NO | - | VERIFIED | The group this instrument belongs to. Explicit FK to Hedge.InstrumentGroups(GroupID). Part of the composite PK. Values correspond to the 6 defined groups: 1=Futures, 100=Virtu US, 101=Virtu EU, 102=Virtu APAC, 201=OMS-Virtu EU, 202=OMS-Virtu US. |
| 3 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 4 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.InstrumentGroupsMapping. |
| 7 | IsActive | bit | NO | 1 | VERIFIED | Whether this group membership is currently enforced. 1=active (instrument is in the group, routing rules apply), 0=inactive (instrument removed from group, rules no longer apply). Indexed for efficient WHERE IsActive=1 filtering. DEFAULT 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Hedge.InstrumentGroups | FK (FK_InstrumentGroupsMapping_GroupID) | Links each mapping to a defined instrument group |
| InstrumentID | Trade.Instrument | Implicit FK | Identifies the instrument being grouped; no explicit FK constraint |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetInstrumentGroupsMapping | (JOIN) | READER | Returns active group memberships (InstrumentID + GroupID + GroupName) |
| Hedge.GetOrderTypeConfiguration | GroupID | JOIN | Expands group-level OrderTypeConfiguration entries (Entity=1) to individual InstrumentIDs |
| History.InstrumentGroupsMapping | (temporal) | Temporal History | Stores all historical membership changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InstrumentGroupsMapping (table)
  └── Hedge.InstrumentGroups (table) [FK - GroupID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentGroups | Table | FK_InstrumentGroupsMapping_GroupID - every GroupID must exist in InstrumentGroups |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetInstrumentGroupsMapping | Stored Procedure | READER - JOINs to return active instrument-to-group assignments |
| Hedge.GetOrderTypeConfiguration | Stored Procedure | READER - JOINs to expand group configs to instrument-level rules |
| History.InstrumentGroupsMapping | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_InstrumentGroupsMapping | CLUSTERED PK | InstrumentID ASC, GroupID ASC | - | - | Active |
| IX | NONCLUSTERED | IsActive ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_InstrumentGroupsMapping | PRIMARY KEY | (InstrumentID, GroupID) - prevents duplicate group assignments |
| FK_InstrumentGroupsMapping_GroupID | FOREIGN KEY | GroupID must reference Hedge.InstrumentGroups(GroupID) |
| DF_Hedge_InstrumentGroupsMapping_IsActive | DEFAULT | IsActive = 1 (new mappings are active by default) |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.InstrumentGroupsMapping |

---

## 8. Sample Queries

### 8.1 View all active instrument group assignments with group names

```sql
SELECT
    igm.InstrumentID,
    igm.GroupID,
    ig.GroupName,
    ig.Description
FROM Hedge.InstrumentGroupsMapping igm WITH (NOLOCK)
JOIN Hedge.InstrumentGroups ig WITH (NOLOCK)
    ON igm.GroupID = ig.GroupID
WHERE igm.IsActive = 1
ORDER BY ig.GroupID, igm.InstrumentID
```

### 8.2 Find instruments in a specific group

```sql
SELECT
    igm.InstrumentID,
    igm.IsActive,
    igm.SysStartTime
FROM Hedge.InstrumentGroupsMapping igm WITH (NOLOCK)
WHERE igm.GroupID = 100  -- Virtu UnManaged US Flow Direct
    AND igm.IsActive = 1
ORDER BY igm.InstrumentID
```

### 8.3 View membership history for a specific instrument

```sql
SELECT
    h.InstrumentID,
    h.GroupID,
    ig.GroupName,
    h.IsActive,
    h.SysStartTime,
    h.SysEndTime
FROM History.InstrumentGroupsMapping h WITH (NOLOCK)
JOIN Hedge.InstrumentGroups ig WITH (NOLOCK)
    ON h.GroupID = ig.GroupID
WHERE h.InstrumentID = 200000  -- specific futures instrument
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InstrumentGroupsMapping | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.InstrumentGroupsMapping.sql*
