# Dictionary.CreationSource

> Lookup table identifying the system or method used to create an affiliate account - locally created, synced from Azure AD, or created for testing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CreationSourceID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CreationSource tracks the origin of affiliate accounts. Understanding whether an affiliate was manually created in the local admin system, automatically synced from Azure Active Directory, or created for testing purposes is essential for compliance, reporting, and data quality management.

Without this classification, the system could not distinguish real production affiliates from test data, nor track the provisioning method. This matters for reconciliation between the affiliate platform and Azure AD, and for filtering out test accounts from commission calculations and reporting.

This is static reference data read by affiliate management procedures. The dbo.tblaff_Affiliates table stores CreationSourceID for each affiliate record, populated at account creation time and never changed afterward.

---

## 2. Business Logic

### 2.1 Affiliate Provisioning Channels

**What**: Three distinct channels through which affiliate accounts enter the system.

**Columns/Parameters Involved**: `CreationSourceID`, `Name`

**Rules**:
- ID=1 (Local) indicates manual creation via the admin portal - an administrator explicitly created the affiliate
- ID=2 (Azure) indicates automatic provisioning from Azure Active Directory - the affiliate was synced from the corporate identity system
- ID=3 (Test) marks the account as a test/QA affiliate - these should be excluded from production reporting and commission calculations

---

## 3. Data Overview

| CreationSourceID | Name | Meaning |
|---|---|---|
| 1 | Local | Affiliate created manually in the local admin system by an administrator. This is the traditional onboarding method requiring manual data entry and verification |
| 2 | Azure | Affiliate synced automatically from Azure Active Directory. Part of the corporate identity integration - account details are maintained in Azure AD and provisioned to the affiliate system |
| 3 | Test | Test affiliate account created for QA/development purposes. Must be excluded from production reporting, commission calculations, and compliance audits |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreationSourceID | int | NO | - | VERIFIED | Primary key identifying the affiliate creation channel. Values: 1=Local, 2=Azure, 3=Test. See [Creation Source](../../_glossary.md#creation-source) for full business definitions. Set once at affiliate creation, never modified. |
| 2 | Name | nvarchar(50) | NO | - | VERIFIED | Human-readable label for the creation source. Used in admin UIs and reporting to indicate how the affiliate was provisioned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | CreationSourceID | Implicit FK | Core affiliate table records how each affiliate was created |
| History.tblaff_Affiliates | CreationSourceID | Implicit FK | Historical snapshot preserves the creation source for audit trail |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | Stores CreationSourceID for each affiliate |
| History.tblaff_Affiliates | Table | Historical records preserve CreationSourceID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCreationSource | CLUSTERED PK | CreationSourceID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all creation sources
```sql
SELECT CreationSourceID, Name
FROM Dictionary.CreationSource WITH (NOLOCK)
ORDER BY CreationSourceID
```

### 8.2 Count affiliates by creation source
```sql
SELECT cs.CreationSourceID, cs.Name, COUNT(*) AS AffiliateCount
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN Dictionary.CreationSource cs WITH (NOLOCK) ON a.CreationSourceID = cs.CreationSourceID
GROUP BY cs.CreationSourceID, cs.Name
ORDER BY AffiliateCount DESC
```

### 8.3 Find non-test affiliates (production only)
```sql
SELECT a.*
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
WHERE a.CreationSourceID != 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CreationSource | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.CreationSource.sql*
