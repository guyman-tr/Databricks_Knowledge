# AffiliateCommission.ClosedPositionBI_VW

> BI-optimized view of closed positions with affiliate attribution, combining ClosedPosition financial data with RegistrationMetaData attribution context. Simplified variant of ClosedPositionVW without legacy position handling.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | View |
| **Key Identifier** | ClosedPositionID (from ClosedPosition) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ClosedPositionBI_VW is a Business Intelligence-focused view that combines closed position data with affiliate attribution. It is structurally similar to ClosedPositionVW but simplified: it has only one SELECT block (no UNION ALL for legacy positions) and uses a different date cutoff (TrackingDate >= '2021-01-01' vs '2021-12-31'). This makes it cleaner for BI tools that only need current-era data.

The view joins ClosedPosition (financial metrics) with RegistrationMetaData (affiliate attribution) on CID with partition alignment. It computes UpdateDate as GREATEST(CommissionDate, ValidFrom) for change detection by BI ETL pipelines.

---

## 2. Business Logic

### 2.1 Single-Path Join (No Legacy Support)

**What**: Only handles current positions (CID > 0, post-2021).

**Rules**:
- Single SELECT: CID > 0 AND TrackingDate >= '2021-01-01'
- No UNION ALL for legacy CID=-1 positions
- Simpler execution plan for BI query patterns

---

## 3. Data Overview

N/A - view returns data from ClosedPosition + RegistrationMetaData.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Position identifier. From ClosedPosition. |
| 2 | CommissionDate | datetime | NO | - | CODE-BACKED | Commission calculation timestamp. |
| 3 | Amount | decimal(16,6) | NO | - | CODE-BACKED | Gross commission amount. |
| 4 | HedgeCommission | decimal(16,6) | NO | - | CODE-BACKED | Hedge commission. |
| 5 | CID | bigint | NO | - | CODE-BACKED | Customer ID. From RegistrationMetaData. |
| 6 | OriginalCID | bigint | NO | - | CODE-BACKED | Original customer. From RegistrationMetaData. |
| 7 | AffiliateID | int | NO | - | CODE-BACKED | Referring affiliate. |
| 8 | AffiliateCampaign | nvarchar(1024) | NO | - | CODE-BACKED | Campaign tracking. |
| 9 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider. |
| 10 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider. |
| 11 | AdditionalData | varchar(512) | NO | - | CODE-BACKED | Extensible metadata. |
| 12 | RealProviderID | bigint | NO | - | CODE-BACKED | Execution entity. |
| 13 | CountryID | bigint | NO | - | CODE-BACKED | Customer country. |
| 14 | NetProfit | float | NO | - | CODE-BACKED | Position P&L. |
| 15 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel. |
| 16 | LabelID | - | YES | - | CODE-BACKED | Always NULL. Backward compatibility. |
| 17 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level. |
| 18 | DownloadID | bigint | NO | - | CODE-BACKED | Download tracking. |
| 19 | LotCount | decimal(16,6) | NO | - | CODE-BACKED | Position size. |
| 20 | BannerID | int | NO | - | CODE-BACKED | Banner reference. |
| 21 | Valid | bit | NO | - | CODE-BACKED | Commission eligibility. |
| 22 | TrackingDate | datetime | NO | - | CODE-BACKED | Tracking entry time. |
| 23 | IsProcessed | bit | YES | - | CODE-BACKED | Processing flag. |
| 24 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Attribution effective date. |
| 25 | UpdateDate | datetime | - | - | CODE-BACKED | Computed: GREATEST(CommissionDate, ValidFrom). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPosition | JOIN | Financial data |
| - | AffiliateCommission.RegistrationMetaData | JOIN | Attribution data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ClosedPositionBI_VW (view)
├── AffiliateCommission.ClosedPosition (table)
└── AffiliateCommission.RegistrationMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | INNER JOIN |
| AffiliateCommission.RegistrationMetaData | Table | INNER JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Recent BI position data
```sql
SELECT TOP 10 ClosedPositionID, CommissionDate, Amount, AffiliateID, CountryID, UpdateDate
FROM AffiliateCommission.ClosedPositionBI_VW WITH (NOLOCK) ORDER BY CommissionDate DESC;
```

### 8.2 Affiliate performance summary
```sql
SELECT AffiliateID, COUNT(*) AS Positions, SUM(Amount) AS TotalAmount, SUM(NetProfit) AS TotalProfit
FROM AffiliateCommission.ClosedPositionBI_VW WITH (NOLOCK) WHERE Valid = 1
GROUP BY AffiliateID ORDER BY TotalAmount DESC;
```

### 8.3 Incremental load query
```sql
SELECT * FROM AffiliateCommission.ClosedPositionBI_VW WITH (NOLOCK)
WHERE UpdateDate >= @LastLoadDate ORDER BY UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionBI_VW | Type: View | Source: fiktivo/AffiliateCommission/Views/AffiliateCommission.ClosedPositionBI_VW.sql*
