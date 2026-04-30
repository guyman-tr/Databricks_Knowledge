# dbo.qry_aff_EarliestUnpaidCPA

> Returns the single earliest ORDER_DATE among unpaid, valid, affiliate-accepted CPA events, establishing the start boundary for payment period calculations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_CPA |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_EarliestUnpaidCPA returns exactly one row containing the ORDER_DATE of the oldest CPA deposit event that has not yet been paid. The payment processing system uses this date as the lower bound when constructing payment period windows -- any CPA commission dated on or after this date is a candidate for inclusion in the next payment run.

Without this anchor, payment calculations would need to scan the full CPA history each cycle. By exposing the earliest unpaid date as a scalar-equivalent single-row view, the payment engine can efficiently slice the dataset to only the relevant unpaid window.

If all CPA commissions are paid, or no valid accepted CPA events exist, the view returns no rows.

---

## 2. Business Logic

### 2.1 Triple Gate Filter

**What**: Three simultaneous conditions must be true for a CPA event to be a candidate for payment and therefore eligible to be the earliest unpaid record.

**Columns/Parameters Involved**: `Paid`, `Valid`, `AffiliateDepositAccepted`

**Rules**:
- `Paid = 0`: The commission linked to this deposit in tblaff_CPA_Commissions has not yet been paid
- `Valid = 1`: The CPA deposit itself passed internal validation (not fraudulent, minimum deposit met, first qualifying deposit)
- `AffiliateDepositAccepted = 1`: The deposit was successfully attributed to an affiliate
- All three must be true simultaneously; a deposit rejected by any gate is excluded

### 2.2 TOP 1 / ORDER BY Anchor

**What**: The view selects only the single chronologically earliest qualifying record.

**Columns/Parameters Involved**: `ORDER_DATE`

**Rules**:
- `ORDER BY ORDER_DATE ASC` (ascending, oldest first)
- `TOP 1` returns only that oldest row
- The result is a single datetime value representing the payment window start

---

## 3. Data Overview

Returns zero or one row. One row is the normal operating state (unpaid CPA commissions exist). Zero rows indicates either the payment queue is fully cleared or no valid accepted CPA events have ever been created.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ORDER_DATE | datetime | YES | - | VERIFIED | The earliest ORDER_DATE across all unpaid, valid, affiliate-accepted CPA deposits. Used as the start date for payment period range queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ORDER_DATE | dbo.tblaff_CPA | Base table | Source of CPA deposit timestamps and validation flags |
| Paid | dbo.tblaff_CPA_Commissions | LEFT JOIN on DepositID | Payment status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment period calculation logic | FROM / scalar reference | Consumer | Uses returned date as payment window lower bound |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_EarliestUnpaidCPA (view)
  +-- dbo.tblaff_CPA (table)
  +-- dbo.tblaff_CPA_Commissions (table, LEFT JOIN on DepositID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA | Table | Source of ORDER_DATE, Valid, AffiliateDepositAccepted |
| dbo.tblaff_CPA_Commissions | Table | LEFT JOIN to check Paid status |

### 6.2 Objects That Depend On This

No dependents registered in SSDT. Used at runtime by payment period calculation routines.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Underlying tblaff_CPA has a clustered index on ORDER_DATE and a composite NC index on (AffiliateDepositAccepted, Valid) that the engine can use to evaluate the filter efficiently.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Retrieve the earliest unpaid CPA date
```sql
SELECT ORDER_DATE
FROM dbo.qry_aff_EarliestUnpaidCPA WITH (NOLOCK)
```

### 8.2 Use as a window start for a payment run
```sql
DECLARE @WindowStart datetime
SELECT @WindowStart = ORDER_DATE
FROM dbo.qry_aff_EarliestUnpaidCPA WITH (NOLOCK)

SELECT cpa.DepositID, cpa.ORDER_DATE, comm.AffiliateID, comm.Commission
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON cpa.DepositID = comm.DepositID
WHERE cpa.ORDER_DATE >= @WindowStart
  AND comm.Paid = 0
  AND cpa.Valid = 1
  AND cpa.AffiliateDepositAccepted = 1
ORDER BY cpa.ORDER_DATE
```

### 8.3 Confirm payment queue is non-empty
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.qry_aff_EarliestUnpaidCPA WITH (NOLOCK))
       THEN 'Unpaid CPA queue is active'
       ELSE 'No unpaid CPA commissions' END AS QueueStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 7/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_EarliestUnpaidCPA | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_EarliestUnpaidCPA.sql*
