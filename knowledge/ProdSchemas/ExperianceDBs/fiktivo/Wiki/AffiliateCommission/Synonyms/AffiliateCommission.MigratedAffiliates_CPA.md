# AffiliateCommission.MigratedAffiliates_CPA

> Synonym pointing to the MigratedAffiliates_CPA table in the production eToro database, enabling the fiktivo instance to check CPA migration status for affiliates via cross-server linked query.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MigratedAffiliates_CPA is a synonym that points to `[AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_CPA]` - the CPA migration tracking table on the production eToro database server. It enables the fiktivo environment to check whether a given affiliate has been migrated to the new commission system for CPA (Cost Per Acquisition) commissions without needing direct cross-server queries in every consuming object.

This synonym is consumed by CheckIfAffiliateWasMigratedForCPA function, which returns 1 if an affiliate exists in the target table (migrated) or 0 if not. The pattern is identical to MigratedAffiliates_Sales (local table) and MigratedAffiliates_Registration (synonym).

---

## 2. Business Logic

N/A for Synonym. Business logic is in the target table and consuming function.

---

## 3. Data Overview

N/A for Synonym. Data resides on the target server `[AO-REAL-DB-ROR].[etoro]`.

---

## 4. Elements

N/A for Synonym.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_CPA] | Synonym Target | External production table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CheckIfAffiliateWasMigratedForCPA | SELECT | Reader | Migration check function |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object depends on an external server.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_CPA] | External Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CheckIfAffiliateWasMigratedForCPA | Function | Migration gate check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

None. Synonym definition: `CREATE SYNONYM [AffiliateCommission].[MigratedAffiliates_CPA] FOR [AO-REAL-DB-ROR].[etoro].[AffiliateCommission].[MigratedAffiliates_CPA]`

---

## 8. Sample Queries

### 8.1 Check if an affiliate is migrated for CPA
```sql
SELECT AffiliateID FROM AffiliateCommission.MigratedAffiliates_CPA WITH (NOLOCK) WHERE AffiliateID = 12345;
```

### 8.2 Use via the function
```sql
SELECT AffiliateCommission.CheckIfAffiliateWasMigratedForCPA(12345) AS IsMigrated;
```

### 8.3 Count migrated affiliates
```sql
SELECT COUNT(*) AS MigratedCount FROM AffiliateCommission.MigratedAffiliates_CPA WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/2*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.MigratedAffiliates_CPA | Type: Synonym | Source: fiktivo/AffiliateCommission/Synonyms/AffiliateCommission.MigratedAffiliates_CPA.sql*
