# EXW_dbo.EXW_FinanceReportsBalancesNew

> Daily crypto wallet balance reconciliation snapshot for the eToro Wallet portfolio — 1.62B rows covering all active Wallet users across all crypto assets from 2023-01-01 to 2026-04-11. Each row represents one wallet-crypto-date combination, comparing blockchain balances from WalletBalancesReportDB's reconciliation engine against eToro's ledger, enriched with user demographics and AML/compliance status.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletBalancesReportDB.Wallet.FinanceReportRecords (reconciliation results) + EXW_Wallet.CustomerWalletsView (user scope) |
| **Refresh** | Daily — SP_EXW_FinanceReportsBalancesNew @d DATE; DELETE by BalanceDateID + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (BalanceDateID ASC, RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only finance reconciliation snapshot |

---

## 1. Business Meaning

EXW_FinanceReportsBalancesNew is the central daily balance snapshot used by the eToro Wallet finance team to track crypto holdings across all active Wallet users. With 1.62 billion rows, it stores one record per GCID × WalletID × CryptoID × date, covering 689,733 distinct users across 173 cryptocurrency types as of the latest snapshot (2026-04-11).

The table is driven by WalletBalancesReportDB's daily reconciliation engine, which cross-checks wallet balances across three systems: the blockchain ledger (TotalReceive − TotalSend), eToro's internal computed ledger (ComputedAmount), and third-party providers BitGo (ProviderValue) and Blox (WalletTrackerValue). The SP applies a priority rule to select the "best available" balance: if no discrepancy was detected (LevelId IS NULL), BloxBalance is used; if a discrepancy was classified, the BitGoValue or BloxValue is preferred based on LevelId. The result is stored in Balance, and multiplied by the daily average crypto price (EXW_PriceDaily.AvgPrice) to produce BalanceUSD.

80% of rows have Balance = 0 — this is expected: the table includes all wallet-crypto combinations for all users, including wallets with no transactions. Only 20% of rows reflect non-zero crypto holdings.

The table is the canonical balance source for EXW_DimUser_Enriched.TotalBalanceUSD (aggregated as SUM(BalanceUSD) GROUP BY GCID) and for the 30-day balance extract (SP_EXW_30DayBalanceExtract). The `AMLClosureEvent` flag identifies users who are AML-blocked or compensated, computed from EXW_UserSettingsWalletAllowance, EXW_CompensationClosingCountries, and Fact_SnapshotCustomer. `ComplianceClosureEvent` is hardcoded to 0 — the column is retained for schema compatibility but not populated.

XRP wallets (CryptoID=4) have a non-zero `Reserved` column from 2026-04-06 onwards, representing the 10-XRP minimum on-chain activation reserve that is locked and unavailable for trading.

---

## 2. Business Logic

### 2.1 Balance Priority Selection

**What**: The `Balance` column is computed using a hierarchical selection based on reconciliation classification level.

**Columns Involved**: Balance, LevelId, WalletDBBalance, ProviderValue, WalletTrackerValue

**Rules**:
- LevelId IS NULL → use WalletDBBalance (blockchain net balance; no reconciliation discrepancy detected)
- LevelId IS NOT NULL AND ProviderValue IS NULL AND WalletTrackerValue IS NOT NULL → use WalletTrackerValue (Blox balance available, BitGo not)
- LevelId IS NOT NULL AND ProviderValue IS NULL AND WalletTrackerValue IS NULL → use WalletDBBalance (fallback)
- ELSE → use ProviderValue (BitGo balance is preferred when available and discrepancy detected)
- BalanceUSD = Balance × EXW_PriceDaily.AvgPrice for the crypto on that date

### 2.2 AMLClosureEvent Flag

**What**: `AMLClosureEvent` = 1 flags users who are wallet-blocked due to AML status, zero balance, or completed compensation. `ComplianceClosureEvent` is always 0 (hardcoded).

**Columns Involved**: AMLClosureEvent, ComplianceClosureEvent, UserWalletAllowance, PlayerStatus

**Rules**:
- Condition 1: PlayerStatusID IN (2=Blocked, 4=BlockedUponRequest) AND SelectedValue = 0 (wallet not allowed) → AMLClosureEvent = 1
- Condition 2: SelectedValue = 0 AND TotalBalance ≤ 0 → AMLClosureEvent = 1 (blocked + zero balance)
- Condition 3: SelectedValue = 0 AND TotalBalanceUSD ≤ 0 → AMLClosureEvent = 1
- Condition 4: GCID in EXW_CompensationClosingCountries (compensated, project-specific) AND SelectedValue = 0 → AMLClosureEvent = 1
- 12.5% of rows in the latest snapshot have AMLClosureEvent = 1

### 2.3 LevelId — Reconciliation Classification

**What**: LevelId classifies the reconciliation outcome for each wallet-crypto pair, inherited verbatim from WalletBalancesReportDB.Dictionary.FinanceReportLevel.

**Columns Involved**: LevelId, WalletDBBalance, ComputedAmount, ProviderValue, WalletTrackerValue

**Rules**:
- NULL (96.9%): No discrepancy detected — balances agree within threshold
- 3 = EtoroDiffBoth (1.5%): eToro ledger differs from both BitGo and Blox consensus — most common discrepancy
- 2 = AllDiff (0.35%): All three systems disagree — full investigation required
- 1 = EventualyConsolidated (0.24%): Discrepancy self-resolved across runs

### 2.4 XRP Reserve (Added 2026-04-06)

**What**: XRP wallets require a minimum on-chain balance of 10 XRP (the "activation reserve"). This locked amount is tracked in `Reserved`.

**Columns Involved**: Reserved, CryptoID

**Rules**:
- Reserved = ISNULL(WalletPoolAttributes.ReservedAmount, 0) — only non-zero for XRP wallets (CryptoID = 4)
- For all other cryptos, Reserved = 0
- The 10-XRP minimum is locked on-chain and unavailable for trading or withdrawal

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution (no partition key) — queries must filter on CLUSTERED INDEX columns (BalanceDateID, RealCID) to avoid full table scans. At 1.62B rows, a full scan is extremely expensive. Always filter by BalanceDateID first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Total USD balance for a user | `SELECT SUM(BalanceUSD) FROM EXW_FinanceReportsBalancesNew WHERE GCID = @gcid AND BalanceDateID = (SELECT MAX(BalanceDateID) FROM EXW_FinanceReportsBalancesNew)` |
| Users with non-zero wallet balance on a date | `SELECT GCID, SUM(BalanceUSD) AS TotalUSD FROM EXW_FinanceReportsBalancesNew WHERE BalanceDateID = @dateID AND BalanceUSD > 0 GROUP BY GCID` |
| AML-flagged users on latest date | `WHERE BalanceDateID = MAX(BalanceDateID) AND AMLClosureEvent = 1` |
| ETH balance history for a user | `WHERE GCID = @gcid AND CryptoID = 2 ORDER BY BalanceDateID` |
| Reconciliation discrepancies | `WHERE BalanceDateID = @dateID AND LevelId IS NOT NULL AND Balance <> 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_DimUser | GCID = GCID | User demographic enrichment |
| EXW_AML_Users_Report | GCID = GCID | AML status and compliance flags |
| EXW_UserSettingsWalletAllowance | GCID = GCID | Wallet allowance decisions |

### 3.4 Gotchas

- **80% zero-balance rows**: Always filter `Balance > 0` or `BalanceUSD > 0` unless you need the full wallet inventory including inactive wallets
- **Balance = 0 is ambiguous**: May mean zero holdings, no price available for that crypto on that date, or the wallet was never activated
- **ROUND_ROBIN distribution**: No colocation with GCID-based tables; expect data movement in JOINs
- **XRP Reserved**: For XRP balance analysis, `Balance - Reserved` gives the spendable amount (from 2026-04-06 onwards)
- **AMLClosureEvent vs ComplianceClosureEvent**: AMLClosureEvent is computed and meaningful (12.5% = 1); ComplianceClosureEvent is always 0 (hardcoded) — do not use it in analysis
- **Multiple rows per user per date**: One row per wallet × crypto combination; always GROUP BY GCID when computing user-level totals
- **5 Bitcoin addresses excluded**: Legacy pre-2021 Beta wallets (addresses starting with `3GqmgFc...`, `3JZ2Ekm...`, `3KjmsAn...`, `3Peo3MT...`, `3Qjmwe3...`) are excluded from inserts — these are pre-production wallets
- **CryptoID = 158 excluded**: One crypto type filtered out in SP output

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki (WalletBalancesReportDB.Wallet.FinanceReportRecords or Customer.CustomerStatic) |
| Tier 2 | Derived from SP code analysis — ETL-computed, lookup-enriched, or sourced without upstream wiki |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best guess — no code or wiki evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID -- identifies the wallet owner. Carried from the external table for denormalized customer-level querying without joining back to WalletDB. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 2 | RealCID | int | NULL | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from DWH_dbo.Fact_SnapshotCustomer relay. (Tier 1 — Customer.CustomerStatic) |
| 3 | WalletID | uniqueidentifier | NO | Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). Used in CROSS APPLY joins by CreateNewReportRun and GetFinanceSnapshot to correlate with external table data. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 4 | PublicAddress | nvarchar(max) | NULL | Blockchain address associated with this wallet-crypto pair. Passed through from the external table for traceability during discrepancy investigation. NULL for wallets without dedicated on-chain addresses. Renamed from FinanceReportRecords.Address. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 5 | CryptoID | int | NO | Cryptocurrency asset identifier. Completes the composite business key. Same CryptoId may appear multiple times per run if a customer has multiple wallets for the same crypto. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 6 | CryptoName | nvarchar(256) | NULL | Human-readable crypto asset name. Lookup from EXW_Wallet.CryptoTypes by CryptoID. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 7 | BalanceDate | date | NULL | Snapshot date for this balance record. Set to the @d input parameter of SP_EXW_FinanceReportsBalancesNew. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 8 | BalanceDateID | int | NULL | Integer representation of BalanceDate in YYYYMMDD format. Used as the primary filter key for incremental DELETE+INSERT. CLUSTERED INDEX key. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 9 | Price_Date | date | NULL | Date of the price record used for USD conversion. Sourced from EXW_Wallet.EXW_PriceDaily.FullDate, matched by CryptoID + BalanceDateID. May differ from BalanceDate if no price is available for that exact date. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 10 | Rate | decimal(38,8) | NULL | Daily average crypto-to-USD price used to compute BalanceUSD. Sourced from EXW_Wallet.EXW_PriceDaily.AvgPrice for CryptoID on BalanceDateID. NULL if no price record exists for this crypto on this date. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 11 | ReportID | bigint | NO | FK to Wallet.FinanceReportRuns.Id identifying which reconciliation run produced this record. Constraint: FK__FinanceReportRecords__ReportId. Indexed in composite with LevelId and with WalletId+CryptoId. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 12 | TotalReceive | decimal(38,18) | NULL | Total amount received into this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalRecive (note: mapped from the misspelled column). Represents the cumulative incoming blockchain transactions. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 13 | TotalSend | decimal(38,18) | NULL | Total amount sent from this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalSend. Represents the cumulative outgoing blockchain transactions. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 14 | WalletDBBalance | decimal(38,18) | NULL | Blockchain-reported net balance (TotalReceive - TotalSend). Despite the name suggesting "Blox balance," this is actually the blockchain/computed balance from the external table's TotalBalance column. The naming reflects the legacy system where Blox was the primary comparison source. Renamed from FinanceReportRecords.BloxBalance. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 15 | ComputedAmount | decimal(38,18) | NULL | Internally computed expected balance from eToro's ledger system. Sourced from vu_GetWalletBalanceReport.TotalAmount. The reconciliation threshold check compares this against BloxBalance: ABS(ComputedAmount - BloxBalance) > @Threshold. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 16 | ProviderValue | decimal(38,18) | NULL | Balance amount reported by BitGo custody provider during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual BitGo API response. NULL/0 until the verification phase processes this record. Renamed from FinanceReportRecords.BitgoValue. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 17 | WalletTrackerValue | decimal(38,18) | NULL | Balance amount reported by Blox portfolio tracker during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual Blox API response. NULL/0 until verification. Renamed from FinanceReportRecords.BloxValue. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 18 | LevelId | int | NULL | FK to Dictionary.FinanceReportLevel classifying the reconciliation outcome. Initially set to 100 (InitialDiscrepancy) if balance exceeds threshold, NULL otherwise. Refined by UpdateReportRecords: 1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, 5-11=API errors, 12=InternalError. Distribution: NULL=96.9%, 3=1.5%, 2=0.35%, 1=0.24%. (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 19 | ReportOccurred | datetime2(7) | NULL | UTC timestamp when the reconciliation record was created by WalletBalancesReportDB.Wallet.CreateNewReportRun. Renamed from FinanceReportRecords.Created (aliased as Occurred in SP). (Tier 1 — WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| 20 | Balance | decimal(38,18) | NULL | Best available crypto balance for this wallet-crypto pair, selected by LevelId-based priority: LevelId IS NULL → WalletDBBalance; LevelId set but only BloxValue available → WalletTrackerValue; LevelId set but both providers NULL → WalletDBBalance; ELSE → ProviderValue (BitGo preferred). 80% of rows = 0 (inactive wallets). (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 21 | BalanceUSD | decimal(38,8) | NULL | Balance converted to USD using daily average price. Computed as Balance × Rate (EXW_Wallet.EXW_PriceDaily.AvgPrice). 0 when Balance = 0 or Rate is NULL (price unavailable). Used by SP_EXW_DimUser_Enriched as the canonical TotalBalanceUSD source. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 22 | RegulationID | tinyint | NULL | Regulatory entity classification at the time of the snapshot. Sourced from DWH_dbo.Fact_SnapshotCustomer. Distribution (latest date): CySEC=1 (46%), FCA=2 (27%), FinCEN+FINRA=8 (7%), FSA SEY=9 (5%), BVI=5 (5%), ASIC & GAML=10 (4%), eToroUS=6 (3%), others. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via Fact_SnapshotCustomer) |
| 23 | Regulation | nvarchar(256) | NULL | Human-readable name of the regulatory entity. Lookup from DWH_dbo.Dim_Regulation.Name by RegulationID (DWHRegulationID). (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 24 | CountryID | int | NULL | Country of the wallet user at snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer.CountryID. FK to DWH_dbo.Dim_Country. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via Fact_SnapshotCustomer) |
| 25 | Country | nvarchar(256) | NULL | Human-readable country name. Lookup from DWH_dbo.Dim_Country.Name by CountryID. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 26 | IsTestAccount | int | NULL | 1 = user is a known test account (matched from EXW_TestUsers by username pattern or Beta criteria). 0 = real customer. Sourced from EXW_DimUser via LEFT JOIN on GCID. NULL if GCID not found in EXW_DimUser (pre-scope users). (Tier 2 — SP_EXW_FinanceReportsBalancesNew via EXW_DimUser) |
| 27 | IsValidCustomer | int | NULL | 1 = user passes standard eToro customer validity checks at snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer.IsValidCustomer. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via Fact_SnapshotCustomer) |
| 28 | VerificationLevelID | int | NULL | KYC verification tier at snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer. FK to Dim_VerificationLevel (1=Registered, 2=Phone verified, 3=KYC approved). (Tier 2 — SP_EXW_FinanceReportsBalancesNew via Fact_SnapshotCustomer) |
| 29 | PlayerLevelID | int | NULL | Club tier of the user at snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer. FK to Dim_PlayerLevel (1=Bronze, 2=Silver, 3=Gold, 4=Platinum, 5=Diamond). (Tier 2 — SP_EXW_FinanceReportsBalancesNew via Fact_SnapshotCustomer) |
| 30 | Club | nvarchar(256) | NULL | Human-readable club tier name. Lookup from DWH_dbo.Dim_PlayerLevel.Name by PlayerLevelID. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 31 | ComplianceClosureEvent | int | NOT NULL | Always 0. Column was intended to flag country-closure-affected users but is hardcoded to 0 in SP_EXW_FinanceReportsBalancesNew. Retained for schema backward compatibility. Do not use in analysis. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 32 | AMLClosureEvent | int | NOT NULL | 1 = user is wallet-blocked due to AML/compliance conditions; 0 = normal. Set to 1 if any of 4 conditions: (1) PlayerStatus Blocked/BlockedUponRequest AND wallet not allowed; (2) wallet not allowed AND TotalBalance ≤ 0; (3) wallet not allowed AND TotalBalanceUSD ≤ 0; (4) compensated user AND wallet not allowed. 12.5% of rows in latest snapshot. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 33 | UserWalletAllowance | nvarchar(256) | NULL | Resolved wallet access decision for the user. Sourced from EXW_UserSettingsWalletAllowance via LEFT JOIN on GCID. Values: Allowed, NotAllowed, ReadOnly. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via EXW_UserSettingsWalletAllowance) |
| 34 | UpdateDate | datetime | NOT NULL | Timestamp of when this row was inserted into EXW_FinanceReportsBalancesNew. Set to GETDATE() at insert time by the SP. (Tier 2 — SP_EXW_FinanceReportsBalancesNew) |
| 35 | WalletEntity | nvarchar(124) | NULL | Legal entity under which the wallet operates (e.g., eToro Europe Ltd, eToro USA LLC). Sourced from EXW_dbo.EXW_WalletEntity via LEFT JOIN on GCID + BalanceDateID. NULL for dates before WalletEntity data was backfilled or users not in EXW_WalletEntity. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via EXW_WalletEntity) |
| 36 | PlayerStatus | nvarchar(124) | NULL | Human-readable player/account status at snapshot date. Lookup from DWH_dbo.Dim_PlayerStatus.Name by PlayerStatusID. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via Dim_PlayerStatus) |
| 37 | Reserved | decimal(38,18) | NULL | XRP on-chain activation reserve locked in this wallet. For XRP wallets (CryptoID=4): ISNULL(WalletPool.WalletPoolAttributes.ReservedAmount, 0). For all other cryptos: 0. Added 2026-04-06. The 10-XRP minimum reserve is required to activate an XRP wallet on-chain and cannot be withdrawn. (Tier 2 — SP_EXW_FinanceReportsBalancesNew via EXW_Wallet.WalletPool) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | WalletBalancesReportDB.Wallet.FinanceReportRecords | Gcid | Passthrough |
| RealCID | Customer.CustomerStatic (via Fact_SnapshotCustomer) | CID | Relay passthrough |
| WalletID | WalletBalancesReportDB.Wallet.FinanceReportRecords | WalletId | Passthrough |
| PublicAddress | WalletBalancesReportDB.Wallet.FinanceReportRecords | Address | Renamed |
| CryptoID | WalletBalancesReportDB.Wallet.FinanceReportRecords | CryptoId | Passthrough |
| ReportID | WalletBalancesReportDB.Wallet.FinanceReportRecords | ReportId | Passthrough |
| TotalReceive | WalletBalancesReportDB.Wallet.FinanceReportRecords | TotalReceive | Passthrough |
| TotalSend | WalletBalancesReportDB.Wallet.FinanceReportRecords | TotalSend | Passthrough |
| WalletDBBalance | WalletBalancesReportDB.Wallet.FinanceReportRecords | BloxBalance | Renamed |
| ComputedAmount | WalletBalancesReportDB.Wallet.FinanceReportRecords | ComputedAmount | Passthrough |
| ProviderValue | WalletBalancesReportDB.Wallet.FinanceReportRecords | BitgoValue | Renamed |
| WalletTrackerValue | WalletBalancesReportDB.Wallet.FinanceReportRecords | BloxValue | Renamed |
| LevelId | WalletBalancesReportDB.Wallet.FinanceReportRecords | LevelId | Passthrough |
| ReportOccurred | WalletBalancesReportDB.Wallet.FinanceReportRecords | Created | Renamed |
| Balance | SP_EXW_FinanceReportsBalancesNew | — | ETL-computed: LevelId-based CASE expression |
| BalanceUSD | SP_EXW_FinanceReportsBalancesNew | — | ETL-computed: Balance × EXW_PriceDaily.AvgPrice |

### 5.2 ETL Pipeline

```
WalletBalancesReportDB.Wallet.FinanceReportRecords
  (daily reconciliation results — BloxBalance, BitgoValue, BloxValue, LevelId)
  |
  | CopyFromLake (Bronze Parquet → Synapse External Tables)
  | via CopyFromLake.WalletBalancesReportDB_Wallet_FinanceReportRecords
  |                                            |
EXW_Wallet.CustomerWalletsView (user scope)   |
DWH_dbo.Fact_SnapshotCustomer (demographics)  |
EXW_dbo.EXW_UserSettingsWalletAllowance       |
EXW_dbo.EXW_CompensationClosingCountries      |
EXW_Wallet.EXW_PriceDaily (daily rates)       |
  |                                            |
  +--------------------------------------------+
  |
  | SP_EXW_FinanceReportsBalancesNew @d DATE
  | DELETE by BalanceDateID + INSERT
  v
EXW_dbo.EXW_FinanceReportsBalancesNew (1.62B rows — Synapse)
  |
  +-- SP_EXW_DimUser_Enriched → EXW_DimUser_Enriched.TotalBalanceUSD
  +-- SP_EXW_30DayBalanceExtract → EXW_30DayBalanceExtract
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Wallet user dimension — scope and IsTestAccount |
| GCID | EXW_dbo.EXW_UserSettingsWalletAllowance | Wallet access decision source |
| GCID | EXW_dbo.EXW_WalletEntity | Legal entity per wallet user per date |
| GCID | EXW_dbo.EXW_CompensationClosingCountries | AML compensation status check |
| CryptoID | EXW_Wallet.CryptoTypes | Crypto asset name lookup |
| CryptoID + BalanceDateID | EXW_Wallet.EXW_PriceDaily | Daily crypto-to-USD rate |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation name |
| CountryID | DWH_dbo.Dim_Country | Country name |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Club tier name |

### 6.2 Referenced By

| Source Object | Join Column | Description |
|--------------|-------------|-------------|
| EXW_dbo.EXW_DimUser_Enriched | GCID | SUM(BalanceUSD) GROUP BY GCID → TotalBalanceUSD per user |
| EXW_dbo.EXW_30DayBalanceExtract | GCID, BalanceDateID | Rolling 30-day balance window |

---

## 7. Sample Queries

### 7.1 Total USD balance per user for the latest available date

```sql
SELECT
    GCID,
    RealCID,
    SUM(BalanceUSD) AS TotalBalanceUSD,
    COUNT(DISTINCT CryptoID) AS ActiveCryptos
FROM EXW_dbo.EXW_FinanceReportsBalancesNew
WHERE BalanceDateID = (SELECT MAX(BalanceDateID) FROM EXW_dbo.EXW_FinanceReportsBalancesNew)
  AND BalanceUSD > 0
GROUP BY GCID, RealCID
ORDER BY TotalBalanceUSD DESC;
```

### 7.2 Daily balance history for a specific user across all cryptos

```sql
SELECT
    BalanceDate,
    CryptoName,
    Balance,
    BalanceUSD,
    Rate,
    LevelId
FROM EXW_dbo.EXW_FinanceReportsBalancesNew
WHERE GCID = 12345678
  AND BalanceDateID >= 20250101
ORDER BY BalanceDateID, CryptoID;
```

### 7.3 Reconciliation discrepancies requiring investigation on a specific date

```sql
SELECT
    GCID,
    WalletID,
    CryptoName,
    WalletDBBalance,    -- blockchain net
    ComputedAmount,     -- eToro ledger
    ProviderValue,      -- BitGo
    WalletTrackerValue, -- Blox
    LevelId,
    Balance
FROM EXW_dbo.EXW_FinanceReportsBalancesNew
WHERE BalanceDateID = 20260411
  AND LevelId IN (2, 3)  -- AllDiff or EtoroDiffBoth
  AND Balance > 0
ORDER BY BalanceUSD DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found. SP header notes: authored by Inessa Kontorovich, initial creation 2020-05-21, major optimization 2023-07-03 (performance improvements, AML fix, parameter fix). Recent additions: WalletEntity (2025-06-06), AML_EEA flag (2025-07-27), AML flag logic overhaul (2025-11-08), XRP Reserve (2026-04-06).

---

*Generated: 2026-04-20 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 14 T1, 23 T2, 0 T3, 0 T4, 0 T5 | Elements: 37/37, Logic: 9/10, Sources: 8/10*
*Object: EXW_dbo.EXW_FinanceReportsBalancesNew | Type: Table | Production Source: WalletBalancesReportDB.Wallet.FinanceReportRecords*
