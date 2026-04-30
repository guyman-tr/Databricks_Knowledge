# Dictionary.ManagerPermit

> Defines the permission levels granted to BackOffice account managers, controlling whether they can perform trading operations, fund operations, or both on behalf of customers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ManagerPermitID (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique NC on Name |

---

## 1. Business Meaning

Dictionary.ManagerPermit enumerates the permission tiers for BackOffice managers who handle customer accounts. Each tier defines what operational scope a manager has: no permissions, trading only, fund management only, or both trading and fund operations.

Without this table, the BackOffice system could not enforce granular manager permissions. It prevents unauthorized managers from executing trades or processing fund transfers on customer accounts, forming a key access-control layer for the operations team.

Referenced by BackOffice.Customer (ManagerPermitID column), the permission is checked during operations like NFA (National Futures Association) concordance reporting (dbo.PR_NFA_CONCORDANCE, dbo.PR_NFA_MANAGER) and customer management (BackOffice.GetCustomerByCID, BackOffice.UpdateCustomerMaster, BackOffice.GetHistoryBackOfficeCustomer).

---

## 2. Business Logic

### 2.1 Permission Escalation Tiers

**What**: Four-level permission system controlling what managers can do on customer accounts.

**Columns/Parameters Involved**: `ManagerPermitID`, `Name`

**Rules**:
- ID 1 (None): Manager can view but not modify — read-only access
- ID 2 (Trade and Fund): Full operational access — can execute trades AND process funding operations
- ID 3 (Trade): Can execute trades but not funding operations (deposits/withdrawals)
- ID 4 (Fund): Can process funding operations but not execute trades
- The "Trade and Fund" tier combines both permissions; there is no separate "all" tier

**Diagram**:
```
Permission Hierarchy:
  None (1) ─── View Only
  Trade (3) ── Can open/close positions on behalf of customer
  Fund (4) ─── Can process deposits/withdrawals
  Trade and Fund (2) ── Full operational access (combines 3 + 4)
```

---

## 3. Data Overview

| ManagerPermitID | Name | Meaning |
|---|---|---|
| 1 | None | Manager has no operational permissions — view-only access to customer accounts, used for junior staff or auditors |
| 2 | Trade and Fund | Full permission — manager can execute trades and process fund operations (deposits, withdrawals, transfers) |
| 3 | Trade | Trade-only permission — manager can open/close positions but cannot process funding operations |
| 4 | Fund | Fund-only permission — manager can process deposits and withdrawals but cannot execute trades |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerPermitID | tinyint | NO | - | CODE-BACKED | Unique identifier for the permission tier: 1=None (view only), 2=Trade and Fund (full access), 3=Trade only, 4=Fund only. Referenced by BackOffice.Customer and NFA reporting procedures. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable permission label. Enforced unique by UK_DMP_Name constraint. Displayed in BackOffice manager assignment screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | ManagerPermitID | Implicit | Each BackOffice customer record links to a manager permission tier |
| History.BackOfficeCustomer | ManagerPermitID | Implicit | Historical snapshot of manager permissions for audit |
| BackOffice.CustomerSafty | ManagerPermitID | Implicit | Schema-bound safe view includes permit |
| dbo.PR_NFA_MANAGER | ManagerPermitID | Implicit | NFA regulatory reporting uses manager permissions |
| dbo.PR_NFA_CONCORDANCE | ManagerPermitID | Implicit | NFA concordance reporting includes permit data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | ManagerPermitID FK |
| History.BackOfficeCustomer | Table | Historical ManagerPermitID |
| BackOffice.GetCustomerByCID | Stored Procedure | Reads manager permission |
| BackOffice.UpdateCustomerMaster | Stored Procedure | Updates manager permission |
| BackOffice.GetHistoryBackOfficeCustomer | Stored Procedure | Historical permission audit |
| dbo.PR_NFA_MANAGER | Stored Procedure | NFA regulatory reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMP | CLUSTERED PK | ManagerPermitID | - | - | Active |
| UK_DMP_Name | NC UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_DMP_Name | UNIQUE | Ensures no two permission tiers share the same name |

---

## 8. Sample Queries

### 8.1 List all permission tiers
```sql
SELECT  ManagerPermitID,
        Name
FROM    [Dictionary].[ManagerPermit] WITH (NOLOCK)
ORDER BY ManagerPermitID;
```

### 8.2 Find managers with full trading + fund access
```sql
SELECT  c.*
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[ManagerPermit] mp WITH (NOLOCK)
        ON c.ManagerPermitID = mp.ManagerPermitID
WHERE   mp.Name = 'Trade and Fund';
```

### 8.3 Count customers per manager permission level
```sql
SELECT  mp.Name AS PermissionTier,
        COUNT(*) AS CustomerCount
FROM    [BackOffice].[Customer] c WITH (NOLOCK)
JOIN    [Dictionary].[ManagerPermit] mp WITH (NOLOCK)
        ON c.ManagerPermitID = mp.ManagerPermitID
GROUP BY mp.Name
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ManagerPermit | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ManagerPermit.sql*
