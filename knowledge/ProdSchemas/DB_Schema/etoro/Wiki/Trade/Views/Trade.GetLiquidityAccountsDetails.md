# Trade.GetLiquidityAccountsDetails

> Enriched view of liquidity accounts with provider type name, provider instance name, and account name - a flattened hierarchy for display and reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | LiquidityAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLiquidityAccountsDetails extends Trade.GetLiquidityAccounts by joining Trade.LiquidityProviders and Trade.LiquidityProviderType. Each row provides the full hierarchy: LiquidityProviderType (e.g., FD, FXCM), LiquidityProvider instance (e.g., FD RealStream Production), and LiquidityAccount (e.g., Simulation Non Stocks). The view answers: "For each active liquidity account, what is its provider type, provider instance name, and account name?"

This view exists because Hedge.GetHedgeServersDetails, configuration UIs, and reporting need a flat list of accounts with human-readable provider context. Without it, consumers would JOIN GetLiquidityAccounts, LiquidityProviders, and LiquidityProviderType separately. The view centralizes that logic. Data flows from GetLiquidityAccounts (active accounts only) via INNER JOIN to LiquidityProviders and LiquidityProviderType, so only accounts with valid provider and type appear.

Data flows: Trade.GetLiquidityAccounts provides base accounts (IsActive=1). INNER JOIN to LiquidityProviders adds provider instance; INNER JOIN to LiquidityProviderType adds type name. The view is read by configuration UIs and Hedge views. No procedures directly reference GetLiquidityAccountsDetails in grep; dependency docs note it is used for display.

---

## 2. Business Logic

### 2.1 Account-to-Provider-to-Type Hierarchy

**What**: Each liquidity account belongs to a provider instance; each provider instance belongs to a provider type. The view flattens this for display.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `Name`, `LiquidityProviderID`, `LiquidityProviderName`, `LiquidityAccountID`, `LiquidityAccountName`

**Rules**:
- GetLiquidityAccounts filters IsActive=1 - only active accounts. INNER JOINs ensure only accounts with valid provider and type appear.
- Name = provider type (e.g., FD, FXCM, eToro). LiquidityProviderName = instance (e.g., FD RealStream Production REAL 208.100.16.161).
- One account per row. Same provider instance can have multiple accounts (e.g., Simulation Non Stocks, Simulation Stocks BATS).

**Diagram**:
```
Trade.LiquidityProviderType (FD, FXCM)
  -> Trade.LiquidityProviders (FD RealStream Production)
       -> Trade.GetLiquidityAccounts (Simulation Non Stocks, Simulation Stocks BATS, ...)
```

### 2.2 Column Order and Naming

**What**: Output columns follow Type -> Provider -> Account order for hierarchical display.

**Columns/Parameters Involved**: All output columns

**Rules**:
- TLPT (LiquidityProviderTypeID, Name) first
- TLP (LiquidityProviderID, LiquidityProviderName) second
- TLA (LiquidityAccountID, LiquidityAccountName) last
- Name in SELECT is from TLPT - the provider type name.

---

## 3. Data Overview

| LiquidityProviderTypeID | Name | LiquidityProviderID | LiquidityProviderName | LiquidityAccountID | LiquidityAccountName | Meaning |
|---|---|---|---|---|---|---|
| 3 | FD | 4 | FD RealStream Production REAL 208.100.16.161 | 1 | Simulation Non Stocks | FD-type provider, production instance, simulation account for non-stocks. |
| 3 | FD | 4 | FD RealStream Production REAL 208.100.16.161 | 2 | Simulation Stocks BATS | Same provider/instance, BATS-listed stocks simulation. |
| 3 | FD | 4 | FD RealStream Production REAL 208.100.16.161 | 3 | Simulation Stocks DAX | DAX-listed stocks simulation. |
| 3 | FD | 4 | FD RealStream Production REAL 208.100.16.161 | 4 | Simulation Stocks FTSE | FTSE-listed stocks simulation. |
| 2 | FXCM | 2 | FXCM Real | 5 | eToro Custom Price Provider | FXCM production, custom price provider account. |

**Selection criteria**: From live MCP sample. Shows FD (type 3) with 4 simulation accounts, and FXCM (type 2) with one account. Provider type Name, provider instance name, and account name all resolved.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | From TLPT. FK to Trade.LiquidityProviderType. Provider type (0=eToro, 1=BMFN, 2=FXCM, 3=FD, etc.). Defines pluggable assembly/class config. |
| 2 | Name | varchar | NO | - | CODE-BACKED | From TLPT.Name. Human-readable provider type (e.g., FD, FXCM, eToro). Used for display and filtering. |
| 3 | LiquidityProviderID | int | NO | - | CODE-BACKED | From TLP. FK to Trade.LiquidityProviders. Provider instance (e.g., FXCM Real, FD RealStream Production). Links account to deployment. |
| 4 | LiquidityProviderName | varchar | YES | - | CODE-BACKED | From TLP. Human-readable instance name (e.g., FD RealStream Production REAL 208.100.16.161). |
| 5 | LiquidityAccountID | int | NO | - | CODE-BACKED | From TLA. PK from Trade.LiquidityAccounts. Allocated by Trade.SetNextLiquidityAccountID. The liquidity account. |
| 6 | LiquidityAccountName | varchar | YES | - | CODE-BACKED | From TLA. Human-readable account name (e.g., Simulation Non Stocks, eToro Custom Price Provider). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID, Name | Trade.LiquidityProviderType | Lookup | Provider type definition |
| LiquidityProviderID, LiquidityProviderName | Trade.LiquidityProviders | Lookup | Provider instance |
| LiquidityAccountID, LiquidityAccountName | Trade.GetLiquidityAccounts | Base | Active liquidity accounts |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetLiquidityAccounts | View | FROM | Base for GetLiquidityAccountsDetails |
| Trade.LiquidityProviders | Table | JOIN | Resolves provider instance |
| Trade.LiquidityProviderType | Table | JOIN | Resolves provider type name |
| Hedge.GetHedgeServersDetails | - | Consumer (per dependency docs) | Account details for hedge servers |
| Configuration UIs | - | Reader | Display and reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLiquidityAccountsDetails (view)
├── Trade.GetLiquidityAccounts (view)
│     ├── Trade.LiquidityAccounts (table)
│     └── Price.AccountRateSource (table)
├── Trade.LiquidityProviders (table)
│     └── Trade.LiquidityProviderType (table)
└── Trade.LiquidityProviderType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetLiquidityAccounts | View | FROM - active accounts with rate source names |
| Trade.LiquidityProviders | Table | INNER JOIN - provider instance |
| Trade.LiquidityProviderType | Table | INNER JOIN - provider type name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHedgeServersDetails | View | Per dependency docs - account details |
| Configuration UIs | - | Display and reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all account details by provider type
```sql
SELECT LiquidityProviderTypeID, Name, LiquidityProviderID, LiquidityProviderName,
       LiquidityAccountID, LiquidityAccountName
  FROM Trade.GetLiquidityAccountsDetails WITH (NOLOCK)
 ORDER BY LiquidityProviderTypeID, LiquidityProviderID, LiquidityAccountID
```

### 8.2 Accounts for a specific provider
```sql
SELECT LiquidityAccountID, LiquidityAccountName, Name AS ProviderTypeName
  FROM Trade.GetLiquidityAccountsDetails WITH (NOLOCK)
 WHERE LiquidityProviderID = 4
 ORDER BY LiquidityAccountName
```

### 8.3 Count accounts per provider type
```sql
SELECT LiquidityProviderTypeID, Name,
       COUNT(*) AS AccountCount
  FROM Trade.GetLiquidityAccountsDetails WITH (NOLOCK)
 GROUP BY LiquidityProviderTypeID, Name
 ORDER BY AccountCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLiquidityAccountsDetails | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetLiquidityAccountsDetails.sql*
