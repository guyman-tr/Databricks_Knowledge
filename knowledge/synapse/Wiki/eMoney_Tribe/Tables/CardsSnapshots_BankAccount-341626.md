# eMoney_Tribe.CardsSnapshots_BankAccount-341626

> 88.3M-row raw Tribe data feed storing bank account details linked to eToro Money card snapshots, spanning 2023-12-20 to 2026-04-26. Ingested via Generic Pipeline from the Tribe card issuer platform. This table is a child of `CardsSnapshots_BankAccounts-83854` and provides individual bank account attributes (IBAN, sort code, BIC, payment capabilities) consumed by `SP_eMoney_Reconciliation_ETLs` to build `ETL_CardSnapshot`. Production source is the Tribe Cards API external data feed.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Tribe Cards API (external data feed) — consumed by SP_eMoney_Reconciliation_ETLs |
| **Refresh** | Incremental via Generic Pipeline; SP runs incremental load based on MAX(Created) |
| **Synapse Distribution** | HASH ([@CardsSnapshots_BankAccounts@Id-83854]) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is part of the eToro Money (eMoney) Tribe raw data layer. It stores bank account details associated with card holder snapshots from the Tribe card issuer/processor platform. Each row represents a bank account record linked to a card snapshot via the parent table `CardsSnapshots_BankAccounts-83854`.

The table contains 88.3M rows spanning from 2023-12-20 to 2026-04-26. Data is ingested from the Tribe Cards API through the Generic Pipeline into the `eMoney_Tribe` schema. The stored procedure `SP_eMoney_Reconciliation_ETLs` reads from this table (LEFT JOIN on `@CardsSnapshots_BankAccounts@Id-83854`) to enrich the `#Final` temp table with bank account fields, which are then inserted into `eMoney_dbo.ETL_CardSnapshot`.

The table captures UK banking attributes: account numbers, sort codes, IBANs (predominantly GB-prefixed), BIC codes (primarily MRMIGB22XXX indicating Modulr/Tribe UK operations), and payment capability flags for direct debits and instant payments.

The `etr_y`, `etr_ym`, `etr_ymd` columns are ETL partition markers populated by the Generic Pipeline during ingestion. These appear populated for earlier data (2023-12) but are empty for more recent records (2024+), suggesting a schema or pipeline change.

---

## 2. Business Logic

### 2.1 Parent-Child Relationship

**What**: Each bank account record is a child of a `CardsSnapshots_BankAccounts-83854` parent record, forming a one-to-many hierarchy (one card snapshot can have multiple bank accounts).
**Columns Involved**: `@Id`, `@CardsSnapshots_BankAccounts@Id-83854`
**Rules**:
- `@CardsSnapshots_BankAccounts@Id-83854` is the FK to the parent table `CardsSnapshots_BankAccounts-83854.@Id`
- `@Id` appears to equal `@CardsSnapshots_BankAccounts@Id-83854` in sampled data (1:1 relationship in practice)
- The distribution key is `@CardsSnapshots_BankAccounts@Id-83854` to co-locate with parent table JOINs

### 2.2 Payment Capability Flags

**What**: Boolean-style flags indicating which payment capabilities are enabled for the bank account.
**Columns Involved**: `BankAccountDirectDebitsIn`, `BankAccountDirectDebitsOut`, `BankAccountInstantPaymentsIn`, `BankAccountInstantPaymentsOut`
**Rules**:
- Values are stored as varchar: "Yes" or empty string
- In 2023-12 data, all four flags were "Yes" for sampled accounts
- In 2026 data, all four flags are empty strings, suggesting the Tribe API stopped populating these fields or the schema changed
- These columns are passed through to `ETL_CardSnapshot` without transformation

### 2.3 UK Banking Identifiers

**What**: Standard UK banking identifiers for the associated bank account.
**Columns Involved**: `BankAccountNumber`, `BankAccountSortCode`, `BankAccountIban`, `BankAccountBic`
**Rules**:
- IBANs are GB-prefixed (UK accounts)
- BIC is predominantly `MRMIGB22XXX` (Modulr Finance / Tribe UK)
- Sort code `041335` is the most common value in sampled data
- These are PII/sensitive banking fields

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `@CardsSnapshots_BankAccounts@Id-83854` — optimized for JOIN to parent table `CardsSnapshots_BankAccounts-83854`
- **Index**: HEAP (no clustered index) — suitable for append-heavy ingestion workload
- **NCI**: `XI_partition_date` on `partition_date` for date-filtered queries; `idx_341626_Id` on `@CardsSnapshots_BankAccounts@Id-83854` for FK lookups

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Bank accounts for a specific snapshot | Filter on `@CardsSnapshots_BankAccounts@Id-83854` (uses NCI + distribution key) |
| Recent bank account records | Filter on `partition_date >= 'YYYY-MM-DD'` (uses NCI) |
| Bank account status distribution | `GROUP BY BankAccountStatus WHERE partition_date >= ...` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| CardsSnapshots_BankAccounts-83854 | `@CardsSnapshots_BankAccounts@Id-83854 = [@Id]` | Parent snapshot linkage |
| CardsSnapshots-890718 | Via parent chain through CardsSnapshots_BankAccounts-83854 | Root card snapshot |
| ETL_CardSnapshot | Downstream — SP joins this table into the reconciliation output | Final reconciliation table |

### 3.4 Gotchas

- **PII data**: `BankAccountNumber`, `BankAccountSortCode`, `BankAccountIban`, `BankAccountBic` are sensitive banking identifiers — apply appropriate access controls
- **Empty payment flags in recent data**: `BankAccountDirectDebitsIn/Out` and `BankAccountInstantPaymentsIn/Out` are empty strings (not NULL) in 2024+ data despite being "Yes" in earlier data
- **ETR columns inconsistency**: `etr_y`, `etr_ym`, `etr_ymd` are populated for 2023-12 data but empty for later records
- **All varchar(max)**: Most columns are varchar(max) — no type enforcement at the storage layer; this is typical for raw Tribe ingestion tables
- **88.3M rows**: Large table — always filter on `partition_date` or `@CardsSnapshots_BankAccounts@Id-83854` to avoid full scans

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, data samples, and SP context — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(max) | YES | Unique record identifier (GUID) assigned by the Tribe platform during data export. Acts as the primary key for this bank account record. In sampled data, matches @CardsSnapshots_BankAccounts@Id-83854 (1:1 relationship). (Tier 3 — Tribe Cards API, no upstream wiki) |
| 2 | @CardsSnapshots_BankAccounts@Id-83854 | varchar(255) | YES | Foreign key to the parent table CardsSnapshots_BankAccounts-83854. Links this bank account record to its parent card snapshot bank accounts collection. Distribution key and indexed column. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 3 | BankAccountNumber | varchar(max) | YES | UK bank account number (8-digit format in sampled data, e.g. "03464580"). PII field. Passed through to ETL_CardSnapshot by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 4 | BankAccountSortCode | varchar(max) | YES | UK bank sort code identifying the bank and branch (6-digit format, e.g. "041335"). PII field. Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 5 | BankAccountIban | varchar(max) | YES | International Bank Account Number. Predominantly GB-prefixed for UK accounts (e.g. "GB32MRMI04133503464580"). PII field. Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 6 | BankAccountBic | varchar(max) | YES | Bank Identifier Code (SWIFT/BIC). Predominantly "MRMIGB22XXX" indicating Modulr Finance / Tribe UK operations. Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 7 | BankAccountStatus | varchar(max) | YES | Bank account active status. Values: "Yes" (100% of 2026 data). Indicates whether the bank account is active. Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 8 | BankAccountDirectDebitsIn | varchar(max) | YES | Inbound direct debit capability flag. Values: "Yes" in 2023-12 data, empty string in 2024+ data. Indicates whether the bank account can receive direct debits. Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 9 | BankAccountDirectDebitsOut | varchar(max) | YES | Outbound direct debit capability flag. Values: "Yes" in 2023-12 data, empty string in 2024+ data. Indicates whether the bank account can send direct debits. Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 10 | BankAccountInstantPaymentsIn | varchar(max) | YES | Inbound instant payment capability flag. Values: "Yes" in 2023-12 data, empty string in 2024+ data. Indicates whether the bank account can receive instant payments (Faster Payments). Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 11 | BankAccountInstantPaymentsOut | varchar(max) | YES | Outbound instant payment capability flag. Values: "Yes" in 2023-12 data, empty string in 2024+ data. Indicates whether the bank account can send instant payments (Faster Payments). Passed through to ETL_CardSnapshot. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 12 | etr_y | varchar(max) | YES | ETL partition year marker populated by the Generic Pipeline during ingestion (e.g. "2023"). Populated for 2023-12 data, empty for 2024+ records. (Tier 3 — Generic Pipeline, no upstream wiki) |
| 13 | etr_ym | varchar(max) | YES | ETL partition year-month marker populated by the Generic Pipeline during ingestion (e.g. "2023-12"). Populated for 2023-12 data, empty for 2024+ records. (Tier 3 — Generic Pipeline, no upstream wiki) |
| 14 | etr_ymd | varchar(max) | YES | ETL partition year-month-day marker populated by the Generic Pipeline during ingestion (e.g. "2023-12-20"). Populated for 2023-12 data, empty for 2024+ records. (Tier 3 — Generic Pipeline, no upstream wiki) |
| 15 | SynapseUpdateDate | datetime | YES | Timestamp when the record was last updated/ingested into Synapse by the Generic Pipeline. (Tier 3 — Generic Pipeline, no upstream wiki) |
| 16 | Created | datetime2(7) | YES | Record creation timestamp from the Tribe platform. Used by SP_eMoney_Reconciliation_ETLs as the incremental watermark (MAX(Created)) to determine which records to process. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 17 | partition_date | date | YES | Partition date for the record, derived from the ingestion date. Indexed (XI_partition_date) for efficient date-range queries. (Tier 3 — Generic Pipeline, no upstream wiki) |
| 18 | BankAccountBankStateBranch | varchar(max) | YES | Bank state or branch identifier. Empty in all sampled data. May represent the physical branch state/region for the bank account. (Tier 3 — Tribe Cards API, no upstream wiki) |
| 19 | BankAccountBankBranchCode | varchar(max) | YES | Bank branch code. Empty in all sampled data. May represent an alternative branch identifier from the Tribe platform. (Tier 3 — Tribe Cards API, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | Tribe Cards API | @Id | Passthrough |
| @CardsSnapshots_BankAccounts@Id-83854 | Tribe Cards API | @CardsSnapshots_BankAccounts@Id-83854 | Passthrough (FK to parent) |
| BankAccountNumber | Tribe Cards API | BankAccountNumber | Passthrough |
| BankAccountSortCode | Tribe Cards API | BankAccountSortCode | Passthrough |
| BankAccountIban | Tribe Cards API | BankAccountIban | Passthrough |
| BankAccountBic | Tribe Cards API | BankAccountBic | Passthrough |
| BankAccountStatus | Tribe Cards API | BankAccountStatus | Passthrough |
| BankAccountDirectDebitsIn | Tribe Cards API | BankAccountDirectDebitsIn | Passthrough |
| BankAccountDirectDebitsOut | Tribe Cards API | BankAccountDirectDebitsOut | Passthrough |
| BankAccountInstantPaymentsIn | Tribe Cards API | BankAccountInstantPaymentsIn | Passthrough |
| BankAccountInstantPaymentsOut | Tribe Cards API | BankAccountInstantPaymentsOut | Passthrough |
| etr_y | Generic Pipeline | etr_y | Pipeline partition marker |
| etr_ym | Generic Pipeline | etr_ym | Pipeline partition marker |
| etr_ymd | Generic Pipeline | etr_ymd | Pipeline partition marker |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Ingestion timestamp |
| Created | Tribe Cards API | @Created | Passthrough (renamed) |
| partition_date | Generic Pipeline | partition_date | Derived partition date |
| BankAccountBankStateBranch | Tribe Cards API | BankAccountBankStateBranch | Passthrough |
| BankAccountBankBranchCode | Tribe Cards API | BankAccountBankBranchCode | Passthrough |

### 5.2 ETL Pipeline

```
Tribe Cards API (external card issuer platform)
  |-- Generic Pipeline (raw data export, incremental) ---|
  v
eMoney_Tribe.CardsSnapshots_BankAccount-341626 (88.3M rows, raw)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN via CardsSnapshots_BankAccounts-83854) ---|
  v
eMoney_dbo.ETL_CardSnapshot (reconciliation output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @CardsSnapshots_BankAccounts@Id-83854 | eMoney_Tribe.CardsSnapshots_BankAccounts-83854 | FK to parent bank accounts collection |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| BankAccount columns | eMoney_dbo.ETL_CardSnapshot | SP_eMoney_Reconciliation_ETLs reads BankAccountNumber, SortCode, IBAN, BIC, Status, and payment flags into the reconciliation table |
| (DDL clone) | eMoney_Tribe_tmp.CardsSnapshots_BankAccount-341626_tmp | Temp staging table with identical schema |

---

## 7. Sample Queries

### 7.1 Recent Bank Accounts by Partition Date

```sql
SELECT TOP 100
    [@Id],
    BankAccountNumber,
    BankAccountSortCode,
    BankAccountIban,
    BankAccountBic,
    BankAccountStatus,
    Created,
    partition_date
FROM [eMoney_Tribe].[CardsSnapshots_BankAccount-341626]
WHERE partition_date >= '2026-04-01'
ORDER BY Created DESC
```

### 7.2 Bank Account Status Distribution Over Time

```sql
SELECT
    YEAR(partition_date) AS yr,
    MONTH(partition_date) AS mo,
    BankAccountStatus,
    COUNT(*) AS cnt
FROM [eMoney_Tribe].[CardsSnapshots_BankAccount-341626]
WHERE partition_date >= '2025-01-01'
GROUP BY YEAR(partition_date), MONTH(partition_date), BankAccountStatus
ORDER BY yr, mo
```

### 7.3 Payment Capability Flags Check

```sql
SELECT TOP 50
    BankAccountDirectDebitsIn,
    BankAccountDirectDebitsOut,
    BankAccountInstantPaymentsIn,
    BankAccountInstantPaymentsOut,
    partition_date
FROM [eMoney_Tribe].[CardsSnapshots_BankAccount-341626]
WHERE partition_date >= '2024-01-01'
  AND BankAccountDirectDebitsIn <> ''
ORDER BY partition_date DESC
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources were searched for this raw Tribe ingestion table. The SP header references Freshservice change request #20353.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 19 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 3/10, Lineage: complete*
*Object: eMoney_Tribe.CardsSnapshots_BankAccount-341626 | Type: Table | Production Source: Tribe Cards API (external, dormant upstream)*
