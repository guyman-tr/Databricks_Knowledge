# Dictionary.EvProviderSettings

> Lookup table defining configuration setting types for Electronic Verification provider integrations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SettingId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.EvProviderSettings defines the types of configuration parameters required to integrate with each Electronic Verification provider. Each EV provider (GBG, Trulioo, Au10tix, etc.) needs API credentials and profile settings to operate. This table normalizes those setting types so they can be stored consistently across providers.

This table enables multi-provider EV configuration without hardcoding credentials. Each provider can have different values for the same setting types (e.g., different API usernames), and new providers can be onboarded by simply adding rows to a configuration table that references these setting types.

Settings are read during EV provider initialization when the system needs to authenticate against a provider's API. The ProfileId and ProfileVersion identify the provider account, while UserName and Password provide authentication.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| SettingId | Value | Meaning |
|---|---|---|
| 0 | ProfileId | Provider-specific account or profile identifier used to select the correct verification configuration |
| 1 | ProfileVersion | Version identifier for the provider integration profile - supports A/B testing or gradual migration between versions |
| 2 | UserName | API authentication username for connecting to the provider's verification service |
| 3 | Password | API authentication secret/password for the provider service (stored encrypted in configuration tables) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettingId | int | NO | - | CODE-BACKED | Primary key. Setting type: 0=ProfileId, 1=ProfileVersion, 2=UserName, 3=Password. See [EV Provider Settings](_glossary.md#ev-provider-settings). |
| 2 | Value | varchar(30) | NO | - | CODE-BACKED | Setting type name/label. Used as a key when looking up provider-specific configuration values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer/Config EV settings tables | SettingId | Lookup | Links provider configuration rows to their setting type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryEvProviderSettings | CLUSTERED PK | SettingId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all EV settings types
```sql
SELECT SettingId, Value
FROM Dictionary.EvProviderSettings WITH (NOLOCK)
ORDER BY SettingId
```

### 8.2 Get provider configuration
```sql
SELECT ep.Name AS Provider, eps.Value AS SettingType, pc.SettingValue
FROM Customer.EvProviderConfig pc WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON pc.EvProviderId = ep.EvProviderId
JOIN Dictionary.EvProviderSettings eps WITH (NOLOCK) ON pc.SettingId = eps.SettingId
WHERE ep.Name = 'GBG'
```

### 8.3 Check which providers have all settings configured
```sql
SELECT ep.Name, COUNT(DISTINCT pc.SettingId) AS ConfiguredSettings
FROM Dictionary.EvProvider ep WITH (NOLOCK)
LEFT JOIN Customer.EvProviderConfig pc WITH (NOLOCK) ON ep.EvProviderId = pc.EvProviderId
GROUP BY ep.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EvProviderSettings | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.EvProviderSettings.sql*
