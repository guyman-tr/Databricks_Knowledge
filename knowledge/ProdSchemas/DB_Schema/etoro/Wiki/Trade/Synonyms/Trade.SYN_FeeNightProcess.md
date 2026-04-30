# Trade.SYN_FeeNightProcess

> Synonym pointing to the FeeNightProcess table in the FeesProcess database, enabling the Trade schema to read and write overnight fee processing data without a four-part name.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [FeesProcess].[etoro].[Trade].[FeeNightProcess] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SYN_FeeNightProcess is a synonym that provides local access to the FeeNightProcess table in the FeesProcess database. The FeeNightProcess table holds staged position data used during the nightly overnight fee calculation cycle - the process that charges or credits swap/rollover fees to positions held past market close.

This synonym exists because the overnight fee calculation pipeline runs in a separate database (FeesProcess) for isolation. The Trade schema needs to populate that table with eligible positions before fee processing begins, and this synonym allows procedures in the Trade database to INSERT into the remote table using a simple two-part name.

Trade.GetPositionsForFeeProcess is the primary consumer. It gathers eligible open positions and writes them to this synonym's target table. After population, the fee processing engine reads the data, calculates fees, and applies them. A companion synonym (Trade.SYN_TruncateFeeNightProcess) handles cleanup by truncating the table before the next cycle.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This synonym targets a staging table for the fee pipeline - business logic resides in the fee processing procedures.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [FeesProcess].[etoro].[Trade].[FeeNightProcess]. A staging table that holds position data for the nightly overnight fee calculation cycle. Populated by Trade.GetPositionsForFeeProcess with eligible open positions before each fee run. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [FeesProcess].[etoro].[Trade].[FeeNightProcess] | Synonym target | Cross-database reference to the overnight fee staging table in the FeesProcess database |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | INSERT/SELECT | Writer | Populates the staging table with eligible open positions for overnight fee calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SYN_FeeNightProcess (synonym)
  +-- [FeesProcess].[etoro].[Trade].[FeeNightProcess] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [FeesProcess].[etoro].[Trade].[FeeNightProcess] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Stored Procedure | Writes position data into this synonym for overnight fee processing |

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
WHERE  name = 'SYN_FeeNightProcess'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SYN_FeeNightProcess') AS ObjectID
```

### 8.3 Preview staged fee data (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SYN_FeeNightProcess WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SYN_FeeNightProcess | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SYN_FeeNightProcess.sql*
