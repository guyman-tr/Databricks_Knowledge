# EXW_dbo.EXW_30DayBalanceExtract

> Rolling 30-day balance extract — 52.7M rows (689,733 GCIDs, 31 dates: currently 2026-03-12 to 2026-04-11) providing a TRUNCATE+INSERT snapshot of EXW_FinanceReportsBalancesNew for the trailing 30 days, enriched with EXW_DimUser geographic attributes (Region, State, StateCode, ComplianceClosureEvent) not available in the source table.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.EXW_FinanceReportsBalancesNew |
| **Refresh** | On-demand — SP_EXW_30DayBalanceExtract (no date parameter); TRUNCATE TABLE then INSERT; window = BalanceDateID >= GETDATE()-31 |
| **Row Count** | 52,654,401 (rolling 31-date window; refreshed 2026-04-12) |
| **Data Coverage** | Rolling 30-day window (currently 2026-03-12 to 2026-04-11) |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only rolling extract |

---

## 1. Business Meaning

EXW_30DayBalanceExtract is a rolling 30-day window of wallet balances sourced from EXW_FinanceReportsBalancesNew, enriched with geographic and compliance attributes from EXW_DimUser. Each SP run completely replaces the table (TRUNCATE + INSERT) with the last 31 days of balance data.

**Key enrichments over EXW_FinanceReportsBalancesNew**:
- **Region**: geographic region (not in EXW_FinanceReportsBalancesNew)
- **State / StateCode**: US state name and short code (not in EXW_FinanceReportsBalancesNew)
- **ComplianceClosureEvent**: compliance closure flag from EXW_DimUser (not in EXW_FinanceReportsBalancesNew)
- **RealUser**: derived from IsTestAccount and IsValidCustomer — 'TestUser', 'eTorian', or 'RealUser'

**CryptoId/CryptoName** in this table refer to the **blockchain-level** crypto (EXW_Wallet.CryptoTypes.BlockchainCryptoId), not the ERC-level. The original ERC-level values are preserved in CryptoIdERC/CryptoNameERC. This is a key distinction from EXW_FinanceReportsBalancesNew where CryptoID is the ERC-level identifier.

With 689,733 GCIDs across 31 dates (vs the source table's full history), this extract is optimized for reports and dashboards that need only recent balance data without full table scans on EXW_FinanceReportsBalancesNew.

---

## 2. Business Logic

### 2.1 Rolling 30-Day Window

**What**: The extract always contains exactly the last 31 dates from EXW_FinanceReportsBalancesNew.

**Columns Involved**: FullDate, FullDateID

**Rules**:
- DECLARE @enddate DATE = GETDATE()-31
- DECLARE @enddateid INT = CAST(CONVERT(VARCHAR(8),@enddate,112) AS INT)
- Filter: WHERE BalanceDateID >= @enddateid
- On each SP run, all previous data is discarded (TRUNCATE TABLE) and replaced

### 2.2 CryptoId Mapping: ERC → Blockchain

**What**: CryptoId/CryptoName are remapped to the blockchain-level identifier for consistency with blockchain analytics.

**Columns Involved**: CryptoId, CryptoName, CryptoIdERC, CryptoNameERC

**Rules**:
- EXW_FinanceReportsBalancesNew.CryptoID → preserved as CryptoIdERC (ERC-level)
- EXW_Wallet.CryptoTypes WHERE CryptoID=BlockchainCryptoId → CryptoId (blockchain-level BlockchainCryptoId)
- Separate join table #blcid pre-aggregates DISTINCT BlockchainCryptoId+Name for efficiency
- InstrumentId: from CryptoTypes WHERE CryptoID=EXW_FinanceReportsBalancesNew.CryptoID

### 2.3 RealUser Derivation

**What**: Classifies each wallet user into three segments for reporting.

**Columns Involved**: RealUser

**Rules**:
- IsTestAccount=1 → 'TestUser'
- IsValidCustomer=0 → 'eTorian' (internal/employee)
- Else → 'RealUser'
- Sources: IsTestAccount from EXW_FinanceReportsBalancesNew; IsValidCustomer from EXW_FinanceReportsBalancesNew
- Same CASE logic as EXW_30DayBalanceExtract.RealUser; consistent across tables

### 2.4 Geographic Enrichment from EXW_DimUser

**What**: Adds geographic attributes not stored in EXW_FinanceReportsBalancesNew.

**Columns Involved**: Region, StateCode, State, ComplianceClosureEvent

**Rules**:
- LEFT JOIN EXW_DimUser ON GCID
- Region: EXW_DimUser.Region (geographic region, e.g., Europe, Americas)
- StateCode: EXW_DimUser.UserRegionID (US state/region code)
- State: EXW_DimUser.UserRegion_State (full US state name)
- ComplianceClosureEvent: EXW_DimUser.ComplianceClosureEvent (1 if user has a regulatory closure event)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID), HEAP. Distribution on GCID is optimal for per-user and country-level joins. HEAP means no CCI — for the 52M-row table, always filter on FullDateID or GCID. The rolling nature (fresh TRUNCATE+INSERT) means no data older than 31 days.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current balance snapshot (latest date) | `WHERE FullDateID = (SELECT MAX(FullDateID) FROM EXW_dbo.EXW_30DayBalanceExtract)` |
| US state-level balance distribution | `WHERE StateCode IS NOT NULL GROUP BY State, StateCode` |
| Compliance closure users with balance | `WHERE ComplianceClosureEvent=1 AND BalanceUSD>0` |
| Balance by blockchain crypto | `GROUP BY CryptoName SUM(BalanceUSD)` — uses blockchain-level name |

### 3.3 Gotchas

- **TRUNCATE+INSERT on every run**: Do not depend on historical data — this table has no history beyond 31 days. Use EXW_FinanceReportsBalancesNew directly for older dates.
- **CryptoId/CryptoName = blockchain level**: Different from EXW_FinanceReportsBalancesNew.CryptoID (ERC level). Use CryptoIdERC/CryptoNameERC for cross-table JOIN consistency with other EXW tables.
- **StateCode = UserRegionID** (not ShortName as in EXW_FirstTimeWalletsAndUsers): The column represents EXW_DimUser.UserRegionID, which is a region code. Not the same encoding as Dim_State_and_Province.ShortName.
- **ComplianceClosureEvent**: 1 = user has been affected by a compliance closure event (set by SP_DimUser via EXW_WalletClosedCountryProjects). Useful for compliance reporting.
- **FactBalance_UpdateDate** preserves the source table's UpdateDate, not the extract run time. Use UpdateDate for extract freshness, FactBalance_UpdateDate for source data freshness.

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
| 1 | FullDate | date | YES | Balance snapshot date. Alias of EXW_FinanceReportsBalancesNew.BalanceDate. Rolling window: current last 31 days. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 2 | FullDateID | int | YES | YYYYMMDD integer form of FullDate. Alias of BalanceDateID. Filter on this for best performance. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 3 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Source: EXW_FinanceReportsBalancesNew. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 4 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Source: EXW_FinanceReportsBalancesNew.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 5 | CryptoId | int | YES | Blockchain-level crypto ID from EXW_Wallet.CryptoTypes.BlockchainCryptoId. Different from CryptoIdERC (ERC-level). Use CryptoIdERC for joins to other EXW tables that use ERC-level IDs. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 6 | CryptoName | varchar(256) | YES | Canonical blockchain crypto name from EXW_Wallet.CryptoTypes.Name (WHERE CryptoID=BlockchainCryptoId). Use CryptoNameERC for joins to other EXW tables. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 7 | InstrumentID | int | YES | Trading instrument ID from EXW_Wallet.CryptoTypes.InstrumentId for the ERC-level CryptoId. Used for cross-referencing with trading platform instruments. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 8 | WalletID | nvarchar(256) | YES | Wallet GUID from EXW_FinanceReportsBalancesNew. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 9 | Balance | numeric(38,8) | YES | Wallet balance in native crypto units from EXW_FinanceReportsBalancesNew. Direct snapshot balance (not cumulative calculation). (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 10 | BalanceUSD | numeric(38,8) | YES | USD equivalent of Balance from EXW_FinanceReportsBalancesNew. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 11 | FactBalance_UpdateDate | datetime | YES | UpdateDate from EXW_FinanceReportsBalancesNew — records when the source balance was last updated by SP_EXW_FinanceReportsBalancesNew. Not the extract run time. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 12 | CryptoIdERC | int | YES | Original ERC-level crypto ID from EXW_FinanceReportsBalancesNew.CryptoID. Use this for joins to EXW_FactTransactions and other EXW tables. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 13 | CryptoNameERC | varchar(256) | YES | Original ERC-level crypto name from EXW_FinanceReportsBalancesNew.CryptoName. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 14 | Country | varchar(100) | YES | Country name from EXW_FinanceReportsBalancesNew.Country. Passthrough. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 15 | CountryID | int | YES | Country ID from EXW_FinanceReportsBalancesNew.CountryID. Passthrough. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 16 | Region | varchar(100) | YES | Geographic region from EXW_DimUser.Region (LEFT JOIN on GCID). Not available in EXW_FinanceReportsBalancesNew. NULL if GCID not in EXW_DimUser. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 17 | Regulation | varchar(256) | YES | Regulation entity name from EXW_FinanceReportsBalancesNew.Regulation. Passthrough. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 18 | PlayerLevelID | int | YES | Player level ID from EXW_FinanceReportsBalancesNew.PlayerLevelID. Passthrough. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 19 | Club | varchar(100) | YES | Player level name (Club tier) from EXW_FinanceReportsBalancesNew.Club. Passthrough. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 20 | RealUser | varchar(100) | YES | User segment classification: 'TestUser' (IsTestAccount=1), 'eTorian' (IsValidCustomer=0), 'RealUser' (otherwise). Derived from EXW_FinanceReportsBalancesNew source flags. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 21 | StateCode | varchar(50) | YES | US state/region code from EXW_DimUser.UserRegionID (LEFT JOIN on GCID). NULL for non-US users. Note: this is UserRegionID, not Dim_State_and_Province.ShortName. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 22 | State | varchar(100) | YES | Full US state/region name from EXW_DimUser.UserRegion_State (LEFT JOIN on GCID). NULL for non-US users. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 23 | UpdateDate | datetime | YES | Extract run timestamp — GETDATE() at SP run time. Reflects when this table was last refreshed. (Tier 2 — SP_EXW_30DayBalanceExtract) |
| 24 | ComplianceClosureEvent | int | YES | Compliance closure flag from EXW_DimUser.ComplianceClosureEvent (LEFT JOIN on GCID). 1 = user has a regulatory country-closure event; 0 = no closure event. Not available in EXW_FinanceReportsBalancesNew. (Tier 2 — SP_EXW_30DayBalanceExtract) |

---

## 5. Lineage

### 5.1 Production Sources

| Table Column | Source Object | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| FullDate | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceDate | Alias rename |
| FullDateID | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceDateID | Alias rename |
| GCID | EXW_dbo.EXW_FinanceReportsBalancesNew | GCID | Passthrough |
| RealCID | EXW_dbo.EXW_FinanceReportsBalancesNew | RealCID | Passthrough |
| CryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | WHERE CryptoID=BlockchainCryptoId |
| CryptoName | EXW_Wallet.CryptoTypes | Name | Blockchain-level name |
| InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | JOIN on ERC CryptoID |
| WalletID | EXW_dbo.EXW_FinanceReportsBalancesNew | WalletID | Passthrough |
| Balance / BalanceUSD | EXW_dbo.EXW_FinanceReportsBalancesNew | Balance / BalanceUSD | Passthrough |
| FactBalance_UpdateDate | EXW_dbo.EXW_FinanceReportsBalancesNew | UpdateDate | Alias rename |
| CryptoIdERC | EXW_dbo.EXW_FinanceReportsBalancesNew | CryptoID | Alias rename |
| CryptoNameERC | EXW_dbo.EXW_FinanceReportsBalancesNew | CryptoName | Alias rename |
| Country / CountryID / Regulation / PlayerLevelID / Club | EXW_dbo.EXW_FinanceReportsBalancesNew | same columns | Passthrough |
| Region | EXW_dbo.EXW_DimUser | Region | LEFT JOIN on GCID |
| RealUser | EXW_FinanceReportsBalancesNew (IsTestAccount, IsValidCustomer) | — | CASE classification |
| StateCode | EXW_dbo.EXW_DimUser | UserRegionID | LEFT JOIN on GCID |
| State | EXW_dbo.EXW_DimUser | UserRegion_State | LEFT JOIN on GCID |
| ComplianceClosureEvent | EXW_dbo.EXW_DimUser | ComplianceClosureEvent | LEFT JOIN on GCID |
| UpdateDate | (computed) | — | GETDATE() |

### 5.2 ETL Flow Diagram

```
TRUNCATE TABLE EXW_dbo.EXW_30DayBalanceExtract
  |
EXW_dbo.EXW_FinanceReportsBalancesNew (WHERE BalanceDateID >= GETDATE()-31)
  |-- 22 of 24 columns via passthrough/alias
  |
  LEFT JOIN EXW_dbo.EXW_DimUser ON GCID
  |  → Region, StateCode (UserRegionID), State (UserRegion_State), ComplianceClosureEvent
  |
  LEFT JOIN EXW_Wallet.CryptoTypes (ERC-level CryptoID)
  |  → InstrumentId
  |
  LEFT JOIN #blcid (CryptoTypes WHERE CryptoID=BlockchainCryptoId)
  |  → CryptoId (blockchain), CryptoName (blockchain)
  v
INSERT INTO EXW_dbo.EXW_30DayBalanceExtract (24 columns, ~52.7M rows, rolling 31 dates)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| Balance / Country / Regulation | EXW_dbo.EXW_FinanceReportsBalancesNew | Primary 30-day balance source |
| Region / State / ComplianceClosureEvent | EXW_dbo.EXW_DimUser | Geographic enrichment (not in source table) |
| CryptoId / CryptoName (blockchain) | EXW_Wallet.CryptoTypes | Blockchain-level crypto mapping |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| Direct analyst queries | Rolling 30-day balance reporting, compliance closure monitoring |
| No SSDT-tracked SP consumers | Leaf node in the EXW_dbo dependency graph |

---

## 7. Sample Queries

### Current balance snapshot (latest available date)

```sql
SELECT
    RealUser,
    CryptoName,
    Country,
    Regulation,
    COUNT(DISTINCT GCID) AS Users,
    SUM(BalanceUSD) AS TotalBalanceUSD
FROM EXW_dbo.EXW_30DayBalanceExtract
WHERE FullDateID = (SELECT MAX(FullDateID) FROM EXW_dbo.EXW_30DayBalanceExtract)
  AND BalanceUSD > 0
GROUP BY RealUser, CryptoName, Country, Regulation
ORDER BY TotalBalanceUSD DESC;
```

### Compliance closure users with active balances

```sql
SELECT
    FullDate,
    GCID,
    RealCID,
    CryptoName,
    Balance,
    BalanceUSD,
    Country
FROM EXW_dbo.EXW_30DayBalanceExtract
WHERE ComplianceClosureEvent = 1
  AND BalanceUSD > 0
  AND FullDateID = (SELECT MAX(FullDateID) FROM EXW_dbo.EXW_30DayBalanceExtract)
ORDER BY BalanceUSD DESC;
```

### US state-level balance distribution

```sql
SELECT
    State,
    StateCode,
    SUM(BalanceUSD) AS TotalBalanceUSD,
    COUNT(DISTINCT GCID) AS Users
FROM EXW_dbo.EXW_30DayBalanceExtract
WHERE StateCode IS NOT NULL
  AND FullDateID = (SELECT MAX(FullDateID) FROM EXW_dbo.EXW_30DayBalanceExtract)
GROUP BY State, StateCode
ORDER BY TotalBalanceUSD DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. SP has no author header or change history comments. SP is parameterless (no @d parameter) — runs as a full TRUNCATE+INSERT on each execution. Window is hardcoded as GETDATE()-31.

---

*Generated: 2026-04-20 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 1 T1, 23 T2, 0 T3, 0 T4, 0 T5 | Elements: 24/24, Logic: 9/10, Sources: 9/10*
*Object: EXW_dbo.EXW_30DayBalanceExtract | Type: Table | Production Source: EXW_dbo.EXW_FinanceReportsBalancesNew*
