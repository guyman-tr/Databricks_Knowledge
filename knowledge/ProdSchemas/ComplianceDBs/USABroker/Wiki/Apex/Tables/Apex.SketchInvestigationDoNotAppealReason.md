# Apex.SketchInvestigationDoNotAppealReason

> Records specific CIP investigation failure reasons from Sketch/Equifax that prevent automatic appeal, creating a per-customer audit trail of identity verification blockers.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.SketchInvestigationDoNotAppealReason stores the specific reasons why a customer's identity verification (CIP) investigation cannot be automatically appealed. When Sketch (the identity verification provider, backed by Equifax) returns investigation results that are too severe for auto-appeal (e.g., SSN fraud victim warnings, address flagged as nonresidential), those reasons are recorded here per customer per investigation.

This table exists to document why the system blocked auto-appeal for a specific customer. Regulators may need to see why an application was rejected and that the platform properly handled high-risk findings from the identity verification provider. The table also informs the customer-facing experience - explaining what verification failures occurred.

Data is created by Apex.SaveSketchInvestigationDoNotAppealReason, which inserts one row per reason per investigation. A single investigation can produce multiple do-not-appeal reasons (e.g., SSN fraud + DOB mismatch). The reasons are sourced from the Equifax identity verification response and categorized by ReasonTypeID (from Dictionary.SketchInvestigationReasonType).

---

## 2. Business Logic

### 2.1 Multi-Reason Investigation Blocking

**What**: A single CIP investigation can produce multiple do-not-appeal reasons, each independently blocking auto-appeal.

**Columns/Parameters Involved**: `GCID`, `SketchID`, `ReasonTypeID`, `ReasonConstant`

**Rules**:
- Multiple rows per GCID+SketchID are common - each reason is recorded separately
- ReasonTypeID=2 (Reject) indicates reasons that definitively block the investigation
- Common reason constants: SSN_FRAUD_VICTIM, DOB_NO_SSN_RELATION_FOUND, ADDRESS_NOT_VERIFIED, ADDRESS_NONRESIDENTIAL
- SketchDataSource is typically "Equifax" - the underlying identity verification bureau
- These reasons represent the most severe findings that cannot be auto-resolved

---

## 3. Data Overview

| ID | GCID | ApexID | ReasonConstant | SketchDataSource | ReasonDescription | Meaning |
|----|------|--------|----------------|-----------------|-------------------|---------|
| 42029 | 47589917 | 3FN37587 | SSN_FRAUD_VICTIM | Equifax | Applicant profile contains a fraud victim warning | Highest severity - SSN is flagged in Equifax as belonging to a fraud victim. Account cannot be auto-approved; manual review or customer appeal required. |
| 42028 | 47589917 | 3FN37587 | DOB_NO_SSN_RELATION_FOUND | Equifax | SSN could not be verified to the date of birth | Same customer, same investigation - multiple reasons compound. SSN-DOB mismatch suggests possible identity theft. |
| 42027 | 47587063 | 3FN37570 | ADDRESS_NOT_VERIFIED | Equifax | Address could not be verified | Address fails Equifax verification - could be new address, typo, or non-residential. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. ~42K records to date. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID of the customer whose investigation produced this do-not-appeal reason. |
| 3 | ApexID | varchar(8) | NO | - | CODE-BACKED | The customer's Apex Clearing account ID. Stored here for direct reference without needing to JOIN to ApexData. |
| 4 | SketchID | uniqueidentifier | NO | - | CODE-BACKED | GUID of the Sketch investigation that produced this reason. Multiple reasons can share the same SketchID when the investigation returned multiple blockers. |
| 5 | ReasonTypeID | int | NO | - | VERIFIED | Category of the investigation reason. FK to Dictionary.SketchInvestigationReasonType: 0=None, 1=Indeterminate (inconclusive), 2=Reject (definitive failure). See [Sketch Investigation Reason Type](_glossary.md#sketch-investigation-reason-type). All observed data shows ReasonTypeID=2 (Reject). (Dictionary.SketchInvestigationReasonType) |
| 6 | ReasonConstant | varchar(500) | NO | - | VERIFIED | Machine-readable constant identifying the specific reason. Maps to constants in the Sketch/Equifax API. Examples: SSN_FRAUD_VICTIM, DOB_NO_SSN_RELATION_FOUND, ADDRESS_NOT_VERIFIED, ADDRESS_NONRESIDENTIAL. Used for programmatic handling and matching against Apex.SketchInvestigationReason configuration. |
| 7 | SketchDataSource | varchar(50) | NO | - | CODE-BACKED | The data bureau that provided this verification result. Observed value: "Equifax". Identifies which third-party data source flagged the issue. |
| 8 | ReasonDescription | varchar(1024) | YES | - | CODE-BACKED | Human-readable description of the verification failure. Examples: "Applicant profile contains a fraud victim warning", "SSN could not be verified to the date of birth provided". NULL is allowed but typically populated from the Sketch API response. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReasonTypeID | Dictionary.SketchInvestigationReasonType | FK | Categorizes as Indeterminate or Reject |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveSketchInvestigationDoNotAppealReason | all params | Writer | Inserts one reason per investigation finding |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.SketchInvestigationDoNotAppealReason (table)
└── Dictionary.SketchInvestigationReasonType (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.SketchInvestigationReasonType | Table | FK for ReasonTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveSketchInvestigationDoNotAppealReason | Stored Procedure | Writer - inserts reasons |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SketchInvestigationDoNotAppealReason | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SketchInvestigationDoNotAppealReason | PRIMARY KEY | Clustered on ID |
| FK_SketchInvestigationDoNotAppealReason_SketchInvestigationReasonType | FOREIGN KEY | ReasonTypeID -> Dictionary.SketchInvestigationReasonType |

---

## 8. Sample Queries

### 8.1 Get all do-not-appeal reasons for a customer

```sql
SELECT d.ID, d.GCID, d.ApexID, d.SketchID, d.ReasonConstant,
       d.SketchDataSource, d.ReasonDescription, rt.Name AS ReasonType
FROM Apex.SketchInvestigationDoNotAppealReason d WITH (NOLOCK)
INNER JOIN Dictionary.SketchInvestigationReasonType rt WITH (NOLOCK)
    ON rt.SketchInvestigationReasonTypeID = d.ReasonTypeID
WHERE d.GCID = 47589917
ORDER BY d.ID;
```

### 8.2 Most common do-not-appeal reasons

```sql
SELECT TOP 10 ReasonConstant, COUNT(*) AS Occurrences
FROM Apex.SketchInvestigationDoNotAppealReason WITH (NOLOCK)
GROUP BY ReasonConstant
ORDER BY Occurrences DESC;
```

### 8.3 Customers with multiple investigation blockers

```sql
SELECT GCID, SketchID, COUNT(*) AS ReasonCount
FROM Apex.SketchInvestigationDoNotAppealReason WITH (NOLOCK)
GROUP BY GCID, SketchID
HAVING COUNT(*) > 1
ORDER BY ReasonCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.SketchInvestigationDoNotAppealReason | Type: Table | Source: USABroker/Apex/Tables/Apex.SketchInvestigationDoNotAppealReason.sql*
