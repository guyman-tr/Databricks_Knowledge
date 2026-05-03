# eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050

> 1.5B-row daily account snapshot landing table from FiatDwhDB (prod-banking) capturing eMoney account balances, statuses, and holder metadata per work date. Loaded via Generic Pipeline (Append, daily) since 2022-04-11. Read by SP_eMoney_Reconciliation_ETLs to feed eMoney_dbo.ETL_AccountSnapshot.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 (prod-banking) |
| **Refresh** | Daily (1440 min), Append strategy via Generic Pipeline |
| **Synapse Distribution** | HASH(`@Id`) |
| **Synapse Index** | Clustered Index on `@Id` ASC; NCI on `partition_date` ASC |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

This table is a raw daily snapshot of eMoney account states from the FiatDwhDB production database on the prod-banking server. Each row represents one account's state on a given work date, capturing balances (available, settled, reserved), account status lifecycle, currency, holder country, and program membership.

The table contains ~1.52 billion rows spanning 2022-04-11 to 2026-04-26, growing daily via the Generic Pipeline with an Append copy strategy. All business columns are stored as `varchar(max)` — this is characteristic of a raw "Tribe" landing table where type casting has not been applied at the landing layer.

SP_eMoney_Reconciliation_ETLs reads this table, JOINs it with the parent header table `AccountsSnapshots-509416` on `@Id` and LEFT JOINs `AccountsSnapshots_BankAccounts-795870` for bank account details, then INSERTs the combined result into `eMoney_dbo.ETL_AccountSnapshot`.

Account statuses observed: A (Active, ~91%), S (Suspended, ~7%), B (Blocked, ~0.7%), P (Pending, ~0.3%), R (Restricted, <0.1%). Currencies are ISO 4217 numeric codes: 978 (EUR, ~67%), 826 (GBP, ~31%), 036 (AUD, ~1.6%), 208 (DKK, <0.1%).

---

## 2. Business Logic

### 2.1 Account Status Lifecycle

**What**: Each account carries a status code and full status-change audit trail.
**Columns Involved**: AccountStatus, AccountStatusDescription, AccountStatusChangeDate, AccountStatusChangeSource, AccountStatusChangeReasonCode, AccountStatusChangeNote, AccountStatusChangeOriginatorId
**Rules**:
- AccountStatus is a single-character code: A=Active, S=Suspended, B=Blocked, P=Pending, R=Restricted
- AccountStatusDescription provides the human-readable label (e.g. "Active")
- Status change columns (Date, Source, ReasonCode, Note, OriginatorId) form a complete audit record of the most recent status transition
- Many status change fields are empty/NULL for accounts that have never changed status

### 2.2 Balance Tracking

**What**: Three balance measures capture the financial state of each account at snapshot time.
**Columns Involved**: AvailableBalance, SettledBalance, ReservedBalance
**Rules**:
- AvailableBalance represents funds the holder can use immediately
- SettledBalance represents funds that have been cleared/settled
- ReservedBalance represents funds held back (typically 0.00 in sample data)
- All stored as varchar(max) strings in the landing layer (e.g. "34.56", "0.00")

### 2.3 Currency and Country Identification

**What**: ISO numeric codes identify the account currency and holder country.
**Columns Involved**: CurrencyIson, HolderCountryIson
**Rules**:
- CurrencyIson uses ISO 4217 numeric codes: 978=EUR, 826=GBP, 036=AUD, 208=DKK
- HolderCountryIson uses ISO 3166 numeric codes: 826=United Kingdom, 276=Germany, 250=France, 380=Italy, 724=Spain, etc.
- The same code 826 appears in both columns (GBP currency vs United Kingdom country)

### 2.4 Daily Snapshot Grain

**What**: Each row is a single account's snapshot on a specific work date.
**Columns Involved**: WorkDate, @WorkDate, FileDate, partition_date
**Rules**:
- WorkDate (varchar) and @WorkDate (datetime2) represent the same business date in different formats
- FileDate matches WorkDate and identifies the source file date
- partition_date aligns with the snapshot date for efficient date-range queries

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is HASH-distributed on `@Id` (GUID) and clustered on `@Id`. This optimizes single-record lookups and JOINs with sibling Tribe tables (AccountsSnapshots-509416, AccountsSnapshots_BankAccounts-795870) that share the same `@Id` distribution key.

A non-clustered index on `partition_date` supports efficient date-range filtering, which is critical given the 1.5B row count.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Account status distribution on a given date | `WHERE partition_date = '2026-04-01' GROUP BY AccountStatus` |
| Balance for a specific account over time | `WHERE AccountId = '...' ORDER BY partition_date` |
| Accounts by country and currency | `WHERE partition_date = '...' GROUP BY HolderCountryIson, CurrencyIson` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Tribe.AccountsSnapshots-509416 | `@Id = @Id` | Parent snapshot header (used by SP_eMoney_Reconciliation_ETLs) |
| eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 | `@Id = @Id` | Bank account details enrichment |
| eMoney_dbo.ETL_AccountSnapshot | Downstream | Reconciliation target table |

### 3.4 Gotchas

- **All business columns are varchar(max)**: Balances, dates, and IDs are strings. CAST/CONVERT before arithmetic or date comparisons.
- **1.5B rows**: Always filter by `partition_date` to avoid full scans. Never run unfiltered `COUNT(*)` or `GROUP BY`.
- **Status change audit fields are mostly empty**: For accounts that have never changed status, all `AccountStatusChange*` columns are empty strings, not NULL.
- **@Id is a GUID**: Not a sequential integer. Equality joins only; range scans on @Id are meaningless.
- **etr_y/etr_ym/etr_ymd are mostly empty**: In sample data these ETL partition columns are unpopulated for many rows.
- **CurrencyIson vs HolderCountryIson both use 826**: 826 = GBP (currency) and 826 = United Kingdom (country). Context matters.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP code with transform logic |
| Tier 3 | Grounded in DDL, data sample, and SP usage — no upstream wiki available |
| Tier 4 | Inferred from column name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | Generic Pipeline record creation timestamp. Indicates when this row was ingested into Synapse. (Tier 2 — Generic Pipeline) |
| 2 | @Id | varchar(255) | YES | Generic Pipeline unique record identifier (GUID). Distribution key and clustered index. Links to sibling Tribe tables (AccountsSnapshots-509416, AccountsSnapshots_BankAccounts-795870). (Tier 2 — Generic Pipeline) |
| 3 | @AccountsSnapshots@Id-509416 | varchar(max) | YES | Generic Pipeline parent reference linking this account snapshot row to its parent record in AccountsSnapshots-509416. Observed to equal @Id in sample data. (Tier 2 — Generic Pipeline) |
| 4 | FileDate | varchar(max) | YES | Source file date string from FiatDwhDB. Matches WorkDate in sample data (e.g. "2024-01-27"). Identifies which daily export file this row originated from. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 5 | WorkDate | varchar(max) | YES | Business work date as a string (e.g. "2024-01-27 00:00:00"). Represents the snapshot date for this account record. Passed through to ETL_AccountSnapshot by SP_eMoney_Reconciliation_ETLs as @WorkDate. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 6 | @WorkDate | datetime2(7) | YES | Typed datetime2 representation of WorkDate. Used by SP_eMoney_Reconciliation_ETLs as the canonical work date for downstream processing. (Tier 2 — Generic Pipeline) |
| 7 | AccountId | varchar(max) | YES | eMoney account identifier (numeric string, e.g. "7219741"). Uniquely identifies the account within the eMoney system. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 8 | HolderId | varchar(max) | YES | Account holder identifier (numeric string, e.g. "6358891"). Identifies the person or entity that owns the account. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 9 | ProgramId | varchar(max) | YES | eMoney program identifier (numeric string). Observed values include 175, 39, 177 in sample data. Identifies the eMoney program the account belongs to. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 10 | CurrencyIson | varchar(max) | YES | ISO 4217 numeric currency code for the account (e.g. "978"=EUR, "826"=GBP, "036"=AUD, "208"=DKK). 4 distinct values observed. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 11 | AvailableBalance | varchar(max) | YES | Available account balance as a decimal string (e.g. "34.56", "0.00"). Represents funds immediately available to the account holder at snapshot time. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 12 | SettledBalance | varchar(max) | YES | Settled account balance as a decimal string. Represents cleared/settled funds in the account at snapshot time. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 13 | AccountStatus | varchar(max) | YES | Account status single-character code. A=Active, S=Suspended, B=Blocked, P=Pending, R=Restricted. 5 distinct values observed. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 14 | AccountStatusDescription | varchar(max) | YES | Human-readable account status label (e.g. "Active"). Corresponds to AccountStatus code. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 15 | AccountStatusChangeDate | varchar(max) | YES | Date/time of the most recent account status change as a string. Empty for accounts that have not undergone a status transition. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 16 | AccountStatusChangeSource | varchar(max) | YES | Source system or actor that initiated the most recent status change. Empty for accounts with no status change history. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 17 | AccountStatusChangeReasonCode | varchar(max) | YES | Reason code for the most recent account status change. Empty for accounts with no status change history. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 18 | AccountStatusChangeNote | varchar(max) | YES | Free-text note accompanying the most recent status change. Empty for most rows in sample data. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 19 | AccountStatusChangeOriginatorId | varchar(max) | YES | Identifier of the user or system that originated the most recent status change. Empty for accounts with no status change history. Passed through to ETL_AccountSnapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 20 | DateUpdated | varchar(max) | YES | Last update timestamp for the account record in the source system (e.g. "2024-01-02 11:39:23"). Aliased as AccountDateTimeUpdated and AccountDateUpdated by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 21 | DateCreated | varchar(max) | YES | Account creation timestamp in the source system (e.g. "2024-01-02 11:39:23"). Aliased as AccountDateTimeCreated and AccountDateCreated by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 22 | BankAccounts | varchar(max) | YES | Bank accounts associated with this eMoney account. Empty in all sample rows; bank account details are stored separately in AccountsSnapshots_BankAccounts-795870 and joined via @Id. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 23 | ReservedBalance | varchar(max) | YES | Reserved balance as a decimal string (e.g. "0.00"). Represents funds held or reserved in the account. Observed as "0.00" in all sample rows. Passed through to ETL_AccountSnapshot (not directly — enriched via bank account join). (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 24 | HolderCountryIson | varchar(max) | YES | ISO 3166 numeric country code for the account holder (e.g. "826"=United Kingdom, "276"=Germany, "250"=France, "380"=Italy). 20+ distinct values observed. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050, no upstream wiki) |
| 25 | etr_y | varchar(max) | YES | ETL partition year string. Part of the Generic Pipeline's date partitioning scheme. Mostly empty in sample data. (Tier 2 — Generic Pipeline) |
| 26 | etr_ym | varchar(max) | YES | ETL partition year-month string. Part of the Generic Pipeline's date partitioning scheme. Mostly empty in sample data. (Tier 2 — Generic Pipeline) |
| 27 | etr_ymd | varchar(max) | YES | ETL partition year-month-day string. Part of the Generic Pipeline's date partitioning scheme. Mostly empty in sample data. (Tier 2 — Generic Pipeline) |
| 28 | SynapseUpdateDate | datetime | YES | Timestamp when the row was last loaded or updated in Synapse by the Generic Pipeline (e.g. "2024-01-27 07:09:58.123"). (Tier 2 — Generic Pipeline) |
| 29 | partition_date | date | YES | Synapse partition date for this row, aligned with the snapshot work date. Indexed (NCI) for efficient date-range filtering on this 1.5B-row table. (Tier 2 — Generic Pipeline) |
| 30 | Created | datetime2(7) | YES | Typed datetime2 copy of @Created. Pipeline record creation timestamp with microsecond precision. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| AccountId | FiatDwhDB.Tribe | AccountId | Passthrough (varchar) |
| HolderId | FiatDwhDB.Tribe | HolderId | Passthrough (varchar) |
| ProgramId | FiatDwhDB.Tribe | ProgramId | Passthrough (varchar) |
| CurrencyIson | FiatDwhDB.Tribe | CurrencyIson | Passthrough (varchar) |
| AvailableBalance | FiatDwhDB.Tribe | AvailableBalance | Passthrough (varchar) |
| SettledBalance | FiatDwhDB.Tribe | SettledBalance | Passthrough (varchar) |
| AccountStatus | FiatDwhDB.Tribe | AccountStatus | Passthrough (varchar) |
| AccountStatusDescription | FiatDwhDB.Tribe | AccountStatusDescription | Passthrough (varchar) |
| AccountStatusChange* | FiatDwhDB.Tribe | AccountStatusChange* | Passthrough (varchar), 5 columns |
| DateUpdated | FiatDwhDB.Tribe | DateUpdated | Passthrough (varchar) |
| DateCreated | FiatDwhDB.Tribe | DateCreated | Passthrough (varchar) |
| BankAccounts | FiatDwhDB.Tribe | BankAccounts | Passthrough (varchar) |
| ReservedBalance | FiatDwhDB.Tribe | ReservedBalance | Passthrough (varchar) |
| HolderCountryIson | FiatDwhDB.Tribe | HolderCountryIson | Passthrough (varchar) |
| @Created, @Id, @WorkDate | Generic Pipeline | — | Pipeline-injected metadata |
| etr_y, etr_ym, etr_ymd | Generic Pipeline | — | ETL date partition columns |
| SynapseUpdateDate, partition_date | Generic Pipeline | — | Synapse load/partition timestamps |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.AccountsSnapshots_AccountSnapshot-956050 (prod-banking)
  |-- Generic Pipeline (Append, daily, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/AccountsSnapshots_AccountSnapshot-956050/ (Data Lake)
  |-- Generic Pipeline (Bronze landing) ---|
  v
eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050 (1.5B rows, Synapse)
  |-- SP_eMoney_Reconciliation_ETLs (JOIN with AccountsSnapshots-509416 + BankAccounts-795870) ---|
  v
eMoney_dbo.ETL_AccountSnapshot (Synapse)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
emoney.bronze_fiatdwhdb_tribe_accountssnapshots_accountsnapshot-956050 (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| @Id | eMoney_Tribe.AccountsSnapshots-509416 | Parent snapshot header via @Id JOIN |
| @Id | eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 | Bank account details via @Id LEFT JOIN |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| @Id | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Reads all business columns into ETL_AccountSnapshot |
| (all) | DE_dbo.NewSBUpdateStatsBigTables | Statistics maintenance |

---

## 7. Sample Queries

### 7.1 Account Status Distribution by Date

```sql
SELECT partition_date,
       AccountStatus,
       COUNT_BIG(*) AS cnt
FROM [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050]
WHERE partition_date = '2026-04-01'
GROUP BY partition_date, AccountStatus
ORDER BY cnt DESC;
```

### 7.2 Balance Summary by Currency for a Given Date

```sql
SELECT CurrencyIson,
       COUNT_BIG(*) AS account_count,
       SUM(CAST(AvailableBalance AS DECIMAL(18,2))) AS total_available,
       SUM(CAST(SettledBalance AS DECIMAL(18,2))) AS total_settled
FROM [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050]
WHERE partition_date = '2026-04-01'
GROUP BY CurrencyIson
ORDER BY account_count DESC;
```

### 7.3 Account History for a Specific Account

```sql
SELECT partition_date,
       AccountStatus,
       AvailableBalance,
       SettledBalance,
       ReservedBalance
FROM [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050]
WHERE AccountId = '7219741'
ORDER BY partition_date;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 13/14*
*Tiers: 0 T1, 10 T2, 20 T3, 0 T4, 0 T5 | Elements: 30/30, Logic: 7/10, Lineage: 7/10*
*Object: eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking, Generic Pipeline)*
