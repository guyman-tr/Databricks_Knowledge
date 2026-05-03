# eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253

> 2.9M-row raw Tribe sub-entity table storing card payment security verification method flags for settlement transactions, sourced daily from FiatDwhDB.Tribe on prod-banking via Generic Pipeline (Append). Data ranges from 2023-12-20 to present. Each row records which cardholder verification methods (PIN, CVV2, 3DS, chip, magnetic stripe, AVS, etc.) were present on a given settlement transaction. Consumed by SP_eMoney_Reconciliation_ETLs which LEFT JOINs security check flags into ETL_SettlementsTransactions for eMoney reconciliation reporting.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 (prod-banking, Generic Pipeline #540) |
| **Refresh** | Daily (1440 min), Append strategy |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP + 4 NCIs (@Id x2, @SettlementsTransactions_SettlementTransaction@Id-637239, partition_date) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze raw export |

---

## 1. Business Meaning

This table is a **sub-entity** of the eMoney Tribe Settlements Transactions data feed, specifically the `SecurityChecks` child element (XML entity ID 426253). It stores boolean flags indicating which cardholder verification methods (CVM) were present during each card-based settlement transaction processed by the Tribe card payments platform.

The table contains ~2.9M rows spanning from December 2023 to present. Each row is keyed by `@Id` (a GUID) and linked to the parent `SettlementsTransactions_SettlementTransaction-637239` table via `@SettlementsTransactions_SettlementTransaction@Id-637239`.

**ETL pattern**: Data is exported daily from `FiatDwhDB.Tribe` on the `prod-banking` server via the Generic Pipeline (Append strategy, parquet format). The table is then consumed as a read-only source by `SP_eMoney_Reconciliation_ETLs`, which LEFT JOINs security check columns (CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature) into the `ETL_SettlementsTransactions` reconciliation table.

**Data pattern**: Security check flags are stored as varchar strings "0" or "1" (not bit/int). Most transactions show CardExpirationDatePresent=1 and MagneticStripe=1/ChipData=1, with OnlinePIN, ThreeDomainSecure, and CVV2 rarely present — consistent with chip-and-PIN or contactless card-present transactions.

---

## 2. Business Logic

### 2.1 Cardholder Verification Method (CVM) Flags

**What**: Each boolean column represents whether a specific card security verification method was used or present during the transaction.
**Columns Involved**: CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature
**Rules**:
- Values are "0" (not present/not used) or "1" (present/used), stored as varchar(max)
- Multiple CVMs can be flagged simultaneously on a single transaction (e.g., ChipData=1 AND MagneticStripe=1)
- A transaction with all zeros indicates no card verification methods were captured

### 2.2 Parent-Child Relationship

**What**: This table is a child entity of the settlement transaction, linked via a shared GUID.
**Columns Involved**: @Id, @SettlementsTransactions_SettlementTransaction@Id-637239
**Rules**:
- `@Id` is the unique identifier for this security checks record
- `@SettlementsTransactions_SettlementTransaction@Id-637239` links to the parent settlement transaction
- In sampled data, @Id and the FK column often carry the same GUID value, indicating a 1:1 relationship

### 2.3 ETL Time Grain Columns

**What**: Hierarchical date breakdown columns added by the Tribe export pipeline for partitioning and filtering.
**Columns Involved**: etr_y, etr_ym, etr_ymd
**Rules**:
- `etr_y` = year (e.g., "2023")
- `etr_ym` = year-month (e.g., "2023-12")
- `etr_ymd` = year-month-day (e.g., "2023-12-20")
- These correspond to the source record creation date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Ideal for this relatively small sub-entity table used in JOINs.
- **HEAP** storage (no clustered index) with 4 NCIs on the key columns and partition_date.
- JOINs on `@Id` or `@SettlementsTransactions_SettlementTransaction@Id-637239` leverage the NCIs.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Which CVMs were used for a specific transaction? | Filter by `@Id` or `@SettlementsTransactions_SettlementTransaction@Id-637239` |
| How many transactions used 3D Secure? | `SELECT COUNT(*) WHERE ThreeDomainSecure = '1' AND partition_date >= '...'` |
| CVM usage trends over time | Group by `etr_ym` and aggregate CVM flag columns |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | `@Id = @Id` | Get full settlement transaction details |
| eMoney_dbo.ETL_SettlementsTransactions | Via SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id) | Reconciliation reporting with all transaction fields |

### 3.4 Gotchas

- **VARCHAR boolean flags**: CVM columns are varchar(max), not bit. Compare with string `'1'` / `'0'`, not integer 1/0.
- **AccountNames is usually empty**: In sampled data, AccountNames is blank for most rows.
- **@Id duplication**: The table has two duplicate NCIs on `@Id` (ClusteredIndex_ST_426253 and idx_426253_Id).
- **NOLOCK in SP**: The reader SP uses `WITH (NOLOCK)`, though Synapse uses snapshot isolation by default.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL transform logic |
| Tier 3 | Inferred from DDL, sample data, and SP usage — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(40) | YES | Unique GUID identifier for this security checks record. Used as the primary join key to the parent settlement transaction entity. Indexed by ClusteredIndex_ST_426253 and idx_426253_Id. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 2 | @SettlementsTransactions_SettlementTransaction@Id-637239 | varchar(40) | YES | Foreign key GUID linking to the parent record in SettlementsTransactions_SettlementTransaction-637239. In sampled data, often matches @Id (1:1 relationship). Indexed by ClusteredIndex_ST_426253_c2. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 3 | CardExpirationDatePresent | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether the card expiration date was present/verified during the transaction. Sampled data shows most transactions have this flag set to "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 4 | OnlinePIN | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether online PIN verification was performed during the transaction. Sampled data shows this is rarely "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 5 | OfflinePIN | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether offline PIN verification was performed during the transaction. Sampled data shows this is rarely "1". (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 6 | ThreeDomainSecure | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether 3D Secure (3DS) authentication was applied to the transaction. Sampled data shows this is rarely "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 7 | Cvv2 | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether CVV2 (Card Verification Value 2) was present/verified. Sampled data shows this is rarely "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 8 | MagneticStripe | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether the magnetic stripe was read during the transaction. Sampled data shows this is frequently "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 9 | ChipData | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether EMV chip data was present during the transaction. Sampled data shows this is frequently "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 10 | AVS | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether Address Verification System (AVS) was used during the transaction. Sampled data shows this is rarely "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 11 | PhoneNumber | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether phone number verification was used during the transaction. Sampled data shows this is rarely "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 12 | Signature | varchar(max) | YES | Boolean flag ("0"/"1") indicating whether a signature was captured/verified during the transaction. Sampled data shows this is rarely "1". Consumed by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 13 | etr_y | varchar(max) | YES | ETL time grain — year component of the source record date (e.g., "2023"). Added by the Tribe export pipeline for partitioning. (Tier 3 — no upstream wiki; grounded in DDL + sample data) |
| 14 | etr_ym | varchar(max) | YES | ETL time grain — year-month component of the source record date (e.g., "2023-12"). Added by the Tribe export pipeline for partitioning. (Tier 3 — no upstream wiki; grounded in DDL + sample data) |
| 15 | etr_ymd | varchar(max) | YES | ETL time grain — year-month-day component of the source record date (e.g., "2023-12-20"). Added by the Tribe export pipeline for partitioning. (Tier 3 — no upstream wiki; grounded in DDL + sample data) |
| 16 | SynapseUpdateDate | datetime | YES | Timestamp when the row was last updated/ingested in Synapse. Set by the Generic Pipeline during data load. (Tier 3 — no upstream wiki; grounded in DDL + sample data) |
| 17 | Created | datetime2(7) | YES | Source record creation timestamp from the Tribe platform. Used by SP_eMoney_Reconciliation_ETLs as the incremental load watermark (`WHERE @Created >= @SettlementsTransactions_DATE`). (Tier 3 — no upstream wiki; grounded in DDL + SP code + sample data) |
| 18 | AccountNames | varchar(max) | YES | Account name(s) associated with the security checks record. Sampled data shows this column is typically empty. (Tier 3 — no upstream wiki; grounded in DDL + sample data) |
| 19 | partition_date | date | YES | Date-based partition key for the table. Indexed by XI_partition_date. Aligns with the Created date in sampled data. (Tier 3 — no upstream wiki; grounded in DDL + sample data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe | @Id | Passthrough |
| @SettlementsTransactions_SettlementTransaction@Id-637239 | FiatDwhDB.Tribe | @SettlementsTransactions_SettlementTransaction@Id-637239 | Passthrough |
| CardExpirationDatePresent | FiatDwhDB.Tribe | CardExpirationDatePresent | Passthrough |
| OnlinePIN | FiatDwhDB.Tribe | OnlinePIN | Passthrough |
| OfflinePIN | FiatDwhDB.Tribe | OfflinePIN | Passthrough |
| ThreeDomainSecure | FiatDwhDB.Tribe | ThreeDomainSecure | Passthrough |
| Cvv2 | FiatDwhDB.Tribe | Cvv2 | Passthrough |
| MagneticStripe | FiatDwhDB.Tribe | MagneticStripe | Passthrough |
| ChipData | FiatDwhDB.Tribe | ChipData | Passthrough |
| AVS | FiatDwhDB.Tribe | AVS | Passthrough |
| PhoneNumber | FiatDwhDB.Tribe | PhoneNumber | Passthrough |
| Signature | FiatDwhDB.Tribe | Signature | Passthrough |
| etr_y | FiatDwhDB.Tribe | etr_y | Passthrough |
| etr_ym | FiatDwhDB.Tribe | etr_ym | Passthrough |
| etr_ymd | FiatDwhDB.Tribe | etr_ymd | Passthrough |
| SynapseUpdateDate | Generic Pipeline | N/A | Ingestion timestamp |
| Created | FiatDwhDB.Tribe | Created | Passthrough |
| AccountNames | FiatDwhDB.Tribe | AccountNames | Passthrough |
| partition_date | Generic Pipeline | N/A | Partition key |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253 (prod-banking)
  |-- Generic Pipeline #540 (Append, daily, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/SettlementsTransactions_SecurityChecks-426253/ (Data Lake)
  |-- Generic Pipeline (lake-to-Synapse) ---|
  v
eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253 (2.9M rows, REPLICATE)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id) ---|
  v
eMoney_dbo.ETL_SettlementsTransactions (reconciliation target)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_settlementstransactions_securitychecks-426253 (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @SettlementsTransactions_SettlementTransaction@Id-637239 | eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | Parent settlement transaction entity |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | aas.* | LEFT JOINs security check flags into ETL_SettlementsTransactions |
| eMoney_Tribe_tmp.SettlementsTransactions_SecurityChecks-426253_tmp | N/A | Temporary staging copy of this table |

---

## 7. Sample Queries

### 7.1 CVM Usage Summary by Month

```sql
SELECT
    etr_ym,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN CardExpirationDatePresent = '1' THEN 1 ELSE 0 END) AS with_expiry,
    SUM(CASE WHEN OnlinePIN = '1' THEN 1 ELSE 0 END) AS with_online_pin,
    SUM(CASE WHEN ThreeDomainSecure = '1' THEN 1 ELSE 0 END) AS with_3ds,
    SUM(CASE WHEN ChipData = '1' THEN 1 ELSE 0 END) AS with_chip,
    SUM(CASE WHEN Cvv2 = '1' THEN 1 ELSE 0 END) AS with_cvv2
FROM [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
GROUP BY etr_ym
ORDER BY etr_ym DESC
```

### 7.2 Transactions with Multiple CVMs

```sql
SELECT TOP 100
    [@Id],
    CardExpirationDatePresent, OnlinePIN, OfflinePIN,
    ThreeDomainSecure, Cvv2, MagneticStripe, ChipData,
    AVS, PhoneNumber, Signature,
    Created
FROM [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
WHERE (CASE WHEN OnlinePIN = '1' THEN 1 ELSE 0 END
     + CASE WHEN ThreeDomainSecure = '1' THEN 1 ELSE 0 END
     + CASE WHEN Cvv2 = '1' THEN 1 ELSE 0 END
     + CASE WHEN ChipData = '1' THEN 1 ELSE 0 END) >= 2
ORDER BY Created DESC
```

### 7.3 Join Security Checks to Settlement Transactions

```sql
SELECT TOP 50
    st.*,
    sc.CardExpirationDatePresent,
    sc.OnlinePIN,
    sc.ThreeDomainSecure,
    sc.Cvv2,
    sc.ChipData
FROM [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239] st
INNER JOIN [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253] sc
    ON st.[@Id] = sc.[@Id]
WHERE st.partition_date >= '2026-01-01'
ORDER BY st.[@Created] DESC
```

---

## 8. Atlassian Knowledge Sources

- Freshservice change request #20353 — original migration of eMoney reconciliation tables to Synapse (referenced in SP_eMoney_Reconciliation_ETLs header)
- No Jira/Confluence pages found specific to this sub-entity table

---

*Generated: 2026-04-30 | Quality: 7/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 19 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 6/10, Lineage: 8/10*
*Object: eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking, dormant — no upstream wiki)*
