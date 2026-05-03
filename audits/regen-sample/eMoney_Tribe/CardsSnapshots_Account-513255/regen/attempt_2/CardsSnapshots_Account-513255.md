# eMoney_Tribe.CardsSnapshots_Account-513255

> 86.4M-row child table storing individual card-linked account snapshots from the Tribe card provider, spanning 2023-12-20 to 2026-04-26. Loaded daily via Generic Pipeline (Append) from FiatDwhDB.Tribe. Contains account status, balances, fee groups, and limit groups per card snapshot. Read downstream by SP_eMoney_Reconciliation_ETLs to build the reconciliation dataset.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.CardsSnapshots_Account-513255 (Generic Pipeline, Append) |
| **Refresh** | Daily (every 1440 min via Generic Pipeline) |
| **Synapse Distribution** | HASH([@Id]) |
| **Synapse Index** | CLUSTERED INDEX ([@Id] ASC), NCI on partition_date |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

This table stores individual account records extracted from Tribe card snapshot files. Each row represents a point-in-time snapshot of a single account associated with a card, capturing the account's status, currency, balances (available, blocked, current, reserved), and assigned fee/limits groups.

The table is part of a hierarchical JSON-shredded structure:
- **CardsSnapshots-890718** (root snapshot container, one row per file)
- **CardsSnapshots_Accounts-350640** (accounts collection, intermediate node)
- **CardsSnapshots_Account-513255** (this table — individual account detail)

The table is loaded daily via Generic Pipeline from `FiatDwhDB.Tribe` on `prod-banking`. It is read by `SP_eMoney_Reconciliation_ETLs` which joins it (alias `ad`) with the parent tables to build the `ETL_CardSnapshot` reconciliation dataset.

With 86.4M rows, the table grows by appending daily snapshots. All account-detail columns are stored as `varchar(max)` since they originate from JSON shredding. Balance columns (AvailableBalance, BlockedAmount, CurrentBalance, ReservedBalance) are string-typed and require CAST for numeric operations.

---

## 2. Business Logic

### 2.1 Account Status Tracking

**What**: Each snapshot captures the account status at a point in time.
**Columns Involved**: AccountStatus, AccountStatusDate, AccountStatusChangeSource, AccountStatusChangeReasonCode, AccountStatusChangeNote, AccountStatusChangeOriginatorId
**Rules**:
- AccountStatus values: A (Active, ~94%), S (Suspended, ~4.1%), B (Blocked, ~1.1%), P (Pending, ~0.5%), R (Restricted, ~0.08%)
- Status change metadata (source, reason code, note, originator) provides audit trail for each status transition
- AccountStatusDate records when the status was last changed

### 2.2 Fee and Limits Group Assignment

**What**: Each account is assigned to fee and limits groups that determine pricing and transaction limits.
**Columns Involved**: AccountLimitsGroupName, AccountLimitsGroupId, AccountFeeGroupName, AccountFeeGroupId
**Rules**:
- Limits groups: eToro Green Account (~68%), eToro Black Account (~14%), eToro Black EU EUR (~13%), eToro Green EU EUR (~4%), plus eToro Bronze, BPM Limit, Test, and Internal UK
- Fee groups mirror the limits group tier (Green, Black, Bronze) but with simpler naming
- Group assignment determines account-level transaction limits and fee schedules

### 2.3 Balance Snapshot

**What**: Point-in-time balance snapshot for each account.
**Columns Involved**: AvailableBalance, BlockedAmount, CurrentBalance, ReservedBalance, AccountCurrency
**Rules**:
- All balance columns are varchar(max) — must CAST to numeric for calculations
- AccountCurrency: GBP (~77%) or EUR (~23%)
- CurrentBalance = AvailableBalance + BlockedAmount (logical relationship, not enforced)
- ReservedBalance tracks funds held for pending operations

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH([@Id]) — optimal for joins on @Id with sibling tables
- **Clustered Index**: [@Id] ASC — fast point lookups by snapshot record ID
- **NCI**: partition_date — supports date-range filtering

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest snapshot per account | `WHERE partition_date = (SELECT MAX(partition_date) ...)` |
| Account balance trend | Filter by AccountId + date range on partition_date |
| Active accounts by currency | `WHERE AccountStatus = 'A' AND partition_date = @date GROUP BY AccountCurrency` |
| Fee group distribution | `GROUP BY AccountLimitsGroupName WHERE partition_date = @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Tribe.CardsSnapshots_Accounts-350640 | `ad.[@CardsSnapshots_Accounts@Id-350640] = ac.[@Id]` | Link to accounts collection |
| eMoney_Tribe.CardsSnapshots-890718 | Via CardsSnapshots_Accounts-350640 | Link to root snapshot file |
| eMoney_Tribe.CardsSnapshots_CardSnapshot-140457 | Via CardsSnapshots-890718.@Id | Link to card-level snapshot details |

### 3.4 Gotchas

- **All account columns are varchar(max)**: Balance columns, IDs, dates — all stored as strings from JSON shredding. Always CAST before numeric or date operations.
- **No unique constraint on AccountId**: The same AccountId appears in multiple snapshots (one per partition_date). Always filter by partition_date.
- **Empty strings vs NULLs**: Many columns contain empty strings rather than NULLs (e.g., AccountStatusDate, AccountStatusChangeSource). Check for both `IS NULL` and `= ''`.
- **etr_y/etr_ym/etr_ymd may be empty**: Some rows have NULL ETL date partition columns (visible in sample data). Use partition_date for date filtering instead.
- **86.4M rows**: Always filter by partition_date to avoid full table scans. Never run unfiltered GROUP BY.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed, transform documented from SP code |
| Tier 3 | No upstream documentation; grounded in DDL + sample data + SP usage |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(255) | YES | Unique snapshot record identifier for this account row. Used as the HASH distribution key and clustered index column. Values are GUIDs (e.g., 0008c90e-2884-47a9-b75d-c2be53f74ded). Also serves as the join key to the parent CardsSnapshots_Accounts-350640 table (shares the same value as @CardsSnapshots_Accounts@Id-350640). (Tier 3 — no upstream wiki) |
| 2 | @CardsSnapshots_Accounts@Id-350640 | varchar(max) | YES | FK to the accounts collection table CardsSnapshots_Accounts-350640. Links this individual account record to its parent accounts node in the snapshot hierarchy. Not documented in production wiki (production uses @CardsSnapshots@Id-890718 for a different parent relationship). (Tier 3 — no upstream wiki) |
| 3 | AccountId | varchar(max) | YES | Numeric account identifier from the Tribe card provider. Identifies the specific card-linked account (e.g., 1137061, 804592). Not unique across snapshots — repeats per partition_date. (Tier 3 — no upstream wiki) |
| 4 | AccountStatus | varchar(max) | YES | Account status code from Tribe. A=Active, S=Suspended, B=Blocked, P=Pending, R=Restricted. (Tier 3 — no upstream wiki) |
| 5 | AccountStatusDate | varchar(max) | YES | Date/time when the account status was last changed. Stored as varchar from JSON shredding; often empty string when no status change has occurred. (Tier 3 — no upstream wiki) |
| 6 | AccountStatusChangeSource | varchar(max) | YES | Source system or actor that triggered the account status change. Often empty string. (Tier 3 — no upstream wiki) |
| 7 | AccountStatusChangeReasonCode | varchar(max) | YES | Reason code for the account status change. Often empty string. (Tier 3 — no upstream wiki) |
| 8 | AccountStatusChangeNote | varchar(max) | YES | Free-text note associated with the account status change. Often empty string. (Tier 3 — no upstream wiki) |
| 9 | AccountStatusChangeOriginatorId | varchar(max) | YES | Identifier of the person or system that originated the account status change. Often empty string. (Tier 3 — no upstream wiki) |
| 10 | AccountLimitsGroupName | varchar(max) | YES | Name of the transaction limits group assigned to this account. Values include: eToro Green Account, eToro Black Account, eToro Black EU EUR, eToro Green EU EUR, eToro Bronze Account, BPM Limit, eToro Test Account, eToro Internal UK. (Tier 3 — no upstream wiki) |
| 11 | AccountLimitsGroupId | varchar(max) | YES | Numeric identifier of the transaction limits group. Corresponds to AccountLimitsGroupName (e.g., 44=Green, 45=Black, 80=Black EU EUR). (Tier 3 — no upstream wiki) |
| 12 | AccountFeeGroupName | varchar(max) | YES | Name of the fee group assigned to this account. Values mirror the limits tier: eToro Green, eToro Black, eToro Consumer Black EU. (Tier 3 — no upstream wiki) |
| 13 | AccountFeeGroupId | varchar(max) | YES | Numeric identifier of the fee group. Corresponds to AccountFeeGroupName (e.g., 24=Green, 23=Black, 36=Consumer Black EU). (Tier 3 — no upstream wiki) |
| 14 | BankAccounts | varchar(max) | YES | Linked bank account information from Tribe. Often empty string in sample data. (Tier 3 — no upstream wiki) |
| 15 | AvailableBalance | varchar(max) | YES | Available balance on the account at snapshot time. Stored as varchar from JSON; CAST to numeric for calculations. Denominated in AccountCurrency. (Tier 3 — no upstream wiki) |
| 16 | BlockedAmount | varchar(max) | YES | Amount blocked/held on the account at snapshot time. Stored as varchar from JSON; CAST to numeric for calculations. (Tier 3 — no upstream wiki) |
| 17 | CurrentBalance | varchar(max) | YES | Current total balance on the account at snapshot time. Logically equals AvailableBalance + BlockedAmount. Stored as varchar; CAST to numeric. (Tier 3 — no upstream wiki) |
| 18 | AccountCurrency | varchar(max) | YES | ISO currency code for the account. GBP (~77%) or EUR (~23%). (Tier 3 — no upstream wiki) |
| 19 | ReservedBalance | varchar(max) | YES | Reserved balance for pending operations on the account at snapshot time. Stored as varchar; CAST to numeric. (Tier 3 — no upstream wiki) |
| 20 | etr_y | varchar(max) | YES | ETL year partition value (e.g., "2023"). Generic Pipeline framework column. May be empty for some rows. (Tier 3 — Generic Pipeline framework) |
| 21 | etr_ym | varchar(max) | YES | ETL year-month partition value (e.g., "2023-12"). Generic Pipeline framework column. May be empty for some rows. (Tier 3 — Generic Pipeline framework) |
| 22 | etr_ymd | varchar(max) | YES | ETL year-month-day partition value (e.g., "2023-12-20"). Generic Pipeline framework column. May be empty for some rows. (Tier 3 — Generic Pipeline framework) |
| 23 | SynapseUpdateDate | datetime | YES | Timestamp when the row was loaded or last updated in Synapse. (Tier 3 — Synapse framework) |
| 24 | Created | datetime2(7) | YES | Source-side record creation timestamp from the Tribe provider. Indicates when this snapshot row was originally created in the production system before ingestion into Synapse. (Tier 3 — no upstream wiki) |
| 25 | partition_date | date | YES | Date partition column for incremental loading. Aligned with the snapshot date. Indexed (XI_partition_date). (Tier 3 — Synapse framework) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| @Id | FiatDwhDB.Tribe.CardsSnapshots_Account-513255 | @Id | Passthrough (uniqueidentifier → varchar(255)) |
| @CardsSnapshots_Accounts@Id-350640 | FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 | @Id | FK reference |
| AccountId–ReservedBalance | FiatDwhDB.Tribe.CardsSnapshots_Account-513255 | Same names | Passthrough (JSON-shredded fields) |
| etr_y / etr_ym / etr_ymd | — | — | Generic Pipeline framework |
| SynapseUpdateDate | — | — | Synapse load timestamp |
| Created | FiatDwhDB.Tribe.CardsSnapshots_Account-513255 | Created | Passthrough |
| partition_date | — | — | Synapse partition column |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.CardsSnapshots_Account-513255 (prod-banking)
  |-- Generic Pipeline (Bronze export, Append, daily, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/CardsSnapshots_Account-513255/ (Data Lake)
  |-- Generic Pipeline (Synapse load) ---|
  v
eMoney_Tribe.CardsSnapshots_Account-513255 (86.4M rows, Synapse)
  |-- SP_eMoney_Reconciliation_ETLs (reader, alias ad) ---|
  v
eMoney_dbo.ETL_CardSnapshot (reconciliation output)
  |-- Generic Pipeline (Bronze export, delta) ---|
  v
emoney.bronze_fiatdwhdb_tribe_cardssnapshots_account-513255 (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| @CardsSnapshots_Accounts@Id-350640 | eMoney_Tribe.CardsSnapshots_Accounts-350640 | FK to parent accounts collection |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Type | How Used |
|-------------------|------|----------|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Stored Procedure | LEFT JOIN on ad.[@Id] = ac.[@Id] to read account details for reconciliation |

---

## 7. Sample Queries

### 7.1 Latest snapshot balances per account

```sql
SELECT AccountId,
       AccountStatus,
       CAST(AvailableBalance AS DECIMAL(18,2)) AS AvailableBalance,
       CAST(CurrentBalance AS DECIMAL(18,2)) AS CurrentBalance,
       AccountCurrency,
       AccountLimitsGroupName
FROM [eMoney_Tribe].[CardsSnapshots_Account-513255]
WHERE partition_date = (SELECT MAX(partition_date) FROM [eMoney_Tribe].[CardsSnapshots_Account-513255])
  AND AccountStatus = 'A';
```

### 7.2 Account status distribution over time

```sql
SELECT partition_date, AccountStatus, COUNT(1) AS cnt
FROM [eMoney_Tribe].[CardsSnapshots_Account-513255]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date, AccountStatus
ORDER BY partition_date, cnt DESC;
```

### 7.3 Join with parent snapshot for full card context

```sql
SELECT TOP 100
       ad.AccountId, ad.AccountStatus, ad.AccountCurrency,
       CAST(ad.CurrentBalance AS DECIMAL(18,2)) AS Balance,
       ad.AccountLimitsGroupName
FROM [eMoney_Tribe].[CardsSnapshots_Account-513255] ad
INNER JOIN [eMoney_Tribe].[CardsSnapshots_Accounts-350640] ac
  ON ad.[@CardsSnapshots_Accounts@Id-350640] = ac.[@Id]
WHERE ad.partition_date >= '2026-04-01';
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 25 T3, 0 T4 | Elements: 25/25, Logic: 7/10, Relationships: 7/10*
*Object: eMoney_Tribe.CardsSnapshots_Account-513255 | Type: Table | Production Source: FiatDwhDB.Tribe.CardsSnapshots_Account-513255*
