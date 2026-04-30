# Customer.DeletePrivacyUniqueIdentityByUserID

> Soft-deletes a social network identity by setting IsAuthorized=0 for all Customer.PrivacyUniqueIdentity rows matching a given social platform UserID - despite the "Delete" name, this is a revocation (deauthorization), not a hard delete.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserID (social network user ID to deauthorize) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeletePrivacyUniqueIdentityByUserID soft-deletes a social network identity by setting IsAuthorized=0 for all rows in Customer.PrivacyUniqueIdentity where UserID matches the provided social network user identifier. Despite the "Delete" in the name, no rows are removed - the row is retained but marked as no longer authorized.

The "delete by UserID" pattern (rather than by CID) is used when the trigger for revocation comes from the social network side rather than the customer side. For example, when a social network invalidates a user's OAuth token or notifies eToro that a user ID is no longer valid, the revocation happens by the social platform's user ID - which may be different from eToro's CID. The row is soft-deleted (IsAuthorized=0) rather than hard-deleted because preserving the identity linkage record is useful for audit trails, fraud investigation, and re-authorization flows (the user can re-link the same social account, at which point IsAuthorized is set back to 1 by Customer.SetPrivacyUniqueIdentityNew).

Contrast with Customer.DeletePrivacyUniqueIdentity (hard DELETE by CID + PrivacyRecipientID) which is used for customer-initiated unlinking and GDPR erasure.

---

## 2. Business Logic

### 2.1 Soft Delete by Social Platform UserID

**What**: Revokes authorization for a social identity without removing the linkage record.

**Columns/Parameters Involved**: `@UserID`, `Customer.PrivacyUniqueIdentity.UserID`, `IsAuthorized`

**Rules**:
- UPDATE Customer.PrivacyUniqueIdentity SET IsAuthorized=0 WHERE UserID = @UserID
- May affect multiple rows if the same social UserID is linked to multiple eToro accounts (though in normal operation, one social UserID maps to one eToro account)
- No transaction wrapper - single-statement UPDATE is auto-committed
- No return value - callers cannot distinguish "no rows matched" from "rows updated"
- IsAuthorized=0 prevents the token from being used for social login until re-authorized

### 2.2 Re-authorization Path

**What**: Soft-deleted connections can be re-activated without a new INSERT.

**Rules**:
- Customer.SetPrivacyUniqueIdentityNew sets IsAuthorized=1 on UPDATE (when GCID exists but Token is new)
- This means a customer who was deauthorized can re-link their social account and the existing row is reused
- The audit trail (row creation date etc.) is preserved through the soft-delete cycle

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserID | varchar(255) | NO | - | CODE-BACKED | The social network's own user identifier (OAuth subject ID). Maps to Customer.PrivacyUniqueIdentity.UserID (indexed for fast lookup). All rows with this UserID will be deauthorized (IsAuthorized set to 0). |

**No result set - procedure returns no output.**

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserID | Customer.PrivacyUniqueIdentity | UPDATE | Sets IsAuthorized=0 for all rows matching the social UserID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called by OAuth/social login revocation webhooks or cleanup jobs.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeletePrivacyUniqueIdentityByUserID (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | UPDATE target - sets IsAuthorized=0 WHERE UserID = @UserID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from social login revocation flows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No transaction | Design | Single-statement UPDATE - auto-committed. No rollback capability. |
| No return value | Design | No indication of affected row count. Callers cannot detect no-op (no matching UserID). |

---

## 8. Sample Queries

### 8.1 Deauthorize a social identity by UserID

```sql
EXEC Customer.DeletePrivacyUniqueIdentityByUserID @UserID = '1234567890'
```

### 8.2 Verify deauthorization

```sql
SELECT CID, GCID, PrivacyRecipientID, UserID, IsAuthorized, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE UserID = '1234567890'
```

### 8.3 Check all deauthorized connections

```sql
SELECT CID, PrivacyRecipientID, UserID, TokenExpiry
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE IsAuthorized = 0
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.DeletePrivacyUniqueIdentityByUserID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.DeletePrivacyUniqueIdentityByUserID.sql*
