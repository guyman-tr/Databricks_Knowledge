# BackOffice.ExceptionalCustomers

> Manual risk classification override table where compliance officers can force specific risk scores for individual customer parameters, bypassing the automated scoring engine.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | GCID + RiskClassificationParameterID (composite CLUSTERED PK) |
| **Partition** | No (FILLFACTOR 90, PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table stores manual compliance overrides for specific customer risk parameters. When the automated risk scoring engine produces a score that compliance officers deem incorrect or insufficient, they can insert a row here to force a specific RiskScore for a given customer+parameter combination. The most common use is overriding the final aggregate score (parameter 9999) to force a customer to "High" (100) status.

The table is temporal (system-versioned with `History.ExceptionalCustomers`), preserving a full audit trail of every override - when it was created, when it was changed, and when it was removed. This is essential for regulatory compliance - auditors need to know who was under manual override and when.

Currently holds only 7 active overrides, all for parameter 9999 (final score) with RiskScore=100 (High), all created on 2025-03-06. The historical table has ~127K rows, indicating many past overrides have been created and subsequently removed.

---

## 2. Business Logic

### 2.1 Final Score Override Pattern

**What**: Most overrides target parameter 9999 (Final score) to force the aggregate classification.

**Columns/Parameters Involved**: `GCID`, `RiskClassificationParameterID`, `RiskScore`

**Rules**:
- Parameter 9999 overrides the final aggregate risk score, regardless of individual parameter scores
- RiskScore=100 forces the customer to "High" risk classification
- The automated P_RiskClassification procedure should check this table and apply overrides on top of calculated scores
- Only 7 active overrides vs ~127K historical = overrides are typically temporary compliance interventions

---

## 3. Data Overview

| GCID | ParameterID | RiskScore | BeginTime | Meaning |
|------|------------|-----------|-----------|---------|
| 7630178 | 9999 | 100 | 2025-03-06 | Customer forced to High (100) risk. Final score override active since March 2025. |
| 3761758 | 9999 | 100 | 2025-03-06 | Same batch of overrides - compliance action affecting multiple customers simultaneously. |
| 20609322 | 9999 | 100 | 2025-03-06 | Another customer in the same batch override. All 7 current overrides share the same timestamp. |

Total: 7 active overrides (all parameter 9999, all score 100, all from 2025-03-06). ~127K historical overrides.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of composite PK. Identifies the customer under manual override. |
| 2 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter being overridden. Part of composite PK. FK to Dictionary.RiskClassificationParameter. Most commonly 9999 (Final score). See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 3 | RiskScore | INT | YES | - | VERIFIED | Forced risk score value. Overrides the automated calculation for this customer+parameter. Typically 100 (High). |
| 4 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal row start. When this override was created or last modified. GENERATED ALWAYS AS ROW START. |
| 5 | EndTime | DATETIME2(7) | NO | 9999-12-31... | VERIFIED | Temporal row end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Explicit FK | FK_BackOffice_ExceptionalCustomers_RiskClassificationParameterID - validates parameter ID |

### 5.2 Referenced By (other objects point to this)

No dbo objects directly reference this table. Consumed by the risk classification engine during score calculation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ExceptionalCustomers (table)
+-- Dictionary.RiskClassificationParameter (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RiskClassificationParameter | Table | FK constraint on RiskClassificationParameterID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ExceptionalCustomers | Table | Temporal history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_ExceptionalCustomers | CLUSTERED PK | GCID ASC, RiskClassificationParameterID ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_ExceptionalCustomers | PRIMARY KEY | GCID + RiskClassificationParameterID |
| FK_BackOffice_ExceptionalCustomers_RiskClassificationParameterID | FOREIGN KEY | -> Dictionary.RiskClassificationParameter |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[ExceptionalCustomers] |

---

## 8. Sample Queries

### 8.1 List all active overrides
```sql
SELECT ec.GCID, ec.RiskClassificationParameterID, p.Name AS Parameter,
       ec.RiskScore, ec.BeginTime
FROM BackOffice.ExceptionalCustomers ec WITH (NOLOCK)
INNER JOIN Dictionary.RiskClassificationParameter p WITH (NOLOCK)
    ON ec.RiskClassificationParameterID = p.RiskClassificationParameterID
ORDER BY ec.BeginTime DESC
```

### 8.2 Check if a specific customer has an override
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore, BeginTime
FROM BackOffice.ExceptionalCustomers WITH (NOLOCK)
WHERE GCID = 7630178
```

### 8.3 View override history (temporal query)
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore, BeginTime, EndTime
FROM BackOffice.ExceptionalCustomers
FOR SYSTEM_TIME ALL
WHERE GCID = 7630178
ORDER BY BeginTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ExceptionalCustomers | Type: Table | Source: RiskClassification/BackOffice/Tables/BackOffice.ExceptionalCustomers.sql*
