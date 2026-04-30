# Trade.SYN_ExecuteAllFeeJobs

> Synonym pointing to the ExecuteAllFeeJobs stored procedure in the FeesProcess database, enabling the Trade schema to invoke the central fee processing job orchestrator.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [FeesProcess].[etoro].[Trade].[ExecuteAllFeeJobs] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SYN_ExecuteAllFeeJobs is a synonym pointing to the ExecuteAllFeeJobs stored procedure in the FeesProcess database. This is the central orchestrator that triggers all fee calculation and processing jobs - including overnight fees, weekend fees, and other recurring charges applied to trading positions.

Unlike most other synonyms in this batch (which point to tables), this synonym targets a stored procedure. It allows the Trade schema to invoke the fee processing pipeline via a simple two-part name, abstracting the cross-database call.

Used by Trade.GetPositionsForFeeProcess, which prepares position data for fee calculations and then invokes this synonym to execute the actual fee processing.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This synonym targets a procedure, not a table - business logic resides in the target procedure.

---

## 3. Data Overview

N/A for synonym (targets a stored procedure, not a table).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [FeesProcess].[etoro].[Trade].[ExecuteAllFeeJobs]. A stored procedure that orchestrates all fee calculation jobs across the platform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [FeesProcess].[etoro].[Trade].[ExecuteAllFeeJobs] | Synonym target | Cross-database reference to the fee processing orchestrator procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | EXEC | Caller | Invokes this synonym to trigger fee processing after preparing position data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SYN_ExecuteAllFeeJobs (synonym)
  +-- [FeesProcess].[etoro].[Trade].[ExecuteAllFeeJobs] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [FeesProcess].[etoro].[Trade].[ExecuteAllFeeJobs] | Remote Stored Procedure | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Stored Procedure | Calls via EXEC to trigger fee processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute fee processing (USE WITH CAUTION - production impact)
```sql
-- EXEC Trade.SYN_ExecuteAllFeeJobs  -- Uncomment only in appropriate environment
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'SYN_ExecuteAllFeeJobs' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SYN_ExecuteAllFeeJobs') AS ObjectID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SYN_ExecuteAllFeeJobs | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SYN_ExecuteAllFeeJobs.sql*
