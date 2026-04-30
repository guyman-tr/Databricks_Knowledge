# Customer.GetManyAggregatedInfo_RAN

> Rate-limiting wrapper around GetManyAggregatedInfo that detects suspicious large-batch requests with nearly sequential IDs and returns an empty result set instead of executing the expensive query.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns same as GetManyAggregatedInfo (with rate limiting) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyAggregatedInfo_RAN is a security/performance wrapper around Customer.GetManyAggregatedInfo. It detects potentially abusive batch requests where someone is trying to enumerate all customer data by sending large lists of nearly-sequential GCIDs. When such a pattern is detected, it returns an empty result set instead of executing the expensive aggregated info query.

This procedure exists to prevent data scraping or denial-of-service attacks via the aggregated info endpoint. Legitimate batch requests typically contain non-sequential customer IDs (e.g., from a shopping cart or watchlist), while scraping attempts use sequential ID ranges.

If the request passes the rate-limiting check, the procedure executes the exact same logic as GetManyAggregatedInfo (identical query, same temp tables, same CTEs).

---

## 2. Business Logic

### 2.1 Sequential ID Range Detection (Rate Limiting)

**What**: Detects suspiciously sequential GCID lists and short-circuits with an empty result.

**Columns/Parameters Involved**: `@ids`, COUNT, MAX, MIN

**Rules**:
- Triggers only when COUNT(@ids) > 50 (small batches are always allowed)
- Calculates gap score: MAX(Id) - MIN(Id) + 1 - COUNT(*) 
- If gap score < 5, the IDs are nearly sequential (e.g., 1000-1050 with fewer than 5 gaps)
- On detection: creates a fake IdList with just (-1), calls GetManyAggregatedInfo with this fake list, and RETURNs
- GetManyAggregatedInfo with Id=-1 finds no customers and returns empty result sets
- If gap score >= 5 (legitimate non-sequential batch), falls through to the full query

**Diagram**:
```
@ids (IdList)
  |
  v
COUNT > 50?
  NO --> Execute full query (same as GetManyAggregatedInfo)
  YES --> Check: MAX(Id) - MIN(Id) + 1 - COUNT(*) < 5?
            NO  --> Execute full query
            YES --> DETECTED: Nearly sequential IDs
                    --> EXEC GetManyAggregatedInfo with fake list (-1)
                    --> RETURN empty results
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve aggregated info for. Subject to rate-limiting check. |
| 2-83 | (Same as GetManyAggregatedInfo) | - | - | - | CODE-BACKED | All output columns are identical to GetManyAggregatedInfo when the rate limit is not triggered. See Customer.GetManyAggregatedInfo for full element descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.GetManyAggregatedInfo | EXEC | Delegates to this SP when rate limit is triggered (with fake ID list) |
| (all) | (Same as GetManyAggregatedInfo) | JOIN | When rate limit is not triggered, executes identical query logic |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Rate-limited version of aggregated info retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyAggregatedInfo_RAN (procedure)
+-- Customer.GetManyAggregatedInfo (procedure) [called when rate-limited]
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_ElectronicIdentityCheck (table)
+-- dbo.BlockedCustomerOperations (table)
+-- Ev.CustomerResult (table)
+-- dbo.General_Settings (table)
+-- dbo.Publications (table)
+-- dbo.CustomerClassifiedDocumentsTable (function)
+-- Dictionary.EvProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetManyAggregatedInfo | Stored Procedure | EXEC - called with fake list when rate limit triggers |
| (Same 10 tables as GetManyAggregatedInfo) | Tables/Functions | Used when full query executes |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Rate limit | Business logic | COUNT > 50 AND MAX-MIN+1-COUNT < 5 triggers empty response |
| TRY/CATCH | Error handling | Same error handling as GetManyAggregatedInfo |

---

## 8. Sample Queries

### 8.1 Normal usage (passes rate limit)
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (5432), (9876)  -- Non-sequential
EXEC Customer.GetManyAggregatedInfo_RAN @ids = @ids
```

### 8.2 Would trigger rate limit (sequential range)
```sql
DECLARE @ids dbo.IdList
-- Inserting 51+ nearly-sequential IDs would trigger the rate limit
-- and return empty result sets
INSERT @ids SELECT TOP 51 GCID FROM dbo.Real_Customer WITH (NOLOCK) ORDER BY GCID
EXEC Customer.GetManyAggregatedInfo_RAN @ids = @ids
```

### 8.3 Rate limit check logic
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1000), (1001), (1002), (1003) -- Only 4 items
-- COUNT = 4, which is <= 50, so rate limit check is SKIPPED
-- Full query executes regardless of sequential pattern
EXEC Customer.GetManyAggregatedInfo_RAN @ids = @ids
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 9/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 83 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyAggregatedInfo_RAN | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyAggregatedInfo_RAN.sql*
