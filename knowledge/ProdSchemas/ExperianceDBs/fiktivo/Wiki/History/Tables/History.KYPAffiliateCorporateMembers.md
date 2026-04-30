# History.KYPAffiliateCorporateMembers

> SQL Server temporal history table storing all historical versions of corporate member records for KYP-verified corporate affiliates.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID + Index (composite - identifies a specific member within a corporate affiliate across versions) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.KYPAffiliateCorporateMembers is the system-versioned temporal history table for KYP.AffiliateCorporateMembers. It captures every historical version of the corporate members (directors, officers, shareholders) associated with a KYP-verified corporate affiliate. Each row represents one member of the corporate affiliate entity at a specific point in time, identified by their ordinal position (Index) within the affiliate's member list.

This table is essential for regulatory compliance and audit trails. When a corporate affiliate updates their member list - adding new directors, removing officers, or correcting shareholder information - every prior version is preserved here. This enables compliance teams to reconstruct the full history of who was associated with a corporate affiliate at any point in time, which is critical for anti-money laundering (AML) and Know Your Partner (KYP) investigations.

Data flows in automatically via SQL Server's temporal mechanism whenever rows in the base table KYP.AffiliateCorporateMembers are updated or deleted. With 905 historical rows, member changes occur moderately often as corporate structures evolve. Sensitive fields like FullName and Position are protected with dynamic data masking for PII compliance.

---

## 2. Business Logic

### 2.1 Corporate Member Versioning

**What**: Tracks changes to the list of corporate members (directors, officers, shareholders) associated with a KYP-verified corporate affiliate over time.

**Columns/Parameters Involved**: `AffiliateID`, `Index`, `FullName`, `Position`, `ValidFrom`, `ValidTo`

**Rules**:
- AffiliateID + Index together identify a specific member slot within a corporate affiliate
- The Index column is the ordinal position (1-based) of the member in the affiliate's member list
- FullName and Position are MASKED to protect personally identifiable information
- Each row represents a superseded version of a corporate member record
- ValidFrom/ValidTo define the exact time range when this version was the active record

---

## 3. Data Overview

The table contains 905 historical rows representing superseded versions of corporate member records. These accumulate as affiliates update their corporate structure - adding, removing, or modifying member details during the KYP verification and ongoing compliance process.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | The corporate affiliate this member belongs to. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | Index | int | NO | - | CODE-BACKED | Ordinal position of the member within the affiliate's corporate member list (1-based). |
| 3 | FullName | nvarchar(100) | YES | - | CODE-BACKED | Full name of the corporate member (MASKED). Director, officer, or shareholder name. |
| 4 | Position | nvarchar(50) | NO | - | CODE-BACKED | Role or title of the member within the corporate entity, e.g., Director, Officer, Shareholder (MASKED). |
| 5 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 6 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 7 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | KYP.AffiliateCorporateMembers | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The corporate affiliate this member belongs to |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on KYP.AffiliateCorporateMembers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.KYPAffiliateCorporateMembers (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateCorporateMembers | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_KYPAffiliateCorporateMembers | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View full corporate member history for an affiliate
```sql
SELECT AffiliateID, [Index], FullName, Position, ValidFrom, ValidTo
FROM KYP.AffiliateCorporateMembers FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY [Index], ValidFrom
```

### 8.2 Check corporate members at a specific date
```sql
SELECT AffiliateID, [Index], FullName, Position
FROM KYP.AffiliateCorporateMembers FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY [Index]
```

### 8.3 Find recently changed corporate member records
```sql
SELECT AffiliateID, [Index], FullName, Position, ValidFrom, ValidTo
FROM History.KYPAffiliateCorporateMembers WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.KYPAffiliateCorporateMembers | Type: Table | Source: fiktivo/History/Tables/History.KYPAffiliateCorporateMembers.sql*
