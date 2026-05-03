# eMoney_Tribe.AccountsSnapshots_BankAccount-393561

> ~1.6B-row raw Tribe export table storing individual bank account details within eMoney account snapshots, spanning 2023-12-20 to 2026-04-26. Sourced from `FiatDwhDB.Tribe` on `prod-banking` via Generic Pipeline #552 (daily append). Consumed by `SP_eMoney_Reconciliation_ETLs` to build the `ETL_AccountSnapshot` reconciliation table. Contains PII (account names, numbers, IBANs).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 (prod-banking) via Generic Pipeline #552 |
| **Refresh** | Daily (1440 min), Append strategy |
| **Synapse Distribution** | HASH(@Id) |
| **Synapse Index** | CLUSTERED INDEX (@Id ASC), NCI XI_partition_date (partition_date ASC) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (raw Tribe data) |

---

## 1. Business Meaning

This table is a child entity within the eMoney Tribe data hierarchy for account snapshots. Each row represents a bank account record associated with an account snapshot from the eToro Money (eMoney) banking platform, exported daily from the Tribe card management system.

The hierarchy is:
- `AccountsSnapshots-509416` (root file-level record)
- `AccountsSnapshots_AccountSnapshot-956050` (account snapshot details)
- `AccountsSnapshots_BankAccounts-795870` (bank accounts container)
- **`AccountsSnapshots_BankAccount-393561`** (this table — individual bank account details)

The table contains ~1.6B rows from 2023-12-20 to present, loaded daily via Generic Pipeline #552 (Append strategy) from `prod-banking.FiatDwhDB.Tribe`. The high row count reflects daily snapshots accumulating over time — each snapshot date captures the full state of all bank accounts.

`SP_eMoney_Reconciliation_ETLs` reads this table (LEFT JOIN on `@Id`) to enrich account snapshots with bank account details (ID, status, IBAN, BIC, sort code, account number, provider, EPM method) before inserting into `eMoney_dbo.ETL_AccountSnapshot`.

Bank account statuses observed: A (Active, ~90%), B (Blocked, ~10%), S (Suspended, <0.01%).

---

## 2. Business Logic

### 2.1 Bank Account Status Lifecycle

**What**: Each bank account carries a status reflecting its current operational state.
**Columns Involved**: BankAccountStatus, BankAccountStatusChangeReasonCode, BankAccountStatusChangeNote, BankAccountStatusChangeSource
**Rules**:
- `A` = Active — account is operational
- `B` = Blocked — account is blocked (regulatory, fraud, or compliance hold)
- `S` = Suspended — account is suspended (rare, <0.01% of records)
- Status change metadata (reason code, note, source) is largely unpopulated in recent data

### 2.2 Snapshot-Level Record Identity

**What**: Each record is uniquely identified by `@Id` and linked to the parent bank accounts container.
**Columns Involved**: @Id, @AccountsSnapshots_BankAccounts@Id-795870
**Rules**:
- `@Id` is a GUID serving as the primary key and distribution key
- `@AccountsSnapshots_BankAccounts@Id-795870` is an FK to the parent `AccountsSnapshots_BankAccounts-795870` table
- When `@Id` equals `@AccountsSnapshots_BankAccounts@Id-795870`, this is the primary bank account for the snapshot; when different, it is an additional bank account under the same snapshot

### 2.3 Bank Provider Identification

**What**: Bank accounts are associated with external banking providers.
**Columns Involved**: BankAccountBankProviderId, BankAccountExternalId
**Rules**:
- `BankAccountBankProviderId` identifies the banking provider (observed values: 3, 4 in sample data)
- `BankAccountExternalId` is the provider's external reference for the account
- Provider 3 appears associated with UK accounts (MRMI BIC prefix), provider 4 with Malta accounts (CFTE BIC prefix)

### 2.4 ETR Partition Fields

**What**: Tribe export includes date-based partition fields for data lake organization.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date
**Rules**:
- `etr_y`, `etr_ym`, `etr_ymd` are string-based year/year-month/year-month-day values from the Tribe export
- These fields are frequently NULL in recent data — `partition_date` (date type) is the reliable partition key
- `partition_date` has a dedicated non-clustered index (`XI_partition_date`)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(`@Id`) — queries filtering or joining on `@Id` avoid data movement
- **Clustered Index**: `@Id` ASC — efficient point lookups and range scans on the primary key
- **Non-Clustered Index**: `XI_partition_date` on `partition_date` — supports date-range filtering

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many active bank accounts on a given date? | `WHERE partition_date = '2026-04-01' AND BankAccountStatus = 'A'` |
| Find a specific bank account by IBAN | `WHERE BankAccountIban = '...' AND partition_date = (SELECT MAX(partition_date) FROM ...)` |
| Track status changes over time | Filter by `BankAccountId` and order by `partition_date` |
| Count accounts by provider | `GROUP BY BankAccountBankProviderId WHERE partition_date = '...'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 | `@AccountsSnapshots_BankAccounts@Id-795870` = parent.`@Id` | Link to parent bank accounts container |
| eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050 | Via parent chain through BankAccounts-795870 | Link to account snapshot details (HolderId, AccountId) |
| eMoney_dbo.ETL_AccountSnapshot | Downstream — this table feeds ETL_AccountSnapshot via SP | Reconciliation output |

### 3.4 Gotchas

- **Massive table (~1.6B rows)**: Always filter by `partition_date` to avoid full scans. Never run unfiltered `COUNT(*)` or `GROUP BY`.
- **PII columns**: `BankAccountAccountName`, `BankAccountAccountNumber`, `BankAccountIban`, `BankAccountBic`, `BankAccountSortCode` contain sensitive banking PII. Data is masked in some environments.
- **etr_* fields often NULL**: Do not rely on `etr_y`/`etr_ym`/`etr_ymd` for filtering — use `partition_date` instead.
- **Snapshot accumulation**: Row count grows daily. Each `partition_date` captures the full bank account state, not just changes.
- **BankAccountBankStateBranch and BankAccountBankBranchCode**: Appear to be sparsely populated (all NULL in sampled data).
- **varchar(max) for most columns**: Even numeric-looking fields like `BankAccountId` and `BankAccountBankProviderId` are stored as `varchar(max)`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP code with transform |
| Tier 3 | Inferred from DDL, data samples, and SP usage context — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(255) | YES | Unique record identifier (GUID). Primary key and HASH distribution key. Used as the join key to parent table `AccountsSnapshots_BankAccounts-795870` in `SP_eMoney_Reconciliation_ETLs`. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 2 | @AccountsSnapshots_BankAccounts@Id-795870 | varchar(max) | YES | Foreign key to the parent `AccountsSnapshots_BankAccounts-795870` table. Links this individual bank account record to its parent bank accounts container within the account snapshot hierarchy. When equal to `@Id`, this is the primary bank account for the snapshot. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 3 | BankAccountId | varchar(max) | YES | Internal bank account identifier within the Tribe platform. Numeric string (e.g., 748414, 2501173). (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 4 | BankAccountExternalId | varchar(max) | YES | External reference identifier for the bank account from the banking provider. Long numeric string. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 5 | BankAccountStatus | varchar(max) | YES | Current status of the bank account. A=Active, B=Blocked, S=Suspended. Distribution (2026): A ~90%, B ~10%, S <0.01%. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 6 | BankAccountBankProviderId | varchar(max) | YES | Identifier for the banking provider. Observed values: 3 (associated with UK accounts, MRMI BIC), 4 (associated with Malta accounts, CFTE BIC). (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 7 | BankAccountAccountName | varchar(max) | YES | Account holder name. Contains PII — masked with asterisks in restricted environments. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 8 | BankAccountAccountNumber | varchar(max) | YES | Bank account number. Format varies by provider and country (e.g., UK 8-digit, Malta 18-digit). Contains PII. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 9 | BankAccountSortCode | varchar(max) | YES | UK bank sort code (6 digits, e.g., 041335). Populated for UK bank accounts (provider 3); NULL or empty for non-UK accounts. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 10 | BankAccountIban | varchar(max) | YES | International Bank Account Number. Observed prefixes: GB (UK), MT (Malta). Contains PII. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 11 | BankAccountBic | varchar(max) | YES | Bank Identifier Code (SWIFT/BIC). Observed values: MRMIGB22XXX (UK provider 3), CFTEMTM1 (Malta provider 4). (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 12 | BankAccountStatusChangeReasonCode | varchar(max) | YES | Reason code for the most recent bank account status change. Largely unpopulated in recent data (all empty in 2026 sample). (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 13 | BankAccountStatusChangeNote | varchar(max) | YES | Free-text note accompanying a bank account status change. Largely unpopulated in recent data. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 14 | BankAccountStatusChangeSource | varchar(max) | YES | Source system or actor that triggered the bank account status change. Largely unpopulated in recent data. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 15 | etr_y | varchar(max) | YES | Tribe export year partition value (e.g., "2023"). Frequently NULL in recent data — use `partition_date` instead. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 16 | etr_ym | varchar(max) | YES | Tribe export year-month partition value (e.g., "2023-12"). Frequently NULL in recent data — use `partition_date` instead. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 17 | etr_ymd | varchar(max) | YES | Tribe export year-month-day partition value (e.g., "2023-12-20"). Frequently NULL in recent data — use `partition_date` instead. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 18 | SynapseUpdateDate | datetime | YES | Timestamp when the record was last updated in Synapse. Set during Generic Pipeline load. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 19 | Created | datetime2(7) | YES | Timestamp when the record was created in the source Tribe system. Used as the incremental load watermark in `SP_eMoney_Reconciliation_ETLs`. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 20 | EpmMethodId | varchar(max) | YES | Electronic Payment Method identifier. Observed values: 4, 5, or empty. Passed through to `ETL_AccountSnapshot` by `SP_eMoney_Reconciliation_ETLs`. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 21 | partition_date | date | YES | Date partition key for the snapshot. Has a dedicated non-clustered index (`XI_partition_date`). Primary filter for date-range queries. Range: 2023-12-20 to present. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 22 | BankAccountBankStateBranch | varchar(max) | YES | Bank state/branch identifier. Sparsely populated — all NULL in sampled data. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |
| 23 | BankAccountBankBranchCode | varchar(max) | YES | Bank branch code. Sparsely populated — all NULL in sampled data. (Tier 3 — FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | @Id | Passthrough |
| @AccountsSnapshots_BankAccounts@Id-795870 | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | @AccountsSnapshots_BankAccounts@Id-795870 | Passthrough |
| BankAccountId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountId | Passthrough |
| BankAccountExternalId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountExternalId | Passthrough |
| BankAccountStatus | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountStatus | Passthrough |
| BankAccountBankProviderId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountBankProviderId | Passthrough |
| BankAccountAccountName | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountAccountName | Passthrough |
| BankAccountAccountNumber | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountAccountNumber | Passthrough |
| BankAccountSortCode | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountSortCode | Passthrough |
| BankAccountIban | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountIban | Passthrough |
| BankAccountBic | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountBic | Passthrough |
| BankAccountStatusChangeReasonCode | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountStatusChangeReasonCode | Passthrough |
| BankAccountStatusChangeNote | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountStatusChangeNote | Passthrough |
| BankAccountStatusChangeSource | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountStatusChangeSource | Passthrough |
| etr_y | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | etr_y | Passthrough |
| etr_ym | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | etr_ym | Passthrough |
| etr_ymd | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | etr_ymd | Passthrough |
| SynapseUpdateDate | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | SynapseUpdateDate | Passthrough |
| Created | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | Created | Passthrough |
| EpmMethodId | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | EpmMethodId | Passthrough |
| partition_date | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | partition_date | Passthrough |
| BankAccountBankStateBranch | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountBankStateBranch | Passthrough |
| BankAccountBankBranchCode | FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 | BankAccountBankBranchCode | Passthrough |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.AccountsSnapshots_BankAccount-393561 (prod-banking)
  |-- Generic Pipeline #552 (Bronze export, daily append, parquet) ---|
  v
Azure Data Lake: Bronze/FiatDwhDB/Tribe/AccountsSnapshots_BankAccount-393561/
  |-- Generic Pipeline (Synapse COPY INTO) ---|
  v
eMoney_Tribe.AccountsSnapshots_BankAccount-393561 (~1.6B rows, Synapse)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id) ---|
  v
eMoney_dbo.ETL_AccountSnapshot (reconciliation target)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_accountssnapshots_bankaccount-393561 (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @AccountsSnapshots_BankAccounts@Id-795870 | eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 | FK to parent bank accounts container |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | @Id | LEFT JOIN to enrich account snapshots with bank account details |
| DE_dbo.NewSBUpdateStatsBigTables | — | Statistics update (UPDATE STATISTICS) |

---

## 7. Sample Queries

### 7.1 Active Bank Accounts on a Specific Date

```sql
SELECT BankAccountId, BankAccountIban, BankAccountBic, BankAccountBankProviderId
FROM [eMoney_Tribe].[AccountsSnapshots_BankAccount-393561]
WHERE partition_date = '2026-04-01'
  AND BankAccountStatus = 'A'
```

### 7.2 Bank Account Status Distribution by Provider

```sql
SELECT BankAccountBankProviderId, BankAccountStatus, COUNT(*) AS cnt
FROM [eMoney_Tribe].[AccountsSnapshots_BankAccount-393561]
WHERE partition_date = '2026-04-01'
GROUP BY BankAccountBankProviderId, BankAccountStatus
ORDER BY BankAccountBankProviderId, cnt DESC
```

### 7.3 Track Status Changes for a Specific Bank Account Over Time

```sql
SELECT partition_date, BankAccountStatus, BankAccountStatusChangeReasonCode, BankAccountStatusChangeSource
FROM [eMoney_Tribe].[AccountsSnapshots_BankAccount-393561]
WHERE BankAccountId = '748414'
ORDER BY partition_date
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen-harness mode). The SP header references Freshservice change #20353 (https://etoro.freshservice.com/a/changes/20353) for the original migration to Synapse.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 23 T3, 0 T4, 0 T5 | Elements: 23/23, Logic: 6/10, Lineage: 8/10*
*Object: eMoney_Tribe.AccountsSnapshots_BankAccount-393561 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking, dormant — no upstream wiki)*
