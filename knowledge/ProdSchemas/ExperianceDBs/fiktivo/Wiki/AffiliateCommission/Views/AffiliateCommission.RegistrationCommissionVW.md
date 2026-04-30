# AffiliateCommission.RegistrationCommissionVW

> Commission reporting view joining RegistrationCommission with Registration and PaymentHistory, providing registration commission records with payment-aware UpdateDate for BI incremental loading.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | RegistrationID (from RegistrationCommission) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RegistrationCommissionVW provides registration commission records with UpdateDate that accounts for payment processing. Same pattern as ClosedPositionCommissionVW and CreditCommissionVW: when paid, UpdateDate = GREATEST(PaymentDate, RegistrationDate); when unpaid, UpdateDate = RegistrationDate. Requested by BI team (Feb 2024).

---

## 2. Business Logic

### 2.1 Payment-Aware UpdateDate

**Rules**: Same as ClosedPositionCommissionVW but using RegistrationDate instead of CommissionDate.

---

## 3. Data Overview

N/A - combines RegistrationCommission (14.5M) with Registration and PaymentHistory.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegistrationID | bigint | NO | - | CODE-BACKED | From Registration. Registration identifier. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | From RegistrationCommission. Earning affiliate. |
| 3 | Commission | float | NO | - | CODE-BACKED | From RegistrationCommission. Commission amount. |
| 4 | Tier | int | NO | - | CODE-BACKED | From RegistrationCommission. Commission tier. |
| 5 | Paid | bit | NO | - | CODE-BACKED | From RegistrationCommission. Payment status. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | From RegistrationCommission. Payment batch. |
| 7 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(PaymentDate, RegistrationDate) when paid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationCommission | JOIN | Commission records |
| - | AffiliateCommission.Registration | JOIN | RegistrationDate source |
| - | dbo.tblaff_PaymentHistory | Subquery | PaymentDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RegistrationCommissionVW (view)
├── AffiliateCommission.RegistrationCommission (table)
├── AffiliateCommission.Registration (table)
└── dbo.tblaff_PaymentHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommission | Table | INNER JOIN |
| AffiliateCommission.Registration | Table | INNER JOIN |
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

### 8.1 Recent registration commissions
```sql
SELECT TOP 20 RegistrationID, AffiliateID, Commission, Tier, Paid, UpdateDate
FROM AffiliateCommission.RegistrationCommissionVW WITH (NOLOCK) ORDER BY UpdateDate DESC;
```

### 8.2 Paid registration commissions
```sql
SELECT AffiliateID, SUM(Commission) AS TotalPaid, COUNT(*) AS Registrations
FROM AffiliateCommission.RegistrationCommissionVW WITH (NOLOCK) WHERE Paid = 1
GROUP BY AffiliateID ORDER BY TotalPaid DESC;
```

### 8.3 Incremental load
```sql
SELECT * FROM AffiliateCommission.RegistrationCommissionVW WITH (NOLOCK)
WHERE UpdateDate >= @LastLoadDate ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationCommissionVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.sql*
