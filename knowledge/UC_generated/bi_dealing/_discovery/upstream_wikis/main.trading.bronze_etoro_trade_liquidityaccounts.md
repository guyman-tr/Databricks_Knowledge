# Trade.LiquidityAccounts

> Configuration table for liquidity provider accounts that store credentials, provider linkage, and rate-source mapping used for price feeds and hedge execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | LiquidityAccountID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.LiquidityAccounts stores the **login credentials and configuration** for each liquidity provider account used by eToro's trading infrastructure. While Trade.LiquidityProviders defines provider instances (e.g., FXCM Real, FD Production), this table defines the actual accounts - each row is a specific login (Username, Password) tied to a provider instance and an account type (Price vs Execution). The table links to Price.AccountRateSource to map which price feed each account serves, enabling the platform to route price requests and hedge orders to the correct external broker endpoints.

This table exists because the hedge and price subsystems need to know which accounts can provide prices vs. execute orders. LiquidityAccountTypeID distinguishes Price Account (pricing only), Execution Account (trading only), or Price and Execution (both). Without this table, the system could not route instrument rate requests to the correct feeds or send hedge orders to the right execution accounts.

Data flows as follows: rows are created by Trade.SetNextLiquidityAccountID (for legacy "Obsolete! Use Hedge Account" placeholders - the procedure also inserts into Hedge.Accounts), by instrument setup flows, and by admin scripts. The table is read by Trade.GetLiquidityAccounts (view), Hedge.GetActiveLiquidityAccounts, Hedge.SyncLiquidityAccounts, Price.GetAllowedAccountRateSources, Price.GetInstrumentAllocationData, and many price/hedge views. System versioning records all changes to History.LiquidityAccounts.

---

## 2. Business Logic

### 2.1 Account Type vs Provider Instance

**What**: Each liquidity account belongs to one provider instance and has one account type. Multiple accounts can share the same provider (e.g., ZBFX Price1 and ZBFX Price2 both on LiquidityProviderID 69).

**Columns/Parameters Involved**: `LiquidityAccountID`, `LiquidityProviderID`, `LiquidityAccountTypeID`, `AccountRateSourceID`

**Rules**:
- LiquidityProviderID references Trade.LiquidityProviders - the account is tied to a provider instance
- LiquidityAccountTypeID: 0=NONE, 1=Price Account, 2=Execution Account, 3=Price and Execution, 4=OMS IM Pricing
- AccountRateSourceID links to Price.AccountRateSource - used for price feed routing. Value 0 = "Do not use!", -1 = "US"
- Price.CleanUnmappedInstrumentRateSources excludes accounts with LiquidityAccountTypeID=2 (Execution only) when resolving rate sources
- Hedge.Accounts mirrors each row via ID=LiquidityAccountID; Hedge.SyncLiquidityAccounts keeps them aligned

**Diagram**:
```
Trade.LiquidityProviders (e.g., ZBFX)
  -> Trade.LiquidityAccounts (ZBFX Price1 Rates, ZBFX Price1 Execution)
        -> Price.AccountRateSource (feed mapping)
        -> Hedge.Accounts (mirror)
```

### 2.2 System Versioning for Audit

**What**: All changes to account configuration are retained via PERIOD FOR SYSTEM_TIME.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- History.LiquidityAccounts holds superseded rows when credentials or settings change
- Enables point-in-time queries for forensics or configuration rollback

---

## 3. Data Overview

| LiquidityAccountID | LiquidityAccountName | LiquidityProviderID | LiquidityAccountTypeID | AccountRateSourceID | Meaning |
|--------------------|---------------------|---------------------|------------------------|---------------------|---------|
| 1 | Simulation Non Stocks | 4 | 1 | 1 | FD provider simulation account for non-stock pricing. Type 1 = Price Account. |
| 5 | eToro Custom Price Provider | 2 | 1 | 5 | FXCM Real provider - custom pricing. Price-only account. |
| 7 | ZBFX Price1 Rates | 69 | 1 | 21 | ZBFX provider price feed account. Separate from execution account. |
| 8 | ZBFX Price1 Execution | 69 | 2 | -1 | Same provider as #7 but Execution Account type. AccountRateSourceID=-1 (US) for execution routing. |
| 10 | ZBFX Price2 Execution | 69 | 2 | 21 | Execution account with different rate source mapping. |

**Selection criteria for the 5 rows:**
- Mix of Price (type 1) and Execution (type 2) accounts
- Same provider (69) with multiple accounts showing the account-type split
- Simulation, custom, and ZBFX environments

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | Primary key. Allocated by Trade.SetNextLiquidityAccountID using gap-fill (lowest missing ID) or MAX+1. Mirrored to Hedge.Accounts.ID. Referenced by Price.InstrumentRateSources, Hedge.ExecutionLog, Hedge.HBCAccountConfiguration. |
| 2 | LiquidityAccountName | varchar(50) | YES | - | CODE-BACKED | Human-readable account name (e.g., Simulation Non Stocks, ZBFX Price1 Rates). SetNextLiquidityAccountID uses '{Name} - Obsolete! Use Hedge Account' for placeholder rows. |
| 3 | LiquidityProviderID | int | YES | - | CODE-BACKED | FK to Trade.LiquidityProviders. Links account to provider instance (e.g., FXCM Real=2, FD=4, ZBFX=69). |
| 4 | Username | varchar(50) | YES | - | CODE-BACKED | Login username for the external broker. Empty string for simulation/placeholder accounts. |
| 5 | Password | varchar(50) | YES | - | CODE-BACKED | Login password for the external broker. Empty for simulation. Audited on INSERT/UPDATE/DELETE. |
| 6 | SettingsXML | xml | YES | - | CODE-BACKED | Account-specific XML settings. SetNextLiquidityAccountID inserts '<settings />' for placeholder rows. |
| 7 | IsActive | bit | NO | 1 | CODE-BACKED | 1 = active (account in use), 0 = inactive. Trade.GetLiquidityAccounts filters WHERE IsActive = 1. Default 1. |
| 8 | LiquidityAccountTypeID | int | NO | 1 | CODE-BACKED | FK to Dictionary.LiquidityAccountType. 0=NONE, 1=Price Account, 2=Execution Account, 3=Price and Execution, 4=OMS IM Pricing. Default 1. |
| 9 | AccountRateSourceID | int | YES | - | CODE-BACKED | FK to Price.AccountRateSource. Maps account to price feed. 0="Do not use!", -1="US". Used for instrument rate source allocation. |
| 10 | DbLoginName | varchar(128) | NO | computed | CODE-BACKED | Computed: suser_name(). SQL login that last modified the row. Audit context. |
| 11 | AppLoginName | varchar(500) | NO | computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context. Often NULL when not set. |
| 12 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning start. GENERATED ALWAYS AS ROW START. |
| 13 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning end. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviders | FK | Each account links to a provider instance for hedge/price routing. |
| LiquidityAccountTypeID | Dictionary.LiquidityAccountType | FK | Classifies account role (Price, Execution, or both). |
| AccountRateSourceID | Price.AccountRateSource | FK | Maps account to price feed for instrument rate allocation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.Accounts | ID | Implicit FK | Mirrors LiquidityAccountID; SyncLiquidityAccounts keeps in sync |
| Price.InstrumentRateSources | LiquidityAccountID | FK | Maps instruments to liquidity accounts for rate sources |
| Hedge.ExecutionLog | LiquidityAccountID | FK | Logs which account executed hedge orders |
| Hedge.HBCExecutionLog | LiquidityAccountID | FK | HBC execution logging |
| Hedge.HBCAccountConfiguration | LiquidityAccountID | FK | Per-account instrument configuration |
| Hedge.AccountClosedPositions | LiquidityAccountID | FK | Closed position tracking |
| Hedge.Netting | LiquidityAccountID | FK | Netting configuration |
| Price.PCSToLiquidityAccount | LiquidityAccountID | FK | PCS mapping |
| Price.SpotInstrumentMapping | LiquidityAccountID | FK | Spot instrument mapping |
| Trade.GetLiquidityAccounts | - | FROM | View lists active accounts with rate source names |
| Hedge.GetActiveLiquidityAccounts | - | FROM | Procedure returns active accounts |
| Hedge.SyncLiquidityAccounts | - | UPDATE | Syncs provider assignments |
| Price.GetAllowedAccountRateSources | - | JOIN | Resolves allowed rate sources |
| Price.GetInstrumentAllocationData | - | JOIN | Rate source allocation by account |
| Trade.SetNextLiquidityAccountID | - | INSERT/SELECT | Creates placeholder accounts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.LiquidityAccounts (table)
├── Trade.LiquidityProviders (table)
├── Dictionary.LiquidityAccountType (table)
└── Price.AccountRateSource (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | FK LiquidityProviderID |
| Dictionary.LiquidityAccountType | Table | FK LiquidityAccountTypeID |
| Price.AccountRateSource | Table | FK AccountRateSourceID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiquidityAccounts | View | FROM - lists active accounts |
| Hedge.GetActiveLiquidityAccounts | Procedure | SELECT active accounts |
| Hedge.SyncLiquidityAccounts | Procedure | UPDATE provider assignments |
| Trade.SetNextLiquidityAccountID | Procedure | INSERT, SELECT |
| Price.GetAllowedAccountRateSources | View | JOIN |
| Price.GetInstrumentAllocationData | View | JOIN |
| Price.GetRateSourceConfiguration | View | JOIN |
| Price.GetTopRateSourceAllocations | View | JOIN |
| Price.GetPriceAccounts | View | FROM |
| Price.GetPriceServerAccountAllocation | View | JOIN |
| Price.CleanUnmappedInstrumentRateSources | Procedure | JOIN |
| Hedge.GetAccountSupportedInstruments | Procedure | JOIN |
| Hedge.GetHedgeSupportedInstruments | Procedure | JOIN |
| Hedge.GetAllLiquidityAccountsMetadata | Procedure | FROM |
| Hedge.CheckAccountUsernameExists | Procedure | JOIN |
| Hedge.AddAccountStatus | Procedure | FROM |
| Monitor.CheckOutOfSyncLiquidityProviders | Procedure | FULL JOIN |
| Price.DelistInstrument | Procedure | JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TRLA | CLUSTERED | LiquidityAccountID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TRLA | PRIMARY KEY | LiquidityAccountID - unique identifier |
| FK_TRLP_TRLA | FOREIGN KEY | LiquidityProviderID -> Trade.LiquidityProviders(LiquidityProviderID) |
| FK_LiquidityAccounts_LiquidityAccountsType | FOREIGN KEY | LiquidityAccountTypeID -> Dictionary.LiquidityAccountType(LiquidityAccountTypeID) |
| FK_LiquidityAccounts_AccountRateSourceID | FOREIGN KEY | AccountRateSourceID -> Price.AccountRateSource(AccountRateSourceID) |
| DEFAULT_LiquidityAccountIsActive | DEFAULT | IsActive = 1 |
| DEFAULT_LiquidityAccountLiquidityAccountTypeID | DEFAULT | LiquidityAccountTypeID = 1 |
| DF_LiquidityAccounts_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_LiquidityAccounts_SysEnd | DEFAULT | 9999-12-31 for SysEndTime |
| PERIOD FOR SYSTEM_TIME | SYSTEM VERSIONING | SysStartTime, SysEndTime -> History.LiquidityAccounts |

---

## 8. Sample Queries

### 8.1 List active liquidity accounts with provider and type
```sql
SELECT LA.LiquidityAccountID,
       LA.LiquidityAccountName,
       LP.LiquidityProviderName,
       LAT.Name AS AccountTypeName,
       ARS.Name AS RateSourceName
FROM Trade.LiquidityAccounts LA WITH (NOLOCK)
LEFT JOIN Trade.LiquidityProviders LP WITH (NOLOCK)
  ON LA.LiquidityProviderID = LP.LiquidityProviderID
LEFT JOIN Dictionary.LiquidityAccountType LAT WITH (NOLOCK)
  ON LA.LiquidityAccountTypeID = LAT.LiquidityAccountTypeID
LEFT JOIN Price.AccountRateSource ARS WITH (NOLOCK)
  ON LA.AccountRateSourceID = ARS.AccountRateSourceID
WHERE LA.IsActive = 1
ORDER BY LA.LiquidityProviderID, LA.LiquidityAccountID;
```

### 8.2 Count accounts per provider
```sql
SELECT LP.LiquidityProviderName,
       COUNT(LA.LiquidityAccountID) AS AccountCount
FROM Trade.LiquidityProviders LP WITH (NOLOCK)
LEFT JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
  ON LA.LiquidityProviderID = LP.LiquidityProviderID AND LA.IsActive = 1
GROUP BY LP.LiquidityProviderID, LP.LiquidityProviderName
ORDER BY AccountCount DESC;
```

### 8.3 Resolve AccountRateSourceID to human-readable names
```sql
SELECT LA.LiquidityAccountID,
       LA.LiquidityAccountName,
       LA.AccountRateSourceID,
       ARS.Name AS RateSourceName
FROM Trade.LiquidityAccounts LA WITH (NOLOCK)
LEFT JOIN Price.AccountRateSource ARS WITH (NOLOCK)
  ON LA.AccountRateSourceID = ARS.AccountRateSourceID
WHERE LA.IsActive = 1
ORDER BY LA.LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL, LiveData, Grep*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.LiquidityAccounts | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.LiquidityAccounts.sql*
