# dbo.tblaff_Bonuses_Commissions

> Stores tier-based affiliate commission records generated from customer bonus events, linking each bonus to the affiliate's commission amount and payment status.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 7 active |

---

## 1. Business Meaning

dbo.tblaff_Bonuses_Commissions records the affiliate commissions generated from customer bonus events (tblaff_Bonuses). Each row represents a single commission entry for one tier level - when a bonus triggers multi-tier commissions, separate rows are created for Tier 1 (direct affiliate), Tier 2 (parent affiliate), etc. This is the commission junction between the bonus event and the affiliate payout.

Without this table, the system could not track how much commission each affiliate earns from bonus-related events or manage the payment lifecycle (unpaid -> paid) for these commissions. It is one of nine parallel commission tables that together form the complete affiliate commission ledger.

Data is created by the commission processing engine when bonuses in tblaff_Bonuses are processed. The `UpdateSubAffiliateID` procedure can update SubAffiliateID and AffiliateID for late-binding attribution. Contains ~558K commission records.

---

## 2. Business Logic

### 2.1 Multi-Tier Commission Distribution

**What**: Each bonus event generates separate commission rows for each affiliate tier.

**Columns/Parameters Involved**: `BonusID`, `AffiliateID`, `Commission`, `Tier`

**Rules**:
- Tier 1: Direct referring affiliate - receives the primary commission
- Tier 2+: Parent affiliates in the hierarchy (from tblaff_Tier2Members) - receive cascading commissions
- Commission can be 0 (no commission for this tier) or negative (reversal/clawback, e.g., -2 for Tier 2)
- The same BonusID can appear multiple times with different Tier values

### 2.2 Payment Lifecycle

**What**: Tracks whether each commission has been included in a payment.

**Columns/Parameters Involved**: `Paid`, `PaymentID`

**Rules**:
- `Paid = 0, PaymentID = 0`: Unpaid commission - not yet included in any payment batch
- `Paid = 1, PaymentID > 0`: Commission included in payment batch identified by PaymentID (references tblaff_PaymentHistory)
- Payment views (qry_aff_Tier*BonusesCommissions) aggregate unpaid commissions for payment generation

---

## 3. Data Overview

| ID | BonusID | AffiliateID | Commission | Tier | Paid | PaymentID | SubAffiliateID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 578102 | 413341 | 23399 | 0 | 1 | false | 0 | (empty) | Tier 1 commission for bonus 413341 - zero commission (bonus may not qualify for commission at this tier). Unpaid. |
| 578101 | 413340 | 25202 | -2 | 2 | false | 0 | (empty) | Tier 2 negative commission (clawback/reversal of $2) for parent affiliate 25202. Unpaid. |
| 578100 | 413340 | 40376 | 0 | 1 | false | 0 | (empty) | Tier 1 for same bonus 413340 - zero commission at direct level. Affiliate 40376 is the direct referrer. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | BonusID | int | YES | 0 | VERIFIED | References the source bonus event in tblaff_Bonuses.BonusID. Multiple rows can share the same BonusID (one per tier). |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this commission. Maps to tblaff_Affiliates.AffiliateID. For Tier 1: the direct referrer. For Tier 2+: parent affiliates from the tier hierarchy. |
| 4 | Commission | float | YES | 0 | VERIFIED | Commission amount for this tier. Positive = earned commission. Zero = no commission at this tier. Negative = reversal/clawback. |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1 = direct affiliate, 2 = parent of direct, 3-5 = higher tier parents. Determines which affiliate in the hierarchy receives this commission. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid (available for next payment batch), 1 = included in a completed payment. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when Paid=1. Value 0 = not yet paid. Links this commission to its payment batch for reconciliation. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. Can be updated by UpdateSubAffiliateID for late-binding mobile attribution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BonusID | dbo.tblaff_Bonuses | Implicit | The source bonus event that generated this commission |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate receiving this commission |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | The payment batch (when paid) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Updates SubAffiliateID/AffiliateID for late-binding |
| dbo.qry_aff_Tier1BonusesCommissions | FROM | View (READER) | Aggregates Tier 1 bonus commissions |
| dbo.qry_aff_BonusesDetailAllTiers | FROM | View (READER) | Aggregates all-tier bonus commission details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.UpdateSubAffiliateID | Stored Procedure | MODIFIER - late-binding attribution |
| dbo.qry_aff_Tier1BonusesCommissions | View | Aggregates Tier 1 commissions |
| dbo.qry_aff_BonusesDetailAllTiers | View | All-tier commission details |
| dbo.GetUnpaidCommissions | Stored Procedure | READER - retrieves unpaid commission totals |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Bonuses_Commissions_PK | NC PK | ID ASC | - | - | Active (PAGE compression) |
| CLU_IDX_tblaff_Bonuses_Commissions_AffiliateID | CLUSTERED | AffiliateID ASC | - | - | Active (fill 70%, PAGE compression) |
| IDX_BONUS_COMM_PAID | NC | Paid ASC | BonusID, AffiliateID, Commission, Tier | - | Active (PAGE compression) |
| IDX_tblaff_Bonuses_Commissions_AffTier | NC | AffiliateID, Tier | BonusID | - | Active (PAGE compression) |
| IDX_tblaff_Bonuses_Commissions_Tier | NC | Tier ASC | BonusID, AffiliateID, Commission | - | Active (PAGE compression) |
| IX_BonusID_Tier_Incl_AffiliateID | NC | BonusID, Tier | AffiliateID | - | Active (PAGE compression) |
| IX_tblaff_Bonuses_Commissions_Incl1 | NC | AffiliateID | BonusID, Commission, Paid | - | Active (PAGE compression) |
| IX_tblaff_Bonuses_Commissions_Incl2 | NC | AffiliateID, Paid | ID, BonusID | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Bonuses_Commissions_Paid | DEFAULT | 0 - Unpaid by default |
| DF_tblaff_Bonuses_Commissions_PaymentID | DEFAULT | 0 - No payment assigned |

---

## 8. Sample Queries

### 8.1 Unpaid bonus commissions for an affiliate
```sql
SELECT BonusID, Commission, Tier, SubAffiliateID
FROM dbo.tblaff_Bonuses_Commissions WITH (NOLOCK)
WHERE AffiliateID = @AffiliateID AND Paid = 0
ORDER BY Tier, BonusID
```

### 8.2 Total unpaid commission by tier
```sql
SELECT Tier, COUNT(*) AS Records, SUM(Commission) AS TotalUnpaid
FROM dbo.tblaff_Bonuses_Commissions WITH (NOLOCK)
WHERE Paid = 0
GROUP BY Tier
ORDER BY Tier
```

### 8.3 Commission with bonus and affiliate details
```sql
SELECT bc.ID, bc.BonusID, bc.Commission, bc.Tier, bc.Paid,
       a.Contact AS AffiliateName, b.Optional3 AS CustomerCID
FROM dbo.tblaff_Bonuses_Commissions bc WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON bc.AffiliateID = a.AffiliateID
JOIN dbo.tblaff_Bonuses b WITH (NOLOCK) ON bc.BonusID = b.BonusID
WHERE bc.AffiliateID = @AffiliateID
ORDER BY bc.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Bonuses_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Bonuses_Commissions.sql*
