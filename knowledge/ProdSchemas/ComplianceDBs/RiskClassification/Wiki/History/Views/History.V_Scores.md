# History.V_Scores

> Combined timeline view that UNION ALLs current scores from dbo.T_Scores with historical scores from History.T_Scores, enriched with regulation names, parameter names, and risk level labels from Dictionary tables.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | Base tables: dbo.T_Scores UNION ALL History.T_Scores |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a complete, unified timeline of ALL customer risk parameter scores - both current and historical - in a single queryable interface. It achieves this by performing a `UNION ALL` between `dbo.T_Scores` (current active scores) and `History.T_Scores` (superseded historical scores), with both halves enriched via the same Dictionary JOINs.

This enables compliance and analytics queries that span the full lifecycle: "Show me all values this customer's screening status has ever had" or "When did this customer's country risk score change from 50 to 100?" Without this view, such queries would require manually combining two separate queries.

Both halves of the UNION use identical JOIN logic to Dictionary.Regulation, Dictionary.RiskClassificationParameter, and Dictionary.RiskClassificationRegulation, producing a uniform output schema regardless of whether a row is current or historical.

Created by Geri Reshef in 2019-12 (RD-16450) and enhanced in 2020-01.

---

## 2. Business Logic

### 2.1 Current + Historical Union

**What**: Combines active and superseded score records into one timeline.

**Columns/Parameters Involved**: All output columns

**Rules**:
- First SELECT: dbo.T_Scores (current) with NOLOCK, JOINed to Dictionary tables
- Second SELECT: History.T_Scores (historical) with NOLOCK, same JOINs
- UNION ALL (not UNION) preserves all rows without deduplication - appropriate since a customer legitimately has both a current and multiple historical versions
- RiskScore JOIN to RiskClassificationRegulation does NOT use ISNULL (unlike dbo.V_Scores which uses `ISNULL(S.RiskScore, 0)`) - this means NULL scores will not get a RiskScoreName (they are excluded by the INNER JOIN)
- Historical rows have EndTime < '9999-12-31', current rows have EndTime = '9999-12-31 23:59:59.9999999'

---

## 3. Data Overview

Output combines ~222M current rows + ~261M historical rows = ~483M total rows. Each row enriched with:

| GCID | CID | RegulationID | Regulation | ParameterID | RiskClassificationParameter | RiskScore | RiskScoreName | Value | BeginTime | EndTime | Meaning |
|------|-----|-------------|-----------|------------|---------------------------|-----------|--------------|-------|-----------|---------|---------|
| 91 | 683770 | 1 | CySEC | 7 | Screening Status | 100 | High | 2 | 2021-02-18 | 9999-12-31 | Current screening score - active (EndTime far-future). Flagged since 2021. |
| 91 | 683770 | 1 | CySEC | 2 | Country of Residence, Onboarding | 50 | Medium | Turkey | 2023-04-23 | 9999-12-31 | Current country score - active. |
| 91 | ... | 1 | CySEC | 2 | Country of Residence, Onboarding | 0 | Low | Turkey | 2020-01-01 | 2023-04-23 | Historical country score - was Low before April 2023 upgrade to Medium. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. From T_Scores (current) or History.T_Scores (historical). |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulation ID. See [Regulation](../_glossary.md#regulation). |
| 4 | Regulation | VARCHAR(50) | YES | - | VERIFIED | Regulation name from Dictionary.Regulation via INNER JOIN. E.g., "CySEC", "FCA". |
| 5 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter ID. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 6 | RiskClassificationParameter | VARCHAR(50) | YES | - | VERIFIED | Parameter name from Dictionary.RiskClassificationParameter (`DP.Name`). E.g., "Country of Residence, Onboarding", "Screening Status". |
| 7 | RiskScore | INT | YES | - | VERIFIED | Risk score for this parameter during [BeginTime, EndTime). Unlike dbo.V_Scores, NULL scores are not coalesced to 0 - they are excluded by the INNER JOIN to RiskClassificationRegulation. |
| 8 | RiskScoreName | VARCHAR(20) | YES | - | VERIFIED | Named risk level from Dictionary.RiskClassificationRegulation. "Low", "Medium", "High", etc. Resolved via INNER JOIN on RegulationID + RiskScore. |
| 9 | Value | VARCHAR(100) | YES | - | VERIFIED | The value/label used for scoring during this period. Country names, age, screening codes, etc. |
| 10 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | When this score version became effective. For current rows: last update time. For historical: when the superseded version started. |
| 11 | EndTime | DATETIME2(7) | NO | - | VERIFIED | When this score version ended. Current rows: '9999-12-31 23:59:59.9999999'. Historical rows: timestamp when superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM (first SELECT) | dbo.T_Scores | Base table | Current active scores |
| FROM (second SELECT) | History.T_Scores | Base table | Historical superseded scores |
| INNER JOIN | Dictionary.Regulation | Lookup | Regulation name resolution (both SELECTs) |
| INNER JOIN | Dictionary.RiskClassificationParameter | Lookup | Parameter name resolution (both SELECTs) |
| INNER JOIN | Dictionary.RiskClassificationRegulation | Lookup | Risk level name resolution (both SELECTs) |

### 5.2 Referenced By (other objects point to this)

No other SSDT objects reference this view directly. Used by compliance and analytics for full-timeline queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.V_Scores (view)
+-- dbo.T_Scores (table)
+-- History.T_Scores (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.RiskClassificationParameter (table)
+-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.T_Scores | Table | FROM (first UNION ALL leg) - current scores |
| History.T_Scores | Table | FROM (second UNION ALL leg) - historical scores |
| Dictionary.Regulation | Table | INNER JOIN - regulation name (both legs) |
| Dictionary.RiskClassificationParameter | Table | INNER JOIN - parameter name (both legs) |
| Dictionary.RiskClassificationRegulation | Table | INNER JOIN - risk level name (both legs) |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Complete score timeline for a customer and parameter
```sql
SELECT GCID, Regulation, RiskClassificationParameter, RiskScore, RiskScoreName,
       Value, BeginTime, EndTime
FROM History.V_Scores WITH (NOLOCK)
WHERE GCID = 91 AND RiskClassificationParameterID = 7
ORDER BY BeginTime DESC
```

### 8.2 Find all score changes for a customer across all parameters
```sql
SELECT GCID, RiskClassificationParameter, RiskScore, RiskScoreName, Value,
       BeginTime, EndTime
FROM History.V_Scores WITH (NOLOCK)
WHERE GCID = 91
ORDER BY RiskClassificationParameterID, BeginTime DESC
```

### 8.3 Point-in-time all-parameter snapshot
```sql
SELECT GCID, RiskClassificationParameter, RiskScore, RiskScoreName, Value
FROM History.V_Scores WITH (NOLOCK)
WHERE GCID = 91
  AND BeginTime <= '2022-06-01' AND EndTime > '2022-06-01'
ORDER BY RiskClassificationParameterID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.V_Scores | Type: View | Source: RiskClassification/History/Views/History.V_Scores.sql*
