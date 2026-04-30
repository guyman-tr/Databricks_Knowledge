# Dictionary.HedgeAccountType

> Lookup table defining the two types of hedge accounts — Execution Account and OMS IM Pricing Account — used to classify accounts in eToro's hedging infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountTypeID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeAccountType classifies the types of accounts used in eToro's hedging infrastructure. Hedge accounts are the broker's own accounts at liquidity providers and execution venues, used to offset customer exposure. Different account types serve different purposes in the hedging workflow — execution accounts handle actual trade placement, while OMS (Order Management System) IM (Initial Margin) pricing accounts provide price discovery and margin calculation.

This table exists because the hedge system manages multiple account types at external counterparties. An Execution Account is where the hedge server actually places offsetting trades, while an OMS IM Pricing Account is used by the Order Management System for initial margin calculations and price sourcing. These accounts have different configurations, balance requirements, and monitoring needs.

AccountTypeID is stored on Hedge.Accounts, which tracks the hedge system's external accounts and their balances.

---

## 2. Business Logic

### 2.1 Account Type Classification

**What**: Hedge accounts are categorized by their role in the hedging workflow.

**Columns/Parameters Involved**: `AccountTypeID`, `Name`

**Rules**:
- **Execution Account (2)**: The operational account where hedge orders are placed and executed. This is the account that holds actual positions offsetting customer exposure. Monitored for available margin, P&L, and position limits.
- **OMS IM Pricing Account (4)**: Used by the Order Management System for initial margin (IM) pricing and calculation. Provides pricing data and margin requirements without executing actual trades. Used for pre-trade validation and risk calculation.

---

## 3. Data Overview

| AccountTypeID | Name | Meaning |
|---|---|---|
| 2 | Execution Account | The primary hedge account for placing and executing offsetting trades at liquidity providers. When eToro needs to hedge customer exposure, orders are sent to this account type. Balance, available margin, and open positions are actively monitored. |
| 4 | OMS IM Pricing Account | Account used by the Order Management System for initial margin pricing calculations. Provides reference prices and margin requirements for pre-trade risk assessment. Does not hold execution positions — purely for price discovery and margin computation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountTypeID | int | NO | - | VERIFIED | Primary key identifying the hedge account type. 2=Execution Account, 4=OMS IM Pricing Account. Note: IDs are non-sequential (2, 4), suggesting other types may have existed or are reserved. Stored on Hedge.Accounts to classify each hedge account. |
| 2 | Name | varchar(126) | NO | - | VERIFIED | Human-readable label for the account type. Used in hedge monitoring dashboards, account management UI, and reconciliation reports. Describes the account's functional role in the hedging infrastructure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.Accounts | AccountTypeID | Implicit Lookup | Classifies each hedge account by its role |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Accounts | Table | References AccountTypeID to classify hedge accounts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeAccountType | CLUSTERED PK | AccountTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeAccountType | PRIMARY KEY | Unique account type identifier |

---

## 8. Sample Queries

### 8.1 List all hedge account types
```sql
SELECT  AccountTypeID,
        Name
FROM    [Dictionary].[HedgeAccountType] WITH (NOLOCK)
ORDER BY AccountTypeID;
```

### 8.2 Count hedge accounts by type
```sql
SELECT  hat.Name        AS AccountType,
        COUNT(*)        AS AccountCount
FROM    [Hedge].[Accounts] ha WITH (NOLOCK)
JOIN    [Dictionary].[HedgeAccountType] hat WITH (NOLOCK)
        ON ha.AccountTypeID = hat.AccountTypeID
GROUP BY hat.Name;
```

### 8.3 Find all execution accounts with their details
```sql
SELECT  ha.*,
        hat.Name AS AccountTypeName
FROM    [Hedge].[Accounts] ha WITH (NOLOCK)
JOIN    [Dictionary].[HedgeAccountType] hat WITH (NOLOCK)
        ON ha.AccountTypeID = hat.AccountTypeID
WHERE   hat.AccountTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeAccountType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeAccountType.sql*
