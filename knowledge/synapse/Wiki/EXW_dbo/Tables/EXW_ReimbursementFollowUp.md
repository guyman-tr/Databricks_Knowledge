# EXW_dbo.EXW_ReimbursementFollowUp

> Reimbursement tracking table — one row per GCID × CryptoId × compensation-project for all wallet users whose crypto was subject to a country-closure or AML compensation event and had a non-zero balance. Each row cross-references the compensation snapshot (balance/rate at time of closure) against the current user state (current balance/rate/regulation/country), enabling finance and compliance teams to monitor outstanding balances, reconcile platform-side payments, and identify users requiring further action.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.EXW_CompensationClosingCountries + DWH dimension tables + EXW balance/transaction tables |
| **Writer SP** | EXW_dbo.SP_EXW_CompensationClosingCountries |
| **Refresh** | On-demand — same SP run that refreshes EXW_CompensationClosingCountries (no date param); TRUNCATE + INSERT |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only compliance tracking table |

---

## 1. Business Meaning

EXW_ReimbursementFollowUp is the primary operational tracking table for the eToro Wallet reimbursement program. It stores one row per GCID × CryptoId combination for every user who appears in EXW_CompensationClosingCountries with a non-zero compensation balance. Each row captures a complete snapshot of the compensation event alongside the user's current state, enabling finance and compliance teams to:

- Track whether compensated users have since changed country or regulation
- Monitor residual wallet balances after the compensation date
- Reconcile platform-side credits (Fact_CustomerAction) against wallet-side reimbursement records
- Identify users where the wallet balance differs from what was compensated
- Track actual crypto extractions (withdrawals) post-compensation

The table is rebuilt on every on-demand SP run by TRUNCATE + INSERT, meaning it reflects the state as of the most recent run — it is not time-series data. The same SP also populates EXW_ReimbursementSumTable (7-population summary counts) after writing this table.

---

## 2. Business Logic

### 2.1 Row Selection Filter

**What**: Not all rows from EXW_CompensationClosingCountries appear here — only those with a non-zero compensation balance.

**Columns Involved**: [Reimbursement Coin Balance]

**Rules**:
- INSERT filter: `WHERE [Reimbursement Coin Balance] <> 0`
- Users with zero-balance compensation entries (e.g., AML cases where the platform credited full amount with nothing left in the wallet) are excluded
- The GCID set is the UNION of `#platformdata` (Fact_CustomerAction CompensationReasonID 101/102) and `EXW_CompensationClosingCountries` (all projects)

### 2.2 Current State vs. Compensation Snapshot

**What**: The table pairs the historical compensation snapshot with the current user profile, allowing change detection.

**Columns Involved**: [Reimbursement Country] vs [Current Country], ReimbursementCountryID vs CurrentCountryID, [Reimbursement Regulation] vs CurrentRegulation, ReimbursementRegulationID vs CurrentRegulationID, [Reimbursement Coin Balance] vs [Current Coin Balance]

**Rules**:
- `[Country Changed]` = 'True' if `CurrentCountryID <> ReimbursementCountryID`
- `[Regulation Changed]` = 'True' if `CurrentRegulationID <> ReimbursementRegulationID`
- `[Amount Change]` = 'True' if `ISNULL([Reimbursement Coin Balance], 0) <> ISNULL([Current Coin Balance], 0)`
- `[Any Change]` = 'True' if any of the above three change flags is True
- `[Non Zero Wallet]` = 'True' if `[Current Coin Balance] > 0 OR [Reimbursement Coin Balance] > 0`
- Current balance sourced from EXW_FinanceReportsBalancesNew at @d = MAX(BalanceDate)

### 2.3 Platform vs. Wallet Reconciliation

**What**: The table enables reconciliation between platform-side compensation credits and wallet-side reimbursement amounts.

**Columns Involved**: PlatformUSDCompensationPerGCID, WalletDataUSDReimbursementPerGCID, WalletVsPlatform

**Rules**:
- `PlatformUSDCompensationPerGCID` = SUM of Fact_CustomerAction.Amount WHERE ActionTypeID=36 AND CompensationReasonID IN (101, 102) AND Occurred≥'2022-05-01', per GCID
- `WalletDataUSDReimbursementPerGCID` = SUM([Reimbursement USD Balance]) per GCID across all CryptoIds
- `WalletVsPlatform` classification:
  - 'No Gap' — platform and wallet amounts match within $1
  - 'Wallet Above Platform Record for Reason 101,102' — wallet total > platform credits by >$1
  - 'Only Platform' — platform record exists but no EXW_CompensationClosingCountries entry
  - 'Only Wallet Side' — EXW_CompensationClosingCountries entry exists but no Fact_CustomerAction credit
  - 'Dups' — row is a duplicate (Rn > 1 from ROW_NUMBER over GCID × CryptoId × CompensationDate)
  - 'No Gap' also returned when both platform and wallet amounts are zero
  - 'ToCheck' — default catch-all for unresolved discrepancies

### 2.4 Extraction Tracking

**What**: Post-compensation crypto withdrawals are tracked to identify users who extracted funds after the compensation event.

**Columns Involved**: TotalExtractedUnitsPerCrypto, TotalExtractedUSDPerCrypto, LastExtractionDatePerCrypto

**Rules**:
- Source: EXW_FactTransactions WHERE TransactionTypeID=13 (extraction) AND TranStatusID=2 (completed) AND TranDate>'2024-01-18'
- Aggregated per GCID × CryptoId
- Cut-off date 2024-01-18 is hardcoded in the SP — extractions before this date are not included
- NULL if no qualifying extraction found for that GCID × CryptoId

### 2.5 Balance Rate Context

**What**: Two USD valuations are computed for the current coin balance — one at the original reimbursement rate and one at the current market rate.

**Columns Involved**: [Current USD Balance by Reimbursement Rate], [Current USD Balance by Current Rate], [Reimbursement Rate], CurrentUSDRate, DateForCurrentBalanceRate

**Rules**:
- `[Current USD Balance by Reimbursement Rate]` = ISNULL([Current Coin Balance], 0) × [Reimbursement Rate]
- `[Current USD Balance by Current Rate]` = ISNULL([Current Coin Balance], 0) × CurrentUSDRate
- `CurrentUSDRate` = EXW_PriceDaily.AvgPrice for the CryptoID at @d_i
- `DateForCurrentBalanceRate` = @d scalar variable = MAX(BalanceDate) from EXW_FinanceReportsBalancesNew
- Both valuations use ISNULL([Current Coin Balance], 0), so zero for users with no current balance record

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) — co-located with EXW_CompensationClosingCountries (also HASH(GCID)), EXW_DimUser (HASH(GCID)), EXW_FactBalance (HASH(GCID)). HEAP — full table scans when querying by Project or CryptoId; always add a GCID filter when possible.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All users with an outstanding gap | `WHERE WalletVsPlatform = 'ToCheck'` |
| Users whose regulation changed since compensation | `WHERE [Regulation Changed] = 'True'` |
| Users with non-zero current balance | `WHERE [Non Zero Wallet] = 'True'` |
| AML users only | `WHERE Project IN ('AML', 'AML_US', 'AML_EEA')` |
| Legacy country-closure users only | `WHERE Project NOT LIKE 'AML%'` |
| Total current USD value by crypto | `SELECT CryptoName, SUM([Current USD Balance by Current Rate]) ... GROUP BY CryptoName` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_CompensationClosingCountries | GCID = GCID AND CryptoId = CryptoId | Expand with full compensation event history |
| EXW_dbo.EXW_DimUser | GCID = GCID | Additional user attributes not in this table |
| EXW_dbo.EXW_ReimbursementSumTable | n/a (summary table) | Population-level summary built in same SP run |

### 3.4 Gotchas

- **`[Date Rate For  Reimbursement]` has a double space**: The column name contains two consecutive spaces between "For" and "Reimbursement" — bracket-quoting is mandatory and the double space must be preserved
- **Bracket-quoting required for space-in-name columns**: 13 of the 56 columns have spaces in their names — always use `[Column Name]` syntax; ORM tools may fail silently
- **No GCID uniqueness**: Multiple rows per GCID are expected (one per CryptoId per Project). Always GROUP BY GCID for user-level counts
- **TRUNCATE + INSERT on each run**: The table is fully rebuilt on every on-demand execution. There is no row-level history; point-in-time comparisons require external snapshots
- **Extraction cutoff is hardcoded**: TotalExtracted* columns only reflect extractions since 2024-01-18 — earlier extractions are not counted
- **WalletDataUSDReimbursementPerGCID = GCID total**: This is the sum across ALL CryptoIds for that GCID, not per-crypto. Compare to PlatformUSDCompensationPerGCID (also GCID-level) for reconciliation
- **AMLStatus filter already applied upstream**: Rows where LOWER(AMLStatus) NOT IN ('compensated','reimbursed','completed') for AML* projects are excluded from EXW_CompensationClosingCountries input before this table is built (the Rn filter in #EXW_CompensationClosingCountries)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki |
| Tier 2 | Derived from SP code analysis — ETL-computed, join-derived, aggregated, or passthrough from T2 source |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NULL | Platform customer ID (RealCID). Sourced from DWH_dbo.Dim_Customer.RealCID via EXW_DimUser join at GCID. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 2 | GCID | int | NULL | Compensation event GCID from EXW_CompensationClosingCountries. Distribution key. Sourced from Google Sheets (Fivetran) compensation records. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 3 | [Reimbursement Rate] | decimal(38,8) | NULL | Exchange rate (crypto-to-USD) used at time of compensation. Passed through from EXW_CompensationClosingCountries.Rate (source: Google Sheet column `exchange_rate`). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 4 | [Date Rate For  Reimbursement] | date | NULL | Date of the exchange rate used for compensation. Double space in column name. Passed through from EXW_CompensationClosingCountries.RateDate (source: `exchange_date`). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 5 | CryptoName | varchar(50) | NULL | Human-readable name of the compensated cryptocurrency (e.g., BTC, ETH). Passed through from EXW_CompensationClosingCountries. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 6 | CryptoId | int | NULL | Cryptocurrency identifier. Passed through from EXW_CompensationClosingCountries. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 7 | [Reimbursement Coin Balance] | decimal(38,8) | NULL | Crypto balance at time of compensation in native units. Passed through from EXW_CompensationClosingCountries.FinalBalance (source: `units` from Google Sheets). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 8 | [Reimbursement USD Balance] | decimal(38,8) | NULL | USD value of the compensation: FinalBalance × Rate at RateDate. Passed through from EXW_CompensationClosingCountries.USD_FinalBalance. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 9 | WalletId | uniqueidentifier | NULL | Customer's wallet GUID for the compensated CryptoId. Passed through from EXW_CompensationClosingCountries (originally from EXW_Wallet.EXW_CustomerWalletsView.Id). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 10 | Address | varchar(540) | NULL | Blockchain address of the customer's wallet for the compensated crypto. Passed through from EXW_CompensationClosingCountries (originally from EXW_Wallet.EXW_CustomerWalletsView.Address). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 11 | [Reimbursement Country] | varchar(100) | NULL | Country name of the user at time of compensation. Passed through from EXW_CompensationClosingCountries.Country (source: `country` from Google Sheets). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 12 | ReimbursementCountryID | int | NULL | Country identifier at time of compensation. Passed through from EXW_CompensationClosingCountries.CountryID. FK to DWH_dbo.Dim_Country. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 13 | ReportFromDate | date | NULL | Start date of the balance report period used in legacy compensation calculations. NULL for all AML*, AML_US, and AML_EEA rows. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 14 | ReportId | int | NULL | Legacy balance report identifier. NULL for all AML*, AML_US, AML_EEA rows. May contain values for legacy country-closure project rows. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 15 | Project | varchar(100) | NULL | Regulatory compensation project identifier. Values: 'AML', 'AML_US', 'AML_EEA' (active; loaded by current SP); plus ~15 legacy country-closure project names (FrenchTerr, Germany_Tangany_*, Russia*, Netherlands, etc.). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 16 | CompensationDate | date | NULL | Date the compensation was calculated or recorded. Sourced from Google Sheet column `compensation_date`. Used as join key to EXW_WalletEntity for WalletEntity lookup. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 17 | [Reimbursement Regulation] | varchar(100) | NULL | Regulation name at time of compensation (e.g., CySEC, FCA, FinCEN). Passed through from EXW_CompensationClosingCountries.Regulation. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 18 | ReimbursementRegulationID | int | NULL | Regulation identifier at time of compensation. Passed through from EXW_CompensationClosingCountries.RegulationID. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 19 | AMLStatus | varchar(100) | NULL | Status of the AML enforcement action from the source Google Sheet. Only active statuses ('compensated', 'reimbursed', 'completed') are present; pending/in-progress rows are filtered at EXW_CompensationClosingCountries input stage. NULL for legacy non-AML project rows. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 20 | [Current Country] | varchar(100) | NULL | Current country name from EXW_DimUser.Country (denormalized from DWH_dbo.Dim_Country.Name). For joins, use CurrentCountryID. (Tier 2 — SP_DimUser via EXW_DimUser) |
| 21 | CurrentCountryID | int | NULL | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. DWH note: sourced from EXW_DimUser.CountryID at time of this SP run. (Tier 1 — Customer.CustomerStatic) |
| 22 | CurrentRegulation | varchar(100) | NULL | Current regulation name from EXW_DimUser.Regulation (denormalized from DWH_dbo.Dim_Regulation.Name). Use CurrentRegulationID for joins. (Tier 2 — SP_DimUser via EXW_DimUser) |
| 23 | CurrentRegulationID | int | NULL | Regulatory entity governing this account. FK to Dictionary.Regulation. Values: 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. DWH note: sourced from EXW_DimUser.RegulationID at time of this SP run. (Tier 1 — BackOffice.Customer) |
| 24 | CurrentClub | varchar(100) | NULL | Customer experience level from EXW_DimUser.Club (Dim_PlayerLevel.Name). Values: Bronze, Silver, Gold, Platinum, Diamond. NULL if no PlayerLevel match. (Tier 2 — SP_DimUser via EXW_DimUser) |
| 25 | UserRegion_State | varchar(100) | NULL | State or province from EXW_DimUser.UserRegion_State (Dim_State_and_Province.Name joined on RegionByIP_ID). Populated mainly for US, Canada, and Australia. NULL for most non-US users. (Tier 2 — SP_DimUser via EXW_DimUser) |
| 26 | IsTestAccount | int | NULL | 1 if this GCID is in EXW_TestUsers (internal test accounts), 0 otherwise. Sourced from EXW_DimUser. Always filter IsTestAccount=0 in production analytics. (Tier 2 — SP_DimUser via EXW_DimUser) |
| 27 | AccountStatusName | varchar(50) | NULL | Human-readable account status label from DWH_dbo.Dim_AccountStatus, joined on AccountStatusID. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 28 | AccountStatusID | int | NULL | Account status identifier from DWH_dbo.Dim_Customer. FK to Dim_AccountStatus. (Tier 2 — SP_EXW_CompensationClosingCountries via DWH_dbo.Dim_Customer) |
| 29 | PlayerStatusID | int | NULL | Player status identifier from DWH_dbo.Dim_Customer. FK to Dim_PlayerStatus. (Tier 2 — SP_EXW_CompensationClosingCountries via DWH_dbo.Dim_Customer) |
| 30 | PlayerStatus | varchar(50) | NULL | Player status name from DWH_dbo.Dim_PlayerStatus.Name, joined on PlayerStatusID. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 31 | PlayerStatusReason | varchar(50) | NULL | Player status reason from DWH_dbo.Dim_PlayerStatusReasons.Name, joined on PlayerStatusReasonID. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 32 | PlayerStatusSubReason | varchar(540) | NULL | Player status sub-reason from DWH_dbo.Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 33 | CurrentUSDRate | decimal(38,8) | NULL | Current AvgPrice for this CryptoID from EXW_Wallet.EXW_PriceDaily at FullDateID=@d_i (=MAX(BalanceDate) as integer YYYYMMDD). (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 34 | [Date of Current User Balance] | date | NULL | BalanceDate from EXW_FinanceReportsBalancesNew for the matching balance record (GCID × CryptoID at @d). NULL if no balance record found at @d for this GCID × CryptoId. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 35 | VerificationLevelID | int | NULL | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. DWH note: sourced from DWH_dbo.Dim_Customer via #listdc join. (Tier 1 — BackOffice.Customer) |
| 36 | UserWalletAllowance | nchar(50) | NULL | Current wallet allowance status from EXW_UserSettingsWalletAllowance.UserWalletAllowance. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 37 | UserWalletAllowanceBeginDate | datetime | NULL | Date the current wallet allowance setting took effect, from EXW_UserSettingsWalletAllowance.AllowanceBeginDate. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 38 | DateForCurrentBalanceRate | date | NULL | The @d scalar value = MAX(BalanceDate) from EXW_FinanceReportsBalancesNew. Applied uniformly to all rows — the date as of which current balance and price are computed. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 39 | [Current Coin Balance] | decimal(38,8) | NULL | Current crypto balance in native units from EXW_FinanceReportsBalancesNew.Balance at @d. ISNULL to 0 when no balance record exists. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 40 | [Current USD Balance by Reimbursement Rate] | decimal(38,8) | NULL | [Current Coin Balance] × [Reimbursement Rate]. USD value of current balance using the compensation-era exchange rate. 0 when current balance is 0 or NULL. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 41 | [Current USD Balance by Current Rate] | decimal(38,8) | NULL | [Current Coin Balance] × CurrentUSDRate. USD value of current balance using the live market rate at DateForCurrentBalanceRate. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 42 | [Regulation Changed] | varchar(5) | NULL | 'True' if CurrentRegulationID ≠ ReimbursementRegulationID; 'False' otherwise. Detects regulatory regime changes since compensation. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 43 | [Country Changed] | varchar(5) | NULL | 'True' if CurrentCountryID ≠ ReimbursementCountryID; 'False' otherwise. Detects country-of-residence changes since compensation. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 44 | [Amount Change] | varchar(5) | NULL | 'True' if ISNULL([Reimbursement Coin Balance],0) ≠ ISNULL([Current Coin Balance],0); 'False' otherwise. Detects balance changes since compensation. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 45 | [Any Change] | varchar(5) | NULL | 'True' if any of [Regulation Changed], [Country Changed], or [Amount Change] is 'True'; 'False' otherwise. Top-level change indicator. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 46 | [Non Zero Wallet] | varchar(5) | NULL | 'True' if [Current Coin Balance] > 0 OR [Reimbursement Coin Balance] > 0; 'False' otherwise. Identifies users with any wallet balance in scope. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 47 | UpdateDate | datetime | NOT NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the last SP run that rebuilt this table. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 48 | PlatformUSDCompensationPerGCID | decimal(38,8) | NULL | Total platform compensation credits (USD) for this GCID: SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=36, CompensationReasonID IN (101, 102), Occurred≥'2022-05-01'. GCID-level total (not per-crypto). ISNULL to 0. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 49 | WalletDataUSDReimbursementPerGCID | decimal(38,8) | NULL | Total wallet-side USD reimbursement for this GCID: SUM([Reimbursement USD Balance]) across all CryptoIds from EXW_CompensationClosingCountries. GCID-level total. ISNULL to 0. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 50 | WalletVsPlatform | varchar(100) | NULL | Reconciliation status: 'No Gap' / 'Wallet Above Platform Record for Reason 101,102' / 'Only Platform' / 'Only Wallet Side' / 'Dups' / 'ToCheck'. See Section 2.3 for full classification rules. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 51 | MaxPlatformCreditDate | date | NULL | Most recent platform credit date for this GCID: MAX(Occurred) from Fact_CustomerAction, same filter as PlatformUSDCompensationPerGCID. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 52 | TotalExtractedUnitsPerCrypto | decimal(38,8) | NULL | Total crypto units extracted (withdrawn) post-compensation: SUM(EXW_FactTransactions.Amount) WHERE TransactionTypeID=13, TranStatusID=2, TranDate>'2024-01-18', per GCID × CryptoId. NULL if no extraction found. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 53 | TotalExtractedUSDPerCrypto | decimal(38,8) | NULL | Total USD value of extractions: SUM(EXW_FactTransactions.AmountUSD), same filter and grouping as TotalExtractedUnitsPerCrypto. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 54 | LastExtractionDatePerCrypto | date | NULL | Date of the most recent completed extraction: MAX(TranDate), same filter. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 55 | LastWalletEntity | varchar(250) | NULL | WalletEntity at the most recent Date in EXW_WalletEntity for this GCID. Reflects the wallet entity as of the latest known snapshot. (Tier 2 — SP_EXW_CompensationClosingCountries) |
| 56 | WalletEntity | varchar(250) | NULL | WalletEntity from EXW_WalletEntity at CompensationDate for this GCID. Reflects the wallet entity at the time of compensation. (Tier 2 — SP_EXW_CompensationClosingCountries) |

---

## 5. Lineage

See [EXW_ReimbursementFollowUp.lineage.md](EXW_ReimbursementFollowUp.lineage.md) for full column-level lineage.

### Key ETL Sources

| Source | Role |
|--------|------|
| EXW_dbo.EXW_CompensationClosingCountries | Primary input — 19 columns passed through unchanged |
| DWH_dbo.Fact_CustomerAction | Platform compensation credits (ActionTypeID=36) |
| EXW_dbo.EXW_DimUser | Current user profile (country, regulation, club, state) |
| EXW_dbo.EXW_FinanceReportsBalancesNew | Current balance at @d |
| EXW_Wallet.EXW_PriceDaily | Current crypto price at @d |
| EXW_dbo.EXW_FactTransactions | Post-compensation extraction activity |
| EXW_dbo.EXW_WalletEntity | Wallet entity at CompensationDate and most recent date |

---

## 6. Data Quality Notes

- **[Reimbursement Coin Balance] ≠ 0 filter**: Zero-balance compensation rows from EXW_CompensationClosingCountries are excluded from this table
- **GCID-level vs. GCID×CryptoId**: PlatformUSDCompensationPerGCID and WalletDataUSDReimbursementPerGCID are GCID-level totals — the same value appears on every row for a given GCID regardless of CryptoId
- **Legacy project rows**: Country-closure projects (FrenchTerr, Germany, Russia, etc.) are static historical records in EXW_CompensationClosingCountries; they are not refreshed by the current SP
- **Extraction cutoff 2024-01-18**: Hardcoded in SP. Any extraction before this date is not captured in TotalExtracted* columns

---

## 7. Open Questions / Review Needed

See [EXW_ReimbursementFollowUp.review-needed.md](EXW_ReimbursementFollowUp.review-needed.md).

---

## 8. Tier Footer

| Tier | Count | Columns |
|---|---|---|
| Tier 1 | 3 | CurrentCountryID, CurrentRegulationID, VerificationLevelID |
| Tier 2 | 53 | All remaining 53 columns — SP-derived, computed, aggregated, or passthrough from T2 sources |
