# Hedge.CESInstanceToGroup

> Sharding routing table for the Central Exposure Service (CES): maps each CES service instance to the instrument group it is responsible for processing, enabling horizontal scaling of exposure aggregation across instrument categories.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | InstanceID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Hedge.CESInstanceToGroup is the shard-assignment table for the Central Exposure Service (CES). CES is the service that continuously aggregates customer exposure by HedgeServer and InstrumentID, compares each aggregation cycle to the previously published exposure, and publishes the diff to RabbitMQ for downstream consumers (primarily the CBH hedging system). To handle scale, CES uses a sharding model that partitions instruments into groups and assigns CES instances to those groups.

The three-table sharding chain is:
1. `Trade.InstrumentMetaData` - maps each Instrument to an Exchange (e.g., Bitcoin -> ExchangeID 8 "Digital Currency")
2. `Hedge.ExchangeGroups` - maps each Exchange to a Group (e.g., ExchangeID 8 -> GroupID 1)
3. `Hedge.CESInstanceToGroup` - maps each CES instance to a Group (e.g., InstanceID 1 -> GroupID 1)

This table is the final link in that chain: given a CES instance ID (as configured in the service's AppConfig), it tells the instance which GroupID it owns. The CES instance then only processes instruments whose exchange maps to that group.

7 rows exist in the current environment representing the full set of deployed CES instances and their group assignments. Multiple instances can share the same GroupID for high-availability (primary + secondary) deployments.

---

## 2. Business Logic

### 2.1 CES Sharding Model

**What**: CES uses sharding to distribute exposure aggregation work across service instances, partitioned by instrument group.

**Columns/Parameters Involved**: `InstanceID`, `GroupID`

**Rules**:
- Each deployed CES process has a unique InstanceID configured in its AppConfig
- On startup, the CES reads this table to determine its GroupID (its shard assignment)
- The CES then only aggregates and publishes exposures for instruments belonging to exchanges in its assigned group
- Routing path: InstrumentID -> Trade.InstrumentMetaData.ExchangeID -> Hedge.ExchangeGroups.GroupID -> Hedge.CESInstanceToGroup.InstanceID
- ShardingEnabled must be True in AppConfig for this table to be respected (it is always True in production)

**Live data (7 rows)**:

| InstanceID | GroupID | Role |
|-----------|---------|------|
| 1 | 1 | ces-1 service - Digital Currency (Crypto) group exclusively |
| 2 | 3 | ces-2 service |
| 3 | 2 | ces-3 service - All-other exchanges group (FX, Commodity, CFD, Stocks) |
| 4 | 2 | ces-4 service - Same group as #3 (HA/secondary) |
| 5 | 4 | ces-5 service |
| 6 | 4 | ces-6 service - Same group as #5 (HA/secondary) |
| 7 | 4 | ces-7 service - Same group as #5/#6 (tertiary) |

### 2.2 Primary vs Secondary CES Instances

**What**: CES supports primary and secondary deployments for isolation and testing. Multiple InstanceIDs in the same GroupID represent primary + secondary service copies for the same shard.

**Rules**:
- CES secondary connects to a different SCB (Service Configuration Bus), separate RabbitMQ, and a different Redis/DB
- Secondary allows testing CES with real trading flow without affecting production hedging
- BroadcastKafka is only enabled on primary CES instances; only primary publishes to Kafka
- Hosts with "b" in the hostname are secondary deployments
- Since HedgeServer writes netting to Redis, Secondary CES always shows hedged=0 (it cannot see hedge-side netting)

### 2.3 Relationship to ExchangeGroups

**What**: CESInstanceToGroup and ExchangeGroups are complementary halves of the sharding configuration. ExchangeGroups determines which instruments go to which group; CESInstanceToGroup determines which CES service handles that group.

**Rules**:
- GroupID values must align between this table and Hedge.ExchangeGroups - there is no FK enforcing this
- GroupID 1 = Digital Currency (Crypto) group: Exchange 8 "Digital Currency" maps here; only InstanceID 1 handles it, meaning all crypto exposure is aggregated exclusively by the ces-1 service
- GroupID 2 = All other exchanges group: FX (1), Commodity (2), CFD (3), Nasdaq (4), NYSE (5), and most European/Asian stock exchanges map here
- No DDL FK enforces the GroupID -> InstrumentGroups relationship; the grouping is a logical convention maintained operationally

---

## 3. Data Overview

7 rows as of 2026-03-19. The table is small and static - it only changes when new CES instances are deployed or decommissioned.

| InstanceID | GroupID | Meaning |
|-----------|---------|---------|
| 1 | 1 | CES instance 1 handles GroupID 1 (Digital Currency/Crypto). Exclusive: all crypto instruments funnel here. |
| 2 | 3 | CES instance 2 handles GroupID 3. |
| 3 | 2 | CES instance 3 handles GroupID 2 (FX, Commodity, CFD, major stock exchanges). |
| 4 | 2 | CES instance 4 - same group as #3, HA/secondary for GroupID 2. |
| 5 | 4 | CES instance 5 handles GroupID 4. |
| 6 | 4 | CES instance 6 - same group as #5, HA/secondary for GroupID 4. |
| 7 | 4 | CES instance 7 - same group as #5/#6, tertiary for GroupID 4. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceID | int | NO | - | ATLASSIAN-BACKED | The unique identifier of a CES (Central Exposure Service) deployed instance. Configured in the service's AppConfig. Serves as the clustered PK - one row per CES service instance. Used by the CES at startup to look up its GroupID shard assignment. |
| 2 | GroupID | int | NO | - | ATLASSIAN-BACKED | The instrument group this CES instance is responsible for. Logically FK to Hedge.InstrumentGroups(GroupID) but no DDL FK enforces this. Combined with Hedge.ExchangeGroups (Exchange->Group) and Trade.InstrumentMetaData (Instrument->Exchange), determines the full set of instruments a CES instance aggregates. Multiple InstanceIDs can share the same GroupID for HA deployments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Hedge.InstrumentGroups | Implicit (no DDL FK) | GroupID logically references InstrumentGroups.GroupID - the instrument group definition. No FK constraint enforces this. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CES service (application) | AppConfig: InstanceID | Reader | CES reads this table at startup to determine its shard (GroupID). No stored procedure reader found in the Hedge schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.CESInstanceToGroup (table)
  - Logically references Hedge.InstrumentGroups (GroupID, no DDL FK)
  - Logically referenced by Hedge.ExchangeGroups (complementary sharding table)
  - Full chain: Trade.InstrumentMetaData -> Hedge.ExchangeGroups -> Hedge.CESInstanceToGroup
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentGroups | Table | Logical FK target for GroupID (no DDL constraint) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CES application service | External service | Reads InstanceID->GroupID mapping at startup for shard routing |
| Hedge.ExchangeGroups | Table | Complementary sharding table (Exchange->Group); must use same GroupID namespace |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_InstanceID | CLUSTERED PK | InstanceID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_InstanceID | PRIMARY KEY | InstanceID - one row per CES service instance |

---

## 8. Sample Queries

### 8.1 View all CES shard assignments
```sql
SELECT CIG.InstanceID, CIG.GroupID, IG.GroupName
FROM Hedge.CESInstanceToGroup CIG
LEFT JOIN Hedge.InstrumentGroups IG ON CIG.GroupID = IG.GroupID
ORDER BY CIG.GroupID, CIG.InstanceID;
```

### 8.2 Trace instrument to CES instance (full sharding chain)
```sql
-- Find which CES instance handles a specific instrument
SELECT
    IMD.InstrumentID,
    IMD.ExchangeID,
    EG.GroupID,
    CIG.InstanceID AS CESInstanceID
FROM Trade.InstrumentMetaData IMD
JOIN Hedge.ExchangeGroups EG ON IMD.ExchangeID = EG.ExchangeID
JOIN Hedge.CESInstanceToGroup CIG ON EG.GroupID = CIG.GroupID
WHERE IMD.InstrumentID = 100;  -- replace with target instrument
```

### 8.3 Count CES instances per group
```sql
SELECT GroupID, COUNT(1) AS InstanceCount
FROM Hedge.CESInstanceToGroup
GROUP BY GroupID
ORDER BY GroupID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Findings |
|--------|------|-------------|
| [CES Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710596048) | Confluence (DROD) | CES = Central Exposure Service. Aggregates by HedgeServer+InstrumentID. Sharding model: InstrumentMetaData -> ExchangeGroups -> CESInstanceToGroup. ShardingEnabled must be True. Primary vs Secondary deployment model. |
| [Mapping CES instance to Exchanges](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11895311487) | Confluence (DROD) | GroupID 1 = Digital Currency (Crypto), exclusively handled by ces-1. GroupID 2 = all other exchanges (FX, Commodity, CFD, stocks). Full exchange list with ExchangeIDs documented. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 2 ATLASSIAN-BACKED, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.CESInstanceToGroup | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.CESInstanceToGroup.sql*
