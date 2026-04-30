# dbo.tblaff_Chargebacks_Commissions

> Stores tier-based affiliate commission adjustments from chargeback events, typically negative amounts that reduce affiliate payouts when customers reverse transactions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active |

---

## 1. Business Meaning

dbo.tblaff_Chargebacks_Commissions records commission adjustments triggered by customer chargeback events (tblaff_Chargebacks). When a customer reverses a deposit via chargeback, the affiliate's previously earned commission may be clawed back. Each row represents one tier's adjustment for a chargeback event.

Chargebacks protect the platform from paying commissions on reversed transactions. This is the smallest active commission table (~8K records), reflecting that chargebacks are relatively rare compared to deposits and sales. The `UpdateSubAffiliateID` procedure manages late-binding attribution.

---

## 2. Business Logic

### 2.1 Chargeback Commission Clawback

**What**: Commission reversals cascading through the tier hierarchy when customers issue chargebacks.

**Columns/Parameters Involved**: `ChargebackID`, `AffiliateID`, `Commission`, `Tier`

**Rules**:
- Commission values are typically negative (clawback of previously paid commission)
- Each ChargebackID generates one row per affected tier
- Tier 1: Direct affiliate's commission is reversed
- Tier 2+: Parent affiliates' cascading commissions are also reversed

### 2.2 Payment Lifecycle

**Columns/Parameters Involved**: `Paid`, `PaymentID`

**Rules**:
- Same pattern as all commission tables: Paid=0/PaymentID=0 = unpaid, Paid=1/PaymentID>0 = included in payment

---

## 3. Data Overview

Table contains 8,010 rows. Chargebacks are rare events representing reversed customer transactions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | ChargebackID | int | YES | 0 | VERIFIED | References the chargeback event in tblaff_Chargebacks.ChargebackID. |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate whose commission is being adjusted. Maps to tblaff_Affiliates. |
| 4 | Commission | float | YES | 0 | VERIFIED | Commission adjustment amount. Typically negative (clawback). |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1 = direct affiliate, 2-5 = parent affiliates. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid adjustment, 1 = included in payment batch. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when paid. 0 = not yet paid. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChargebackID | dbo.tblaff_Chargebacks | Implicit | The chargeback event triggering this adjustment |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate being adjusted |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | Payment batch when paid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding attribution |
| dbo.qry_aff_ChargebacksDetailAllTiers | FROM | View (READER) | All-tier chargeback commission details |

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
| dbo.qry_aff_Tier1ChargebacksCommissions through Tier5 | Views | Per-tier aggregation |
| dbo.qry_aff_ChargebacksDetailAllTiers | View | All-tier detail |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| tblaff_Chargebacks_Commissions_PK | CLUSTERED PK | ID ASC | - | - | Active (PAGE) |
| (unnamed missing index) | NC | AffiliateID, Paid | - | - | Active |
| IDX_tblaff_Chargebacks_Commissions_Optional3 | NC | ChargebackID | - | - | Active (PAGE) |
| IDX_tblaff_Chargebacks_Commissions_Tier | NC | Tier | ChargebackID, AffiliateID, Commission | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Chargebacks_Commissions_Paid | DEFAULT | 0 |
| DF_tblaff_Chargebacks_Commissions_PaymentID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Unpaid chargeback adjustments
```sql
SELECT ChargebackID, AffiliateID, Commission, Tier
FROM dbo.tblaff_Chargebacks_Commissions WITH (NOLOCK)
WHERE Paid = 0
ORDER BY Commission ASC
```

### 8.2 Total clawback by affiliate
```sql
SELECT AffiliateID, SUM(Commission) AS TotalClawback, COUNT(*) AS ChargebackCount
FROM dbo.tblaff_Chargebacks_Commissions WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY TotalClawback ASC
```

### 8.3 Chargebacks with event details
```sql
SELECT cc.Commission, cc.Tier, cb.Optional3 AS CustomerCID, cb.amount AS ChargebackAmount
FROM dbo.tblaff_Chargebacks_Commissions cc WITH (NOLOCK)
JOIN dbo.tblaff_Chargebacks cb WITH (NOLOCK) ON cc.ChargebackID = cb.ChargebackID
WHERE cc.AffiliateID = @AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Chargebacks_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Chargebacks_Commissions.sql*
