# fiktivo.spafw_DeleteOldCommissionsPriorToDate

> Purges old commission records and their associated payment history prior to a specified cutoff date, then cleans up orphaned sales and leads records.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CutOffDate (date-based commission purge) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_DeleteOldCommissionsPriorToDate is a data retention procedure that removes aged commission and payment records from the affiliate system. Over time, the commission tables accumulate substantial volumes of historical data that are no longer needed for active reporting or payment processing. This procedure systematically removes that data to manage database size and maintain query performance.

The procedure operates in a cascading fashion: for each payment history record prior to the cutoff date, it first deletes the child commission records (sales commissions and leads commissions tied to that payment), then deletes the payment history record itself. After all dated payments are processed, it performs a second cleanup pass to remove orphaned sales and leads records -- those that no longer have any associated commission records.

Note that click-related cleanup was previously included but has been removed (per Noga Rozen, 14/08/2022). The procedure now handles only sales and leads commission data. This is a destructive operation that permanently removes data and should be run only after confirming that the affected records have been archived or are no longer needed for compliance purposes.

---

## 2. Business Logic

### 2.1 Payment-Based Commission Deletion

**What**: Iterates payment history records prior to the cutoff date and deletes their associated commission records.

**Columns/Parameters Involved**: `@CutOffDate`

**Rules**:
- Cursor over dbo.tblaff_PaymentHistory WHERE payment date < @CutOffDate
- For each PaymentID, deletes matching records from dbo.tblaff_Sales_Commissions
- For each PaymentID, deletes matching records from dbo.tblaff_Leads_Commissions
- After commission deletion, deletes the dbo.tblaff_PaymentHistory record itself

### 2.2 Orphan Cleanup

**What**: Removes sales and leads records that no longer have any associated commission records.

**Columns/Parameters Involved**: N/A (post-deletion cleanup)

**Rules**:
- Deletes from dbo.tblaff_Sales where no matching record exists in dbo.tblaff_Sales_Commissions
- Deletes from dbo.tblaff_Leads where no matching record exists in dbo.tblaff_Leads_Commissions
- This ensures referential integrity is maintained even without formal foreign key constraints

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CutOffDate | VARCHAR(12) (IN) | NO | - | CODE-BACKED | The date threshold for deletion. All payment history records (and their associated commissions) prior to this date will be permanently deleted. Passed as a string and implicitly converted to date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CutOffDate | dbo.tblaff_PaymentHistory | SELECT / DELETE | Cursor source for payments prior to cutoff; deleted after child commissions are removed |
| PaymentID | dbo.tblaff_Sales_Commissions | DELETE | Deletes sales commission records for each payment being purged |
| PaymentID | dbo.tblaff_Leads_Commissions | DELETE | Deletes leads commission records for each payment being purged |
| - | dbo.tblaff_Sales | DELETE | Removes orphaned sales records with no remaining commission entries |
| - | dbo.tblaff_Leads | DELETE | Removes orphaned leads records with no remaining commission entries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_DeleteOldCommissionsPriorToDate (procedure)
├── dbo.tblaff_PaymentHistory (table, cross-schema)
├── dbo.tblaff_Sales_Commissions (table, cross-schema)
├── dbo.tblaff_Leads_Commissions (table, cross-schema)
├── dbo.tblaff_Sales (table, cross-schema)
└── dbo.tblaff_Leads (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table (cross-schema) | Cursor source and DELETE target for aged payment records |
| dbo.tblaff_Sales_Commissions | Table (cross-schema) | DELETE target for sales commissions tied to purged payments |
| dbo.tblaff_Leads_Commissions | Table (cross-schema) | DELETE target for leads commissions tied to purged payments |
| dbo.tblaff_Sales | Table (cross-schema) | DELETE target for orphaned sales records after commission purge |
| dbo.tblaff_Leads | Table (cross-schema) | DELETE target for orphaned leads records after commission purge |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Purge commissions older than one year
```sql
EXEC fiktivo.spafw_DeleteOldCommissionsPriorToDate @CutOffDate = '2025-04-12'
```

### 8.2 Preview payment history records that would be affected
```sql
SELECT PaymentID, AffiliateID, PaymentDate, Amount
FROM dbo.tblaff_PaymentHistory WITH (NOLOCK)
WHERE PaymentDate < '2025-04-12'
ORDER BY PaymentDate
```

### 8.3 Check for orphaned sales records (no commission entries)
```sql
SELECT s.*
FROM dbo.tblaff_Sales s WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Sales_Commissions sc WITH (NOLOCK) ON s.SaleID = sc.SaleID
WHERE sc.SaleID IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 6.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_DeleteOldCommissionsPriorToDate | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_DeleteOldCommissionsPriorToDate.sql*
