# dbo.P_GetRiskClassification

> Retrieves a customer's complete risk classification profile by dynamically building a SELECT against T_RiskClassification that includes all score/value columns, enriched with a risk score explanation from V_Scores.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns dynamic result set for a specific GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a dynamic, self-adapting query to retrieve a customer's full risk classification profile. Unlike a static SELECT, it dynamically discovers all `*_RiskScore`, `*_Value`, and `*_SubValue` columns from `T_RiskClassification` using `sys.columns`, ensuring the query automatically adapts when new risk parameters are added to the table without requiring code changes.

The procedure is designed for operational lookups - given a GCID, it returns the customer's complete risk profile including all parameter scores, the base fields (GCID, CID, RegulationID, RiskScore, RiskScore_Value, BeginTime), and a dynamically built `RiskScore_Explanation` that lists which risk parameters match the customer's score level.

Created by Geri Reshef on 2019-12-26 as part of the original RD-16450 risk classification reports implementation.

---

## 2. Business Logic

### 2.1 Dynamic Column Discovery

**What**: Automatically discovers all score/value columns from T_RiskClassification's metadata.

**Columns/Parameters Involved**: Dynamic SQL built from `sys.columns`

**Rules**:
- Queries `sys.columns` for `T_RiskClassification` where column name matches `%_RiskScore`, `%_Value`, or `%_SubValue`
- Builds the SELECT column list dynamically using `CONCAT(@SQL, ',[', name, ']')`
- This means new risk parameters added to T_RiskClassification are automatically included without procedure changes

### 2.2 Risk Score Explanation (Dynamic)

**What**: Builds explanation by finding which V_Scores parameters match the customer's final score.

**Columns/Parameters Involved**: `RiskScore_Explanation`

**Rules**:
- Uses `OUTER APPLY` on `V_Scores` where `GCID` matches
- Matches by parsing `RiskScore_Value` to extract the score after `*`: `Try_Cast(Stuff(R.RiskScore_Value, 1, CharIndex('*', R.RiskScore_Value), '') As Int) = S.RiskScore`
- Excludes parameter 9999 (final score itself)
- Uses `STUFF` with `FOR XML PATH` to build comma-separated list (legacy string aggregation, pre-STRING_AGG)
- Uses `SELECT DISTINCT` to avoid duplicates

### 2.3 Optional GCID Filter

**What**: Can query one customer or all customers.

**Columns/Parameters Involved**: `@GCID`

**Rules**:
- If `@GCID IS NOT NULL`: adds `AND R.GCID = {value}` to the WHERE clause
- If `@GCID IS NULL` (default): returns all customers
- The SQL is executed via `EXEC(@SQL)` - dynamic SQL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | YES | NULL | VERIFIED | Global Customer ID to retrieve risk profile for. If NULL, returns all customers. If provided, filters to that single customer. |

**Return columns** (dynamic):
- GCID, CID, RegulationID, RiskScore, RiskScore_Value, RiskScore_Explanation, BeginTime
- All `*_RiskScore`, `*_Value`, `*_SubValue` columns from T_RiskClassification (discovered dynamically)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.T_RiskClassification | Reader | Base data source for customer risk profiles |
| OUTER APPLY | dbo.V_Scores | Reader | Score explanation - finds parameter names matching the final score |
| sys.columns | sys.columns | Metadata | Dynamic column discovery for T_RiskClassification |

### 5.2 Referenced By (other objects point to this)

Called by external applications and compliance tools for customer risk lookups.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.P_GetRiskClassification (procedure)
+-- dbo.T_RiskClassification (table)
+-- dbo.V_Scores (view)
    +-- dbo.T_Scores (table)
    +-- Dictionary.Regulation (table)
    +-- Dictionary.RiskClassificationParameter (table)
    +-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.T_RiskClassification | Table | FROM (dynamic SQL) |
| dbo.V_Scores | View | OUTER APPLY for explanation (dynamic SQL) |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Called by external applications.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get risk profile for a specific customer
```sql
EXEC dbo.P_GetRiskClassification @GCID = 91
```

### 8.2 Get risk profile for all customers (use with caution - large result)
```sql
EXEC dbo.P_GetRiskClassification
```

### 8.3 Get risk profile with default parameter
```sql
EXEC dbo.P_GetRiskClassification @GCID = 1342104
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.P_GetRiskClassification | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.P_GetRiskClassification.sql*
