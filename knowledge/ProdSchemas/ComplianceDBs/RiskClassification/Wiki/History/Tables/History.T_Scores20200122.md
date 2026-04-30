# History.T_Scores20200122

> Temporal history table for the archived dbo.T_Scores20200122 snapshot, preserving superseded versions of the legacy normalized risk scores that included SubValue columns.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | GCID + RiskClassificationParameterID + BeginTime (clustered index) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

This is the temporal history table for `dbo.T_Scores20200122` - the archived normalized scores snapshot from January 2020. It preserves superseded versions of records in that archive table. With ~5M rows, this table has accumulated significant history, indicating the 2020 archive has been modified over time (unlike the empty T_RiskClassification20200122 history).

The SubValue column preserves the legacy three-column scoring format (Score + Value + SubValue) that was later simplified to two columns in the current T_Scores schema.

---

## 2. Business Logic

### 2.1 Legacy Score Format History

**What**: Preserves historical versions of the legacy three-column score format.

**Columns/Parameters Involved**: `RiskScore`, `Value`, `SubValue`, `BeginTime`, `EndTime`

**Rules**:
- Same temporal versioning pattern as all History tables
- SubValue preserves the raw source identifiers (country IDs, answer codes) from the pre-2020 schema
- ~5M rows indicates the archive data has been modified significantly - likely through compliance corrections or re-scoring

---

## 3. Data Overview

N/A - history of archive table. ~5M rows of superseded 2020 archive records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of clustered index. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulation ID. See [Regulation](../_glossary.md#regulation). |
| 4 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter. Part of clustered index. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 5 | RiskScore | INT | YES | - | VERIFIED | Risk score during this period. |
| 6 | Value | VARCHAR(100) | YES | - | CODE-BACKED | Score value/label during this period. |
| 7 | SubValue | VARCHAR(100) | YES | - | CODE-BACKED | Legacy raw source identifier. Country IDs, answer codes, etc. |
| 8 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | When this version became effective. |
| 9 | EndTime | DATETIME2(7) | NO | - | VERIFIED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (parent) | dbo.T_Scores20200122 | Temporal history | History for the 2020 scores archive |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_T_Scores20200122 | CLUSTERED | GCID ASC, RiskClassificationParameterID ASC, BeginTime ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check archive modification volume
```sql
SELECT COUNT_BIG(*) AS TotalHistoricalVersions
FROM History.T_Scores20200122 WITH (NOLOCK)
```

### 8.2 Find modifications for a customer
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore, Value, SubValue,
       BeginTime, EndTime
FROM History.T_Scores20200122 WITH (NOLOCK)
WHERE GCID = @GCID
ORDER BY RiskClassificationParameterID, BeginTime DESC
```

### 8.3 Analyze SubValue patterns in history
```sql
SELECT TOP 20 RiskClassificationParameterID, SubValue, COUNT(*) AS Cnt
FROM History.T_Scores20200122 WITH (NOLOCK)
WHERE SubValue IS NOT NULL
GROUP BY RiskClassificationParameterID, SubValue
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.T_Scores20200122 | Type: Table | Source: RiskClassification/History/Tables/History.T_Scores20200122.sql*
