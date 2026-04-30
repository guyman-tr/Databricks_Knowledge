# dbo.qry_aff_EarliestUnpaidSale

> Returns the single earliest ORDER_DATE among unpaid, valid, affiliate-accepted sale events, establishing the start boundary for sale commission payment period calculations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Sales |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_EarliestUnpaidSale returns exactly one row containing the ORDER_DATE of the oldest sale event that has not yet been paid. The payment processing system uses this date as the lower bound when constructing payment period windows for sale-based commissions.

Sales represent revenue-generating transactions by customers referred by affiliates. This is a deeper funnel conversion event than a lead or registration, and typically commands a higher commission rate. This view anchors the payment window specifically for sale-model commissions, in parallel with the equivalent views for CPA, lead, and registration models.

If all sale commissions are paid, or no valid accepted sale events exist, the view returns no rows.

---

## 2. Business Logic

### 2.1 Triple Gate Filter

**What**: Three simultaneous conditions must be true for a sale event to be a candidate for payment.

**Columns/Parameters Involved**: `Paid`, `Valid`, `AffiliateSaleAccepted`

**Rules**:
- `Paid = 0`: The commission in tblaff_Sales_Commissions linked to this sale has not been paid
- `Valid = 1`: The sale passed internal validation (not reversed, not fraudulent, meets minimum criteria)
- `AffiliateSaleAccepted = 1`: The sale was attributed to an affiliate
- All three must be true; a sale excluded by any gate does not contribute

### 2.2 TOP 1 / ORDER BY Anchor

**What**: Selects only the single chronologically earliest qualifying record.

**Columns/Parameters Involved**: `ORDER_DATE`

**Rules**:
- `ORDER BY ORDER_DATE ASC` (ascending, oldest first)
- `TOP 1` returns only that oldest row
- Result is a single datetime representing the payment window start for sales

---

## 3. Data Overview

Returns zero or one row. One row is the normal operating state (unpaid sale commissions exist). Zero rows indicates the sale payment queue is fully cleared or no valid accepted sale events have been created.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ORDER_DATE | datetime | YES | - | VERIFIED | The earliest ORDER_DATE across all unpaid, valid, affiliate-accepted sale events. Used as the start date for sale commission payment period range queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ORDER_DATE | dbo.tblaff_Sales | Base table | Source of sale event timestamps, Valid, and AffiliateSaleAccepted flags |
| Paid | dbo.tblaff_Sales_Commissions | LEFT JOIN on SaleID | Payment status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment period calculation logic | FROM / scalar reference | Consumer | Uses returned date as sale payment window lower bound |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_EarliestUnpaidSale (view)
  +-- dbo.tblaff_Sales (table)
  +-- dbo.tblaff_Sales_Commissions (table, LEFT JOIN on SaleID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales | Table | Source of ORDER_DATE, Valid, AffiliateSaleAccepted |
| dbo.tblaff_Sales_Commissions | Table | LEFT JOIN to check Paid status |

### 6.2 Objects That Depend On This

No dependents registered in SSDT. Used at runtime by payment period calculation routines.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Underlying tblaff_Sales has a clustered index on ORDER_DATE which supports the ORDER BY efficiently.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Retrieve the earliest unpaid sale date
```sql
SELECT ORDER_DATE
FROM dbo.qry_aff_EarliestUnpaidSale WITH (NOLOCK)
```

### 8.2 Use as a window start for a sale payment run
```sql
DECLARE @WindowStart datetime
SELECT @WindowStart = ORDER_DATE
FROM dbo.qry_aff_EarliestUnpaidSale WITH (NOLOCK)

SELECT s.SaleID, s.ORDER_DATE, comm.AffiliateID, comm.Commission
FROM dbo.tblaff_Sales s WITH (NOLOCK)
JOIN dbo.tblaff_Sales_Commissions comm WITH (NOLOCK) ON s.SaleID = comm.SaleID
WHERE s.ORDER_DATE >= @WindowStart
  AND comm.Paid = 0
  AND s.Valid = 1
  AND s.AffiliateSaleAccepted = 1
ORDER BY s.ORDER_DATE
```

### 8.3 Confirm sale payment queue is non-empty
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.qry_aff_EarliestUnpaidSale WITH (NOLOCK))
       THEN 'Unpaid sale queue is active'
       ELSE 'No unpaid sale commissions' END AS QueueStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_EarliestUnpaidSale | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_EarliestUnpaidSale.sql*
