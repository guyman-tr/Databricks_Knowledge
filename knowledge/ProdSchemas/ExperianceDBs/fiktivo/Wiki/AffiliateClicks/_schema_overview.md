# AffiliateClicks Schema Overview

> Affiliate tracking link click and impression aggregation system - captures, stores, and manages daily aggregated counts for affiliate performance reporting in admin and portal dashboards.

## Purpose

The AffiliateClicks schema supports the affiliate click and impression tracking feature, which allows the platform to count clicks and impressions on affiliate tracking links and present them in admin and portal reports. The data is aggregated on a 24-hour daily resolution per affiliate/banner/campaign/country combination.

## Architecture

```
Affiliate Tracking Links (user clicks/views)
    |
    | Event notifications
    v
aff-clicksimp AKS Service (Partners Team)
    |
    | Aggregates on 24H daily resolution
    | Batches into TVP
    v
+------------------------------------------------------------+
|  AffiliateClicks Schema                                    |
|                                                            |
|  AffiliateClicksImpType (UDT)                             |
|    = Data contract for batch insert                        |
|                                                            |
|  UpdateAffiliateClicks (SP)                                |
|    = Deduplicating batch INSERT (LEFT JOIN anti-pattern)   |
|              |                                             |
|              v                                             |
|  ClicksImpressionsAggregation (Table)                     |
|    = Main fact table, partitioned by AffiliateID%100       |
|    = PAGE compressed, clustered on UpdateDate              |
|              |                                             |
|              v                                             |
|  DeleteClicksImpressionsAggregationByDate (SP)            |
|    = 6-month retention purge, batched deletes              |
|              |                                             |
|              v                                             |
|  ClicksImpressionsAggregationDeleteLog (Table)             |
|    = Purge execution audit log                             |
+------------------------------------------------------------+
    |
    | Read by admin/portal reporting dashboards
    v
Affiliate Performance Reports
```

## Data Flow

1. Users click or view affiliate tracking links on the web
2. The **aff-clicksimp** AKS service receives event notifications
3. The service aggregates events by affiliate + banner + campaign + country + date (24H resolution)
4. Aggregated batches are passed via **AffiliateClicksImpType** TVP to **UpdateAffiliateClicks**
5. The procedure deduplicates via LEFT JOIN and inserts only new rows into **ClicksImpressionsAggregation**
6. A scheduled job runs **DeleteClicksImpressionsAggregationByDate** every ~30 minutes to purge data older than 6 months
7. Admin and portal dashboards query the aggregation table for affiliate performance reports

## Object Summary

| Object | Type | Role |
|--------|------|------|
| AffiliateClicksImpType | UDT | Data contract: TVP for batch insert from aff-clicksimp service |
| ClicksImpressionsAggregation | Table | Main fact table: daily click/impression counts, partitioned, PAGE compressed |
| ClicksImpressionsAggregationDeleteLog | Table | Audit: purge execution logging |
| UpdateAffiliateClicks | SP | Writer: deduplicating batch INSERT via LEFT JOIN anti-pattern |
| DeleteClicksImpressionsAggregationByDate | SP | Purger: 6-month retention, batched DELETE with logging |

## Key Design Patterns

- **INSERT-only (no updates)**: Data is never modified after insertion (PART-2546)
- **LEFT JOIN anti-pattern deduplication**: Prevents duplicate aggregation rows on 6-column composite key
- **Partition-aware queries**: PartitionCol100 = AffiliateID%100 with PS_Mod100 scheme
- **Batched purge**: DELETE TOP(5000) in WHILE loop to avoid lock escalation
- **Binary collation**: Campaign and AdditionalData use Latin1_General_BIN for exact matching

## Team and Service

- **Team**: Partners Team
- **Service**: aff-clicksimp (AKS)
- **Code repo**: AffiliateClicks (GitHub eToro)
- **Key contributors**: Gil Haba (PART-2689, PART-2546, PART-3693), Noga (purge procedure)

## JIRA References

- **PART-2689**: Original implementation - Affiliate Clicks feature (Feb 2024)
- **PART-2546**: Modified to load daily without updates (Oct 2024)
- **PART-3693**: Added AdditionalData column (Nov 2024)
