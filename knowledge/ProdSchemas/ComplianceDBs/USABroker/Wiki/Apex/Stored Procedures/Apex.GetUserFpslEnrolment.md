# Apex.GetUserFpslEnrolment

> Retrieves a customer's FPSL (Fully Paid Securities Lending) enrollment status and appropriateness test results by GCID.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns UserFpslEnrolment row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetUserFpslEnrolment retrieves the FPSL enrollment record for a customer, including enrollment status, appropriateness test result, product classification, and recalculation reason. Used to determine if a customer is enrolled in the securities lending program and whether they passed the suitability assessment.

---

## 2. Business Logic

No complex business logic. Simple SELECT by GCID with NOLOCK.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to retrieve FPSL enrollment for. |

**Returns**: GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID, AppropriatenessProductID, AppropriatenessRecalculationReasonID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.UserFpslEnrolment | Read | Retrieves by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetUserFpslEnrolment (procedure)
└── Apex.UserFpslEnrolment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserFpslEnrolment | Table | Read by GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check FPSL enrollment

```sql
EXEC Apex.GetUserFpslEnrolment @GCID = 11;
```

### 8.2 Verify appropriateness test result

```sql
EXEC Apex.GetUserFpslEnrolment @GCID = 19533157;
-- Check if AppropriatenessTestResultID = 2 (Passed)
```

### 8.3 Check enrollment for non-existent customer

```sql
EXEC Apex.GetUserFpslEnrolment @GCID = 999999;
-- Empty result if not enrolled
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetUserFpslEnrolment | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetUserFpslEnrolment.sql*
