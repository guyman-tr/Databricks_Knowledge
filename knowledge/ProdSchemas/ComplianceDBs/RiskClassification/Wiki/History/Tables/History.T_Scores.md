# History.T_Scores

> Temporal history table preserving all superseded versions of individual customer risk parameter scores from dbo.T_Scores, the largest table in the database at ~261M rows, enabling per-parameter point-in-time risk lookback.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | GCID + RiskClassificationParameterID + BeginTime (clustered index) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

This is the temporal history table for `dbo.T_Scores` - the normalized customer risk scores table. It stores all superseded versions of individual parameter scores. Every time the `P_RiskClassification` procedure's MERGE operation updates a score in T_Scores, the previous version moves here automatically.

This is the largest table in the entire RiskClassification database at ~261M rows (compared to ~222M current rows in T_Scores). The large volume reflects the frequent per-parameter score changes across the ~5M customer base. It enables granular lookback: not just "what was the customer's overall risk on date X?" but "what score did parameter Y have for customer Z on date X?"

The table is consumed by `History.V_Scores` (which UNION ALLs it with dbo.T_Scores for complete timeline views).

---

## 2. Business Logic

### 2.1 Per-Parameter Score History

**What**: Preserves the complete timeline of every individual parameter score change for every customer.

**Columns/Parameters Involved**: All columns mirror dbo.T_Scores

**Rules**:
- Each row = one superseded score for one parameter for one customer
- A customer who has had 3 country risk changes has 3 rows here for parameter ID 2
- BeginTime = when this score version became effective
- EndTime = when this version was replaced by a newer score
- Combined with dbo.T_Scores (current), provides the complete score timeline
- Clustered on GCID + ParameterID + BeginTime for efficient per-customer lookups

---

## 3. Data Overview

N/A - massive history table (~261M rows). Sample data mirrors dbo.T_Scores structure with historical BeginTime/EndTime ranges.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of clustered index. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulation ID during this period. See [Regulation](../_glossary.md#regulation). |
| 4 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter. Part of clustered index. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 5 | RiskScore | INT | YES | - | VERIFIED | Risk score that was in effect during [BeginTime, EndTime). |
| 6 | Value | VARCHAR(100) | YES | - | VERIFIED | The value/label used for scoring during this period (country name, age, etc.). |
| 7 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | When this score version became effective. |
| 8 | EndTime | DATETIME2(7) | NO | - | VERIFIED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (parent) | dbo.T_Scores | Temporal history | System-versioned history for the normalized scores table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.V_Scores | FROM (UNION ALL) | Reader | Combined view of current + historical scores |

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.V_Scores | View | UNION ALL with dbo.T_Scores for complete timeline |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_T_Scores | CLUSTERED | GCID ASC, RiskClassificationParameterID ASC, BeginTime ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Score history for a specific customer and parameter
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore, Value, BeginTime, EndTime
FROM History.T_Scores WITH (NOLOCK)
WHERE GCID = 91 AND RiskClassificationParameterID = 7
ORDER BY BeginTime DESC
```

### 8.2 Point-in-time parameter score lookup
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore, Value
FROM History.T_Scores WITH (NOLOCK)
WHERE GCID = 91
  AND BeginTime <= '2022-01-01' AND EndTime > '2022-01-01'
ORDER BY RiskClassificationParameterID
```

### 8.3 Count score changes per parameter
```sql
SELECT TOP 10 RiskClassificationParameterID, COUNT_BIG(*) AS HistoricalChanges
FROM History.T_Scores WITH (NOLOCK)
GROUP BY RiskClassificationParameterID
ORDER BY HistoricalChanges DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.T_Scores | Type: Table | Source: RiskClassification/History/Tables/History.T_Scores.sql*
