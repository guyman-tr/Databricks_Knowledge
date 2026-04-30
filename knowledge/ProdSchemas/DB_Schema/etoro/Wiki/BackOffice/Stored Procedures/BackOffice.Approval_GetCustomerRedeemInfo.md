# BackOffice.Approval_GetCustomerRedeemInfo

> Returns a customer's AML comment from BackOffice.Customer for use by the redeem approval service to check for compliance notes before approving a withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is called by the approval service to fetch a customer's AML (Anti-Money Laundering) comment before approving a redeem (real stock redemption) request. If a BackOffice agent has flagged a customer with an AML note, the approval service needs to surface that note during the approval workflow so that approvers can see any compliance concerns before authorizing the redemption.

The procedure exists as a lightweight, named interface for the approval service to read a single field from `BackOffice.Customer` without needing direct table access. It was created on 2021-07-04 by Ran Sh. specifically for this integration. The `TOP 1` guard ensures at most one row is returned even if (unexpectedly) multiple rows exist for a CID.

It is granted EXECUTE to the ApprovalUser database principal (as seen in the permissions scripts), isolating the approval service's access to only this specific operation on BackOffice.Customer.

---

## 2. Business Logic

### 2.1 AML Comment Retrieval for Redeem Approval

**What**: The AMLComment field captures compliance notes about a customer that must be considered during redeem approval.

**Columns/Parameters Involved**: `BackOffice.Customer.AMLComment`

**Rules**:
- AMLComment is a free-text field on BackOffice.Customer where agents record AML-related observations (suspicious activity, enhanced due diligence notes, investigation references)
- If AMLComment IS NULL: no AML concerns on record - approval may proceed normally
- If AMLComment is non-NULL: approval service surfaces the note to the approver for human review

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters BackOffice.Customer to the specific customer requesting the redeem. |

**Result Set - AML Comment (one row):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AMLComment | NVARCHAR | YES | NULL | CODE-BACKED | Anti-Money Laundering comment from BackOffice.Customer. Free-text field where BackOffice agents record compliance notes. NULL = no AML concerns on record. Non-NULL = compliance note exists, requires approver review. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Lookup (SELECT) | Reads AMLComment for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ApprovalUser (principal) | Permissions | EXECUTE grant | Approval service database user has EXECUTE permission |
| BusinessRuleUserForEtoro | Permissions | EXECUTE grant | Business rule service also has access |
| PROD_BIadmins | Permissions | EXECUTE grant | BI admin users have EXECUTE permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Approval_GetCustomerRedeemInfo (procedure)
+-- BackOffice.Customer (table) [SELECT AMLComment WHERE CID=@CID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | SELECT TOP 1 AMLComment WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Redeem approval service | External | Calls this procedure before approving a real stock redemption to check AML status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1 | Design | Returns at most 1 row; BackOffice.Customer has one row per CID (clustered PK) so this is a safety guard |

---

## 8. Sample Queries

### 8.1 Check a customer's AML comment before redeem approval

```sql
EXEC BackOffice.Approval_GetCustomerRedeemInfo @CID = 12345
-- Returns single row: AMLComment (NULL if no AML notes, text if compliance concern exists)
```

### 8.2 Directly query AMLComment for comparison

```sql
SELECT CID, AMLComment
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345
```

### 8.3 Find customers with AML comments (compliance audit)

```sql
SELECT TOP 20 CID, AMLComment, ModifiedDate
FROM BackOffice.Customer WITH (NOLOCK)
WHERE AMLComment IS NOT NULL
ORDER BY ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Approval_GetCustomerRedeemInfo | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.Approval_GetCustomerRedeemInfo.sql*
