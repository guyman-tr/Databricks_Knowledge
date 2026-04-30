# fiktivo.qry_aff_LeadRegistrationDate

> Returns the earliest lead registration date for each customer (CID), providing a lookup of when each customer first appeared as a lead in the affiliate system.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Leads |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a simple lookup: for each customer who has generated at least one lead event, what was the earliest date they appeared? It aggregates dbo.tblaff_Leads by customer ID (stored in the Optional3 column) and returns the minimum ORDER_DATE as the lead registration date.

This is useful for affiliate reporting and commission calculations that need to know when a customer first entered the affiliate funnel. For example, determining whether a deposit occurred within a certain time window after lead registration (for CPA eligibility checks), or for cohort analysis of affiliate-referred customers.

The CID is sourced from the `Optional3` column of dbo.tblaff_Leads (a multi-purpose field that stores the customer ID in this context). Only rows with Optional3 > 0 are included, filtering out leads without a resolved customer ID.

---

## 2. Business Logic

### 2.1 First Lead Date per Customer

**What**: Determines the earliest lead event timestamp for each unique customer.

**Columns/Parameters Involved**: `LeadDate` (output), `CID` (output/group by)

**Rules**:
- Groups by Optional3 (customer ID) from dbo.tblaff_Leads
- Returns MIN(ORDER_DATE) as LeadDate - the very first lead event for that customer
- Filters HAVING Optional3 > 0 to exclude leads without a resolved customer
- ISNULL(Optional3, 0) ensures NULLs are treated as 0 (then excluded by the HAVING clause)
- A customer with multiple lead events appears only once with their earliest date

---

## 3. Data Overview

| LeadDate | CID | Meaning |
|----------|-----|---------|
| 2012-08-23 | 229233 | Customer 229233 first appeared as a lead in August 2012. Any deposits after this date can be attributed to the affiliate funnel. |
| 2012-11-05 | 185491 | Customer 185491 entered as a lead in November 2012. |
| 2012-11-17 | 3744 | Long-standing customer 3744 (low ID = early customer) first appeared as a lead in late 2012 - may have been an existing customer re-attributed. |
| 2013-01-03 | 197499 | Customer 197499 registered as a lead in early January 2013. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeadDate | DATETIME | YES | - | CODE-BACKED | Earliest lead event date for this customer. Computed as MIN(ORDER_DATE) from dbo.tblaff_Leads. Represents when the customer first entered the affiliate funnel as a lead. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. Sourced from ISNULL(Optional3, 0) in dbo.tblaff_Leads. Optional3 is a multi-purpose field that stores the CID for lead events. Only customers with CID > 0 are included. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | dbo.tblaff_Leads | View base table | Aggregates MIN(ORDER_DATE) grouped by Optional3 (CID). |
| CID | (external) Customer system | Implicit | Customer identifier resolved from the lead event. |

### 5.2 Referenced By (other objects point to this)

No objects in the fiktivo schema reference this view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.qry_aff_LeadRegistrationDate (view)
    └── dbo.tblaff_Leads (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | SELECT MIN(ORDER_DATE), GROUP BY Optional3 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Find lead registration date for a specific customer
```sql
SELECT LeadDate, CID
FROM fiktivo.qry_aff_LeadRegistrationDate WITH (NOLOCK)
WHERE CID = 229233
```

### 8.2 Customers who became leads in a date range
```sql
SELECT CID, LeadDate
FROM fiktivo.qry_aff_LeadRegistrationDate WITH (NOLOCK)
WHERE LeadDate BETWEEN '2012-01-01' AND '2012-12-31'
ORDER BY LeadDate
```

### 8.3 Join with deposits to find time-to-deposit after lead
```sql
SELECT lr.CID, lr.LeadDate, MIN(d.date) AS FirstDepositDate,
       DATEDIFF(DAY, lr.LeadDate, MIN(d.date)) AS DaysToDeposit
FROM fiktivo.qry_aff_LeadRegistrationDate lr WITH (NOLOCK)
JOIN dbo.tblaff_Deposits d WITH (NOLOCK) ON lr.CID = d.CID
WHERE d.isFirstDeposit = 1
GROUP BY lr.CID, lr.LeadDate
ORDER BY DaysToDeposit
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.qry_aff_LeadRegistrationDate | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.qry_aff_LeadRegistrationDate.sql*
