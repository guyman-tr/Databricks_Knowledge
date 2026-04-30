# RiskClassification.UpsertCustomerOnboardingRiskClassification

> Upserts a customer's onboarding risk classification score and JSON breakdown - updates existing records or inserts new ones with the current timestamp.

| Property | Value |
|----------|-------|
| **Schema** | RiskClassification |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upserts by GCID into CustomerOnboardingRiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write endpoint for the onboarding risk classification system. Called by the external risk assessment engine after calculating a customer's onboarding risk score, it either creates a new record (for first-time scoring) or updates an existing one (for re-scoring). The LastUpdate timestamp is always set to CURRENT_TIMESTAMP, providing a reliable record of when the scoring occurred.

The IF EXISTS / UPDATE / ELSE INSERT pattern ensures idempotent operation - calling the procedure multiple times for the same customer simply updates the existing record rather than failing with a duplicate key error.

---

## 2. Business Logic

### 2.1 Upsert Pattern

**What**: IF EXISTS UPDATE ELSE INSERT for atomic score persistence.

**Columns/Parameters Involved**: `GCID`, `Score`, `Data`, `LastUpdate`

**Rules**:
- IF EXISTS (SELECT 1 WHERE GCID = @gcid): UPDATE Score, Data, LastUpdate=CURRENT_TIMESTAMP
- ELSE: INSERT (GCID, Score, Data, LastUpdate=CURRENT_TIMESTAMP)
- LastUpdate is always set to CURRENT_TIMESTAMP, never passed as parameter - ensures server-side timestamp
- Data can be NULL (score-only updates are valid)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | VERIFIED | Global Customer ID to upsert. If exists, UPDATE; otherwise INSERT. |
| 2 | @score | DECIMAL(6,3) | NO | - | VERIFIED | Weighted composite onboarding risk score to set. Continuous decimal (e.g., 4.5, 10.0, 14.5). |
| 3 | @data | NVARCHAR(4000) | NO | - | VERIFIED | Full JSON scoring breakdown with parameter contributions. Stored in the Data column for audit and transparency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IF EXISTS / UPDATE / INSERT | RiskClassification.CustomerOnboardingRiskClassification | Writer | Upserts Score, Data, LastUpdate |

### 5.2 Referenced By (other objects point to this)

Called by external risk assessment engine during customer onboarding.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RiskClassification.UpsertCustomerOnboardingRiskClassification (procedure)
+-- RiskClassification.CustomerOnboardingRiskClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RiskClassification.CustomerOnboardingRiskClassification | Table | IF EXISTS check + UPDATE + INSERT |

### 6.2 Objects That Depend On This

No dependents found. Called by external services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Upsert a customer's onboarding risk score
```sql
EXEC RiskClassification.UpsertCustomerOnboardingRiskClassification
    @gcid = 47590708,
    @score = 4.5,
    @data = '{"Contributions":{"CountryOfResidenceRank":{"Answer":0,"Score":0,"Weight":0.13,"WeightedScore":0.00}}}'
```

### 8.2 Update an existing customer's score
```sql
EXEC RiskClassification.UpsertCustomerOnboardingRiskClassification
    @gcid = 47590708,
    @score = 10.0,
    @data = '{"Contributions":{"CountryOfResidenceRank":{"Answer":1,"Score":50,"Weight":0.13,"WeightedScore":6.50}}}'
```

### 8.3 Verify the upsert worked
```sql
EXEC RiskClassification.UpsertCustomerOnboardingRiskClassification @gcid = 12345, @score = 5.0, @data = '{}'
EXEC RiskClassification.GetCustomerOnboardingRiskClassification @gcid = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RiskClassification.UpsertCustomerOnboardingRiskClassification | Type: Stored Procedure | Source: RiskClassification/RiskClassification/Stored Procedures/RiskClassification.UpsertCustomerOnboardingRiskClassification.sql*
