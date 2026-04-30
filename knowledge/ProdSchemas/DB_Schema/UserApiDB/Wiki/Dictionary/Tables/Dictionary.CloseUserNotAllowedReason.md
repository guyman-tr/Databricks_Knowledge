# Dictionary.CloseUserNotAllowedReason

> Lookup table defining blocking conditions that prevent a user's account closure request from being processed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CloseUserNotAllowedReasonId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CloseUserNotAllowedReason defines the specific conditions that block a user from closing their account through self-service. When a user initiates the account closure flow, the system checks for these blocking conditions and, if any are present, informs the user what must be resolved first.

This table exists for regulatory and operational safety. Accounts with open positions, pending withdrawals, or significant equity cannot be closed without proper unwinding. Closing an account with open positions could result in uncontrolled liquidation, and closing with pending cashouts could lose user funds.

The system evaluates these conditions in real-time when a user enters the closure flow. If any blocking condition is detected, the closure is prevented and the user sees a message explaining what needs to be resolved (e.g., "Please close all open positions before closing your account").

---

## 2. Business Logic

### 2.1 Account Closure Blocking Conditions

**What**: Pre-conditions that must be cleared before an account can be closed.

**Columns/Parameters Involved**: `CloseUserNotAllowedReasonId`, `CloseUserNotAllowedReasonName`

**Rules**:
- All blocking conditions are checked simultaneously - any single one prevents closure
- TooHighEquity (1): account equity exceeds the self-service closure threshold (requires CS intervention)
- OpenOrders/OpenPositions/OpenMirrors (2,3,4): active trading activity must be unwound first
- OpenCashouts (5): pending withdrawals must complete before closure
- WalletNotAllowedToClose (6): eToro Money wallet has its own restrictions (e.g., pending crypto transfers)

---

## 3. Data Overview

| CloseUserNotAllowedReasonId | CloseUserNotAllowedReasonName | Meaning |
|---|---|---|
| 1 | TooHighEquity | Account equity exceeds the self-service closure threshold - user must contact support |
| 2 | OpenOrders | Pending limit/stop orders exist that must be cancelled before closure |
| 3 | OpenPositions | Active trading positions must be closed (sold/bought back) before account closure |
| 4 | OpenMirrors | User is actively copy-trading other users - must stop all copy relationships first |
| 5 | OpenCashouts | Withdrawal requests are in progress - must wait for completion or cancel |
| 6 | WalletNotAllowedToClose | eToro Money wallet has restrictions preventing closure (pending crypto, compliance holds) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CloseUserNotAllowedReasonId | int | NO | - | CODE-BACKED | Primary key. Blocking condition: 1=TooHighEquity, 2=OpenOrders, 3=OpenPositions, 4=OpenMirrors, 5=OpenCashouts, 6=WalletNotAllowedToClose. See [Close User Not Allowed Reason](_glossary.md#close-user-not-allowed-reason). |
| 2 | CloseUserNotAllowedReasonName | varchar(60) | NO | - | CODE-BACKED | PascalCase identifier for the blocking condition. Used as localization key and in API responses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer closure flow tables | CloseUserNotAllowedReasonId | Lookup | Records which blocking conditions were present when user attempted closure |

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
| PK_CloseUserNotAllowedReason | CLUSTERED PK | CloseUserNotAllowedReasonId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all blocking conditions
```sql
SELECT CloseUserNotAllowedReasonId, CloseUserNotAllowedReasonName
FROM Dictionary.CloseUserNotAllowedReason WITH (NOLOCK)
ORDER BY CloseUserNotAllowedReasonId
```

### 8.2 Check if a user has any blocking conditions
```sql
SELECT r.CloseUserNotAllowedReasonName
FROM Customer.CloseUserBlockingConditions b WITH (NOLOCK)
JOIN Dictionary.CloseUserNotAllowedReason r WITH (NOLOCK) ON b.ReasonId = r.CloseUserNotAllowedReasonId
WHERE b.CustomerID = @CustomerID
```

### 8.3 Most common blocking conditions
```sql
SELECT r.CloseUserNotAllowedReasonName, COUNT(*) AS OccurrenceCount
FROM Customer.CloseUserBlockingConditions b WITH (NOLOCK)
JOIN Dictionary.CloseUserNotAllowedReason r WITH (NOLOCK) ON b.ReasonId = r.CloseUserNotAllowedReasonId
GROUP BY r.CloseUserNotAllowedReasonName
ORDER BY OccurrenceCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CloseUserNotAllowedReason | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CloseUserNotAllowedReason.sql*
