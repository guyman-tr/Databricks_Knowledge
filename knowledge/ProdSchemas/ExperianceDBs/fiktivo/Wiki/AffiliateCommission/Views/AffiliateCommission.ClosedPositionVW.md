# AffiliateCommission.ClosedPositionVW

> View combining closed position financial data with affiliate attribution from RegistrationMetaData, providing a unified record for commission reporting that includes both position details and the referring affiliate context.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | ClosedPositionID (from ClosedPosition base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ClosedPositionVW is the primary reporting view for closed position commissions. It joins ClosedPosition (financial data: Amount, HedgeCommission, NetProfit, LotCount) with RegistrationMetaData (attribution: AffiliateID, AffiliateCampaign, BannerID, DownloadID, FunnelID, PlayerLevelID) to create a single denormalized record per position.

This view exists because ClosedPosition was deliberately designed without attribution columns (they were removed during schema simplification). Attribution lives in RegistrationMetaData. Downstream consumers (reports, commission calculations) need both in one row, and this view provides that without forcing every consumer to write the join themselves.

The view uses a UNION ALL with two SELECT blocks: the first handles standard positions (CID > 0, TrackingDate >= 2021-12-31) joined on CID, and the second handles legacy positions (CID = -1, pre-2021-12-31) joined on OriginalCID. The computed UpdateDate column uses GREATEST(CommissionDate, ValidFrom) to track when either the position or the attribution was last changed.

---

## 2. Business Logic

### 2.1 Dual Join Strategy

**What**: Two join paths handle current vs legacy position attribution.

**Columns/Parameters Involved**: `CID`, `OriginalCID`, `TrackingDate`

**Rules**:
- Path 1 (current): CID > 0 AND TrackingDate >= '2021-12-31' -> JOIN on CID with partition alignment (PartitionCol = CID % 50)
- Path 2 (legacy): CID = -1 AND TrackingDate <= '2021-12-31' AND ClosedPositionID < 0 -> JOIN on OriginalCID
- The cutover date marks when the system switched from OriginalCID-based to CID-based attribution

### 2.2 UpdateDate Computation

**What**: Tracks the most recent change to either the position or the attribution.

**Columns/Parameters Involved**: `CommissionDate`, `ValidFrom`, `UpdateDate`

**Rules**:
- UpdateDate = GREATEST(CommissionDate, ValidFrom)
- If the position was recalculated after attribution change, CommissionDate is later
- If attribution was changed after commission calculation, ValidFrom is later
- Used by CDC/incremental consumers to detect changes

---

## 3. Data Overview

N/A - view returns combined data from ClosedPosition (246K rows) and RegistrationMetaData (18.8M rows). Query the view directly for samples.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | From ClosedPosition. Unique position identifier. |
| 2 | CommissionDate | datetime | NO | - | CODE-BACKED | From ClosedPosition. When commission was calculated. |
| 3 | Amount | decimal(16,6) | NO | - | CODE-BACKED | From ClosedPosition. Gross commission-eligible amount. |
| 4 | HedgeCommission | decimal(16,6) | NO | - | CODE-BACKED | From ClosedPosition. Hedge commission component. |
| 5 | CID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Customer ID. |
| 6 | OriginalCID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Original customer in copy-trading. |
| 7 | AffiliateID | int | NO | - | CODE-BACKED | From RegistrationMetaData. Referring affiliate. |
| 8 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | From RegistrationMetaData. Campaign tracking string. |
| 9 | ProviderID | bigint | NO | - | CODE-BACKED | From ClosedPosition. Current provider. |
| 10 | OriginalProviderID | bigint | NO | - | CODE-BACKED | From ClosedPosition. Original provider. |
| 11 | AdditionalData | varchar(512) | NO | - | CODE-BACKED | From RegistrationMetaData. Extensible metadata. |
| 12 | RealProviderID | bigint | NO | - | CODE-BACKED | From ClosedPosition. Execution entity. |
| 13 | CountryID | bigint | NO | - | CODE-BACKED | From ClosedPosition. Customer country. |
| 14 | NetProfit | float | NO | - | CODE-BACKED | From ClosedPosition. Position profit/loss. |
| 15 | FunnelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. Marketing funnel. |
| 16 | LabelID | - | YES | - | CODE-BACKED | Always NULL. Column preserved for backward compatibility with legacy consumers. |
| 17 | PlayerLevelID | int | YES | - | CODE-BACKED | From RegistrationMetaData. Player level classification. |
| 18 | DownloadID | bigint | NO | - | CODE-BACKED | From RegistrationMetaData. Download tracking. |
| 19 | LotCount | decimal(16,6) | NO | - | CODE-BACKED | From ClosedPosition. Position size in lots. |
| 20 | BannerID | int | NO | - | CODE-BACKED | From RegistrationMetaData. Banner reference. |
| 21 | Valid | bit | NO | - | CODE-BACKED | From ClosedPosition. Commission eligibility. |
| 22 | TrackingDate | datetime | NO | - | CODE-BACKED | From ClosedPosition. Tracking system entry time. |
| 23 | IsProcessed | bit | YES | - | CODE-BACKED | From ClosedPosition. Processing completion flag. |
| 24 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | From RegistrationMetaData. When current attribution became effective. |
| 25 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(CommissionDate, ValidFrom). Latest change timestamp for CDC consumers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPosition | JOIN (INNER) | Position financial data |
| - | AffiliateCommission.RegistrationMetaData | JOIN (INNER) | Affiliate attribution data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ClosedPositionVW (view)
├── AffiliateCommission.ClosedPosition (table)
└── AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | INNER JOIN on CID/OriginalCID |
| AffiliateCommission.RegistrationMetaData | Table | INNER JOIN for attribution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View (not indexed/materialized).

### 7.2 Constraints

None. UNION ALL view with two SELECT blocks.

---

## 8. Sample Queries

### 8.1 Recent positions with affiliate attribution
```sql
SELECT TOP 10 ClosedPositionID, CommissionDate, Amount, CID, AffiliateID,
       AffiliateCampaign, CountryID, Valid, UpdateDate
FROM AffiliateCommission.ClosedPositionVW WITH (NOLOCK)
ORDER BY CommissionDate DESC;
```

### 8.2 Positions by affiliate
```sql
SELECT AffiliateID, COUNT(*) AS PositionCount, SUM(Amount) AS TotalAmount
FROM AffiliateCommission.ClosedPositionVW WITH (NOLOCK)
WHERE Valid = 1 AND IsProcessed = 1
GROUP BY AffiliateID ORDER BY TotalAmount DESC;
```

### 8.3 Changed records since a given date
```sql
SELECT ClosedPositionID, AffiliateID, UpdateDate
FROM AffiliateCommission.ClosedPositionVW WITH (NOLOCK)
WHERE UpdateDate >= '2026-04-01'
ORDER BY UpdateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionVW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.sql*
