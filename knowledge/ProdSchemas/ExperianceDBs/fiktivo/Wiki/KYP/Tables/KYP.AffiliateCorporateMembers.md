# KYP.AffiliateCorporateMembers

> Child table storing the corporate board members, directors, and key principals associated with an affiliate entity as part of KYP (Know Your Partner) compliance verification.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID + Index (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

KYP.AffiliateCorporateMembers stores the list of corporate officers, board members, and key principals for each affiliate entity undergoing KYP verification. Regulatory compliance (KYP/KYC) requires identifying all individuals who control or significantly influence a corporate affiliate - this is essential for anti-money laundering (AML) and beneficial ownership checks.

Without this table, the platform would not be able to record the identities and roles of corporate principals, which is a regulatory requirement for partner onboarding. Each affiliate can have multiple corporate members (e.g., CEO, CFO, Board Chair), each identified by their full name and position within the entity.

Rows are managed exclusively by `KYP.UpdateAffiliateData` using a MERGE statement that synchronizes the table with the @CorporateMembers table-valued parameter (KypCorporateMembersTableType UDT). This supports insert, update, and delete in a single atomic operation. `KYP.GetAffiliateData` reads all members for an affiliate ordered by Index. The table uses temporal versioning (History.KYPAffiliateCorporateMembers) and dynamic data masking on the FullName field.

---

## 2. Business Logic

### 2.1 Index-Based Member Ordering

**What**: Corporate members are ordered by a zero-based Index that represents their position in the submitted list.

**Columns/Parameters Involved**: `AffiliateID`, `Index`

**Rules**:
- Index is part of the composite PK (AffiliateID + Index)
- Index starts at 0 for the first/primary corporate member
- The MERGE in UpdateAffiliateData matches on (AffiliateID, Index) - if a member's index changes, it's treated as a delete + insert (not an update)
- GetAffiliateData orders results by Index to maintain consistent display order

---

## 3. Data Overview

| AffiliateID | Index | FullName | Position | Meaning |
|---|---|---|---|---|
| 60062 | 0 | Eitan Galed | Product Manager | Primary corporate member for affiliate 60062 (KYPStatusID=5, Submitted). Index 0 = first listed principal. |
| 60056 | 0 | ghjh | hgj | Test data entry for affiliate 60056 (KYPStatusID=3, In Progress). Gibberish values suggest this is a test/development record. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | FK to KYP.Affiliate. Identifies which affiliate entity these corporate members belong to. Part of composite PK. |
| 2 | Index | int | NO | - | CODE-BACKED | Zero-based ordinal position of this corporate member in the list. Part of composite PK. Used for ordering in GetAffiliateData (ORDER BY Index). |
| 3 | FullName | nvarchar(100) | YES | - | CODE-BACKED | Full legal name of the corporate member. MASKED with default(). PII field requiring data protection. |
| 4 | Position | nvarchar(50) | NO | - | CODE-BACKED | Role/title of the corporate member within the entity (e.g., 'Product Manager', 'Director', 'CEO'). MASKED with default(). |
| 5 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName. Inherited pattern from KYP.Affiliate. |
| 6 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row start. GENERATED ALWAYS AS ROW START. |
| 7 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row end. GENERATED ALWAYS AS ROW END. Current rows have '9999-12-31'. History in History.KYPAffiliateCorporateMembers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | KYP.Affiliate | FK | Parent affiliate's KYP record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.GetAffiliateData | AffiliateID | SELECT (READER) | Reads all members for an affiliate |
| KYP.UpdateAffiliateData | AffiliateID, Index | MERGE (WRITER) | Synchronizes members via MERGE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.AffiliateCorporateMembers (table)
└── KYP.Affiliate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | FK on AffiliateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.GetAffiliateData | SP | SELECT reader |
| KYP.UpdateAffiliateData | SP | MERGE writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYP_AffiliateCorporateMembers | CLUSTERED PK | AffiliateID ASC, Index ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_KYP_AffiliateCorporateMembers | PRIMARY KEY | Composite (AffiliateID, Index) |
| FK_KYP_AffiliateCorporateMembers_AffiliateID | FOREIGN KEY | AffiliateID -> KYP.Affiliate(AffiliateID) |

Temporal: SYSTEM_VERSIONING ON with History.KYPAffiliateCorporateMembers.

---

## 8. Sample Queries

### 8.1 Get all corporate members for an affiliate
```sql
SELECT [Index], FullName, Position
FROM KYP.AffiliateCorporateMembers WITH (NOLOCK)
WHERE AffiliateID = 60062
ORDER BY [Index]
```

### 8.2 Affiliates with multiple corporate members
```sql
SELECT AffiliateID, COUNT(*) AS MemberCount
FROM KYP.AffiliateCorporateMembers WITH (NOLOCK)
GROUP BY AffiliateID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
```

### 8.3 View member change history via temporal table
```sql
SELECT AffiliateID, [Index], FullName, Position, ValidFrom, ValidTo
FROM KYP.AffiliateCorporateMembers
FOR SYSTEM_TIME ALL
WHERE AffiliateID = 60062
ORDER BY [Index], ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.AffiliateCorporateMembers | Type: Table | Source: fiktivo/KYP/Tables/KYP.AffiliateCorporateMembers.sql*
