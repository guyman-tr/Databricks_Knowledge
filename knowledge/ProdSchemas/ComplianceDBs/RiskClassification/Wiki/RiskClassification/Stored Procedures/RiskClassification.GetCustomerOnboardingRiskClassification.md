# RiskClassification.GetCustomerOnboardingRiskClassification

> Retrieves a customer's onboarding risk classification score and full JSON scoring breakdown by GCID from the CustomerOnboardingRiskClassification table.

| Property | Value |
|----------|-------|
| **Schema** | RiskClassification |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Score + Data for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the read endpoint for the onboarding risk classification system. Given a customer's GCID, it returns their onboarding risk score (a weighted decimal composite) and the full JSON breakdown of all scoring contributions. It is designed for real-time lookups during the onboarding flow and by downstream services that need to check a customer's onboarding risk level.

The procedure uses NOLOCK for non-blocking reads, suitable for high-throughput onboarding scenarios where read consistency is less critical than availability.

---

## 2. Business Logic

No complex logic. Single SELECT with WHERE GCID = @gcid and NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | VERIFIED | Global Customer ID to look up. Matches against the PK of CustomerOnboardingRiskClassification. |

**Return columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Score | DECIMAL(6,3) | Weighted composite onboarding risk score. |
| 2 | Data | NVARCHAR(4000) | Full JSON scoring breakdown with parameter contributions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT FROM | RiskClassification.CustomerOnboardingRiskClassification | Reader | Reads Score and Data |

### 5.2 Referenced By (other objects point to this)

Called by external onboarding services and compliance tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RiskClassification.GetCustomerOnboardingRiskClassification (procedure)
+-- RiskClassification.CustomerOnboardingRiskClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RiskClassification.CustomerOnboardingRiskClassification | Table | SELECT FROM |

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

### 8.1 Get onboarding risk for a customer
```sql
EXEC RiskClassification.GetCustomerOnboardingRiskClassification @gcid = 47590708
```

### 8.2 Get and parse the JSON result
```sql
DECLARE @score DECIMAL(6,3), @data NVARCHAR(4000)
EXEC RiskClassification.GetCustomerOnboardingRiskClassification @gcid = 47590708
```

### 8.3 Check if a customer has been scored
```sql
EXEC RiskClassification.GetCustomerOnboardingRiskClassification @gcid = 12345
-- Empty result = customer not yet scored during onboarding
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RiskClassification.GetCustomerOnboardingRiskClassification | Type: Stored Procedure | Source: RiskClassification/RiskClassification/Stored Procedures/RiskClassification.GetCustomerOnboardingRiskClassification.sql*
