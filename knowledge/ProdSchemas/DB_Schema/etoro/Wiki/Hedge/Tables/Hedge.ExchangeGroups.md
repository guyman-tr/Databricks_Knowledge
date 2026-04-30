# Hedge.ExchangeGroups

> Second step in the CES sharding chain: maps each financial exchange to a CES instrument group, determining which Central Exposure Service shard processes instruments listed on that exchange.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ExchangeID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Hedge.ExchangeGroups is the middle tier of the CES (Central Exposure Service) sharding routing chain. CES shards instrument exposure aggregation across multiple service instances by grouping exchanges into logical clusters and assigning CES instances to those clusters. This table provides the Exchange -> Group mapping.

The three-table sharding chain is:
1. `Trade.InstrumentMetaData` - maps each Instrument to an Exchange
2. **`Hedge.ExchangeGroups`** - maps each Exchange to a Group (this table)
3. `Hedge.CESInstanceToGroup` - maps each CES instance to a Group

A CES instance processes all instruments whose exchange maps to the instance's group. For example, in production: ExchangeID 8 (Digital Currency) -> GroupID 1 -> InstanceID 1 (ces-1), meaning all crypto instruments are processed by the ces-1 shard.

The table holds 28 rows. It is updated via `Trade.AddExchangesHedgeGroups` (MERGE upsert using a TVP), which is the API-level mechanism for reconfiguring exchange-to-group assignments when adding new exchanges or rebalancing shard loads.

**Note on environment vs production**: In this environment (test/clone DB), all exchanges map to GroupID 1 ("Futures") except ExchangeIDs 33 and 154 which map to GroupID 2. In production, the key routing distinction is ExchangeID 8 (Digital Currency/Crypto) -> GroupID 1 (exclusive crypto shard), all others -> GroupID 2. The test environment data does not reflect the production sharding topology.

---

## 2. Business Logic

### 2.1 Exchange-to-Group Routing

**What**: Each financial exchange is assigned to a CES group, which routes all instruments on that exchange to the CES instance(s) responsible for that group.

**Columns/Parameters Involved**: `ExchangeID`, `GroupID`

**Rules**:
- ExchangeID is the PK - one group assignment per exchange.
- GroupID must match a GroupID in Hedge.InstrumentGroups and Hedge.CESInstanceToGroup (no DDL FK enforces this - it is an operational contract).
- The routing path: `Instrument -> Trade.InstrumentMetaData.ExchangeID -> Hedge.ExchangeGroups.GroupID -> Hedge.CESInstanceToGroup.InstanceID` -> CES shard.
- When a new exchange is added to the platform (e.g., a new stock exchange for CFD instruments), a row must be added here before CES can correctly route its instruments.
- All exchanges not mapped here will not be handled by any CES shard - this would cause missed exposure aggregation for instruments on unmapped exchanges.

**Production topology (from Confluence "Mapping CES instance to Exchanges")**:
- ExchangeID 8 (Digital Currency/Crypto) -> GroupID 1 -> ces-1 instance exclusively
- All other exchanges (FX, Commodity, CFD, Nasdaq, NYSE, European/Asian stock exchanges) -> GroupID 2 -> ces-2+

### 2.2 MERGE Upsert via TVP

**What**: The table is updated via a MERGE operation, not direct DML, ensuring atomicity of multi-exchange updates.

**Columns/Parameters Involved**: `ExchangeID`, `GroupID`

**Rules**:
- `Trade.AddExchangesHedgeGroups` accepts a TVP of type `Trade.ExchangeHedgeGroupsTbl` (read-only).
- MERGE logic: if ExchangeID exists, UPDATE GroupID; if new, INSERT the row. No DELETE - removals must be done manually.
- Called when: adding a new exchange to the platform, reassigning an exchange to a different CES shard (e.g., after a rebalancing decision), or during environment setup.

---

## 3. Data Overview

28 rows as of 2026-03-19. Static configuration table - changes only when exchanges are added or CES sharding is reconfigured.

| ExchangeID | GroupID | GroupName (this env) | Notes |
|-----------|---------|---------------------|-------|
| 0 | 1 | Futures | Default/unknown exchange |
| 1-21 | 1 | Futures | FX through various exchanges (this env) |
| 24, 30, 31, 155 | 1 | Futures | Additional exchanges |
| 33 | 2 | (null) | Not in InstrumentGroups in this env |
| 154 | 2 | (null) | Not in InstrumentGroups in this env |

**Production note** (Confluence): ExchangeID 8 ("Digital Currency") -> GroupID 1; all others -> GroupID 2. Test environment data differs.

Exchange ID reference (from Confluence "Mapping CES instance to Exchanges"):

| ExchangeID | Exchange Name |
|-----------|---------------|
| 1 | FX |
| 2 | Commodity |
| 3 | CFD |
| 4 | Nasdaq |
| 5 | NYSE |
| 6 | FRA (Frankfurt) |
| 7 | LSE (London) |
| 8 | Digital Currency |
| 9 | Euronext Paris |
| 10 | Bolsa De Madrid |
| 11 | Borsa Italiana |
| 12 | SIX (Switzerland) |
| 13 | TYO (Tokyo) |
| 14 | Oslo Stock Exchange |
| 15 | Stockholm Stock Exchange |
| 16 | Copenhagen Stock Exchange |
| 17 | Helsinki Stock Exchange |
| 18 | Toronto Stock Exchange |
| 19 | OTC Markets |
| 20 | Chicago Board Options Exchange |
| 21 | Hong Kong Exchanges |
| 22 | Euronext Lisbon |
| 23 | Euronext Brussels |
| 24 | Tadawul |
| 30 | Euronext Amsterdam |
| 31 | Sydney |
| 32 | Vienna |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | ATLASSIAN-BACKED | The financial exchange identifier. Implicitly references Trade.InstrumentMetaData.ExchangeID - no DDL FK. Clustered PK - one group assignment per exchange. When a new exchange is onboarded, a row must be added here to enable CES routing for its instruments. |
| 2 | GroupID | int | NO | - | ATLASSIAN-BACKED | The CES instrument group this exchange belongs to. Logically FK to Hedge.InstrumentGroups(GroupID). All instruments listed on this exchange will be processed by whichever CES instance(s) have this GroupID in Hedge.CESInstanceToGroup. No DDL FK enforces this relationship. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeID | Trade.InstrumentMetaData | Implicit (no DDL FK) | Exchange used by instruments via InstrumentMetaData.ExchangeID |
| GroupID | Hedge.InstrumentGroups | Implicit (no DDL FK) | Group definition and name |
| GroupID | Hedge.CESInstanceToGroup | Logical (no DDL FK) | Paired sharding table - CES instances are assigned to the same GroupID values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AddExchangesHedgeGroups | @ExchangeGroups TVP | Writer | MERGE upsert - updates Exchange->Group assignments |
| CES application service | ExchangeID lookup | Reader | CES resolves Exchange->Group to determine which shard owns an instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExchangeGroups (table)
  - Logically references Trade.InstrumentMetaData (ExchangeID)
  - Logically references Hedge.InstrumentGroups (GroupID)
  - Complementary: Hedge.CESInstanceToGroup (same GroupID namespace)
  - Written by: Trade.AddExchangesHedgeGroups (MERGE via TVP Trade.ExchangeHedgeGroupsTbl)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Logical source for ExchangeID values |
| Hedge.InstrumentGroups | Table | Logical FK target for GroupID |
| Trade.ExchangeHedgeGroupsTbl | User Defined Type | TVP type used by AddExchangesHedgeGroups to pass new assignments |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AddExchangesHedgeGroups | Procedure | Writer - MERGE upsert of Exchange->Group assignments |
| Hedge.CESInstanceToGroup | Table | Complementary sharding table (CES Instance->Group, same GroupID namespace) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_GroupIDToExchangeID | CLUSTERED PK | ExchangeID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_GroupIDToExchangeID | PRIMARY KEY | ExchangeID - one group assignment per exchange |

---

## 8. Sample Queries

### 8.1 Full CES sharding topology (Exchange->Group->CES Instance)
```sql
SELECT EG.ExchangeID, IG.GroupName, CIG.InstanceID AS CESInstance
FROM Hedge.ExchangeGroups EG
LEFT JOIN Hedge.InstrumentGroups IG ON EG.GroupID = IG.GroupID
LEFT JOIN Hedge.CESInstanceToGroup CIG ON EG.GroupID = CIG.GroupID
ORDER BY EG.GroupID, EG.ExchangeID;
```

### 8.2 Find the CES shard for a specific instrument
```sql
SELECT IMD.InstrumentID, IMD.ExchangeID, EG.GroupID, IG.GroupName, CIG.InstanceID
FROM Trade.InstrumentMetaData IMD
JOIN Hedge.ExchangeGroups EG ON IMD.ExchangeID = EG.ExchangeID
JOIN Hedge.InstrumentGroups IG ON EG.GroupID = IG.GroupID
JOIN Hedge.CESInstanceToGroup CIG ON EG.GroupID = CIG.GroupID
WHERE IMD.InstrumentID = 100;
```

### 8.3 Count instruments per CES group
```sql
SELECT EG.GroupID, IG.GroupName, COUNT(1) AS InstrumentCount
FROM Trade.InstrumentMetaData IMD
JOIN Hedge.ExchangeGroups EG ON IMD.ExchangeID = EG.ExchangeID
LEFT JOIN Hedge.InstrumentGroups IG ON EG.GroupID = IG.GroupID
GROUP BY EG.GroupID, IG.GroupName
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Findings |
|--------|------|-------------|
| [CES Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710596048) | Confluence (DROD) | Sharding chain: InstrumentMetaData -> ExchangeGroups -> CESInstanceToGroup. ExchangeGroups is the Exchange->Group step. |
| [Mapping CES instance to Exchanges](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11895311487) | Confluence (DROD) | Production mapping: ExchangeID 8 (Digital Currency) -> GroupID 1 (ces-1 exclusive); all others -> GroupID 2. Full exchange list (IDs 1-32) with names. Data as of 2023-01-01. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 2 ATLASSIAN-BACKED, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExchangeGroups | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ExchangeGroups.sql*
