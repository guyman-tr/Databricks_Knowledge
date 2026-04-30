# AffiliateCommission.GetMissingFTD

> Retrieves unprocessed missing First-Time Deposit (FTD) JSON records for reprocessing by the commission system.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FTDJson from unprocessed MissingFTD rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetMissingFTD retrieves FTD (First-Time Deposit) records that were missed during normal processing and need to be reprocessed. The MissingFTD table acts as a retry queue for deposit events that failed initial commission processing. Each row contains the full event payload as JSON (FTDJson), which can be re-submitted to the commission pipeline.

This procedure exists as a recovery mechanism. When the normal deposit processing pipeline misses a first-time deposit (due to timing issues, data availability gaps, or transient failures), the missing deposit is recorded in MissingFTD with Processed = 0. A scheduled job calls this procedure to retrieve the unprocessed records for retry. After successful reprocessing, UpdateMissingFTD marks them as Processed = 1.

---

## 2. Business Logic

### 2.1 Unprocessed Queue Read

**What**: Returns all FTD JSON payloads that haven't been successfully reprocessed yet.

**Columns/Parameters Involved**: `Processed`, `FTDJson`

**Rules**:
- Selects FTDJson WHERE Processed = 0
- No pagination or batch limit - returns all unprocessed records
- The FTDJson column contains the full event payload needed for reprocessing
- Companion procedure UpdateMissingFTD sets Processed = 1 after successful reprocessing

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FTDJson | nvarchar(max) | - | - | CODE-BACKED | Full JSON payload of the missing FTD event. Contains all data needed to resubmit the deposit to the commission pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.MissingFTD | READ (SELECT) | Retrieves unprocessed FTD records (Processed = 0) |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by a scheduled reprocessing job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetMissingFTD (procedure)
+-- AffiliateCommission.MissingFTD (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.MissingFTD | Table | SELECT WHERE Processed = 0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (FTD reprocessing job) | External | Reads missing FTDs for retry |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all unprocessed missing FTDs
```sql
EXEC [AffiliateCommission].[GetMissingFTD]
```

### 8.2 Count unprocessed vs processed missing FTDs
```sql
SELECT Processed, COUNT(*) AS RecordCount
FROM [AffiliateCommission].[MissingFTD] WITH (NOLOCK)
GROUP BY Processed
```

### 8.3 View recent missing FTD entries
```sql
SELECT ID, FTDJson, Processed
FROM [AffiliateCommission].[MissingFTD] WITH (NOLOCK)
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-4318: Created procedure (2025-04-27)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetMissingFTD | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetMissingFTD.sql*
