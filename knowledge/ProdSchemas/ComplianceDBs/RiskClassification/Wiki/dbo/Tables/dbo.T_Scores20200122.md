# dbo.T_Scores20200122

> Archived snapshot of the normalized customer risk scores table from 2020-01-22, preserving the legacy schema that included a SubValue column alongside Score and Value for each parameter.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | GCID + RiskClassificationParameterID (INT + INT, composite CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is the normalized-form archive companion to `T_RiskClassification20200122`. It preserves the per-customer, per-parameter risk scores as they existed before the 2020 schema migration that removed the `SubValue` column. While the current `T_Scores` stores GCID + ParameterID + RiskScore + Value, this archive additionally stores a `SubValue` column that captured the raw source identifier (e.g., country ID, answer code) used to derive the score.

The table exists for compliance audit and regulatory lookback. Like `T_RiskClassification20200122`, it is a frozen record of the system state before a structural schema change. With ~26M rows (compared to ~222M in the current T_Scores), it reflects the smaller customer base and potentially fewer parameters active at the time.

Data in this table is static from the original migration period. It is temporal (system-versioned with `History.T_Scores20200122`) to preserve any modifications made to the archive itself.

---

## 2. Business Logic

### 2.1 Three-Column Score Record (Legacy)

**What**: Each parameter score record included Score + Value + SubValue, providing a more granular record than the current two-column format.

**Columns/Parameters Involved**: `RiskScore`, `Value`, `SubValue`

**Rules**:
- `RiskScore`: Numeric score (0, 50, 100) - same as current
- `Value`: Score value or label used in scoring - same as current
- `SubValue`: Raw source identifier (country ID, questionnaire answer code, etc.) that was the input to the scoring logic. This dimension was later removed from T_Scores, with the Value column absorbing descriptive labels directly

---

## 3. Data Overview

N/A - archive table. Structure mirrors T_Scores with additional SubValue column. ~26M rows from the 2020-01-22 snapshot.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of composite PK. Same as T_Scores. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID - secondary identifier. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulatory jurisdiction. FK to Dictionary.Regulation. See [Regulation](_glossary.md#regulation). |
| 4 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter being scored. Part of composite PK. FK to Dictionary.RiskClassificationParameter. See [Risk Classification Parameter](_glossary.md#risk-classification-parameter). |
| 5 | RiskScore | INT | YES | - | VERIFIED | Numeric risk score for this parameter (0/50/100). |
| 6 | Value | VARCHAR(100) | YES | - | CODE-BACKED | Score value or label that determined the RiskScore. In legacy format, often numeric codes rather than descriptive names. |
| 7 | SubValue | VARCHAR(100) | YES | - | CODE-BACKED | Raw source identifier used to derive the score. Contains reference IDs (country IDs, answer codes) from the source systems. This column was removed in the schema migration to T_Scores current format. |
| 8 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal row start. GENERATED ALWAYS AS ROW START. |
| 9 | EndTime | DATETIME2(7) | NO | 9999-12-31... | VERIFIED | Temporal row end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Implicit FK | Risk parameter lookup |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction |

### 5.2 Referenced By (other objects point to this)

No other objects reference this archive table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dbo_T_Scores20200122 | CLUSTERED PK | GCID ASC, RiskClassificationParameterID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_dbo_T_Scores_BeginTime20200122 | DEFAULT | GETUTCDATE() |
| Df_dbo_T_Scores_EndTime20200122 | DEFAULT | '99991231 23:59:59.9999999' |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[T_Scores20200122] |

---

## 8. Sample Queries

### 8.1 Compare legacy SubValue with current Value for a customer
```sql
SELECT a.GCID, a.RiskClassificationParameterID, P.Name,
       a.RiskScore AS LegacyScore, a.Value AS LegacyValue, a.SubValue AS LegacySubValue,
       c.RiskScore AS CurrentScore, c.Value AS CurrentValue
FROM dbo.T_Scores20200122 a WITH (NOLOCK)
INNER JOIN Dictionary.RiskClassificationParameter P WITH (NOLOCK) ON a.RiskClassificationParameterID = P.RiskClassificationParameterID
LEFT JOIN dbo.T_Scores c WITH (NOLOCK) ON a.GCID = c.GCID AND a.RiskClassificationParameterID = c.RiskClassificationParameterID
WHERE a.GCID = @GCID
ORDER BY a.RiskClassificationParameterID
```

### 8.2 Analyze SubValue patterns for country parameters
```sql
SELECT TOP 20 SubValue, Value, RiskScore, COUNT(*) AS Cnt
FROM dbo.T_Scores20200122 WITH (NOLOCK)
WHERE RiskClassificationParameterID = 2
GROUP BY SubValue, Value, RiskScore
ORDER BY Cnt DESC
```

### 8.3 Count customers in the archive
```sql
SELECT COUNT(DISTINCT GCID) AS UniqueCustomers, COUNT(*) AS TotalScoreRows
FROM dbo.T_Scores20200122 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.T_Scores20200122 | Type: Table | Source: RiskClassification/dbo/Tables/dbo.T_Scores20200122.sql*
