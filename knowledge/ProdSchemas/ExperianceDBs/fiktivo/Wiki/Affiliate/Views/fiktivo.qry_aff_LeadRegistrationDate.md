# fiktivo.qry_aff_LeadRegistrationDate

> View that returns the earliest lead date for each customer (CID) from the affiliate leads table, used to determine when each customer first entered the affiliate funnel.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | CID (derived from Optional3) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

qry_aff_LeadRegistrationDate answers the question "when did each customer first become a lead in the affiliate system?" It returns the earliest ORDER_DATE from the dbo.tblaff_Leads table for each customer, identified by the Optional3 column (which stores the CID). This is used for attribution timing - determining the lag between lead creation and subsequent conversion events (registration, deposit, sale).

This view exists because the affiliate commission system needs to know the original lead date to calculate days-to-convert metrics, enforce attribution windows, and reconcile commission timing. Without it, each query needing the first lead date would have to implement the MIN(ORDER_DATE) GROUP BY logic inline.

The view reads from dbo.tblaff_Leads (cross-schema in the dbo schema) and filters to rows where Optional3 > 0 (valid CIDs only). The HAVING clause excludes rows with null or zero CIDs.

---

## 2. Business Logic

### 2.1 First Lead Date Resolution

**What**: Determines the earliest lead event date per customer for attribution timing.

**Columns/Parameters Involved**: `LeadDate`, `CID`

**Rules**:
- MIN(ORDER_DATE) gives the first lead date for each customer
- Optional3 is used as the CID column (ISNULL(Optional3, 0))
- Only customers with Optional3 > 0 are included (HAVING clause filters out invalid/null CIDs)
- One row per customer - no duplicates

---

## 3. Data Overview

N/A - view depends on dbo.tblaff_Leads which is a cross-schema table. Query results would show (LeadDate, CID) pairs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeadDate | datetime | YES | - | CODE-BACKED | Earliest lead date for this customer. Computed as MIN(ORDER_DATE) from dbo.tblaff_Leads. Represents when the customer first entered the affiliate lead funnel. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. Derived from ISNULL(Optional3, 0) in dbo.tblaff_Leads. Optional3 stores the CID in the leads table. Only values > 0 are included. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID (Optional3) | dbo.tblaff_Leads | SELECT + GROUP BY | Reads ORDER_DATE and Optional3, aggregates by CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.qry_aff_LeadRegistrationDate (view)
└── dbo.tblaff_Leads (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table (cross-schema) | SELECT MIN(ORDER_DATE), GROUP BY Optional3 |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get first lead dates for recent customers
```sql
SELECT TOP 10 CID, LeadDate
FROM fiktivo.qry_aff_LeadRegistrationDate WITH (NOLOCK)
ORDER BY LeadDate DESC
```

### 8.2 Calculate days between lead and current date
```sql
SELECT CID, LeadDate, DATEDIFF(day, LeadDate, GETDATE()) AS DaysSinceLead
FROM fiktivo.qry_aff_LeadRegistrationDate WITH (NOLOCK)
ORDER BY LeadDate DESC
```

### 8.3 Count leads by month
```sql
SELECT YEAR(LeadDate) AS Yr, MONTH(LeadDate) AS Mo, COUNT(*) AS LeadCount
FROM fiktivo.qry_aff_LeadRegistrationDate WITH (NOLOCK)
GROUP BY YEAR(LeadDate), MONTH(LeadDate)
ORDER BY Yr DESC, Mo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.qry_aff_LeadRegistrationDate | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.qry_aff_LeadRegistrationDate.sql*
