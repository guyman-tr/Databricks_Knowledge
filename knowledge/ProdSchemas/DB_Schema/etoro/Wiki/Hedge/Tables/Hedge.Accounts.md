# Hedge.Accounts

> Registry of eToro's physical trading accounts at external liquidity providers, classified by provider and account type (Execution vs OMS Pricing), with credentials used for hedge order placement.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ID (int, non-IDENTITY PK CLUSTERED) |
| **Partition** | No (on [PRIMARY] filegroup) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

`Hedge.Accounts` is the registry of eToro's external trading accounts - the actual brokerage/API accounts held at liquidity providers (ZBFX, TRAFIX, Talos, DLT, Marex, Virtu, etc.) and internal OMS accounts. Each row represents one account that the hedge engine uses for order placement or pricing.

Two account types exist (from `Dictionary.HedgeAccountType`):
- **Execution Account (AccountTypeID=2)**: The primary accounts for placing real hedge orders. The hedge engine routes execution through these accounts.
- **OMS IM Pricing Account (AccountTypeID=4)**: Accounts used by the Order Management System for initial margin pricing calculations only. These do NOT execute trades - they provide reference prices and margin data.

The `IsActive` flag allows an account to be disabled without deletion. Multiple procedures explicitly filter `WHERE AccountTypeID != 4` to exclude OMS pricing accounts from operational hedge server routing queries.

`ID` is not an IDENTITY column - values are manually assigned and non-sequential, spanning from 8 to 354,541. This suggests IDs may originate from an external system or manual allocation.

Data flows: `Hedge.HedgeServerToLiquidityAccount` maps hedge servers to these accounts (via LiquidityAccountID FK to ID). Procedures like `GetHedgeServerInfo`, `GetHedgeServerMetaData`, and `GetHedgeToAccountMapping` JOIN this table to enrich hedge server configurations with provider and account names.

---

## 2. Business Logic

### 2.1 Execution vs Pricing Account Segregation

**What**: Accounts are segregated by type - execution accounts handle real orders; OMS pricing accounts provide price/margin data only.

**Columns/Parameters Involved**: `AccountTypeID`, `IsActive`, `ID`

**Rules**:
- AccountTypeID=2 (Execution Account): used for actual hedge order placement and position management
- AccountTypeID=4 (OMS IM Pricing Account): used by OMS for IM (Initial Margin) calculation - no real orders placed
- `GetHedgeServerInfo`, `GetHedgeServerMetaData` both filter `WHERE AccountTypeID != 4` - operational routing excludes pricing accounts
- `GetActiveAccountByProviderAndAccountType` accepts both type and active flag as parameters for flexible querying
- IsActive=0 accounts are soft-disabled - retained in registry but excluded from active routing

### 2.2 Provider-Account Assignment

**What**: Each account is assigned to one liquidity provider type, enabling multi-provider hedge routing through different accounts.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `Name`, `Username`

**Rules**:
- `LiquidityProviderTypeID` links to Trade.LiquidityProviderType - identifies which provider this account belongs to
- Multiple accounts can exist for the same provider (e.g., ZBFX has 3 Price accounts for load distribution/redundancy)
- `Username` stores the account credential/login name used by the FIX/API connection (e.g., "ZBFX_Price1", "ETORO_INTERNAL_03_UAT")
- `Username` can be empty string (IDs 13, 346, 439, 2150) - these accounts may use API key authentication or have credentials stored elsewhere
- Account names follow pattern: `{ProviderName} {Purpose}` (e.g., "ZBFX Price1 Execution", "OMS UAT IM3 IM Pricing")

---

## 3. Data Overview

| ID | Name | LiquidityProviderTypeID | AccountTypeID | Username | IsActive | Meaning |
|---|---|---|---|---|---|---|
| 8 | ZBFX Price1 Execution | 69 (ZBFX) | 2 (Execution) | ZBFX_Price1 | 1 | Primary ZBFX execution account (connection 1) |
| 10 | ZBFX Price2 Execution | 69 (ZBFX) | 2 (Execution) | ZBFX_Price2 | 1 | Secondary ZBFX execution account (connection 2) |
| 11 | ZBFX Price3 Execution | 69 (ZBFX) | 2 (Execution) | ZBFX_Price3 | 1 | Tertiary ZBFX execution account (connection 3) |
| 14 | TRAFIX UAT Fract | 40 (TRAFIX) | 2 (Execution) | 3ET03901 | 1 | TRAFIX fractional execution account (UAT environment) |
| 346 | Talos | 128 (Talos) | 2 (Execution) | (empty) | 1 | Talos execution account |
| 439 | DLT | 439 (DLT) | 2 (Execution) | DLT | 1 | DLT execution account |
| 2147 | OMS UAT IM3 IM Pricing | 10002 (OMS internal) | 4 (OMS Pricing) | ETORO_INTERNAL_03_UAT | 1 | OMS IM pricing account - not used for execution |
| 2148 | OMS UAT IM4 IM Hedging | 10002 (OMS internal) | 2 (Execution) | ETORO_INTERNAL_04_UAT | 1 | OMS internal hedging execution account |
| 2150 | OMS UAT DMA Virtu | 10002 (OMS internal) | 2 (Execution) | ETORO_STG_VIRTU_UAT | 1 | OMS DMA path to Virtu via OMS |
| 2151 | OMS UAT DMA Marex | 84 (Marex) | 2 (Execution) | ETORO_MAREX_UAT | 1 | OMS DMA path to Marex |
| 12566 | MM Direct STG | 125 (MM Direct) | 2 (Execution) | TestExecution@etoro.com | 1 | MM Direct staging execution account |
| 354541 | FD Provider UAT Account | 3 (FD Provider) | 2 (Execution) | etoroDHedge22 | 1 | FD Provider UAT execution account |

Total: 13 rows (12 Execution, 1 OMS Pricing). All currently active.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key. Non-IDENTITY - manually assigned, non-sequential (range: 8-354,541). Represents a unique hedge account at an external provider. Referenced as `LiquidityAccountID` in Hedge.HedgeServerToLiquidityAccount and related tables/procedures. |
| 2 | Name | varchar(256) | YES | - | VERIFIED | Human-readable account name. Format: `{ProviderName} {Purpose}` (e.g., "ZBFX Price1 Execution"). Used in hedge monitoring dashboards and operational reports via GetHedgeServerMetaData. |
| 3 | LiquidityProviderTypeID | int | YES | - | VERIFIED | FK to Trade.LiquidityProviderType(LiquidityProviderTypeID). Identifies which provider this account belongs to (e.g., 69=ZBFX, 10002=OMS internal). Used to filter accounts by provider in GetActiveAccountByProviderAndAccountType. |
| 4 | AccountTypeID | int | YES | - | VERIFIED | FK to Dictionary.HedgeAccountType(AccountTypeID). 2=Execution Account (places real hedge orders), 4=OMS IM Pricing Account (price/margin calculation only). Operational procedures filter AccountTypeID != 4 to exclude pricing accounts from routing. |
| 5 | Username | varchar(256) | YES | - | VERIFIED | Account credential/login name at the liquidity provider (e.g., "ZBFX_Price1", "ETORO_INTERNAL_03_UAT"). Used by FIX/API connections for authentication. May be empty when API key authentication is used. |
| 6 | IsActive | bit | NO | - | VERIFIED | Whether this account is actively used for routing. 1=active (included in operational queries), 0=disabled (retained for history but excluded from routing). All 13 current rows are active. |
| 7 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 8 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 9 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 10 | SysEndTime | datetime2(7) | NO | - | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.Accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountTypeID | Dictionary.HedgeAccountType | FK (FK_Hedge_Account_Type) | Classifies each account as Execution (2) or OMS Pricing (4) |
| LiquidityProviderTypeID | Trade.LiquidityProviderType | FK (FK_Hedge_Accounts_ProviderID) | Links each account to its liquidity provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeServerToLiquidityAccount | LiquidityAccountID | FK | Maps hedge servers to accounts (ID is the FK target) |
| Hedge.ActiveHedgingAccounts | AccountID | Implicit FK | References active accounts from this table |
| Hedge.AccountInstrumentConfiguration | AccountID | Implicit FK | Per-account per-instrument configuration |
| Hedge.HBCAccountConfiguration | - | JOIN | HBC configuration joins to accounts |
| Hedge.GetHedgeServerInfo | ID | JOIN | Returns account name + provider for a given hedge server |
| Hedge.GetHedgeServerMetaData | ID | JOIN | Returns full hedge server + account metadata |
| Hedge.GetHedgeToAccountMapping | ID | JOIN | Returns server-to-account mapping with provider type |
| Hedge.GetActiveAccountByProviderAndAccountType | ID | JOIN | Returns active accounts filtered by provider and type |
| Hedge.GetHedgeSupportedInstruments | ID | JOIN chain | Returns supported instruments via account chain |
| Hedge.GetHSUnitConversionRatio | ID | JOIN | Returns unit conversion ratio via account chain |
| Hedge.CheckAccountUsernameExists | Username | READER | Checks if a username already exists |
| Hedge.SyncLiquidityAccounts | - | WRITER | Synchronizes account data from external source |
| History.Accounts | (temporal) | Temporal History | Stores historical row versions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Accounts (table)
  ├── Dictionary.HedgeAccountType (table) [FK - AccountTypeID]
  └── Trade.LiquidityProviderType (table) [FK - LiquidityProviderTypeID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgeAccountType | Table | FK_Hedge_Account_Type - AccountTypeID must reference a valid account type |
| Trade.LiquidityProviderType | Table | FK_Hedge_Accounts_ProviderID - LiquidityProviderTypeID must reference a valid provider type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | References ID as LiquidityAccountID - maps servers to accounts |
| Hedge.ActiveHedgingAccounts | Table | References accounts for active hedging assignments |
| Hedge.AccountInstrumentConfiguration | Table | Per-account instrument-level configuration |
| Hedge.HBCAccountConfiguration | Table | HBC deal size configuration per account |
| Hedge.GetHedgeServerInfo | Stored Procedure | READER - returns account info for a hedge server |
| Hedge.GetHedgeServerMetaData | Stored Procedure | READER - enriches hedge server data with account names |
| Hedge.GetHedgeToAccountMapping | Stored Procedure | READER - returns server-to-account mapping |
| Hedge.GetActiveAccountByProviderAndAccountType | Stored Procedure | READER - returns active accounts by provider + type |
| Hedge.GetHedgeSupportedInstruments | Stored Procedure | READER - part of account-based instrument lookup chain |
| Hedge.GetHSUnitConversionRatio | Stored Procedure | READER - part of account-based conversion ratio chain |
| Hedge.CheckAccountUsernameExists | Stored Procedure | READER - validates username uniqueness |
| Hedge.SyncLiquidityAccounts | Stored Procedure | WRITER - syncs accounts from external system |
| History.Accounts | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_Accounts | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_Accounts | PRIMARY KEY | ID - unique account registry |
| FK_Hedge_Account_Type | FOREIGN KEY | AccountTypeID must reference Dictionary.HedgeAccountType(AccountTypeID) |
| FK_Hedge_Accounts_ProviderID | FOREIGN KEY | LiquidityProviderTypeID must reference Trade.LiquidityProviderType(LiquidityProviderTypeID) |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.Accounts |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| TRG_INSERT_Accounts | INSERT | Self-UPDATE (A.Name = B.Name) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all accounts with provider and type names

```sql
SELECT
    ha.ID,
    ha.Name,
    lpt.Name AS ProviderName,
    hat.Name AS AccountTypeName,
    ha.Username,
    ha.IsActive
FROM Hedge.Accounts ha WITH (NOLOCK)
LEFT JOIN Trade.LiquidityProviderType lpt WITH (NOLOCK)
    ON ha.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID
LEFT JOIN Dictionary.HedgeAccountType hat WITH (NOLOCK)
    ON ha.AccountTypeID = hat.AccountTypeID
ORDER BY ha.LiquidityProviderTypeID, ha.AccountTypeID
```

### 8.2 Find all execution accounts (exclude OMS pricing)

```sql
SELECT
    ha.ID,
    ha.Name,
    ha.LiquidityProviderTypeID,
    ha.Username,
    ha.IsActive
FROM Hedge.Accounts ha WITH (NOLOCK)
WHERE ha.AccountTypeID != 4  -- Exclude OMS IM Pricing Accounts
ORDER BY ha.ID
```

### 8.3 Find accounts for a specific provider

```sql
SELECT
    ha.ID,
    ha.Name,
    hat.Name AS AccountType,
    ha.Username,
    ha.IsActive
FROM Hedge.Accounts ha WITH (NOLOCK)
JOIN Dictionary.HedgeAccountType hat WITH (NOLOCK)
    ON ha.AccountTypeID = hat.AccountTypeID
WHERE ha.LiquidityProviderTypeID = 69  -- ZBFX
ORDER BY ha.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.Accounts | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.Accounts.sql*
