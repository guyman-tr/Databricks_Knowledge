# Trade.HedgeFilter

> Stores XML filter configuration that controls which instrument statuses a hedge server includes or excludes when performing periodic hedge operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | HedgeFilterID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Trade.HedgeFilter holds per-hedge-server configuration that defines which instrument statuses are included or excluded during periodic hedge execution. Each row is an XML document (Value column) containing a PeriodicControl structure with InstStatus entries - each InstStatus has an ID (instrument status type) and a Status flag (true = include, false = exclude). Hedge servers use this filter to decide which positions contribute to exposure calculations and which are eligible for periodic hedging runs.

This table exists because different hedge servers may need different instrument-status rules for their hedging strategy. For example, a server handling only major forex might exclude certain instrument statuses (e.g., delisted, halted) while including active tradable ones. Without it, hedge servers would lack per-server control over which instruments drive periodic hedge decisions.

Data flows: Rows are created by the Trade.Insert_Trade_Instrument trigger on Trade.HedgeServer INSERT. When a new hedge server is added, the trigger inserts one HedgeFilter row with HedgeFilterID = HedgeServerID*1000+1 and a default PeriodicControl XML. Trade.HedgeServerToFilter links each HedgeServerID to its HedgeFilterID. The Hedge application (Hedge.GetHedgeServerSettings and related services) reads this table via HedgeServerToFilter to obtain filter config for each server.

---

## 2. Business Logic

### 2.1 PeriodicControl - Instrument Status Inclusion

**What**: The Value XML defines which instrument status types (by ID) are included or excluded from periodic hedge operations.

**Columns/Parameters Involved**: `Value`

**Rules**:
- Root element is PeriodicControl containing InstStatus child elements
- Each InstStatus has ID (integer) and Status (true/false string)
- Status=true: instrument status is included - positions with this status contribute to exposure and are eligible for periodic hedging
- Status=false: instrument status is excluded - positions with this status are filtered out of periodic hedge decisions
- Default trigger seed: IDs 1-16 get Status=true, IDs 17-19 and 27-32 get Status=false (major instrument types enabled, minors/crypto disabled by default)

**Diagram**:
```
HedgeFilter.Value (XML)
     |
     +-> <PeriodicControl>
           <InstStatus><ID>1</ID><Status>true</Status></InstStatus>
           <InstStatus><ID>2</ID><Status>true</Status></InstStatus>
           ...
           <InstStatus><ID>17</ID><Status>false</Status></InstStatus>
           ...
         </PeriodicControl>
     |
     v
Hedge server applies filter when computing exposure for periodic hedging
```

### 2.2 HedgeFilterID Naming Convention

**What**: HedgeFilterID encodes the owning hedge server to support one default filter per server.

**Columns/Parameters Involved**: `HedgeFilterID`, `Trade.HedgeServer.HedgeServerID`

**Rules**:
- HedgeFilterID = HedgeServerID * 1000 + 1 for the default filter created on hedge server insert
- Allows multiple filters per server in future (e.g., 1001, 1002 for HedgeServerID=1) though current trigger creates only one
- Trade.HedgeServerToFilter JOINs HedgeServerID to HedgeFilterID for lookup

---

## 3. Data Overview

| HedgeFilterID | Value (truncated) | Meaning |
|---------------|-------------------|---------|
| 1001 | `<PeriodicControl><InstStatus><ID>1</ID><Status>true</Status>...</InstStatus>...</PeriodicControl>` | Default filter for HedgeServerID=1. IDs 1-16 (major instrument types) included for periodic hedging; IDs 17-19, 27-32 excluded. |
| 2001 | `<PeriodicControl>...</PeriodicControl>` | Default filter for HedgeServerID=2. Same structure - each new hedge server gets one default PeriodicControl filter. |
| 3001 | `<PeriodicControl>...</PeriodicControl>` | Default filter for HedgeServerID=3. |
| 4001 | `<PeriodicControl>...</PeriodicControl>` | Default filter for HedgeServerID=4. |
| 5001 | `<PeriodicControl>...</PeriodicControl>` | Default filter for HedgeServerID=5. |

**Selection criteria for the 5 rows:**
- Rows represent typical default filters created by the Insert_Trade_Instrument trigger
- HedgeFilterID follows pattern HedgeServerID*1000+1
- All default filters share the same PeriodicControl structure (IDs 1-16 true, 17-19 and 27-32 false)

**CRITICAL - Rules for the "Meaning" column:**
- Each row links to a specific hedge server via HedgeFilterID div 1000
- The default XML enables major instrument types and disables minors/crypto for periodic hedge eligibility
- Filter can be updated manually (UPDATE Trade.HedgeFilter) to customize which instrument statuses a server hedges

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeFilterID | int | NO | - | CODE-BACKED | Primary key. Surrogate ID for the filter. Default convention: HedgeServerID*1000+1 when created by Insert_Trade_Instrument trigger. Referenced by Trade.HedgeServerToFilter.FK_THFR_TH2F. |
| 2 | Value | xml | NO | - | CODE-BACKED | PeriodicControl XML. Root element PeriodicControl with InstStatus children. Each InstStatus: ID (instrument status type), Status (true/false). Status=true includes that instrument status in periodic hedge eligibility; Status=false excludes it. Structure from Trade.Insert_Trade_Instrument trigger. |

**Rules for the Description column - this is where the MEANING lives:**
- HedgeFilterID ties to HedgeServer via HedgeServerToFilter; naming convention from trigger
- Value XML structure and semantics from trigger INSERT and hedge application consumption

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. The Value XML references instrument status IDs by convention (InstStatus/ID) but no formal FK exists.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeServerToFilter | HedgeFilterID | FK | Junction table linking hedge servers to their filters. One HedgeFilter can serve one or more HedgeServers. |
| Trade.Insert_Trade_Instrument (trigger) | INSERT target | Writer | Trigger on Trade.HedgeServer INSERT creates one HedgeFilter row per new hedge server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeFilter (table)
```

This object has no code-level dependencies. It is a leaf table with no FROM/JOIN/CROSS APPLY. FKs from HedgeServerToFilter point TO this table, not from it.

---

### 6.1 Objects This Depends On

No dependencies. Trade.HedgeFilter has no FK columns, computed columns, or object references in its DDL.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServerToFilter | Table | FK HedgeFilterID references Trade.HedgeFilter.HedgeFilterID |
| Trade.Insert_Trade_Instrument | Trigger | INSERTs into Trade.HedgeFilter on Trade.HedgeServer insert |
| Hedge schema (external) | Application | Hedge.GetHedgeServerSettings and related services read filter config via HedgeServerToFilter -> HedgeFilter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_THFR | CLUSTERED | HedgeFilterID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_THFR | PRIMARY KEY | Enforces unique HedgeFilterID |

---

## 8. Sample Queries

### 8.1 List all hedge filters with owning server
```sql
SELECT THF.HedgeFilterID,
       TH2F.HedgeServerID,
       THF.Value
FROM Trade.HedgeFilter THF WITH (NOLOCK)
INNER JOIN Trade.HedgeServerToFilter TH2F WITH (NOLOCK)
    ON THF.HedgeFilterID = TH2F.HedgeFilterID;
```

### 8.2 Get filter for a specific hedge server
```sql
SELECT THF.HedgeFilterID,
       THF.Value
FROM Trade.HedgeFilter THF WITH (NOLOCK)
INNER JOIN Trade.HedgeServerToFilter TH2F WITH (NOLOCK)
    ON THF.HedgeFilterID = TH2F.HedgeFilterID
WHERE TH2F.HedgeServerID = 1;
```

### 8.3 Parse InstStatus entries from Value XML
```sql
SELECT THF.HedgeFilterID,
       x.value('(ID)[1]', 'int') AS InstStatusID,
       x.value('(Status)[1]', 'varchar(10)') AS Status
FROM Trade.HedgeFilter THF WITH (NOLOCK)
CROSS APPLY THF.Value.nodes('/PeriodicControl/InstStatus') AS T(x)
WHERE THF.HedgeFilterID = 1001
ORDER BY InstStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL, Trigger, Grep, Atlassian*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.HedgeFilter | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.HedgeFilter.sql*
