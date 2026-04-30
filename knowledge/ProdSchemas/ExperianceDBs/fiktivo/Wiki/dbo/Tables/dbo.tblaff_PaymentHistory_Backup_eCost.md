# dbo.tblaff_PaymentHistory_Backup_eCost

> Developer backup/snapshot of tblaff_PaymentHistory, created by Noga before the eCost migration. No indexes, no FKs, no triggers - exists purely as a point-in-time data safety copy.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (backup/junk) |
| **Key Identifier** | None (heap) |
| **Partition** | No |
| **Indexes** | 0 (heap) |

---

## 1. Business Meaning

dbo.tblaff_PaymentHistory_Backup_eCost is a developer backup copy of dbo.tblaff_PaymentHistory, created as a data safety snapshot before the eCost migration. The "_Backup_eCost" suffix indicates this was taken as a precautionary copy prior to changes related to the eCost commission type integration or migration. These tables should be reviewed for potential cleanup.

See [dbo.tblaff_PaymentHistory](dbo.tblaff_PaymentHistory.md) for full documentation of the source table's structure, business meaning, and element descriptions. This backup has an identical column structure but no indexes, constraints, triggers, or foreign keys. The source table has FKs, triggers, and an approval workflow - none of those features are present in this backup copy.

---

## 2. Business Logic

No business logic. This is a static backup copy.

---

## 3. Data Overview

Developer backup - data represents a point-in-time snapshot taken before the eCost migration.

---

## 4. Elements

See [dbo.tblaff_PaymentHistory](dbo.tblaff_PaymentHistory.md) for complete element descriptions. This table has identical columns (100 columns) covering: PaymentID, AffiliateID, payment period fields, per-tier commission breakdowns across all 8 commission types (CPA, Sales, Registrations, Leads, Clicks, CopyTraders, FirstPositions, eCost), multi-level approval workflow columns (ManagerApproved, VPMarketingApproved, FinanceApproved, FinanceManagerApproved, Approved), PaymentRowStatusID, currency fields, RequestedBy, ApprovedBy, and related audit columns.

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (backup copy - no FKs).

### 5.2 Referenced By (other objects point to this)

No dependents found. This is an orphaned backup table.

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

No indexes (heap table).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if backup has data
```sql
SELECT COUNT(*) AS RowCount FROM dbo.tblaff_PaymentHistory_Backup_eCost WITH (NOLOCK)
```

### 8.2 Compare with current source table
```sql
SELECT 'Current' AS Source, COUNT(*) AS Rows FROM dbo.tblaff_PaymentHistory WITH (NOLOCK)
UNION ALL
SELECT 'Backup', COUNT(*) FROM dbo.tblaff_PaymentHistory_Backup_eCost WITH (NOLOCK)
```

### 8.3 Sample backup data
```sql
SELECT TOP 5 * FROM dbo.tblaff_PaymentHistory_Backup_eCost WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_PaymentHistory_Backup_eCost | Type: Table (backup) | Source: fiktivo/dbo/Tables/dbo.tblaff_PaymentHistory_Backup_eCost.sql*
