# Ev.ProviderSetting

> Stores API configuration values (credentials, profile IDs) for each EV provider per country.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Table |
| **Key Identifier** | ProviderId + SettingId + CountryId (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Ev.ProviderSetting stores the actual API configuration values for each EV provider per country. Each row is one setting value for a specific provider+country combination. Settings include API credentials, profile IDs, and profile versions (as defined by Dictionary.EvProviderSettings). Allows per-country provider configuration.

---

## 2. Business Logic

No complex business logic. Key-value configuration per provider+country.

---

## 3. Data Overview

N/A - configuration table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderId | int | NO | - | CODE-BACKED | Part of composite PK. FK to Dictionary.EvProvider. Which provider this setting is for. |
| 2 | SettingId | int | NO | - | CODE-BACKED | Part of composite PK. Implicit FK to Dictionary.EvProviderSettings. Setting type: 0=ProfileId, 1=ProfileVersion, 2=UserName, 3=Password. See [EV Provider Settings](_glossary.md#ev-provider-settings). |
| 3 | CountryId | int | NO | - | CODE-BACKED | Part of composite PK. Country this setting applies to. |
| 4 | Value | varchar(50) | NO | - | CODE-BACKED | The configuration value (API key, profile ID, username, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderId | Dictionary.EvProvider | Explicit FK | EV provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ev.GetProviderSettings | ProviderId+CountryId | SP reads | Returns settings for provider+country |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.ProviderSetting (table)
  +-- Dictionary.EvProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EvProvider | Table | FK: ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Ev.GetProviderSettings | SP | SELECT FROM |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EvProviderSetting | CLUSTERED PK | ProviderId, SettingId, CountryId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EvProviderSetting | FOREIGN KEY | ProviderId -> Dictionary.EvProvider |

---

## 8. Sample Queries

### 8.1 Settings for a provider+country
```sql
SELECT eps.Value AS SettingType, ps.Value FROM Ev.ProviderSetting ps WITH (NOLOCK)
JOIN Dictionary.EvProviderSettings eps WITH (NOLOCK) ON ps.SettingId = eps.SettingId
WHERE ps.ProviderId = @ProviderId AND ps.CountryId = @CountryId
```

### 8.2 All settings for a provider
```sql
SELECT c.Name AS Country, eps.Value AS Setting, ps.Value
FROM Ev.ProviderSetting ps WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ps.CountryId = c.CountryID
JOIN Dictionary.EvProviderSettings eps WITH (NOLOCK) ON ps.SettingId = eps.SettingId
WHERE ps.ProviderId = @ProviderId ORDER BY c.Name
```

### 8.3 Providers with settings
```sql
SELECT DISTINCT ep.Name FROM Ev.ProviderSetting ps WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON ps.ProviderId = ep.EvProviderId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Ev.ProviderSetting | Type: Table | Source: UserApiDB/UserApiDB/Ev/Tables/Ev.ProviderSetting.sql*
