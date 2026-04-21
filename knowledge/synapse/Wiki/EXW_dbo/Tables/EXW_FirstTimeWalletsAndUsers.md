# EXW_dbo.EXW_FirstTimeWalletsAndUsers

> Daily pre-aggregated count of first-time wallet users and new wallet creations — 642,093 rows (2018-07-12 to 2026-04-11) tracking new user and wallet adoption per Country×Regulation×CryptoName×RealUser×Region×State combination. Each row records how many users registered for the first time (NewUsers) and how many new wallets were opened (NewWallets) for a specific crypto type, geography, and user segment on a given date.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.New_UsersAndWallets_Inventory |
| **Refresh** | Daily — SP_EXW_FirstTimeWalletsAndUsers(@d date); DELETE for FullDateID, then INSERT |
| **Row Count** | 642,093 (2018-07-12 to 2026-04-11, active) |
| **Data Coverage** | New user and wallet events from Wallet launch (Jul 2018) to present |
| **Synapse Distribution** | HASH (FullDateID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only pre-aggregated daily table |

---

## 1. Business Meaning

EXW_FirstTimeWalletsAndUsers is the canonical daily summary of new user and wallet adoption in eToro's Crypto Wallet product. It answers: "How many new wallet users (NewUsers) and new wallets (NewWallets) were created on a given day, broken down by country, regulation, crypto type, user segment, and geography?"

**NewUsers** counts GCIDs whose first wallet join date (UserJoinDate from New_UsersAndWallets_Inventory) equals FullDate — these are brand-new wallet participants on that day. ROW_NUMBER() deduplication ensures each GCID is counted only once even if they opened multiple wallets on the same day.

**NewWallets** counts all new wallets (WalletJoinDate = FullDate) regardless of whether the user is new or an existing user opening a wallet for a new crypto type. A single user opening ETH, BTC, and ADA wallets on the same day contributes 3 to NewWallets but 1 to NewUsers.

The distinction between **CryptoNameERC** (internal ERC token name) and **CryptoName** (canonical blockchain crypto name) mirrors the CryptoTypes mapping: both identify the same crypto but at different levels of the token hierarchy.

---

## 2. Business Logic

### 2.1 New User Detection (DELETE+INSERT Pattern)

**What**: Daily idempotent refresh — all rows for a date are removed and reinserted.

**Columns Involved**: FullDateID, FullDate

**Rules**:
- DELETE FROM EXW_FirstTimeWalletsAndUsers WHERE FullDateID = @d_i
- INSERT from #final — guarantees clean re-run without duplicates

### 2.2 NewUsers Deduplication

**What**: Counts each new user exactly once even if they have multiple new wallets.

**Columns Involved**: NewUsers

**Rules**:
- ROW_NUMBER() OVER (PARTITION BY w.GCID ORDER BY w.GCID) AS RN in #both
- COUNT(CASE WHEN CIDtype='NewCID' AND RN=1 THEN GCID END) — only RN=1 row per GCID is counted
- CIDtype='NewCID': GCID is in both #wallets (WalletJoinDate=@d) AND #users (UserJoinDate=@d)
- CIDtype='OldCID': user existed before @d but opened a new wallet type — contributes to NewWallets, not NewUsers

### 2.3 CryptoName vs CryptoNameERC

**What**: Distinguishes internal ERC token identity from canonical blockchain crypto identity.

**Columns Involved**: CryptoNameERC, CryptoName

**Rules**:
- CryptoNameERC: from New_UsersAndWallets_Inventory.CryptoName — the raw name as stored in WalletDB (ERC/internal token level)
- CryptoName: CryptoTypes.Name WHERE CryptoID=BlockchainCryptoId — canonical blockchain-level name (deduped; e.g., ERC-20 tokens consolidated under their base chain name)
- Both columns may match (for L1 cryptos) or differ (for ERC-20 tokens)

### 2.4 StateCode/State for US Users

**What**: US state information is added for regulatory and geographic analysis.

**Columns Involved**: StateCode, State

**Rules**:
- StateCode = DWH_dbo.Dim_State_and_Province.ShortName JOIN on EXW_DimUser.UserRegion_State = Dim_State_and_Province.Name
- State = EXW_DimUser.UserRegion_State (full state name)
- NULL for all non-US users (region/state not available in DWH_dbo dimension for non-US jurisdictions)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(FullDateID), HEAP. Distribution on FullDateID means date-filtered queries won't benefit from colocation — all 60 distributions are scanned. For large date-range queries, CCI would be more efficient but this is a HEAP table. Always filter on FullDateID (not FullDate) when possible.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily new user count by country | `GROUP BY FullDate, Country ORDER BY SUM(NewUsers) DESC` |
| New wallets by crypto over a month | `WHERE FullDateID BETWEEN 20260301 AND 20260331 GROUP BY CryptoName SUM(NewWallets)` |
| New user funnel by regulation | `GROUP BY Regulation, FullDate SUM(NewUsers)` |
| US state-level acquisition | `WHERE StateCode IS NOT NULL GROUP BY State, FullDate` |

### 3.3 Gotchas

- **NewUsers + NewWallets can both be 0**: If a dimension combination appears on a date but all counts are zero, the row should not exist — but verify with SP logic.
- **HASH(FullDateID) means date queries read all 60 shards**: Use date range filters; avoid point lookups on Country or Regulation without also filtering FullDateID.
- **nvarchar(1000) for all string columns**: Generous type sizing from SP SELECT — no truncation risk but impacts memory in string operations.
- **CryptoNameERC vs CryptoName**: Do not conflate. For standard queries use CryptoName (blockchain canonical). CryptoNameERC is preserved for token-level analysis.
- **Source table New_UsersAndWallets_Inventory is pending documentation**: If backfill or gap analysis is needed, query that table directly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Country | nvarchar(1000) | YES | Country name from EXW_DimUser.Country (LEFT JOIN on GCID). Reflects user's registered country as of last EXW_DimUser refresh. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 2 | RealUser | nvarchar(1000) | YES | User type from EXW_DimUser_Enriched.UserType. Values: 'RealUser' (genuine retail user), 'eTorian' (employee/internal), 'TestUser' (matched test patterns). LEFT JOIN — NULL if GCID not in EXW_DimUser_Enriched. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 3 | CryptoNameERC | nvarchar(1000) | YES | Internal ERC-level crypto name from New_UsersAndWallets_Inventory.CryptoName. Represents the token name as stored in WalletDB, including ERC-20 distinctions. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 4 | CryptoName | nvarchar(1000) | YES | Canonical blockchain crypto name from EXW_Wallet.CryptoTypes.Name (WHERE CryptoID=BlockchainCryptoId). Deduped to the base blockchain asset. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 5 | Regulation | nvarchar(1000) | YES | Regulation entity name from EXW_DimUser.Regulation. Reflects user's current regulatory jurisdiction. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 6 | Region | nvarchar(1000) | YES | Geographic region from EXW_DimUser.Region. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 7 | StateCode | nvarchar(1000) | YES | US state/province short code from DWH_dbo.Dim_State_and_Province.ShortName. NULL for non-US users. JOIN on EXW_DimUser.UserRegion_State=Dim_State_and_Province.Name. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 8 | State | nvarchar(1000) | YES | Full US state/region name from EXW_DimUser.UserRegion_State. NULL for non-US users. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 9 | FullDate | date | YES | Date of new user/wallet registration event (= @d execution parameter). (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 10 | FullDateID | int | YES | YYYYMMDD integer form of FullDate. Distribution column. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 11 | NewUsers | int | YES | Count of GCIDs whose first wallet registration date (UserJoinDate) equals FullDate. ROW_NUMBER() deduplication ensures each GCID counted once. 0 for rows where all wallets belong to returning users. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 12 | NewWallets | int | YES | Count of new wallets (WalletJoinDate=FullDate) for this dimension combination. Includes both new-user wallets and returning-user new-crypto wallets. Always >= NewUsers within any row. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |
| 13 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at SP run time. (Tier 2 — SP_EXW_FirstTimeWalletsAndUsers) |

---

## 5. Lineage

### 5.1 Production Sources

| Table Column | Source Object | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| Country | EXW_dbo.EXW_DimUser | Country | Passthrough via LEFT JOIN |
| RealUser | EXW_dbo.EXW_DimUser_Enriched | UserType | Passthrough via LEFT JOIN |
| CryptoNameERC | EXW_dbo.New_UsersAndWallets_Inventory | CryptoName | Aliased as CryptoNameERC |
| CryptoName | EXW_Wallet.CryptoTypes | Name | WHERE CryptoID=BlockchainCryptoId |
| Regulation | EXW_dbo.EXW_DimUser | Regulation | Passthrough via LEFT JOIN |
| Region | EXW_dbo.EXW_DimUser | Region | Passthrough via LEFT JOIN |
| StateCode | DWH_dbo.Dim_State_and_Province | ShortName | JOIN on UserRegion_State=Name |
| State | EXW_dbo.EXW_DimUser | UserRegion_State | Passthrough |
| FullDate | SP parameter | @d | Execution date |
| FullDateID | SP parameter | @d_i | YYYYMMDD integer |
| NewUsers | EXW_dbo.New_UsersAndWallets_Inventory | GCID (UserJoinDate=@d) | COUNT with ROW_NUMBER dedup |
| NewWallets | EXW_dbo.New_UsersAndWallets_Inventory | CryptoNameERC (WalletJoinDate=@d) | COUNT(CryptoNameERC) |
| UpdateDate | (computed) | — | GETDATE() |

### 5.2 ETL Flow Diagram

```
EXW_dbo.New_UsersAndWallets_Inventory (pending documentation)
  |-- WHERE UserJoinDate=@d → #users (new GCIDs)
  |-- WHERE WalletJoinDate=@d → #wallets (new wallets)
  |
  #wallets JOIN CryptoTypes → CryptoName (blockchain canonical)
  #wallets LEFT JOIN #users → CIDtype (NewCID vs OldCID) + RN deduplication
  |
  #both JOIN CustomerWalletsView (validates wallet scope)
  LEFT JOIN EXW_DimUser → Country, Regulation, Region, State
  LEFT JOIN EXW_DimUser_Enriched → RealUser
  LEFT JOIN Dim_State_and_Province → StateCode
  |
  GROUP BY all dimension columns → #final
  |-- NewUsers = COUNT(RN=1 AND NewCID)
  |-- NewWallets = COUNT(CryptoNameERC)
  v
DELETE WHERE FullDateID=@d_i
INSERT → EXW_dbo.EXW_FirstTimeWalletsAndUsers (13 columns, ~642K rows)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| UserJoinDate / WalletJoinDate | EXW_dbo.New_UsersAndWallets_Inventory | Primary source of new user/wallet events |
| Country / Regulation / Region / State | EXW_dbo.EXW_DimUser | User geography and regulation |
| RealUser | EXW_dbo.EXW_DimUser_Enriched | User type classification |
| CryptoName | EXW_Wallet.CryptoTypes | Blockchain canonical crypto name |
| StateCode | DWH_dbo.Dim_State_and_Province | US state short code |
| (scope) | EXW_Wallet.CustomerWalletsView | Wallet scope validation |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| Direct analyst queries | Daily new user and wallet acquisition metrics |
| No SSDT-tracked SP consumers | Leaf node in the EXW_dbo dependency graph |

---

## 7. Sample Queries

### Daily new user and wallet adoption by regulation

```sql
SELECT
    FullDate,
    Regulation,
    SUM(NewUsers) AS TotalNewUsers,
    SUM(NewWallets) AS TotalNewWallets
FROM EXW_dbo.EXW_FirstTimeWalletsAndUsers
WHERE FullDateID BETWEEN 20260101 AND 20260411
GROUP BY FullDate, Regulation
ORDER BY FullDate DESC, TotalNewUsers DESC;
```

### Top cryptos by new wallet opens in last 30 days

```sql
SELECT
    CryptoName,
    SUM(NewWallets) AS NewWallets,
    SUM(NewUsers) AS NewUsers
FROM EXW_dbo.EXW_FirstTimeWalletsAndUsers
WHERE FullDateID >= CAST(CONVERT(VARCHAR(8), DATEADD(DAY, -30, GETDATE()), 112) AS INT)
GROUP BY CryptoName
ORDER BY NewWallets DESC;
```

### US state-level new user acquisition

```sql
SELECT
    FullDate,
    State,
    StateCode,
    SUM(NewUsers) AS NewUsers,
    SUM(NewWallets) AS NewWallets
FROM EXW_dbo.EXW_FirstTimeWalletsAndUsers
WHERE StateCode IS NOT NULL
  AND FullDateID >= 20260101
GROUP BY FullDate, State, StateCode
ORDER BY FullDate DESC, NewUsers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. SP header (Guy Manova, 2019-01-20): original author; 2019-09-26 fix for double-counting CIDs (added ROW_NUMBER deduplication); 2024-04-02 migration to smaller source table (Inessa). SP description: "pre aggregate first occurrences to per day instead of per walletID."

---

*Generated: 2026-04-20 | Quality: 8.6/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 8/10, Sources: 9/10*
*Object: EXW_dbo.EXW_FirstTimeWalletsAndUsers | Type: Table | Production Source: EXW_dbo.New_UsersAndWallets_Inventory*
