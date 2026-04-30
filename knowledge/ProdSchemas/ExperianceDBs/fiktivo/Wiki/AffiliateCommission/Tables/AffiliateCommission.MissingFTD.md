# AffiliateCommission.MissingFTD

> Holds JSON records of first-time deposits (FTDs) that failed initial processing, enabling retry and reconciliation of missed affiliate commission events.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CID + GCID (logical composite key, no PK defined) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

MissingFTD is a reconciliation table that captures first-time deposit (FTD) events that were not properly processed by the main credit commission pipeline. When the system detects that an FTD was missed - for example, because the Credit record was not created, or the commission was not calculated - the FTD details are stored here as a JSON payload for later reprocessing.

This table exists as a safety net for the critical FTD workflow. First deposits are the most important commission event because they represent customer acquisition (CPA model). Missing an FTD means an affiliate might not get paid for acquiring a customer, which directly impacts partner relationships and contractual obligations.

The table has 201 rows, all marked as Processed. Data shows FTDs from January 2024 with standard deposit amounts ($85 USD) and a $2 fee. The JSON format allows the original deposit details to be preserved exactly as they arrived from the payment system, enabling faithful replay.

---

## 2. Business Logic

### 2.1 FTD Recovery Workflow

**What**: Missing FTDs are captured, stored as JSON, and reprocessed by a dedicated recovery procedure.

**Columns/Parameters Involved**: `CID`, `GCID`, `FTDJson`, `Processed`

**Rules**:
- GetMissingFTD identifies FTDs that were not processed (detection logic in the SP)
- Missing FTDs are inserted with Processed = 0 (or NULL)
- UpdateMissingFTD reprocesses the JSON payload and sets Processed = 1
- The JSON contains: GCID, AccountTypeId, AccountId, TransactionDate, TransactionId, ConvertedAmount (AmountInUsd), Fee

---

## 3. Data Overview

| CID | GCID | FTDJson (parsed) | Processed | Meaning |
|---|---|---|---|---|
| -1 | 1983586 | $85 deposit, $2 fee, 2024-01-30 | 1 | CID=-1 indicates the customer mapping was unresolved at detection time. GCID 1983586 is the global identifier. Successfully reprocessed. |
| 100 | 1983642 | $85 deposit, $2 fee, 2024-01-21 | 1 | Low CID suggests a test or early customer. Same deposit pattern ($85 + $2 fee). |
| 150 | 1983690 | $85 deposit, $2 fee, 2024-01-21 | 1 | Same batch of missing FTDs. Uniform $85 amount suggests a minimum deposit threshold or test data. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID. Can be -1 when the CID mapping was not yet resolved at detection time (GCID is the reliable identifier). Nullable because the customer mapping may not exist. |
| 2 | GCID | int | YES | - | CODE-BACKED | Global Customer ID. Cross-provider customer identifier. More reliable than CID for identifying the customer when CID is -1 or unresolved. |
| 3 | FTDJson | nvarchar(max) | YES | - | CODE-BACKED | Full JSON payload of the FTD event. Contains: GCID, AccountTypeId, AccountId, TransactionDate, TransactionId, ConvertedAmount.AmountInUsd, Fee.Amount. Preserved exactly as received from the payment system for faithful replay. |
| 4 | Processed | bit | YES | - | CODE-BACKED | Whether this missing FTD has been successfully reprocessed. NULL or 0 = pending, 1 = reprocessed. All 201 current rows are processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID and GCID link to the external customer system.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.GetMissingFTD | SELECT | Reader | Detects and retrieves missing FTDs |
| AffiliateCommission.UpdateMissingFTD | UPDATE | Modifier | Marks FTDs as processed after recovery |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.GetMissingFTD | Stored Procedure | Reader - retrieves unprocessed FTDs |
| AffiliateCommission.UpdateMissingFTD | Stored Procedure | Modifier - marks as processed |

---

## 7. Technical Details

### 7.1 Indexes

None defined. Heap table - no clustered index. Small enough (201 rows) that table scans are acceptable.

### 7.2 Constraints

None. No PK, no FK, no defaults. All columns nullable.

---

## 8. Sample Queries

### 8.1 Find unprocessed missing FTDs
```sql
SELECT CID, GCID, FTDJson, Processed
FROM AffiliateCommission.MissingFTD WITH (NOLOCK)
WHERE ISNULL(Processed, 0) = 0;
```

### 8.2 Parse JSON details from missing FTDs
```sql
SELECT CID, GCID,
       JSON_VALUE(FTDJson, '$.ConvertedAmount.AmountInUsd') AS AmountUSD,
       JSON_VALUE(FTDJson, '$.Fee.Amount') AS Fee,
       JSON_VALUE(FTDJson, '$.TransactionDate') AS TransactionDate,
       JSON_VALUE(FTDJson, '$.TransactionId') AS TransactionId,
       Processed
FROM AffiliateCommission.MissingFTD WITH (NOLOCK)
ORDER BY GCID;
```

### 8.3 Summary of missing FTD processing
```sql
SELECT ISNULL(Processed, 0) AS IsProcessed,
       COUNT(*) AS FTDCount
FROM AffiliateCommission.MissingFTD WITH (NOLOCK)
GROUP BY ISNULL(Processed, 0);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.MissingFTD | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.MissingFTD.sql*
