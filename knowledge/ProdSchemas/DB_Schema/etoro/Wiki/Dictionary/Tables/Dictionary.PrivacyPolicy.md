# Dictionary.PrivacyPolicy

> Lookup table defining 2 customer privacy policies — "Share All" (default, public profile) and "Don't Share" (private profile) — controlling data visibility across the eToro social trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PrivacyPolicyID (INT IDENTITY, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PrivacyPolicy defines the two data-sharing policies available to eToro customers. eToro is a social trading platform where users can view each other's portfolios, copy trades, and participate in leaderboards. The privacy policy determines how much of a customer's trading data is visible to other users.

This table exists because GDPR, data protection regulations, and user preference require the platform to offer privacy controls. Some users want maximum visibility (to attract copiers and build reputation), while others prefer to keep their trading activity private.

The PrivacyPolicyID is stored in Customer.CustomerStatic and flows through Customer.Customer and Customer.CustomerSafty views. It is set during registration (Customer.InsertRealCustomer, Customer.RegisterReal, Customer.RegisterDemo), read by numerous BackOffice and SalesForce procedures, managed by Customer.SetPrivacyPolicyID and Customer.GetPrivacyPolicyID, and respected by Customer.GetUsersPrivacyPoliciesByCIDs and Customer.GetUsersPrivacyPoliciesByUserNames for bulk privacy checks. It also integrates with STS authentication (STS.Authenticate_OpenbookUser, STS.Find_OpenbookUser) and GDPR processes.

---

## 2. Business Logic

### 2.1 Privacy Policy Selection

**What**: Every customer has exactly one privacy policy that controls their data visibility on the platform.

**Columns/Parameters Involved**: `PrivacyPolicyID`, `PrivacyName`, `IsDefault`

**Rules**:
- **Share All (1)** — Default policy (IsDefault=true). The customer's trading data, portfolio, performance statistics, and profile are visible to other users. Required for being a Popular Investor (PI) or being copied on CopyTrader.
- **Don't Share (2)** — Private policy (IsDefault=false). The customer's trading activity is hidden from other users. Cannot be a Popular Investor or appear on public leaderboards while this policy is active.
- New accounts default to "Share All" (the IsDefault flag identifies policy ID 1 as the default).
- Users can change their privacy policy through platform settings — Customer.SetPrivacyPolicyID handles the transition.
- The privacy policy interacts with Dictionary.PrivacyPolicyDetails for per-event granular settings (e.g., championship visibility).

### 2.2 Privacy Policy Impact on Platform Features

**What**: The privacy policy controls access to social trading features.

**Columns/Parameters Involved**: `PrivacyPolicyID`

**Rules**:
- **Share All** enables: public profile, CopyTrader candidacy, Popular Investor eligibility, leaderboard inclusion, public portfolio view.
- **Don't Share** disables: public profile visibility, copier attraction, public performance statistics. The user can still copy others but cannot be copied.
- STS authentication includes PrivacyPolicyID in the user session, enabling real-time privacy enforcement across all platform features.

**Diagram**:
```
Privacy Policy Impact
├── 1 = Share All (default)
│   ├── Public profile         ✓
│   ├── CopyTrader candidacy   ✓
│   ├── Popular Investor       ✓
│   ├── Leaderboards           ✓
│   └── Portfolio visible      ✓
│
└── 2 = Don't Share
    ├── Public profile         ✗
    ├── CopyTrader candidacy   ✗
    ├── Popular Investor       ✗
    ├── Leaderboards           ✗
    └── Portfolio visible      ✗ (private)
```

---

## 3. Data Overview

| PrivacyPolicyID | PrivacyName | IsDefault | Meaning |
|---|---|---|---|
| 1 | Share All | Yes | Default privacy policy — all trading data, portfolio, and performance are publicly visible. Enables full participation in eToro's social trading ecosystem. Required for Popular Investor program and CopyTrader. |
| 2 | Don't Share | No | Private privacy policy — trading activity is hidden from other users. The customer can still trade and copy others, but cannot be copied or appear on public leaderboards. Respects GDPR right to data minimization. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PrivacyPolicyID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. 1=Share All, 2=Don't Share. Stored in Customer.CustomerStatic and referenced by 20+ procedures across Customer, BackOffice, SalesForce, STS, and GDPR schemas. |
| 2 | PrivacyName | varchar(30) | YES | - | VERIFIED | Human-readable policy label. "Share All" or "Don't Share". Displayed in user settings, BackOffice customer cards, and privacy configuration screens. |
| 3 | IsDefault | bit | YES | - | VERIFIED | Indicates which policy is assigned to new accounts by default. 1=default (Share All), 0=not default (Don't Share). Used by registration procedures to set the initial privacy policy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | PrivacyPolicyID | Implicit | Stores the customer's selected privacy policy |
| Customer.Customer | PrivacyPolicyID | Implicit (via view) | Exposes privacy policy in the main customer view |
| Customer.CustomerSafty | PrivacyPolicyID | Implicit (via view) | Schema-bound customer view with privacy policy |
| Customer.IsCustomerFund | PrivacyPolicyID | Implicit (via view) | Fund customer identification view |
| History.Customer | PrivacyPolicyID | Implicit | Historical audit of privacy policy changes |
| Dictionary.PrivacyPolicyDetails | PrivacyPolicyID | Implicit | Per-event privacy settings for each policy |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores PrivacyPolicyID per customer |
| History.Customer | Table | Historical audit of privacy policy |
| Dictionary.PrivacyPolicyDetails | Table | Per-event privacy settings |
| Customer.Customer | View | Exposes privacy policy |
| Customer.CustomerSafty | View | Schema-bound privacy policy view |
| Customer.IsCustomerFund | View | Fund identification with privacy |
| Customer.InsertRealCustomer | Stored Procedure | Writer — sets initial privacy policy during registration |
| Customer.RegisterReal | Stored Procedure | Writer — registration with privacy policy |
| Customer.RegisterDemo | Stored Procedure | Writer — demo registration with privacy policy |
| Customer.SetPrivacyPolicyID | Stored Procedure | Modifier — changes customer privacy policy |
| Customer.GetPrivacyPolicyID | Stored Procedure | Reader — retrieves customer privacy policy |
| Customer.GetUsersPrivacyPoliciesByCIDs | Stored Procedure | Reader — bulk privacy check by CID |
| Customer.GetUsersPrivacyPoliciesByUserNames | Stored Procedure | Reader — bulk privacy check by username |
| Customer.UpdateUserSettingsRemote | Stored Procedure | Modifier — remote settings update |
| Customer.PostRegisterOperations | Stored Procedure | Writer — post-registration setup |
| Customer.GDPRDeleteUser | Stored Procedure | Modifier — GDPR deletion |
| BackOffice.GetHistoryCustomer | Stored Procedure | Reader — customer history |
| STS.Authenticate_OpenbookUser | Stored Procedure | Reader — authentication with privacy |
| STS.Find_OpenbookUser | Stored Procedure | Reader — user lookup with privacy |
| History.OpenBookLogin | Stored Procedure | Reader — login history with privacy |
| Customer.Ins_HistoryLoginOpenBook | Stored Procedure | Writer — login history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DICT_PRPL | CLUSTERED PK | PrivacyPolicyID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DICT_PRPL | PRIMARY KEY | Unique privacy policy identifier |

---

## 8. Sample Queries

### 8.1 List all privacy policies
```sql
SELECT  PrivacyPolicyID,
        PrivacyName,
        IsDefault
FROM    [Dictionary].[PrivacyPolicy] WITH (NOLOCK)
ORDER BY PrivacyPolicyID;
```

### 8.2 Find the default privacy policy
```sql
SELECT  PrivacyPolicyID,
        PrivacyName
FROM    [Dictionary].[PrivacyPolicy] WITH (NOLOCK)
WHERE   IsDefault = 1;
```

### 8.3 Count customers by privacy policy
```sql
SELECT  pp.PrivacyName,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[PrivacyPolicy] pp WITH (NOLOCK)
        ON cs.PrivacyPolicyID = pp.PrivacyPolicyID
GROUP BY pp.PrivacyName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 18 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PrivacyPolicy | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PrivacyPolicy.sql*
