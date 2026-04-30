# dbo.tblaff_Leads_Commissions

> Stores tier-based affiliate commission records from lead generation events, with trigger-enforced RI and an additional eCost field for effective cost tracking.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 5 active |

---

## 1. Business Meaning

dbo.tblaff_Leads_Commissions records affiliate commissions earned from lead generation events (tblaff_Leads). A lead typically represents a customer who has shown interest (e.g., started registration) but has not yet completed a qualifying action. Affiliates earn per-lead commissions based on their agreement type.

Contains ~427K records. Triggers enforce that LeadID references a valid lead and AffiliateID references a valid affiliate. Includes an `eCost` field (shared with Registrations and eCost commission tables) for tracking the effective cost of customer acquisition alongside the commission.

---

## 2. Business Logic

### 2.1 Multi-Tier Lead Commission

**Columns/Parameters Involved**: `LeadID`, `AffiliateID`, `Commission`, `Tier`, `eCost`

**Rules**:
- LeadID references tblaff_Leads. Trigger enforces RI.
- Standard multi-tier: Tier 1 = direct, 2-5 = parents
- `eCost` captures the platform's effective cost for this lead (separate from the affiliate commission). This enables ROI calculations.

### 2.2 Payment Lifecycle

- Same pattern: Paid=0/PaymentID=0 = unpaid, Paid=1/PaymentID>0 = paid

---

## 3. Data Overview

Table contains 426,702 rows of lead commission records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | LeadID | int | YES | 0 | VERIFIED | References tblaff_Leads.LeadID. Trigger enforces RI. |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this commission. Trigger enforces RI against tblaff_Affiliates. |
| 4 | Commission | float | YES | 0 | VERIFIED | Lead commission amount for this tier. |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1-5. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid, 1 = paid. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when paid. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. Updatable by UpdateSubAffiliateID. |
| 9 | eCost | float | YES | - | CODE-BACKED | Effective cost to the platform for this lead event. Enables ROI calculation: Commission/eCost. NULL when eCost tracking is not configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LeadID | dbo.tblaff_Leads | Implicit (trigger) | The lead event that generated this commission |
| AffiliateID | dbo.tblaff_Affiliates | Implicit (trigger) | The affiliate receiving commission |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | Payment batch when paid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding attribution |
| dbo.qry_aff_LeadDetailAllTiers | FROM | View (READER) | All-tier lead commission details |
| dbo.DailySummaryReport | JOIN | View (READER) | Daily lead count aggregation |

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
| dbo.qry_aff_Tier1LeadsCommissions through Tier5 | Views | Per-tier aggregation |
| dbo.DailySummaryReport | View | Lead count for daily summary |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_Leads_Commissions_PK | NC PK | ID ASC | - | - | Active (PAGE) |
| LeadCommissions_Clustered | CLUSTERED | ID, Tier, AffiliateID, LeadID, Commission, Paid, PaymentID | - | - | Active (PAGE) |
| AffiliateID | NC | AffiliateID | - | - | Active (PAGE) |
| LeadID | NC | LeadID | - | - | Active (PAGE) |
| Tier | NC | Tier | - | - | Active (PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Leads_Commissions_Paid | DEFAULT | 0 |
| DF_tblaff_Leads_Commissions_PaymentID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Unpaid lead commissions per affiliate
```sql
SELECT AffiliateID, Tier, COUNT(*) AS Records, SUM(Commission) AS TotalUnpaid
FROM dbo.tblaff_Leads_Commissions WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID, Tier ORDER BY TotalUnpaid DESC
```

### 8.2 Lead commission with eCost ROI
```sql
SELECT AffiliateID, SUM(Commission) AS TotalCommission,
       SUM(eCost) AS TotaleCost,
       CASE WHEN SUM(eCost) > 0 THEN SUM(Commission) / SUM(eCost) ELSE NULL END AS ROI
FROM dbo.tblaff_Leads_Commissions WITH (NOLOCK)
WHERE eCost IS NOT NULL AND eCost > 0
GROUP BY AffiliateID ORDER BY ROI DESC
```

### 8.3 Leads with commission and event details
```sql
SELECT lc.Commission, lc.Tier, l.Optional3 AS CustomerCID
FROM dbo.tblaff_Leads_Commissions lc WITH (NOLOCK)
JOIN dbo.tblaff_Leads l WITH (NOLOCK) ON lc.LeadID = l.LeadID
WHERE lc.AffiliateID = @AffiliateID AND lc.Paid = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Leads_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Leads_Commissions.sql*
