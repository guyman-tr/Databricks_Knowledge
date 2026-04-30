# AffiliateCommission.MigratedAffiliates_Sales

> Lookup table tracking which affiliates have been migrated to the new commission system for sales-based (closed position) commissions, with migration dates and notes.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

MigratedAffiliates_Sales tracks which affiliates have been migrated from the legacy commission system (tblaff_Sales, tblaff_Sales_Commissions) to the new AffiliateCommission schema for sales/closed-position commissions. Each row represents one affiliate that has been migrated, with the migration date and optional comments.

This table exists because the migration from the legacy system to the new commission system was done incrementally, affiliate by affiliate. The CheckIfAffiliateWasMigratedForSales function checks this table to determine whether a given affiliate's sales commissions should be processed by the new system or the legacy system. This enables a gradual rollout without a big-bang migration.

The table is currently empty in this environment (0 rows), suggesting either all affiliates are still on the legacy system or the migration check has been bypassed. Two companion tables exist as synonyms pointing to the production database: MigratedAffiliates_CPA and MigratedAffiliates_Registration.

---

## 2. Business Logic

### 2.1 Migration Gate Pattern

**What**: Acts as a feature flag per affiliate for the sales commission system migration.

**Columns/Parameters Involved**: `AffiliateID`, `MigrationDate`

**Rules**:
- If an affiliate's ID exists in this table, their sales commissions are processed by the new AffiliateCommission system
- If not present, the legacy tblaff_Sales system handles their commissions
- MigrationDate defaults to getdate() - records when the migration occurred
- Comments can document the reason or batch for the migration

---

## 3. Data Overview

Table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Unique identifier of the migrated affiliate. PK. Existence in this table means the affiliate uses the new commission system for sales. |
| 2 | MigrationDate | datetime | YES | getdate() | CODE-BACKED | When the affiliate was migrated. Auto-set to current time via default. NULL should not occur in practice (default always applies). |
| 3 | Comments | nvarchar(400) | YES | - | CODE-BACKED | Optional notes about the migration (reason, batch number, ticket reference, etc.). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | dbo.tblaff_Affiliates | Implicit | References the affiliate system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CheckIfAffiliateWasMigratedForSales | SELECT | Reader | Migration gate check function |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CheckIfAffiliateWasMigratedForSales | Function | Checks if affiliate is migrated |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MigratedAffiliates_Sales | CLUSTERED PK | AffiliateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MigratedAffiliates_Sales | PRIMARY KEY | Unique affiliate identifier |
| DF_MigratedAffiliates_MigrationDate_Sales | DEFAULT | getdate() - auto-stamps migration time |

---

## 8. Sample Queries

### 8.1 Check if a specific affiliate is migrated
```sql
SELECT AffiliateID, MigrationDate, Comments
FROM AffiliateCommission.MigratedAffiliates_Sales WITH (NOLOCK)
WHERE AffiliateID = 12345;
```

### 8.2 List all migrated affiliates
```sql
SELECT AffiliateID, MigrationDate, Comments
FROM AffiliateCommission.MigratedAffiliates_Sales WITH (NOLOCK)
ORDER BY MigrationDate DESC;
```

### 8.3 Check migration status across all three domains
```sql
SELECT 'Sales' AS Domain, COUNT(*) AS MigratedCount FROM AffiliateCommission.MigratedAffiliates_Sales WITH (NOLOCK)
-- CPA and Registration are synonyms to external DB, not queryable here
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.MigratedAffiliates_Sales | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.MigratedAffiliates_Sales.sql*
