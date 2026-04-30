# Billing.GetPlayerStatusList

> Returns all rows from Dictionary.PlayerStatus, providing the payments validation service with the full lookup table of player status codes and their associated permission flags.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Dictionary.PlayerStatus (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPlayerStatusList` is a no-parameter lookup procedure that returns the entire `Dictionary.PlayerStatus` table. Each row defines a player status level and its associated capability flags: whether customers at that status level can deposit, withdraw, log in, open/close/edit positions, copy other traders, be copied, participate in chat, and receive interest.

The procedure exists to give the payments validation service (PaymentsValidationUser) a clean read interface to the PlayerStatus reference data without direct table access. The validation service uses the CanDeposit and CanRequestWithdraw flags when evaluating whether a customer's current player status permits a payment operation.

Data flows: the payments validation service calls this on startup or when building its in-memory permission reference to populate its player status cache for deposit/withdrawal eligibility checks.

---

## 2. Business Logic

### 2.1 Full Table Read (Reference Data Cache)

**What**: Returns all PlayerStatus rows - there is no filtering. This is a reference data procedure designed for caching.

**Rules**:
- No WHERE clause - all rows returned
- No parameters
- The caller is expected to use the full set to build a local lookup/cache

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Return columns (all from Dictionary.PlayerStatus):**

| # | Column | Confidence | Description |
|---|--------|------------|-------------|
| 1 | PlayerStatusID | CODE-BACKED | PK - numeric status level identifier. |
| 2 | Name | CODE-BACKED | Human-readable status name (e.g., "Active", "Blocked", "Restricted"). |
| 3 | IsBlocked | CODE-BACKED | 1=customer account is blocked from all operations. |
| 4 | CanEditPosition | CODE-BACKED | 1=customer may edit (SL/TP) open positions. |
| 5 | CanOpenPosition | CODE-BACKED | 1=customer may open new trading positions. |
| 6 | CanClosePosition | CODE-BACKED | 1=customer may close open positions. |
| 7 | CanDeposit | CODE-BACKED | 1=customer may make deposits. Key flag used by payment validation for deposit eligibility. |
| 8 | CanRequestWithdraw | CODE-BACKED | 1=customer may submit withdrawal requests. Key flag used by payment validation for withdrawal eligibility. |
| 9 | CanLogin | CODE-BACKED | 1=customer may log in to the platform. |
| 10 | CanChatAndPost | CODE-BACKED | 1=customer may post in the eToro social feed. |
| 11 | CanBeCopied | CODE-BACKED | 1=customer's trades can be copied by other users. |
| 12 | CanCopy | CODE-BACKED | 1=customer may copy other traders. |
| 13 | GetsInterest | CODE-BACKED | 1=customer receives interest payments on their balance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source) | Dictionary.PlayerStatus | SELECT | Full table read; all rows and columns returned |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PaymentsValidationUser | GRANT EXECUTE | Permission | Payments validation service reads player status reference data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPlayerStatusList (procedure)
└── Dictionary.PlayerStatus (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerStatus | Table | Full SELECT - all rows and columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PaymentsValidationUser | DB Security Principal | EXECUTE permission - player status reference cache |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: Uses three-part name `[etoro].[Dictionary].[PlayerStatus]` in the FROM clause, tying the procedure to the `etoro` database. Although in the Billing schema, this procedure reads exclusively from the Dictionary schema. No WITH (NOLOCK) hint.

---

## 8. Sample Queries

### 8.1 Get all player statuses
```sql
EXEC [Billing].[GetPlayerStatusList]
```

### 8.2 Equivalent direct query
```sql
SELECT
    PlayerStatusID, Name, IsBlocked,
    CanEditPosition, CanOpenPosition, CanClosePosition,
    CanDeposit, CanRequestWithdraw, CanLogin,
    CanChatAndPost, CanBeCopied, CanCopy, GetsInterest
FROM Dictionary.PlayerStatus WITH (NOLOCK)
ORDER BY PlayerStatusID
```

### 8.3 Check which statuses allow deposits but not withdrawals (or vice versa)
```sql
SELECT PlayerStatusID, Name, CanDeposit, CanRequestWithdraw
FROM Dictionary.PlayerStatus WITH (NOLOCK)
WHERE CanDeposit != CanRequestWithdraw
ORDER BY PlayerStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPlayerStatusList | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPlayerStatusList.sql*
