# dbo.T_ScoresTemporary

> Staging table that receives batches of recalculated customer risk parameter scores from the external risk engine before they are merged into the permanent T_Scores table via P_RiskClassification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GCID + RiskClassificationParameterID (INT + INT, composite CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is the staging/landing table for the risk classification pipeline. The external risk calculation engine populates this table with recalculated parameter scores for customers whose risk profiles need updating. The `P_RiskClassification` stored procedure then reads from this table, MERGEs the scores into the permanent `T_Scores` table, pivots them into `T_RiskClassification`, and the `TruncateTempTable` procedure clears it for the next batch.

Without this table, the risk calculation engine would need to write directly to the production `T_Scores` table, losing the ability to perform atomic batch processing with change detection. The staging pattern enables: (1) bulk loading by the external engine, (2) efficient MERGE with change detection against T_Scores, (3) clean batch boundaries via TRUNCATE between runs.

The table follows a load-process-truncate cycle: the external BI/risk engine inserts scores, `P_RiskClassification` merges them into T_Scores and pivots to T_RiskClassification, then `TruncateTempTable` clears the staging area. The table currently holds 34 rows, indicating either a small batch in progress or residual data from the last run.

---

## 2. Business Logic

### 2.1 Load-Process-Truncate Pipeline

**What**: Three-phase data pipeline using this table as the staging area between the external risk engine and the permanent risk tables.

**Columns/Parameters Involved**: All columns (same structure as T_Scores minus temporal columns)

**Rules**:
- **Load**: External risk engine INSERTs recalculated scores for target customers
- **Process**: P_RiskClassification reads this table as `Source` in a MERGE against T_Scores as `Target`
- **Truncate**: TruncateTempTable clears the table via TRUNCATE TABLE (DDL operation, no logging)
- Structure intentionally mirrors T_Scores (minus BeginTime/EndTime) for seamless MERGE compatibility

**Diagram**:
```
External Risk Engine
        |
        v
T_ScoresTemporary (staging - LOAD)
        |
        v
P_RiskClassification (MERGE into T_Scores - PROCESS)
        |
        v
TruncateTempTable (TRUNCATE - CLEAR)
```

---

## 3. Data Overview

| GCID | CID | RegulationID | ParameterID | RiskScore | Value | Meaning |
|------|-----|-------------|------------|-----------|-------|---------|
| 451 | 684062 | 2 (FCA) | 2 | 0 | United Kingdom | FCA customer from UK being rescored. Country of Residence onboarding = Low risk (0). UK is a low-risk country under FCA regulation. |
| 451 | 684062 | 2 (FCA) | 3 | 0 | United Kingdom | Same customer, existing-client country score. Also 0 (Low). |
| 451 | 684062 | 2 (FCA) | 5 | 0 | 43 | Same customer, age 43. No risk (age 21-65 range). |

Total: 34 rows currently staged (small batch or residual from last processing run).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of composite PK. Identifies the customer whose scores are being staged for update. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID - secondary identifier. Carried through to T_Scores during MERGE. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulatory jurisdiction. Carried through to T_Scores. FK to Dictionary.Regulation. See [Regulation](_glossary.md#regulation). |
| 4 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter being scored. Part of composite PK. FK to Dictionary.RiskClassificationParameter. See [Risk Classification Parameter](_glossary.md#risk-classification-parameter). |
| 5 | RiskScore | INT | YES | - | VERIFIED | Recalculated risk score for this parameter. Will replace the existing T_Scores value if different. |
| 6 | Value | VARCHAR(100) | YES | - | VERIFIED | The raw value/label used to derive the RiskScore. E.g., "United Kingdom" for country, "43" for age. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Implicit FK | Risk parameter being scored |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.P_RiskClassification | Source (MERGE) | Reader | Uses as MERGE source against T_Scores target |
| dbo.TruncateTempTable | T_ScoresTemporary | Truncator | Clears the table after processing completes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.P_RiskClassification | Stored Procedure | MERGE source - reads staged scores to update T_Scores |
| dbo.TruncateTempTable | Stored Procedure | TRUNCATE - clears staging area after processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ScoresTemporary | CLUSTERED PK | GCID ASC, RiskClassificationParameterID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key. No temporal versioning (staging data is transient).

---

## 8. Sample Queries

### 8.1 Check what's currently staged for processing
```sql
SELECT ST.GCID, ST.RiskClassificationParameterID, P.Name AS Parameter,
       ST.RiskScore, ST.Value
FROM dbo.T_ScoresTemporary ST WITH (NOLOCK)
INNER JOIN Dictionary.RiskClassificationParameter P WITH (NOLOCK)
    ON ST.RiskClassificationParameterID = P.RiskClassificationParameterID
ORDER BY ST.GCID, ST.RiskClassificationParameterID
```

### 8.2 Compare staged scores vs current for pending customers
```sql
SELECT ST.GCID, ST.RiskClassificationParameterID,
       ST.RiskScore AS NewScore, S.RiskScore AS CurrentScore,
       ST.Value AS NewValue, S.Value AS CurrentValue
FROM dbo.T_ScoresTemporary ST WITH (NOLOCK)
LEFT JOIN dbo.T_Scores S WITH (NOLOCK)
    ON ST.GCID = S.GCID AND ST.RiskClassificationParameterID = S.RiskClassificationParameterID
WHERE ISNULL(ST.RiskScore, -999) <> ISNULL(S.RiskScore, -999)
   OR ISNULL(ST.Value, '') <> ISNULL(S.Value, '')
```

### 8.3 Count customers and parameters in staging
```sql
SELECT COUNT(DISTINCT GCID) AS CustomersStaged, COUNT(*) AS TotalRows
FROM dbo.T_ScoresTemporary WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (P_RiskClassification, TruncateTempTable) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.T_ScoresTemporary | Type: Table | Source: RiskClassification/dbo/Tables/dbo.T_ScoresTemporary.sql*
