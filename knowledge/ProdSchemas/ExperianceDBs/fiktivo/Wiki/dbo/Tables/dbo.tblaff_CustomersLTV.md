# dbo.tblaff_CustomersLTV

> Stores per-customer Lifetime Value (LTV) calculations linked to affiliate serial IDs for evaluating affiliate traffic quality and ROI.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table holds pre-calculated LTV (Lifetime Value) scores for customers attributed to the affiliate program. Each row links a customer (CustomerID) and their affiliate tracking serial (SerialID) to a calculated LTV value representing the customer's expected total revenue contribution.

With 81,123 records, this is a focused analytics table. Unlike dbo.UpdatedLTV which stores snapshots with gross/net/past/future decomposition, this table stores a single aggregated LTV decimal value per customer-serial combination. It is designed for quick lookups in commission calculations and affiliate performance reporting.

The LTV value is used to assess affiliate traffic quality: affiliates who refer high-LTV customers are more valuable partners and may qualify for better commission rates or CPA slabs.

---

## 2. Business Logic

### 2.1 Customer-Serial LTV Mapping

**What**: LTV is calculated per customer-serial pair, not just per customer.

**Columns/Parameters Involved**: `CustomerID`, `SerialID`, `Ltv`

**Rules**:
- Each CustomerID-SerialID pair represents a unique affiliate attribution path
- The same customer could appear with different SerialIDs if they were re-attributed to a different affiliate
- Ltv is a decimal(18,11) with high precision for financial calculations
- Higher LTV values indicate more profitable customer referrals

---

## 3. Data Overview

| ID | CustomerID | SerialID | Ltv | Meaning |
|---|---|---|---|---|
| 6030437 | 2417527 | 3 | 711.52 | High-value customer attributed to serial 3 - represents premium affiliate traffic |
| 6030435 | 737939 | 2323 | 1303.69 | Highest LTV in sample - an extremely valuable customer referral for serial 2323 |
| 6030434 | 2155432 | 19626 | 219.98 | Moderate LTV customer - represents typical affiliate-referred customer value |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerID | bigint | NO | - | VERIFIED | Trading platform customer identifier. The customer whose lifetime value is being measured. |
| 2 | SerialID | int | NO | - | VERIFIED | Affiliate serial/tracking identifier linking this customer to a specific affiliate tracking mechanism. |
| 3 | Ltv | decimal(18,11) | NO | - | VERIFIED | Calculated Lifetime Value of the customer. High precision (11 decimal places) for financial calculations. Higher values = more profitable customer. |
| 4 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. NOT FOR REPLICATION. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_CustomersLTV | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get top LTV customers
```sql
SELECT TOP 10 CustomerID, SerialID, Ltv
FROM dbo.tblaff_CustomersLTV WITH (NOLOCK)
ORDER BY Ltv DESC
```

### 8.2 Average LTV by affiliate serial
```sql
SELECT SerialID, COUNT(*) AS Customers, AVG(Ltv) AS AvgLtv, SUM(Ltv) AS TotalLtv
FROM dbo.tblaff_CustomersLTV WITH (NOLOCK)
GROUP BY SerialID
ORDER BY TotalLtv DESC
```

### 8.3 LTV distribution
```sql
SELECT
    CASE WHEN Ltv < 100 THEN 'Low (<100)'
         WHEN Ltv < 500 THEN 'Medium (100-500)'
         WHEN Ltv < 1000 THEN 'High (500-1000)'
         ELSE 'Premium (1000+)' END AS LtvBucket,
    COUNT(*) AS Customers
FROM dbo.tblaff_CustomersLTV WITH (NOLOCK)
GROUP BY CASE WHEN Ltv < 100 THEN 'Low (<100)'
              WHEN Ltv < 500 THEN 'Medium (100-500)'
              WHEN Ltv < 1000 THEN 'High (500-1000)'
              ELSE 'Premium (1000+)' END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_CustomersLTV | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_CustomersLTV.sql*
