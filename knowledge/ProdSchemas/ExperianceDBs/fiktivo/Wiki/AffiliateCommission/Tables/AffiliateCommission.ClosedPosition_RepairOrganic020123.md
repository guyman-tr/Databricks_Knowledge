# AffiliateCommission.ClosedPosition_RepairOrganic020123

> One-time repair/backup table created during the February 2023 organic affiliate data fix for closed positions. Structurally identical to ClosedPosition_Repair010123. Not deployed to the live database.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

ClosedPosition_RepairOrganic020123 is a repair/backup table created during a data correction operation in February 2023 targeting organic affiliate attribution. It is structurally identical to ClosedPosition_Repair010123 (the January 2023 repair) and contains the same expanded column set including attribution columns no longer present in the current ClosedPosition table.

The "Organic" designation indicates this repair specifically addressed positions that were incorrectly classified as organic (no affiliate) when they should have been attributed to a referring affiliate. This is the companion table to ClosedPositionEvent_RepairOrganic020123, which holds the corresponding event-level repair data.

This table exists only in the SSDT project and is NOT deployed to the live database. No other objects reference it.

---

## 2. Business Logic

No complex business logic. This is a static backup/repair table used during the February 2023 organic affiliate re-attribution operation.

---

## 3. Data Overview

Table does not exist in the live database. No data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Closed position identifier. |
| 2 | CommissionDate | datetime | NO | - | CODE-BACKED | Commission calculation timestamp. |
| 3 | Amount | decimal(16,6) | NO | - | CODE-BACKED | Gross commission amount. |
| 4 | HedgeCommission | decimal(16,6) | NO | - | CODE-BACKED | Hedge commission component. |
| 5 | CID | bigint | NO | - | CODE-BACKED | Customer ID. |
| 6 | OriginalCID | bigint | NO | - | CODE-BACKED | Original customer in copy-trading. |
| 7 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate attribution - key field for the organic repair. |
| 8 | AffiliateCampaign | nvarchar(1024) | YES | - | CODE-BACKED | Campaign tracking string. |
| 9 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider. |
| 10 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider. |
| 11 | RealProviderID | bigint | NO | - | CODE-BACKED | Execution entity. |
| 12 | CountryID | bigint | NO | - | CODE-BACKED | Customer country. |
| 13 | NetProfit | float | NO | - | CODE-BACKED | Position net profit/loss. |
| 14 | FunnelID | int | YES | - | CODE-BACKED | Funnel tracking. |
| 15 | LabelID | int | YES | - | CODE-BACKED | Label classification. |
| 16 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level. |
| 17 | DownloadID | bigint | NO | - | CODE-BACKED | Download tracking. |
| 18 | LotCount | decimal(16,6) | NO | - | CODE-BACKED | Position size in lots. |
| 19 | BannerID | int | NO | - | CODE-BACKED | Banner reference. |
| 20 | Valid | bit | NO | - | CODE-BACKED | Position validity flag. |
| 21 | TrackingDate | datetime | NO | - | CODE-BACKED | Tracking system entry timestamp. |
| 22 | IsProcessed | bit | YES | - | CODE-BACKED | Processing completion flag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPosition | Implicit | Repair copy of position records |

### 5.2 Referenced By (other objects point to this)

No objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None defined.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if table exists
```sql
SELECT OBJECT_ID('AffiliateCommission.ClosedPosition_RepairOrganic020123') AS ObjectID;
```

### 8.2 Count records if deployed
```sql
SELECT COUNT(*) AS RepairRecords
FROM AffiliateCommission.ClosedPosition_RepairOrganic020123 WITH (NOLOCK);
```

### 8.3 Compare with companion event repair table
```sql
-- This table and ClosedPositionEvent_RepairOrganic020123 form a pair
-- for the February 2023 organic re-attribution fix
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPosition_RepairOrganic020123 | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPosition_RepairOrganic020123.sql*
