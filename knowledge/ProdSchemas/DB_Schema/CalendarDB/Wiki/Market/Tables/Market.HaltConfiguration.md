# Market.HaltConfiguration

> Configuration table defining which instruments or exchanges should be monitored for trading halt events, specifying the market data provider and account to use for each subscription.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | RowID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (1 PK + 3 NC) |

---

## 1. Business Meaning

This table defines the halt monitoring configuration - which instruments or exchanges should be subscribed to market data streams for detecting trading halt events (circuit breakers, regulatory halts, etc.). The Halt Service reads this table on startup to subscribe instruments to the appropriate market data provider streams.

Without this table, the Halt Service would not know which instruments to monitor for halt events. When a trading halt occurs on an exchange or instrument, the Halt Service needs to detect it in real-time and notify the platform so that trading can be suspended.

Each row represents a subscription configuration: the target entity (identified by `ID` + `ConfigurationIdType`), the market data provider (e.g., Bloomberg), and the provider account to use. Data is managed via the Market State OPS API's CRUD endpoints (`/api/v1.0/configurations/halt`). On create/update/delete, a `HaltConfigurationChangedEvent` is published to RabbitMQ (`MarketStateEvents` exchange), and the Halt Service's background listener automatically subscribes new instruments without requiring a restart.

Currently the table is empty (0 rows) in production, indicating halt monitoring may not yet be fully deployed.

---

## 2. Business Logic

### 2.1 ConfigurationIdType Polymorphism

**What**: The `ID` column is polymorphic - its meaning depends on `ConfigurationIdType`.

**Columns/Parameters Involved**: `ID`, `ConfigurationIdType`

**Rules**:
- ConfigurationIdType = 1 (Instrument): `ID` is an InstrumentID. The Halt Service subscribes this specific instrument to the market data stream.
- ConfigurationIdType = 2 (Exchange): `ID` is an ExchangeID. The Halt Service queries Security Master API to resolve all instrument IDs for that exchange, then subscribes them all.
- Unknown type: Warning is logged, no subscriptions added.

**Diagram**:
```
ConfigurationIdType=1 (Instrument)
  ID=1234 → Subscribe instrument 1234 directly

ConfigurationIdType=2 (Exchange)
  ID=4 → Query Security Master API for all instruments on exchange 4
       → Subscribe [inst1, inst2, inst3, ...] in bulk
```

### 2.2 Provider Enum

**What**: ProviderID identifies the market data provider for halt event streams.

**Columns/Parameters Involved**: `ProviderID`

**Rules**:
- ProviderID = 1 (Bloomberg): Bloomberg market data stream is the halt event source
- Note: This ProviderID is NOT the same as CalenderProviders.ProviderID (which tracks calendar data providers). The halt ProviderID maps to a different enum in the application code.

### 2.3 Event-Driven Subscription Updates

**What**: CRUD operations on this table trigger real-time subscription changes via RabbitMQ events.

**Columns/Parameters Involved**: All columns

**Rules**:
- On CREATE: `HaltConfigurationChangedEvent` with ChangeType=Created is published. Halt Service processes Created events only - resolves instruments and subscribes.
- On UPDATE: Event published with ChangeType=Updated. Currently skipped by the Halt Service consumer.
- On DELETE: Event published with ChangeType=Deleted. Currently skipped by the Halt Service consumer.
- Events published to exchange `MarketStateEvents`, routing key `MarketState.HaltConfiguration.#`

---

## 3. Data Overview

Table is currently empty (0 rows). No halt configurations have been deployed to production yet.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RowID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-increment surrogate primary key. Used for individual record operations (GET by RowID, UPDATE by RowID, DELETE by RowID). |
| 2 | ID | int | NO | - | VERIFIED | Polymorphic entity identifier. Meaning depends on ConfigurationIdType: when ConfigurationIdType=1, this is an InstrumentID; when ConfigurationIdType=2, this is an ExchangeID. Validated by FluentValidation: must be > 0. |
| 3 | ConfigurationIdType | int | NO | - | VERIFIED | Type classifier for the ID column: 1 = Instrument (ID is InstrumentID, subscribe directly), 2 = Exchange (ID is ExchangeID, resolve to instruments via Security Master API). Maps to `ConfigurationIdType` C# enum. Validated: must be a defined enum value. |
| 4 | ProviderID | int | NO | - | VERIFIED | Market data provider for halt event streams. 1 = Bloomberg. Maps to `Provider` C# enum (different from CalenderProviders.ProviderID). Determines which market data subscription API to use. Validated: must be a defined enum value. |
| 5 | AccountID | varchar(255) | NO | - | VERIFIED | Provider account identifier for the market data subscription. Examples: "BBGPricing", "RawRedistribution". Determines which credentials and data tier to use for the subscription. Validated: must not be empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Market.CalenderProviders | Implicit (different domain) | ProviderID here maps to halt data providers (Bloomberg=1), not calendar providers (eToro=0, Xignite=1). Different enum. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.GetAllHaltConfigurations | N/A | Read | Reads all rows for admin UI and startup |
| Market.GetHaltConfigurationsByIdTypeAndId | ConfigurationIdType, ID | Read | Filters by entity type and ID |
| Market.GetHaltConfigurationsByProviderAndAccount | ProviderID, AccountID | Read | Filters by provider and account |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.GetAllHaltConfigurations | Stored Procedure | READER - returns all halt configurations |
| Market.GetHaltConfigurationsByIdTypeAndId | Stored Procedure | READER - filtered by type and ID |
| Market.GetHaltConfigurationsByProviderAndAccount | Stored Procedure | READER - filtered by provider and account |
| Market State OPS API | External Service | CRUD operations via Dapper |
| Halt Service | External Service | Reads configs on startup, subscribes via event consumer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HaltConfiguration | CLUSTERED PK | RowID | - | - | Active |
| IX_HaltConfiguration_Account | NC | AccountID | ID, ConfigurationIdType, ProviderID | - | Active |
| IX_HaltConfiguration_IdType_ID | NC | ConfigurationIdType, ID | ProviderID, AccountID | - | Active |
| IX_HaltConfiguration_Provider_Account | NC | ProviderID, AccountID | ID, ConfigurationIdType | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HaltConfiguration | PRIMARY KEY | Unique RowID per configuration entry |

---

## 8. Sample Queries

### 8.1 Get all halt configurations

```sql
SELECT RowID, ID, ConfigurationIdType, ProviderID, AccountID
FROM Market.HaltConfiguration WITH (NOLOCK);
```

### 8.2 Find configurations for Bloomberg provider

```sql
SELECT RowID, ID, ConfigurationIdType, AccountID
FROM Market.HaltConfiguration WITH (NOLOCK)
WHERE ProviderID = 1;
```

### 8.3 Find all instrument-level configurations

```sql
SELECT RowID, ID AS InstrumentID, ProviderID, AccountID
FROM Market.HaltConfiguration WITH (NOLOCK)
WHERE ConfigurationIdType = 1
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Market State OPS API - Halt Configurations CRUD](https://etoro-jira.atlassian.net/wiki/spaces/view/14145519620) | Confluence | Full CRUD API specification, data model (ConfigurationIdType: 1=Instrument, 2=Exchange; Provider: 1=Bloomberg), event publishing via RabbitMQ MarketStateEvents, FluentValidation rules, Halt Service consumer that processes Created events |
| [Market State OPS API - Halt Configurations HLD](https://etoro-jira.atlassian.net/wiki/spaces/view/13600063792) | Confluence | High-level design for halt configuration system |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.HaltConfiguration | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.HaltConfiguration.sql*
