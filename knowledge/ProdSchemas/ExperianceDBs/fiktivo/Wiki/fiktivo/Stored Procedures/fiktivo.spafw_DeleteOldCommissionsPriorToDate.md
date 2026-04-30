# fiktivo.spafw_DeleteOldCommissionsPriorToDate

> Cleanup procedure that permanently deletes paid commission records and their orphaned parent event records older than a specified cutoff date, running within a transaction for data integrity.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CutOffDate (date threshold for deletion) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs data cleanup by deleting old, already-paid commission records from the affiliate system. It targets commission records associated with payment batches that were completed before the specified cutoff date. This is a critical archival/purge mechanism that prevents the commission tables from growing unbounded over time.

The procedure exists to manage database size and performance. As the affiliate system processes thousands of commissions daily, the historical tables can grow very large. Once commissions have been paid and reconciled, the detailed records become less operationally relevant. Without this cleanup procedure, the commission tables would grow indefinitely, degrading query performance and increasing storage costs.

The procedure is typically run periodically (e.g., monthly) by a DBA or scheduled job. It uses a cursor over `dbo.tblaff_PaymentHistory` to find payments older than the cutoff date, then deletes the associated commission records from `tblaff_Sales_Commissions` and `tblaff_Leads_Commissions` by PaymentID. After removing commissions, it cleans up orphaned parent records in `tblaff_Sales` and `tblaff_Leads` that no longer have any commission records. The entire operation runs in a transaction. Note: Click-related removal was commented out by Noga Rozen on 14/08/2022.

---

## 2. Business Logic

### 2.1 Payment-Based Commission Deletion

**What**: Identifies paid commission records for deletion based on the payment history cutoff date.

**Columns/Parameters Involved**: `@CutOffDate`, PaymentID from tblaff_PaymentHistory

**Rules**:
- Cursor iterates over tblaff_PaymentHistory to find PaymentIDs with payment dates before @CutOffDate
- For each qualifying PaymentID, deletes all commission records from tblaff_Sales_Commissions WHERE PaymentID = @PaymentID
- For each qualifying PaymentID, deletes all commission records from tblaff_Leads_Commissions WHERE PaymentID = @PaymentID
- Only paid commissions (linked to a PaymentID) are deleted; unpaid commissions are never affected

**Diagram**:
```
spafw_DeleteOldCommissionsPriorToDate(@CutOffDate)
    |
    v
BEGIN TRANSACTION
    |
    v
CURSOR: tblaff_PaymentHistory WHERE PaymentDate < @CutOffDate
    |
    +--> For each PaymentID:
    |       |
    |       +--> DELETE FROM tblaff_Sales_Commissions WHERE PaymentID = @PaymentID
    |       |
    |       +--> DELETE FROM tblaff_Leads_Commissions WHERE PaymentID = @PaymentID
    |
    v
Orphan Cleanup:
    +--> DELETE FROM tblaff_Sales WHERE SalesID NOT IN (SELECT SalesID FROM tblaff_Sales_Commissions)
    +--> DELETE FROM tblaff_Leads WHERE LeadID NOT IN (SELECT LeadID FROM tblaff_Leads_Commissions)
    |
    v
COMMIT TRANSACTION
```

### 2.2 Orphaned Parent Record Cleanup

**What**: After removing commission records, removes parent event records (Sales, Leads) that no longer have any associated commissions.

**Columns/Parameters Involved**: tblaff_Sales.SalesID, tblaff_Leads.LeadID, tblaff_Sales_Commissions.SalesID, tblaff_Leads_Commissions.LeadID

**Rules**:
- A Sale record is orphaned when it has zero remaining commission records in tblaff_Sales_Commissions
- A Lead record is orphaned when it has zero remaining commission records in tblaff_Leads_Commissions
- Orphan cleanup runs AFTER all commission deletions, ensuring no premature removal
- The entire operation (commission deletes + orphan cleanup) is wrapped in a single transaction

### 2.3 Commented-Out Click Removal (Historical)

**What**: Click-related data removal was previously part of this procedure but was disabled.

**Columns/Parameters Involved**: Click tables (commented out)

**Rules**:
- Click removal logic was commented out by Noga Rozen on 14/08/2022
- The decision to preserve click data suggests clicks have longer analytical value than paid commissions
- This is a deliberate business decision to retain marketing attribution data

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CutOffDate (IN) | VARCHAR(12) | NO | - | CODE-BACKED | The date threshold for deletion. All paid commissions linked to payments completed before this date will be deleted. Format is a date string (e.g., '2025-01-01'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Cursor source | dbo.tblaff_PaymentHistory | Read | Reads payment records to find those older than the cutoff date |
| DELETE target | dbo.tblaff_Sales_Commissions | Delete | Removes paid sales commission records by PaymentID |
| DELETE target | dbo.tblaff_Leads_Commissions | Delete | Removes paid lead commission records by PaymentID |
| DELETE target | dbo.tblaff_Sales | Delete | Removes orphaned sale event records after commission cleanup |
| DELETE target | dbo.tblaff_Leads | Delete | Removes orphaned lead event records after commission cleanup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_DeleteOldCommissionsPriorToDate (procedure)
├── dbo.tblaff_PaymentHistory (table)
├── dbo.tblaff_Sales_Commissions (table)
├── dbo.tblaff_Leads_Commissions (table)
├── dbo.tblaff_Sales (table)
└── dbo.tblaff_Leads (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Cursor source for identifying old payments |
| dbo.tblaff_Sales_Commissions | Table | DELETE target for paid sales commissions |
| dbo.tblaff_Leads_Commissions | Table | DELETE target for paid lead commissions |
| dbo.tblaff_Sales | Table | DELETE target for orphaned sale records |
| dbo.tblaff_Leads | Table | DELETE target for orphaned lead records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Delete all paid commissions older than 2 years
```sql
EXEC fiktivo.spafw_DeleteOldCommissionsPriorToDate @CutOffDate = '2024-04-01'
```

### 8.2 Preview what would be deleted (dry run)
```sql
SELECT ph.PaymentID, ph.PaymentDate, COUNT(sc.ID) AS SalesCommissions
FROM dbo.tblaff_PaymentHistory ph WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Sales_Commissions sc WITH (NOLOCK) ON sc.PaymentID = ph.PaymentID
WHERE ph.PaymentDate < '2024-04-01'
GROUP BY ph.PaymentID, ph.PaymentDate
ORDER BY ph.PaymentDate
```

### 8.3 Check for orphaned records after cleanup
```sql
SELECT 'Orphaned Sales' AS RecordType, COUNT(*) AS Cnt
FROM dbo.tblaff_Sales s WITH (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM dbo.tblaff_Sales_Commissions sc WITH (NOLOCK) WHERE sc.SalesID = s.SalesID)
UNION ALL
SELECT 'Orphaned Leads', COUNT(*)
FROM dbo.tblaff_Leads l WITH (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM dbo.tblaff_Leads_Commissions lc WITH (NOLOCK) WHERE lc.LeadID = l.LeadID)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_DeleteOldCommissionsPriorToDate | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_DeleteOldCommissionsPriorToDate.sql*
