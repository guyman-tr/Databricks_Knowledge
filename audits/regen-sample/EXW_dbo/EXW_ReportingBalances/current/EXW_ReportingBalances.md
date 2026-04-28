# EXW_dbo.EXW_ReportingBalances

> Monthly end-of-month regulatory balance snapshot schema for eToro Wallet — 40-column table modeling per-customer, per-crypto-asset, per-month regulatory balances (LTD/MTD units, reporting balance vs tracker balance, country/regulation context). **Currently empty (0 rows as of 2026-04-20).** The schema is the streamlined successor to EXW_EOMReportingBalances (decommissioned Sep-2023) — drops the 4 debug/demographic columns (ReportingDateID, IsValidCustomer, VerificationLevelID, PlayerLevelID) and tightens constraints on compliance columns. No SSDT writer SP — loaded via external ETL not tracked in the SSDT repo.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Monthly Regulatory Balance Snapshot) |
| **Production Source** | External ETL (Python/ADF — not tracked in SSDT repo) |
| **Writer SP** | None found in SSDT |
| **Refresh** | Unknown — no SP orchestration found |
| **Row Count** | 0 (empty as of 2026-04-20) |
| **Date Range** | None — never populated |
| **Synapse Distribution** | HASH([eToro Unique ID 1 GCID]) |
| **Synapse Index** | CLUSTERED INDEX([ReportingDate] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_ReportingBalances is a monthly regulatory balance reporting schema for eToro Wallet. Each row is intended to represent one customer's crypto holdings for a given month-end date, providing regulators (CySEC, FCA, FinCEN, ASIC, etc.) with a complete view of the customer's wallet position including:

- **Opening and closing balances** for the reporting month (in crypto units and USD)
- **Life-to-date (LTD) and month-to-date (MTD)** units received and sent
- **Regulatory reporting balance** — the balance reported to regulators (may differ from raw blockchain balance due to known-issue wallet adjustments)
- **Reconciliation diagnostics** — TrackerBalance comparison, KnownIssueWallet flags, Gap in USD estimation
- **Customer context** — Country, Regulation, UserWalletAllowance, compensation status

**Relationship to EXW_EOMReportingBalances**: This table is the slimmed schema successor to EXW_EOMReportingBalances. It drops 4 columns (`ReportingDateID`, `IsValidCustomer`, `VerificationLevelID`, `PlayerLevelID`) and changes several column nullabilities (stricter constraints on compliance/flag columns). The assumption is that EXW_ReportingBalances was prepared as a successor but was never populated — either the reporting pipeline was discontinued, or data was migrated to a different system entirely.

**Grain** (intended): One row per (ReportingDate × GCID × WalletID × Cryptoasset).

**Important**: As of 2026-04-20, this table contains 0 rows. All documentation below is inferred from the DDL structure and data patterns from EXW_EOMReportingBalances (identical schema minus 4 columns). See `EXW_EOMReportingBalances.md` for the populated historical version.

---

## 2. Business Logic

### 2.1 Balance Hierarchy: Opening → MTD Activity → Closing → Reporting

**What**: The table tracks the full balance lifecycle within a month through a chain of calculated fields.

**Columns Involved**: `[Opening Balance...]`, `[LTD Units Recieved]`, `[LTD Units Sent]`, `[Closing Units Balance]`, `[Reporting Balance]`, `[MTD Units Sent]`, `[MTD Units Recieved]`

**Rules** (inferred from EXW_EOMReportingBalances data):
- `[Opening Balance as of the 1st of Designated Month]` = prior month's Closing Units Balance
- `[LTD Units Recieved]` - `[LTD Units Sent]` should approximately equal `[Closing Units Balance]`
- `[MTD Units Total]` = `[MTD Units Recieved]` - `[MTD Units Sent]` (may differ due to staking)
- `[Reporting Balance]` = adjusted version of `[Closing Units Balance]` for known-issue wallets

### 2.2 TrackerBalance Reconciliation

**What**: `[TrackerBalance]` compares the eToro-computed closing balance against a third-party tracker (likely BitGo or Blox, same pattern as EXW_FinanceReportsBalancesNew). Discrepancies are flagged.

**Columns Involved**: `[TrackerBalance]`, `[TrackerBalanceUSD]`, `[Has Dif with TrackerBalance]`, `[Dif with TrackerBalance]`

**Rules**:
- `[Has Dif with TrackerBalance]` = 'Y' if `[TrackerBalance]` ≠ `[Closing Units Balance]`, 'N' otherwise
- `[Dif with TrackerBalance]` = `[TrackerBalance]` - `[Closing Units Balance]`
- `[KnownIssueWallet]` = 1 flags wallets with persistent reconciliation discrepancies

### 2.3 MTD vs Closing Balance Consistency Check

**What**: The `[MTD Balance Change -MTD Units Total Flag]` column flags inconsistencies between the MTD flow and the balance delta.

**Columns Involved**: `[MTD Balance Change]`, `[MTD Balance Change -MTD Units Total Flag]`, `[MTD Balance Change -MTD Units Total]`

**Rules**:
- If MTD balance change does NOT equal MTD units net flow → Flag = 'Y'
- `[MTD Balance Change -MTD Units Total]` = numeric difference between the two values

### 2.4 Compliance Flags

**What**: Country-closure and compensation status for regulatory compliance reporting.

**Columns Involved**: `[Closed Country AND Regulation]`, `[User was Compensated during Country Closure]`, `[UserWalletAllowance]`

**Rules** (both columns are NOT NULL in this schema vs NULL in EXW_EOMReportingBalances):
- `[Closed Country AND Regulation]` = 'Y' if customer's country + regulation combination is closed/restricted
- `[User was Compensated during Country Closure]` = 'Y' if user received compensation during country closure
- `[UserWalletAllowance]` = 'Allowed' or 'NotAllowed' (plus trailing spaces to 50 chars)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH distributed on `[eToro Unique ID 1 GCID]` (bigint). CLUSTERED INDEX on `[ReportingDate]` ASC. Queries filtering on `[ReportingDate]` benefit from index elimination.

### 3.2 Common Query Patterns (Intended)

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Month-end balance for specific GCID | Filter `[eToro Unique ID 1 GCID]` AND `[ReportingDate]` |
| All customers with known-issue wallets | Filter `[KnownIssueWallet] = 1` |
| Regulatory breakdown by month | GROUP BY `[ReportingDate]`, `[Regulation]` |
| Compensation status by country | Filter `[Closed Country AND Regulation] = 'Y'` |

### 3.3 Common JOINs (Intended)

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_EOMReportingBalances | GCID + Cryptoasset + ReportingDate | Historical EOM data for pre-Oct-2023 months |

### 3.4 Gotchas

- **0 rows**: Table is empty — do not use in production queries until populated
- **Leading space in column name**: `[ Closing Balance Date]` has a leading space — requires `[ Closing Balance Date]` (note the space inside brackets)
- **DDL typos**: `[LTD Units Recieved]` and `[MTD Units Recieved]` — note the missing 'n' (same typo as EXW_EOMReportingBalances)
- **Nullability change from EOM**: `[KnownIssueWallet]` is NOT NULL here (was NULL in EOM), as are compliance flags; `[UpdateDate]` is NULL here (was NOT NULL in EOM)
- **UserWalletAllowance padding**: nchar(50) pads values with trailing spaces — trim before comparison
- **Space-in-name columns**: Almost all columns require `[bracket]` quoting

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
| 1 | ReportingDate | date | NO | The month-end reporting date (always the last day of the reporting month, e.g., 2023-09-30). CLUSTERED INDEX key. NOT NULL — the primary partition key. (Tier 4 — External ETL) |
| 2 | [eToro Unique ID 1 GCID] | bigint | NO | Global Customer ID. Primary customer identifier. HASH distribution key. NOT NULL. (Tier 4 — External ETL) |
| 3 | [eToro Unique ID 2 CID] | bigint | NO | Legacy CID (eToro trading platform Customer ID). Second identifier for cross-system joins. NOT NULL. (Tier 4 — External ETL) |
| 4 | [eToro Wallet Identifier] | uniqueidentifier | YES | WalletID — UUID identifying the specific wallet address record in WalletDB.Wallets. Maps to the PublicWalletAddress. NULL when not yet assigned. (Tier 4 — External ETL) |
| 5 | [Public Wallet Address] | nvarchar(100) | YES | Blockchain address for this wallet (BTC: base58, ETH: 0x hex, XRP: with optional ?dt= destination tag, etc.). NULL when not assigned. (Tier 4 — External ETL) |
| 6 | [Cryptoasset] | nvarchar(256) | YES | Display name of the crypto asset (BTC, ETH, XRP, ADA, DOGE, etc.). Determines the denomination of all balance columns. (Tier 4 — External ETL) |
| 7 | [Opening Balance as of the 1st of Designated Month] | numeric(38,8) | YES | Crypto units held at the start of the reporting month (= prior month's closing balance). Basis for MTD change calculations. (Tier 4 — External ETL) |
| 8 | [Prior Month Closing Balance Date] | datetime | YES | The exact date-time of the prior month's closing snapshot. Connects this month's opening to the previous month's record. (Tier 4 — External ETL) |
| 9 | [LTD Units Recieved] | numeric(38,8) | YES | Lifetime-to-date total crypto units received across all time. DDL typo: "Recieved" instead of "Received" (same typo as EXW_EOMReportingBalances). (Tier 4 — External ETL) |
| 10 | [LTD Units Sent] | numeric(38,8) | YES | Lifetime-to-date total crypto units sent across all time. LTD Received − LTD Sent should approximate Closing Units Balance. (Tier 4 — External ETL) |
| 11 | [Closing Units Balance] | numeric(38,8) | YES | Closing crypto balance at month-end in native crypto units. The raw blockchain or ledger balance before any reporting adjustments. (Tier 4 — External ETL) |
| 12 | [Closing Balance USD] | numeric(38,8) | YES | Closing balance converted to USD using the month-end crypto price. (Tier 4 — External ETL) |
| 13 | [Reporting Balance] | numeric(38,8) | YES | The official regulatory reporting balance — may differ from [Closing Units Balance] for KnownIssueWallets where a corrected balance is used. (Tier 4 — External ETL) |
| 14 | [Reporting Balance USD] | numeric(38,6) | YES | [Reporting Balance] converted to USD. This is the value submitted to regulators. (Tier 4 — External ETL) |
| 15 | [DevReportBalancesTime] | datetime2(7) | YES | Developer diagnostic timestamp recording when the balance calculation engine ran. Not a business field. (Tier 4 — External ETL) |
| 16 | [DevReportBalance For 'KnownIssueWallets'] | decimal(20,8) | YES | Developer diagnostic: the corrected balance value applied to wallets flagged as KnownIssueWallet=1. Traces the source of any [Reporting Balance] vs [Closing Units Balance] discrepancy. (Tier 4 — External ETL) |
| 17 | [DevReportBalanceUSD For 'KnownIssueWallets'] | decimal(38,6) | YES | USD value of [DevReportBalance For 'KnownIssueWallets']. Developer diagnostic field. (Tier 4 — External ETL) |
| 18 | [ Closing Balance Date] | datetime | YES | Date-time of the closing balance event. Note: column name has a leading space — must be queried as `[ Closing Balance Date]`. (Tier 4 — External ETL) |
| 19 | [Country] | varchar(100) | YES | Customer's country of residence at time of reporting. Determines applicable regulatory framework alongside [Regulation]. (Tier 4 — External ETL) |
| 20 | [Regulation] | varchar(100) | YES | Customer's regulatory jurisdiction (CySEC, FCA, FinCEN, ASIC & GAML, BVI, eToroUS, etc.). Determines which regulator this balance is reported to. (Tier 4 — External ETL) |
| 21 | [Test accounting classifier] | bigint | YES | Internal accounting classification flag (0=production, non-zero=test accounting category). Used to exclude test accounts from regulatory submissions. (Tier 4 — External ETL) |
| 22 | [MTD Units Sent] | numeric(38,8) | YES | Month-to-date crypto units sent during the reporting month. (Tier 4 — External ETL) |
| 23 | [MTD Units Recieved] | numeric(38,8) | YES | Month-to-date crypto units received during the reporting month. DDL typo: "Recieved". (Tier 4 — External ETL) |
| 24 | [MTD Units Total] | numeric(38,8) | YES | Net MTD units: [MTD Units Recieved] - [MTD Units Sent]. Represents net crypto flow for the month. (Tier 4 — External ETL) |
| 25 | [MTD Balance Change] | numeric(38,8) | YES | Actual change in balance over the month: [Closing Units Balance] - [Opening Balance...]. May differ from [MTD Units Total] due to staking or corrections. (Tier 4 — External ETL) |
| 26 | [MTD Balance Change -MTD Units Total Flag] | varchar(1) | YES | Consistency flag. NULL if [MTD Balance Change] equals [MTD Units Total]; otherwise 'Y' (inconsistency detected). NULL in this schema (vs NOT NULL in EXW_EOMReportingBalances). (Tier 4 — External ETL) |
| 27 | [MTD Balance Change -MTD Units Total] | numeric(38,8) | YES | Numeric difference: [MTD Balance Change] minus [MTD Units Total]. Non-zero values warrant investigation. (Tier 4 — External ETL) |
| 28 | [Gap in USD -Estimation] | numeric(38,6) | YES | Estimated USD gap between [Reporting Balance USD] and [TrackerBalanceUSD]. Helps quantify reconciliation discrepancies in financial terms. (Tier 4 — External ETL) |
| 29 | [TrackerBalance] | numeric(38,8) | YES | Balance from a third-party tracking provider (likely BitGo or Blox, same as EXW_FinanceReportsBalancesNew). Used for independent cross-validation. (Tier 4 — External ETL) |
| 30 | [TrackerBalanceUSD] | numeric(38,8) | YES | [TrackerBalance] converted to USD. (Tier 4 — External ETL) |
| 31 | [Has Dif with TrackerBalance] | varchar(1) | YES | 'Y' if [Closing Units Balance] differs from [TrackerBalance]; 'N' otherwise. NULL in this schema (vs NOT NULL in EXW_EOMReportingBalances). (Tier 4 — External ETL) |
| 32 | [Dif with TrackerBalance] | numeric(38,8) | YES | Numeric difference: [TrackerBalance] minus [Closing Units Balance]. Positive = tracker shows more than ledger. (Tier 4 — External ETL) |
| 33 | [KnownIssueWallet] | int | NO | Flag (0/1) indicating this wallet has a known reconciliation issue requiring corrective balance adjustment. NOT NULL. 1 = known-issue wallet; [DevReportBalance...] columns hold the corrected value. (Tier 4 — External ETL) |
| 34 | [Most Recent Occured Date] | datetime | YES | Timestamp of the most recent transaction recorded for this wallet-crypto combination. (Tier 4 — External ETL) |
| 35 | [UserWalletAllowance] | nchar(50) | YES | Wallet allowance status from EXW_UserSettingsWalletAllowance. Values: 'Allowed' or 'NotAllowed' (padded to 50 chars with spaces). (Tier 4 — External ETL) |
| 36 | [Closed Country AND Regulation] | varchar(2) | NO | 'Y' if the customer's regulatory jurisdiction was closed/restricted during this period; 'No' otherwise. NOT NULL. (Tier 4 — External ETL) |
| 37 | [User was Compensated during Country Closure] | varchar(2) | NO | 'Y' if the customer received compensation through EXW_CompensationClosingCountries during a country closure; 'No' otherwise. NOT NULL. (Tier 4 — External ETL) |
| 38 | [Staking Units] | decimal(38,18) | YES | Crypto units held in staking during the reporting month. NULL when staking not applicable for this crypto/customer. (Tier 4 — External ETL) |
| 39 | [Staking USD] | decimal(38,6) | YES | [Staking Units] converted to USD. NULL when staking not applicable. (Tier 4 — External ETL) |
| 40 | [UpdateDate] | datetime | YES | ETL load timestamp for this row. NULL in this schema (vs NOT NULL in EXW_EOMReportingBalances). (Tier 4 — External ETL) |

---

## 5. Lineage

### 5.1 Production Sources

All columns sourced via external ETL not tracked in SSDT. Likely sources (inferred from column semantics and EXW_EOMReportingBalances patterns):

| Column Group | Likely Source |
|-------------|---------------|
| GCID, CID, WalletIdentifier, PublicWalletAddress | WalletDB.Wallets / EXW_WalletInventory |
| LTD/MTD balances, Closing balance | WalletBalancesReportDB or equivalent |
| TrackerBalance | Third-party: BitGo or Blox |
| Country, Regulation | eToro CRM / Fact_SnapshotCustomer |
| UserWalletAllowance | EXW_UserSettingsWalletAllowance |
| Compensation flag | EXW_CompensationClosingCountries |
| Staking | Staking service tables |

### 5.2 ETL Pipeline

```
[External reporting ETL — Python/ADF, not in SSDT]
  Likely sources: WalletDB + WalletBalancesReportDB + eToro CRM
  |-- Monthly EOM batch ---|
  v
EXW_dbo.EXW_ReportingBalances (EMPTY — 0 rows as of 2026-04-20)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| [eToro Unique ID 1 GCID] | EXW_dbo.EXW_DimUser | Implicit | Customer identity; GCID is the primary join key |
| [UserWalletAllowance] | EXW_dbo.EXW_UserSettingsWalletAllowance | Implicit | Allowance status source |
| [Closed Country AND Regulation] + [User was Compensated...] | EXW_dbo.EXW_CompensationClosingCountries | Implicit | Country closure/compensation flags |

### 6.2 Referenced By

No downstream consumers found in SSDT. Intended as an ad-hoc regulatory reporting extract.

---

## 7. Sample Queries

### Schema exploration (empty table — structure only)

```sql
-- Confirm schema and distribution
SELECT TOP 0 * FROM [EXW_dbo].[EXW_ReportingBalances];
```

### Query historical data from predecessor table

```sql
-- Use EXW_EOMReportingBalances for all pre-Oct-2023 months
SELECT 
    [ReportingDate],
    [eToro Unique ID 1 GCID],
    [Cryptoasset],
    [Closing Units Balance],
    [Reporting Balance USD],
    [Regulation]
FROM [EXW_dbo].[EXW_EOMReportingBalances]
WHERE [ReportingDate] = '2023-09-30'
  AND [Regulation] = 'CySEC'
ORDER BY [eToro Unique ID 1 GCID];
```

### KnownIssueWallet analysis (for when populated)

```sql
SELECT
    [Cryptoasset],
    [Closing Units Balance],
    [DevReportBalance For 'KnownIssueWallets'],
    [DevReportBalanceUSD For 'KnownIssueWallets'],
    [Has Dif with TrackerBalance],
    [Dif with TrackerBalance]
FROM [EXW_dbo].[EXW_ReportingBalances]
WHERE [KnownIssueWallet] = 1;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. Table appears to be a regulatory reporting artifact — documentation may exist in finance/compliance team SharePoint rather than developer Confluence.

---

*Generated: 2026-04-20 | Quality: 7.5/10 | Phases: 9/14 (P5 N/A, P6 inferred, P9/9B no SP)*
*Tiers: 0 T1, 0 T2, 0 T3, 40 T4, 0 T5 | Elements: 40/40 | Empty table — all Tier 4*
*Object: EXW_dbo.EXW_ReportingBalances | Type: Table | Production Source: External ETL (not in SSDT)*
