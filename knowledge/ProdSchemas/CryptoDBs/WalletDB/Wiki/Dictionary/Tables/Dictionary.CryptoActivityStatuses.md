# Dictionary.CryptoActivityStatuses

> Lookup table defining the availability statuses of cryptocurrency assets on the platform, controlling whether customers can buy, sell, or hold each crypto.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the lifecycle statuses for cryptocurrency availability on the eToro platform. Each supported cryptocurrency has an activity status that controls what operations customers can perform with it. This enables the platform to gradually onboard new cryptos (ComingSoon), fully enable them (Available), or restrict operations during market events or delistings (AvailableRedeemOnly, NotActive).

Without this status system, the platform could not control per-crypto availability. This is especially important for regulatory compliance (some cryptos may need to be restricted in certain jurisdictions) and for managing the rollout of new crypto support.

The table is FK-referenced by `Wallet.CryptoTypes` which stores the master record for each supported cryptocurrency, including its current activity status.

---

## 2. Business Logic

### 2.1 Crypto Availability Lifecycle

**What**: Four-state model controlling what customers can do with each cryptocurrency.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `NotActive` (0): Cryptocurrency is disabled on the platform. No operations permitted - buy, sell, send, or receive. Used for delisted assets or assets under regulatory review.
- `ComingSoon` (1): Cryptocurrency is announced but not yet available. May appear in the UI as "coming soon" to build awareness. No transactions permitted.
- `Available` (2): Fully active. All operations permitted - buy, sell, send, receive, convert. Normal operational state.
- `AvailableRedeemOnly` (3): Restricted mode where only sell/redeem operations are permitted. Used during delistings to allow customers to exit their positions without allowing new purchases.

**Diagram**:
```
Crypto Lifecycle:
  ComingSoon (1) --> Available (2) --> AvailableRedeemOnly (3) --> NotActive (0)
       [Announced]    [Full access]    [Sell-only, delisting]      [Disabled]

  Any state can transition to NotActive (0) for emergency shutdowns.
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | NotActive | Cryptocurrency is completely disabled. No buy, sell, send, or receive operations allowed. Used for assets removed from the platform or under regulatory investigation. Customers holding this crypto see it in their portfolio but cannot transact. |
| 1 | ComingSoon | Cryptocurrency has been added to the system but is not yet available for trading. May be visible in the UI as a preview. No transactions permitted. Allows the platform to prepare infrastructure before enabling customer access. |
| 2 | Available | Full operational status. Customers can buy, sell, send, receive, and convert this cryptocurrency. The normal state for all actively supported assets on the platform. |
| 3 | AvailableRedeemOnly | Restricted mode allowing only sell/redeem operations. Customers can liquidate existing holdings but cannot make new purchases. Typically set during a delisting process to give customers time to exit their positions gracefully. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Unique identifier for the crypto activity status. Values: 0=NotActive, 1=ComingSoon, 2=Available, 3=AvailableRedeemOnly. FK target for Wallet.CryptoTypes.CryptoActivityStatusId. |
| 2 | Name | varchar(100) | YES | - | CODE-BACKED | Human-readable status name. Nullable (unusual for a lookup Name column). Used in application logic to control UI elements and transaction permission checks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CryptoTypes | CryptoActivityStatusId | FK | Each cryptocurrency's current availability status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK on CryptoActivityStatusId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__CryptoActivityStatused_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all crypto activity statuses
```sql
SELECT Id, Name FROM Dictionary.CryptoActivityStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find all available cryptocurrencies
```sql
SELECT ct.CryptoTypeId, ct.Name, cas.Name AS ActivityStatus
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Dictionary.CryptoActivityStatuses cas WITH (NOLOCK) ON ct.CryptoActivityStatusId = cas.Id
WHERE cas.Id = 2 -- Available
ORDER BY ct.Name
```

### 8.3 Identify cryptos being delisted (redeem-only)
```sql
SELECT ct.CryptoTypeId, ct.Name, cas.Name AS Status
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Dictionary.CryptoActivityStatuses cas WITH (NOLOCK) ON ct.CryptoActivityStatusId = cas.Id
WHERE cas.Id = 3 -- AvailableRedeemOnly
ORDER BY ct.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoActivityStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.CryptoActivityStatuses.sql*
