# EXW_dbo.EXW_EOMReportingBalances

> Monthly end-of-month regulatory balance reporting snapshot for eToro Wallet — 25.4M rows covering 23 months from Nov-2021 through Sep-2023 (decommissioned). One row per customer × wallet × crypto-asset × month-end date, providing regulators (CySEC, FCA, FinCEN, ASIC, BVI, etc.) with full balance statements including LTD/MTD activity, opening/closing balances, third-party tracker reconciliation, and compliance flags. No SSDT writer SP — loaded via external ETL. Last update: 2023-10-15; superseded by EXW_ReportingBalances schema (empty successor).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Monthly Regulatory Balance Snapshot — DECOMMISSIONED) |
| **Production Source** | External ETL (Python/ADF — not tracked in SSDT repo) |
| **Writer SP** | None found in SSDT |
| **Refresh** | Monthly EOM batch — last run 2023-10-15 for Sep-2023 reporting |
| **Row Count** | 25,417,666 (23 monthly snapshots × ~1.1M rows/month, growing) |
| **Date Range** | ReportingDate: 2021-11-30 — 2023-09-30 |
| **Synapse Distribution** | HASH([eToro Unique ID 1 GCID]) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — historical archive |

---

## 1. Business Meaning

EXW_EOMReportingBalances is the historical monthly regulatory balance reporting table for eToro Wallet. It captures a complete snapshot of every customer's crypto holdings at the end of each month, supporting balance reporting requirements across all applicable jurisdictions.

**Business context**: eToro Wallet is subject to regulatory reporting obligations across multiple jurisdictions — CySEC (EU/Cyprus, 546K rows in Sep-2023), FCA (UK, 310K), BVI (105K), ASIC & GAML (81K), FinCEN/FINRA (US, 76K), and others. For each jurisdiction, regulators may require monthly position reports showing each customer's crypto holdings with opening/closing balances, activity, and USD valuations.

**What each row represents**: One customer's holding of one crypto asset at one month-end date. The same customer appears multiple times — once per crypto asset they hold (131 distinct cryptos across 467,616 distinct GCIDs in the last snapshot).

**Scale and growth**: The table grew from ~949K rows/month in Nov-2021 to ~1.23M rows/month in Sep-2023 — reflecting both new user growth and expansion of the tracked crypto universe.

**Decommissioning**: The last batch loaded was 2023-10-15 for the Sep-2023 reporting period. The successor schema (EXW_ReportingBalances, 40 cols, empty) drops the debugging columns and tightens compliance field constraints, but has not been populated as of 2026-04-20.

**Key columns**: The table combines blockchain balance data (LTD activity, closing balance), regulatory reporting values (Reporting Balance with known-issue corrections), third-party reconciliation (TrackerBalance vs ledger), and customer regulatory context (Country, Regulation, compensation flags) in a single denormalized row.

---

## 2. Business Logic

### 2.1 Balance Hierarchy: LTD → MTD → Closing → Reporting

**What**: The table tracks the full balance chain from lifetime activity to the official regulatory reporting figure.

**Columns Involved**: `[LTD Units Recieved]`, `[LTD Units Sent]`, `[Closing Units Balance]`, `[Opening Balance...]`, `[MTD Units Sent]`, `[MTD Units Recieved]`, `[MTD Units Total]`, `[MTD Balance Change]`, `[Reporting Balance]`

**Rules**:
- `[Closing Units Balance]` ≈ `[LTD Units Recieved]` - `[LTD Units Sent]` (minor rounding differences for ERC-20 tokens)
- `[Opening Balance as of the 1st of Designated Month]` = prior month's `[Closing Units Balance]`
- `[MTD Balance Change]` = `[Closing Units Balance]` - `[Opening Balance...]`
- `[MTD Units Total]` = `[MTD Units Recieved]` - `[MTD Units Sent]`
- `[MTD Balance Change -MTD Units Total]` = `[MTD Balance Change]` - `[MTD Units Total]` (non-zero = staking or correction)
- `[Reporting Balance]` = `[Closing Units Balance]` for normal wallets; corrected value for KnownIssueWallet=1 rows

### 2.2 KnownIssueWallet Correction

**What**: Some wallets have persistent reconciliation discrepancies. For these, a corrected DevReportBalance value is used as the official reporting balance.

**Columns Involved**: `[KnownIssueWallet]`, `[DevReportBalance For 'KnownIssueWallets']`, `[DevReportBalanceUSD For 'KnownIssueWallets']`, `[Reporting Balance]`, `[DevReportBalancesTime]`

**Rules**:
- `[KnownIssueWallet]` = 1 → `[Reporting Balance]` uses the corrected DevReportBalance value
- `[KnownIssueWallet]` = 0 → `[Reporting Balance]` = `[Closing Units Balance]`
- `[DevReportBalancesTime]` records when the balance calculation engine ran for all rows (same timestamp per batch)
- From data: KnownIssueWallet=1 rows still have TrackerBalance data and Gap in USD estimates

### 2.3 TrackerBalance Reconciliation

**What**: Independent cross-validation comparing the eToro-computed balance against a third-party provider's balance.

**Columns Involved**: `[TrackerBalance]`, `[TrackerBalanceUSD]`, `[Has Dif with TrackerBalance]`, `[Dif with TrackerBalance]`, `[Gap in USD -Estimation]`

**Rules**:
- `[Has Dif with TrackerBalance]` NOT NULL: 'Y' or 'N'
- `[Dif with TrackerBalance]` = `[TrackerBalance]` - `[Closing Units Balance]`
- `[Gap in USD -Estimation]` = USD value of the discrepancy
- Most rows have `[Has Dif with TrackerBalance]` = 'N' and Gap = 0

### 2.4 Regulatory Context Enrichment

**What**: Each row is enriched with the customer's regulatory context for the reporting period.

**Columns Involved**: `[Country]`, `[Regulation]`, `[Closed Country AND Regulation]`, `[User was Compensated during Country Closure]`, `[UserWalletAllowance]`, `[IsValidCustomer]`, `[VerificationLevelID]`, `[PlayerLevelID]`

**Rules**:
- `[Regulation]` determines which regulator receives this row: CySEC, FCA, FinCEN, ASIC & GAML, BVI, eToroUS, FSA Seychelles, NFA
- `[Closed Country AND Regulation]` = 'Y' if the customer's jurisdiction was closed — EXW_CompensationClosingCountries pattern
- `[UserWalletAllowance]` = 'NotAllowed' for users with wallet restrictions (AML blocks, etc.)
- `[IsValidCustomer]` = 1 for active customers; VerificationLevelID and PlayerLevelID are point-in-time CRM snapshots

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH distributed on `[eToro Unique ID 1 GCID]`. HEAP — no clustered index. For large month-level queries, filter on `[ReportingDate]` to reduce scan to a single monthly partition (~1.1-1.2M rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Sep-2023 CySEC regulatory report | `WHERE [ReportingDate] = '2023-09-30' AND [Regulation] = 'CySEC'` |
| Customer's full balance history across all months | `WHERE [eToro Unique ID 1 GCID] = @gcid ORDER BY [ReportingDate]` |
| Monthly closing balance by regulation | GROUP BY `[ReportingDate]`, `[Regulation]`, `[Cryptoasset]`, SUM [Closing Balance USD] |
| Known-issue wallets for a month | Filter `[KnownIssueWallet] = 1 AND [ReportingDate] = @date` |
| Country-closure affected customers | Filter `[Closed Country AND Regulation] = 'Y'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_ReportingBalances | GCID + Cryptoasset + ReportingDate | Successor table for Oct-2023+ (if ever populated) |
| EXW_dbo.EXW_DimUser_Enriched | [eToro Unique ID 1 GCID] = GCID | Additional customer attributes |

### 3.4 Gotchas

- **DECOMMISSIONED**: Last data is Sep-2023. Do not expect new rows.
- **Leading space in column name**: `[ Closing Balance Date]` — note the space: `[ Closing Balance Date]`
- **DDL typos**: `[LTD Units Recieved]` and `[MTD Units Recieved]` — missing 'n' — same in both this and EXW_ReportingBalances
- **UserWalletAllowance padding**: nchar(50) pads values with trailing spaces — use RTRIM for comparison
- **Space-in-name columns**: Virtually all metric columns require `[bracket]` quoting
- **XRP addresses**: Include destination tag suffix (`?dt=0`) — must handle when parsing blockchain addresses
- **0E-8 values**: Decimal columns store true zeros as `0E-8` — functionally equivalent to 0.00000000
- **NULL nullability for NOT NULL cols**: Several columns marked NOT NULL in DDL have NULL semantics (can be absent in the external ETL — DDL constraint but not enforced by a SP)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from column name + data patterns |
| Tier 4 | Best available knowledge — no SP, no upstream wiki (limited confidence) |
| Tier 5 | Domain glossary |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportingDate | date | YES | Month-end reporting date — always the last calendar day of the reporting month (e.g., 2023-09-30, 2023-08-31). 23 distinct values: Nov-2021 through Sep-2023. Part of the reporting grain key. (Tier 4 — External ETL) |
| 2 | ReportingDateID | int | YES | Date integer key in YYYYMMDD format derived from ReportingDate (e.g., 20230930). Used for indexed lookups. Not present in EXW_ReportingBalances. (Tier 4 — External ETL) |
| 3 | [eToro Unique ID 1 GCID] | bigint | NO | Global Customer ID. Primary customer identifier. HASH distribution key. 467,616 distinct values in Sep-2023 snapshot. NOT NULL. (Tier 4 — External ETL) |
| 4 | [eToro Unique ID 2 CID] | bigint | NO | Legacy eToro trading platform CID. Paired with GCID for cross-system joins. NOT NULL. (Tier 4 — External ETL) |
| 5 | [eToro Wallet Identifier] | uniqueidentifier | NO | WalletID — UUID identifying the specific blockchain wallet record in WalletDB.Wallets. Maps to [Public Wallet Address]. NOT NULL in this schema. (Tier 4 — External ETL) |
| 6 | [Public Wallet Address] | nvarchar(max) | YES | Blockchain address for this wallet. Format varies by crypto: BTC (base58), ETH (0x hex), XRP (with `?dt=N` destination tag suffix), SOL (base58). nvarchar(max) allows any length. (Tier 4 — External ETL) |
| 7 | [Cryptoasset] | nvarchar(256) | YES | Display name of the crypto asset. 131 distinct values across all months. Common values: BTC, ETH, XRP, ADA, DOGE, SOL, GLDX, and many ERC-20 tokens. Determines denomination of all balance columns. (Tier 4 — External ETL) |
| 8 | [Opening Balance as of the 1st of Designated Month] | numeric(38,8) | YES | Crypto units held at the start of the reporting month (midnight on the 1st). Equal to the prior month's [Closing Units Balance] for the same GCID+WalletID+Cryptoasset. 0E-8 for customers with zero holdings. (Tier 4 — External ETL) |
| 9 | [Prior Month Closing Balance Date] | datetime | YES | Datetime of the prior month-end balance snapshot. Connects this month's opening to the prior month's record (e.g., 2023-09-30 row has Prior Month = 2023-08-31 datetime). (Tier 4 — External ETL) |
| 10 | [LTD Units Recieved] | numeric(38,8) | YES | Lifetime-to-date total crypto units received across all transactions since account creation. Monotonically increasing over time. DDL typo: "Recieved" for "Received" — same in EXW_ReportingBalances. (Tier 4 — External ETL) |
| 11 | [LTD Units Sent] | numeric(38,8) | YES | Lifetime-to-date total crypto units sent across all transactions. LTD Received − LTD Sent ≈ Closing Units Balance (minor differences for ERC-20 tokens). (Tier 4 — External ETL) |
| 12 | [Closing Units Balance] | numeric(38,8) | YES | Closing crypto balance at month-end in native crypto units. The raw ledger balance before any KnownIssueWallet correction. Most rows have 0E-8 (customers with no active holdings). (Tier 4 — External ETL) |
| 13 | [Closing Balance USD] | numeric(38,8) | YES | [Closing Units Balance] converted to USD using the month-end exchange rate. Used for USD-normalized reporting. (Tier 4 — External ETL) |
| 14 | [Reporting Balance] | numeric(38,8) | YES | Official regulatory reporting balance. For KnownIssueWallet=0 rows: same as [Closing Units Balance]. For KnownIssueWallet=1: uses corrected [DevReportBalance For 'KnownIssueWallets'] value. (Tier 4 — External ETL) |
| 15 | [Reporting Balance USD] | numeric(38,6) | YES | [Reporting Balance] converted to USD. This is the figure submitted to regulators. 6 decimal precision (vs 8 for balance columns). (Tier 4 — External ETL) |
| 16 | [DevReportBalancesTime] | datetime2(7) | YES | Diagnostic: timestamp when the balance calculation engine ran for this reporting batch. Same value for all rows in a given ReportingDate. Not a business field. (Tier 4 — External ETL) |
| 17 | [DevReportBalance For 'KnownIssueWallets'] | decimal(20,8) | YES | Diagnostic: the corrected balance value applied to KnownIssueWallet=1 rows. Traces the source of any [Reporting Balance] vs [Closing Units Balance] discrepancy. Non-NULL only for KnownIssueWallet=1. (Tier 4 — External ETL) |
| 18 | [DevReportBalanceUSD For 'KnownIssueWallets'] | decimal(38,6) | YES | Diagnostic: USD value of [DevReportBalance For 'KnownIssueWallets']. Non-NULL only for KnownIssueWallet=1. (Tier 4 — External ETL) |
| 19 | [ Closing Balance Date] | datetime | YES | Date-time of the closing balance event. Note: column name has a leading space — must be queried as `[ Closing Balance Date]`. In data: always the EOM date at midnight (e.g., 2023-09-30 00:00:00). (Tier 4 — External ETL) |
| 20 | [Country] | varchar(100) | YES | Customer's country of residence at time of reporting. Determines applicable regulatory framework. Common values: Germany, United Kingdom, Ukraine, United States, Netherlands, and 150+ others. (Tier 4 — External ETL) |
| 21 | [Regulation] | varchar(100) | YES | Customer's regulatory jurisdiction. 10 distinct values: CySEC (44%), FCA (25%), BVI (8.5%), ASIC & GAML (6.6%), FinCEN+FINRA (6.2%), eToroUS (4.2%), FinCEN (2.2%), ASIC (1.4%), FSA Seychelles (1.4%), NFA (<0.1%). (Tier 4 — External ETL) |
| 22 | [Test accounting classifier] | bigint | YES | Accounting classification for test/QA accounts. 0 = production account; non-zero = test classification category. From data: mostly 0. (Tier 4 — External ETL) |
| 23 | [MTD Units Sent] | numeric(38,8) | YES | Crypto units sent during the reporting month only (not lifetime). Month-to-date activity. (Tier 4 — External ETL) |
| 24 | [MTD Units Recieved] | numeric(38,8) | YES | Crypto units received during the reporting month only. DDL typo: "Recieved". (Tier 4 — External ETL) |
| 25 | [MTD Units Total] | numeric(38,8) | YES | Net MTD units: [MTD Units Recieved] - [MTD Units Sent]. Positive = net inflow; negative = net outflow for the month. (Tier 4 — External ETL) |
| 26 | [MTD Balance Change] | numeric(38,8) | YES | Actual balance change: [Closing Units Balance] - [Opening Balance as of the 1st of Designated Month]. May differ from [MTD Units Total] due to staking rewards or corrections. (Tier 4 — External ETL) |
| 27 | [MTD Balance Change -MTD Units Total Flag] | varchar(1) | NO | Consistency check: 'Y' if [MTD Balance Change] ≠ [MTD Units Total]; 'N' if they match. NOT NULL. From data: 'N' for all sampled rows including KnownIssueWallet=1. (Tier 4 — External ETL) |
| 28 | [MTD Balance Change -MTD Units Total] | numeric(38,8) | YES | Numeric difference: [MTD Balance Change] minus [MTD Units Total]. Non-zero values indicate staking adjustments or corrections. (Tier 4 — External ETL) |
| 29 | [Gap in USD -Estimation] | numeric(38,6) | YES | Estimated USD gap between [Reporting Balance USD] and [TrackerBalanceUSD]. Non-zero values indicate unresolved reconciliation discrepancies. (Tier 4 — External ETL) |
| 30 | [TrackerBalance] | numeric(38,8) | YES | Third-party provider's independent balance for this wallet-crypto combination (likely BitGo or Blox, same providers as EXW_FinanceReportsBalancesNew). Used for cross-validation. (Tier 4 — External ETL) |
| 31 | [TrackerBalanceUSD] | numeric(38,8) | YES | [TrackerBalance] converted to USD. (Tier 4 — External ETL) |
| 32 | [Has Dif with TrackerBalance] | varchar(1) | NO | 'Y' if [Closing Units Balance] differs from [TrackerBalance]; 'N' otherwise. NOT NULL. (Tier 4 — External ETL) |
| 33 | [Dif with TrackerBalance] | numeric(38,8) | YES | Numeric difference: [TrackerBalance] minus [Closing Units Balance]. Positive = tracker shows higher balance. (Tier 4 — External ETL) |
| 34 | [KnownIssueWallet] | int | YES | Flag (0/1) indicating this wallet has a known persistent reconciliation issue requiring corrective [Reporting Balance] override. NULL in DDL (vs NOT NULL in EXW_ReportingBalances). (Tier 4 — External ETL) |
| 35 | [Most Recent Occured Date] | datetime | YES | Datetime of the most recent transaction recorded for this wallet-crypto combination. NULL when no transactions exist. (Tier 4 — External ETL) |
| 36 | [UserWalletAllowance] | nchar(50) | YES | Wallet allowance status from EXW_UserSettingsWalletAllowance. Values: 'Allowed' or 'NotAllowed' (padded to 50 chars with spaces — RTRIM for comparison). (Tier 4 — External ETL) |
| 37 | [Closed Country AND Regulation] | varchar(2) | YES | 'Y' if the customer's country+regulation combination is closed/restricted; 'No' otherwise. From data: 'Y' for Netherlands (CySEC) rows and other closed markets. NULL in DDL (vs NOT NULL in EXW_ReportingBalances). (Tier 4 — External ETL) |
| 38 | [User was Compensated during Country Closure] | varchar(2) | YES | 'Y' if the customer received compensation through EXW_CompensationClosingCountries during a country closure event; 'No' otherwise. NULL in DDL. (Tier 4 — External ETL) |
| 39 | [Staking Units] | decimal(38,18) | YES | Crypto units held in staking products during the reporting month. NULL when staking not applicable for this crypto/customer. High precision (18 decimals). (Tier 4 — External ETL) |
| 40 | [Staking USD] | decimal(38,6) | YES | [Staking Units] converted to USD. NULL when staking not applicable. (Tier 4 — External ETL) |
| 41 | [UpdateDate] | datetime | NO | Timestamp when this row was loaded by the external ETL. NOT NULL. All rows in Sep-2023 snapshot have UpdateDate = 2023-10-15 09:55:24. (Tier 4 — External ETL) |
| 42 | [IsValidCustomer] | int | YES | Customer validity flag (1 = valid, 0 = invalid) at time of reporting. From eToro CRM. 1 for all sampled rows. Not present in EXW_ReportingBalances. (Tier 4 — External ETL) |
| 43 | [VerificationLevelID] | int | YES | KYC verification tier ID at time of reporting. From eToro CRM. Values observed: 3 (from data). Not present in EXW_ReportingBalances. (Tier 4 — External ETL) |
| 44 | [PlayerLevelID] | int | YES | Customer club tier ID at time of reporting (FK to DWH_dbo.Dim_PlayerLevel). Values observed: 1 (Bronze), 3 (Gold). Not present in EXW_ReportingBalances. (Tier 4 — External ETL) |

---

## 5. Lineage

### 5.1 Production Sources

All columns sourced via external ETL not in SSDT. Inferred sources from column semantics:

| Column Group | Likely Source |
|-------------|---------------|
| GCID, CID, WalletIdentifier, PublicWalletAddress | WalletDB.Wallets |
| LTD/MTD/Closing balances | WalletBalancesReportDB (same engine as EXW_FinanceReportsBalancesNew) |
| TrackerBalance | Third-party: BitGo or Blox |
| Country, Regulation, IsValidCustomer | eToro CRM / Fact_SnapshotCustomer |
| UserWalletAllowance | EXW_UserSettingsWalletAllowance |
| Closed Country / Compensation flags | EXW_CompensationClosingCountries |
| Staking columns | ETH staking / staking service tables |
| VerificationLevelID, PlayerLevelID | eToro CRM |

### 5.2 ETL Pipeline

```
WalletDB.Wallets + WalletBalancesReportDB + eToro CRM (external — not SSDT)
  |-- Monthly end-of-month ETL batch ---|
  v
EXW_dbo.EXW_EOMReportingBalances
  (25.4M rows, Nov-2021 through Sep-2023 — DECOMMISSIONED)
  |-- UC Target: _Not_Migrated ---|
  Successor: EXW_dbo.EXW_ReportingBalances (empty successor schema)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| [eToro Unique ID 1 GCID] | EXW_dbo.EXW_DimUser | Implicit | Customer identity |
| [UserWalletAllowance] | EXW_dbo.EXW_UserSettingsWalletAllowance | Implicit | Allowance status source |
| [Closed Country AND Regulation] | EXW_dbo.EXW_CompensationClosingCountries | Implicit | Country closure tracking |
| [PlayerLevelID] | DWH_dbo.Dim_PlayerLevel | Implicit | Club tier lookup |

### 6.2 Referenced By

No downstream consumers found in SSDT. Used directly for regulatory reporting extracts.

---

## 7. Sample Queries

### Monthly regulatory balance report for CySEC (Sep-2023)

```sql
SELECT
    [eToro Unique ID 1 GCID],
    [eToro Unique ID 2 CID],
    [eToro Wallet Identifier],
    [Public Wallet Address],
    [Cryptoasset],
    [Opening Balance as of the 1st of Designated Month],
    [Closing Units Balance],
    [Reporting Balance],
    [Reporting Balance USD],
    [Country]
FROM [EXW_dbo].[EXW_EOMReportingBalances]
WHERE [ReportingDate] = '2023-09-30'
  AND [Regulation] = 'CySEC'
  AND [Reporting Balance] > 0
ORDER BY [eToro Unique ID 1 GCID];
```

### Monthly total balance by regulation (all months)

```sql
SELECT
    [ReportingDate],
    [Regulation],
    COUNT(DISTINCT [eToro Unique ID 1 GCID]) AS customer_count,
    SUM([Reporting Balance USD]) AS total_reporting_balance_usd
FROM [EXW_dbo].[EXW_EOMReportingBalances]
GROUP BY [ReportingDate], [Regulation]
ORDER BY [ReportingDate], total_reporting_balance_usd DESC;
```

### Known-issue wallet reconciliation check

```sql
SELECT
    [eToro Unique ID 1 GCID],
    [Cryptoasset],
    [Closing Units Balance],
    [DevReportBalance For 'KnownIssueWallets'],
    [DevReportBalanceUSD For 'KnownIssueWallets'],
    [TrackerBalance],
    [Has Dif with TrackerBalance],
    [Gap in USD -Estimation]
FROM [EXW_dbo].[EXW_EOMReportingBalances]
WHERE [KnownIssueWallet] = 1
  AND [ReportingDate] = '2023-09-30'
ORDER BY ABS([Gap in USD -Estimation]) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This table is a regulatory reporting artifact — documentation may exist in finance/compliance team SharePoint.

---

*Generated: 2026-04-20 | Quality: 7.8/10 | Phases: 9/14 (P5 N/A, P6 inferred, P9/9B no SP)*
*Tiers: 0 T1, 0 T2, 0 T3, 44 T4, 0 T5 | Elements: 44/44 | Decommissioned Sep-2023*
*Object: EXW_dbo.EXW_EOMReportingBalances | Type: Table | Production Source: External ETL (not in SSDT)*
