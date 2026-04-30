# BILoad Schema Overview

> Azure Data Factory staging schema for the affiliate revenue-share commission pipeline. Provides transient staging tables for position data, a sync checkpoint mechanism, and operational logging.

## Purpose

The BILoad schema is a lightweight ETL staging layer that mediates between Azure Data Factory (ADF) and the affiliate commission system. It replaces the legacy linked-server approach where the commission system queried the eToro production database directly. Instead, ADF extracts data in batches, lands it in BILoad staging tables, and SQL-side procedures process and load it into the commission tables.

## Architecture

```
eToro Platform (source)
    |
    | Azure Data Factory (extraction + calculation)
    v
+-----------------------------------------------------------+
|  BILoad Schema (staging)                                  |
|                                                           |
|  HistoryClosedPosition    RevsharePositionSummary         |
|  (position-level detail)  (customer-level aggregates)     |
|                                                           |
|  LastRevshareRuntime      Progress_Log                    |
|  (sync checkpoint)        (operational audit log)         |
|                                                           |
|  GetLastRevshareRuntime   TruncateLoadTable               |
|  (scheduling API)         (staging cleanup utility)       |
|                                                           |
|  UpdateProgress_Log                                       |
|  (centralized logging)                                    |
+-----------------------------------------------------------+
    |
    | AffiliateCommission.LoadClosedPositionsAndAggregates_ADF
    v
+-----------------------------------------------------------+
|  Commission System (destination)                          |
|                                                           |
|  AffiliateCommission.ClosedPositionFromEtoro_ADF          |
|  History.ClosedPosition_ADF                               |
|  AffiliateCommission.CustomerAggregatedData_ADF           |
+-----------------------------------------------------------+
```

## Pipeline Flow

1. **ADF calls TruncateLoadTable** to clear HistoryClosedPosition and RevsharePositionSummary
2. **ADF loads staging tables** with fresh position data from eToro
3. **ADF calls GetLastRevshareRuntime** to get scheduling parameters
4. **ADF calls LoadClosedPositionsAndAggregates_ADF** with @LastRunDate and @NextRunTime
5. The procedure validates sync state via LastRevshareRuntime
6. The procedure processes data in a single transaction:
   - Phase 1: Insert aggregated positions into ClosedPositionFromEtoro_ADF
   - Phase 2: Map individual positions to aggregates via HistoryClosedPosition
   - Phase 3: MERGE customer aggregated data into CustomerAggregatedData_ADF
7. On success, LastRevshareRuntime is updated to @NextRunTime
8. All steps are logged to Progress_Log via UpdateProgress_Log

## Object Summary

| Object | Type | Role |
|--------|------|------|
| HistoryClosedPosition | Table | Staging: individual closed position records (CID, PositionID, CloseOccurred) |
| LastRevshareRuntime | Table | Config: single-row sync checkpoint (LastRun datetime) |
| Progress_Log | Table | Audit: operational log of all pipeline steps |
| RevsharePositionSummary | Table | Staging: customer-level aggregated revenue-share data (28 columns) |
| GetLastRevshareRuntime | SP | API: returns LastRun + computed NextRun for ADF scheduling |
| UpdateProgress_Log | SP | Utility: centralized logging wrapper for Progress_Log |
| TruncateLoadTable | SP | Utility: dynamic TRUNCATE with EXECUTE AS OWNER for staging cleanup |

## Key Design Patterns

- **Truncate-Load-Process**: Staging tables are truncated, loaded by ADF, processed by SQL, then truncated again
- **Sync Guard**: LastRevshareRuntime prevents stale data processing via timestamp comparison
- **Permission Elevation**: TruncateLoadTable uses EXECUTE AS OWNER for TRUNCATE permission
- **Centralized Logging**: All pipeline steps log through UpdateProgress_Log
- **Dollar-to-Cents Conversion**: Commission values arrive in dollars, stored as cents (*100) downstream

## Related Schemas

- **AffiliateCommission**: Destination for processed commission data (ClosedPositionFromEtoro_ADF, CustomerAggregatedData_ADF)
- **History**: Destination for position bridge records (ClosedPosition_ADF)
- **Dictionary**: Lookup tables referenced by RevsharePositionSummary columns (PlayerLevel, Country, etc.)

## JIRA Reference

- **PART-5265**: Original implementation ticket by Noga (Feb 2026). Created the entire BILoad schema as part of the ADF pipeline migration.
