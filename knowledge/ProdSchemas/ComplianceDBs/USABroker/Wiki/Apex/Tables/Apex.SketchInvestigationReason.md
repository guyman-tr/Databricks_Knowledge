# Apex.SketchInvestigationReason

> Configuration/reference table defining all known CIP investigation reason codes from Sketch/Equifax, their descriptions, severity types, and whether each reason permits automatic appeal.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.SketchInvestigationReason is a configuration table that defines all known reason codes returned by the Sketch identity verification system (backed by Equifax). Each row maps a Sketch/Equifax reason code to a human-readable description, categorizes it by severity (Indeterminate vs Reject), and specifies whether the system can automatically appeal that reason.

This table drives the auto-appeal decision logic. When a CIP investigation returns with findings, the system looks up each reason constant in this table to determine: (1) Is this an Indeterminate result (might pass on retry) or a Reject (definitive failure)? (2) Can we automatically appeal this reason, or does it require manual intervention? Only active reasons (Active=1) are considered in the decision.

Data is loaded as configuration and retrieved by Apex.GetSketchInvestigationReasons (which returns all active reasons). The table is not modified by normal application operations - it is maintained as reference data.

---

## 2. Business Logic

### 2.1 Auto-Appeal Decision Rules

**What**: Each investigation reason has a CanAutoAppeal flag that determines whether the system can automatically retry/appeal the investigation when that specific reason is the blocker.

**Columns/Parameters Involved**: `ReasonTypeID`, `CanAutoAppeal`, `ReasonConstant`

**Rules**:
- ReasonTypeID=1 (Indeterminate): Warnings about suspicious addresses, SSN anomalies, fraud alerts. All observed Indeterminate reasons have CanAutoAppeal=false - these require manual review
- ReasonTypeID=2 (Reject): Definitive verification failures. Some Reject reasons CAN be auto-appealed (e.g., DOB_NOT_VERIFIED, SSN_NOT_VERIFIED, ADDRESS_NOT_VERIFIED - customer may resubmit corrected data)
- Address-related warnings (ReasonCode 25, 26, 28, 29, 31, 32, 88) are all Indeterminate and cannot be auto-appealed
- Fraud-related findings (FL, 99) are Indeterminate and cannot be auto-appealed
- Verification failures (47, 49, 36) are Reject type but CAN be auto-appealed (customer may correct and retry)

**Diagram**:
```
Sketch Investigation Result
    |
    v
For each reason returned:
    |
    +-> Lookup in SketchInvestigationReason by ReasonConstant
    |       |
    |       +-> Active = 0? --> Skip (deprecated reason)
    |       +-> Active = 1? --> Check CanAutoAppeal
    |                               |
    |                               +-> true  --> Eligible for auto-appeal
    |                               +-> false --> Requires manual review
    |
    v
If ALL reasons are CanAutoAppeal=true --> Auto-appeal
If ANY reason is CanAutoAppeal=false --> Manual review required
    (Record those in SketchInvestigationDoNotAppealReason)
```

---

## 3. Data Overview

| ID | ReasonTypeID | ReasonCode | ReasonConstant | CanAutoAppeal | Meaning |
|----|-------------|------------|----------------|---------------|---------|
| 1 | 1 (Indeterminate) | 88 | WARNING_INQUIRY_ADDRESS_IS_A_POST_OFFICE_OR_CHECK_CASHING_FACILITY | false | Address is flagged as suspicious (post office/check cashing) - cannot auto-appeal, requires manual investigation of address legitimacy. |
| 13 | 1 (Indeterminate) | FL | FRAUD_VICTIM_ALERT_PRESENT_IN_DATABASE | false | Equifax records show a fraud victim alert on this SSN - highest severity warning, manual review mandatory to protect potential fraud victim. |
| 22 | 2 (Reject) | 47 | SSN_NOT_VERIFIED | true | SSN failed verification but can be auto-appealed - customer may resubmit with correct SSN or supporting documents. |
| 26 | 2 (Reject) | 36 | ADDRESS_NOT_VERIFIED | true | Address verification failed but auto-appeal is permitted - customer may correct address and retry. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Not sequential (gaps exist: IDs 2, 9, 12, 14 are missing). 22 active reasons configured. |
| 2 | ReasonTypeID | int | NO | - | VERIFIED | Category of investigation reason. FK to Dictionary.SketchInvestigationReasonType: 1=Indeterminate (warning, inconclusive), 2=Reject (definitive failure). See [Sketch Investigation Reason Type](_glossary.md#sketch-investigation-reason-type). Determines severity classification. (Dictionary.SketchInvestigationReasonType) |
| 3 | ReasonCode | varchar(50) | YES | - | CODE-BACKED | The Equifax/Sketch numeric or alphanumeric reason code from the identity verification response. Examples: "88", "47", "FL", "3A". Used for matching API responses to configuration. NULL should not occur for active reasons. |
| 4 | ReasonDescription | varchar(1024) | YES | - | CODE-BACKED | Human-readable description of what this investigation reason means. Typically sourced from Equifax documentation. Displayed to operations staff and used in customer communications. |
| 5 | ReasonConstant | varchar(500) | NO | - | VERIFIED | Machine-readable constant name used in application code to reference this reason. Examples: SSN_NOT_VERIFIED, ADDRESS_NOT_VERIFIED, FRAUD_VICTIM_ALERT_PRESENT_IN_DATABASE. Matched against the ReasonConstant in SketchInvestigationDoNotAppealReason for cross-referencing. |
| 6 | CanAutoAppeal | bit | NO | 0 | VERIFIED | Whether the system can automatically appeal/retry when this reason is the blocker. 1=auto-appeal permitted (verification failures that customer can correct), 0=manual review required (fraud alerts, suspicious address warnings). Default is false (conservative - new reasons default to requiring manual review). |
| 7 | Active | bit | NO | 1 | CODE-BACKED | Whether this reason is currently active in the system. 1=active (used by GetSketchInvestigationReasons), 0=deprecated/disabled. Default is true. Only active reasons are loaded by the application. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReasonTypeID | Dictionary.SketchInvestigationReasonType | FK | Categorizes as Indeterminate or Reject |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.GetSketchInvestigationReasons | - | Reader | Retrieves all active investigation reasons |
| Apex.SketchInvestigationDoNotAppealReason | ReasonConstant | Implicit | Transactional table records per-customer instances matching these configuration entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.SketchInvestigationReason (table)
└── Dictionary.SketchInvestigationReasonType (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.SketchInvestigationReasonType | Table | FK for ReasonTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.GetSketchInvestigationReasons | Stored Procedure | Reader - retrieves active reasons |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SketchInvestigationReason | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SketchInvestigationReason | PRIMARY KEY | Clustered on ID |
| FK_SketchInvestigationReason_SketchInvestigationReasonType | FOREIGN KEY | ReasonTypeID -> Dictionary.SketchInvestigationReasonType |
| DF_SketchInvestigationReason_CanAutoAppeal | DEFAULT | CanAutoAppeal = 0 (conservative default - new reasons require manual review) |
| DF_SketchInvestigationReason_Active | DEFAULT | Active = 1 (new reasons are active by default) |

---

## 8. Sample Queries

### 8.1 Get all active investigation reasons with type names

```sql
SELECT r.ID, rt.Name AS ReasonType, r.ReasonCode,
       r.ReasonConstant, r.CanAutoAppeal, r.ReasonDescription
FROM Apex.SketchInvestigationReason r WITH (NOLOCK)
INNER JOIN Dictionary.SketchInvestigationReasonType rt WITH (NOLOCK)
    ON rt.SketchInvestigationReasonTypeID = r.ReasonTypeID
WHERE r.Active = 1
ORDER BY r.ReasonTypeID, r.ReasonCode;
```

### 8.2 List reasons that can be auto-appealed vs manual-only

```sql
SELECT CASE WHEN CanAutoAppeal = 1 THEN 'Auto-Appeal' ELSE 'Manual Review' END AS Category,
       COUNT(*) AS ReasonCount
FROM Apex.SketchInvestigationReason WITH (NOLOCK)
WHERE Active = 1
GROUP BY CanAutoAppeal;
```

### 8.3 Match a specific investigation finding to its configuration

```sql
SELECT r.ReasonConstant, r.ReasonDescription, r.CanAutoAppeal,
       rt.Name AS ReasonType
FROM Apex.SketchInvestigationReason r WITH (NOLOCK)
INNER JOIN Dictionary.SketchInvestigationReasonType rt WITH (NOLOCK)
    ON rt.SketchInvestigationReasonTypeID = r.ReasonTypeID
WHERE r.ReasonConstant = 'SSN_NOT_VERIFIED' AND r.Active = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.SketchInvestigationReason | Type: Table | Source: USABroker/Apex/Tables/Apex.SketchInvestigationReason.sql*
