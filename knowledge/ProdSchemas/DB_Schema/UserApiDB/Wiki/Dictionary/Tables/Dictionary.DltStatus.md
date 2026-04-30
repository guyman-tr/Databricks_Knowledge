# Dictionary.DltStatus

> Lookup table defining Distributed Ledger Technology (blockchain) verification status codes for crypto-related operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DltStatusID (TINYINT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.DltStatus tracks the lifecycle of DLT (Distributed Ledger Technology / blockchain) verification processes. When users perform crypto-related operations that require on-chain verification (e.g., wallet address validation, transaction confirmation), each verification goes through a defined set of states from Pending through to Passed or Failed.

This table supports crypto compliance and operational monitoring. DLT verification is part of the crypto asset custody workflow, particularly relevant under MiCA regulation. Without status tracking, the platform could not monitor verification progress, retry failed verifications, or report on verification outcomes.

Status transitions follow a standard lifecycle: a verification starts as Pending (1), moves to Ongoing (2) during processing, and terminates as either Passed (4) or Failed (3). Inactive (5) indicates a verification that was abandoned or is no longer relevant.

---

## 2. Business Logic

### 2.1 DLT Verification Lifecycle

**What**: State machine for DLT verification processes.

**Columns/Parameters Involved**: `DltStatusID`, `Name`

**Rules**:
- Pending (1) -> Ongoing (2) -> Passed (4) or Failed (3)
- Inactive (5) can be set at any point to abandon the verification
- Only Passed (4) allows the associated crypto operation to proceed

**Diagram**:
```
Pending(1) -> Ongoing(2) -> Passed(4)
                |               
                +-> Failed(3)   
    Any state -> Inactive(5)
```

---

## 3. Data Overview

| DltStatusID | Name | Meaning |
|---|---|---|
| 1 | Pending | DLT verification request submitted but not yet picked up for processing |
| 2 | Ongoing | DLT verification actively in progress - blockchain queries or confirmations underway |
| 3 | Failed | DLT verification did not pass - address invalid, transaction unconfirmed, or compliance check failed |
| 4 | Passed | DLT verification successful - crypto operation may proceed |
| 5 | Inactive | DLT verification abandoned or no longer applicable |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DltStatusID | tinyint | NO | - | CODE-BACKED | Primary key. DLT verification state: 1=Pending, 2=Ongoing, 3=Failed, 4=Passed, 5=Inactive. See [DLT Status](_glossary.md#dlt-status). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable status label used in monitoring dashboards and compliance reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer DLT verification tables | DltStatusID | Lookup | Tracks current state of each DLT verification |

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
| PK_DltStatus | CLUSTERED PK | DltStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all DLT statuses
```sql
SELECT DltStatusID, Name
FROM Dictionary.DltStatus WITH (NOLOCK)
ORDER BY DltStatusID
```

### 8.2 Find pending DLT verifications
```sql
SELECT v.CustomerID, v.CreatedDate, ds.Name AS Status
FROM Customer.DltVerifications v WITH (NOLOCK)
JOIN Dictionary.DltStatus ds WITH (NOLOCK) ON v.DltStatusID = ds.DltStatusID
WHERE v.DltStatusID = 1 -- Pending
```

### 8.3 DLT verification outcome distribution
```sql
SELECT ds.Name, COUNT(*) AS VerificationCount
FROM Customer.DltVerifications v WITH (NOLOCK)
JOIN Dictionary.DltStatus ds WITH (NOLOCK) ON v.DltStatusID = ds.DltStatusID
GROUP BY ds.Name
ORDER BY VerificationCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DltStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.DltStatus.sql*
