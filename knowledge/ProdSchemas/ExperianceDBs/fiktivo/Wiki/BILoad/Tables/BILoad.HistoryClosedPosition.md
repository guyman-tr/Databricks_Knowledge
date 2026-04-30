# BILoad.HistoryClosedPosition

> ADF staging table that temporarily holds individual closed trading position records from the eToro platform before they are mapped to aggregated commission records by the ADF ETL pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Table |
| **Key Identifier** | No PK - staging table with no unique constraint |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

BILoad.HistoryClosedPosition is a staging table in the Azure Data Factory (ADF) ETL pipeline for affiliate commission processing. It holds individual closed trading positions - each row representing a single position that was closed on the eToro platform - temporarily staged by ADF before being loaded into the commission system. The table captures the minimal position identity needed for the downstream bridge mapping: which customer (CID) closed which position (PositionID) and when (CloseOccurred).

This table exists because the ADF pipeline replaced the legacy linked-server-based ETL that queried the eToro production database directly. Instead of pulling position data through a linked server in real time, ADF extracts data in batches and lands it in BILoad staging tables. Without this staging table, the ADF pipeline could not map individual positions to their aggregated commission records in the downstream History.ClosedPosition_ADF table.

Data flows in from Azure Data Factory (external), is read by AffiliateCommission.LoadClosedPositionsAndAggregates_ADF, and is consumed in Phase 2 of that procedure: each row is joined via CID to the just-inserted aggregated records (captured via OUTPUT) to create position-to-aggregate mappings in History.ClosedPosition_ADF. After the pipeline completes, BILoad.TruncateLoadTable clears this table to prepare for the next batch. The table is intentionally ephemeral - it is truncated between runs.

---

## 2. Business Logic

### 2.1 ADF Staging and Load Cycle

**What**: This table is part of a truncate-load-process staging pattern for the ADF batch ETL pipeline.

**Columns/Parameters Involved**: `CID`, `PositionID`, `CloseOccurred`

**Rules**:
- ADF populates this table with closed position data extracted from the eToro platform
- AffiliateCommission.LoadClosedPositionsAndAggregates_ADF checks if this table has data before proceeding (EXISTS guard)
- The procedure also verifies BILoad.LastRevshareRuntime sync before processing (prevents stale data)
- Rows are joined on CID to OUTPUT-captured ClosedPositionIDs from AffiliateCommission.ClosedPositionFromEtoro_ADF to create bridge records in History.ClosedPosition_ADF
- After processing, BILoad.TruncateLoadTable clears the table for the next ADF run
- The entire load-process cycle runs in a single transaction for atomicity

**Diagram**:
```
Azure Data Factory (external)
    |
    | TRUNCATE (BILoad.TruncateLoadTable)
    | LOAD (ADF populates staging)
    v
BILoad.HistoryClosedPosition (staging)
    |
    | READ (LoadClosedPositionsAndAggregates_ADF - Phase 2)
    | JOIN on CID to @InsertedClosedPositions
    v
History.ClosedPosition_ADF (bridge table)
    |
    | TRUNCATE (next cycle prep)
    v
(staging cleared for next batch)
```

### 2.2 CID-Based Position-to-Aggregate Bridging

**What**: CID is the join key that links individual positions in this staging table to their aggregated commission records.

**Columns/Parameters Involved**: `CID`, `PositionID`

**Rules**:
- BILoad.RevsharePositionSummary is inserted first into ClosedPositionFromEtoro_ADF (one row per CID with aggregated commission data)
- The OUTPUT clause captures each inserted row's CID and auto-generated ClosedPositionID
- This table's rows are then joined on CID to that OUTPUT to get the ClosedPositionID for each position
- Result: each PositionID in this table gets mapped to its parent aggregate ClosedPositionID
- A single CID may have multiple positions (1:many) - one aggregate record maps to many individual positions

---

## 3. Data Overview

Table is currently empty (0 rows). This is expected behavior for a staging table - it is truncated between ADF pipeline runs. Data is transient: loaded by ADF, consumed by LoadClosedPositionsAndAggregates_ADF, then truncated by TruncateLoadTable.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | NO | - | CODE-BACKED | Customer identifier on the eToro platform. Used as the join key to link individual closed positions to their aggregated commission record in AffiliateCommission.ClosedPositionFromEtoro_ADF. In LoadClosedPositionsAndAggregates_ADF, this column joins to the @InsertedClosedPositions temp table (ON h.CID = i.CID) to obtain the generated ClosedPositionID for each position. A single CID may have multiple positions in a batch. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique identifier of an individual closed trading position from the eToro platform. Inserted into History.ClosedPosition_ADF as the position-level detail record. Each PositionID represents one closed trade (e.g., a stock sale, CFD close, or copy-trade closure). |
| 3 | CloseOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the position was closed on the eToro platform. Inserted into History.ClosedPosition_ADF.CloseOccurred, where it serves as the partition column (PS_ClosedPosition_By_Month) and clustering key for the downstream bridge table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer (cross-database) | Implicit | Customer identifier from the eToro trading platform - references the customer who owns the closed positions |
| PositionID | Positions (cross-database) | Implicit | References the individual trading position on the eToro platform |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ClosedPosition_ADF | PositionID | Implicit FK | Bridge table stores PositionID values sourced from this staging table |
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | - | READ (SELECT + EXISTS) | Reads all rows during Phase 2 of the load procedure; also checks existence as a safeguard |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is a standalone staging table with no FKs, no computed columns, and no references to other objects within its CREATE TABLE statement.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | READER - EXISTS guard check + SELECT FROM with JOIN on CID to create bridge records |
| BILoad.TruncateLoadTable | Stored Procedure | DELETER - dynamic TRUNCATE TABLE clears staging data between ADF runs |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. As a staging table that is truncated between runs, indexes are unnecessary - the table is always either empty or holds a single batch that is read once sequentially.

### 7.2 Constraints

None. No PK, no FKs, no CHECK constraints. This is a minimal staging table designed for fast bulk INSERT (from ADF) and sequential read (by the load procedure).

---

## 8. Sample Queries

### 8.1 Check if ADF has loaded data for processing
```sql
SELECT COUNT(*) AS PendingPositions
FROM BILoad.HistoryClosedPosition WITH (NOLOCK)
```

### 8.2 Preview staged positions by customer
```sql
SELECT CID,
       COUNT(*) AS PositionCount,
       MIN(CloseOccurred) AS EarliestClose,
       MAX(CloseOccurred) AS LatestClose
FROM BILoad.HistoryClosedPosition WITH (NOLOCK)
GROUP BY CID
ORDER BY PositionCount DESC
```

### 8.3 Join staged positions to RevsharePositionSummary for full context
```sql
SELECT h.CID,
       h.PositionID,
       h.CloseOccurred,
       r.AffiliateID,
       r.Commission,
       r.NetProfit,
       r.LotsDecimal
FROM BILoad.HistoryClosedPosition h WITH (NOLOCK)
JOIN BILoad.RevsharePositionSummary r WITH (NOLOCK) ON h.CID = r.CID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created BILoad schema tables and procedures for ADF-based ETL. |

No direct Confluence pages found for this object. Business context inherited from existing wiki docs for History.ClosedPosition_ADF and AffiliateCommission.LoadClosedPositionsAndAggregates_ADF.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.HistoryClosedPosition | Type: Table | Source: fiktivo/BILoad/Tables/BILoad.HistoryClosedPosition.sql*
