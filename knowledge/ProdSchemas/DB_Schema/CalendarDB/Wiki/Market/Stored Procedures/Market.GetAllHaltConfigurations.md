# Market.GetAllHaltConfigurations

> Retrieves all halt monitoring configurations from Market.HaltConfiguration, used by the admin UI and Halt Service on startup to load the complete set of instrument/exchange subscriptions.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from HaltConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the entire contents of `Market.HaltConfiguration` - all configured halt monitoring subscriptions. It serves two consumers: (1) the admin UI that displays all configurations for management, and (2) the Halt Service on startup to load all subscriptions.

The procedure uses NOLOCK to avoid blocking other operations on the configuration table.

---

## 2. Business Logic

No complex business logic. Simple SELECT of all rows.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RowID | int | NO | - | CODE-BACKED | Auto-increment PK of the halt configuration record. |
| 2 | ID | int | NO | - | CODE-BACKED | Polymorphic entity ID (InstrumentID or ExchangeID depending on ConfigurationIdType). |
| 3 | ConfigurationIdType | int | NO | - | CODE-BACKED | Entity type classifier: 1=Instrument, 2=Exchange. |
| 4 | ProviderID | int | NO | - | CODE-BACKED | Market data provider: 1=Bloomberg. |
| 5 | AccountID | varchar(255) | NO | - | CODE-BACKED | Provider account identifier (e.g., "BBGPricing"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | Market.HaltConfiguration | Read | Reads all rows from the halt configuration table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market State OPS API | /halt/all endpoint | Caller | GET /api/v1.0/configurations/halt/all returns all configs for admin UI |
| Halt Service | Startup | Caller | Loads all configurations to initialize subscriptions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.GetAllHaltConfigurations (procedure)
└── Market.HaltConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.HaltConfiguration | Table | READER - SELECT all rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market State OPS API | External Service | Called via Dapper for admin UI |
| Halt Service | External Service | Called on startup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Market.GetAllHaltConfigurations;
```

### 8.2 Call from application code (Dapper pattern)

```sql
-- C# equivalent via Dapper:
-- var configs = await connection.QueryAsync<HaltConfiguration>("Market.GetAllHaltConfigurations", commandType: CommandType.StoredProcedure);
EXEC Market.GetAllHaltConfigurations;
```

### 8.3 Filter results client-side for instrument configs only

```sql
-- The procedure returns all rows; client filters by ConfigurationIdType
-- This is equivalent to what the admin UI does:
EXEC Market.GetAllHaltConfigurations;
-- Then in C#: configs.Where(c => c.ConfigurationIdType == 1)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Market State OPS API - Halt Configurations CRUD](https://etoro-jira.atlassian.net/wiki/spaces/view/14145519620) | Confluence | SP is called by GET /halt/all endpoint via Dapper. Returns all halt configurations for admin UI. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.GetAllHaltConfigurations | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.GetAllHaltConfigurations.sql*
