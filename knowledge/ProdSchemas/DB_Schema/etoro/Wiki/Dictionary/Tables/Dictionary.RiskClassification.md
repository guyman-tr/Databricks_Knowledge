# Dictionary.RiskClassification

> Lookup table defining overall risk classification levels for customer accounts. Each level has a numeric RiskScore enabling quantitative risk comparison and regulatory-driven trading restrictions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskClassificationID (int, PK CLUSTERED) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RiskClassification defines the overall risk classification levels for customer accounts within the eToro platform. Each level corresponds to a human-readable Name (e.g., High, Medium, Low, Unacceptable) and a numeric RiskScore that allows quantitative risk comparison across customers. The hierarchy from lowest to highest risk is: Low (0) < Medium Low (25) < Medium (50) < Medium High (75) < High (100) < Unacceptable (200).

This classification drives trading restrictions, deposit limits, and compliance review requirements. Customers with higher risk classifications may be subject to enhanced due diligence, reduced leverage, or blocked access until remediation. The RiskCalculation schema contains algorithms (e.g., RiskCalculation.SetRiskClassificationForCySec, RiskCalculation.RiskParameterConfiguration) that compute these classifications based on regulatory context and customer attributes.

The classification is stored on BackOffice.Customer in two columns: RiskClassificationID (ongoing risk assessment) and OnboardingRiskClassificationID (initial classification at account opening). Both flow into UserApiDB procedures (Customer.UpdateRiskUserInfo, Customer.GetRiskInfo, Customer.GetUserRiskClassification) for front-end display and risk-based feature gating.

---

## 2. Business Logic

### 2.1 Risk Hierarchy and Scoring

**What**: The ordering of risk levels by severity, with numeric RiskScore enabling quantitative comparison.

**Columns Involved**: `RiskClassificationID`, `Name`, `RiskScore`

**Rules**:
- **Unacceptable (200)**: Highest risk — typically triggers immediate restrictions or account review.
- **High (100)**: Elevated risk — reduced leverage, enhanced monitoring.
- **Medium High (75)**: Between Medium and High.
- **Medium (50)**: Standard risk level.
- **Medium Low (25)**: Between Low and Medium.
- **Low (0)**: Lowest risk — full trading privileges within regulatory bounds.

**Diagram**:
```
Risk Score Hierarchy (ascending severity):

  RiskScore    Name
  ─────────────────────────────────────────
      0   →   Low
     25   →   Medium Low
     50   →   Medium
     75   →   Medium High
    100   →   High
    200   →   Unacceptable

  BackOffice.Customer
  ├── RiskClassificationID      (ongoing assessment)
  └── OnboardingRiskClassificationID  (initial at registration)

  RiskCalculation.SetRiskClassificationForCySec
  RiskCalculation.RiskParameterConfiguration
  → Compute classification by regulation & attributes
```

---

## 3. Data Overview

| RiskClassificationID | Name | RiskScore | Meaning |
|---|---|---|---|
| 2 | Low | 0 | Lowest risk. Full trading privileges. Typically assigned after strong verification and low-risk profile. |
| 5 | Medium Low | 25 | Between Low and Medium. Graduated restriction level. |
| 1 | Medium | 50 | Standard risk level. Typical for verified customers with normal trading behavior. Full access within regulatory limits. |
| 4 | Medium High | 75 | Between Medium and High. Graduated restriction level. |
| 0 | High | 100 | Elevated risk classification. May trigger reduced leverage and enhanced monitoring. Used when risk algorithms or manual review flag elevated exposure. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskClassificationID | int | NO | - | VERIFIED | Primary key identifying the risk classification level. 0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low. Referenced by BackOffice.Customer (RiskClassificationID, OnboardingRiskClassificationID), History.BackOfficeCustomer. Used by RiskCalculation.SetRiskClassificationForCySec, BackOffice.CustomerSetRiskClassification. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the classification. Used for reporting, UI display, and audit logs. Values: High, Medium, Low, Unacceptable, Medium High, Medium Low. |
| 3 | RiskScore | int | YES | - | VERIFIED | Numeric score enabling quantitative risk comparison. Higher = higher risk. Range 0–200 in live data. Used for sorting, thresholds, and regulatory reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | RiskClassificationID | FK / Lookup | Ongoing risk classification for the customer |
| BackOffice.Customer | OnboardingRiskClassificationID | FK / Lookup | Initial risk classification at onboarding |
| History.BackOfficeCustomer | RiskClassificationID | FK | Historical snapshots of risk classification |
| History.BackOfficeCustomer | OnboardingRiskClassificationID | FK | Historical snapshots of onboarding classification |
| BackOffice.SetRiskClassificationNew | @RiskClassificationID | Parameter | Sets risk classification on customer |
| BackOffice.CustomerSetRiskClassification | @RiskClassificationID | Parameter | Updates customer risk classification |
| RiskCalculation.SetRiskClassificationForCySec | — | Logic | Computes CySEC-specific classification |
| RiskCalculation.RiskParameterConfiguration | — | Config | Risk algorithm parameters per regulation |
| UserApiDB: Customer.UpdateRiskUserInfo, Customer.GetRiskInfo | — | Read/Write | API layer risk info operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FK — RiskClassificationID, OnboardingRiskClassificationID |
| History.BackOfficeCustomer | Table | FK — historical risk classification |
| BackOffice.SetRiskClassificationNew | Stored Procedure | Sets risk classification |
| BackOffice.CustomerSetRiskClassification | Stored Procedure | Updates risk classification |
| RiskCalculation.SetRiskClassificationForCySec | Stored Procedure | CySEC risk computation |
| RiskCalculation.RiskParameterConfiguration | Table | Config for risk algorithms |
| UserApiDB Customer procedures | Stored Procedure | Risk info read/write |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RiskClassificationID | CLUSTERED PK | RiskClassificationID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RiskClassificationID | PRIMARY KEY | Unique RiskClassificationID on PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all risk classifications with scores
```sql
SELECT  RiskClassificationID,
        Name,
        RiskScore
FROM    Dictionary.RiskClassification WITH (NOLOCK)
ORDER BY RiskScore;
```

### 8.2 Count customers by risk classification
```sql
SELECT  rc.Name,
        rc.RiskScore,
        COUNT(*) AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.RiskClassification rc WITH (NOLOCK)
        ON bc.RiskClassificationID = rc.RiskClassificationID
GROUP BY rc.Name, rc.RiskScore
ORDER BY rc.RiskScore DESC;
```

### 8.3 Compare onboarding vs current risk classification
```sql
SELECT  rc.Name AS CurrentClassification,
        rcOnboard.Name AS OnboardingClassification,
        COUNT(*) AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.RiskClassification rc WITH (NOLOCK)
        ON bc.RiskClassificationID = rc.RiskClassificationID
JOIN    Dictionary.RiskClassification rcOnboard WITH (NOLOCK)
        ON bc.OnboardingRiskClassificationID = rcOnboard.RiskClassificationID
WHERE   bc.RiskClassificationID <> bc.OnboardingRiskClassificationID
GROUP BY rc.Name, rcOnboard.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4+ analyzed | App Code: UserApiDB Customer procs | Corrections: 0 applied*
*Object: Dictionary.RiskClassification | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskClassification.sql*
