# AffiliateClicks.UpdateAffiliateClicks

> Batch insert procedure that receives aggregated click/impression data from the aff-clicksimp service via a table-valued parameter and inserts only new rows (deduplication via LEFT JOIN anti-pattern) into the main aggregation table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateClicks |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into ClicksImpressionsAggregation with deduplication |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateClicks.UpdateAffiliateClicks is the sole entry point for writing click and impression data into the AffiliateClicks.ClicksImpressionsAggregation table. The aff-clicksimp AKS service (Partners Team) batches daily aggregated click/impression counts and calls this procedure with a table-valued parameter containing the batch. The procedure deduplicates against existing data and inserts only genuinely new rows.

Despite the "Update" name, this procedure performs INSERT-only operations - no UPDATE (per PART-2546: "Modify to load daily without updates"). The name is historical from an earlier design that included MERGE/UPDATE logic. The current behavior is strictly additive.

The aff-clicksimp service calls this procedure after aggregating click and impression notifications from affiliate tracking links on a 24-hour daily resolution. The procedure runs within a transaction, returns the count of inserted rows, and rolls back on failure.

---

## 2. Business Logic

### 2.1 LEFT JOIN Anti-Pattern Deduplication

**What**: New rows are inserted only if no matching row exists in the target table, using a LEFT JOIN with IS NULL check.

**Columns/Parameters Involved**: `@AffiliateClicksImp` (TVP), all columns

**Rules**:
- The TVP (@AffiliateClicksImp) is LEFT JOINed to ClicksImpressionsAggregation on 7 key columns:
  - PartitionCol100 = AffiliateID % 100 (partition alignment)
  - AffiliateID, BannerID, Campaign, AdditionalData, UpdateDate, CountryID
- WHERE B.AffiliateID IS NULL selects only unmatched rows (new data)
- Matched rows (duplicates) are silently discarded
- The procedure returns @@ROWCOUNT as the count of inserted rows
- The entire operation runs within a single transaction

**Diagram**:
```
@AffiliateClicksImp (TVP)              ClicksImpressionsAggregation
+-----------+----------+------+         +-----------+----------+------+
| AffID=100 | Banner=1 | ...  |   LEFT  | AffID=100 | Banner=1 | ...  |
| AffID=100 | Banner=2 | ...  |   JOIN  |           |          |      |
| AffID=200 | Banner=1 | ...  |   ON 7  |           |          |      |
+-----------+----------+------+   cols   +-----------+----------+------+
                                           |
                                           | WHERE B.AffiliateID IS NULL
                                           v
                                    INSERT only rows #2 and #3
                                    (row #1 already exists)
```

### 2.2 Partition-Aware JOIN

**What**: The deduplication JOIN includes the computed partition column for partition elimination.

**Columns/Parameters Involved**: `PartitionCol100`, `AffiliateID`

**Rules**:
- JOIN condition includes: B.PartitionCol100 = A.AffiliateID % 100
- This enables SQL Server to probe only the relevant partition instead of scanning all 100 partitions
- The AffiliateID % 100 computation is done inline on the TVP side (matching the PERSISTED computed column)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateClicksImp | AffiliateClicks.AffiliateClicksImpType | NO | - | CODE-BACKED | READONLY table-valued parameter containing batched click/impression aggregates from the aff-clicksimp service. Each row represents one day's counts for a specific affiliate/banner/campaign/country/additionalData combination. Columns mirror ClicksImpressionsAggregation (minus PartitionCol100). |
| 2 | RETURN value | int | NO | - | CODE-BACKED | Returns @@ROWCOUNT - the number of new rows inserted after deduplication. 0 if all rows in the TVP were duplicates. The application can use this to track insertion success. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateClicksImp | AffiliateClicks.AffiliateClicksImpType | Parameter Type | READONLY TVP defining the input data contract |
| - | AffiliateClicks.ClicksImpressionsAggregation | WRITE (INSERT) + READ (LEFT JOIN) | Target table for insertion; also read for deduplication |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| aff-clicksimp service (external) | - | Caller | AKS service calls this procedure with batched click/impression data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateClicks.UpdateAffiliateClicks (procedure)
+-- AffiliateClicks.AffiliateClicksImpType (user defined type)
+-- AffiliateClicks.ClicksImpressionsAggregation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateClicks.AffiliateClicksImpType | User Defined Type | Parameter type for @AffiliateClicksImp |
| AffiliateClicks.ClicksImpressionsAggregation | Table | INSERT target + LEFT JOIN source for deduplication |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| aff-clicksimp (external AKS service) | External | Calls this procedure with batched TVP data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a batch of click data
```sql
DECLARE @Data AffiliateClicks.AffiliateClicksImpType
INSERT INTO @Data (AffiliateID, BannerID, Campaign, UpdateDate, CountryID, ClicksCount, ImpressionsCount, AdditionalData)
VALUES (12345, 100, 'spring_2026', '2026-04-13', 1, 50, 1200, ''),
       (12345, 101, 'spring_2026', '2026-04-13', 1, 25, 600, '')
DECLARE @Inserted INT
EXEC @Inserted = AffiliateClicks.UpdateAffiliateClicks @AffiliateClicksImp = @Data
SELECT @Inserted AS RowsInserted
```

### 8.2 Test deduplication (run twice - second should return 0)
```sql
DECLARE @Data AffiliateClicks.AffiliateClicksImpType
INSERT INTO @Data VALUES (99999, 999, 'dedup_test', '2026-04-13', 1, 1, 1, '')
DECLARE @R1 INT, @R2 INT
EXEC @R1 = AffiliateClicks.UpdateAffiliateClicks @Data
EXEC @R2 = AffiliateClicks.UpdateAffiliateClicks @Data
SELECT @R1 AS FirstCall, @R2 AS SecondCall -- expect 1, 0
```

### 8.3 Verify inserted data
```sql
SELECT AffiliateID, UpdateDate, Campaign, ClicksCount, ImpressionsCount
FROM AffiliateClicks.ClicksImpressionsAggregation WITH (NOLOCK)
WHERE AffiliateID = 12345
  AND UpdateDate = '2026-04-13'
ORDER BY Campaign
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Clicks and Impressions](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12188942429) | Confluence | Service aggregates click/impression notifications and writes to the table via this procedure |
| [Clicks and Impressions Deployment](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12188516397) | Confluence | Calling service: aff-clicksimp (AKS, Partners Team) |
| PART-2689 (referenced in SQL comments) | Jira | Original implementation (Feb 2024, Gil Haba) |
| PART-2546 (referenced in SQL comments) | Jira | Modified to load daily without updates - INSERT-only pattern (Oct 2024, Gil Haba) |
| PART-3693 (referenced in SQL comments) | Jira | Added AdditionalData to the insert and deduplication key (Nov 2024, Gil Haba) |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence + 3 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateClicks.UpdateAffiliateClicks | Type: Stored Procedure | Source: fiktivo/AffiliateClicks/Stored Procedures/AffiliateClicks.UpdateAffiliateClicks.sql*
