# AffiliateCommission.ClosedPositionEvent_RepairOrganic020123

> One-time repair/backup table created during the February 2023 organic affiliate data fix for closed position events. Not deployed to the live database.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, IDENTITY) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

ClosedPositionEvent_RepairOrganic020123 is a repair/backup table created during a data correction operation in February 2023 ("020123" = Feb 01, 2023). It is a structural copy of the ClosedPositionEvent table, designed to hold a snapshot of event records before or after a repair operation related to organic affiliate attribution.

This table exists only in the SSDT project definition and is NOT deployed to the live database. It served as a safety net during a one-time data fix - either holding the original data before correction or the corrected data before it was applied. The "Organic" in the name suggests the repair involved re-attributing positions that were incorrectly classified as organic (no affiliate) when they should have been attributed to an affiliate.

The table has no stored procedures, views, or other objects referencing it. It is a historical artifact of a completed maintenance operation.

---

## 2. Business Logic

### 2.1 Organic Affiliate Repair Context

**What**: A one-time operation to correct organic attribution on closed position events.

**Columns/Parameters Involved**: `AffiliateID`, `AffiliateCampaign`, `BannerID`, `DownloadID`, `FunnelID`, `LabelID`, `PlayerLevelID`

**Rules**:
- "Organic" positions are those without an affiliate attribution (AffiliateID typically 0 or a special organic affiliate ID)
- This repair corrected events where the affiliate attribution was missing or wrong
- The table includes the full set of attribution columns (AffiliateID, Campaign, Banner, Download, Funnel, Label, PlayerLevel) to capture the corrected values
- Note: this table includes columns (AffiliateCampaign, BannerID, DownloadID, FunnelID, LabelID, PlayerLevelID) that are NOT present in the current ClosedPositionEvent table - indicating these columns were removed from ClosedPositionEvent after this repair was created

---

## 3. Data Overview

Table does not exist in the live database. No data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | NAME-INFERRED | Auto-incrementing surrogate key for the repair table. |
| 2 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Identifier of the closed position event being repaired. Maps to ClosedPositionEvent.ClosedPositionID. |
| 3 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp when the position close event occurred. |
| 4 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the trader. |
| 5 | Amount | decimal(16,6) | NO | - | CODE-BACKED | Commission-eligible amount for the position. |
| 6 | HedgeCommission | decimal(16,6) | NO | - | CODE-BACKED | Hedge commission component. |
| 7 | NetProfit | money | NO | - | CODE-BACKED | Net profit/loss of the position. |
| 8 | LotCount | decimal(16,6) | NO | - | CODE-BACKED | Position size in lots. |
| 9 | OriginalCID | bigint | NO | - | CODE-BACKED | Original customer in copy-trading scenarios. NOT NULL here (vs nullable in ClosedPositionEvent). |
| 10 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider that opened the position. |
| 11 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate attribution - the key field being repaired. |
| 12 | AffiliateCampaign | nvarchar(1024) | YES | - | CODE-BACKED | Campaign string from the affiliate tracking system. Present here but removed from current ClosedPositionEvent. |
| 13 | BannerID | int | NO | - | CODE-BACKED | Banner that led to the registration. Present here but removed from current ClosedPositionEvent. |
| 14 | DownloadID | bigint | NO | - | CODE-BACKED | Download tracking ID. Present here but removed from current ClosedPositionEvent. |
| 15 | CountryID | bigint | NO | - | CODE-BACKED | Customer country. |
| 16 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider for the position. |
| 17 | RealProviderID | bigint | NO | - | CODE-BACKED | Actual execution entity. |
| 18 | FunnelID | int | YES | - | CODE-BACKED | Funnel tracking ID. Present here but removed from current ClosedPositionEvent. |
| 19 | LabelID | int | YES | - | CODE-BACKED | Label classification. Present here but removed from current ClosedPositionEvent. |
| 20 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level classification. Present here but removed from current ClosedPositionEvent. |
| 21 | LastCheckDate | datetime | YES | - | CODE-BACKED | Last date the event was checked for processing. |
| 22 | Source | nvarchar(50) | YES | - | CODE-BACKED | Source system that generated the event. |
| 23 | DateModified | datetime | NO | - | CODE-BACKED | Last modification timestamp. |
| 24 | NonOrganicUpdated | datetime | YES | - | CODE-BACKED | Timestamp when the event was updated from organic to non-organic attribution. Key field for the repair. |
| 25 | ReAttributeUpdated | datetime | YES | - | CODE-BACKED | Timestamp of re-attribution update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPositionEvent | Implicit | Repair copy of event records |

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

### 8.1 Check if table exists in current environment
```sql
SELECT OBJECT_ID('AffiliateCommission.ClosedPositionEvent_RepairOrganic020123') AS ObjectID;
-- Returns NULL if not deployed
```

### 8.2 Count records if deployed
```sql
SELECT COUNT(*) AS RepairRecords
FROM AffiliateCommission.ClosedPositionEvent_RepairOrganic020123 WITH (NOLOCK);
```

### 8.3 Compare with current ClosedPositionEvent structure
```sql
-- This repair table has columns (AffiliateCampaign, BannerID, DownloadID, FunnelID, LabelID, PlayerLevelID)
-- that no longer exist in ClosedPositionEvent, showing schema evolution
SELECT c.name, t.name AS type_name
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('AffiliateCommission.ClosedPositionEvent')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9.6/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionEvent_RepairOrganic020123 | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionEvent_RepairOrganic020123.sql*
