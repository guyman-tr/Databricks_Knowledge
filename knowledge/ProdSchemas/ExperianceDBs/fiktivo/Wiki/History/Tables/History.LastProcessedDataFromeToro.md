# History.LastProcessedDataFromeToro

> Audit log of every credit-data batch processed from the eToro platform into the fiktivo affiliate commission aggregation pipeline.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint, IDENTITY) - clustered index |
| **Partition** | No |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

History.LastProcessedDataFromeToro is an ETL audit table that logs every batch of credit transactions fetched from the eToro trading platform and processed into the fiktivo affiliate commission system. Each row represents one execution of the Internal.LoadDataFromeToroToFiktivoAggTable procedure, recording the range of CreditIDs processed and the processing time window.

This table provides a complete operational history of the credit-to-commission ETL pipeline. It is essential for troubleshooting data gaps, diagnosing processing delays, and auditing the completeness of data synchronization between eToro and fiktivo. Without it, operators would have no visibility into which credit batches were processed, when processing occurred, or whether gaps exist in the credit ID range.

Data is written exclusively by Internal.LoadDataFromeToroToFiktivoAggTable at the end of each processing batch. The procedure reads credit transactions (CreditTypeID 3=Open Position, 4=Close Position) from the eToro linked server in batches of 50,000 CreditIDs, processes them into the aggregation tables, then logs the batch here. The companion table Internal.LastProcessedDataFromeToro (note: Internal schema, not History) stores the current watermark (LastProcessedCreditID). The Monitor.AlertForDelayInAggregatedData procedure uses that watermark to detect if processing has fallen behind by more than 6 hours.

---

## 2. Business Logic

### 2.1 Batch Processing Audit Trail

**What**: Each row records one ETL batch execution, forming a sequential, gap-free log of all credit data processed from eToro.

**Columns/Parameters Involved**: `ID`, `FromCreditID`, `ToCreditID`, `StartTime`, `EndTime`

**Rules**:
- Batches are sequential: the ToCreditID of row N should equal or be close to the FromCreditID of row N+1
- Each batch covers up to 50,000 CreditIDs (the @BatchSize parameter)
- StartTime is captured at the beginning of the procedure; EndTime at the time of insert (after processing completes)
- Processing typically completes in under 1 second (EndTime - StartTime < 1s based on sample data)
- A row is inserted even when no matching credits are found in the batch range (gap-skip scenario) - this ensures the audit trail has no gaps in credit ID coverage
- FromCreditID may equal ToCreditID when the batch contained only one credit or the range was skipped

**Diagram**:
```
Credit ID Range: ... 2148250456 ... 2148250483 ... 2148250827 ...
                     |------------|               |---------|
                     Batch ID=1                   Batch ID=2
                     From: 2148250456             From: 2148250827
                     To:   2148250483             To:   2148250827
                     Start: 10:27:15              Start: 08:20:01
                     End:   10:27:16              End:   08:20:02
```

---

## 3. Data Overview

| ID | FromCreditID | ToCreditID | StartTime | EndTime | Meaning |
|---|---|---|---|---|---|
| 1 | 2148250456 | 2148250483 | 2021-03-03 10:27:15 | 2021-03-03 10:27:16 | First batch ever processed - 27 credits in the range, completed in ~0.5 seconds |
| 2 | 2148250827 | 2148250827 | 2023-01-04 08:20:01 | 2023-01-04 08:20:02 | Single-credit batch - FromCreditID equals ToCreditID, likely a sparse period |
| 8 | 2148250903 | 2148250904 | 2023-01-04 13:08:01 | 2023-01-04 13:08:01 | Typical small batch (2 credits) during normal operations |
| 284819 | 12968690192 | 12968740192 | 2024-08-14 08:18:00 | 2024-08-14 08:18:00 | Recent batch near the end of the dataset - 50,000 credit ID range per batch, sub-second completion |
| 284821 | 12968790192 | 12968840192 | 2024-08-14 08:22:00 | 2024-08-14 08:22:01 | Latest batch recorded - ~2 minute intervals between batches at this volume |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO (IDENTITY) | Auto-increment | CODE-BACKED | Sequential row identifier (IDENTITY(1,1)). Each value represents one ETL batch execution. Currently at ~285K, meaning ~285K batches have been processed since inception in 2021. |
| 2 | FromCreditID | bigint | YES | - | CODE-BACKED | Starting CreditID of the batch range processed in this execution. Corresponds to the previous batch's ToCreditID (watermark). When no matching credits exist in a range, this records the watermark value at the start of the skip. Nullable but always populated in practice. |
| 3 | ToCreditID | bigint | YES | - | CODE-BACKED | Ending CreditID of the batch range processed. Set to the MAX(CreditID) found within the batch range, or to PreviousLastCreditID + BatchSize when no credits of type 3 or 4 exist in the range. When FromCreditID = ToCreditID, only one credit or no credits were found. |
| 4 | StartTime | datetime | YES | - | CODE-BACKED | UTC timestamp captured at the very start of the Internal.LoadDataFromeToroToFiktivoAggTable procedure execution (via GETUTCDATE()). Used to measure processing duration. Nullable but always populated. |
| 5 | EndTime | datetime | YES | - | CODE-BACKED | UTC timestamp captured at the moment this audit row is inserted, after all batch processing is complete (via GETUTCDATE()). EndTime - StartTime = total processing time for the batch. Typically under 1 second. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FromCreditID / ToCreditID | eToro History.ActiveCredit (external) | Implicit FK | References CreditID values from the eToro platform's credit transaction log accessed via linked server |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.LoadDataFromeToroToFiktivoAggTable | INSERT | WRITER | Inserts one audit row per batch execution to record the credit range processed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LastProcessedDataFromeToro (table)
```

This table has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.LoadDataFromeToroToFiktivoAggTable | Stored Procedure | WRITER - inserts audit rows after each credit batch is processed |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX_History_LastProcessedDataFromeToro | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None. No primary key constraint (though the clustered index on ID provides uniqueness via IDENTITY), no foreign keys, no check constraints.

Note: Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 Check the latest processing batch
```sql
SELECT TOP 1 *
FROM History.LastProcessedDataFromeToro WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Find processing gaps (batches where FromCreditID does not match previous ToCreditID)
```sql
SELECT curr.ID, prev.ToCreditID AS PrevTo, curr.FromCreditID AS CurrFrom,
       curr.FromCreditID - prev.ToCreditID AS GapSize
FROM History.LastProcessedDataFromeToro curr WITH (NOLOCK)
JOIN History.LastProcessedDataFromeToro prev WITH (NOLOCK)
  ON curr.ID = prev.ID + 1
WHERE curr.FromCreditID <> prev.ToCreditID
ORDER BY curr.ID DESC
```

### 8.3 Analyze processing frequency and duration
```sql
SELECT TOP 20 ID, FromCreditID, ToCreditID,
       ToCreditID - FromCreditID AS CreditRange,
       DATEDIFF(MILLISECOND, StartTime, EndTime) AS ProcessingMs,
       StartTime, EndTime
FROM History.LastProcessedDataFromeToro WITH (NOLOCK)
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LastProcessedDataFromeToro | Type: Table | Source: fiktivo/History/Tables/History.LastProcessedDataFromeToro.sql*
