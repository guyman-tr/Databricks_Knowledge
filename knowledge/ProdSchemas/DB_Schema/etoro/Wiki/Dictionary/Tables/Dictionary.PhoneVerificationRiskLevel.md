# Dictionary.PhoneVerificationRiskLevel

> Lookup table defining 8 risk levels from phone verification providers — ranging from None (0) through Low/Medium/High to a catch-all Other (MaxInt) — used in KYC risk scoring.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskLevelID (INT, PK) |
| **Partition** | PRIMARY filegroup (PAGE compression) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PhoneVerificationRiskLevel classifies the risk assessment returned by external phone verification providers. When a customer's phone number is verified, the provider returns a risk level indicating the likelihood that the number is associated with fraudulent activity.

This table exists because phone number risk is a key input to the overall KYC risk scoring algorithm. A "High" risk phone number (associated with VOIP fraud, number recycling, or known bad patterns) triggers additional verification steps, while a "Low" risk number contributes positively to the customer's trust score.

The risk level is stored per verification record in Customer.PhoneVerificationDetails and feeds into risk assessment procedures and compliance dashboards.

---

## 2. Business Logic

### 2.1 Risk Level Hierarchy

**What**: Phone risk levels form a 7-point scale from no risk to high risk, plus a catch-all for unclassifiable results.

**Columns/Parameters Involved**: `RiskLevelID`, `RiskLevel`

**Rules**:
- **None (0)** — No risk information available (provider did not return a risk assessment).
- **Low (1)** — Low risk — phone number has clean history, verified carrier, stable ownership.
- **MediumLow (2)** — Between low and medium risk.
- **Medium (3)** — Moderate risk — some concerning signals but not conclusive.
- **MediumHigh (4)** — Elevated risk — multiple concerning signals.
- **High (5)** — High risk — strong indicators of fraud, abuse, or suspicious patterns.
- **Neutral (6)** — No positive or negative signals — insufficient data to assess.
- **Other (2147483647/MaxInt)** — Catch-all for unrecognized risk levels from the provider.

**Diagram**:
```
Risk Level Scale
  0 = None          (no data)
  1 = Low           ████░░░░░░ (clean)
  2 = MediumLow     █████░░░░░
  3 = Medium         ██████░░░░
  4 = MediumHigh     ████████░░
  5 = High           ██████████ (fraud indicators)
  6 = Neutral        ??????????  (insufficient data)
  MaxInt = Other     (unrecognized)
```

---

## 3. Data Overview

| RiskLevelID | RiskLevel | Meaning |
|---|---|---|
| 0 | None | Verification provider did not return a risk assessment. May occur when the number could not be looked up or the provider does not support risk scoring for this number type. |
| 1 | Low | Phone number has a clean history with verified carrier ownership. Contributes positively to customer trust scoring. Standard result for legitimate mobile/fixed-line numbers. |
| 5 | High | Strong fraud indicators — number associated with known bad patterns, VOIP fraud rings, or rapid recycling. Triggers additional KYC verification steps. |
| 6 | Neutral | Insufficient data to determine risk — no positive or negative signals. The provider has no history for this number. |
| 2147483647 | Other | Catch-all for unrecognized risk level values returned by the provider. Uses INT max value to ensure it sorts last. Logged for investigation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskLevelID | int | NO | - | VERIFIED | Primary key identifying the risk level. 0=None, 1=Low, 2=MediumLow, 3=Medium, 4=MediumHigh, 5=High, 6=Neutral, 2147483647=Other. Stored in Customer.PhoneVerificationDetails. |
| 2 | RiskLevel | varchar(50) | NO | - | VERIFIED | Human-readable risk level label. Used in risk scoring displays, compliance reports, and verification dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PhoneVerificationDetails | RiskLevelID | Implicit | Stores the risk level per phone verification record |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails | Table | Stores RiskLevelID per verification record |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PhoneVerificationRiskLevel | CLUSTERED PK | RiskLevelID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PhoneVerificationRiskLevel | PRIMARY KEY | Unique risk level identifier |

---

## 8. Sample Queries

### 8.1 List all risk levels
```sql
SELECT  RiskLevelID,
        RiskLevel
FROM    [Dictionary].[PhoneVerificationRiskLevel] WITH (NOLOCK)
ORDER BY RiskLevelID;
```

### 8.2 Find elevated risk levels (Medium and above)
```sql
SELECT  RiskLevelID,
        RiskLevel
FROM    [Dictionary].[PhoneVerificationRiskLevel] WITH (NOLOCK)
WHERE   RiskLevelID BETWEEN 3 AND 5
ORDER BY RiskLevelID;
```

### 8.3 Map risk levels to action thresholds
```sql
SELECT  RiskLevelID,
        RiskLevel,
        CASE WHEN RiskLevelID IN (0, 6) THEN 'No Action (insufficient data)'
             WHEN RiskLevelID IN (1, 2) THEN 'Pass (low risk)'
             WHEN RiskLevelID = 3 THEN 'Review (moderate risk)'
             WHEN RiskLevelID IN (4, 5) THEN 'Flag (elevated risk)'
             ELSE 'Investigate (unknown)'
        END AS ActionThreshold
FROM    [Dictionary].[PhoneVerificationRiskLevel] WITH (NOLOCK)
ORDER BY RiskLevelID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PhoneVerificationRiskLevel | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PhoneVerificationRiskLevel.sql*
