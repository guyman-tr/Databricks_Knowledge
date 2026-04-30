# Market.GetHaltConfigurationsByProviderAndAccount

> Retrieves halt monitoring configurations filtered by market data provider and account, used by services on startup to load subscriptions for a specific provider/account combination.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Filtered SELECT from HaltConfiguration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns halt configurations matching a specific provider and account combination. The Halt Service uses this on startup to load only the configurations relevant to its provider and account (e.g., Bloomberg/BBGPricing), rather than loading all configurations.

Called by the Market State OPS API's `GET /halt?ProviderId=X&AccountId=Y` endpoint. Uses NOLOCK and leverages the `IX_HaltConfiguration_Provider_Account` covering index.

---

## 2. Business Logic

No complex logic. Parameterized WHERE filter on ProviderID and AccountID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INT | NO | - | VERIFIED | Market data provider filter: 1=Bloomberg. Maps to Provider enum. |
| 2 | @AccountID | VARCHAR(255) | NO | - | VERIFIED | Provider account identifier filter (e.g., "BBGPricing", "RawRedistribution"). |

**Return Columns**: Same as GetAllHaltConfigurations (RowID, ID, ConfigurationIdType, ProviderID, AccountID).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | Market.HaltConfiguration | Read | Filtered SELECT by ProviderID and AccountID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market State OPS API | GET /halt | Caller | Service startup subscription loading |
| Halt Service | Startup | Caller | Loads configs for its specific provider/account |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.GetHaltConfigurationsByProviderAndAccount (procedure)
└── Market.HaltConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Market.HaltConfiguration | Table | READER - filtered SELECT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market State OPS API | External Service | GET /halt endpoint |
| Halt Service | External Service | Startup configuration loading |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses `IX_HaltConfiguration_Provider_Account` covering index.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get Bloomberg BBGPricing configurations

```sql
EXEC Market.GetHaltConfigurationsByProviderAndAccount @ProviderID = 1, @AccountID = 'BBGPricing';
```

### 8.2 Get all configurations for a provider

```sql
EXEC Market.GetHaltConfigurationsByProviderAndAccount @ProviderID = 1, @AccountID = 'RawRedistribution';
```

### 8.3 Equivalent direct query

```sql
SELECT RowID, ID, ConfigurationIdType, ProviderID, AccountID
FROM Market.HaltConfiguration WITH (NOLOCK)
WHERE ProviderID = 1 AND AccountID = 'BBGPricing';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Market State OPS API - Halt Configurations CRUD](https://etoro-jira.atlassian.net/wiki/spaces/view/14145519620) | Confluence | "Get configurations by provider + account (used by services on startup)." |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Market.GetHaltConfigurationsByProviderAndAccount | Type: Stored Procedure | Source: CalendarDB/CalendarDB/Market/Stored Procedures/Market.GetHaltConfigurationsByProviderAndAccount.sql*
