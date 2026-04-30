# dbo.qry_aff_EarliestUnpaidLead

> Returns the single earliest ORDER_DATE among unpaid, valid, affiliate-accepted lead events, establishing the start boundary for lead commission payment period calculations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Leads |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_EarliestUnpaidLead returns exactly one row containing the ORDER_DATE of the oldest lead event that has not yet been paid. The payment processing system uses this date as the lower bound when constructing payment period windows for lead-based commissions.

Leads represent the earliest stage of the affiliate conversion funnel (demo account creation, form submission, initial inquiry). This view anchors the payment window specifically for lead-model commissions, distinct from CPA (deposit), registration, and sale models which each have their own equivalent view.

If all lead commissions are paid, or no valid accepted lead events exist, the view returns no rows.

---

## 2. Business Logic

### 2.1 Triple Gate Filter

**What**: Three simultaneous conditions must be true for a lead event to be a candidate for payment.

**Columns/Parameters Involved**: `Paid`, `Valid`, `AffiliateSaleAccepted`

**Rules**:
- `Paid = 0`: The commission in tblaff_Leads_Commissions linked to this lead has not been paid
- `Valid = 1`: The lead passed internal validation (not a duplicate, genuine interest signal)
- `AffiliateSaleAccepted = 1`: The lead was attributed to an affiliate (note: column uses legacy "SaleAccepted" naming inherited from a shared codebase pattern)
- All three must be true; a lead excluded by any gate does not contribute

### 2.2 TOP 1 / ORDER BY Anchor

**What**: Selects only the single chronologically earliest qualifying record.

**Columns/Parameters Involved**: `ORDER_DATE`

**Rules**:
- `ORDER BY ORDER_DATE ASC` (ascending, oldest first)
- `TOP 1` returns only that oldest row
- Result is a single datetime representing the payment window start for leads

---

## 3. Data Overview

Returns zero or one row. One row is the normal operating state (unpaid lead commissions exist). Zero rows indicates the lead payment queue is fully cleared or no valid accepted lead events have been created.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ORDER_DATE | datetime | YES | - | VERIFIED | The earliest ORDER_DATE across all unpaid, valid, affiliate-accepted lead events. Used as the start date for lead commission payment period range queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ORDER_DATE | dbo.tblaff_Leads | Base table | Source of lead event timestamps, Valid, and AffiliateSaleAccepted flags |
| Paid | dbo.tblaff_Leads_Commissions | LEFT JOIN on LeadID | Payment status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment period calculation logic | FROM / scalar reference | Consumer | Uses returned date as lead payment window lower bound |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_EarliestUnpaidLead (view)
  +-- dbo.tblaff_Leads (table)
  +-- dbo.tblaff_Leads_Commissions (table, LEFT JOIN on LeadID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | Source of ORDER_DATE, Valid, AffiliateSaleAccepted |
| dbo.tblaff_Leads_Commissions | Table | LEFT JOIN to check Paid status |

### 6.2 Objects That Depend On This

No dependents registered in SSDT. Used at runtime by payment period calculation routines.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Underlying tblaff_Leads has a clustered index on ORDER_DATE which supports the ORDER BY efficiently.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Retrieve the earliest unpaid lead date
```sql
SELECT ORDER_DATE
FROM dbo.qry_aff_EarliestUnpaidLead WITH (NOLOCK)
```

### 8.2 Use as a window start for a lead payment run
```sql
DECLARE @WindowStart datetime
SELECT @WindowStart = ORDER_DATE
FROM dbo.qry_aff_EarliestUnpaidLead WITH (NOLOCK)

SELECT l.LeadID, l.ORDER_DATE, comm.AffiliateID, comm.Commission
FROM dbo.tblaff_Leads l WITH (NOLOCK)
JOIN dbo.tblaff_Leads_Commissions comm WITH (NOLOCK) ON l.LeadID = comm.LeadID
WHERE l.ORDER_DATE >= @WindowStart
  AND comm.Paid = 0
  AND l.Valid = 1
  AND l.AffiliateSaleAccepted = 1
ORDER BY l.ORDER_DATE
```

### 8.3 Confirm lead payment queue is non-empty
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.qry_aff_EarliestUnpaidLead WITH (NOLOCK))
       THEN 'Unpaid lead queue is active'
       ELSE 'No unpaid lead commissions' END AS QueueStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_EarliestUnpaidLead | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_EarliestUnpaidLead.sql*
