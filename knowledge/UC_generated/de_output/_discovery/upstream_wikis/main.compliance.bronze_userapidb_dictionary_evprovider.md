# Dictionary.EvProvider

> Lookup table defining third-party Electronic Verification identity verification providers integrated with the platform, classified by verification method.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EvProviderId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.EvProvider lists the 15 third-party identity verification service providers integrated into eToro's KYC workflow. Each provider specializes in either electronic data matching (comparing user data against authoritative databases) or document scanning (analyzing uploaded ID documents and selfies). The platform routes users to different providers based on their country, regulation, and verification needs.

Multiple providers are needed because no single provider has global coverage. GBG may cover UK verification best, while Trulioo covers North America, DataZoo covers Australia, and Au10tix handles document verification globally. The system uses fallback chains: if one provider fails, the next is tried.

---

## 2. Business Logic

### 2.1 Provider Classification

**What**: 15 providers split between electronic (11) and document (4) verification methods.

**Columns/Parameters Involved**: `EvProviderId`, `Name`, `ProviderTypeID`

**Rules**:
- Electronic (type 0): GDC, GBG, TruNarrative, Cognito, Melisa, Au10tix-Ev, Trulioo, DataZoo, DataZoo2, IDMerit, Prove
- Document (type 1): Au10tix-Documents, Au10tix_Selfie, Onfido, SumSub
- Au10tix has 3 entries: Documents (3), Ev (7), Selfie (10) - different services from same vendor

---

## 3. Data Overview

| EvProviderId | Name | ProviderTypeID | Meaning |
|---|---|---|---|
| 1 | GDC | 0 | GDC electronic verification - data matching against government databases |
| 2 | GBG | 0 | GBG Group - UK/EU focused electronic identity verification |
| 3 | Au10tix-Documents | 1 | Au10tix ID document scanning and OCR verification |
| 8 | Trulioo | 0 | Trulioo GlobalGateway - broad international electronic verification |
| 14 | SumSub | 1 | Sum&Substance - document and biometric verification |

*5 of 15 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EvProviderId | int | NO | - | CODE-BACKED | Primary key. Provider identifier (1-15). See [EV Provider](_glossary.md#ev-provider). |
| 2 | Name | varchar(30) | YES | - | CODE-BACKED | Provider display name used in admin tools and verification logs. |
| 3 | ProviderTypeID | int | YES | - | CODE-BACKED | FK to Dictionary.ProviderType. Classification: 0=ElectronicVerification, 1=DocumentsVerification. See [Provider Type](_glossary.md#provider-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderTypeID | Dictionary.ProviderType | Explicit FK | Classifies provider as electronic or document-based |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer EV result tables | EvProviderId | Lookup | Records which provider performed each verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.EvProvider (table)
  +-- Dictionary.ProviderType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ProviderType | Table | FK: ProviderTypeID |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryEvProvider | CLUSTERED PK | EvProviderId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_Dictionary_EvProvider_ProviderType | FOREIGN KEY | ProviderTypeID -> Dictionary.ProviderType(ProviderTypeID) |

---

## 8. Sample Queries

### 8.1 List providers with type
```sql
SELECT ep.EvProviderId, ep.Name, pt.Name AS ProviderType FROM Dictionary.EvProvider ep WITH (NOLOCK)
JOIN Dictionary.ProviderType pt WITH (NOLOCK) ON ep.ProviderTypeID = pt.ProviderTypeID ORDER BY ep.EvProviderId
```

### 8.2 Find document verification providers
```sql
SELECT EvProviderId, Name FROM Dictionary.EvProvider WITH (NOLOCK) WHERE ProviderTypeID = 1
```

### 8.3 Verification attempts by provider
```sql
SELECT ep.Name, COUNT(*) AS Attempts FROM Customer.EvResults er WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON er.EvProviderId = ep.EvProviderId
GROUP BY ep.Name ORDER BY Attempts DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.EvProvider | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.EvProvider.sql*
