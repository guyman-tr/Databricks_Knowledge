# Eligibility.GetResolvedAllowedUsingWalletStatus

> Resolves a customer's effective crypto eligibility status by looking up the GroupValue + CustomerValue combination in the StatusMap.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resolved Status from Eligibility.StatusMap |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the core status resolution endpoint. Given a group-level eligibility status and a customer-level override, it returns the resolved effective status that determines what crypto operations the customer can perform. It is the database counterpart to the in-memory resolution performed by the Eligibility Service when the cached matrix is available.

The procedure directly queries `Eligibility.StatusMap` using the two-column lookup (GroupValue + CustomerValue). This is used as a fallback when the cached resolution matrix is unavailable, or for ad-hoc status checks.

---

## 2. Business Logic

### 2.1 Direct Matrix Lookup

**What**: Simple two-column equality lookup returning the resolved status.

**Columns/Parameters Involved**: `@GroupValue`, `@CustomerValue`

**Rules**:
- Filters StatusMap WHERE GroupValue = @GroupValue AND CustomerValue = @CustomerValue
- Returns the Status column (the resolved effective eligibility)
- Uses NOLOCK for performance
- If no matching row exists (invalid combination), returns empty result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GroupValue | INT (IN) | NO | - | VERIFIED | Group-level eligibility status from InfraSetting. Maps to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. Per HLD: "AllowedUsingWalletStatus." |
| 2 | @CustomerValue | INT (IN) | NO | - | VERIFIED | Customer-level eligibility override. Maps to Dictionary.EligibilityStatuses. Per HLD: "AllowedUsingWalletStatusCustomerLevel." Note: declared as INT but StatusMap.CustomerValue is nullable tinyint - NULL handling depends on the calling application. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Status | tinyint | NO | - | VERIFIED | The resolved effective eligibility status. This is the final answer that all downstream services use to gate crypto operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT FROM | Eligibility.StatusMap | READER | Looks up resolved status by GroupValue + CustomerValue |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project. Called by the Eligibility Service.

---

## 6. Dependencies

```
Eligibility.GetResolvedAllowedUsingWalletStatus (procedure)
+-- Eligibility.StatusMap (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.StatusMap | Table | Lookup source for status resolution |

### 6.2 Objects That Depend On This

No callers found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Resolve status for AllOperations group with ReadOnly customer override
```sql
EXEC Eligibility.GetResolvedAllowedUsingWalletStatus @GroupValue = 2, @CustomerValue = 1
-- Returns: Status = 1 (ReadOnly)
```

### 8.2 Resolve status when group is Blocked
```sql
EXEC Eligibility.GetResolvedAllowedUsingWalletStatus @GroupValue = 0, @CustomerValue = 2
-- Returns: Status = 0 (BlockedFromAccess) - group block always wins
```

### 8.3 Direct equivalent query
```sql
SELECT Status FROM Eligibility.StatusMap WITH (NOLOCK)
WHERE GroupValue = @GroupValue AND CustomerValue = @CustomerValue
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Confirms this procedure implements the "Getting Eligibility results" resolution logic. The HLD provides the complete resolution matrix and confirms GroupValue = AllowedUsingWalletStatus and CustomerValue = AllowedUsingWalletStatusCustomerLevel. |

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.GetResolvedAllowedUsingWalletStatus | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.GetResolvedAllowedUsingWalletStatus.sql*
