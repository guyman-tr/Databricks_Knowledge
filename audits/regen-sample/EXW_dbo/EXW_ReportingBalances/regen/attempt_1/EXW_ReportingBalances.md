# EXW_dbo.EXW_ReportingBalances

> Dormant (0-row) crypto wallet reporting balances table tracking per-customer, per-cryptoasset monthly balance snapshots including opening/closing balances, MTD unit flows, tracker reconciliation, staking positions, and country-closure compensation flags. No production source identified — not referenced by any Synapse SP or generic pipeline mapping. Sibling table EXW_EOMReportingBalances shares an identical column structure with additional verification columns.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — no writer SP, not in generic pipeline mapping |
| **Refresh** | Unknown — no ETL pipeline identified; table is empty |
| **Synapse Distribution** | HASH([eToro Unique ID 1 GCID]) |
| **Synapse Index** | CLUSTERED INDEX([ReportingDate] ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | None |
| **UC Table Type** | — |

---

## 1. Business Meaning

EXW_ReportingBalances is a crypto-wallet reporting table designed to hold monthly balance snapshots for eToro customers' crypto holdings. The table is currently **empty (0 rows)** and appears to be dormant — no stored procedures write to it, it is not registered in the generic pipeline mapping, and it has no entry in the dependency order graph.

The column structure indicates the table was designed to track:
- **Customer identification**: GCID (Global Customer ID), CID, wallet identifiers, and public wallet addresses.
- **Monthly balance lifecycle**: Opening balance at month start, closing balance, and the reporting balance (potentially adjusted).
- **Unit flow tracking**: Life-to-date (LTD) and month-to-date (MTD) units sent and received per cryptoasset.
- **Reconciliation**: Tracker balance comparison with difference flags, gap estimation in USD.
- **Known-issue wallets**: Separate balance columns for wallets flagged as problematic, with a KnownIssueWallet flag.
- **Regulatory context**: Country, regulation, country-closure status, and whether the user was compensated during a country closure.
- **Staking**: Staking units and their USD value.

A sibling table `EXW_EOMReportingBalances` shares nearly identical columns (with 3 additional: IsValidCustomer, VerificationLevelID, PlayerLevelID) and uses a HEAP instead of a clustered index, suggesting the EOM variant may be the actively used version.

---

## 2. Business Logic

### 2.1 Balance Lifecycle (Monthly Snapshot)

**What**: Each row represents one customer-wallet-cryptoasset combination for a given reporting month.
**Columns Involved**: ReportingDate, Opening Balance as of the 1st of Designated Month, Closing Units Balance, Closing Balance USD, Reporting Balance, Reporting Balance USD, Prior Month Closing Balance Date, Closing Balance Date.
**Rules**:
- Opening balance is the balance at the 1st of the designated month.
- Closing balance captures the final position at month end in both units and USD.
- Reporting Balance / Reporting Balance USD may differ from closing balance (possibly after adjustments for known-issue wallets).

### 2.2 Unit Flow Tracking (LTD and MTD)

**What**: Tracks cumulative and monthly unit movements per wallet-cryptoasset.
**Columns Involved**: LTD Units Recieved, LTD Units Sent, MTD Units Sent, MTD Units Recieved, MTD Units Total, MTD Balance Change.
**Rules**:
- LTD = life-to-date cumulative totals.
- MTD = month-to-date totals for the reporting period.
- MTD Units Total = MTD Units Sent + MTD Units Recieved (net flow).
- MTD Balance Change tracks the monetary impact of unit flows.

### 2.3 Reconciliation with Tracker

**What**: Compares the reported balance against an independent tracker balance to identify discrepancies.
**Columns Involved**: TrackerBalance, TrackerBalanceUSD, Has Dif with TrackerBalance, Dif with TrackerBalance, MTD Balance Change -MTD Units Total Flag, MTD Balance Change -MTD Units Total, Gap in USD -Estimation.
**Rules**:
- Has Dif with TrackerBalance is a varchar(1) flag (likely Y/N).
- Dif with TrackerBalance stores the numeric difference when a discrepancy exists.
- Gap in USD -Estimation converts the discrepancy to USD.
- MTD Balance Change -MTD Units Total Flag flags when the MTD balance change does not match the MTD unit total.

### 2.4 Known-Issue Wallet Handling

**What**: Separates balance reporting for wallets flagged as problematic.
**Columns Involved**: KnownIssueWallet, DevReportBalance For 'KnownIssueWallets', DevReportBalanceUSD For 'KnownIssueWallets', DevReportBalancesTime.
**Rules**:
- KnownIssueWallet is an int flag (NOT NULL, default significance unknown).
- Dev-prefixed columns store alternative balance calculations for flagged wallets.
- DevReportBalancesTime records when the dev report balance was computed.

### 2.5 Country Closure and Compensation

**What**: Tracks regulatory status and compensation for customers in closed countries.
**Columns Involved**: Country, Regulation, Closed Country AND Regulation, User was Compensated during Country Closure.
**Rules**:
- Closed Country AND Regulation is a varchar(2) NOT NULL field (likely Y/N or similar two-char code).
- User was Compensated during Country Closure is also varchar(2) NOT NULL.
- These columns support regulatory reporting for jurisdictions where eToro ceased operations.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH([eToro Unique ID 1 GCID]) — queries filtering or joining on GCID will have optimal data locality.
- **Clustered Index**: [ReportingDate] ASC — range scans on ReportingDate are efficient.
- **Note**: Table is currently empty; distribution and index are relevant only if the table is repopulated.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly balance for a specific customer | `WHERE [eToro Unique ID 1 GCID] = @gcid AND ReportingDate = @date` |
| All cryptoasset balances for a reporting period | `WHERE ReportingDate = @date GROUP BY Cryptoasset` |
| Wallets with tracker discrepancies | `WHERE [Has Dif with TrackerBalance] = 'Y'` |
| Known-issue wallet balances | `WHERE KnownIssueWallet = 1` |
| Country closure impact | `WHERE [Closed Country AND Regulation] <> 'No'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_EOMReportingBalances | ON GCID + ReportingDate + Wallet | Compare monthly vs EOM snapshots |

### 3.4 Gotchas

- **Table is empty**: 0 rows as of 2026-04-27. May be deprecated in favor of EXW_EOMReportingBalances.
- **Typo in column name**: "LTD Units Recieved" and "MTD Units Recieved" — misspelling of "Received" is in the DDL and must be used as-is in queries.
- **Leading space in column name**: `[ Closing Balance Date]` has a leading space — must include the space when referencing: `[ Closing Balance Date]`.
- **Embedded quotes in column names**: `[DevReportBalance For 'KnownIssueWallets']` contains single quotes — use bracket notation in queries.
- **NOT NULL on flag columns**: KnownIssueWallet (int), Closed Country AND Regulation (varchar(2)), and User was Compensated during Country Closure (varchar(2)) are NOT NULL — no need for NULL checks on these.
- **No writer SP**: Unlike most EXW tables, this table has no SP loader. Data origin is unknown.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP / ETL code |
| Tier 3 | Grounded in DDL + domain context, no upstream wiki or SP code available |
| Tier 4 | Inferred from name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportingDate | date | NO | Reporting period date for the balance snapshot. Used as the clustered index — each row represents one month's data for a customer-wallet-cryptoasset combination. (Tier 3 — DDL, no upstream) |
| 2 | eToro Unique ID 1 GCID | bigint | NO | Global Customer ID (GCID). Primary customer identifier in the eToro platform. Distribution key for this table. (Tier 3 — DDL, no upstream) |
| 3 | eToro Unique ID 2 CID | bigint | NO | Customer ID (CID). Secondary customer identifier in the eToro platform. (Tier 3 — DDL, no upstream) |
| 4 | eToro Wallet Identifier | uniqueidentifier | YES | Internal eToro wallet GUID identifying the specific crypto wallet for this customer. (Tier 3 — DDL, no upstream) |
| 5 | Public Wallet Address | nvarchar(100) | YES | Blockchain public wallet address associated with the eToro wallet. Used for on-chain reconciliation. (Tier 3 — DDL, no upstream) |
| 6 | Cryptoasset | nvarchar(256) | YES | Name or symbol of the cryptoasset held in this wallet (e.g., BTC, ETH). (Tier 3 — DDL, no upstream) |
| 7 | Opening Balance as of the 1st of Designated Month | numeric(38,8) | YES | Crypto unit balance at the start of the reporting month. Serves as the baseline for MTD calculations. (Tier 3 — DDL, no upstream) |
| 8 | Prior Month Closing Balance Date | datetime | YES | Date of the previous month's closing balance snapshot. Used to verify continuity between reporting periods. (Tier 3 — DDL, no upstream) |
| 9 | LTD Units Recieved | numeric(38,8) | YES | Life-to-date cumulative crypto units received into this wallet. Note: column name contains a typo ("Recieved" instead of "Received"). (Tier 3 — DDL, no upstream) |
| 10 | LTD Units Sent | numeric(38,8) | YES | Life-to-date cumulative crypto units sent from this wallet. (Tier 3 — DDL, no upstream) |
| 11 | Closing Units Balance | numeric(38,8) | YES | Crypto unit balance at the end of the reporting period. (Tier 3 — DDL, no upstream) |
| 12 | Closing Balance USD | numeric(38,8) | YES | USD value of the closing crypto unit balance, converted at the applicable exchange rate. (Tier 3 — DDL, no upstream) |
| 13 | Reporting Balance | numeric(38,8) | YES | Adjusted crypto unit balance used for regulatory reporting. May differ from closing balance due to known-issue wallet adjustments. (Tier 3 — DDL, no upstream) |
| 14 | Reporting Balance USD | numeric(38,6) | YES | USD value of the reporting balance, converted at the applicable exchange rate. (Tier 3 — DDL, no upstream) |
| 15 | DevReportBalancesTime | datetime2(7) | YES | Timestamp when the dev report balance was computed for known-issue wallet analysis. (Tier 3 — DDL, no upstream) |
| 16 | DevReportBalance For 'KnownIssueWallets' | decimal(20,8) | YES | Alternative crypto unit balance calculated specifically for wallets flagged as known-issue. Used in dev/reconciliation reporting. (Tier 3 — DDL, no upstream) |
| 17 | DevReportBalanceUSD For 'KnownIssueWallets' | decimal(38,6) | YES | USD value of the dev report balance for known-issue wallets. (Tier 3 — DDL, no upstream) |
| 18 |  Closing Balance Date | datetime | YES | Date of the closing balance snapshot for this reporting period. Note: column name has a leading space in the DDL. (Tier 3 — DDL, no upstream) |
| 19 | Country | varchar(100) | YES | Country of the customer's registration or regulatory jurisdiction. (Tier 3 — DDL, no upstream) |
| 20 | Regulation | varchar(100) | YES | Regulatory entity or framework under which the customer operates (e.g., FCA, CySEC, ASIC). (Tier 3 — DDL, no upstream) |
| 21 | Test accounting classifier | bigint | YES | Classifier flag used to identify test or internal accounting entries. Non-NULL values likely indicate test accounts. (Tier 3 — DDL, no upstream) |
| 22 | MTD Units Sent | numeric(38,8) | YES | Month-to-date crypto units sent from this wallet during the reporting period. (Tier 3 — DDL, no upstream) |
| 23 | MTD Units Recieved | numeric(38,8) | YES | Month-to-date crypto units received into this wallet during the reporting period. Note: column name contains a typo ("Recieved" instead of "Received"). (Tier 3 — DDL, no upstream) |
| 24 | MTD Units Total | numeric(38,8) | YES | Net month-to-date unit movement (sent + received) for the reporting period. (Tier 3 — DDL, no upstream) |
| 25 | MTD Balance Change | numeric(38,8) | YES | Month-to-date change in crypto unit balance, accounting for both unit flows and value adjustments. (Tier 3 — DDL, no upstream) |
| 26 | MTD Balance Change -MTD Units Total Flag | varchar(1) | YES | Flag indicating whether the MTD balance change differs from the MTD units total. Likely Y/N. Used to highlight reconciliation discrepancies within the month. (Tier 3 — DDL, no upstream) |
| 27 | MTD Balance Change -MTD Units Total | numeric(38,8) | YES | Numeric difference between MTD Balance Change and MTD Units Total. Non-zero values indicate unexplained balance movements beyond unit transfers. (Tier 3 — DDL, no upstream) |
| 28 | Gap in USD -Estimation | numeric(38,6) | YES | Estimated USD gap between expected and actual balance. Used for reconciliation and discrepancy reporting. (Tier 3 — DDL, no upstream) |
| 29 | TrackerBalance | numeric(38,8) | YES | Independent tracker system's crypto unit balance for this wallet. Used as a reference for reconciliation against the reported balance. (Tier 3 — DDL, no upstream) |
| 30 | TrackerBalanceUSD | numeric(38,8) | YES | USD value of the tracker balance, converted at the applicable exchange rate. (Tier 3 — DDL, no upstream) |
| 31 | Has Dif with TrackerBalance | varchar(1) | YES | Flag (Y/N) indicating whether the reported balance differs from the tracker balance. (Tier 3 — DDL, no upstream) |
| 32 | Dif with TrackerBalance | numeric(38,8) | YES | Numeric difference between the reported crypto unit balance and the tracker balance. Non-zero when Has Dif with TrackerBalance = 'Y'. (Tier 3 — DDL, no upstream) |
| 33 | KnownIssueWallet | int | NO | Flag identifying wallets with known issues (e.g., stuck transactions, reconciliation problems). NOT NULL — 0 likely indicates no known issues. (Tier 3 — DDL, no upstream) |
| 34 | Most Recent Occured Date | datetime | YES | Date of the most recent transaction or event for this wallet-cryptoasset combination. Note: column name contains a typo ("Occured" instead of "Occurred"). (Tier 3 — DDL, no upstream) |
| 35 | UserWalletAllowance | nchar(50) | YES | Wallet allowance status or classification for the user. Semantics unclear — possibly indicates withdrawal limits or wallet tier. (Tier 3 — DDL, no upstream) |
| 36 | Closed Country AND Regulation | varchar(2) | NO | Flag indicating whether the customer's country and regulation combination has been closed (eToro ceased operations). NOT NULL — likely 'Y'/'N' or similar two-char code. (Tier 3 — DDL, no upstream) |
| 37 | User was Compensated during Country Closure | varchar(2) | NO | Flag indicating whether the customer received compensation when eToro exited their country/regulation. NOT NULL — likely 'Y'/'N' or similar two-char code. (Tier 3 — DDL, no upstream) |
| 38 | Staking Units | decimal(38,18) | YES | Crypto units currently staked by the customer. High precision (18 decimals) to accommodate fractional staking amounts. (Tier 3 — DDL, no upstream) |
| 39 | Staking USD | decimal(38,6) | YES | USD value of the staked crypto units. (Tier 3 — DDL, no upstream) |
| 40 | UpdateDate | datetime | YES | Timestamp of the last update to this row. (Tier 3 — DDL, no upstream) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Unknown | — | No SP or generic pipeline mapping found. Table is dormant. |

### 5.2 ETL Pipeline

```
Unknown external source (possibly SSIS, Excel import, or ad-hoc script)
  |-- Direct INSERT (no Synapse SP identified) ---|
  v
EXW_dbo.EXW_ReportingBalances (0 rows, dormant)
  |-- No UC migration ---|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| eToro Unique ID 1 GCID | Customer dimension (unresolved) | GCID likely maps to a customer dimension table |
| eToro Unique ID 2 CID | Customer dimension (unresolved) | CID likely maps to a customer dimension table |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|-------------------|---------|-------------|
| EXW_EOMReportingBalances | (structural sibling) | Shares nearly identical column structure; likely the EOM-snapshot variant of this table |

---

## 7. Sample Queries

### 7.1 Monthly Balance Summary by Cryptoasset

```sql
SELECT
    ReportingDate,
    Cryptoasset,
    COUNT(*) AS wallet_count,
    SUM([Closing Units Balance]) AS total_units,
    SUM([Closing Balance USD]) AS total_usd
FROM [EXW_dbo].[EXW_ReportingBalances]
GROUP BY ReportingDate, Cryptoasset
ORDER BY ReportingDate DESC, total_usd DESC
```

### 7.2 Wallets with Tracker Discrepancies

```sql
SELECT
    [eToro Unique ID 1 GCID],
    Cryptoasset,
    [Closing Units Balance],
    TrackerBalance,
    [Dif with TrackerBalance],
    [Gap in USD -Estimation]
FROM [EXW_dbo].[EXW_ReportingBalances]
WHERE [Has Dif with TrackerBalance] = 'Y'
ORDER BY ABS([Gap in USD -Estimation]) DESC
```

### 7.3 Country Closure Impact

```sql
SELECT
    Country,
    Regulation,
    COUNT(*) AS affected_wallets,
    SUM(CASE WHEN [User was Compensated during Country Closure] <> 'No' THEN 1 ELSE 0 END) AS compensated,
    SUM([Reporting Balance USD]) AS total_reporting_usd
FROM [EXW_dbo].[EXW_ReportingBalances]
WHERE [Closed Country AND Regulation] <> 'No'
GROUP BY Country, Regulation
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object.

---

*Generated: 2026-04-27 | Quality: 5.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 40 T3, 0 T4, 0 T5 | Elements: 40/40, Logic: 5/10, Lineage: 2/10*
*Object: EXW_dbo.EXW_ReportingBalances | Type: Table | Production Source: Unknown (dormant)*
