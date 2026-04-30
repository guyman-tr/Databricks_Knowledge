# Trade.SYN_TruncateFeeNightProcess

> Synonym pointing to the TruncateFeeNightProcess stored procedure in the FeesProcess database, enabling the Trade schema to clear the overnight fee staging table before each new fee processing cycle.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [FeesProcess].[etoro].[Trade].[TruncateFeeNightProcess] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SYN_TruncateFeeNightProcess is a synonym that provides local access to the TruncateFeeNightProcess stored procedure in the FeesProcess database. This procedure truncates the FeeNightProcess staging table, clearing it of all previous cycle data before a fresh batch of positions is loaded for overnight fee calculation.

This synonym is the cleanup counterpart to Trade.SYN_FeeNightProcess (which points to the staging table itself). Together they form the staging pipeline: first truncate (via this synonym), then populate (via SYN_FeeNightProcess), then process fees. The separate database architecture isolates the computationally intensive fee calculations from the core trading database.

Trade.GetPositionsForFeeProcess is the primary consumer. Before inserting eligible positions into the staging table, it calls this synonym to ensure the table starts empty for each nightly cycle.

---

## 2. Business Logic

### 2.1 Fee Processing Staging Lifecycle

**What**: The overnight fee staging table follows a truncate-populate-process cycle each night.

**Columns/Parameters Involved**: N/A (synonym targets a procedure)

**Rules**:
- Step 1: Trade.GetPositionsForFeeProcess calls SYN_TruncateFeeNightProcess to clear the staging table
- Step 2: Same procedure inserts eligible positions into SYN_FeeNightProcess
- Step 3: FeesProcess engine reads the staged data and calculates fees

**Diagram**:
```
GetPositionsForFeeProcess
    |
    +--EXEC--> SYN_TruncateFeeNightProcess (clear staging)
    |
    +--INSERT--> SYN_FeeNightProcess (populate staging)
    |
    +--EXEC--> SYN_ExecuteAllFeeJobs (trigger processing)
```

---

## 3. Data Overview

N/A for synonym (targets a stored procedure).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [FeesProcess].[etoro].[Trade].[TruncateFeeNightProcess]. A stored procedure that truncates the FeeNightProcess staging table, clearing all data from the previous overnight fee cycle. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [FeesProcess].[etoro].[Trade].[TruncateFeeNightProcess] | Synonym target | Cross-database reference to the staging table cleanup procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | EXEC | Caller | Invokes this synonym to truncate the staging table before populating it with new position data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SYN_TruncateFeeNightProcess (synonym)
  +-- [FeesProcess].[etoro].[Trade].[TruncateFeeNightProcess] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [FeesProcess].[etoro].[Trade].[TruncateFeeNightProcess] | Remote Stored Procedure | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Stored Procedure | Calls to clear fee staging table before each nightly cycle |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'SYN_TruncateFeeNightProcess'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SYN_TruncateFeeNightProcess') AS ObjectID
```

### 8.3 Execute staging cleanup (USE WITH CAUTION)
```sql
-- EXEC Trade.SYN_TruncateFeeNightProcess  -- Uncomment only in appropriate environment
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SYN_TruncateFeeNightProcess | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SYN_TruncateFeeNightProcess.sql*
