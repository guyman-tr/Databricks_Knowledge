# AffiliateCommission.MigratedAffiliates_Registration

> Synonym pointing to the MigratedAffiliates_Registration table in the production eToro database, enabling the fiktivo instance to check registration commission migration status for affiliates.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MigratedAffiliates_Registration is a synonym pointing to `[AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_Registration]` - the registration commission migration tracking table on the production server. It enables fiktivo to check whether an affiliate uses the new or legacy system for registration commissions.

Consumed by CheckIfAffiliateWasMigratedForRegistration function. Same pattern as MigratedAffiliates_CPA (synonym to external) and MigratedAffiliates_Sales (local table).

---

## 2. Business Logic

N/A for Synonym.

---

## 3. Data Overview

N/A for Synonym.

---

## 4. Elements

N/A for Synonym.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_Registration] | Synonym Target | External production table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration | SELECT | Reader | Migration gate check |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object depends on an external server.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_Registration] | External Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration | Function | Migration gate check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

None. Synonym definition: `CREATE SYNONYM [AffiliateCommission].[MigratedAffiliates_Registration] FOR [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_Registration]`

---

## 8. Sample Queries

### 8.1 Check migration status via function
```sql
SELECT AffiliateCommission.CheckIfAffiliateWasMigratedForRegistration(12345) AS IsMigrated;
```

### 8.2 Direct query
```sql
SELECT AffiliateID FROM AffiliateCommission.MigratedAffiliates_Registration WITH (NOLOCK) WHERE AffiliateID = 12345;
```

### 8.3 Count migrated
```sql
SELECT COUNT(*) AS MigratedCount FROM AffiliateCommission.MigratedAffiliates_Registration WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.MigratedAffiliates_Registration | Type: Synonym | Source: fiktivo/AffiliateCommission/Synonyms/AffiliateCommission.MigratedAffiliates_Registration.sql*
