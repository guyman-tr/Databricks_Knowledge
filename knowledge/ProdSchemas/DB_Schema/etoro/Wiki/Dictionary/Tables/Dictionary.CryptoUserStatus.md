# Dictionary.CryptoUserStatus

> Lookup table defining the access level a user has to eToro's crypto wallet features — from fully blocked to full send/receive capabilities.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CryptoUserStatusID (int, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CryptoUserStatus defines the access level a user has to eToro's crypto wallet features. Unlike many dictionary tables, this one is primarily consumed at the application layer (eToroX/crypto wallet service) rather than via explicit foreign keys in the database. The four values form an ascending permission ladder: BlockedFromAccess (0) means the user cannot access the crypto wallet at all; ReadOnly (1) allows viewing but no transactions; AllOperations (2) grants full crypto wallet access including send and receive; AllowUsingWalletStatus (3) permits use of wallet features and may act as a prerequisite or alternate flag for certain flows.

This table supports compliance and risk controls. Regional restrictions, KYC status, or internal policy can limit a user's crypto access. The application layer reads this status to enforce UI visibility, API behavior, and transaction eligibility. The absence of FKs in other database tables suggests the status is resolved in application code — perhaps from a cached lookup or configuration service — rather than stored per-customer in a central table.

---

## 2. Business Logic

### 2.1 Crypto Wallet Access Ladder

**What**: Four-tier access model for crypto wallet features.

**Columns/Parameters Involved**: `CryptoUserStatusID`, `Name`

**Rules**:
- **0 — BlockedFromAccess**: User cannot access crypto wallet. UI hidden, API rejects. Used for restricted jurisdictions or risk holds.
- **1 — ReadOnly**: User can view wallet balances and history but cannot send, receive, or trade. Used for audit-only or partial onboarding.
- **2 — AllOperations**: Full access — send, receive, and all wallet operations. Standard authenticated crypto user.
- **3 — AllowUsingWalletStatus**: Permitted to use wallet features. May indicate a prerequisite state or slightly different entitlement than AllOperations (e.g., wallet visible but certain operations still gated).

**Diagram**:
```
Crypto Wallet Access Flow:

  User Request
       │
       ▼
  Resolve CryptoUserStatusID (app layer)
       │
       ├── 0 BlockedFromAccess ──► Deny all access
       │
       ├── 1 ReadOnly ──► View-only: balances, history
       │
       ├── 2 AllOperations ──► Full: send, receive, trade
       │
       └── 3 AllowUsingWalletStatus ──► Wallet features enabled
```

---

## 3. Data Overview

| CryptoUserStatusID | Name | Meaning |
|---|---|---|
| 0 | BlockedFromAccess | User cannot access crypto wallet at all. UI and API restricted. |
| 1 | ReadOnly | User can view wallet balances and history but cannot transact. |
| 2 | AllOperations | Full crypto wallet access including send, receive, and trade. |
| 3 | AllowUsingWalletStatus | Permitted to use wallet features. May be a prerequisite or alternate entitlement. |

*MCP-verified live data. 4 rows.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoUserStatusID | int | NO | - | VERIFIED | Primary key. 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllowUsingWalletStatus. MCP-verified. Used by crypto wallet application layer. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable label. Values: 'BlockedFromAccess', 'ReadOnly', 'AllOperations', 'AllowUsingWalletStatus'. MCP-verified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DDL / Schema | - | Definition | Only referenced in its own DDL across etoro/tradonomi. No explicit FK references in other tables or procedures. Application-level lookup for crypto wallet service. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToroX / Crypto Wallet App | Application | Resolves user crypto access level; enforces UI and API behavior. No FK in DB. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DUS | CLUSTERED PK | CryptoUserStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DUS | PRIMARY KEY | Unique status identifier. FILLFACTOR 95, DICTIONARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all crypto user statuses
```sql
SELECT  CryptoUserStatusID,
        Name
FROM    Dictionary.CryptoUserStatus WITH (NOLOCK)
ORDER BY CryptoUserStatusID;
```

### 8.2 Find status by name
```sql
SELECT  CryptoUserStatusID,
        Name
FROM    Dictionary.CryptoUserStatus WITH (NOLOCK)
WHERE   Name = 'AllOperations';
```

### 8.3 Resolve status ID to label
```sql
SELECT  CryptoUserStatusID AS StatusID,
        Name               AS StatusLabel
FROM    Dictionary.CryptoUserStatus WITH (NOLOCK)
WHERE   CryptoUserStatusID IN (0, 1, 2, 3)
ORDER BY CryptoUserStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Dictionary.CryptoUserStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CryptoUserStatus.sql*
