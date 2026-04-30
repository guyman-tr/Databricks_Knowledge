# Dictionary.ServiceType

## 1. Business Meaning

**What it is**: A lookup table identifying the types of microservices in eToro's trading platform architecture. Each entry represents a distinct service role — from lobby and login services to trading engines, hedge servers, price servers, and API gateways.

**Why it exists**: eToro's trading platform consists of ~48 distinct service types. The `Internal.ServiceConfiguration` table stores per-service configuration key-value pairs with an FK to this table, enabling centralized configuration management for all services. This dictionary provides the canonical list of all service types in the platform.

**How it works**: The `Internal.ServiceConfiguration` table references `ServiceTypeID` via an explicit FK to scope configuration entries to specific services. Each service instance reads its configuration filtered by its `ServiceTypeID`. The configuration table is temporal (system-versioned) with full audit history for change tracking.

---

## 2. Business Logic

### Service Categories
**Core Trading** (IDs 1-10):
- LOBBY, ORDER, LOGIN, REG, INFO, GATE, CHAT, TRADE, HEDGE, PRICE

**Infrastructure** (IDs 11-21):
- MANAGER, CANDELS, PRICE_DETECT, MONEY_MANAGER, CENTRAL_EXPOSURES, OME, RATE_LOGGER, EVENT_WRITER, MSL, SYS_CONN_BROKER, PROVIDER_CONNECTIVITY

**Stocks & Crypto** (IDs 22-27):
- STOCKS_SYSTEM, CLIENT_DATA_DISTRIBUTOR, ACCOUNT_LIQUIDATION, BONUS_STOP_LOSS, CRYPTO_EXCHANGE, CRYPTO_LOG

**Modern API Layer** (IDs 30-43):
- API, PUBLISHER, DEALING_ALERT, FRONT_TRADING_API, BACK_TRADING_API, USER_API, FAPI, STS, CNP_EVENT_WRITER, CNP_INSTRUMENT_EVENT_WRITER, SERVICE_BROKER_READER, TRADING_ANTI_CORRUPTION_LAYER, CNP_NOTIFICATION, SAGA_STATE_ENGINE

**Specialized** (IDs 45-99):
- TRAILING_STOP_LOSS_PERSISTOR_DB/REDIS, SKEW_COST_MODEL, CONFIGURATION_MANAGER, MONITOR

---

## 3. Data Overview

| ServiceTypeID | ServiceName | Business Meaning |
|--------------|-------------|------------------|
| 1 | LOBBY_SRV_TYPE | User lobby/session service |
| 8 | TRADE_SRV_TYPE | Core trading engine |
| 9 | HEDGE_SRV_TYPE | Hedge execution service |
| 10 | PRICE_SRV_TYPE | Price distribution service |
| 33 | FRONT_TRADING_API | Front-end trading API gateway |
| 99 | MONITOR_SRV_TYPE | System monitoring service |

*48 rows — complete service type registry (note: ID 28 and 44 are gaps)*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ServiceTypeID** | int | NOT NULL | — | Primary key. Service type identifier. Range: 1-99 with gaps. Convention: `{SERVICE_NAME}_SRV_TYPE` for legacy services; newer services use short names (OME, MSL, FAPI, STS). | `MCP` |
| **ServiceName** | varchar(50) | NOT NULL | — | Uppercase service identifier following `{NAME}_SRV_TYPE` convention for legacy services. Used in `Internal.ServiceConfiguration.ServerTypeName` for human-readable configuration scoping. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Internal.ServiceConfiguration | ServerType | FK_InternalServiceConfiguration_DictionaryServiceType | Service configuration entries scoped by service type (temporal table with audit) |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Internal.ServiceConfiguration` — per-service configuration store (temporal, with full audit triggers)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ServiceTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | PRIMARY |
| Fill Factor | 95% |
| Row Count | 48 |

---

## 8. Sample Queries

```sql
-- Get all service types
SELECT  ServiceTypeID, ServiceName
FROM    Dictionary.ServiceType WITH (NOLOCK)
ORDER BY ServiceTypeID;

-- Count configuration entries per service
SELECT  ST.ServiceName, COUNT(*) AS ConfigCount
FROM    Internal.ServiceConfiguration SC WITH (NOLOCK)
JOIN    Dictionary.ServiceType ST WITH (NOLOCK) ON ST.ServiceTypeID = SC.ServerType
GROUP BY ST.ServiceName
ORDER BY ConfigCount DESC;

-- Find all configuration for the trading engine
SELECT  SC.ConfigurationKey, SC.Value, SC.IsApplicative
FROM    Internal.ServiceConfiguration SC WITH (NOLOCK)
WHERE   SC.ServerType = 8
ORDER BY SC.ConfigurationKey;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Service types are an infrastructure-level registry for the trading platform's microservice architecture.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (48 rows), codebase traced (1 FK consumer: Internal.ServiceConfiguration with temporal + audit triggers)*
