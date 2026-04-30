# Dictionary.KycRegulationConfigType

> Lookup table defining configuration types for KYC regulation-specific settings such as titles, phone prefixes, and allowed characters.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.KycRegulationConfigType defines the types of locale and format configurations that vary by regulatory jurisdiction during KYC data collection. Different regulations have different requirements for user titles (Mr/Mrs/Dr), phone number prefixes, and which special characters are permitted in name fields.

This table enables per-regulation customization of the KYC data entry forms without code changes. By defining config types, the platform can store regulation-specific values (e.g., "Title options for CySEC: Mr, Mrs, Ms, Dr" vs "Title options for ASIC: Mr, Mrs, Ms, Dr, Prof") in a normalized configuration structure.

Config values are read during registration form rendering to populate dropdowns, validate input formats, and apply character restrictions based on the user's assigned regulation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| TypeID | Name | Meaning |
|---|---|---|
| 1 | Title | User title/salutation options (Mr, Mrs, Ms, Dr, etc.) that vary by regulation |
| 2 | Prefix | Phone number prefix rules and validation patterns per regulatory jurisdiction |
| 3 | Special Char | Allowed special characters in name fields per regulation - e.g., hyphens, apostrophes, accents |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TypeID | int | NO | - | CODE-BACKED | Primary key. Config type: 1=Title, 2=Prefix, 3=Special Char. See [KYC Regulation Config Type](_glossary.md#kyc-regulation-config-type). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Configuration type label used in admin tools and configuration management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC regulation config tables | TypeID | Lookup | Links configuration values to their config type |

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
| PK_Dictionary_KycRegulationConfigType | CLUSTERED PK | TypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all config types
```sql
SELECT TypeID, Name
FROM Dictionary.KycRegulationConfigType WITH (NOLOCK)
ORDER BY TypeID
```

### 8.2 Get configuration values by type and regulation
```sql
SELECT r.Name AS Regulation, ct.Name AS ConfigType, c.ConfigValue
FROM Customer.KycRegulationConfig c WITH (NOLOCK)
JOIN Dictionary.KycRegulationConfigType ct WITH (NOLOCK) ON c.TypeID = ct.TypeID
JOIN Dictionary.Regulation r WITH (NOLOCK) ON c.RegulationID = r.ID
WHERE ct.Name = 'Title'
ORDER BY r.Name
```

### 8.3 Count configs per type
```sql
SELECT ct.Name, COUNT(*) AS ConfigCount
FROM Customer.KycRegulationConfig c WITH (NOLOCK)
JOIN Dictionary.KycRegulationConfigType ct WITH (NOLOCK) ON c.TypeID = ct.TypeID
GROUP BY ct.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.KycRegulationConfigType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.KycRegulationConfigType.sql*
