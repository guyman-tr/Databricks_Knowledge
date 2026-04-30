# AffiliateCommission.ClosedPositionCommission

> Child table of ClosedPosition storing the actual commission amounts earned by each affiliate at each tier for a closed trading position.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID + Tier (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (PK clustered + 2 NC) |

---

## 1. Business Meaning

ClosedPositionCommission stores the commission breakdown for each closed position - how much each affiliate earned at each tier level. While ClosedPosition holds the position's financial details (Amount, NetProfit, LotCount), this table holds the per-affiliate, per-tier commission amounts that result from applying the commission rules to those financial details.

This table exists because a single closed position can generate commissions for multiple affiliates in a multi-tier referral chain. The composite PK (ClosedPositionID + Tier) ensures one commission record per tier per position. The data is populated atomically with ClosedPosition by InsertClosedPosition and can be replaced by SaveClosedPositionCommission (which deletes and re-inserts within a transaction).

The table has 246,571 rows closely matching ClosedPosition's 246,449 rows, indicating nearly 1:1 ratio (mostly single-tier commissions). It is also the source table for ClosedPositionDailySummary aggregation.

---

## 2. Business Logic

### 2.1 Multi-Tier Commission Storage

**What**: Each row represents one affiliate's commission for one position at one tier.

**Columns/Parameters Involved**: `ClosedPositionID`, `AffiliateID`, `Tier`, `Commission`, `Paid`, `PaymentID`

**Rules**:
- Tier 1 = direct referrer affiliate, Tier 2+ = upstream affiliates
- Commission amount is calculated by the commission engine and passed via PositionCommissionType TVP
- Paid starts as 0 (unpaid), set to 1 when included in an affiliate payment batch
- PaymentID is 0 when unpaid, set to the payment batch ID when paid
- SaveClosedPositionCommission does DELETE + INSERT (full replace) within a transaction
- AggregateClosedPositionDailyData reads this table for daily summary aggregation

---

## 3. Data Overview

| ClosedPositionID | AffiliateID | Commission | Tier | Paid | PaymentID | Meaning |
|---|---|---|---|---|---|---|
| 419747 | 3 | 0 | 1 | 0 | 0 | Most recent position. Zero commission despite position having Amount=22.04 in ClosedPosition. Commission may be zero due to affiliate agreement terms. Unpaid. |
| 419746 | 3 | 0 | 1 | 0 | 0 | Zero commission, Tier 1 only. All recent commissions going to AffiliateID 3. |
| 419745 | 3 | 0 | 1 | 0 | 0 | Same pattern - single-tier, zero commission, unpaid. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Closed position this commission applies to. First column of composite PK. Implicitly references ClosedPosition.ClosedPositionID. Inserted by InsertClosedPosition and SaveClosedPositionCommission. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate earning this commission. References dbo.tblaff_Affiliates. Indexed with ClosedPositionID for affiliate-based lookups. Also indexed with Tier for commission reporting. |
| 3 | Commission | float | NO | - | CODE-BACKED | Dollar amount of commission earned. Can be 0 for positions where the affiliate agreement doesn't generate commission (e.g., certain instrument types or below-threshold positions). Aggregated into ClosedPositionDailySummary. |
| 4 | Tier | int | NO | - | CODE-BACKED | Commission tier level. 1 = direct referrer, 2+ = upstream affiliates. Second column of composite PK. Most records are Tier 1 (single-tier structure). |
| 5 | Paid | bit | NO | - | CODE-BACKED | Payment status. 0 = unpaid/pending, 1 = paid out to affiliate. Updated during payment batch processing. Retroactively fixed in ClosedPositionDailySummary via 3-month lookback. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | Payment batch identifier. 0 when unpaid. Set to the batch ID when the commission is included in an affiliate payout. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPosition | Implicit FK | Parent position record |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | Affiliate earning commission |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.ClosedPositionCommissionVW | - | View | View on commission data |
| AffiliateCommission.AggregateClosedPositionDailyData | JOIN | Reader | Source for daily aggregation |
| AffiliateCommission.InsertClosedPosition | INSERT | Writer | Creates commission rows atomically with position |
| AffiliateCommission.SaveClosedPositionCommission | DELETE+INSERT | Writer | Replaces commission rows |
| AffiliateCommission.GetClosedPositionTriggeredEvents | SELECT | Reader | Reads for event triggering |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ClosedPositionCommission (table)
└── AffiliateCommission.ClosedPosition (table) [implicit, via ClosedPositionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | Parent - ClosedPositionID references position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionCommissionVW | View | Reads commission data |
| AffiliateCommission.AggregateClosedPositionDailyData | Stored Procedure | Source for daily aggregation |
| AffiliateCommission.InsertClosedPosition | Stored Procedure | Writer |
| AffiliateCommission.SaveClosedPositionCommission | Stored Procedure | Writer (replace pattern) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPositionCommission | CLUSTERED PK | ClosedPositionID, Tier | - | - | Active (PAGE compression) |
| IX_ClosedPositionCommissionClosedPositionIDAffiliateID | NC | ClosedPositionID, AffiliateID | - | - | Active (PAGE compression) |
| IX_ClosedPositionCommission_AffiliateIDTier | NC | AffiliateID, Tier | Commission | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClosedPositionCommission | PRIMARY KEY | Composite - one commission per position per tier |

---

## 8. Sample Queries

### 8.1 Commission details for a specific position
```sql
SELECT cpc.ClosedPositionID, cpc.AffiliateID, cpc.Commission, cpc.Tier, cpc.Paid, cpc.PaymentID
FROM AffiliateCommission.ClosedPositionCommission cpc WITH (NOLOCK)
WHERE cpc.ClosedPositionID = 419747;
```

### 8.2 Total unpaid commissions by affiliate
```sql
SELECT AffiliateID, SUM(Commission) AS UnpaidCommission, COUNT(*) AS Positions
FROM AffiliateCommission.ClosedPositionCommission WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID
ORDER BY UnpaidCommission DESC;
```

### 8.3 Position with full financial context
```sql
SELECT cp.ClosedPositionID, cp.Amount, cp.HedgeCommission, cp.NetProfit,
       cpc.AffiliateID, cpc.Commission, cpc.Tier, cpc.Paid
FROM AffiliateCommission.ClosedPosition cp WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPositionCommission cpc WITH (NOLOCK)
    ON cp.ClosedPositionID = cpc.ClosedPositionID
WHERE cp.ClosedPositionID = 419747;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design context (Dec 2023) |
| [PART-1278](https://etoro-jira.atlassian.net/browse/PART-1278) | Jira | IsProcessed field added to save flow (Mar 2023) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionCommission | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionCommission.sql*
