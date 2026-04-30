# Dictionary.PlayerStatus

> Reference table defining account statuses with a granular permission matrix controlling trading, deposits, withdrawals, login, and social features.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.PlayerStatus is one of the most critical lookup tables in UserApiDB. It defines 15 distinct account statuses, each with a granular permission matrix that controls exactly what actions a user can perform on the platform. This enables fine-grained account restriction rather than a simple active/blocked binary, supporting compliance workflows that need to restrict specific activities while preserving others.

This table exists to support complex regulatory and operational scenarios. A user under PayPal investigation needs trading blocked but may need to close existing positions. A user pending verification can view but not open new trades. A scalper needs full blocking. Each scenario requires a different combination of permissions, which this table codifies.

PlayerStatus is set by compliance agents, automated rules engines, and user self-service flows. It is stored on the user's core profile and checked on virtually every platform action. The dbo.Dictionary_PlayerStatus synonym provides cross-schema access. PlayerStatusReasons and PlayerStatusSubReasons provide the "why" behind each status change.

---

## 2. Business Logic

### 2.1 Permission Matrix

**What**: 10-dimensional permission system controlling all user actions.

**Columns/Parameters Involved**: `IsBlocked`, `CanEditPosition`, `CanOpenPosition`, `CanClosePosition`, `CanDeposit`, `CanRequestWithdraw`, `CanLogin`, `CanChatAndPost`, `CanBeCopied`, `CanCopy`

**Rules**:
- IsBlocked=true implies CanLogin=false (complete lockout, statuses 2,4,6,7,8,14)
- Partial blocks (9,10,13,15) allow login and closing existing positions but restrict new activity
- CanCopy defaults to true for all statuses (copy relationships are managed separately)
- Normal (1) is the only status with full unrestricted access
- Warning (5) has full access but the account is flagged for monitoring
- Copy Block (12) only restricts copying - all other actions allowed

### 2.2 Block Severity Tiers

**What**: Three tiers of account restriction severity.

**Columns/Parameters Involved**: `PlayerStatusID`, `IsBlocked`, `CanLogin`

**Rules**:
- **Full Block** (IsBlocked=true): Statuses 2,4,6,7,8,14 - no login, no actions, complete lockout
- **Partial Block** (IsBlocked=false, some actions restricted): Statuses 9,10,13,15 - can login, limited actions
- **Soft Restriction** (IsBlocked=false, most actions allowed): Statuses 3,5,11,12 - minimal impact
- **No Restriction**: Status 1 (Normal) only

**Diagram**:
```
Full Block (no login):
  2=Blocked, 4=Blocked Upon Request, 6=Under Investigation,
  7=Scalpers Block, 8=PayPal Investigation, 14=Failed Verification

Partial Block (login OK, limited actions):
  9=Trade & MIMO Blocked, 10=Deposit Blocked,
  13=Pending Verification, 15=Block Deposit & Trading

Soft Restriction (most actions OK):
  3=Chat Blocked, 5=Warning, 11=Social Index, 12=Copy Block

No Restriction:
  1=Normal
```

---

## 3. Data Overview

| PlayerStatusID | Name | IsBlocked | Key Restrictions | Meaning |
|---|---|---|---|---|
| 1 | Normal | No | None | Full platform access - default status for active, compliant users |
| 2 | Blocked | Yes | All actions blocked | Complete account lockout - compliance, fraud, or AML action |
| 9 | Trade & MIMO Blocked | No | No open/deposit/withdraw | Can close existing positions and login, but cannot open new trades or transact money |
| 13 | Pending Verification | No | No open/deposit/withdraw | KYC verification incomplete - can view portfolio and close positions only |
| 5 | Warning | No | None (flagged) | Full access but account flagged - compliance monitoring active |

*5 of 15 rows shown - selected to represent each block severity tier.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusID | int | NO | - | CODE-BACKED | Primary key. Account status identifier: 1=Normal through 15=Block Deposit & Trading. Referenced by virtually all Customer schema procedures and tables. See [Player Status](_glossary.md#player-status). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Status display name used in admin tools, compliance reports, and audit logs. |
| 3 | IsBlocked | bit | NO | - | CODE-BACKED | Master block flag. When true, user cannot login at all - complete account lockout. All individual Can* flags are false when IsBlocked=true. |
| 4 | CanEditPosition | bit | YES | - | CODE-BACKED | Whether user can modify existing position parameters (stop loss, take profit). Disabled in all blocked and trade-restricted statuses. |
| 5 | CanOpenPosition | bit | YES | - | CODE-BACKED | Whether user can open new trading positions. Disabled in all blocked, trade-restricted, and pending verification statuses. |
| 6 | CanClosePosition | bit | YES | - | CODE-BACKED | Whether user can close existing positions. True for partial blocks (9,13,15) to allow portfolio unwinding. False only for full blocks. |
| 7 | CanDeposit | bit | YES | - | CODE-BACKED | Whether user can deposit funds. Disabled for blocked statuses, Deposit Blocked (10), and pending verification statuses. |
| 8 | CanRequestWithdraw | bit | YES | - | CODE-BACKED | Whether user can request fund withdrawals. Disabled for blocked statuses, trade-restricted statuses, and Social Index (11). |
| 9 | CanLogin | bit | YES | - | CODE-BACKED | Whether user can authenticate and access the platform. False only when IsBlocked=true (full lockout statuses). |
| 10 | CanChatAndPost | bit | YES | - | CODE-BACKED | Whether user can use social features (news feed posts, comments). Disabled for Chat Blocked (3) and all full block statuses. |
| 11 | CanBeCopied | bit | YES | - | CODE-BACKED | Whether other users can copy this user's trades. Disabled only for full block statuses. Popular Investors need this for their copier base. |
| 12 | CanCopy | bit | YES | 1 | CODE-BACKED | Whether user can copy other traders. True for all statuses by default. Only Copy Block (12) sets this to false. Default: 1. |
| 13 | GetsInterest | bit | YES | - | CODE-BACKED | Whether user accrues interest on uninvested cash balance. Currently NULL for all statuses - feature not yet implemented at status level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RiskUserInfo | PlayerStatusID | Lookup | Stores user's current account status |
| History.RiskUserInfo | PlayerStatusID | Lookup | Historical tracking of status changes |
| dbo.Dictionary_PlayerStatus | - | Synonym | Cross-schema access synonym |
| Customer.GetUsersPlayerStatus | PlayerStatusID | Lookup | Retrieves user status |
| Customer.UpdateRiskUserInfo | PlayerStatusID | Lookup | Updates user status |
| Customer.GetSingleAggregatedInfo | PlayerStatusID | Lookup | Returns status in aggregated info |
| Customer.GetManyAggregatedInfo | PlayerStatusID | Lookup | Bulk status retrieval |
| Customer.InsertRealCustomer | PlayerStatusID | Lookup | Sets initial status at registration |
| Customer.InsertNewCustomer | PlayerStatusID | Lookup | Sets initial status at registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | Stores PlayerStatusID |
| History.RiskUserInfo | Table | Historical tracking |
| dbo.Dictionary_PlayerStatus | Synonym | Cross-schema access |
| Customer.GetUsersPlayerStatus | Stored Procedure | Reads PlayerStatusID |
| Customer.UpdateRiskUserInfo | Stored Procedure | Writes PlayerStatusID |
| Customer.InsertRealCustomer | Stored Procedure | Sets initial status |
| Customer.InsertNewCustomer | Stored Procedure | Sets initial status |
| Customer.GetRiskInfo | Stored Procedure | Reads PlayerStatusID |
| Customer.UpdateRiskInfo | Stored Procedure | Writes PlayerStatusID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlayerStatus | CLUSTERED PK | PlayerStatusID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PlayerStatus_CanCopy | DEFAULT | (1) - all users can copy by default |

---

## 8. Sample Queries

### 8.1 List all statuses with permissions
```sql
SELECT PlayerStatusID, RTRIM(Name) AS Name, IsBlocked, CanOpenPosition, CanDeposit, CanLogin
FROM Dictionary.PlayerStatus WITH (NOLOCK)
ORDER BY PlayerStatusID
```

### 8.2 Find blocked users
```sql
SELECT r.CustomerID, RTRIM(ps.Name) AS Status
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON r.PlayerStatusID = ps.PlayerStatusID
WHERE ps.IsBlocked = 1
```

### 8.3 Check if a user can perform a specific action
```sql
SELECT ps.CanOpenPosition, ps.CanDeposit, ps.CanRequestWithdraw, ps.CanLogin
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON r.PlayerStatusID = ps.PlayerStatusID
WHERE r.CustomerID = @CustomerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.PlayerStatus.sql*
