# KYC.RegulationConfig

> Stores regulation-specific KYC configuration values (titles, phone prefixes, special characters) with unique type+value combinations.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + unique on TypeID,Value) |

---

## 1. Business Meaning

KYC.RegulationConfig stores the actual configuration values for KYC form customization per regulation. The TypeID links to Dictionary.KycRegulationConfigType (1=Title, 2=Prefix, 3=Special Char), and Value holds the specific value (e.g., "Mr", "Mrs" for titles, "+44" for prefixes). Contains 71 configuration entries. The unique index on (TypeID, Value) prevents duplicate entries.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Key-value configuration store.

---

## 3. Data Overview

71 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing config entry identifier. |
| 2 | Value | varchar(50) | NO | - | CODE-BACKED | The configuration value (e.g., "Mr", "Mrs", "+44", "-"). Unique per TypeID. |
| 3 | TypeID | int | NO | - | CODE-BACKED | FK to Dictionary.KycRegulationConfigType. Config type: 1=Title, 2=Prefix, 3=Special Char. See [KYC Regulation Config Type](_glossary.md#kyc-regulation-config-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TypeID | Dictionary.KycRegulationConfigType | Explicit FK | Configuration type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.MetadataLoader | ID | SP reads | Returns config data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.RegulationConfig (table)
  +-- Dictionary.KycRegulationConfigType (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.KycRegulationConfigType | Table | FK: TypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.MetadataLoader | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegulationConfig | CLUSTERED PK | ID | - | - | Active (PAGE compressed) |
| Idx_KYC_RegulationConfig_TypeID_Value | NC UNIQUE | TypeID, Value | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_KYC_RegulationConfig_TypeID | FOREIGN KEY | TypeID -> Dictionary.KycRegulationConfigType |

---

## 8. Sample Queries

### 8.1 All titles
```sql
SELECT ID, Value FROM KYC.RegulationConfig WITH (NOLOCK) WHERE TypeID = 1 ORDER BY Value
```

### 8.2 All config with type names
```sql
SELECT rc.ID, ct.Name AS ConfigType, rc.Value FROM KYC.RegulationConfig rc WITH (NOLOCK)
JOIN Dictionary.KycRegulationConfigType ct WITH (NOLOCK) ON rc.TypeID = ct.TypeID ORDER BY ct.Name, rc.Value
```

### 8.3 Count by type
```sql
SELECT ct.Name, COUNT(*) AS ValueCount FROM KYC.RegulationConfig rc WITH (NOLOCK)
JOIN Dictionary.KycRegulationConfigType ct WITH (NOLOCK) ON rc.TypeID = ct.TypeID GROUP BY ct.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.RegulationConfig | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.RegulationConfig.sql*
