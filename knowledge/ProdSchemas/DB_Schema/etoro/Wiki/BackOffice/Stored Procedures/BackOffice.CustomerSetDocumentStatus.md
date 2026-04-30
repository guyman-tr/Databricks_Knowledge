# BackOffice.CustomerSetDocumentStatus

> Updates DocumentStatusID on BackOffice.Customer for a given CID. TRY/CATCH with custom 60000 error message on failure.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure directly sets the KYC document review status for a customer by updating `BackOffice.Customer.DocumentStatusID`. It is used by BackOffice agents and automated processes to advance or reset a customer's document verification state.

`DocumentStatusID` is a key KYC field that tracks the lifecycle of a customer's document review:
- Documents submitted start at status 1 (documents received, set by `BackOffice.CustomerDocumentAdd_JUNKYulia0325`)
- Agents reviewing and approving/rejecting documents advance this through higher statuses
- The status gates what a customer can do: trading limits, withdrawal caps, and feature access all depend on verification state

This SP gives direct control over the status value without performing any validation on the new status value itself - callers are responsible for providing a valid DocumentStatusID.

---

## 2. Business Logic

### 2.1 Direct Update with Error Wrapping

**What**: Simple UPDATE with TRY/CATCH that wraps SQL errors in a descriptive 60000 error.

**Rules**:
- UPDATE BackOffice.Customer SET DocumentStatusID=@DocumentStatusID WHERE CID=@CID
- No DocumentStatusID validation against a dictionary
- No @@ROWCOUNT check: silent no-op if CID not found
- CATCH: builds descriptive error message including line number, error message, and error number; RAISERROR(60000); RETURN 60000

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. No CID existence check - silent no-op if not found in BackOffice.Customer. |
| 2 | @DocumentStatusID | INT | NO | - | CODE-BACKED | New document status value to set. No validation against a dictionary. Key value: 1 = documents received/pending review. Higher values represent approved/reviewed/rejected states. |

**Return Values:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | (none on success) | - | No explicit RETURN on success path - procedure completes normally. |
| 4 | RETURN 60000 | INT | CATCH path: SQL error occurred during UPDATE. Error message format: 'An error occured at BackOffice.CustomerSetDocumentStatus (line number N. The error was [message] ([number]))'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets DocumentStatusID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice KYC workflow | External | Direct call | Advance or reset document review status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetDocumentStatus (procedure)
|- BackOffice.Customer (table) [UPDATE: DocumentStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: DocumentStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice KYC workflows | External | Document status transitions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Design | SQL errors caught and re-raised as 60000 with descriptive message |
| No validation | Design | No DocumentStatusID dictionary check; no CID existence check |
| Custom error message | Design | CATCH builds a descriptive string including line number and SQL error details |

---

## 8. Sample Queries

### 8.1 Advance a customer to document-reviewed status

```sql
EXEC BackOffice.CustomerSetDocumentStatus
    @CID = 12345,
    @DocumentStatusID = 2;   -- Value depends on Dictionary.DocumentStatus
-- Returns normally on success; throws 60000 on SQL error
```

### 8.2 Check current document status

```sql
SELECT CID, DocumentStatusID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetDocumentStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetDocumentStatus.sql*
