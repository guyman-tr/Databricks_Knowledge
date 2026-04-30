# dbo.ClosedPositions

> View wrapping dbo.ClosedPositionsTbl with application-name-based partition routing, enabling 10-way parallel processing of closed positions by QuesService worker instances.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.ClosedPositionsTbl |
| **Partition** | N/A (soft partition via PartitionCol filter) |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.ClosedPositions is a view that provides partition-filtered access to dbo.ClosedPositionsTbl. For QuesService worker connections (identified by app_name()), each worker only sees rows matching its assigned partition (CID % 10). For all other connections, the view returns all rows unfiltered.

This is the core mechanism enabling parallel commission processing. Instead of a single worker processing all closed positions (potential bottleneck), 10 QuesService instances each process 1/10th of the data based on the computed PartitionCol. The view abstracts this routing so consumers don't need to implement partition logic.

The UpdateSubAffiliateID procedure writes to this view (which updates the underlying table). SSRS_AffWiz_ClosedPositions reads through this view for monitoring.

---

## 2. Business Logic

### 2.1 App-Name-Based Partition Routing

**What**: Filters rows based on the calling application's name for parallel processing.

**Columns/Parameters Involved**: `PartitionCol`, `host_name()`, `app_name()`

**Rules**:
- If host_name() does NOT match 'lon-affwiz-srv%': ALL rows are returned (non-production connections see everything)
- If host_name() matches AND app_name() = 'QuesService-0': only PartitionCol=0 rows
- If app_name() = 'QuesService-1': only PartitionCol=1
- ... through QuesService-8 (PartitionCol=8)
- If app_name() = 'QuesService' (no suffix): only PartitionCol=9

**Diagram**:
```
dbo.ClosedPositionsTbl
    |
    v
dbo.ClosedPositions (view)
    |
    +-- host NOT 'lon-affwiz-srv*' --> ALL rows
    +-- QuesService-0 --> PartitionCol=0 only
    +-- QuesService-1 --> PartitionCol=1 only
    +-- ...
    +-- QuesService-8 --> PartitionCol=8 only
    +-- QuesService   --> PartitionCol=9 only
```

---

## 3. Data Overview

| ClosedPositionsID | CID | Commission | FinishedProcessing | PartitionCol | Meaning |
|---|---|---|---|---|---|
| 8500001 | 9763151 | 300 | false | 1 | Unprocessed position in partition 1. Only visible to QuesService-1 on production servers. |
| 8500000 | 9763121 | 300 | false | 1 | Another partition-1 position. Same commission amount suggests test data. |
| 8473778 | 1605328 | 90 | false | 8 | Partition 8 position. Only visible to QuesService-8. |

---

## 4. Elements

All columns are inherited directly from dbo.ClosedPositionsTbl. See [dbo.ClosedPositionsTbl](../Tables/dbo.ClosedPositionsTbl.md) for complete element descriptions (23 columns including computed PartitionCol).

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionsID | int | NO | - | VERIFIED | PK from base table. Closed position identifier. |
| 2 | Occurred | datetime | NO | - | VERIFIED | When the position was closed. |
| 3 | CID | int | NO | - | VERIFIED | Customer ID. Source of PartitionCol computation (CID % 10). |
| 4 | Commission | money | NO | - | VERIFIED | Commission amount from the closed position. |
| 5 | NetProfit | money | NO | - | VERIFIED | Customer's net profit/loss. |
| 6 | Lots | decimal(34,6) | NO | - | VERIFIED | Trading volume in lots. |
| 7 | BonusUsed | money | NO | - | VERIFIED | Bonus amount consumed. |
| 8 | OriginalCustomerID | int | YES | - | VERIFIED | Original CID before migration. |
| 9 | OriginalProviderID | int | YES | - | VERIFIED | Original provider at registration. |
| 10 | SerialID | int | YES | - | VERIFIED | Affiliate ID (updatable via UpdateSubAffiliateID). |
| 11 | SubSerialID | varchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag (updatable). |
| 12 | BannerID | int | YES | - | VERIFIED | Marketing banner ID. |
| 13 | DownloadID | int | YES | - | VERIFIED | Download tracking ID. |
| 14 | CountryIDByIP | int | YES | - | VERIFIED | Country by IP geolocation. |
| 15 | ProviderID | int | YES | - | VERIFIED | Current provider. |
| 16 | RealProviderID | int | YES | - | VERIFIED | Actual provider. |
| 17 | FunnelID | int | YES | - | VERIFIED | Marketing funnel. |
| 18 | LabelID | int | YES | - | VERIFIED | Brand label. |
| 19 | DownloadCounter | int | YES | - | VERIFIED | Download count. |
| 20 | PlayerLevelID | int | YES | - | VERIFIED | Customer tier level. |
| 21 | FinishedUpdating | bit | NO | - | VERIFIED | Data complete flag. |
| 22 | FinishedProcessing | bit | NO | - | VERIFIED | Commission processed flag. |
| 23 | PartitionCol | computed | - | - | VERIFIED | CID % 10. The partition routing key used by this view's WHERE clause. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.ClosedPositionsTbl | Base table | SELECT * with partition filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SSRS_AffWiz_ClosedPositions | FROM | Procedure (READER) | Processing backlog monitoring |
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding affiliate attribution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.ClosedPositions (view)
  +-- dbo.ClosedPositionsTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ClosedPositionsTbl | Table | Base table (SELECT * FROM) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SSRS_AffWiz_ClosedPositions | Stored Procedure | READER |
| dbo.UpdateSubAffiliateID | Stored Procedure | MODIFIER |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized).

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Unprocessed positions (as seen by any non-QuesService client)
```sql
SELECT ClosedPositionsID, CID, Commission, PartitionCol
FROM dbo.ClosedPositions WITH (NOLOCK)
WHERE FinishedUpdating = 1 AND FinishedProcessing = 0
ORDER BY ClosedPositionsID
```

### 8.2 Check partition distribution
```sql
SELECT PartitionCol, COUNT(*) AS Rows
FROM dbo.ClosedPositions WITH (NOLOCK)
GROUP BY PartitionCol
ORDER BY PartitionCol
```

### 8.3 Processing backlog summary
```sql
SELECT FinishedUpdating, FinishedProcessing, COUNT(*) AS Cnt
FROM dbo.ClosedPositions WITH (NOLOCK)
GROUP BY FinishedUpdating, FinishedProcessing
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 9.1/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 23 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ClosedPositions | Type: View | Source: fiktivo/dbo/Views/dbo.ClosedPositions.sql*
