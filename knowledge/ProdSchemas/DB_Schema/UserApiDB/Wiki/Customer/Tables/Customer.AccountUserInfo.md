# Customer.AccountUserInfo

> Core user profile table storing account-level configuration: brand label, trade level, currency, guru (Popular Investor) status, account type, and KYC state.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.AccountUserInfo is one of the four core user profile tables (alongside BasicUserInfo, ContactUserInfo, and RiskUserInfo). It stores account-level configuration that defines the user's platform experience: which brand they see (LabelID), which trading interface they use (TradeLevelID), their account currency, their Popular Investor tier (GuruStatusID), and their KYC workflow state.

This table is central to account management. Every user has exactly one row (PK on GCID). Changes to this table are historically tracked via triggers that write to History.AccountUserInfo and trigger sync events to Sync.PendingEntityEvents (EntityType=3 for AccountInfo). It is one of the most frequently read tables in the database, accessed by virtually all aggregated user info procedures.

The table is populated during registration (Customer.InsertRealCustomer, Customer.InsertNewCustomer) and updated throughout the user lifecycle by Customer.UpdateAccountUserInfo and Customer.Bulk_UpdateAccountUserInfo.

---

## 2. Business Logic

### 2.1 Account Type Classification

**What**: Differentiates real, demo, and sub-accounts.

**Columns/Parameters Involved**: `AccountTypeID`, `MasterAccountCID`

**Rules**:
- AccountTypeID defaults to 1 (real account)
- When MasterAccountCID is not NULL, this is a sub-account linked to a master
- Sub-accounts inherit some settings from their master account

### 2.2 History and Sync Triggers

**What**: Automatic audit trail and cross-system synchronization.

**Columns/Parameters Involved**: All columns

**Rules**:
- INSERT trigger: writes initial snapshot to History.AccountUserInfo with ValidTo='3000-01-01'
- UPDATE trigger: closes current history row (sets ValidTo) and opens new one; also writes to Sync.PendingEntityEvents(EntityType=3)
- DELETE trigger: closes current history row
- INSERT/DELETE triggers are DISABLED; UPDATE trigger is ENABLED

---

## 3. Data Overview

N/A - transactional table with millions of rows. Key columns shown in elements.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID - the unique user identifier across all eToro systems. One row per user. |
| 2 | OriginalCID | int | NO | - | CODE-BACKED | The user's original Customer ID from the legacy system. Used for backward compatibility with older APIs. |
| 3 | SerialID | int | YES | - | CODE-BACKED | Serial number assigned to the user's trading account. Used in trading platform identification. |
| 4 | LabelID | int | NO | - | CODE-BACKED | White-label brand identifier. FK to Dictionary.Label. 0/1=eToro, 14=eToroUSA, etc. Determines brand-specific UI, logos, and payment pages. See [Label](_glossary.md#label). |
| 5 | TradeLevelID | int | NO | - | CODE-BACKED | Trading platform UI access level. FK to Dictionary.TradeLevel. 0=Normal, 1=eToro Pro, 2=eToro Visual. See [Trade Level](_glossary.md#trade-level). |
| 6 | CurrencyID | int | NO | 0 | CODE-BACKED | Account base currency. Default: 0. Determines PnL display and deposit/withdrawal currency. |
| 7 | PendingClosureStatusID | tinyint | YES | 1 | CODE-BACKED | Status of any pending account closure process. Default: 1. |
| 8 | AccountStatusID | tinyint | YES | 1 | CODE-BACKED | Account operational status. Default: 1 (active). |
| 9 | SubSerialID | varchar(1024) | YES | - | CODE-BACKED | Sub-serial identifier for partner/affiliate tracking systems. Free-form string. |
| 10 | FunnelFromID | int | YES | - | CODE-BACKED | Registration funnel source identifier - tracks which onboarding funnel the user came through. |
| 11 | AccountTypeID | tinyint | NO | 1 | CODE-BACKED | Account type classification. Default: 1 (real account). Distinguishes real, demo, internal, sub-accounts. |
| 12 | MasterAccountCID | int | YES | - | CODE-BACKED | For sub-accounts: the parent master account's CID. NULL for standalone accounts. Links child accounts to their controlling master. |
| 13 | ManagerID | int | YES | - | CODE-BACKED | Account manager or relationship manager CID. NULL for unmanaged accounts. |
| 14 | GuruStatusID | int | YES | - | CODE-BACKED | Popular Investor program tier. FK to Dictionary.GuruStatus. 0=No (non-PI), 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. See [Guru Status](_glossary.md#guru-status). |
| 15 | KycState | int | YES | 0 | CODE-BACKED | Current KYC (Know Your Customer) workflow state tracking the user's onboarding progress. Default: 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GuruStatusID | Dictionary.GuruStatus | Explicit FK | Popular Investor tier assignment |
| LabelID | Dictionary.Label | Explicit FK | White-label brand identity |
| TradeLevelID | Dictionary.TradeLevel | Explicit FK | Trading UI access level |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AccountUserInfo | GCID | Trigger-written | Audit trail of all account info changes |
| Sync.PendingEntityEvents | GCID | Trigger-written | Sync queue for EntityType=3 (AccountInfo) |
| Customer.GetAccountInfo | GCID | SP reads | Returns account configuration |
| Customer.GetSingleAggregatedInfo | GCID | SP reads | Included in aggregated user profile |
| Customer.UpdateAccountUserInfo | GCID | SP writes | Updates account configuration |
| Customer.Bulk_UpdateAccountUserInfo | GCID | SP writes | Bulk account updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.AccountUserInfo (table)
  +-- Dictionary.GuruStatus (table) [done]
  +-- Dictionary.Label (table) [done]
  +-- Dictionary.TradeLevel (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GuruStatus | Table | FK: GuruStatusID |
| Dictionary.Label | Table | FK: LabelID |
| Dictionary.TradeLevel | Table | FK: TradeLevelID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AccountUserInfo | Table | Trigger writes audit rows |
| Customer.GetAccountInfo | Stored Procedure | Reads from |
| Customer.UpdateAccountUserInfo | Stored Procedure | Writes to |
| Customer.InsertRealCustomer | Stored Procedure | Inserts initial row |
| Customer.InsertNewCustomer | Stored Procedure | Inserts initial row |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountUserInfo | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AccountUserInfo_CurrencyID | DEFAULT | (0) - default currency |
| DF_AccountUserInfo_PendingClosureStatusID | DEFAULT | (1) |
| DF_AccountUserInfo_AccountStatusID | DEFAULT | (1) - active |
| DF_AccountUserInfo_AccountTypeID | DEFAULT | (1) - real account |
| DF_AccountUserInfo_KycState | DEFAULT | (0) |
| FK_AccountUserInfo_GuruStatusID | FOREIGN KEY | GuruStatusID -> Dictionary.GuruStatus |
| FK_AccountUserInfo_LabelID | FOREIGN KEY | LabelID -> Dictionary.Label |
| FK_AccountUserInfo_TradeLevelID | FOREIGN KEY | TradeLevelID -> Dictionary.TradeLevel |

---

## 8. Sample Queries

### 8.1 Get account info for a user
```sql
SELECT a.GCID, a.OriginalCID, l.Name AS Label, tl.Name AS TradeLevel, gs.Name AS GuruStatus
FROM Customer.AccountUserInfo a WITH (NOLOCK)
JOIN Dictionary.Label l WITH (NOLOCK) ON a.LabelID = l.LabelID
JOIN Dictionary.TradeLevel tl WITH (NOLOCK) ON a.TradeLevelID = tl.TradeLevelID
LEFT JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON a.GuruStatusID = gs.GuruStatusID
WHERE a.GCID = @GCID
```

### 8.2 Find Popular Investors by tier
```sql
SELECT a.GCID, gs.Name AS Tier
FROM Customer.AccountUserInfo a WITH (NOLOCK)
JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON a.GuruStatusID = gs.GuruStatusID
WHERE a.GuruStatusID BETWEEN 2 AND 6
ORDER BY a.GuruStatusID
```

### 8.3 Find sub-accounts for a master
```sql
SELECT a.GCID, a.AccountTypeID, a.MasterAccountCID
FROM Customer.AccountUserInfo a WITH (NOLOCK)
WHERE a.MasterAccountCID = @MasterCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.AccountUserInfo | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.AccountUserInfo.sql*
