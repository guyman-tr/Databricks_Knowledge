# AffiliateCommission.ClosedPosition

> Core entity table storing processed closed trading positions for affiliate commission calculation, representing the final commission-eligible state of each position after it has been closed and attributed.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (PK clustered + 3 NC on CID, CommissionDate, TrackingDate) |

---

## 1. Business Meaning

ClosedPosition is the central fact table in the affiliate commission system's closed-position domain. Each row represents a trading position that was closed and is eligible for affiliate commission calculation. It stores the financial metrics (Amount, HedgeCommission, NetProfit, LotCount) and attribution context (CID, ProviderID chain, CountryID) needed to compute what commission an affiliate earns from the position.

This table exists because affiliate commissions on trading activity are calculated after a position closes. When a customer referred by an affiliate closes a position, the system records the position here with its financial summary. The commission calculation engine then processes the position (computing commission amounts per affiliate tier) and stores results in ClosedPositionCommission. The IsProcessed flag tracks whether this pipeline has completed.

Data flows into this table via InsertClosedPosition, which atomically inserts both the ClosedPosition record and its corresponding ClosedPositionCommission records within a single transaction. The procedure includes an idempotency guard - if a ClosedPositionID already exists, it returns 0 without inserting. The table is actively used (246K rows, latest data from today), with 99.98% of records processed and valid.

---

## 2. Business Logic

### 2.1 Commission Processing Pipeline

**What**: Each closed position goes through a processing pipeline from raw event to commission payout.

**Columns/Parameters Involved**: `IsProcessed`, `Valid`, `CommissionDate`, `TrackingDate`

**Rules**:
- InsertClosedPosition creates the record with IsProcessed = 0 (default) or the caller's value
- SaveClosedPositionCommission sets IsProcessed = 1 and updates CommissionDate when commissions are calculated
- UpdateClosedPositionTracking also sets IsProcessed = 1 as an alternative processing completion marker
- Valid indicates whether the position is eligible for commission (can be set to 0 for disqualified positions)
- TrackingDate is the time the position was first tracked by the commission system (may differ from CommissionDate)

**Diagram**:
```
ClosedPositionFromEtoro (staging)
       |
       v
InsertClosedPosition (atomic insert)
       |
       +-> ClosedPosition (IsProcessed=0, Valid=1)
       +-> ClosedPositionCommission (commission rows)
       |
       v
SaveClosedPositionCommission (updates)
       |
       +-> ClosedPosition (IsProcessed=1, CommissionDate updated)
       +-> ClosedPositionCommission (rows replaced)
```

### 2.2 Provider Chain Attribution

**What**: Three provider IDs track the complete chain of position ownership for multi-entity brokerages.

**Columns/Parameters Involved**: `ProviderID`, `OriginalProviderID`, `RealProviderID`

**Rules**:
- ProviderID: The provider currently responsible for the position
- OriginalProviderID: The provider that originally opened the position (0 = same as ProviderID)
- RealProviderID: The actual entity that executes the trade (relevant for white-label arrangements)
- This chain allows commission rules to vary based on which entity in the brokerage structure originated or executed the trade

### 2.3 Customer Attribution Chain

**What**: CID and OriginalCID track customer ownership for copy-trading and sub-account scenarios.

**Columns/Parameters Involved**: `CID`, `OriginalCID`

**Rules**:
- CID: The customer who holds the position
- OriginalCID: The original customer in copy-trading scenarios (NULL when position was opened independently, not copied)
- Commission attribution may follow the OriginalCID chain to credit the affiliate who referred the original trader

---

## 3. Data Overview

| ClosedPositionID | CommissionDate | Amount | CID | CountryID | NetProfit | Valid | IsProcessed | Meaning |
|---|---|---|---|---|---|---|---|---|
| 419747 | 2026-04-12 13:40 | 22.04 | 3635312 | 54 | -0.14 | 1 | 1 | Active position with significant commission amount (22.04) and small net loss. Country 54. Fully processed. |
| 419746 | 2026-04-12 12:00 | 0 | 25706992 | 219 | 0 | 1 | 1 | Position with zero commission and zero profit - likely a break-even or ineligible position type. Still marked valid and processed. |
| 419745 | 2026-04-12 09:10 | 0 | 25706607 | 196 | 0 | 1 | 1 | Small position (0.19 lots) with zero amounts. Country 196. Pattern of zero-commission positions common for certain position types or affiliate agreements. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Unique identifier of the closed position. Matches the position ID from the trading system (ClosedPositionFromEtoro). PK with idempotency guard in InsertClosedPosition - duplicate inserts are silently ignored. |
| 2 | CommissionDate | datetime | NO | - | CODE-BACKED | Timestamp when the commission was calculated or last updated. Set initially during InsertClosedPosition and updated by SaveClosedPositionCommission when commissions are recalculated. Used for commission reporting periods. |
| 3 | Amount | decimal(16,6) | NO | - | CODE-BACKED | Gross commission amount for the position in USD. Represents the base commission before hedge adjustments. Can be 0 for positions that are valid but generate no commission (e.g., certain affiliate agreement types). |
| 4 | HedgeCommission | decimal(16,6) | NO | - | CODE-BACKED | Additional commission component from hedging activity on this position. Typically a fraction of the main Amount. Combined with Amount for total commission calculation. |
| 5 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the trader who held the position. References the customer in the external customer system. Indexed alongside OriginalCID for attribution lookups. |
| 6 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer ID in copy-trading scenarios. When a position is copied from another trader, this holds the CID of the original trader. NULL for independently opened positions. Used in commission attribution to follow the referral chain. |
| 7 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider/entity responsible for the position. In multi-entity brokerage setups, identifies which regulated entity processes the position. Commonly 1 for the primary entity. |
| 8 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Provider that originally opened the position. 0 indicates the position was opened directly (not transferred between providers). Used to track provider migrations and white-label attribution. |
| 9 | RealProviderID | bigint | NO | - | CODE-BACKED | Actual execution entity for the trade. In white-label arrangements, this identifies the real broker executing the trade while ProviderID represents the customer-facing entity. |
| 10 | CountryID | bigint | NO | - | CODE-BACKED | Country identifier for the customer's registration country. Used in commission rules that vary by geography (e.g., regulatory region-specific commission rates). |
| 11 | NetProfit | float | NO | - | CODE-BACKED | Net profit/loss of the position in USD. Negative values indicate a losing position. Used in commission calculations where commission may depend on position profitability. |
| 12 | LotCount | decimal(16,6) | NO | - | CODE-BACKED | Size of the position in lots. Represents the traded volume, which may influence commission calculations for volume-based affiliate agreements. |
| 13 | Valid | bit | NO | - | CODE-BACKED | Whether this position is eligible for commission payout. 1 = valid/eligible, 0 = disqualified. Positions may be invalidated if the underlying trade was reversed, the customer was flagged for fraud, or the affiliate violated terms. 99.98% of positions are valid. |
| 14 | TrackingDate | datetime | NO | - | CODE-BACKED | Timestamp when the position first entered the affiliate commission tracking system. May precede CommissionDate if the position was tracked before commissions were calculated. Indexed for time-based queries on tracking pipeline performance. |
| 15 | IsProcessed | bit | YES | 0 | CODE-BACKED | Processing completion flag. 0 = pending commission calculation, 1 = commission has been calculated and saved. Set to 1 by SaveClosedPositionCommission and UpdateClosedPositionTracking. Has a CHECK constraint enforcing NOT NULL (non-nullable via constraint despite DDL allowing NULL). 99.98% processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPositionFromEtoro | Implicit | Source of the position data from the trading platform staging table |
| CID | External customer system | Implicit | Identifies the customer who traded |
| CountryID | External country reference | Implicit | Geographic attribution for commission rules |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.ClosedPositionCommission | ClosedPositionID | Implicit FK | Commission records per tier for this position |
| AffiliateCommission.ClosedPositionIDSalesID | ClosedPositionID | Implicit FK | Maps position to sales tracking ID |
| AffiliateCommission.ClosedPositionEvent | ClosedPositionID | Implicit FK | Event records for this position |
| AffiliateCommission.ClosedPositionVW | - | View | View built on this table |
| AffiliateCommission.ClosedPositionBI_VW | - | View | BI reporting view |
| AffiliateCommission.InsertClosedPosition | INSERT | Writer | Creates position and commission records atomically |
| AffiliateCommission.SaveClosedPositionCommission | UPDATE | Modifier | Updates CommissionDate and IsProcessed |
| AffiliateCommission.UpdateClosedPositionTracking | UPDATE | Modifier | Sets IsProcessed = 1 |
| AffiliateCommission.UpdateClosedPositionTrackingAffiliate | UPDATE | Modifier | Updates tracking for affiliate |
| AffiliateCommission.UpdateClosedPositionTrackingEligibility | UPDATE | Modifier | Updates tracking eligibility |
| AffiliateCommission.ResetClosedPositionTrackingEligibility | UPDATE | Modifier | Resets eligibility |
| AffiliateCommission.UpdateEvents | - | Reader/Modifier | Event processing |
| AffiliateCommission.UpdateFromAppsflyer | - | Modifier | AppsFlyer attribution updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionCommission | Table | Child records (commission per tier) keyed by ClosedPositionID |
| AffiliateCommission.ClosedPositionEvent | Table | Event tracking keyed by ClosedPositionID |
| AffiliateCommission.ClosedPositionIDSalesID | Table | Sales mapping keyed by ClosedPositionID |
| AffiliateCommission.ClosedPositionVW | View | Reads position data |
| AffiliateCommission.ClosedPositionBI_VW | View | BI reporting on positions |
| AffiliateCommission.InsertClosedPosition | Stored Procedure | Writer - creates records |
| AffiliateCommission.SaveClosedPositionCommission | Stored Procedure | Modifier - updates processing state |
| AffiliateCommission.UpdateClosedPositionTracking | Stored Procedure | Modifier - marks as processed |
| AffiliateCommission.UpdateClosedPositionTrackingAffiliate | Stored Procedure | Modifier - affiliate tracking |
| AffiliateCommission.UpdateClosedPositionTrackingEligibility | Stored Procedure | Modifier - eligibility tracking |
| AffiliateCommission.ResetClosedPositionTrackingEligibility | Stored Procedure | Modifier - resets eligibility |
| AffiliateCommission.RemoveClosedPositionEvent | Stored Procedure | Related event cleanup |
| AffiliateCommission.RemoveClosedPositionExpiredEvents | Stored Procedure | Expired event cleanup |
| AffiliateCommission.GetClosedPositionTriggeredEvents | Stored Procedure | Reader - triggered events |
| AffiliateCommission.UpdateClosedPositionEventLastCheckDate | Stored Procedure | Modifier - event check dates |
| AffiliateCommission.UpdateEvents | Stored Procedure | Event processing |
| AffiliateCommission.UpdateFromAppsflyer | Stored Procedure | AppsFlyer attribution updates |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPosition | CLUSTERED PK | ClosedPositionID ASC | - | - | Active |
| IX_ClosedPosition_CID_OriginalCID | NONCLUSTERED | CID, OriginalCID | - | - | Active |
| IX_ClosedPosition_CommissionDate | NONCLUSTERED | CommissionDate ASC | - | - | Active |
| IX_ClosedPosition_TrackingDate | NONCLUSTERED | TrackingDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClosedPosition | PRIMARY KEY | Clustered on ClosedPositionID - ensures uniqueness |
| DF_ClosedPosition_IsProcessed | DEFAULT | (0) for IsProcessed - new positions start as unprocessed |
| CK_ClosedPosition_IsProcessed_not_null | CHECK | IsProcessed IS NOT NULL - enforces NOT NULL despite column DDL allowing NULL (WITH NOCHECK migration pattern) |

Data compression: PAGE on PK index.

---

## 8. Sample Queries

### 8.1 Find unprocessed positions
```sql
SELECT ClosedPositionID, CommissionDate, Amount, CID, TrackingDate
FROM AffiliateCommission.ClosedPosition WITH (NOLOCK)
WHERE IsProcessed = 0
ORDER BY TrackingDate;
```

### 8.2 Position summary with commission details
```sql
SELECT cp.ClosedPositionID, cp.CommissionDate, cp.Amount, cp.HedgeCommission,
       cp.NetProfit, cp.LotCount, cp.CountryID,
       cpc.AffiliateID, cpc.Commission, cpc.Tier
FROM AffiliateCommission.ClosedPosition cp WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPositionCommission cpc WITH (NOLOCK)
    ON cp.ClosedPositionID = cpc.ClosedPositionID
WHERE cp.ClosedPositionID = 419747;
```

### 8.3 Daily commission totals by country
```sql
SELECT CAST(CommissionDate AS DATE) AS CommissionDay,
       CountryID,
       COUNT(*) AS PositionCount,
       SUM(Amount) AS TotalAmount,
       SUM(HedgeCommission) AS TotalHedge
FROM AffiliateCommission.ClosedPosition WITH (NOLOCK)
WHERE Valid = 1 AND IsProcessed = 1
  AND CommissionDate >= DATEADD(day, -7, GETUTCDATE())
GROUP BY CAST(CommissionDate AS DATE), CountryID
ORDER BY CommissionDay DESC, TotalAmount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design + CountryID restored to InsertClosedPosition (Dec 2023) |
| [PART-1278](https://etoro-jira.atlassian.net/browse/PART-1278) | Jira | Added IsProcessed field update to processing pipeline (Mar 2023) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPosition | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPosition.sql*
