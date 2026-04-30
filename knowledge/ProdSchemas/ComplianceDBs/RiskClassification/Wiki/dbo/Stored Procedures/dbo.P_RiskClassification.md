# dbo.P_RiskClassification

> Core risk classification processing procedure that merges staged scores from T_ScoresTemporary into T_Scores, then pivots all scores per customer into the denormalized T_RiskClassification wide-column table, including automatic schema evolution for new risk parameters.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - batch processor |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the central data processing procedure for the risk classification system. It performs the complete pipeline of accepting new risk scores from the staging area and producing the final denormalized risk classification data. The procedure has three main phases: (1) MERGE staged scores into the normalized T_Scores table, (2) dynamically add any new parameter columns to T_RiskClassification if needed, and (3) pivot the normalized scores into T_RiskClassification's wide-column format.

Without this procedure, new risk scores calculated by the external engine would sit in the staging table indefinitely and never be reflected in the queryable views. This is the "engine" that drives the entire risk classification data pipeline.

Created by Geri Reshef in 2019-12 (RD-16450) and enhanced in 2020-01 for the compliance reporting version.

---

## 2. Business Logic

### 2.1 MERGE: Staged Scores into T_Scores

**What**: Efficiently applies score changes from the staging table to the permanent normalized scores.

**Columns/Parameters Involved**: T_ScoresTemporary (source), T_Scores (target)

**Rules**:
- MERGE matches on `GCID + RiskClassificationParameterID`
- UPDATE when matched AND any column changed: uses `ISNULL(Source.Col, sentinel) <> ISNULL(Target.Col, sentinel)` for CID (-999), RegulationID (-999), RiskScore (-999), Value ('')
- INSERT when not matched by target: new customer-parameter combinations
- Does NOT delete from T_Scores when not matched by source (scores are persistent)
- Temporal versioning on T_Scores automatically captures the previous version in History.T_Scores

### 2.2 Dynamic Schema Evolution

**What**: Automatically adds new score columns to T_RiskClassification when new parameters appear in Dictionary.

**Columns/Parameters Involved**: Dictionary.RiskClassificationParameter, T_RiskClassification DDL

**Rules**:
- Compares Dictionary.RiskClassificationParameter names against existing `*_Value` columns in T_RiskClassification (via `sys.columns`)
- For each parameter name NOT yet in T_RiskClassification: executes `ALTER TABLE T_RiskClassification ADD [{Name}_RiskScore] INT, [{Name}_Value] VARCHAR(50)`
- Only considers parameters with ID < 9999 (excludes Final Score)
- Uses dynamic SQL with `Col_Length` checks to avoid errors if column already exists
- This means adding a new risk parameter to Dictionary automatically propagates to the wide table without manual DDL changes

### 2.3 Pivot: Normalized Scores to Wide Table

**What**: Converts per-row scores in V_Scores into per-column format in T_RiskClassification.

**Columns/Parameters Involved**: V_Scores (source), T_RiskClassification (target), temp table #T_RiskClassification

**Rules**:
- Builds a temp table #T_RiskClassification by pivoting V_Scores data: `MAX(IIF(RCP='ParameterName', RiskScore, NULL)) AS [ParameterName_RiskScore]` for each parameter
- Only processes customers NOT already in T_RiskClassification with the same score and regulation (change detection via NOT EXISTS subquery)
- The NOT EXISTS checks: same GCID, same RiskScore (from parameter 9999), same RegulationID
- After building the temp table: DELETE existing rows for those GCIDs from T_RiskClassification, then INSERT all columns from the temp table
- This DELETE+INSERT pattern (rather than UPDATE) ensures temporal versioning captures the full change

**Diagram**:
```
T_ScoresTemporary --MERGE--> T_Scores
                                |
                           V_Scores (enriched)
                                |
                           PIVOT (MAX+IIF per parameter)
                                |
                     #T_RiskClassification (temp)
                                |
                   DELETE+INSERT --> T_RiskClassification
```

### 2.4 Change Detection for Pivot

**What**: Only re-pivots customers whose aggregate score or regulation changed.

**Columns/Parameters Involved**: `RiskScore` (parameter 9999), `RegulationID`

**Rules**:
- Uses `NOT EXISTS` subquery against T_RiskClassification
- A customer is re-pivoted if:
  - They are NOT in T_RiskClassification yet (new customer), OR
  - Their current RiskScore in T_RiskClassification differs from parameter 9999 in T_Scores, OR
  - Their RegulationID changed
- This avoids re-pivoting customers where only non-final-score parameters changed but the aggregate result is the same

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No parameters. The procedure operates on the staging table T_ScoresTemporary and produces output in T_Scores and T_RiskClassification.

**Internal operations**:
- Reads: T_ScoresTemporary, V_Scores, T_RiskClassification, T_Scores, Dictionary.RiskClassificationParameter, sys.columns
- Writes: T_Scores (MERGE), T_RiskClassification (ALTER TABLE, DELETE, INSERT)
- Temp tables: #T_RiskClassification

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MERGE source | dbo.T_ScoresTemporary | Reader | Staged scores to merge |
| MERGE target | dbo.T_Scores | Writer | Permanent normalized scores |
| SELECT FROM | dbo.V_Scores | Reader | Enriched scores for pivot |
| NOT EXISTS | dbo.T_RiskClassification | Reader | Change detection |
| DELETE+INSERT | dbo.T_RiskClassification | Writer | Wide-format score output |
| ALTER TABLE | dbo.T_RiskClassification | DDL | Dynamic column addition |
| SELECT FROM | Dictionary.RiskClassificationParameter | Reader | New parameter discovery |

### 5.2 Referenced By (other objects point to this)

Called by external BI/risk processing pipeline after T_ScoresTemporary is loaded.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.P_RiskClassification (procedure)
+-- dbo.T_ScoresTemporary (table) [MERGE source]
+-- dbo.T_Scores (table) [MERGE target]
+-- dbo.V_Scores (view) [pivot source]
|   +-- dbo.T_Scores (table)
|   +-- Dictionary.Regulation (table)
|   +-- Dictionary.RiskClassificationParameter (table)
|   +-- Dictionary.RiskClassificationRegulation (table)
+-- dbo.T_RiskClassification (table) [DELETE+INSERT target]
+-- Dictionary.RiskClassificationParameter (table) [schema evolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.T_ScoresTemporary | Table | MERGE source |
| dbo.T_Scores | Table | MERGE target |
| dbo.V_Scores | View | Pivot source (FROM) |
| dbo.T_RiskClassification | Table | Change detection (NOT EXISTS) + DELETE+INSERT target + ALTER TABLE |
| Dictionary.RiskClassificationParameter | Table | New parameter discovery |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Called by external pipeline.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the full risk classification pipeline
```sql
EXEC dbo.P_RiskClassification
```

### 8.2 Full pipeline: load -> process -> clear
```sql
-- (external engine loads T_ScoresTemporary)
EXEC dbo.P_RiskClassification
EXEC dbo.TruncateTempTable
```

### 8.3 Verify results after execution
```sql
EXEC dbo.P_RiskClassification
SELECT TOP 10 GCID, RiskScore, RiskScore_Value, BeginTime
FROM dbo.T_RiskClassification WITH (NOLOCK)
ORDER BY BeginTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.P_RiskClassification | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.P_RiskClassification.sql*
