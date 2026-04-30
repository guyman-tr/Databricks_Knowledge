# History.ClosedPosition_ADF

> Azure Data Factory variant of the closed-position bridge table, mapping individual eToro position IDs to aggregated commission records loaded via the ADF-based ETL pipeline.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered index on (PositionID, CloseOccurred) |
| **Partition** | Yes - PS_ClosedPosition_By_Month on CloseOccurred |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

History.ClosedPosition_ADF is the Azure Data Factory counterpart of History.ClosedPosition. It serves the same bridge/mapping purpose - linking individual trading position IDs to aggregated closed-position records - but is populated by the ADF-based ETL pipeline rather than the legacy linked-server-based Internal.LoadClosedPositionsFromeToro procedure. The "_ADF" suffix distinguishes this as part of the parallel ADF migration of the affiliate commission data pipeline.

This table exists to support the migration from the legacy linked-server ETL (which populates History.ClosedPosition) to an Azure Data Factory-based pipeline. Both tables have identical schemas but are populated by different data pipelines. The ADF pipeline reads from BILoad staging tables (BILoad.HistoryClosedPosition and BILoad.RevsharePositionSummary) rather than directly from the eToro linked server.

Data flows from the ADF staging layer (BILoad.HistoryClosedPosition) through the AffiliateCommission.LoadClosedPositionsAndAggregates_ADF procedure, which: (1) aggregates positions into AffiliateCommission.ClosedPositionFromEtoro_ADF, (2) inserts individual position-to-aggregate mappings into this table, and (3) upserts customer-level aggregated data into AffiliateCommission.CustomerAggregatedData_ADF. Currently contains 0 rows - the ADF pipeline may be in deployment or testing phase.

---

## 2. Business Logic

### 2.1 ADF Pipeline Position-to-Aggregate Mapping

**What**: Same bridge pattern as History.ClosedPosition, but using ADF staging tables as the data source instead of linked servers.

**Columns/Parameters Involved**: `PositionID`, `ClosedPositionID`, `CloseOccurred`

**Rules**:
- Positions are loaded from BILoad.HistoryClosedPosition (ADF staging table)
- Aggregated records go to AffiliateCommission.ClosedPositionFromEtoro_ADF (note _ADF suffix)
- The CID (customer ID) from BILoad.HistoryClosedPosition is joined to the OUTPUT-captured ClosedPositionID to create the mappings
- Customer aggregated data is upserted (MERGE) into AffiliateCommission.CustomerAggregatedData_ADF
- The entire operation runs in a single transaction for consistency

**Diagram**:
```
Azure Data Factory
    |
    v
BILoad.HistoryClosedPosition          BILoad.RevsharePositionSummary
    |                                      |
    |   AffiliateCommission.LoadClosedPositionsAndAggregates_ADF
    |   (single transaction)
    v                                      v
History.ClosedPosition_ADF      AffiliateCommission.ClosedPositionFromEtoro_ADF
                                AffiliateCommission.CustomerAggregatedData_ADF
```

---

## 3. Data Overview

Table is currently empty (0 rows). The ADF pipeline has not yet loaded data, suggesting it is in a pre-production or migration phase. When active, it will contain the same type of data as History.ClosedPosition: individual PositionIDs mapped to their ClosedPositionIDs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique identifier of an individual closed trading position from the eToro platform. Sourced from BILoad.HistoryClosedPosition.PositionID (ADF staging table). Identical semantics to History.ClosedPosition.PositionID. |
| 2 | CloseOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the position was closed on the eToro platform. Sourced from BILoad.HistoryClosedPosition.CloseOccurred. Partition column (PS_ClosedPosition_By_Month) and clustering key. Identical semantics to History.ClosedPosition.CloseOccurred. |
| 3 | ClosedPositionID | bigint | NO | - | CODE-BACKED | Foreign key to AffiliateCommission.ClosedPositionFromEtoro_ADF.ClosedPositionID (identity column). Links this position to its aggregated commission record in the ADF pipeline variant. Multiple rows can share the same ClosedPositionID when positions for the same customer are grouped together. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPositionFromEtoro_ADF | Implicit FK | Maps individual positions to their ADF-pipeline aggregated closed-position commission record |
| PositionID | BILoad.HistoryClosedPosition | Implicit FK | References the position data staged by Azure Data Factory from the eToro platform |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | INSERT | WRITER | Only procedure that populates this table - inserts position-to-aggregate mappings from BILoad staging data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ClosedPosition_ADF (table)
```

This table has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | WRITER - inserts position-to-aggregate mappings from ADF staging tables |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CDX_History_ClosedPosition_ADF | CLUSTERED | PositionID ASC, CloseOccurred ASC | - | - | Active |

### 7.2 Constraints

None. No primary key, no foreign keys, no check constraints, no defaults.

Note: Partitioned on PS_ClosedPosition_By_Month(CloseOccurred). Unlike its sibling History.ClosedPosition, this table does NOT use PAGE compression.

---

## 8. Sample Queries

### 8.1 Check if ADF pipeline has loaded data
```sql
SELECT COUNT(*) AS TotalRows,
       MIN(CloseOccurred) AS Earliest,
       MAX(CloseOccurred) AS Latest
FROM History.ClosedPosition_ADF WITH (NOLOCK)
```

### 8.2 Compare ADF vs legacy pipeline coverage
```sql
SELECT 'Legacy' AS Pipeline, COUNT(*) AS Rows FROM History.ClosedPosition WITH (NOLOCK)
UNION ALL
SELECT 'ADF' AS Pipeline, COUNT(*) AS Rows FROM History.ClosedPosition_ADF WITH (NOLOCK)
```

### 8.3 Get aggregate details for ADF-loaded positions
```sql
SELECT cp.PositionID, cp.CloseOccurred, cp.ClosedPositionID,
       fe.CID, fe.Commission, fe.NetProfit, fe.Lots
FROM History.ClosedPosition_ADF cp WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPositionFromEtoro_ADF fe WITH (NOLOCK)
  ON cp.ClosedPositionID = fe.ClosedPositionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.1/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ClosedPosition_ADF | Type: Table | Source: fiktivo/History/Tables/History.ClosedPosition_ADF.sql*
