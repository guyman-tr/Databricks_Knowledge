# dbo.tblaff_CPA_Commissions

> Stores tier-based affiliate commission records generated from CPA (Cost Per Acquisition/first deposit) events, with trigger-enforced referential integrity to tblaff_Affiliates and tblaff_CPA.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 8 active |

---

## 1. Business Meaning

dbo.tblaff_CPA_Commissions records the affiliate commissions generated from CPA events (first-time deposits stored in tblaff_CPA). CPA is the primary commission model - affiliates earn a fixed amount when their referred customer makes their first deposit. Each row represents a commission entry for one tier level, enabling multi-tier CPA distribution.

This is the second-largest commission table (~1.56M records), reflecting the high volume of CPA-based affiliate payouts. CPA commissions are the core revenue driver for most affiliates. Triggers enforce that DepositID references a valid CPA record and AffiliateID references a valid affiliate.

The commission processing engine creates rows when CPA events in tblaff_CPA are processed. The `UpdateSubAffiliateID` procedure handles late-binding attribution. The `AffiliateTypeID` column (unique to this commission table) enables CPA rate differentiation by affiliate tier.

---

## 2. Business Logic

### 2.1 Multi-Tier CPA Distribution

**What**: Each CPA event generates separate commission rows per affiliate tier.

**Columns/Parameters Involved**: `DepositID`, `AffiliateID`, `Commission`, `Tier`, `AffiliateTypeID`

**Rules**:
- Tier 1: Direct referring affiliate receives the primary CPA commission
- Tier 2-5: Parent affiliates receive cascading CPA commissions (typically lower amounts)
- `AffiliateTypeID` links to tblaff_AffiliateTypes for CPA rate differentiation - different affiliate types may earn different CPA rates for the same event
- Trigger-based RI: INSERT/UPDATE triggers verify DepositID exists in tblaff_CPA and AffiliateID exists in tblaff_Affiliates

### 2.2 Payment Lifecycle

**What**: Tracks payment status for each CPA commission entry.

**Columns/Parameters Involved**: `Paid`, `PaymentID`

**Rules**:
- `Paid = 0, PaymentID = 0`: Unpaid - available for next payment batch
- `Paid = 1, PaymentID > 0`: Included in completed payment batch
- Payment views aggregate unpaid CPA commissions per affiliate for payment generation

---

## 3. Data Overview

Table contains 1,564,398 rows. CPA commissions are the second-highest volume commission type, reflecting the importance of first-deposit acquisition in affiliate marketing.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | DepositID | int | YES | 0 | VERIFIED | References the source CPA event in tblaff_CPA.DepositID. Trigger enforces RI. Multiple rows can share the same DepositID (one per tier). |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this CPA commission. Trigger enforces RI against tblaff_Affiliates. |
| 4 | Commission | float | YES | 0 | VERIFIED | CPA commission amount for this tier. Positive = earned commission. Zero = no commission at this tier. |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1 = direct affiliate, 2-5 = parent affiliates in the hierarchy. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid, 1 = paid. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when paid. 0 = not yet paid. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. Updatable by UpdateSubAffiliateID. |
| 9 | AffiliateTypeID | int | YES | - | VERIFIED | References tblaff_AffiliateTypes for CPA rate differentiation. Different affiliate types earn different CPA rates. Unique to this commission table among the nine commission types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | dbo.tblaff_CPA | Implicit (trigger) | The CPA/first-deposit event that generated this commission |
| AffiliateID | dbo.tblaff_Affiliates | Implicit (trigger) | The affiliate receiving this commission |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | The payment batch when paid |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit | Affiliate type for rate differentiation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding attribution updates |
| dbo.qry_aff_Tier1CPACommissions | FROM | View (READER) | Tier 1 CPA commission aggregation |
| dbo.qry_aff_CPADetailAllTiers | FROM | View (READER) | All-tier CPA commission details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.UpdateSubAffiliateID | Stored Procedure | MODIFIER |
| dbo.qry_aff_Tier1CPACommissions through Tier5 | Views | Commission aggregation per tier |
| dbo.qry_aff_CPADetailAllTiers | View | All-tier detail view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_CPA_Commissions_PK | NC PK | ID ASC | - | - | Active (PAGE) |
| CIX_tblaff_CPA_Commissions_AffiliateID | CLUSTERED | AffiliateID ASC | - | - | Active (PAGE) |
| IDX_CPA_COMM_PAID | NC | Paid | DepositID, AffiliateID, Commission, Tier | - | Active (PAGE) |
| IDX_tblaff_CPA_Commissions_Affiliate_Tier_AffiliateTypeID | NC | AffiliateID, Tier, AffiliateTypeID | DepositID | - | Active (PAGE) |
| IDX_tblaff_CPA_Commissions_Composite | NC | DepositID, Tier | AffiliateID | - | Active (PAGE) |
| IDX_tblaff_CPA_Commissions_Tier | NC | Tier | DepositID, AffiliateID, Commission | - | Active (PAGE) |
| IX_tblaff_Sales_Commissions_Incl4 | NC | AffiliateID, Tier | DepositID | - | Active (PAGE) |
| missing_index_65_64 | NC | AffiliateID, Tier | - | - | Active (PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_CPA_Commissions_Paid | DEFAULT | 0 - Unpaid by default |
| DF_tblaff_CPA_Commissions_PaymentID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Unpaid CPA commissions by affiliate
```sql
SELECT AffiliateID, Tier, COUNT(*) AS Records, SUM(Commission) AS TotalUnpaid
FROM dbo.tblaff_CPA_Commissions WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID, Tier
ORDER BY TotalUnpaid DESC
```

### 8.2 CPA commissions by affiliate type
```sql
SELECT AffiliateTypeID, Tier, COUNT(*) AS Records, SUM(Commission) AS Total
FROM dbo.tblaff_CPA_Commissions WITH (NOLOCK)
WHERE AffiliateTypeID IS NOT NULL
GROUP BY AffiliateTypeID, Tier
ORDER BY AffiliateTypeID, Tier
```

### 8.3 Join CPA commission with deposit details
```sql
SELECT cc.ID, cc.Commission, cc.Tier, cc.Paid,
       c.Optional3 AS CustomerCID, c.amount AS DepositAmount
FROM dbo.tblaff_CPA_Commissions cc WITH (NOLOCK)
JOIN dbo.tblaff_CPA c WITH (NOLOCK) ON cc.DepositID = c.DepositID
WHERE cc.AffiliateID = @AffiliateID
ORDER BY cc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_CPA_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_CPA_Commissions.sql*
