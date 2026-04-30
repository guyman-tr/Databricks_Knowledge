# Dictionary.PlayerStatus

> Permission matrix table defining the behavioral restriction states of eToro user accounts, controlling which platform capabilities are enabled or disabled for each status.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerStatusID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK clustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.PlayerStatus defines 15 distinct states that an eToro user account can be in, each with a granular permission matrix controlling what the user can and cannot do on the platform. Unlike Dictionary.AccountStatus (which is a binary open/closed state), PlayerStatus provides fine-grained control over trading, deposits, withdrawals, social features, and copy-trading.

This table is critical to compliance, fraud prevention, and user lifecycle management. Compliance teams block accounts under investigation, fraud teams can restrict deposits while allowing position closure, and KYC processes put accounts into pending verification states. Each status precisely encodes which of 10 platform capabilities are permitted, enabling surgical restriction without full account lockout.

PlayerStatusID is stored in Customer.CustomerStatic and is modified by BackOffice procedures when compliance actions occur. It is read by virtually every user-facing operation — login, trading, funding, social posting, and copy-trading — to enforce permission checks. The permission flags (CanOpenPosition, CanDeposit, etc.) are queried directly from this table rather than hardcoded in business logic.

---

## 2. Business Logic

### 2.1 Permission Matrix System

**What**: Each player status defines a complete set of boolean permissions that gate platform features.

**Columns/Parameters Involved**: `IsBlocked`, `CanEditPosition`, `CanOpenPosition`, `CanClosePosition`, `CanDeposit`, `CanRequestWithdraw`, `CanLogin`, `CanChatAndPost`, `CanBeCopied`, `CanCopy`, `GetsInterest`

**Rules**:
- **Full Block** (IsBlocked=1): Statuses 2, 4, 6, 7, 8, 14 — user cannot even log in. All capabilities disabled except CanCopy (legacy, always true)
- **Partial Restriction**: Statuses 3, 9, 10, 12, 13, 15 — user can access some features but not others
- **Full Access**: Statuses 1, 5 — all capabilities enabled. Status 5 (Warning) is identical to Normal in permissions but signals compliance flagging
- **Close-Only**: Statuses 9 (Trade & MIMO Blocked) and 15 (Block Deposit & Trading) — user can close existing positions but cannot open new ones or deposit. Used as a wind-down state
- **GetsInterest**: Controls overnight fee/credit eligibility. Blocked users (IsBlocked=1) do not accrue or pay overnight fees

**Diagram**:
```
User attempts action
    │
    ├── Login ──► check CanLogin ──► if false → "Account blocked"
    │
    ├── Open Position ──► check CanOpenPosition ──► if false → "Trading restricted"
    │
    ├── Close Position ──► check CanClosePosition ──► if false → "Cannot close" (rare)
    │
    ├── Deposit ──► check CanDeposit ──► if false → "Deposits blocked"
    │
    ├── Withdraw ──► check CanRequestWithdraw ──► if false → "Withdrawals blocked"
    │
    ├── Post/Chat ──► check CanChatAndPost ──► if false → "Social features blocked"
    │
    └── Copy Trader ──► check CanCopy ──► if false → "Copy restricted"

Permission Tiers:
  [1: Normal]     All ✓
  [5: Warning]    All ✓ (+ compliance flag)
  [3: Chat Block] All ✓ except social posting
  [10: Dep Block] All ✓ except deposits
  [12: Copy Block] All ✓ except copying others
  [9/15: Close Only] Close ✓, Login ✓ — everything else ✗
  [13: Pending]   Close ✓, Login ✓ — everything else ✗
  [2/4/6/7/8/14]  Full lockout — nothing permitted
```

### 2.2 Status Transition Patterns

**What**: Common pathways between player statuses driven by compliance and user lifecycle events.

**Columns/Parameters Involved**: `PlayerStatusID`

**Rules**:
- New accounts start at 1 (Normal) or 13 (Pending Verification) depending on regulation
- Compliance investigation: 1 → 6 (Under Investigation) → 1 (cleared) or 2 (blocked)
- KYC timeout: 13 (Pending) → 14 (Failed Verification) if documents not submitted in time
- Self-service closure: 1 → 4 (Blocked Upon Request)
- Scalping detection: 1 → 7 (Scalpers Block)
- PayPal fraud: 1 → 8 (PayPal Investigation)

---

## 3. Data Overview

| PlayerStatusID | Name | IsBlocked | CanOpenPosition | CanDeposit | Meaning |
|---|---|---|---|---|---|
| 1 | Normal | 0 | 1 | 1 | The default active state. User has full access to all platform features — trading, deposits, withdrawals, social, copy-trading. Assigned at registration for most regulations. |
| 2 | Blocked | 1 | 0 | 0 | Complete account lockout. The most severe restriction — user cannot even log in. Applied when compliance or fraud investigation concludes the account must be frozen entirely. All pending operations are halted. |
| 9 | Trade & MIMO Blocked | 0 | 0 | 0 | Wind-down state: user can log in, view portfolio, and close existing positions, but cannot open new positions, deposit, or withdraw. Used when compliance needs the user to wind down activity without full lockout. |
| 13 | Pending Verification | 0 | 0 | 0 | KYC incomplete: user has registered and can log in but cannot trade or move money until identity documents are verified. Common in EU (CySEC) and UK (FCA) regulations that require verification before first trade. |
| 15 | Block Deposit & Trading | 0 | 0 | 0 | Similar to status 9 but explicitly blocks deposits. User can only close positions and log in. Applied when funding sources are under investigation but existing positions should be allowed to close. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusID | int | NO | - | VERIFIED | Primary key identifying the restriction state. 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Failed Verification, 15=Block Deposit & Trading. Stored in Customer.CustomerStatic.PlayerStatusID. See [Player Status](_glossary.md#player-status). (Dictionary.PlayerStatus) |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the status. UNIQUE constraint ensures no duplicate names. Used in BackOffice UI, compliance reports, and monitoring dashboards. |
| 3 | IsBlocked | bit | NO | - | CODE-BACKED | Master block flag. When true (statuses 2, 4, 6, 7, 8, 14), ALL capabilities are disabled including login. When false, individual CanX flags control specific permissions. Checked by Customer.CustomerSafty view and login procedures (History.LogIn). |
| 4 | CanEditPosition | bit | YES | - | CODE-BACKED | Whether the user can modify existing position parameters (SL, TP, trailing stop). When false, positions are frozen in their current configuration. |
| 5 | CanOpenPosition | bit | YES | - | CODE-BACKED | Whether the user can open new trading positions. When false, the user can only close existing positions. Checked by Trade order entry procedures (Trade.OrderEntryOpen) and Stocks.AddExitOrder. |
| 6 | CanClosePosition | bit | YES | - | CODE-BACKED | Whether the user can close existing positions. Almost always true even for restricted statuses — only fully blocked accounts (IsBlocked=1) cannot close. Regulators require users to be able to exit positions. |
| 7 | CanDeposit | bit | YES | - | CODE-BACKED | Whether the user can add funds to their account. When false, the user cannot make deposits through any payment method. Checked by Billing deposit procedures (Billing.GetCustomerDepositInfo). |
| 8 | CanRequestWithdraw | bit | YES | - | CODE-BACKED | Whether the user can request withdrawals. When false, funds are locked in the account. Checked by Billing cashout procedures (BackOffice.GetCashOutRequests_Main). |
| 9 | CanLogin | bit | YES | - | CODE-BACKED | Whether the user can authenticate and access the platform. When false, login attempts are rejected at the gate. Checked by History.LogIn and History.LogInIB procedures. |
| 10 | CanChatAndPost | bit | YES | - | CODE-BACKED | Whether the user can post to the social feed, comment, or chat. When false, the user can view social content but cannot contribute. Applied by status 3 (Chat Blocked) for social policy violations. |
| 11 | CanBeCopied | bit | YES | - | CODE-BACKED | Whether other users can start copying this user's trades. When false, the user is hidden from the CopyTrader marketplace. Applied during compliance restrictions to prevent new copiers. |
| 12 | CanCopy | bit | YES | (1) | CODE-BACKED | Whether this user can copy other traders. Default is true (1) for all statuses — legacy design decision. Status 12 (Copy Block) is the only status that sets this to false. |
| 13 | GetsInterest | bit | YES | - | CODE-BACKED | Whether overnight fees/credits are calculated for this user's positions. When false, no interest accrues or is charged. Blocked users (IsBlocked=1) and financially restricted users (9, 10, 13, 15) do not get interest. Used by Trade.UpdateInterestRate calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | PlayerStatusID | Implicit Lookup | Stores the current player status for each customer |
| Customer.RegistrationRequest | PlayerStatusID | Implicit Lookup | Initial status set during registration |
| Customer.CustomerSafty (view) | PlayerStatusID | JOIN | Safety-filtered customer view includes permission flags |
| Dictionary.PlayerStatusSubReasons | PlayerStatusID | Implicit Lookup | Sub-reasons for why a specific status was applied |
| Dictionary.ChampionshipPlayerStatus | PlayerStatusID | Implicit Lookup | Championship eligibility rules per status |
| History.LogIn | PlayerStatusID | Read | Login procedure checks CanLogin permission |
| History.LogInIB | PlayerStatusID | Read | IB login checks status |
| Billing.GetCustomerDepositInfo | PlayerStatusID | Read | Deposit flow checks CanDeposit |
| Billing.GetPlayerStatusList | PlayerStatusID | Read | Returns full status list for UI |
| Billing.RedeemPayoutProcess_GetNewRecords | PlayerStatusID | Read | Redeem eligibility check |
| BackOffice.GetCashOutRequests_Main | PlayerStatusID | Read | Withdrawal processing checks status |
| BackOffice.GetRedeemDisplayData | PlayerStatusID | Read | Redeem UI display includes status |
| Compliance.GetPOIDocumentsExpirationPopulation | PlayerStatusID | Read | KYC flows reference status |
| KYCAnalyzer.GetUsersWithCfdCopy | PlayerStatusID | Read | KYC analysis checks user status |
| Internal.Monitor_CustomerPlayerStatus | PlayerStatusID | Read | Status change monitoring/alerting |
| Stocks.AddExitOrder | PlayerStatusID | Read | Exit order checks trading permissions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores PlayerStatusID per customer |
| Customer.RegistrationRequest | Table | Initial status at registration |
| Dictionary.PlayerStatusSubReasons | Table | Sub-reasons for status assignment |
| Dictionary.ChampionshipPlayerStatus | Table | Championship eligibility per status |
| Customer.CustomerSafty | View | Exposes permission flags for security-filtered queries |
| History.LogIn | Stored Procedure | Login permission check |
| Billing.GetCustomerDepositInfo | Stored Procedure | Deposit permission check |
| BackOffice.GetCashOutRequests_Main | Stored Procedure | Withdrawal permission check |
| Compliance.GetPOIDocumentsExpirationPopulation | Stored Procedure | KYC status check |
| Internal.Monitor_CustomerPlayerStatus | Stored Procedure | Status monitoring |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPLS | CLUSTERED PK | PlayerStatusID ASC | - | - | Active |
| DPLS_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPLS | PRIMARY KEY | Unique player status identifier |
| DPLS_NAME | UNIQUE | Ensures no duplicate status names |
| DF (CanCopy) | DEFAULT | CanCopy defaults to 1 — all statuses allow copying by default |

---

## 8. Sample Queries

### 8.1 List all statuses with their permission matrix
```sql
SELECT  PlayerStatusID,
        Name,
        IsBlocked,
        CanOpenPosition,
        CanClosePosition,
        CanDeposit,
        CanRequestWithdraw,
        CanLogin,
        GetsInterest
FROM    [Dictionary].[PlayerStatus] WITH (NOLOCK)
ORDER BY PlayerStatusID;
```

### 8.2 Find customers who can close but not open positions (wind-down state)
```sql
SELECT  cs.CID,
        cs.UserName,
        dps.Name AS PlayerStatus
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[PlayerStatus] dps WITH (NOLOCK)
        ON cs.PlayerStatusID = dps.PlayerStatusID
WHERE   dps.CanClosePosition = 1
        AND dps.CanOpenPosition = 0
ORDER BY cs.CID;
```

### 8.3 Count customers by status with block classification
```sql
SELECT  dps.PlayerStatusID,
        dps.Name,
        CASE WHEN dps.IsBlocked = 1 THEN 'Full Block'
             WHEN dps.CanOpenPosition = 0 THEN 'Partial Restriction'
             ELSE 'Active'
        END AS BlockCategory,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[PlayerStatus] dps WITH (NOLOCK)
        ON cs.PlayerStatusID = dps.PlayerStatusID
GROUP BY dps.PlayerStatusID, dps.Name, dps.IsBlocked, dps.CanOpenPosition
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.PlayerStatus. Business meaning derived from permission flag analysis and consumer procedure logic across Customer, BackOffice, Billing, and Compliance schemas.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 16 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PlayerStatus.sql*
