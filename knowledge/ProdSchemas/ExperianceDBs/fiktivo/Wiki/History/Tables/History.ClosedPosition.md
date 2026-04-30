# History.ClosedPosition

> Bridge table that maps individual trading position IDs from the eToro platform to their aggregated closed-position records in the fiktivo affiliate commission system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered index on (PositionID, CloseOccurred) |
| **Partition** | Yes - PS_ClosedPosition_By_Month on CloseOccurred |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

History.ClosedPosition is a bridge table that links individual trading positions closed on the eToro platform to their corresponding aggregated records in the fiktivo affiliate commission pipeline. Each row represents one closed position mapped to a ClosedPositionID, which is the identity key of an aggregated row in AffiliateCommission.ClosedPositionFromEtoro. Multiple positions for the same customer on the same day are aggregated into a single ClosedPositionFromEtoro record, and this table maintains the granular position-level mapping back to that aggregate.

Without this table, the affiliate commission system would lose the ability to trace which specific eToro trading positions contributed to each aggregated commission event. This mapping is essential for auditing, reconciliation, and investigating commission disputes at the individual position level.

Data flows into this table exclusively via the Internal.LoadClosedPositionsFromeToro procedure. That procedure fetches closed positions from the eToro platform (via the linked dbo.HistoryPositionSlim synonym), groups them by customer (CID) and date, inserts the aggregated records into AffiliateCommission.ClosedPositionFromEtoro, then inserts individual position mappings into this table using the OUTPUT-captured ClosedPositionID. No other procedure writes to or modifies this table. The table is read during monitoring checks and partition management.

---

## 2. Business Logic

### 2.1 Position-to-Aggregate Mapping

**What**: Each closed trading position is mapped to exactly one aggregated closed-position record, but multiple positions can map to the same aggregate.

**Columns/Parameters Involved**: `PositionID`, `ClosedPositionID`, `CloseOccurred`

**Rules**:
- Positions are grouped by CID (customer) + date when inserted into AffiliateCommission.ClosedPositionFromEtoro
- The ClosedPositionID is the auto-generated identity from the aggregated record
- Multiple positions sharing the same ClosedPositionID belong to the same customer and were closed on the same calendar day
- Deduplication: before inserting, the ETL procedure deletes any positions already present in History.ClosedPosition for the same PositionID within the processing window

**Diagram**:
```
eToro Platform (dbo.HistoryPositionSlim)
    |
    | Internal.LoadClosedPositionsFromeToro
    |   (fetches TOP 100000, groups by CID + date)
    v
AffiliateCommission.ClosedPositionFromEtoro
    |  ClosedPositionID (identity, 1:many)
    v
History.ClosedPosition
    PositionID  -->  ClosedPositionID
    PositionID  -->  ClosedPositionID   (same aggregate)
    PositionID  -->  ClosedPositionID   (same aggregate)
```

### 2.2 Incremental ETL Watermark

**What**: The ETL process uses a high-watermark pattern to load only new closed positions since the last run.

**Columns/Parameters Involved**: `CloseOccurred`

**Rules**:
- Internal.ClosedPositionsFromeToro stores the LastClosedOccurredPosition watermark
- Each run fetches positions where CloseOccurred >= watermark AND < GETUTCDATE() - 10 minutes
- The 10-minute buffer avoids processing positions that may still be in-flight on the eToro platform
- After successful loading, the watermark is updated to the MAX(CloseOccurred) from the batch
- On cold start (both tables empty), the watermark defaults to GETUTCDATE() - 7 days

---

## 3. Data Overview

| PositionID | CloseOccurred | ClosedPositionID | Meaning |
|---|---|---|---|
| 2147483656 | 2023-01-04 13:06:38 | 1 | First closed position loaded into the system - a single position forming its own aggregate record |
| 2147483660 | 2023-01-04 13:58:04 | 2 | Another individual position forming a separate aggregate - different close time, likely different customer |
| 2147483661 | 2023-01-04 16:09:57 | 3 | One of 7 positions sharing ClosedPositionID=3 - same customer had multiple positions closed within seconds on the same day, all aggregated together |
| 2147483663 | 2023-01-04 16:09:57 | 3 | Another position in the same aggregate batch - notice the near-identical close timestamps indicating a batch close event |
| 2147483673 | 2023-01-04 16:57:58 | 4 | Start of a new aggregate - different customer or different calendar day grouping |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique identifier of an individual closed trading position from the eToro platform. Sourced from dbo.HistoryPositionSlim.PositionID (linked server to eToro). Values are large bigints (2B+ range). Each PositionID appears at most once in this table - the ETL deduplicates before inserting. |
| 2 | CloseOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the position was closed on the eToro platform. Used as the partition column (PS_ClosedPosition_By_Month) and as the clustering key alongside PositionID. Also serves as the ETL watermark boundary - only positions with CloseOccurred >= last watermark are loaded. Range: 2023-01-04 to present. |
| 3 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Foreign key to AffiliateCommission.ClosedPositionFromEtoro.ClosedPositionID (identity column). Links this individual position to its aggregated commission record. Multiple rows can share the same ClosedPositionID when several positions for the same customer are closed on the same calendar day. The aggregate record in ClosedPositionFromEtoro contains the summed Commission, NetProfit, and Lots across all positions in the group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPositionFromEtoro | Implicit FK | Maps individual positions to their aggregated closed-position commission record. The aggregate contains summed financial data (Commission, NetProfit, Lots) and customer attribution data (AffiliateID, CampaignID, etc.) |
| PositionID | dbo.HistoryPositionSlim (external) | Implicit FK | References the original closed position on the eToro trading platform. This is a linked-server synonym to the eToro database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.LoadClosedPositionsFromeToro | INSERT | WRITER | Only procedure that populates this table - inserts position-to-aggregate mappings as part of the ETL pipeline |
| Monitor.CheckClosePositionsAreAdded | - | INDIRECT | Monitors the downstream AffiliateCommission.ClosedPosition table (not this table directly) to verify ETL is running |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ClosedPosition (table)
```

This table has no code-level dependencies (no FK constraints, no computed columns referencing other objects).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.LoadClosedPositionsFromeToro | Stored Procedure | WRITER - inserts position-to-aggregate mappings and reads MAX(CloseOccurred) for watermark initialization |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CDX_History_ClosedPosition | CLUSTERED | PositionID ASC, CloseOccurred ASC | - | - | Active |

### 7.2 Constraints

None. No primary key, no foreign keys, no check constraints, no defaults.

Note: The table uses PAGE compression and is partitioned on PS_ClosedPosition_By_Month(CloseOccurred) for efficient monthly partition management and query performance on the 2.5M+ row dataset.

---

## 8. Sample Queries

### 8.1 Find all positions in a specific aggregate
```sql
SELECT PositionID, CloseOccurred
FROM History.ClosedPosition WITH (NOLOCK)
WHERE ClosedPositionID = 3
ORDER BY CloseOccurred
```

### 8.2 Get aggregate details for a specific position
```sql
SELECT cp.PositionID, cp.CloseOccurred, cp.ClosedPositionID,
       fe.CID, fe.Commission, fe.NetProfit, fe.Lots, fe.AffiliateID
FROM History.ClosedPosition cp WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPositionFromEtoro fe WITH (NOLOCK)
  ON cp.ClosedPositionID = fe.ClosedPositionID
WHERE cp.PositionID = 2147483656
```

### 8.3 Count positions per aggregate for a date range
```sql
SELECT cp.ClosedPositionID, COUNT(*) AS PositionCount,
       MIN(cp.CloseOccurred) AS FirstClose, MAX(cp.CloseOccurred) AS LastClose
FROM History.ClosedPosition cp WITH (NOLOCK)
WHERE cp.CloseOccurred >= '2026-04-01' AND cp.CloseOccurred < '2026-04-13'
GROUP BY cp.ClosedPositionID
ORDER BY PositionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The configured Confluence folder (TRAD/DB) contains Trade schema documentation only. No Confluence pages or Jira tickets reference History.ClosedPosition.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ClosedPosition | Type: Table | Source: fiktivo/History/Tables/History.ClosedPosition.sql*
