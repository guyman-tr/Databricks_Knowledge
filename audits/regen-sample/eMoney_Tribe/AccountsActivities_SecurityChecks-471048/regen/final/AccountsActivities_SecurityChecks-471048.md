# eMoney_Tribe.AccountsActivities_SecurityChecks-471048

> 29.7M-row raw Treezor XML child table storing security check boolean flags for eToro Money account activity transactions, covering 2023-12-20 to 2026-04-26. Each row records which card verification methods (CVV2, 3D Secure, AVS, PIN, chip, magnetic stripe, etc.) were present during a transaction. Loaded via Generic Pipeline from Treezor XML exports; consumed by `SP_eMoney_Reconciliation_ETLs` as a LEFT JOIN child to build `ETL_AccountsActivities`. Production source: FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 (Treezor XML exports) via Generic Pipeline |
| **Refresh** | Incremental append via Generic Pipeline; read by SP_eMoney_Reconciliation_ETLs using `MAX(Created)` watermark from ETL_AccountsActivities |
| **Synapse Distribution** | HASH ( [@Id] ) |
| **Synapse Index** | HEAP + 4 NCIs: `ClusteredIndex_AA_471048_Id` on [@Id], `ClusteredIndex_AA_471048_c2` on [@AccountsActivities_AccountActivity@Id-833937], `XI_partition_date` on [partition_date], `idx_471048_Id` on [@Id] |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`AccountsActivities_SecurityChecks-471048` is a raw Treezor XML child table in the eMoney Tribe schema. It stores security verification results for account activity transactions processed through the eToro Money card and payment platform. Each row corresponds to one account activity event and records which card security verification methods were present during the transaction (e.g., CVV2, 3D Secure, AVS, online PIN, chip data).

The table holds ~29.7M rows spanning from December 2023 to April 2026. The numeric suffix `471048` is a Treezor webhook/file entity identifier for this specific XML child node type.

In the XML document hierarchy, this table sits as a child of `AccountsActivities_AccountActivity-833937` (the transaction detail table), which itself is a child of `AccountsActivities_862157` (the XML envelope). All three tables share the same `@Id` GUID as join key.

The stored procedure `SP_eMoney_Reconciliation_ETLs` (authored by eMoney & Wallet Data Analytics Team, Ofir Ovadia, 2022-11-16; Freshservice Change #20353) reads this table as alias `aas` via LEFT JOIN on `@Id` to enrich the reconciled `ETL_AccountsActivities` fact table with security check flags. Nine of the ten security check columns are selected into ETL_AccountsActivities (all except ChipData, which is excluded from the Account Activities section but included in the Settlements section from a different SecurityChecks table).

All security check columns store `"0"` (not present) or `"1"` (present) as varchar(max) strings. Most transactions show all-zero security checks, indicating the checks were not applicable or not performed for that transaction type (e.g., internal LOAD/UNLOAD transfers).

---

## 2. Business Logic

### 2.1 Security Check Boolean Flags

**What**: Each security verification method is represented as a boolean flag indicating whether it was present during the transaction.
**Columns Involved**: CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature
**Rules**:
- `"1"` = the security check method was present/used during the transaction
- `"0"` = the security check method was not present/used
- For non-card transactions (LOAD, UNLOAD, EPM transfers), all flags are typically `"0"` since card verification does not apply
- Card-present POS transactions may show `MagneticStripe = "1"` and/or `ChipData = "1"`
- E-commerce transactions may show `ThreeDomainSecure = "1"`, `Cvv2 = "1"`, `CardExpirationDatePresent = "1"`

### 2.2 Parent-Child XML Document Model

**What**: This table is a child node in the Treezor XML document hierarchy, linked by @Id.
**Columns Involved**: @Id, @AccountsActivities_AccountActivity@Id-833937
**Rules**:
- `@Id` is the GUID linking to the parent `AccountsActivities_AccountActivity-833937` transaction detail record
- In most observed rows, `@Id` equals `@AccountsActivities_AccountActivity@Id-833937`, indicating a 1:1 relationship with the parent activity record
- Some rows show different values, suggesting the FK field encodes a different parent relationship in those cases

### 2.3 ETL Partition Keys

**What**: Three partition columns support Azure Data Lake bronze export partitioning.
**Columns Involved**: etr_y, etr_ym, etr_ymd
**Rules**:
- Populated by the Generic Pipeline for year/month/day partitioning
- May be NULL for some rows (consistent with sibling table behavior where ~99.8% NULL was observed on 862157)
- Not used by SP_eMoney_Reconciliation_ETLs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(@Id) — co-located with sibling tables `AccountsActivities_AccountActivity-833937`, `AccountsActivities_RiskActions-322546`, and parent `AccountsActivities_862157` for efficient JOIN operations
- **Index**: HEAP with 4 NCIs. Two indexes on @Id (redundant: `ClusteredIndex_AA_471048_Id` and `idx_471048_Id`), one on the FK column, one on partition_date
- **Note**: ~29.7M rows. Always filter by `partition_date` or `Created` for large scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Security checks for a specific transaction | `WHERE [@Id] = '...'` — uses HASH distribution + NCI |
| Transactions with 3D Secure present | `WHERE ThreeDomainSecure = '1' AND partition_date >= '...'` |
| Daily count of transactions with any security check | Filter on partition_date, check each flag column for '1' |
| Combine with full transaction detail | JOIN to AccountsActivities_AccountActivity-833937 on @Id |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.AccountsActivities_AccountActivity-833937 | ON @Id = @Id | Get transaction amounts, codes, merchant info |
| eMoney_Tribe.AccountsActivities_862157 | ON @Id = @Id | Get XML envelope metadata (@FileName) |
| eMoney_Tribe.AccountsActivities_RiskActions-322546 | ON @Id = @Id | Get risk action flags for the same transaction |

### 3.4 Gotchas

- **All security check columns are varchar(max)** — they store `"0"` or `"1"` as strings, not integers or bits. Use string comparison (`= '1'`), not numeric.
- **AccountNames column is mostly empty** — observed values are `"0"` or empty string; purpose is unclear and may not carry meaningful account name data.
- **Duplicate @Id indexes** — `ClusteredIndex_AA_471048_Id` and `idx_471048_Id` both index `[@Id] ASC`, which is redundant.
- **HEAP table** — no columnstore compression. Full scans on 29.7M rows will be slower than columnstore equivalents.
- **ChipData not in ETL_AccountsActivities** — while 9 security check columns are selected by SP_eMoney_Reconciliation_ETLs for the Account Activities reconciliation, ChipData is excluded. It IS included in the Settlements reconciliation from a different SecurityChecks table (426253).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL, live data, and SP context — no upstream wiki for this column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(40) | YES | Unique record identifier. PK. Distribution key (HASH). Links to parent AccountsActivities_AccountActivity-833937 and sibling tables (RiskActions-322546) via same @Id. Indexed via ClusteredIndex_AA_471048_Id and idx_471048_Id. (Tier 1 — FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048) |
| 2 | @AccountsActivities_AccountActivity@Id-833937 | varchar(40) | YES | Foreign key to the parent AccountsActivities_AccountActivity-833937 table. Column name encodes the parent entity ID (833937). In most observed rows, value equals @Id, indicating a 1:1 relationship with the parent activity record. Indexed via ClusteredIndex_AA_471048_c2. (Tier 3 — DDL + SP context, no upstream wiki for this column; production FK column has different name @AccountsActivities@Id-862157) |
| 3 | CardExpirationDatePresent | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether the card expiration date was present and verified during the transaction. '1' = present, '0' = not present. Applicable to card-based transactions; typically '0' for internal transfers and EPM payments. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 4 | OnlinePIN | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether an online PIN was entered and verified during the transaction. '1' = present, '0' = not present. Used for chip-and-PIN card transactions. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 5 | OfflinePIN | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether an offline PIN verification was performed. '1' = present, '0' = not present. Used when the card terminal performs PIN verification locally against the chip without an online authorization call. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 6 | ThreeDomainSecure | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether 3D Secure (3DS) authentication was performed for the transaction. '1' = present, '0' = not present. Applicable to e-commerce/card-not-present transactions. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 7 | Cvv2 | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether the CVV2 (Card Verification Value 2) was provided and checked. '1' = present, '0' = not present. Used for card-not-present transactions as an anti-fraud measure. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 8 | MagneticStripe | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether the card's magnetic stripe was read during the transaction. '1' = present, '0' = not present. Indicates a swipe-based card-present transaction. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 9 | ChipData | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether EMV chip data was read during the transaction. '1' = present, '0' = not present. Indicates a chip-based card-present transaction. Note: this column is NOT selected by SP_eMoney_Reconciliation_ETLs for the Account Activities reconciliation (ETL_AccountsActivities), but IS included in the Settlements reconciliation from SecurityChecks-426253. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 10 | AVS | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether Address Verification Service (AVS) was performed. '1' = present, '0' = not present. AVS checks the billing address provided by the cardholder against the address on file with the card issuer. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 11 | PhoneNumber | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether phone number verification was performed as part of the security check. '1' = present, '0' = not present. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 12 | Signature | varchar(max) | YES | Boolean flag (0/1 as string) indicating whether a signature was captured or verified during the transaction. '1' = present, '0' = not present. Used for card-present transactions where signature verification is the cardholder verification method. (Tier 3 — DDL + live data + SP_eMoney_Reconciliation_ETLs context, no upstream wiki) |
| 13 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition key for year. Populated by the Azure Data Lake bronze export pipeline. Sample: '2023'. May be NULL for some rows. Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 14 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition key for year-month. Populated by the Azure Data Lake bronze export pipeline. Sample: '2023-12'. May be NULL for some rows. Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 15 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition key for year-month-day. Populated by the Azure Data Lake bronze export pipeline. Sample: '2023-12-20'. May be NULL for some rows. Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 16 | SynapseUpdateDate | datetime | YES | Timestamp when the row was loaded or last updated in Synapse by the Generic Pipeline. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 17 | Created | datetime2(7) | YES | Source system timestamp. Record creation time from the Treezor platform. Used as the incremental load boundary in SP_eMoney_Reconciliation_ETLs (`WHERE aa.[@Created] >= @AccountActivities_DATE`). Range: 2023-12-20 to 2026-04-26. (Tier 1 — FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048) |
| 18 | AccountNames | varchar(max) | YES | Account name or identifier associated with the security check record. Observed values are '0' or empty string — purpose is unclear and may not carry meaningful data in current usage. (Tier 3 — DDL + live data, no upstream wiki) |
| 19 | partition_date | date | YES | Date-level partition key for incremental data management in Synapse. Indexed via XI_partition_date. Aligns with the date portion of Created. Range: 2023-12-20 to 2026-04-26. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | @Id | Passthrough (UNIQUEIDENTIFIER → varchar(40)) |
| @AccountsActivities_AccountActivity@Id-833937 | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | (structural FK) | FK name differs between prod and Synapse |
| CardExpirationDatePresent | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | CardExpirationDatePresent | Passthrough |
| OnlinePIN | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | OnlinePIN | Passthrough |
| OfflinePIN | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | OfflinePIN | Passthrough |
| ThreeDomainSecure | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | ThreeDomainSecure | Passthrough |
| Cvv2 | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | Cvv2 | Passthrough |
| MagneticStripe | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | MagneticStripe | Passthrough |
| ChipData | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | ChipData | Passthrough |
| AVS | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | AVS | Passthrough |
| PhoneNumber | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | PhoneNumber | Passthrough |
| Signature | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | Signature | Passthrough |
| etr_y, etr_ym, etr_ymd | Generic Pipeline | Partition keys | ETL partition metadata |
| SynapseUpdateDate | Generic Pipeline | Generated | ETL ingestion timestamp |
| Created | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | Created | Passthrough |
| AccountNames | FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 | AccountNames | Passthrough |
| partition_date | Generic Pipeline | Generated | ETL partition metadata |

### 5.2 ETL Pipeline

```
Treezor API (banking-as-a-service / card issuer)
  |-- XML file export (accounts-activities-*.xml) ---|
  v
Generic Pipeline (Bronze export, XML parsing → Parquet)
  |-- Azure Data Lake: dldataplatformprodwe.dfs.core.windows.net/internal-sources/ ---|
  v
eMoney_Tribe_tmp.AccountsActivities_SecurityChecks-471048_tmp (staging)
  |-- COPY INTO + INSERT SELECT (append, incremental) ---|
  v
eMoney_Tribe.AccountsActivities_SecurityChecks-471048 (29.7M rows, child security checks)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN as aas on @Id) ---|
  v
eMoney_dbo.ETL_AccountsActivities (reconciled fact — 9 of 10 security columns)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.AccountsActivities_AccountActivity-833937 | Parent activity transaction record (LEFT JOIN on @Id) |
| @AccountsActivities_AccountActivity@Id-833937 | eMoney_Tribe.AccountsActivities_AccountActivity-833937 | Explicit FK column encoding parent entity |
| @Id | eMoney_Tribe.AccountsActivities_862157 | Grandparent XML envelope table |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | LEFT JOIN on @Id | Builds reconciliation table ETL_AccountsActivities with security check flags |
| eMoney_Tribe_tmp.AccountsActivities_SecurityChecks-471048_tmp | N/A | Temporary staging copy of this table |

---

## 7. Sample Queries

### 7.1 Transactions with 3D Secure Authentication

```sql
SELECT
    sc.[@Id],
    sc.ThreeDomainSecure,
    sc.Cvv2,
    sc.AVS,
    sc.Created
FROM [eMoney_Tribe].[AccountsActivities_SecurityChecks-471048] sc
WHERE sc.ThreeDomainSecure = '1'
  AND sc.partition_date >= '2026-01-01'
ORDER BY sc.Created DESC;
```

### 7.2 Join Security Checks with Transaction Detail

```sql
SELECT TOP 100
    aa.TransactionCodeDescription,
    aa.TransactionAmount,
    aa.TransactionCurrencyAlpha,
    sc.CardExpirationDatePresent,
    sc.OnlinePIN,
    sc.ThreeDomainSecure,
    sc.Cvv2,
    sc.MagneticStripe,
    sc.ChipData,
    sc.AVS
FROM [eMoney_Tribe].[AccountsActivities_AccountActivity-833937] aa
LEFT JOIN [eMoney_Tribe].[AccountsActivities_SecurityChecks-471048] sc
    ON sc.[@Id] = aa.[@Id]
WHERE aa.partition_date >= '2026-04-01'
ORDER BY aa.[@Created] DESC;
```

### 7.3 Security Check Usage Distribution

```sql
SELECT
    SUM(CASE WHEN CardExpirationDatePresent = '1' THEN 1 ELSE 0 END) AS CardExpiry,
    SUM(CASE WHEN OnlinePIN = '1' THEN 1 ELSE 0 END) AS OnlinePIN,
    SUM(CASE WHEN ThreeDomainSecure = '1' THEN 1 ELSE 0 END) AS ThreeDS,
    SUM(CASE WHEN Cvv2 = '1' THEN 1 ELSE 0 END) AS CVV2,
    SUM(CASE WHEN MagneticStripe = '1' THEN 1 ELSE 0 END) AS MagStripe,
    SUM(CASE WHEN ChipData = '1' THEN 1 ELSE 0 END) AS Chip,
    SUM(CASE WHEN AVS = '1' THEN 1 ELSE 0 END) AS AVS,
    COUNT(*) AS Total
FROM [eMoney_Tribe].[AccountsActivities_SecurityChecks-471048]
WHERE partition_date >= '2026-01-01';
```

---

## 8. Atlassian Knowledge Sources

- Freshservice Change Request #20353 — referenced in SP_eMoney_Reconciliation_ETLs header (migration of eToro Money eMoney Reconciliation Tables to Synapse, authored by eMoney & Wallet Data Analytics Team, Ofir Ovadia, 2022-11-16)

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 2 T1, 0 T2, 17 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 6/10, Lineage: 7/10*
*Object: eMoney_Tribe.AccountsActivities_SecurityChecks-471048 | Type: Table | Production Source: FiatDwhDB.Tribe.AccountsActivities_SecurityChecks-471048 (Treezor XML)*
