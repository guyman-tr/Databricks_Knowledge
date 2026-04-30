# Trade.GetDataForCloseMirrorPositionsMOTElad

> Natively compiled procedure that returns position IDs with non-terminal close executions for a customer - a subset of GetDataForCloseMirrorPositions optimized for memory-optimized tables.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure (Natively Compiled) |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDataForCloseMirrorPositionsMOTElad is a natively compiled stored procedure that performs a single check from the broader GetDataForCloseMirrorPositions workflow: it identifies positions for a given customer that have close executions currently in flight (non-terminal status). "MOT" in the name refers to Memory-Optimized Tables, and "Elad" indicates the developer.

This procedure exists as an optimized, atomic version of Result Set 3 from Trade.GetDataForCloseMirrorPositions. It runs with SNAPSHOT isolation and SCHEMABINDING on memory-optimized tables (Trade.CloseExecutionPlan, Trade.OrderForClose, Dictionary.OrderForExecutionStatus) for maximum throughput. It is used when the calling service only needs the in-flight execution check and wants sub-millisecond response times.

The procedure joins Trade.CloseExecutionPlan -> Trade.OrderForClose -> Dictionary.OrderForExecutionStatus where IsTerminal=0 for the given CID.

---

## 2. Business Logic

### 2.1 In-Flight Close Execution Detection

**What**: Finds positions with close orders that haven't reached a terminal state yet.

**Columns/Parameters Involved**: `@CID`, `IsTerminal`, `StatusID`

**Rules**:
- Joins CloseExecutionPlan -> OrderForClose on OrderID
- Joins OrderForClose -> OrderForExecutionStatus on StatusID
- Filters where IsTerminal = 0 (execution still in progress)
- Returns only PositionID - the minimum information needed to check for conflicts

**Diagram**:
```
Trade.CloseExecutionPlan (CID = @CID)
  |
  JOIN Trade.OrderForClose (on OrderID)
  |
  JOIN Dictionary.OrderForExecutionStatus (on StatusID, IsTerminal = 0)
  |
  Output: PositionID (in-flight close positions)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | YES | NULL | CODE-BACKED | Customer ID to check for in-flight close executions. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position ID with a non-terminal close execution in progress. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Trade.CloseExecutionPlan | FROM | Close execution plans for the customer |
| OrderID | Trade.OrderForClose | JOIN | Close order details |
| StatusID | Dictionary.OrderForExecutionStatus | JOIN | Terminal status check |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDataForCloseMirrorPositionsMOTElad (procedure)
+-- Trade.CloseExecutionPlan (table, memory-optimized)
+-- Trade.OrderForClose (table, memory-optimized)
+-- Dictionary.OrderForExecutionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseExecutionPlan | Table | FROM - close execution plans |
| Trade.OrderForClose | Table | JOIN - close order details |
| Dictionary.OrderForExecutionStatus | Table | JOIN - terminal status flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- **Natively compiled** with SCHEMABINDING
- Executes as OWNER
- ATOMIC with SNAPSHOT isolation
- Language: us_english

---

## 8. Sample Queries

### 8.1 Check in-flight close executions for a customer

```sql
EXEC Trade.GetDataForCloseMirrorPositionsMOTElad @CID = 12345;
```

### 8.2 Compare with the non-MOT equivalent

```sql
-- Full version (6 result sets):
EXEC Trade.GetDataForCloseMirrorPositions @mirrorId = 5001, @cid = 12345;

-- MOT version (single result set - in-flight closes only):
EXEC Trade.GetDataForCloseMirrorPositionsMOTElad @CID = 12345;
```

### 8.3 Direct query equivalent

```sql
SELECT  cep.PositionID
FROM    Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.OrderForClose ofc WITH (NOLOCK) ON cep.OrderID = ofc.OrderID
INNER JOIN Dictionary.OrderForExecutionStatus os WITH (NOLOCK) ON ofc.StatusID = os.ID
WHERE   cep.CID = 12345
        AND os.IsTerminal = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDataForCloseMirrorPositionsMOTElad | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDataForCloseMirrorPositionsMOTElad.sql*
