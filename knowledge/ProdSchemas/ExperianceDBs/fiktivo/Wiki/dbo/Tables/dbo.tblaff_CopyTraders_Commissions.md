# dbo.tblaff_CopyTraders_Commissions

> Stores tier-based affiliate commission records from copy-trading events, linking each copy-trader activation to the affiliate's commission amount and payment status.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 5 active |

---

## 1. Business Meaning

dbo.tblaff_CopyTraders_Commissions records affiliate commissions earned when referred customers activate copy-trading (tblaff_CopyTraders). Copy-trading is eToro's signature social feature where customers automatically replicate the trades of successful investors. Affiliates earn commissions when their referred customers start copying other traders.

Contains ~76K records. Each copy-trader activation generates one row per tier level for multi-tier commission distribution. The `UpdateSubAffiliateID` procedure manages late-binding attribution.

---

## 2. Business Logic

### 2.1 Multi-Tier Copy-Trading Commission

**What**: Commission distribution across affiliate tiers for copy-trading activations.

**Columns/Parameters Involved**: `CopyTraderID`, `AffiliateID`, `Commission`, `Tier`

**Rules**:
- CopyTraderID references the copy-trading event in tblaff_CopyTraders
- Tier 1-5: Standard multi-tier distribution pattern
- Commission reflects the value of the copy-trading activation for affiliate attribution

### 2.2 Payment Lifecycle

**Columns/Parameters Involved**: `Paid`, `PaymentID`
- Same pattern: Paid=0/PaymentID=0 = unpaid, Paid=1/PaymentID>0 = paid

---

## 3. Data Overview

Table contains 75,656 rows of copy-trader commission records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | CopyTraderID | int | YES | 0 | VERIFIED | References tblaff_CopyTraders.CopyTraderID. The copy-trading activation event. |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this commission. Maps to tblaff_Affiliates. |
| 4 | Commission | float | YES | 0 | VERIFIED | Commission amount for this tier level. |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1 = direct, 2-5 = parent affiliates. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid, 1 = paid. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when paid. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CopyTraderID | dbo.tblaff_CopyTraders | Implicit | The copy-trading activation event |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate receiving this commission |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | Payment batch when paid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding attribution |
| dbo.qry_aff_CopyTraderDetailAllTiers | FROM | View (READER) | All-tier copy-trader commission details |

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
| dbo.qry_aff_Tier1CopyTradersCommissions through Tier5 | Views | Per-tier aggregation |
| dbo.qry_aff_CopyTraderDetailAllTiers | View | All-tier detail |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_CopyTraders_Commissions_PK | NC PK | ID ASC | - | - | Active (PAGE) |
| CLU_IDX_tblaff_CopyTraders_Commissions | CLUSTERED | AffiliateID, Paid | - | - | Active (fill 70%, PAGE) |
| IDX_tblaff_CopyTraders_Commissions_CopyTraderID | NC | CopyTraderID | - | - | Active (PAGE) |
| IDX_tblaff_CopyTraders_Commissions_Tier | NC | Tier | CopyTraderID, AffiliateID, Commission | - | Active (PAGE) |
| IX_AffiliateID | NC | AffiliateID, Paid | CopyTraderID, Commission | - | Active (PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_CopyTraders_Commissions_Paid | DEFAULT | 0 |
| DF_tblaff_CopyTraders_Commissions_PaymentID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Unpaid copy-trader commissions per affiliate
```sql
SELECT AffiliateID, Tier, COUNT(*) AS Records, SUM(Commission) AS TotalUnpaid
FROM dbo.tblaff_CopyTraders_Commissions WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID, Tier
ORDER BY TotalUnpaid DESC
```

### 8.2 Copy-trader commissions with event details
```sql
SELECT cc.Commission, cc.Tier, ct.Optional3 AS CustomerCID
FROM dbo.tblaff_CopyTraders_Commissions cc WITH (NOLOCK)
JOIN dbo.tblaff_CopyTraders ct WITH (NOLOCK) ON cc.CopyTraderID = ct.CopyTraderID
WHERE cc.AffiliateID = @AffiliateID AND cc.Paid = 0
```

### 8.3 Commission totals by tier
```sql
SELECT Tier, COUNT(*) AS Records, SUM(Commission) AS Total
FROM dbo.tblaff_CopyTraders_Commissions WITH (NOLOCK)
GROUP BY Tier ORDER BY Tier
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_CopyTraders_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_CopyTraders_Commissions.sql*
