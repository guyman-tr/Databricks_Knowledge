# AffiliateCommission.ClosedPositionFromEtoro_ADF

> Azure Data Factory (ADF) variant of the closed position staging table, used as a landing zone for positions ingested via the ADF pipeline instead of the traditional Service Broker/queue path.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + NC on ProcessingDate) |

---

## 1. Business Meaning

ClosedPositionFromEtoro_ADF is the Azure Data Factory (ADF) variant of the ClosedPositionFromEtoro staging table. It is structurally identical to ClosedPositionFromEtoro and serves the same purpose - staging closed position data from the trading platform for affiliate commission processing - but is loaded via the ADF data pipeline instead of the traditional queue/Service Broker path.

This table exists as part of the migration from Service Broker-based data ingestion to Azure Data Factory pipelines. The ADF pipeline lands position data here, and the LoadClosedPositionsAndAggregates_ADF procedure then processes it, moving data into the main ClosedPosition and ClosedPositionCommission tables.

The table is currently empty (0 rows), which may indicate the ADF pipeline is not active in this environment, or that it processes and clears data quickly. The table structure matches ClosedPositionFromEtoro exactly, including all 20 columns and the same attribution fields.

---

## 2. Business Logic

### 2.1 ADF Pipeline Landing Zone

**What**: ADF deposits closed position data here; a stored procedure then processes and moves it downstream.

**Columns/Parameters Involved**: `ProcessingDate`, `ClosedPositionID`

**Rules**:
- ADF pipeline INSERTs position data (ProcessingDate initially NULL)
- LoadClosedPositionsAndAggregates_ADF reads and processes the data
- After processing, records are presumably deleted (empty table state)
- Same retry pattern as ClosedPositionFromEtoro (10-minute ProcessingDate window)

---

## 3. Data Overview

Table is currently empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier for the staged position. Structurally identical to ClosedPositionFromEtoro.ClosedPositionID. |
| 2 | CloseOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the position was closed on the trading platform. |
| 3 | CID | bigint | NO | - | CODE-BACKED | Customer ID of the trader. |
| 4 | Commission | decimal(16,6) | NO | - | CODE-BACKED | Commission-eligible amount from the position. |
| 5 | NetProfit | money | NO | - | CODE-BACKED | Net profit/loss of the position. |
| 6 | Lots | decimal(34,6) | NO | - | CODE-BACKED | Position size in lots. Uses wider precision decimal(34,6). |
| 7 | OriginalCID | bigint | NO | - | CODE-BACKED | Original customer in copy-trading scenarios. |
| 8 | OriginalProviderID | bigint | NO | - | CODE-BACKED | Original provider. 0 = not transferred. |
| 9 | AffiliateID | int | NO | - | CODE-BACKED | Referring affiliate. Routed to downstream event tables during processing. |
| 10 | AffiliateCampaign | nvarchar(1024) | YES | - | CODE-BACKED | Campaign tracking string. |
| 11 | BannerID | int | YES | - | CODE-BACKED | Banner reference. |
| 12 | DownloadID | bigint | YES | - | CODE-BACKED | Download/app install tracking. |
| 13 | CountryID | bigint | NO | - | CODE-BACKED | Customer's registration country. |
| 14 | ProviderID | bigint | NO | - | CODE-BACKED | Current provider entity. |
| 15 | RealProviderID | bigint | YES | - | CODE-BACKED | Actual execution entity. |
| 16 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel identifier. |
| 17 | LabelID | int | YES | - | CODE-BACKED | Classification label. |
| 18 | PlayerLevelID | int | YES | - | CODE-BACKED | Player level. |
| 19 | ProcessingDate | datetime | YES | - | CODE-BACKED | Timestamp of processing pickup. NULL = unprocessed. |
| 20 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Cross-provider customer identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. Data flows downstream to ClosedPosition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | - | Reader/Modifier | ADF pipeline processor |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | Processes ADF-landed position data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPositions_ADF | CLUSTERED PK | ClosedPositionID ASC | - | - | Active |
| IDX_AffiliateCommissionClosedPositionFromEtoro_ProcessingDate_ADF | NC | ProcessingDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ClosedPositions_ADF | PRIMARY KEY | Ensures unique ClosedPositionID |

---

## 8. Sample Queries

### 8.1 Check if ADF pipeline has pending data
```sql
SELECT COUNT(*) AS PendingPositions
FROM AffiliateCommission.ClosedPositionFromEtoro_ADF WITH (NOLOCK)
WHERE ProcessingDate IS NULL;
```

### 8.2 Compare queue depths between standard and ADF paths
```sql
SELECT 'Standard' AS Pipeline, COUNT(*) AS QueueDepth
FROM AffiliateCommission.ClosedPositionFromEtoro WITH (NOLOCK)
UNION ALL
SELECT 'ADF', COUNT(*)
FROM AffiliateCommission.ClosedPositionFromEtoro_ADF WITH (NOLOCK);
```

### 8.3 Recent ADF-ingested positions
```sql
SELECT TOP 10 ClosedPositionID, CloseOccurred, CID, Commission, AffiliateID, ProcessingDate
FROM AffiliateCommission.ClosedPositionFromEtoro_ADF WITH (NOLOCK)
ORDER BY ClosedPositionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionFromEtoro_ADF | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionFromEtoro_ADF.sql*
