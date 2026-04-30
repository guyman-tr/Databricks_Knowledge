# AffiliateCommission.ClosedPositionFromEtoro

> Staging/queue table that receives closed position data from the eToro trading platform for processing by the affiliate commission pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + NC on ProcessingDate) |

---

## 1. Business Meaning

ClosedPositionFromEtoro is the inbound staging table for closed trading positions arriving from the eToro core trading platform. Each row represents one position that was closed and needs to be processed by the affiliate commission system. It acts as a queue between the trading platform and the commission pipeline.

This table exists as the entry point for the closed position commission workflow. When a trading position is closed on eToro, the details are written here with full affiliate attribution context (AffiliateID, Campaign, Banner, Download, Funnel, Label, PlayerLevel). The commission service then reads unprocessed records via GetClosedPositionsFromEtoro, processes them (creating ClosedPosition and ClosedPositionEvent records), and removes them via RemoveClosedPositionFromEtoro.

The table currently holds 101 rows, all processed (ProcessingDate is set on all). Data ranges from January 2024 to November 2025. Unlike the AffiliateTraderRegistrationQueue (which stores XML messages), this table stores structured columnar data - a more modern pattern. Notably, this table includes attribution columns (AffiliateID, AffiliateCampaign, BannerID, etc.) that are NOT present in the downstream ClosedPosition table, indicating the commission pipeline extracts and routes attribution data to ClosedPositionEvent or RegistrationMetaData during processing.

---

## 2. Business Logic

### 2.1 Queue Processing Pattern

**What**: Positions are picked up in batches, processed, and removed - with a 10-minute retry window for stuck records.

**Columns/Parameters Involved**: `ProcessingDate`, `ClosedPositionID`

**Rules**:
- GetClosedPositionsFromEtoro picks up records where ProcessingDate IS NULL or older than 10 minutes
- It updates ProcessingDate to current UTC time and outputs the position data
- Default batch size is 100 records (@NumberOfMessages parameter)
- After successful processing, RemoveClosedPositionFromEtoro deletes the record by ClosedPositionID
- Records that fail processing remain in the table and are retried after the 10-minute window

**Diagram**:
```
eToro Trading Platform
       |
       v (INSERT - position close data)
  ClosedPositionFromEtoro [ProcessingDate = NULL]
       |
       v GetClosedPositionsFromEtoro (UPDATE + OUTPUT, batch of 100)
  ClosedPositionFromEtoro [ProcessingDate = now]
       |
       v (Commission service processes)
       |
       +-- Success --> RemoveClosedPositionFromEtoro (DELETE)
       +-- Failure --> retried after 10 min (ProcessingDate reset window)
```

### 2.2 Attribution Data Enrichment

**What**: The staging table carries full affiliate attribution context that is separated during downstream processing.

**Columns/Parameters Involved**: `AffiliateID`, `AffiliateCampaign`, `BannerID`, `DownloadID`, `FunnelID`, `LabelID`, `PlayerLevelID`

**Rules**:
- ClosedPositionFromEtoro carries 7 attribution columns not present in the downstream ClosedPosition table
- During processing, position financial data goes to ClosedPosition (Amount, NetProfit, LotCount, etc.)
- Attribution data (AffiliateID, Campaign, Banner, etc.) goes to ClosedPositionEvent
- This separation allows the core position table to remain compact while detailed attribution lives in the event record

---

## 3. Data Overview

| ClosedPositionID | CloseOccurred | CID | Commission | AffiliateID | CountryID | ProcessingDate | Meaning |
|---|---|---|---|---|---|---|---|
| 382382 | 2025-11-27 12:53 | 10000012 | 720670 | 3 | 196 | 2026-04-12 13:46 | Large position with very high commission (720K) and massive lot count. Copied from OriginalCID 4497286. FunnelID 36, PlayerLevel 2. |
| 351473 | 2025-08-27 14:53 | 3739240 | 16 | 3 | 74 | 2026-04-12 13:46 | Typical position with small commission. Copied from OriginalCID 3754095. Country 74, Funnel 5, PlayerLevel 5. |
| 350397 | 2025-08-19 07:01 | 14952810 | 0 | 3 | 74 | 2026-04-12 13:46 | Tiny position (0.000475 lots) with zero commission and profit. Likely a fractional/test position. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier for the staged position. Generated in this table - this is the source ID that flows to ClosedPosition.ClosedPositionID. PK with clustered index. |
| 2 | CloseOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the position was actually closed on the trading platform. Distinct from ProcessingDate (when it was picked up for commission processing). |
| 3 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the trader who held the position. Output by GetClosedPositionsFromEtoro for commission processing. |
| 4 | Commission | decimal(16,6) | NO | - | CODE-BACKED | Commission-eligible amount (spread) from the position. Called "Amount" in the downstream ClosedPosition table. |
| 5 | NetProfit | money | NO | - | CODE-BACKED | Net profit/loss of the position. Negative = customer lost money. Passed through to ClosedPosition.NetProfit. |
| 6 | Lots | decimal(34,6) | NO | - | CODE-BACKED | Position size in lots. Uses decimal(34,6) - wider than ClosedPosition.LotCount decimal(16,6), possibly to handle aggregated or very large positions without overflow. |
| 7 | OriginalCID | bigint | NO | - | CODE-BACKED | Original customer in copy-trading scenarios. NOT NULL here (0 when not copied) vs nullable in ClosedPosition. |
| 8 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Provider that originally opened the position. 0 = same provider. Output by GetClosedPositionsFromEtoro. |
| 9 | AffiliateID | int | NO | - | CODE-BACKED | Referring affiliate. Present here but NOT in downstream ClosedPosition - attribution routed to ClosedPositionEvent during processing. |
| 10 | AffiliateCampaign | nvarchar(1024) | YES | - | CODE-BACKED | Campaign tracking string. Present here but NOT in downstream ClosedPosition. |
| 11 | BannerID | int | YES | - | CODE-BACKED | Banner that led to registration. Present here but NOT in downstream ClosedPosition. |
| 12 | DownloadID | bigint | YES | - | CODE-BACKED | Download/app install tracking. Present here but NOT in downstream ClosedPosition. |
| 13 | CountryID | bigint | NO | - | CODE-BACKED | Customer's registration country. Output by GetClosedPositionsFromEtoro. Flows to ClosedPosition.CountryID. |
| 14 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider entity. Output by GetClosedPositionsFromEtoro. |
| 15 | RealProviderID | bigint | YES | - | CODE-BACKED | Actual execution entity. Nullable here (vs NOT NULL in ClosedPosition), filled during processing. |
| 16 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel identifier. Present here but NOT in downstream ClosedPosition. |
| 17 | LabelID | int | YES | - | CODE-BACKED | Classification label. Present here but NOT in downstream ClosedPosition. |
| 18 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level classification. Present here but NOT in downstream ClosedPosition. |
| 19 | ProcessingDate | datetime | YES | - | CODE-BACKED | Timestamp when GetClosedPositionsFromEtoro picked up the record. NULL = unprocessed. Non-NULL = being processed or completed. Records with ProcessingDate older than 10 minutes are eligible for re-pickup (retry). |
| 20 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Cross-provider customer identifier. Added in PART-3405 (Feb 2025). Output by GetClosedPositionsFromEtoro. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. Data flows downstream to ClosedPosition and ClosedPositionEvent.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.GetClosedPositionsFromEtoro | UPDATE/OUTPUT | Reader/Modifier | Picks up unprocessed records in batches |
| AffiliateCommission.RemoveClosedPositionFromEtoro | DELETE | Deleter | Removes processed records |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | - | Reader | ADF pipeline reads from this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.GetClosedPositionsFromEtoro | Stored Procedure | Reader - batch pickup |
| AffiliateCommission.RemoveClosedPositionFromEtoro | Stored Procedure | Deleter - cleanup after processing |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | Reader - ADF pipeline |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPositions | CLUSTERED PK | ClosedPositionID ASC | - | - | Active |
| IDX_AffiliateCommissionClosedPositionFromEtoro_ProcessingDate | NC | ProcessingDate ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClosedPositions | PRIMARY KEY | Ensures unique ClosedPositionID |

---

## 8. Sample Queries

### 8.1 Find unprocessed positions ready for pickup
```sql
SELECT ClosedPositionID, CloseOccurred, CID, Commission, AffiliateID
FROM AffiliateCommission.ClosedPositionFromEtoro WITH (NOLOCK)
WHERE ProcessingDate IS NULL
   OR ProcessingDate < DATEADD(minute, -10, GETUTCDATE())
ORDER BY ClosedPositionID;
```

### 8.2 Check queue depth and processing lag
```sql
SELECT COUNT(*) AS TotalInQueue,
       SUM(CASE WHEN ProcessingDate IS NULL THEN 1 ELSE 0 END) AS Unprocessed,
       SUM(CASE WHEN ProcessingDate < DATEADD(minute, -10, GETUTCDATE()) THEN 1 ELSE 0 END) AS RetryEligible,
       MIN(CloseOccurred) AS OldestPosition,
       MAX(CloseOccurred) AS NewestPosition
FROM AffiliateCommission.ClosedPositionFromEtoro WITH (NOLOCK);
```

### 8.3 Position details with attribution context
```sql
SELECT ClosedPositionID, CloseOccurred, CID, OriginalCID, GCID,
       Commission, NetProfit, Lots,
       AffiliateID, AffiliateCampaign, BannerID, FunnelID, LabelID, PlayerLevelID,
       CountryID, ProviderID, RealProviderID,
       ProcessingDate
FROM AffiliateCommission.ClosedPositionFromEtoro WITH (NOLOCK)
ORDER BY ClosedPositionID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design + CountryID restored (Dec 2023) |
| [PART-3405](https://etoro-jira.atlassian.net/browse/PART-3405) | Jira | Added GCID to GetClosedPositionsFromEtoro output (Feb 2025) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionFromEtoro | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionFromEtoro.sql*
