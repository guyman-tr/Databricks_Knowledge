# Hedge.InstrumentGroups

> Registry of named instrument groups used by the hedge engine to apply routing rules, order type configurations, and execution policies to sets of instruments collectively rather than one by one.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | GroupID (int, manually assigned, PK CLUSTERED) |
| **Partition** | No (on [MAIN] filegroup) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Hedge.InstrumentGroups` is the group definition table for instrument-level hedging policy. Rather than configuring execution rules for thousands of instruments individually, the hedge system allows instruments to be grouped (via `Hedge.InstrumentGroupsMapping`) and then rules applied to the group as a whole. A group represents a logical set of instruments that share a common execution routing characteristic - such as "all Futures instruments" or "US stocks in the Unmanaged Flow routed to Virtu."

This table exists because execution routing at eToro is not uniform across all instruments. Different providers (Virtu, OMS/Virtu), different regulatory regions (US, EU, APAC), and different instrument types (Futures vs. equities) require distinct order handling configurations. Groups provide the abstraction layer that connects the configuration (`Hedge.OrderTypeConfiguration`) to the instruments it governs.

Data flows as follows: `Hedge.InstrumentGroupsMapping` maps individual InstrumentIDs to a GroupID defined here. `Hedge.OrderTypeConfiguration` references GroupIDs (where `Entity = 1`) to define order type rules. `Hedge.GetOrderTypeConfiguration` JOINs these tables to expand group-level rules into per-instrument configurations returned to the hedge engine.

---

## 2. Business Logic

### 2.1 Group Numbering Convention

**What**: GroupIDs are manually assigned and follow a numbering pattern that encodes the routing destination and region.

**Columns/Parameters Involved**: `GroupID`, `GroupName`, `Description`

**Rules**:
- GroupID=1: Instrument type grouping (Futures) - the original, most generic group
- GroupIDs 100-102: Virtu direct path ("PathToVirtu" business flow), split by geography: 100=US, 101=EU, 102=APAC
- GroupIDs 201-202: OMS/Virtu path ("OMS_CFDs" or similar business flow), split by geography: 201=EU, 202=US
- The "Unmanaged Flow" naming in group descriptions indicates instruments where eToro does not actively manage the hedge exposure - orders flow directly ("unmanaged") to the provider
- GroupID gaps (e.g., no 103, 200) leave room for future groups in the same range

**Diagram**:
```
Instrument -> Hedge.InstrumentGroupsMapping -> GroupID -> Hedge.InstrumentGroups
                                                              |
                                                              v
                                              Hedge.OrderTypeConfiguration (Entity=1)
                                              -> routing rules applied to all instruments in group
```

---

## 3. Data Overview

| GroupID | GroupName | Description | Meaning |
|---|---|---|---|
| 1 | Futures | Group of future instruments | All futures contracts. Routes through the RealFutures business flow (SLTPBehavior=1). Oldest group, dating from 2024-11-06. |
| 100 | Virtu UnManaged US Flow Direct | US Names of the Unmanaged Flow into Virtu | US-listed stocks in the direct Virtu (PathToVirtu) unmanaged flow. Created 2025-09-21 as part of direct routing expansion. |
| 101 | Virtu UnManaged EU flow Direct | EU Names of Unmanaged Flow to Virtu | EU-listed stocks routed directly to Virtu (PathToVirtu). Separate group from US to allow distinct instruments per exchange jurisdiction. |
| 201 | OMS-Virtu Unmanged EU flow | EU Names Unmanaged flow to OMS/Virtu | EU stocks in the OMS-mediated unmanaged flow that ultimately routes to Virtu. OMS path (Entity via OMS_CFDs flow) vs direct path (100-series). |
| 202 | OMS-Virtu Unmanged US flow | US Names Unmanaged flow to OMS/Virtu | US stocks in the OMS-mediated unmanaged flow to Virtu. Created alongside 201. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | VERIFIED | Primary key. Manually assigned integer identifying the instrument group. Numbering convention: 1=instrument-type groups, 100-102=Virtu direct path by region, 201-202=OMS/Virtu path by region. NOT IDENTITY - values are explicitly chosen to encode group category. Referenced by Hedge.InstrumentGroupsMapping and Hedge.OrderTypeConfiguration. |
| 2 | GroupName | varchar(124) | NO | - | CODE-BACKED | Human-readable name for the group (e.g., "Futures", "Virtu UnManaged US Flow Direct"). Used in GetInstrumentGroupsMapping output returned to the hedge engine and in admin interfaces. |
| 3 | Description | varchar(256) | YES | - | CODE-BACKED | Optional free-text description of the group's purpose (e.g., "US Names of the Unmanaged Flow into Virtu"). Informational only - not used by any procedure logic. NULL allowed but always populated in practice. |
| 4 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML via `suser_name()`. |
| 5 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from `CONTEXT_INFO()`. NULL when not set. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal period start. UTC timestamp when this row version became active. Original Futures group created 2024-11-06; Virtu/OMS groups added 2025-09-21. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal period end. 9999-12-31 for all currently active rows. History in History.InstrumentGroups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InstrumentGroupsMapping | GroupID | Implicit FK | Each mapping row assigns an InstrumentID to a GroupID defined here |
| Hedge.GetInstrumentGroupsMapping | GroupID | JOIN | JOINs this table to InstrumentGroupsMapping to return group name alongside instrument IDs |
| Hedge.GetOrderTypeConfiguration | GroupID | JOIN | Expands group-level OrderTypeConfiguration rows (Entity=1) to individual instruments via InstrumentGroupsMapping |
| History.InstrumentGroups | (temporal) | Temporal History | Historical row versions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentGroupsMapping | Table | References GroupID - maps instruments to groups defined here |
| Hedge.GetInstrumentGroupsMapping | Stored Procedure | READER - JOINs this table to return GroupID + GroupName per instrument |
| Hedge.GetOrderTypeConfiguration | Stored Procedure | READER - expands group-level routing configs via GroupID |
| History.InstrumentGroups | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_InstrumentGroups | CLUSTERED PK | GroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_InstrumentGroups | PRIMARY KEY | GroupID - unique group definitions |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.InstrumentGroups |

---

## 8. Sample Queries

### 8.1 View all instrument groups

```sql
SELECT
    ig.GroupID,
    ig.GroupName,
    ig.Description,
    ig.SysStartTime
FROM Hedge.InstrumentGroups ig WITH (NOLOCK)
ORDER BY ig.GroupID
```

### 8.2 Count instruments per group (active mappings only)

```sql
SELECT
    ig.GroupID,
    ig.GroupName,
    COUNT(igm.InstrumentID) AS InstrumentCount
FROM Hedge.InstrumentGroups ig WITH (NOLOCK)
LEFT JOIN Hedge.InstrumentGroupsMapping igm WITH (NOLOCK)
    ON ig.GroupID = igm.GroupID AND igm.IsActive = 1
GROUP BY ig.GroupID, ig.GroupName
ORDER BY ig.GroupID
```

### 8.3 View instruments in a specific group with instrument details

```sql
SELECT
    ig.GroupName,
    ig.Description,
    igm.InstrumentID,
    i.InstrumentDisplayName
FROM Hedge.InstrumentGroups ig WITH (NOLOCK)
JOIN Hedge.InstrumentGroupsMapping igm WITH (NOLOCK)
    ON ig.GroupID = igm.GroupID AND igm.IsActive = 1
JOIN Trade.Instrument i WITH (NOLOCK)
    ON igm.InstrumentID = i.InstrumentID
WHERE ig.GroupID = 100  -- Virtu UnManaged US Flow Direct
ORDER BY i.InstrumentDisplayName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11 (9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InstrumentGroups | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.InstrumentGroups.sql*
