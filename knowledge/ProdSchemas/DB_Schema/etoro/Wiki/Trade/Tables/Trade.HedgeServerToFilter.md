# Trade.HedgeServerToFilter

> Junction table linking hedge execution servers to their instrument-status filter configurations, enabling per-server control over which positions contribute to periodic hedge operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | HedgeServerID + HedgeFilterID (composite PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 NC on HedgeFilterID) |

---

## 1. Business Meaning

Trade.HedgeServerToFilter is a many-to-many junction table that associates hedge execution servers with their hedge filter configurations. Each hedge server uses one or more filters (stored in Trade.HedgeFilter) to determine which instrument statuses are included or excluded when computing exposure and running periodic hedge operations. A single filter can be shared across multiple hedge servers, and a single server can use multiple filters - this table models both directions of that relationship.

This table exists because hedge servers need configurable, per-server rules for which positions drive hedging decisions. Without it, the system could not map each hedge server instance to its filter config, and the Hedge application (Hedge.GetHedgeServerSettings) could not retrieve the correct PeriodicControl XML for each server when it reads filter settings at startup or during runtime.

Data flows: Rows are created by the Trade.Insert_Trade_Instrument trigger on Trade.HedgeServer INSERT. When a new hedge server is added, the trigger inserts one default link (HedgeServerID, HedgeFilterID) where HedgeFilterID = HedgeServerID*1000+1. Additional links can be added manually for servers that use multiple filters. The Hedge application reads this table via JOIN to obtain filter config for each server. No DELETE or UPDATE paths exist in the Trade schema - links are append-only from the trigger; lifecycle management would be external.

---

## 2. Business Logic

### 2.1 Server-to-Filter Association

**What**: Each row binds one hedge server to one hedge filter, allowing a server to apply that filter's instrument-status rules during periodic hedge execution.

**Columns/Parameters Involved**: `HedgeServerID`, `HedgeFilterID`

**Rules**:
- A server can have one default filter (HedgeFilterID = HedgeServerID*1000+1) created automatically by Insert_Trade_Instrument
- A server can have multiple filters (e.g., HedgeServerID 1 links to 1001 and 1002) for advanced scenarios
- The composite PK (HedgeServerID, HedgeFilterID) prevents duplicate associations
- Hedge.GetHedgeServerSettings and related services JOIN through this table to resolve filter config per server

**Diagram**:
```
Trade.HedgeServer (HedgeServerID)
        |
        | 1:N via HedgeServerToFilter
        v
Trade.HedgeServerToFilter (HedgeServerID, HedgeFilterID)
        |
        | N:1
        v
Trade.HedgeFilter (HedgeFilterID, Value XML)
```

### 2.2 Default Filter Naming Convention

**What**: HedgeFilterID follows a naming convention that encodes the owning server for the default filter.

**Columns/Parameters Involved**: `HedgeFilterID`, `HedgeServerID`

**Rules**:
- Default filter: HedgeFilterID = HedgeServerID * 1000 + 1 (e.g., HedgeServerID 1 -> 1001, HedgeServerID 8 -> 8001)
- Additional filters use 1002, 2001, etc. - the convention supports multiple filters per server
- The Insert_Trade_Instrument trigger creates both the HedgeFilter row and the HedgeServerToFilter link with this formula

---

## 3. Data Overview

| HedgeServerID | HedgeFilterID | Meaning |
|---------------|---------------|---------|
| 1 | 1001 | Default filter for hedge server 1 - instrument status rules for periodic hedging |
| 1 | 1002 | Additional filter for hedge server 1 - alternate config (e.g., different instrument set) |
| 8 | 8001 | Default filter for hedge server 8 |
| 8 | 8002 | Additional filter for hedge server 8 |
| 12 | 12001 | Default filter for hedge server 12 - follows HedgeFilterID = HedgeServerID*1000+1 |

**Selection criteria for the 5 rows:**
- Rows showing the default convention (HedgeFilterID = HedgeServerID*1000+1)
- Rows showing servers with multiple filters to illustrate the many-to-many pattern
- Represents variety: single-filter servers (e.g., 2->2001, 3->3001) and multi-filter servers (1, 8, 12)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Foreign key to Trade.HedgeServer. Identifies the hedge execution server that uses this filter. Created by Insert_Trade_Instrument trigger when a new HedgeServer is inserted; value equals the inserted HedgeServerID. |
| 2 | HedgeFilterID | int | NO | - | CODE-BACKED | Foreign key to Trade.HedgeFilter. Identifies the XML filter config (PeriodicControl with InstStatus rules) applied by this server. Default convention: HedgeServerID*1000+1. A server can reference multiple HedgeFilterIDs for advanced routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK | The hedge server that uses this filter for periodic hedge operations |
| HedgeFilterID | Trade.HedgeFilter | FK | The filter config (instrument status include/exclude rules) applied by the server |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeServer Insert_Trade_Instrument trigger | INSERT | Writer | Creates default (HedgeServerID, HedgeFilterID) link when new hedge server is added |
| Hedge.GetHedgeServerSettings (external) | JOIN | Reader | Resolves filter config per server for Hedge application runtime |
| Trade.HedgeFilter doc sample queries | JOIN | Reader | Example queries that JOIN through this table to list filters by server |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a leaf table - CREATE TABLE has no FROM/JOIN/CROSS APPLY. FK targets (Trade.HedgeServer, Trade.HedgeFilter) are structural dependencies only, not code-level.

```
Trade.HedgeServerToFilter (table)
  (leaf - no FROM/JOIN in DDL)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK HedgeServerID references Trade.HedgeServer.HedgeServerID |
| Trade.HedgeFilter | Table | FK HedgeFilterID references Trade.HedgeFilter.HedgeFilterID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer Insert_Trade_Instrument trigger | Trigger | INSERTs into HedgeServerToFilter on HedgeServer INSERT |
| Hedge.GetHedgeServerSettings (Hedge schema) | Procedure | Reads filter config via JOIN through HedgeServerToFilter |
| Trade.HedgeFilter documentation | Sample queries | JOINs HedgeServerToFilter to resolve server-to-filter associations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TH2F | CLUSTERED | HedgeServerID, HedgeFilterID | - | - | Active |
| TH2F_HEDGEFILTER | NC | HedgeFilterID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TH2F | PRIMARY KEY | Enforces unique (HedgeServerID, HedgeFilterID) - no duplicate server-filter pairs |
| FK_THSV_TH2F | FOREIGN KEY | HedgeServerID references Trade.HedgeServer.HedgeServerID |
| FK_THFR_TH2F | FOREIGN KEY | HedgeFilterID references Trade.HedgeFilter.HedgeFilterID |

---

## 8. Sample Queries

### 8.1 List all hedge servers and their associated filters
```sql
SELECT TH2F.HedgeServerID,
       TH2F.HedgeFilterID,
       THF.Value
FROM Trade.HedgeServerToFilter TH2F WITH (NOLOCK)
INNER JOIN Trade.HedgeFilter THF WITH (NOLOCK)
    ON TH2F.HedgeFilterID = THF.HedgeFilterID
ORDER BY TH2F.HedgeServerID, TH2F.HedgeFilterID;
```

### 8.2 Get filters for a specific hedge server
```sql
SELECT TH2F.HedgeFilterID,
       THF.Value
FROM Trade.HedgeServerToFilter TH2F WITH (NOLOCK)
INNER JOIN Trade.HedgeFilter THF WITH (NOLOCK)
    ON TH2F.HedgeFilterID = THF.HedgeFilterID
WHERE TH2F.HedgeServerID = 8;
```

### 8.3 Resolve server and filter names for human-readable report
```sql
SELECT THS.HedgeServerID,
       THS.ServerIP,
       TH2F.HedgeFilterID,
       THF.Value
FROM Trade.HedgeServerToFilter TH2F WITH (NOLOCK)
INNER JOIN Trade.HedgeServer THS WITH (NOLOCK)
    ON TH2F.HedgeServerID = THS.HedgeServerID
INNER JOIN Trade.HedgeFilter THF WITH (NOLOCK)
    ON TH2F.HedgeFilterID = THF.HedgeFilterID
WHERE THS.IsActive = 1
ORDER BY THS.HedgeServerID, TH2F.HedgeFilterID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.HedgeServerToFilter | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.HedgeServerToFilter.sql*
