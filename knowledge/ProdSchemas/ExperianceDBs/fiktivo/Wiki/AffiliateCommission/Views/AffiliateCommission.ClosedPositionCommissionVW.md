# AffiliateCommission.ClosedPositionCommissionVW

> Commission reporting view joining ClosedPositionCommission with ClosedPosition and PaymentHistory to provide commission records with computed UpdateDate reflecting the later of commission calculation or payment date.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | ClosedPositionID (from ClosedPositionCommission) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ClosedPositionCommissionVW provides commission records enriched with an UpdateDate that accounts for both commission calculation time and payment processing time. When a commission has been paid (PaymentID > 0), the UpdateDate is the later of CommissionDate and PaymentDate from tblaff_PaymentHistory. When unpaid, UpdateDate equals CommissionDate.

This view was requested by the BI team (Eyal Boaz & Merav Hunger, Feb 2024) for incremental data loading into BI warehouses. The UpdateDate fix (PART: May 2024) ensures payment events don't get missed by CDC pipelines that use UpdateDate as a watermark.

---

## 2. Business Logic

### 2.1 UpdateDate with Payment Awareness

**What**: UpdateDate reflects the most recent change including payment events.

**Columns/Parameters Involved**: `PaymentID`, `CommissionDate`, `PaymentDate`, `UpdateDate`

**Rules**:
- If PaymentID > 0: UpdateDate = GREATEST(PaymentDate, CommissionDate) via correlated subquery to tblaff_PaymentHistory
- If PaymentID = 0: UpdateDate = CommissionDate
- Ensures BI incremental loads capture both commission changes and payment events

---

## 3. Data Overview

N/A - view combines ClosedPositionCommission (246K rows) with ClosedPosition and PaymentHistory.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | From ClosedPosition. Position identifier. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | From ClosedPositionCommission. Earning affiliate. |
| 3 | Commission | float | NO | - | CODE-BACKED | From ClosedPositionCommission. Commission amount. |
| 4 | Tier | int | NO | - | CODE-BACKED | From ClosedPositionCommission. Commission tier. |
| 5 | Paid | bit | NO | - | CODE-BACKED | From ClosedPositionCommission. Payment status. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | From ClosedPositionCommission. Payment batch. |
| 7 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(PaymentDate, CommissionDate) when paid; CommissionDate when unpaid. For CDC watermarks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPositionCommission | JOIN | Commission records |
| - | AffiliateCommission.ClosedPosition | JOIN | CommissionDate source |
| - | dbo.tblaff_PaymentHistory | Subquery | PaymentDate for paid commissions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ClosedPositionCommissionVW (view)
├── AffiliateCommission.ClosedPositionCommission (table)
├── AffiliateCommission.ClosedPosition (table)
└── dbo.tblaff_PaymentHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionCommission | Table | INNER JOIN |
| AffiliateCommission.ClosedPosition | Table | INNER JOIN |
| dbo.tblaff_PaymentHistory | Table | Correlated subquery for PaymentDate |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Recent commission changes
```sql
SELECT TOP 20 ClosedPositionID, AffiliateID, Commission, Tier, Paid, PaymentID, UpdateDate
FROM AffiliateCommission.ClosedPositionCommissionVW WITH (NOLOCK) ORDER BY UpdateDate DESC;
```

### 8.2 Paid commissions with payment dates
```sql
SELECT ClosedPositionID, AffiliateID, Commission, PaymentID, UpdateDate
FROM AffiliateCommission.ClosedPositionCommissionVW WITH (NOLOCK)
WHERE Paid = 1 ORDER BY UpdateDate DESC;
```

### 8.3 Incremental load for BI
```sql
SELECT * FROM AffiliateCommission.ClosedPositionCommissionVW WITH (NOLOCK)
WHERE UpdateDate >= @LastLoadDate ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. View was requested by BI team (Eyal Boaz & Merav Hunger) per code comments.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionCommissionVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.sql*
