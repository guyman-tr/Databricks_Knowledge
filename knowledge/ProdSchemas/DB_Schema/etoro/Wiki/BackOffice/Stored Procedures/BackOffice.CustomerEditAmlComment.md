# BackOffice.CustomerEditAmlComment

> Updates the AMLComment field on BackOffice.Customer for a specific customer, used by BackOffice agents to record Anti-Money Laundering compliance notes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure allows BackOffice compliance agents to write or update the AML (Anti-Money Laundering) comment on a customer's record. The AMLComment field in BackOffice.Customer is a free-text compliance note where agents document suspicious activity observations, enhanced due diligence findings, investigation references, PEP (Politically Exposed Person) notes, and other AML-related observations.

The AMLComment is subsequently read by `BackOffice.Approval_GetCustomerRedeemInfo` before the approval service processes real stock redemption requests - ensuring that compliance flags set via this procedure surface during withdrawal approval workflows.

Created by Geri Reshef on 2018-04-09 (ticket 51005, OPS0435 "DB changes for OPS0435 - Comments for economic profile report").

---

## 2. Business Logic

### 2.1 AML Comment Update

**What**: Overwrites the AMLComment for the specified customer.

**Columns/Parameters Involved**: `@CID`, `@Comments`, `BackOffice.Customer.AMLComment`

**Rules**:
- UPDATE BackOffice.Customer SET AMLComment=@Comments WHERE CID=@CID
- @Comments replaces the existing AMLComment entirely (no append)
- Pass NULL or empty string to clear an existing AML comment
- Returns 0 always (RETURN 0 hardcoded - no error handling)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. The customer whose AML comment is being set. PK of BackOffice.Customer. |
| 2 | @Comments | VARCHAR(1024) | NO | - | CODE-BACKED | The AML compliance note text. Free-text field for recording suspicious activity, EDD findings, PEP status, investigation references. Max 1024 characters. Replaces existing comment entirely. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | Always 0 (hardcoded RETURN 0). No error handling; SQL errors propagate as unhandled exceptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER | Updates AMLComment WHERE CID=@CID |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. AMLComment set by this procedure is read by BackOffice.Approval_GetCustomerRedeemInfo before redeem approval.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerEditAmlComment (procedure)
+-- BackOffice.Customer (table) [UPDATE target - AMLComment]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: sets AMLComment=@Comments WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice compliance UI | External | Calls this to record or update AML compliance notes on a customer |
| BackOffice.Approval_GetCustomerRedeemInfo | Procedure | Reads AMLComment written by this procedure during redeem approval workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Always returns 0 | Design | RETURN 0 hardcoded - no error check after UPDATE; SQL errors propagate as exceptions |
| Full overwrite | Application | @Comments fully replaces AMLComment; callers must read existing comment before calling if append behavior is needed |
| Audit implications | Business | AML comments may be subject to regulatory record retention; changes should be logged in an audit system external to this procedure |

---

## 8. Sample Queries

### 8.1 Set an AML comment for a customer

```sql
EXEC BackOffice.CustomerEditAmlComment
    @CID = 12345,
    @Comments = 'EDD required - high volume cash deposits inconsistent with stated income. Flagged 2026-03-17.'
```

### 8.2 Clear an AML comment

```sql
EXEC BackOffice.CustomerEditAmlComment
    @CID = 12345,
    @Comments = NULL   -- or empty string ''
```

### 8.3 Check AML comment before a redeem approval

```sql
-- Done by BackOffice.Approval_GetCustomerRedeemInfo, but directly:
SELECT CID, AMLComment
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerEditAmlComment | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerEditAmlComment.sql*
