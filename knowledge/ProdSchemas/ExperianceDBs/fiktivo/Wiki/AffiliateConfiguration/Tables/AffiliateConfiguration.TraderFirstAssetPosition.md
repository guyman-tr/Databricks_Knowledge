# AffiliateConfiguration.TraderFirstAssetPosition

> Tracks each customer's first trading position asset class and accumulated revenue, used to determine when CPA commission thresholds from FirstPositionAssetPlan are met and the affiliate can be paid.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | Table |
| **Key Identifier** | CID + PartitionCol (composite PK CLUSTERED) |
| **Partition** | Yes - PS_Mod50 on PartitionCol (CID % 50) |
| **Indexes** | 2 active (1 clustered PK, 1 NC on DateUpdated) |

---

## 1. Business Meaning

AffiliateConfiguration.TraderFirstAssetPosition is the runtime tracking table for the CPA first-position commission model. While [AffiliateConfiguration.FirstPositionAssetPlan](AffiliateConfiguration.FirstPositionAssetPlan.md) defines the CPA commission rates (what the affiliate SHOULD earn), this table records what actually happened - which asset class a customer's first trading position was in, how much revenue they have generated, and whether they have met the minimum commission threshold.

Without this table, the platform could not track per-customer progress toward CPA thresholds. Many CPA plans require the referred customer to generate a minimum amount of trading revenue before the affiliate's commission is paid. This table accumulates that revenue and exposes a computed RevenuesPercentage column that shows exactly how close the customer is to meeting the threshold (0-100%).

Rows are created by [AffiliateCommission.SetTraderFirstAssetPosition](../../AffiliateCommission/Stored Procedures/AffiliateCommission.SetTraderFirstAssetPosition.md) when a customer opens their first position. The insert uses an anti-join pattern to guarantee only one row per customer. Revenue is updated by [AffiliateCommission.SetCustomerFinanceDetailsState](../../AffiliateCommission/Stored Procedures/AffiliateCommission.SetCustomerFinanceDetailsState.md) as the customer generates trading activity. The commission pipeline reads this table via [AffiliateCommission.GetCreditTriggeredEvents](../../AffiliateCommission/Stored Procedures/AffiliateCommission.GetCreditTriggeredEvents.md) to determine eligibility. Note: airdrop events are ignored - if a customer's first position is an airdrop, the system waits for the second (real) open position. Created as part of the CPA New Compensation Design (PART-2448, Dec 2023).

---

## 2. Business Logic

### 2.1 Revenue Percentage Threshold Tracking

**What**: A computed column calculates the customer's progress toward the CPA minimum commission threshold, enabling real-time eligibility checks.

**Columns/Parameters Involved**: `TotalRevenue`, `MinimumCommission`, `RevenuesPercentage` (computed)

**Rules**:
- RevenuesPercentage formula:
  - If MinimumCommission = 0 -> 100 (no threshold, immediately eligible)
  - If MinimumCommission IS NULL -> NULL (threshold not yet set)
  - If MinimumCommission < TotalRevenue -> 100 (threshold exceeded, capped at 100)
  - Otherwise -> (TotalRevenue / MinimumCommission) * 100, rounded to 2 decimals
- When RevenuesPercentage reaches 100%, the CPA commission is eligible for payout
- In practice, 98.6% of rows have no threshold (MinimumCommission=0 or NULL), meaning CPA is paid immediately
- Only ~1.4% of customers (478 out of 33,523) have an active threshold to work toward

**Diagram**:
```
Customer opens first position
  |
  v
SetTraderFirstAssetPosition (INSERT)
  -> CID, FirstPositionAssetTypeID, DateAdded
  |
  v
Customer generates trading revenue
  |
  v
SetCustomerFinanceDetailsState (UPDATE)
  -> TotalRevenue, MinimumCommission, DateUpdated
  |
  v
RevenuesPercentage (computed, real-time)
  = (TotalRevenue / MinimumCommission) * 100
  |
  +--> < 100%: CPA deferred, keep accumulating
  +--> >= 100%: CPA eligible for payout
```

### 2.2 One Row Per Customer Guarantee

**What**: The insert logic guarantees exactly one row per customer using an anti-join pattern.

**Columns/Parameters Involved**: `CID`, `PartitionCol`

**Rules**:
- SetTraderFirstAssetPosition uses a RIGHT JOIN anti-pattern: it joins the table to the new data on CID and PartitionCol, then inserts only WHERE T.CID IS NULL (no existing row)
- This means the FIRST position recorded wins - subsequent first positions for the same CID are ignored
- The procedure returns a RowAdded flag (1=new row, 0=already existed) so the caller knows if this was actually the first event
- CID is unique across all 33,523 rows (1:1 relationship, verified from live data)

### 2.3 Asset Type Distribution

**What**: The FirstPositionAssetTypeID captures which asset class the customer's first position was in, driving category-specific CPA rates.

**Columns/Parameters Involved**: `FirstPositionAssetTypeID`

**Rules**:
- Crypto (ID=10) dominates at 61% of all first positions
- CFD (ID=3) is second at 34%
- Stocks (ID=5) at 3%, Copy (ID=11) at 2%
- The asset type is matched against FirstPositionAssetPlan to determine the CPA amount
- ID=0 (All) appears in 15 rows - likely from legacy migration or wildcard matching

---

## 3. Data Overview

| CID | AssetType | TotalRevenue | MinCommission | RevPct | DateAdded | Meaning |
|---|---|---|---|---|---|---|
| 25182541 | 10 (Crypto) | 49 | 50 | 98% | 2026-02-17 | Customer's first position was Crypto. Has generated $49 of $50 minimum threshold - 98% complete, CPA not yet eligible |
| 25185010 | 3 (CFD) | 30 | 0 | 100% | 2026-02-17 | First position was CFD. No minimum threshold (MinimumCommission=0) so RevenuesPercentage is immediately 100% - CPA eligible |
| 25184967 | 10 (Crypto) | 10 | 10 | 100% | 2026-02-17 | First position was Crypto. Generated $10 against $10 threshold - exactly met, CPA eligible |
| 24184836 | 10 (Crypto) | 49 | 50 | 98% | 2025-11-17 | Long-standing customer approaching but not yet meeting the $50 threshold. Still being updated (DateUpdated today) |
| 24370485 | 10 (Crypto) | 49 | 50 | 98% | 2025-12-04 | Similar pattern - $49 of $50 threshold. Multiple customers cluster near but below threshold, suggesting deliberate threshold calibration |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | VERIFIED | Customer identifier. Part of composite PK. References the customer who opened a first trading position. One row per CID (guaranteed by anti-join insert logic in SetTraderFirstAssetPosition). Used with PartitionCol for partition-aligned lookups: `WHERE CID = @CID AND PartitionCol = @CID % 50`. |
| 2 | PartitionCol | computed (persisted) | NO | - | CODE-BACKED | Computed: `CID % 50`. PERSISTED. Part of composite PK. Partition alignment column for the PS_Mod50 scheme, distributing rows across 50 physical partitions. Always included in WHERE clauses alongside CID to enable partition elimination. Never set by application code - derived automatically from CID. |
| 3 | FirstPositionAssetTypeID | int | NO | - | VERIFIED | Asset class of the customer's first trading position. Implicit FK to [Dictionary.PositionAssetType](../../Dictionary/Tables/Dictionary.PositionAssetType.md): 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See [Position Asset Type](../../_glossary.md#position-asset-type). Crypto (10) dominates at 61%, CFD (3) at 34%. Set once on INSERT and never updated. Matched against FirstPositionAssetPlan.PositionAssetTypeID to determine CPA amount. |
| 4 | TotalRevenue | float | YES | - | CODE-BACKED | Cumulative trading revenue generated by this customer since their first position. Updated by SetCustomerFinanceDetailsState as new revenue is reported. NULL = no revenue reported yet. Used in RevenuesPercentage calculation to determine CPA threshold progress. |
| 5 | MinimumCommission | float | YES | - | CODE-BACKED | CPA revenue threshold this customer must reach before the affiliate's commission is paid. Copied from the applicable FirstPositionAssetPlan entry. NULL = threshold not yet determined. 0 = no threshold required (immediate CPA payout). Updated by SetCustomerFinanceDetailsState alongside TotalRevenue. 98.6% of rows have 0 or NULL (no threshold). |
| 6 | DateAdded | datetime | NO | - | CODE-BACKED | Timestamp when the customer opened their first position and this row was created (UTC). Set by the @DateAdded parameter in SetTraderFirstAssetPosition - represents the actual position open time, not the insert time. Used in GetCreditTriggeredEvents for commission eligibility timing calculations. Never updated after insert. |
| 7 | RevenuesPercentage | computed | - | - | CODE-BACKED | Computed (not persisted): progress toward CPA minimum commission threshold, rounded to 2 decimals. Formula: CASE WHEN MinimumCommission=0 THEN 100 WHEN MinimumCommission IS NULL THEN NULL WHEN MinimumCommission < TotalRevenue THEN 100 ELSE (TotalRevenue/MinimumCommission)*100 END. Returns 100 when threshold is met or no threshold exists. Used by reporting (PortalReportSummaryByAffiliate) to show conversion progress. |
| 8 | DateUpdated | datetime | NO | GETUTCDATE() | CODE-BACKED | Timestamp of the last revenue update (UTC). Default: GETUTCDATE(). Set to GETUTCDATE() on every SetCustomerFinanceDetailsState call. Used as the only column in IX_TraderFirstAssetPosition_DateUpdated index, likely for batch processing queries that find recently-updated customers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FirstPositionAssetTypeID | Dictionary.PositionAssetType | Implicit FK | Asset class classification of the customer's first position |
| CID | (external customer) | Business Reference | Customer identifier from the core customer system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateConfiguration.FirstPositionAssetPlan | Conceptual | Business Link | Defines the CPA rates that this table tracks progress toward |
| AffiliateCommission.SetTraderFirstAssetPosition | Direct INSERT | WRITER | Creates rows when customer opens first position |
| AffiliateCommission.SetCustomerFinanceDetailsState | Direct UPDATE | MODIFIER | Updates TotalRevenue, MinimumCommission, DateUpdated |
| AffiliateCommission.GetTraderFirstAssetPosition | Direct SELECT | READER | Returns first position data for a customer |
| AffiliateCommission.GetCreditTriggeredEvents | LEFT JOIN | READER | Checks existence and DateAdded for commission eligibility |
| AffiliateReport.PortalReportSummaryByAffiliate | LEFT JOIN | READER | Includes first position data and asset type in affiliate reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. Tables are always leaf nodes.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.SetTraderFirstAssetPosition | Stored Procedure | WRITER - creates first position records |
| AffiliateCommission.SetCustomerFinanceDetailsState | Stored Procedure | MODIFIER - updates revenue tracking |
| AffiliateCommission.GetTraderFirstAssetPosition | Stored Procedure | READER - retrieves first position data |
| AffiliateCommission.GetCreditTriggeredEvents | Stored Procedure | READER - commission eligibility check |
| AffiliateReport.PortalReportSummaryByAffiliate | Stored Procedure | READER - affiliate portal reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TraderFirstAssetPosition_CID | CLUSTERED | CID ASC, PartitionCol ASC | - | - | Active |
| IX_TraderFirstAssetPosition_DateUpdated | NONCLUSTERED | DateUpdated ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TraderFirstAssetPosition_CID | PRIMARY KEY | Composite clustered PK on CID + PartitionCol. One row per customer, partition-aligned |
| DF_TraderFirstAssetPosition_DateUpdated | DEFAULT | GETUTCDATE() for DateUpdated. Automatically timestamps on insert |
| PS_Mod50 | PARTITION SCHEME | Table and both indexes partitioned on PartitionCol (CID % 50), distributing data across 50 physical partitions for parallel query performance |

---

## 8. Sample Queries

### 8.1 Check a customer's CPA threshold progress with asset type name

```sql
SELECT t.CID, t.FirstPositionAssetTypeID, pat.Name AS AssetType,
       t.TotalRevenue, t.MinimumCommission, t.RevenuesPercentage,
       t.DateAdded, t.DateUpdated
FROM AffiliateConfiguration.TraderFirstAssetPosition t WITH (NOLOCK)
INNER JOIN Dictionary.PositionAssetType pat WITH (NOLOCK) ON t.FirstPositionAssetTypeID = pat.ID
WHERE t.CID = 25182541 AND t.PartitionCol = 25182541 % 50;
```

### 8.2 Find customers approaching but not yet meeting CPA threshold

```sql
SELECT t.CID, pat.Name AS AssetType, t.TotalRevenue, t.MinimumCommission,
       t.RevenuesPercentage, t.DateAdded
FROM AffiliateConfiguration.TraderFirstAssetPosition t WITH (NOLOCK)
INNER JOIN Dictionary.PositionAssetType pat WITH (NOLOCK) ON t.FirstPositionAssetTypeID = pat.ID
WHERE t.MinimumCommission > 0
  AND t.RevenuesPercentage < 100
  AND t.RevenuesPercentage >= 80
ORDER BY t.RevenuesPercentage DESC;
```

### 8.3 Asset type distribution of first positions

```sql
SELECT t.FirstPositionAssetTypeID, pat.Name, COUNT(*) AS CustomerCount,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,1)) AS Pct
FROM AffiliateConfiguration.TraderFirstAssetPosition t WITH (NOLOCK)
INNER JOIN Dictionary.PositionAssetType pat WITH (NOLOCK) ON t.FirstPositionAssetTypeID = pat.ID
GROUP BY t.FirstPositionAssetTypeID, pat.Name
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CPA New Compensation Plan - DB design](https://etoro-jira.atlassian.net/wiki/x/PLACEHOLDER) | Confluence | TraderFirstAssetPosition created alongside FirstPositionAssetPlan and Dictionary.PositionAssetType as part of CPA New Compensation Design. Key rule: airdrop events are ignored - the second real open position is recorded instead. Asset class mapping from incoming events to PositionAssetType categories documented. |

PART-2448 (Jira): CPA New Compensation Design - original creation ticket (Dec 2023).
PART-3174 (Jira): Updated SetTraderFirstAssetPosition to only insert records that don't already exist (Jun 2024).

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.TraderFirstAssetPosition | Type: Table | Source: fiktivo/AffiliateConfiguration/Tables/AffiliateConfiguration.TraderFirstAssetPosition.sql*
