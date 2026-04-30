# dbo.Singapore_NegativeConsent_Dor

> Migration table tracking Singapore customer GCIDs for negative consent processing during a regulatory migration event.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK defined) |
| **Partition** | No |
| **Indexes** | 0 active |

---

## 1. Business Meaning

This table records Global Customer IDs (GCIDs) of Singapore-based eToro customers who were subject to a negative consent process during a regulatory migration. Negative consent is a regulatory mechanism where customers are deemed to have consented unless they explicitly opt out within a specified period. The 6,492 rows represent the full population of Singapore customers affected by this migration.

The `_Dor` suffix indicates this was created by a specific team member (consistent with the naming pattern seen in other migration tables like MigrationGermany_Dor and Switzerland_NegativeConsent_Dor). The table served as a lookup list for identifying which customers needed negative consent notifications or processing.

No stored procedures, views, or functions reference this table. Migration operations were likely performed via ad-hoc scripts. The table remains as a historical record of the Singapore negative consent migration scope.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple GCID list with no status tracking, timestamps, or workflow columns. See individual element descriptions in Section 4.

---

## 3. Data Overview

| GCID | Meaning |
|------|---------|
| (sample int) | Singapore customer subject to negative consent -- included in regulatory migration batch |
| (sample int) | Another Singapore customer in the negative consent population |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. The platform-wide unique identifier for a Singapore customer included in the negative consent migration. No index or PK constraint, so duplicates are technically possible. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Count Singapore negative consent customers
```sql
SELECT COUNT(*) AS CustomerCount
FROM dbo.Singapore_NegativeConsent_Dor WITH (NOLOCK)
```

### 8.2 Check for duplicate GCIDs
```sql
SELECT GCID, COUNT(*) AS Cnt
FROM dbo.Singapore_NegativeConsent_Dor WITH (NOLOCK)
GROUP BY GCID
HAVING COUNT(*) > 1
```

### 8.3 Look up a specific customer
```sql
SELECT GCID
FROM dbo.Singapore_NegativeConsent_Dor WITH (NOLOCK)
WHERE GCID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Singapore_NegativeConsent_Dor | Type: Table | Source: WalletDB/dbo/Tables/dbo.Singapore_NegativeConsent_Dor.sql*
