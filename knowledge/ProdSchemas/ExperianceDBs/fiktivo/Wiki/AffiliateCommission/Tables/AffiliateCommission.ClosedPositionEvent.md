# AffiliateCommission.ClosedPositionEvent

> Event tracking table for closed positions in the affiliate commission pipeline, storing the full attribution and financial context for each position event as it flows through commission processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (1 NC PK + 1 CDX on ID + 2 NC) |

---

## 1. Business Meaning

ClosedPositionEvent is the event-level tracking table for closed positions in the affiliate commission pipeline. While ClosedPosition stores the final processed state, ClosedPositionEvent tracks the event as it flows through processing - capturing the initial occurrence details, attribution checks (NonOrganicUpdated, ReAttributeUpdated), and processing metadata (Source, LastCheckDate).

This table exists to manage the intermediate processing state of closed position events. When a position close event arrives, it is recorded here with full financial and attribution context. The system then checks whether the position is organic (no affiliate) or attributed to an affiliate, performs re-attribution checks, and tracks when these checks last occurred. The table enables retry logic and prevents duplicate processing.

The table currently has only 4 rows in this environment, suggesting it is used for active in-flight events that are cleaned up after processing (via RemoveClosedPositionEvent and RemoveClosedPositionExpiredEvents). The NONCLUSTERED PK on ClosedPositionID with a separate CLUSTERED index on ID supports both event-based lookups and ordered processing.

---

## 2. Business Logic

### 2.1 Attribution Check Pipeline

**What**: Each event goes through organic/non-organic checks and optional re-attribution.

**Columns/Parameters Involved**: `NonOrganicUpdated`, `ReAttributeUpdated`, `LastCheckDate`, `Source`

**Rules**:
- NonOrganicUpdated: timestamp when the event was checked for non-organic (affiliate) attribution. NULL = not yet checked
- ReAttributeUpdated: timestamp when the event was checked for re-attribution. NULL = not yet checked
- LastCheckDate: last time the event was examined by the processing pipeline. Updated by UpdateClosedPositionEventLastCheckDate
- Source: identifies which processing node handled the event (e.g., "AzureWestEurope")

### 2.2 Event Lifecycle

**What**: Events are created, processed, and removed.

**Columns/Parameters Involved**: `ClosedPositionID`, `Occurred`, `DateModified`

**Rules**:
- InsertClosedPositionEvent creates the event record
- GetClosedPositionTriggeredEvents reads events ready for commission triggering
- RemoveClosedPositionEvent deletes individual events after processing
- RemoveClosedPositionExpiredEvents cleans up old unprocessed events

---

## 3. Data Overview

| ID | ClosedPositionID | Occurred | CID | Amount | AffiliateID | Source | Meaning |
|---|---|---|---|---|---|---|---|
| 77 | 404469 | 2026-02-17 11:42 | 25182834 | 3 | 61696 | AzureWestEurope | Active event. Small position ($3 amount). Affiliate 61696, Country 101. Neither organic nor re-attribution checks done. |
| 74 | 400460 | 2026-01-21 11:30 | 24231936 | 25.58 | 56662 | AzureWestEurope | Moderate commission amount. Position had a net loss ($-88.63). Country 191. Same Azure processing node. |
| 73 | 386210 | 2025-12-29 20:00 | 24231936 | 483.8 | 56662 | AzureWestEurope | Large commission ($483.80) for same customer as #74. Profitable position ($68.11 net). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. CLUSTERED index for insertion-order processing. Not used as PK - ClosedPositionID is the business key. |
| 2 | ClosedPositionID | bigint | NO | - | CODE-BACKED | The closed position this event tracks. NONCLUSTERED PK ensures uniqueness - one event per position. Maps to ClosedPosition.ClosedPositionID. |
| 3 | Occurred | datetime | NO | - | CODE-BACKED | When the position close occurred on the trading platform. Source event timestamp. |
| 4 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the trader. |
| 5 | Amount | decimal(16,6) | NO | - | CODE-BACKED | Commission-eligible amount (spread). Matches ClosedPosition.Amount. |
| 6 | HedgeCommission | decimal(16,6) | NO | - | CODE-BACKED | Hedge commission component. |
| 7 | NetProfit | money | NO | - | CODE-BACKED | Net profit/loss of the position. |
| 8 | LotCount | decimal(16,6) | NO | - | CODE-BACKED | Position size in lots. |
| 9 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer in copy-trading scenarios. NULL for independent positions. |
| 10 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider entity. |
| 11 | CountryID | bigint | NO | - | CODE-BACKED | Customer country. |
| 12 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider entity. |
| 13 | RealProviderID | bigint | NO | - | CODE-BACKED | Actual execution entity. |
| 14 | LastCheckDate | datetime | YES | - | CODE-BACKED | Last time the event was examined by the processing pipeline. Updated by UpdateClosedPositionEventLastCheckDate. NULL = never checked. |
| 15 | Source | nvarchar(50) | YES | - | CODE-BACKED | Processing node identifier (e.g., "AzureWestEurope"). Tracks which datacenter/service instance processed the event. Indexed for source-based filtering. |
| 16 | DateModified | datetime | NO | getutcdate() | CODE-BACKED | Last modification timestamp. Auto-set via default. Used for staleness checks. |
| 17 | NonOrganicUpdated | datetime | YES | - | CODE-BACKED | Timestamp when the non-organic attribution check was performed. NULL = check not yet run. Indexed with CID for targeted re-checks. |
| 18 | ReAttributeUpdated | datetime | YES | - | CODE-BACKED | Timestamp when the re-attribution check was performed. NULL = check not yet run. |
| 19 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate attributed to this position. Determined during processing. May change after re-attribution. |
| 20 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Cross-provider customer identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPosition | Implicit FK | Parent position record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.InsertClosedPositionEvent | INSERT | Writer | Creates event records |
| AffiliateCommission.RemoveClosedPositionEvent | DELETE | Deleter | Removes processed events |
| AffiliateCommission.RemoveClosedPositionExpiredEvents | DELETE | Deleter | Cleans up expired events |
| AffiliateCommission.GetClosedPositionTriggeredEvents | SELECT | Reader | Reads triggered events |
| AffiliateCommission.UpdateClosedPositionEventLastCheckDate | UPDATE | Modifier | Updates check timestamp |
| AffiliateCommission.UpdateEvents | - | Modifier | General event update processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ClosedPositionEvent (table)
└── AffiliateCommission.ClosedPosition (table) [implicit, via ClosedPositionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | Parent - ClosedPositionID references position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.InsertClosedPositionEvent | Stored Procedure | Writer |
| AffiliateCommission.RemoveClosedPositionEvent | Stored Procedure | Deleter |
| AffiliateCommission.RemoveClosedPositionExpiredEvents | Stored Procedure | Deleter |
| AffiliateCommission.GetClosedPositionTriggeredEvents | Stored Procedure | Reader |
| AffiliateCommission.UpdateClosedPositionEventLastCheckDate | Stored Procedure | Modifier |
| AffiliateCommission.UpdateEvents | Stored Procedure | Modifier |
| AffiliateCommission.ClosedPositionVW | View | Reads event data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPositionEvent | NC PK | ClosedPositionID ASC | - | - | Active (PAGE compression) |
| CDX_ClosedPositionEvent_ID | CLUSTERED | ID ASC | - | - | Active (PAGE compression) |
| IDX_AffiliateCommissionClosedPositionEvent_CID_NonOrganicUpdated | NC | CID, NonOrganicUpdated | - | - | Active (PAGE compression) |
| IX_ClosedPositionEvent_SourceOccurred | NC | Source, Occurred, DateModified | NonOrganicUpdated, ReAttributeUpdated | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClosedPositionEvent | PRIMARY KEY | Unique ClosedPositionID (nonclustered) |
| DF_ClosedPositionEvent_DateModified | DEFAULT | getutcdate() for DateModified |

Data compression: PAGE on table and PK index.

---

## 8. Sample Queries

### 8.1 Active events pending processing
```sql
SELECT ClosedPositionID, Occurred, CID, Amount, AffiliateID, Source,
       NonOrganicUpdated, ReAttributeUpdated, LastCheckDate
FROM AffiliateCommission.ClosedPositionEvent WITH (NOLOCK)
ORDER BY ID DESC;
```

### 8.2 Events needing organic check
```sql
SELECT ClosedPositionID, CID, AffiliateID, Occurred
FROM AffiliateCommission.ClosedPositionEvent WITH (NOLOCK)
WHERE NonOrganicUpdated IS NULL;
```

### 8.3 Events with full position context
```sql
SELECT e.ClosedPositionID, e.Occurred, e.CID, e.AffiliateID, e.GCID,
       e.Amount, e.NetProfit, e.Source,
       cp.CommissionDate, cp.IsProcessed, cp.Valid
FROM AffiliateCommission.ClosedPositionEvent e WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPosition cp WITH (NOLOCK)
    ON e.ClosedPositionID = cp.ClosedPositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionEvent | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionEvent.sql*
