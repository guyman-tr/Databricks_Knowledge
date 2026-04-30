# Apex.UserValidationErrors

> Junction table linking customers to their current set of Apex validation errors, replaced atomically on each state transition to reflect the latest validation failures.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID + ApexValidationErrorID (composite CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserValidationErrors stores the current set of validation errors for each customer in the Apex account processing workflow. When an account application or update fails validation at Apex Clearing, the specific error codes are recorded here. This table is fully replaced on each state transition - SaveState deletes all existing errors for the customer and inserts the new set from the @ValidationErrors TVP (Apex.Ids type).

This table exists to provide the UI and support teams with the specific reasons why a customer's application is in an error or action-required state. The error codes map to Dictionary.ApexValidationError, which contains 50 specific validation failure types (from field-level errors like FirstNameError to compliance blockers like CipCheckRejectedBySketch).

Data lifecycle: DELETE all for GCID, then INSERT new set - managed entirely within SaveState's transaction. Read by GetApexDataAndState (second result set). A customer with no validation errors simply has no rows here.

---

## 2. Business Logic

### 2.1 Atomic Error Set Replacement

**What**: The entire set of validation errors for a customer is replaced atomically during each state transition, ensuring the error list always reflects the current state.

**Columns/Parameters Involved**: `GCID`, `ApexValidationErrorID`

**Rules**:
- SaveState: DELETE FROM UserValidationErrors WHERE GCID=@GCID, then INSERT from @ValidationErrors TVP
- An empty @ValidationErrors TVP results in all errors being cleared (no errors in current state)
- Multiple errors per customer are common (a single validation can return multiple failures)
- The composite PK (GCID, ApexValidationErrorID) prevents duplicate error codes per customer

---

## 3. Data Overview

| GCID | ApexValidationErrorID | ErrorName | Meaning |
|------|-----------------------|-----------|---------|
| 20708 | 6 | AddressError | Customer's address failed Apex validation. This customer is in state 5 (WaitForFailingUserDataUpdate) with this address error blocking progression. |
| 60520 | 43 | CipCheckRejectedBySketch | Customer's CIP identity check was rejected by Sketch. Most severe - identity verification definitively failed. |
| 60520 | 44 | AddressCouldNotBeVerified | Same customer also has address verification failure. Multiple errors compound the rejection. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Part of composite PK. FK to Apex.State(GCID). Multiple error rows per customer are common. |
| 2 | ApexValidationErrorID | int | NO | - | VERIFIED | The specific validation error. FK to Dictionary.ApexValidationError. 50 possible values covering field errors (4-7), form errors (8-11), compliance blocks (38-39), and CIP failures (43-50). See [Apex Validation Error](_glossary.md#apex-validation-error). (Dictionary.ApexValidationError) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Apex.State | FK | Must have a corresponding State row |
| ApexValidationErrorID | Dictionary.ApexValidationError | FK | Specific validation error type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveState | @GCID, @ValidationErrors | Writer | Replaces entire error set atomically |
| Apex.GetApexDataAndState | GCID | Reader | Returns error IDs as second result set |
| Apex.DeleteUserValidationErrors | @GCID | Deleter | Removes all errors for cleanup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.UserValidationErrors (table)
├── Apex.State (table) [FK target]
└── Dictionary.ApexValidationError (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.State | Table | FK on GCID |
| Dictionary.ApexValidationError | Table | FK on ApexValidationErrorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveState | Stored Procedure | Writer - atomic replacement |
| Apex.GetApexDataAndState | Stored Procedure | Reader |
| Apex.DeleteUserValidationErrors | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserValiddationErrors | CLUSTERED PK | GCID ASC, ApexValidationErrorID ASC | - | - | Active |

Note: Constraint name has typo "Validdation" (double d) in the DDL.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserValiddationErrors | PRIMARY KEY | Composite on (GCID, ApexValidationErrorID) |
| FK_UserValiddationErrors_ApexValiddationError | FOREIGN KEY | ApexValidationErrorID -> Dictionary.ApexValidationError |
| FK_UserValiddationErrors_State | FOREIGN KEY | GCID -> Apex.State(GCID) |

---

## 8. Sample Queries

### 8.1 Get all validation errors for a customer with names

```sql
SELECT uv.GCID, uv.ApexValidationErrorID, ve.Name AS ErrorName
FROM Apex.UserValidationErrors uv WITH (NOLOCK)
INNER JOIN Dictionary.ApexValidationError ve WITH (NOLOCK)
    ON ve.ApexValidationErrorID = uv.ApexValidationErrorID
WHERE uv.GCID = 60520;
```

### 8.2 Find customers with CIP-related validation errors

```sql
SELECT DISTINCT uv.GCID, s.ApexStateID, ds.Name AS StateName
FROM Apex.UserValidationErrors uv WITH (NOLOCK)
INNER JOIN Apex.State s WITH (NOLOCK) ON s.GCID = uv.GCID
INNER JOIN Dictionary.State ds WITH (NOLOCK) ON ds.ApexStateID = s.ApexStateID
WHERE uv.ApexValidationErrorID BETWEEN 43 AND 50;
```

### 8.3 Most common validation errors

```sql
SELECT ve.Name AS ErrorName, COUNT(*) AS Occurrences
FROM Apex.UserValidationErrors uv WITH (NOLOCK)
INNER JOIN Dictionary.ApexValidationError ve WITH (NOLOCK)
    ON ve.ApexValidationErrorID = uv.ApexValidationErrorID
GROUP BY ve.Name
ORDER BY Occurrences DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserValidationErrors | Type: Table | Source: USABroker/Apex/Tables/Apex.UserValidationErrors.sql*
