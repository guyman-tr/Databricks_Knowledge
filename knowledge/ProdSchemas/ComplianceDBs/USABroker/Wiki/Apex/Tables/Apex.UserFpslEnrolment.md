# Apex.UserFpslEnrolment

> Tracks each customer's FPSL (Fully Paid Securities Lending) program enrollment status and appropriateness assessment for the lending program.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserFpslEnrolment tracks whether each customer has enrolled in the FPSL (Fully Paid Securities Lending) program, along with their appropriateness assessment for participating. In FPSL, customers lend their fully-paid shares to short sellers via Apex Clearing in exchange for income. This requires a separate suitability assessment to ensure the customer understands the risks of securities lending.

Data is written by Apex.SaveUserFpslEnrolment and Apex.SaveUserFpslAppropriateness. System versioning with History.UserFpslEnrolment.

---

## 2. Business Logic

### 2.1 FPSL Enrollment with Appropriateness Gate

**What**: FPSL enrollment requires a separate appropriateness test specifically for the lending product.

**Columns/Parameters Involved**: `FpslEnrolmentStatusID`, `AppropriatenessTestResultID`, `AppropriatenessProductID`

**Rules**:
- AppropriatenessProductID is always 2 (FPSL) for records in this table
- AppropriatenessTestResultID must be 2 (Passed) before enrollment is permitted
- FpslEnrolmentStatusID tracks the enrollment decision (implicit FK - likely uses UserProgramEnrolmentStatus values)

---

## 3. Data Overview

| GCID | FpslEnrolmentStatusID | AppropTestResult | AppropProduct | RecalcReason | Meaning |
|------|-----------------------|-----------------|---------------|-------------|---------|
| 11 | 0 (None) | 0 (None) | 2 (FPSL) | 0 (None) | Customer has an FPSL enrollment record but has not yet been tested or enrolled. Default state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. One FPSL enrollment record per customer. |
| 2 | FpslEnrolmentStatusID | int | NO | - | CODE-BACKED | Enrollment status for the FPSL program. Likely uses same values as UserProgramEnrolmentStatus: 0=None, 1=OptIn, 2=OptOut. |
| 3 | AppropriatenessTestResultID | int | NO | - | VERIFIED | Suitability test result for the FPSL product. 0=None, 1=Failed, 2=Passed. See [Appropriateness Test Result](_glossary.md#appropriateness-test-result). |
| 4 | AppropriatenessProductID | int | NO | - | VERIFIED | The product being assessed. FK to Dictionary.AppropriatenessProduct. Always 2 (FPSL) for this table. See [Appropriateness Product](_glossary.md#appropriateness-product). (Dictionary.AppropriatenessProduct) |
| 5 | AppropriatenessRecalculationReasonID | int | NO | - | CODE-BACKED | Reason for recalculation. See [Appropriateness Recalculation Reason](_glossary.md#appropriateness-recalculation-reason). |
| 6 | BeginTime | datetime2(0) | NO | dateadd(second,(-1),sysutcdatetime()) | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserFpslEnrolment. |
| 7 | EndTime | datetime2(0) | NO | '9999.12.31 23:59:59.99' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AppropriatenessProductID | Dictionary.AppropriatenessProduct | FK | Product classification (always FPSL for this table) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveUserFpslEnrolment | @GCID | Writer | Upserts enrollment status |
| Apex.SaveUserFpslAppropriateness | @GCID | Writer | Updates appropriateness results |
| Apex.GetUserFpslEnrolment | @GCID | Reader | Retrieves enrollment data |
| Apex.DeleteUserFpslEnrolment | @GCID | Deleter | Removes enrollment record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.UserFpslEnrolment (table)
└── Dictionary.AppropriatenessProduct (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AppropriatenessProduct | Table | FK for AppropriatenessProductID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveUserFpslEnrolment | Stored Procedure | Writer |
| Apex.SaveUserFpslAppropriateness | Stored Procedure | Writer |
| Apex.GetUserFpslEnrolment | Stored Procedure | Reader |
| Apex.DeleteUserFpslEnrolment | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserFpslEnrolment | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserFpslEnrolment | PRIMARY KEY | Clustered on GCID |
| FK_UserFpslEnrolment_AppropriatenessProduct | FOREIGN KEY | AppropriatenessProductID -> Dictionary.AppropriatenessProduct |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserFpslEnrolment |

---

## 8. Sample Queries

### 8.1 Get FPSL enrollment status with resolved values

```sql
SELECT uf.GCID, uf.FpslEnrolmentStatusID,
       atr.Name AS TestResult, ap.Name AS Product
FROM Apex.UserFpslEnrolment uf WITH (NOLOCK)
INNER JOIN Dictionary.AppropriatenessTestResult atr WITH (NOLOCK) ON atr.AppropriatenessTestResultID = uf.AppropriatenessTestResultID
INNER JOIN Dictionary.AppropriatenessProduct ap WITH (NOLOCK) ON ap.AppropriatenessProductID = uf.AppropriatenessProductID
WHERE uf.GCID = 11;
```

### 8.2 Find enrolled FPSL customers

```sql
SELECT GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID
FROM Apex.UserFpslEnrolment WITH (NOLOCK)
WHERE FpslEnrolmentStatusID = 1;
```

### 8.3 FPSL enrollment change history

```sql
SELECT GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID, BeginTime, EndTime
FROM Apex.UserFpslEnrolment WITH (NOLOCK) WHERE GCID = 11
UNION ALL
SELECT GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID, BeginTime, EndTime
FROM History.UserFpslEnrolment WITH (NOLOCK) WHERE GCID = 11
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserFpslEnrolment | Type: Table | Source: USABroker/Apex/Tables/Apex.UserFpslEnrolment.sql*
