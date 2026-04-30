# Dictionary.CryptoAssessmentAnswerCategory

> Lookup table defining question categories in the cryptocurrency knowledge assessment required for crypto trading access.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CryptoAssessmentAnswerCategory defines the seven risk-awareness categories tested in the cryptocurrency knowledge assessment. Under MiCA (Markets in Crypto-Assets) and various national regulations, platforms must verify that users understand crypto-specific risks before granting access to crypto trading. Each category covers a distinct risk dimension.

This table exists because regulators require structured crypto-suitability assessments. The categories ensure comprehensive coverage of all major crypto risk areas. A user must demonstrate adequate understanding across these categories to be approved for crypto trading. Failing the assessment may restrict the user to non-crypto products only.

Categories are used to organize assessment questions and score user responses. Each question belongs to one category, and the platform may require minimum scores per category (not just an overall pass).

---

## 2. Business Logic

### 2.1 Crypto Risk Assessment Framework

**What**: Structured knowledge test covering seven dimensions of crypto risk awareness.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- All seven categories must be assessed for a complete crypto assessment
- Categories cover: loss potential, cyber risks, diversification, regulatory gaps, liquidity, technical aspects, and volatility
- Assessment results determine whether a user can trade crypto assets
- Required by MiCA and various national regulators (e.g., FCA, CySEC)

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 1 | Complete Loss Potential | Tests if user understands cryptocurrency value can drop to zero - total capital loss is possible |
| 2 | Cyber-Risks | Tests understanding of hacking, exchange breaches, wallet theft, and phishing risks |
| 3 | Diversification/Risk Management | Tests understanding of portfolio allocation and not over-concentrating in crypto |
| 4 | Lack of Regulatory Protection | Tests understanding that crypto deposits may lack government protection schemes |
| 5 | Liquidity | Tests understanding that some crypto assets may be difficult to sell at desired prices |
| 6 | Technical Characteristics | Tests basic understanding of blockchain technology, consensus mechanisms, and wallet concepts |
| 7 | Volatility | Tests understanding that crypto prices can swing dramatically in short timeframes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Assessment category: 1=Complete Loss Potential, 2=Cyber-Risks, 3=Diversification/Risk Management, 4=Lack of Regulatory Protection, 5=Liquidity, 6=Technical Characteristics, 7=Volatility. See [Crypto Assessment Answer Category](_glossary.md#crypto-assessment-answer-category). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Category display name. Used in assessment UI and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer crypto assessment answer tables | CategoryID | Lookup | Links each assessment answer to its risk category |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CryptoAssessmentAnswerCategory | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all assessment categories
```sql
SELECT ID, Name
FROM Dictionary.CryptoAssessmentAnswerCategory WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find assessment results by category
```sql
SELECT c.Name AS Category, a.Score, a.Passed
FROM Customer.CryptoAssessmentAnswers a WITH (NOLOCK)
JOIN Dictionary.CryptoAssessmentAnswerCategory c WITH (NOLOCK) ON a.CategoryID = c.ID
WHERE a.CustomerID = @CustomerID
```

### 8.3 Pass rate by category
```sql
SELECT c.Name, AVG(CAST(a.Passed AS FLOAT)) AS PassRate
FROM Customer.CryptoAssessmentAnswers a WITH (NOLOCK)
JOIN Dictionary.CryptoAssessmentAnswerCategory c WITH (NOLOCK) ON a.CategoryID = c.ID
GROUP BY c.Name
ORDER BY PassRate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoAssessmentAnswerCategory | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CryptoAssessmentAnswerCategory.sql*
