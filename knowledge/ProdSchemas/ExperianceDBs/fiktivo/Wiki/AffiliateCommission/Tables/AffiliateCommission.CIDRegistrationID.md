# AffiliateCommission.CIDRegistrationID

> Mapping table that links Customer IDs (CID) to their Registration IDs, enabling fast lookup between the customer identity and their registration record in the affiliate commission system.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

CIDRegistrationID is a simple mapping table that maintains a 1:1 relationship between a Customer ID (CID) and their Registration ID in the affiliate commission system. Since Registration uses an auto-incrementing IDENTITY for RegistrationID, and many downstream processes know only the CID, this table provides a fast lookup path from CID to RegistrationID without scanning the larger Registration table.

This table exists for performance optimization. The Registration table has 14.5 million rows and is indexed by RegistrationID (PK), not by CID as the primary access path. While Registration does have an index on CID, this dedicated mapping table provides a more compact lookup structure with 3.3 million rows (one per customer with a registration). It is populated during the registration insertion process.

---

## 2. Business Logic

No complex business logic. This is a pure mapping/lookup table.

---

## 3. Data Overview

| CID | RegistrationID | Meaning |
|---|---|---|
| 13478166 | 6556993 | Customer 13478166 has Registration 6556993. Sequential IDs suggest batch processing. |
| 13478165 | 6556992 | One-to-one sequential mapping. |
| 13478164 | 6556991 | Continuous sequence - registrations processed in CID order. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | CODE-BACKED | Customer ID. PK. One row per registered customer. Provides direct lookup from customer identity to registration. |
| 2 | RegistrationID | int | NO | - | CODE-BACKED | Registration ID mapping to AffiliateCommission.Registration.RegistrationID. Uses int (vs bigint in Registration table) - may limit mapping for very high RegistrationIDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegistrationID | AffiliateCommission.Registration | Implicit FK | Maps to registration record |
| CID | External customer system | Implicit | Customer identity |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CIDRegistrationID (table)
└── AffiliateCommission.Registration (table) [implicit, via RegistrationID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | RegistrationID references Registration records |

### 6.2 Objects That Depend On This

No dependents found in stored procedures within this schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateCommissionCIDRegistrationID | CLUSTERED PK | CID ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateCommissionCIDRegistrationID | PRIMARY KEY | Unique CID - one registration per customer |

---

## 8. Sample Queries

### 8.1 Look up registration by CID
```sql
SELECT RegistrationID FROM AffiliateCommission.CIDRegistrationID WITH (NOLOCK) WHERE CID = 13478166;
```

### 8.2 Join with Registration for full details
```sql
SELECT m.CID, r.RegistrationID, r.RegistrationDate, r.CountryID, r.Valid, r.IsProcessed
FROM AffiliateCommission.CIDRegistrationID m WITH (NOLOCK)
JOIN AffiliateCommission.Registration r WITH (NOLOCK) ON m.RegistrationID = r.RegistrationID
WHERE m.CID = 13478166;
```

### 8.3 Find customers without mapping
```sql
SELECT TOP 100 r.RegistrationID, r.CID
FROM AffiliateCommission.Registration r WITH (NOLOCK)
LEFT JOIN AffiliateCommission.CIDRegistrationID m WITH (NOLOCK) ON r.CID = m.CID
WHERE m.CID IS NULL
ORDER BY r.RegistrationID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CIDRegistrationID | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CIDRegistrationID.sql*
