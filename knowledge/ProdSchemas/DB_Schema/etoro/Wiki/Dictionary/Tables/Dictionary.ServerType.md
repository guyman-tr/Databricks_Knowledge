# Dictionary.ServerType

## 1. Business Meaning

**What it is**: A lookup table classifying the types of servers in eToro's trading infrastructure. Each entry represents a distinct server role — from database servers to price providers, hedge servers, and game (trading) servers.

**Why it exists**: eToro's distributed architecture has many specialized server types. This table provides a standardized classification used by the error messaging system (`Dictionary.ErrorMessage`) and game server configuration (`Dictionary.GameServer`) to categorize messages and instances by their originating server type.

**How it works**: Server types are referenced by `Dictionary.ErrorMessage.ServerTypeID` to route error messages to the correct monitoring category, and by `Dictionary.GameServer.ServerTypeID` to classify trading server instances. The `Broker.actDispatcher` procedure also references server types in broker communication routing.

---

## 2. Business Logic

### Server Type Classifications
| ID | Name | Role |
|----|------|------|
| 0 | Unknown | Default/unclassified |
| 1 | General | General-purpose application server |
| 2 | Distributor | Message distribution/relay server |
| 3 | DBFrontOffice | Front-office database server |
| 4 | DBBackOffice | Back-office database server |
| 5 | GameServer | Trading engine server (executes trades) |
| 6 | HedgeServer | Hedge execution server |
| 7 | PriceServer | Price distribution/aggregation server |
| 8 | PriceProviders | External price data feed providers |
| 13 | PriceDetector | Price anomaly/spike detection server |

### Gap Analysis
IDs 9-12 are unused — likely reserved or deprecated server types that were removed.

---

## 3. Data Overview

| ServerTypeID | Name | Business Meaning |
|-------------|------|------------------|
| 0 | Unknown | Unclassified server |
| 3 | DBFrontOffice | Front-office database |
| 5 | GameServer | Trading engine |
| 6 | HedgeServer | Hedge execution |
| 7 | PriceServer | Price distribution |
| 13 | PriceDetector | Price anomaly detection |

*10 rows — infrastructure server classifications*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **ServerTypeID** | int | NOT NULL | — | Primary key. Server type identifier. Range: 0-13 (with gaps at 9-12). | `MCP` |
| **Name** | char(20) | NOT NULL | — | Fixed-width server type name. Enforced unique by index `DSVT_NAME`. Padded with spaces due to char(20) type. | `MCP+DDL` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Dictionary.ErrorMessage | ServerTypeID | FK | Error messages categorized by server origin |
| Dictionary.GameServer | ServerTypeID | FK | Trading server instances classified by type |
| Broker.actDispatcher | ServerTypeID | Usage | Broker communication routing |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Dictionary.ErrorMessage` — error message templates by server type
- `Dictionary.GameServer` — trading server instance classification
- `Broker.actDispatcher` — broker routing logic

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `ServerTypeID` (clustered) |
| Indexes | `DSVT_NAME` — unique nonclustered on `Name` |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Fill Factor | 90% |
| Row Count | 10 |

---

## 8. Sample Queries

```sql
-- Get all server types
SELECT  ServerTypeID, RTRIM(Name) AS Name
FROM    Dictionary.ServerType WITH (NOLOCK)
ORDER BY ServerTypeID;

-- Error messages by server type
SELECT  RTRIM(ST.Name) AS ServerType, COUNT(*) AS ErrorCount
FROM    Dictionary.ErrorMessage EM WITH (NOLOCK)
JOIN    Dictionary.ServerType ST WITH (NOLOCK) ON ST.ServerTypeID = EM.ServerTypeID
GROUP BY RTRIM(ST.Name)
ORDER BY ErrorCount DESC;

-- Game servers by type
SELECT  GS.ServerID, GS.ServerName, RTRIM(ST.Name) AS ServerType
FROM    Dictionary.GameServer GS WITH (NOLOCK)
JOIN    Dictionary.ServerType ST WITH (NOLOCK) ON ST.ServerTypeID = GS.ServerTypeID;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Server type classification is an infrastructure-level taxonomy.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (10 rows), codebase traced (3 consumers: ErrorMessage FK, GameServer FK, Broker.actDispatcher)*
