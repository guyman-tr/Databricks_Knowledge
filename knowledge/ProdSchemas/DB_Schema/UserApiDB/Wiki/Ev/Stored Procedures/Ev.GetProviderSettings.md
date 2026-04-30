# Ev.GetProviderSettings

> Returns API configuration settings (credentials, profile IDs) for a specific EV provider and country.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryId + @ProviderId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Ev.GetProviderSettings returns the API configuration values needed to connect to a specific EV provider for a given country. Returns SettingId and Value pairs (ProfileId, ProfileVersion, UserName, Password). Used during EV provider initialization.

---

## 2. Business Logic

No complex business logic. Single SELECT filtered by ProviderId + CountryId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryId | int (IN) | NO | - | CODE-BACKED | Country for which to get provider settings. |
| 2 | @ProviderId | int (IN) | NO | - | CODE-BACKED | EV provider to get settings for. |

Output: SettingId, Value.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Ev.ProviderSetting | SELECT FROM | Provider settings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.GetProviderSettings (procedure)
  +-- Ev.ProviderSetting (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Ev.ProviderSetting | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get settings for GBG + UK
```sql
EXEC Ev.GetProviderSettings @CountryId = 44, @ProviderId = 2
```

### 8.2 Direct equivalent
```sql
SELECT SettingId, Value FROM Ev.ProviderSetting WITH (NOLOCK) WHERE ProviderId = 2 AND CountryId = 44
```

### 8.3 With setting names
```sql
SELECT eps.Value AS SettingType, ps.Value FROM Ev.ProviderSetting ps WITH (NOLOCK)
JOIN Dictionary.EvProviderSettings eps WITH (NOLOCK) ON ps.SettingId = eps.SettingId
WHERE ps.ProviderId = 2 AND ps.CountryId = 44
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Ev.GetProviderSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Ev/Stored Procedures/Ev.GetProviderSettings.sql*
