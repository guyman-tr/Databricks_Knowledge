# Dictionary.ApexStatus

> Lookup table defining the 16 high-level lifecycle statuses for Apex Clearing brokerage accounts, from NEW through COMPLETE, REJECTED, RESTRICTED, and CLOSED.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ApexStatus defines all possible high-level lifecycle states for an Apex Clearing brokerage account. These 16 statuses track the account from initial creation (NEW) through processing stages to terminal states (COMPLETE, REJECTED, CANCELED, CLOSED). This is one of the most referenced lookup tables in the system, used by Apex.ApexData, Apex.RequestLog, and other tables to classify account and request states.

---

## 2. Business Logic

### 2.1 Status Lifecycle Groups

**What**: The 16 statuses organize into groups representing different phases of the account lifecycle.

**Columns/Parameters Involved**: `StatusID`, `Name`

**Rules**:
- Statuses 1-8: Active processing states (NEW -> PENDING -> INVESTIGATION_SUBMITTED -> ACTION_REQUIRED -> SUSPENDED -> READY_FOR_BACK_OFFICE -> BACK_OFFICE -> ACCOUNT_SETUP)
- Statuses 9-11: Failure terminal states (CANCELED, ERROR, REJECTED)
- Status 12: Success terminal state (COMPLETE)
- Statuses 13-14: Non-applicable states (NOTAPPLICABLE, NOTEXISTS)
- Status 15: Post-creation restriction (RESTRICTED)
- Status 16: Final lifecycle state (CLOSED)

---

## 3. Data Overview

| StatusID | Name | Meaning |
|----------|------|---------|
| 1 | NEW | Application just created, no processing begun |
| 2 | PENDING | Submitted to Apex, awaiting processing |
| 3 | INVESTIGATION_SUBMITTED | Identity verification (CIP) investigation submitted to Sketch |
| 4 | ACTION_REQUIRED | Apex requires additional information from the user |
| 5 | SUSPENDED | Account temporarily suspended for compliance review |
| 6 | READY_FOR_BACK_OFFICE | Approved and ready for Apex back-office setup |
| 7 | BACK_OFFICE | Being processed by Apex back-office |
| 8 | ACCOUNT_SETUP | Account being configured in Apex systems |
| 9 | CANCELED | Application canceled before completion |
| 10 | ERROR | System error during processing |
| 11 | REJECTED | Application rejected by Apex Clearing |
| 12 | COMPLETE | Account successfully created and active |
| 13 | NOTAPPLICABLE | Status not applicable to this user/flow |
| 14 | NOTEXISTS | No Apex account record exists |
| 15 | RESTRICTED | Account restricted from trading |
| 16 | CLOSED | Account closed |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | int | NO | - | VERIFIED | Primary key. 16 values (1-16) covering the complete account lifecycle. Referenced by Apex.ApexData.StatusID (explicit FK) and Apex.RequestLog.StatusID (implicit). |
| 2 | Name | varchar(128) | NO | - | VERIFIED | UPPERCASE display name for the status. Used in API responses and UI display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.ApexData | StatusID | FK | Account lifecycle status |
| Apex.RequestLog | StatusID | Implicit | API request processing status |
| Apex.TradingApexData | StatusID | Implicit | Trading copy initial status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.ApexData | Table | FK reference for StatusID |
| Apex.RequestLog | Table | Implicit reference for StatusID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ApexStatus | CLUSTERED PK | StatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ApexStatus | PRIMARY KEY | Clustered on StatusID |

---

## 8. Sample Queries

### 8.1 Get all statuses

```sql
SELECT StatusID, Name FROM Dictionary.ApexStatus WITH (NOLOCK) ORDER BY StatusID;
```

### 8.2 Count accounts by status

```sql
SELECT s.Name, COUNT(*) AS AccountCount
FROM Apex.ApexData d WITH (NOLOCK)
INNER JOIN Dictionary.ApexStatus s WITH (NOLOCK) ON s.StatusID = d.StatusID
GROUP BY s.Name ORDER BY AccountCount DESC;
```

### 8.3 Find active (non-terminal) accounts

```sql
SELECT d.GCID, d.ApexID, s.Name AS Status
FROM Apex.ApexData d WITH (NOLOCK)
INNER JOIN Dictionary.ApexStatus s WITH (NOLOCK) ON s.StatusID = d.StatusID
WHERE d.StatusID NOT IN (9, 10, 11, 12, 13, 14, 15, 16);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ApexStatus | Type: Table | Source: USABroker/Dictionary/Tables/Dictionary.ApexStatus.sql*
