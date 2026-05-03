# eMoney_Tribe.Authorizes_SecurityChecks-30662

> 3.76M-row Tribe XML-shredded child table capturing card authorization security check flags (CVV2, PIN, 3D Secure, AVS, chip data, magnetic stripe, etc.) for eToro Money card transactions from December 2023 to present. Sourced via Generic Pipeline (Append, daily) from FiatDwhDB.Tribe on prod-banking. Each row is joined to its parent authorization record in Authorizes_Authorize-312243 via @Id and consumed by SP_eMoney_Reconciliation_ETLs into ETL_Authorize.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 (prod-banking, Generic Pipeline #544) |
| **Refresh** | Daily (Append, 1440 min), incremental via @Created watermark |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP with 4 NCIs (@Id x2, @Authorizes_Authorize@Id-312243, partition_date) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

This table stores security check results for card authorization transactions processed through the Tribe payment platform for eToro Money. Each row represents the set of security verification methods that were present or applied during a single card authorization attempt.

The table is a child entity of `Authorizes_Authorize-312243` (linked via `@Id`), which contains the core authorization transaction details. This table adds the security verification dimension — whether the transaction included CVV2 verification, online/offline PIN, 3D Secure authentication, magnetic stripe data, chip (EMV) data, AVS (Address Verification Service), phone number verification, or signature verification.

**Row count**: ~3.76M rows as of April 2026.
**Date range**: 2023-12-20 to 2026-04-26.
**ETL pattern**: Generic Pipeline #544 appends daily from `FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662` on prod-banking. Downstream, `SP_eMoney_Reconciliation_ETLs` LEFT JOINs this table to `Authorizes_Authorize-312243` on `@Id` and inserts the security check columns into `eMoney_dbo.ETL_Authorize`.

The security check columns are boolean-like flags stored as varchar(max), with observed values of `0` and `1`. The `etr_y`/`etr_ym`/`etr_ymd` columns are ETL extraction timestamps populated by the Generic Pipeline; older rows (pre-2024) sometimes have these populated while newer rows may have them empty, suggesting a pipeline configuration change.

---

## 2. Business Logic

### 2.1 Security Check Boolean Flags

**What**: Each security check column indicates whether a specific verification method was present during the card authorization.
**Columns Involved**: CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature
**Rules**:
- Values are `0` (not present/not used) or `1` (present/used), stored as varchar(max).
- CardExpirationDatePresent is `1` in 99.9% of recent records — nearly all authorizations include the card expiration date.
- MagneticStripe and ChipData tend to co-occur (both `1` for card-present transactions).
- OnlinePIN and OfflinePIN are mutually exclusive in practice (at most one is `1`).
- ThreeDomainSecure = `1` indicates e-commerce 3DS-authenticated transactions.

### 2.2 Parent-Child Relationship

**What**: This table is a child fragment of the Tribe XML data export, linked to the parent authorization record.
**Columns Involved**: @Id, @Authorizes_Authorize@Id-312243
**Rules**:
- `@Id` is the unique row identifier within this child table.
- `@Authorizes_Authorize@Id-312243` is the FK to the parent `Authorizes_Authorize-312243` table.
- In many rows, `@Id` equals `@Authorizes_Authorize@Id-312243`, indicating a 1:1 relationship with the parent authorization.

### 2.3 ETL Extraction Timestamps

**What**: The `etr_*` columns track when the data was extracted by the Generic Pipeline.
**Columns Involved**: etr_y, etr_ym, etr_ymd
**Rules**:
- These columns are populated by the Generic Pipeline extraction process.
- Older records (2023-12) have values like `2023`, `2023-12`, `2023-12-20`.
- Newer records (2024+) sometimes have empty strings, suggesting a pipeline configuration change.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Efficient for JOINs against any distribution key since no data movement is needed.
- **HEAP** storage (no clustered index) — suitable for append-heavy write patterns.
- 4 NCIs: two on `@Id` (redundant — `ClusteredIndex_Authorizes_30662` and `idx_30662_Id`), one on `@Authorizes_Authorize@Id-312243`, one on `partition_date`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| What security checks were used for a specific authorization? | JOIN to `Authorizes_Authorize-312243` on `@Id`, filter by authorization criteria |
| How many authorizations used 3D Secure in a given period? | Filter on `ThreeDomainSecure = '1'` and `partition_date` range |
| Card-present vs. card-not-present breakdown | Use `ChipData = '1' OR MagneticStripe = '1'` for card-present; `ThreeDomainSecure = '1'` or `Cvv2 = '1'` alone for CNP |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.Authorizes_Authorize-312243 | `@Id = @Id` | Get parent authorization details (amount, merchant, response code) |
| eMoney_dbo.ETL_Authorize | Downstream consumer | Reconciled authorization data with security checks flattened in |

### 3.4 Gotchas

- **varchar(max) booleans**: Security check columns are `varchar(max)` not `bit` — always compare as strings (`= '1'`), not integers.
- **Duplicate NCIs on @Id**: `ClusteredIndex_Authorizes_30662` and `idx_30662_Id` are redundant indexes on the same column.
- **etr_* inconsistency**: Extraction timestamp columns are sometimes empty strings (not NULL) for newer records — filter with `etr_ymd <> ''` rather than `IS NOT NULL`.
- **AccountNames column**: Contains `0` or empty strings in sample data — purpose unclear, may be a placeholder or deprecated field.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + SP code, no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(40) | YES | Unique row identifier for this security checks record. GUID format. Used as the JOIN key to the parent authorization table `Authorizes_Authorize-312243`. Indexed (2 NCIs). (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 2 | @Authorizes_Authorize@Id-312243 | varchar(40) | YES | Foreign key to the parent authorization record in `Authorizes_Authorize-312243`. Links this security check row to its parent authorization transaction. Indexed. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 3 | CardExpirationDatePresent | varchar(max) | YES | Boolean flag indicating whether the card expiration date was present in the authorization request. Values: `0` = not present, `1` = present. Present in 99.9% of recent records. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 4 | OnlinePIN | varchar(max) | YES | Boolean flag indicating whether online PIN verification was used in the authorization. Values: `0` = not used, `1` = used. Mutually exclusive with OfflinePIN in practice. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 5 | OfflinePIN | varchar(max) | YES | Boolean flag indicating whether offline PIN verification was used in the authorization. Values: `0` = not used, `1` = used. Mutually exclusive with OnlinePIN in practice. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 6 | ThreeDomainSecure | varchar(max) | YES | Boolean flag indicating whether 3D Secure (3DS) authentication was applied to the authorization. Values: `0` = not applied, `1` = applied. Typical for e-commerce / card-not-present transactions. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 7 | Cvv2 | varchar(max) | YES | Boolean flag indicating whether CVV2 (Card Verification Value 2) was present in the authorization request. Values: `0` = not present, `1` = present. Used for card-not-present transactions. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 8 | MagneticStripe | varchar(max) | YES | Boolean flag indicating whether magnetic stripe data was read during the authorization. Values: `0` = not read, `1` = read. Indicates a card-present (swiped) transaction. Often co-occurs with ChipData. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 9 | ChipData | varchar(max) | YES | Boolean flag indicating whether EMV chip data was present in the authorization. Values: `0` = not present, `1` = present. Indicates a card-present (chip-inserted or contactless) transaction. Often co-occurs with MagneticStripe. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 10 | AVS | varchar(max) | YES | Boolean flag indicating whether Address Verification Service (AVS) was used in the authorization. Values: `0` = not used, `1` = used. Validates cardholder billing address against issuer records. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 11 | PhoneNumber | varchar(max) | YES | Boolean flag indicating whether phone number verification was used in the authorization. Values: `0` = not used, `1` = used. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 12 | Signature | varchar(max) | YES | Boolean flag indicating whether signature verification was used in the authorization. Values: `0` = not used, `1` = used. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 13 | etr_y | varchar(max) | YES | ETL extraction year. Populated by the Generic Pipeline during data export. Format: `YYYY` (e.g., `2023`). May be empty string for newer records. (Tier 3 — Generic Pipeline) |
| 14 | etr_ym | varchar(max) | YES | ETL extraction year-month. Populated by the Generic Pipeline during data export. Format: `YYYY-MM` (e.g., `2023-12`). May be empty string for newer records. (Tier 3 — Generic Pipeline) |
| 15 | etr_ymd | varchar(max) | YES | ETL extraction year-month-day. Populated by the Generic Pipeline during data export. Format: `YYYY-MM-DD` (e.g., `2023-12-20`). May be empty string for newer records. (Tier 3 — Generic Pipeline) |
| 16 | SynapseUpdateDate | datetime | YES | Timestamp when this row was last loaded or updated in Synapse by the Generic Pipeline. (Tier 3 — Generic Pipeline) |
| 17 | Created | datetime2(7) | YES | Timestamp when this record was created in the source system (Tribe). Used as the incremental watermark by SP_eMoney_Reconciliation_ETLs for loading into ETL_Authorize. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 18 | AccountNames | varchar(max) | YES | Account name(s) associated with the authorization. Observed values in sample data are `0` or empty string — purpose unclear, may be a deprecated or placeholder field from the Tribe XML export. (Tier 3 — FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662) |
| 19 | partition_date | date | YES | Partition date for incremental data management. Derived from the Created timestamp. Indexed (XI_partition_date). (Tier 3 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | @Id | Passthrough |
| @Authorizes_Authorize@Id-312243 | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | @Authorizes_Authorize@Id-312243 | Passthrough |
| CardExpirationDatePresent | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | CardExpirationDatePresent | Passthrough |
| OnlinePIN | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | OnlinePIN | Passthrough |
| OfflinePIN | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | OfflinePIN | Passthrough |
| ThreeDomainSecure | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | ThreeDomainSecure | Passthrough |
| Cvv2 | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | Cvv2 | Passthrough |
| MagneticStripe | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | MagneticStripe | Passthrough |
| ChipData | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | ChipData | Passthrough |
| AVS | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | AVS | Passthrough |
| PhoneNumber | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | PhoneNumber | Passthrough |
| Signature | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | Signature | Passthrough |
| etr_y | Generic Pipeline | etr_y | ETL metadata |
| etr_ym | Generic Pipeline | etr_ym | ETL metadata |
| etr_ymd | Generic Pipeline | etr_ymd | ETL metadata |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | ETL metadata |
| Created | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | @Created | Passthrough |
| AccountNames | FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 | AccountNames | Passthrough |
| partition_date | Generic Pipeline | partition_date | Derived from Created |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 (prod-banking)
  |-- Generic Pipeline #544 (Append, daily, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/Authorizes_SecurityChecks-30662/ (Data Lake)
  |-- Generic Pipeline (Bronze load) ---|
  v
eMoney_Tribe.Authorizes_SecurityChecks-30662 (3.76M rows, Synapse)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id) ---|
  v
eMoney_dbo.ETL_Authorize (reconciled authorization data)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_authorizes_securitychecks-30662 (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Authorizes_Authorize@Id-312243 | eMoney_Tribe.Authorizes_Authorize-312243 | FK to parent authorization record |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | LEFT JOINed on @Id to build ETL_Authorize |

---

## 7. Sample Queries

### 7.1 Security Check Profile for Recent Authorizations

```sql
SELECT
    aas.CardExpirationDatePresent,
    aas.OnlinePIN,
    aas.OfflinePIN,
    aas.ThreeDomainSecure,
    aas.Cvv2,
    aas.MagneticStripe,
    aas.ChipData,
    aas.AVS,
    aas.PhoneNumber,
    aas.Signature,
    COUNT(*) AS cnt
FROM [eMoney_Tribe].[Authorizes_SecurityChecks-30662] aas
WHERE aas.partition_date >= '2026-04-01'
GROUP BY
    aas.CardExpirationDatePresent, aas.OnlinePIN, aas.OfflinePIN,
    aas.ThreeDomainSecure, aas.Cvv2, aas.MagneticStripe, aas.ChipData,
    aas.AVS, aas.PhoneNumber, aas.Signature
ORDER BY cnt DESC
```

### 7.2 3D Secure Adoption Over Time

```sql
SELECT
    CAST(partition_date AS DATE) AS dt,
    SUM(CASE WHEN ThreeDomainSecure = '1' THEN 1 ELSE 0 END) AS three_ds_count,
    COUNT(*) AS total,
    CAST(SUM(CASE WHEN ThreeDomainSecure = '1' THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS three_ds_pct
FROM [eMoney_Tribe].[Authorizes_SecurityChecks-30662]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date
```

### 7.3 Join Security Checks to Parent Authorization

```sql
SELECT TOP 100
    auth.WorkDate,
    auth.HolderId,
    auth.TransactionAmount,
    auth.ResponseCode,
    aas.ThreeDomainSecure,
    aas.Cvv2,
    aas.ChipData,
    aas.MagneticStripe
FROM [eMoney_Tribe].[Authorizes_Authorize-312243] auth
INNER JOIN [eMoney_Tribe].[Authorizes_SecurityChecks-30662] aas
    ON auth.[@Id] = aas.[@Id]
WHERE auth.partition_date >= '2026-04-01'
ORDER BY auth.[@Created] DESC
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object. The SP header references Freshservice change #20353 for the original eMoney reconciliation migration to Synapse.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 19 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 7/10, Lineage: 8/10*
*Object: eMoney_Tribe.Authorizes_SecurityChecks-30662 | Type: Table | Production Source: FiatDwhDB.Tribe.Authorizes_SecurityChecks-30662 (prod-banking)*
