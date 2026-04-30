# Dictionary.RafModelType_NogaJunk210725

> Lookup table defining 2 Refer-A-Friend (RAF) compensation model types — Club (tier-based) and PI (Popular Investor-based) — mapping to their respective source dictionaries. Legacy/junk table from July 2021.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RafModelTypeID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RafModelType_NogaJunk210725 defines the compensation models used in eToro's Refer-A-Friend (RAF) program. The RAF program rewards existing customers who refer new users to the platform. The compensation model determines how referral rewards are calculated — either based on the referrer's eToro Club tier (Club model) or their Popular Investor (PI) status.

The "_NogaJunk210725" suffix indicates this is a legacy table preserved from a July 2021 cleanup/migration by developer "Noga." The SourceDictionary column self-documents which Dictionary table provides the level/tier definitions for each model type.

Referenced by Customer.RafConfigurationModels_NogaJunk210725 and Customer.GetRafConfiguration_NogaJunk210725.

---

## 2. Business Logic

### 2.1 RAF Compensation Models

**What**: Each model type defines how referral rewards are structured.

**Columns/Parameters Involved**: `RafModelTypeID`, `Name`, `SourceDictionary`

**Rules**:
- **1 = Club** — Referral rewards are tiered by eToro Club level (Bronze, Silver, Gold, Platinum, etc.). Source: Dictionary.RafPlayerLevel.
- **2 = PI** — Referral rewards are tiered by Popular Investor status (Cadet, Champion, Elite, etc.). Source: Dictionary.GuruStatus.
- The SourceDictionary column points to the table that defines the tiers for each model.

**Diagram**:
```
RAF Model Types
├── 1 = Club → Dictionary.RafPlayerLevel (Bronze/Silver/Gold/Platinum/Diamond)
└── 2 = PI   → Dictionary.GuruStatus (Cadet/Champion/Elite/Elite Pro)
```

---

## 3. Data Overview

| RafModelTypeID | Name | SourceDictionary | Meaning |
|---|---|---|---|
| 1 | Club | Dictionary.RafPlayerLevel | RAF rewards based on referrer's eToro Club tier. Higher club tier = higher referral bonus. |
| 2 | PI | Dictionary.GuruStatus | RAF rewards based on referrer's Popular Investor status. PI members get enhanced referral bonuses. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RafModelTypeID | int | NO | - | VERIFIED | Primary key. 1=Club, 2=PI. Referenced by Customer.RafConfigurationModels_NogaJunk210725. |
| 2 | Name | nvarchar(50) | NO | - | VERIFIED | Model type label. "Club" for tier-based or "PI" for Popular Investor-based. |
| 3 | SourceDictionary | nvarchar(50) | NO | - | VERIFIED | Self-documenting reference to the Dictionary table providing tier definitions. "Dictionary.RafPlayerLevel" for Club, "Dictionary.GuruStatus" for PI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK references. SourceDictionary is a text reference (not enforced FK).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafConfigurationModels_NogaJunk210725 | RafModelTypeID | Implicit | RAF configuration per model type |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no enforced dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafConfigurationModels_NogaJunk210725 | Table | Stores RAF config per model type |
| Customer.GetRafConfiguration_NogaJunk210725 | Stored Procedure | Reader — retrieves RAF configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafModelType | CLUSTERED PK | RafModelTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RafModelType | PRIMARY KEY | Unique model type identifier |

---

## 8. Sample Queries

### 8.1 List all RAF model types
```sql
SELECT  RafModelTypeID,
        Name,
        SourceDictionary
FROM    [Dictionary].[RafModelType_NogaJunk210725] WITH (NOLOCK)
ORDER BY RafModelTypeID;
```

### 8.2 Find Club model configurations
```sql
SELECT  rc.*
FROM    [Customer].[RafConfigurationModels_NogaJunk210725] rc WITH (NOLOCK)
WHERE   rc.RafModelTypeID = 1;
```

### 8.3 Join model type with source dictionary description
```sql
SELECT  rmt.Name AS ModelType,
        rmt.SourceDictionary
FROM    [Dictionary].[RafModelType_NogaJunk210725] rmt WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RafModelType_NogaJunk210725 | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RafModelType_NogaJunk210725.sql*
