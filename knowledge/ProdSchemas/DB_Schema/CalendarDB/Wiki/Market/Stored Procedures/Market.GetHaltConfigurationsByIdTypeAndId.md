# Market.GetHaltConfigurationsByIdTypeAndId

> Retrieves halt monitoring configurations filtered by entity type (Instrument/Exchange) and entity ID, used to look up all subscriptions for a specific instrument or exchange.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Filtered SELECT from HaltConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns halt configurations matching a specific `ConfigurationIdType` and `ID` combination. For example, to find all halt subscriptions for InstrumentID=1234, call with `@ConfigurationIdType=1, @ID=1234`. To find all subscriptions for ExchangeID=4, call with `@ConfigurationIdType=2, @ID=4`.

Called by the Market State OPS API's `GET /halt/{id}?configurationIdType=X` endpoint. Uses NOLOCK and leverages the `IX_HaltConfiguration_IdType_ID` covering index for efficient filtering.

---

## 2. Business Logic

No complex logic. Parameterized WHERE filter on ConfigurationIdType and ID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigurationIdType | INT | NO | - | VERIFIED | Entity type filter: 1=Instrument, 2=Exchange. Maps to ConfigurationIdType enum. |
| 2 | @ID | INT | NO | - | VERIFIED | Entity ID filter: InstrumentID when type=1, ExchangeID when type=2. |

**Return Columns**: Same as GetAllHaltConfigurations (RowID, ID, ConfigurationIdType, ProviderID, AccountID).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | Market.HaltConfiguration | Read | Filtered SELECT by ConfigurationIdType and ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market State OPS API | GET /halt/{id} | Caller | Returns configs for a specific instrument or exchange |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.GetHaltConfigurationsByIdTypeAndId (procedure)
└── Market.HaltConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.HaltConfiguration | Table | READER - filtered SELECT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market State OPS API | External Service | GET /halt/{id} endpoint |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses `IX_HaltConfiguration_IdType_ID` covering index on the target table.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get halt configs for a specific instrument

```sql
EXEC Market.GetHaltConfigurationsByIdTypeAndId @ConfigurationIdType = 1, @ID = 1234;
```

### 8.2 Get halt configs for a specific exchange

```sql
EXEC Market.GetHaltConfigurationsByIdTypeAndId @ConfigurationIdType = 2, @ID = 4;
```

### 8.3 Equivalent direct query

```sql
SELECT RowID, ID, ConfigurationIdType, ProviderID, AccountID
FROM Market.HaltConfiguration WITH (NOLOCK)
WHERE ConfigurationIdType = 1 AND ID = 1234;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Market State OPS API - Halt Configurations CRUD](https://etoro-jira.atlassian.net/wiki/spaces/view/14145519620) | Confluence | "Get configurations by ID type and ID value." Called by GET /halt/{id} endpoint. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.GetHaltConfigurationsByIdTypeAndId | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.GetHaltConfigurationsByIdTypeAndId.sql*
