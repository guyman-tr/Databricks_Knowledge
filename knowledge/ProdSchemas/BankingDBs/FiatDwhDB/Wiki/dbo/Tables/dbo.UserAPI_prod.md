# dbo.UserAPI_prod

> Staging table holding customer KYC/compliance data imported from the UserAPI, including income thresholds and occupation information.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Gcid (NVARCHAR(250), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

UserAPI_prod is a staging table that caches KYC (Know Your Customer) and compliance-related data from the UserAPI. Each row stores a customer's self-declared financial information: income range answers, TCLA (Total Credit Limit Assessment) amount, and occupation. This data supports the fiat platform's customer suitability assessment and compliance reporting.

This table exists to provide the fiat DWH with customer financial profile data for eligibility processing, sub-program assignment, and regulatory reporting. The data originates from KYC questionnaires completed during customer onboarding.

Note: All columns are nvarchar(250) including Gcid (which is normally bigint), suggesting this is a raw import table where data arrives as strings before type conversion.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a raw data staging table.

---

## 3. Data Overview

N/A - staging table with customer PII/financial data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | nvarchar(250) | NO | - | CODE-BACKED | Global Customer ID stored as string (raw import format). Primary key. |
| 2 | AnswerText | nvarchar(250) | YES | - | NAME-INFERRED | Customer's answer text from KYC questionnaire. Contains the human-readable response to income/financial questions. |
| 3 | MinThreshold | nvarchar(250) | YES | - | NAME-INFERRED | Minimum income threshold for the customer's declared income range. Stored as string from raw import. |
| 4 | MaxThreshold | nvarchar(250) | YES | - | NAME-INFERRED | Maximum income threshold for the customer's declared income range. |
| 5 | AnswerId | nvarchar(250) | YES | - | NAME-INFERRED | Identifier of the specific answer option selected by the customer in the KYC questionnaire. |
| 6 | TCLAAmount | nvarchar(250) | YES | - | NAME-INFERRED | Total Credit Limit Assessment amount. Represents the assessed credit/spending limit for the customer. Used for financial suitability checks. |
| 7 | Occupation | nvarchar(250) | YES | - | NAME-INFERRED | Customer's declared occupation from KYC onboarding. Used for compliance categorization. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this staging table.

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
| PK_UserAPI_prod | CLUSTERED | Gcid ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 Look up a customer's KYC data
```sql
SELECT * FROM dbo.UserAPI_prod WITH (NOLOCK) WHERE Gcid = '12345';
```

### 8.2 Count customers by occupation
```sql
SELECT Occupation, COUNT(*) AS Cnt
FROM dbo.UserAPI_prod WITH (NOLOCK)
WHERE Occupation IS NOT NULL
GROUP BY Occupation ORDER BY Cnt DESC;
```

### 8.3 Find customers with TCLA amounts
```sql
SELECT TOP 20 Gcid, TCLAAmount, MinThreshold, MaxThreshold, Occupation
FROM dbo.UserAPI_prod WITH (NOLOCK)
WHERE TCLAAmount IS NOT NULL ORDER BY Gcid;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 5.7/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.UserAPI_prod | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.UserAPI_prod.sql*
