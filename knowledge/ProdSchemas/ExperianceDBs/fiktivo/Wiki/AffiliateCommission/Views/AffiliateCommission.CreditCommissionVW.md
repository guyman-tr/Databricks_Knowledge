# AffiliateCommission.CreditCommissionVW

> Commission reporting view joining CreditCommission with Credit and PaymentHistory, providing credit commission records with payment-aware UpdateDate for BI incremental loading.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | CreditID (from CreditCommission) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CreditCommissionVW provides credit commission records enriched with UpdateDate that accounts for payment processing. Same pattern as ClosedPositionCommissionVW: when paid (PaymentID > 0), UpdateDate = GREATEST(PaymentDate, CreditDate); when unpaid, UpdateDate = CreditDate. Includes AffiliateTypeID from CreditCommission (not present in the position commission variant). Requested by BI team (Feb 2024).

---

## 2. Business Logic

### 2.1 Payment-Aware UpdateDate

**Rules**:
- PaymentID > 0: correlated subquery to tblaff_PaymentHistory for PaymentDate
- UpdateDate = GREATEST(PaymentDate, CreditDate)
- Unpaid: UpdateDate = CreditDate

---

## 3. Data Overview

N/A - combines CreditCommission (4.75M) with Credit and PaymentHistory.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | From Credit. Credit event identifier. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | From CreditCommission. Earning affiliate. |
| 3 | Commission | float | NO | - | CODE-BACKED | From CreditCommission. Commission amount. |
| 4 | Tier | int | NO | - | CODE-BACKED | From CreditCommission. Commission tier. |
| 5 | Paid | bit | NO | - | CODE-BACKED | From CreditCommission. Payment status. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | From CreditCommission. Payment batch. |
| 7 | AffiliateTypeID | int | YES | - | CODE-BACKED | From CreditCommission. Affiliate type classification (PART-2448). |
| 8 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(PaymentDate, CreditDate) when paid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditCommission | JOIN | Commission records |
| - | AffiliateCommission.Credit | JOIN | CreditDate source |
| - | dbo.tblaff_PaymentHistory | Subquery | PaymentDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditCommissionVW (view)
├── AffiliateCommission.CreditCommission (table)
├── AffiliateCommission.Credit (table)
└── dbo.tblaff_PaymentHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditCommission | Table | INNER JOIN |
| AffiliateCommission.Credit | Table | INNER JOIN |
| dbo.tblaff_PaymentHistory | Table | Correlated subquery |

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

### 8.1 Recent credit commission changes
```sql
SELECT TOP 20 CreditID, AffiliateID, Commission, Tier, AffiliateTypeID, Paid, UpdateDate
FROM AffiliateCommission.CreditCommissionVW WITH (NOLOCK) ORDER BY UpdateDate DESC;
```

### 8.2 Paid commissions by affiliate type
```sql
SELECT AffiliateTypeID, SUM(Commission) AS TotalPaid, COUNT(*) AS Credits
FROM AffiliateCommission.CreditCommissionVW WITH (NOLOCK) WHERE Paid = 1
GROUP BY AffiliateTypeID ORDER BY TotalPaid DESC;
```

### 8.3 Incremental load
```sql
SELECT * FROM AffiliateCommission.CreditCommissionVW WITH (NOLOCK)
WHERE UpdateDate >= @LastLoadDate ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditCommissionVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.sql*
