# EXW_Wallet.AmlProviderUsers

> 207K-row bronze landing table mapping eToro customers (Gcid) to their AML screening provider user IDs, sourced daily from WalletDB.Wallet.AmlProviderUsers via Generic Pipeline (Append), covering registrations from 2020-05-27 to present across 3 active providers (Chainalysis, Unsupported, ChainalysisCDN).

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.AmlProviderUsers (Generic Pipeline #715, Append) |
| **Refresh** | Daily (1440 min), Append strategy |
| **Synapse Distribution** | HASH(AmlProviderId) |
| **Synapse Index** | HEAP + NCI on partition_date ASC |
| **UC Target** | `wallet.bronze_walletdb_wallet_amlproviderusers` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze landing (Generic Pipeline export) |

---

## 1. Business Meaning

This table is a bronze landing copy of `WalletDB.Wallet.AmlProviderUsers`, which stores the mapping between eToro customer accounts (Gcid) and their corresponding user identities on AML (Anti-Money Laundering) screening providers. When a customer first performs a crypto transaction, the platform registers them with an AML provider (primarily Chainalysis) and stores the provider's user ID. This mapping enables ongoing AML screening to maintain risk profile history across transactions.

The table contains 207,352 rows spanning 2020-05-27 to 2026-04-26, loaded daily via Generic Pipeline (Append, pipeline #715). Three AML provider IDs are active in the data: 1 (Chainalysis, 167K rows / 81%), 3 (Unsupported, 27K / 13%), and 4 (ChainalysisCDN, 13K / 6%). Provider 2 (BlackList) exists in the dictionary but has no registrations.

Downstream, `EXW_dbo.SP_EXW_AMLProviderID` reads from this table, enriches it with `RealCID` from `EXW_DimUser`, and writes to `EXW_dbo.EXW_AMLProviderID` for compliance reporting.

---

## 2. Business Logic

### 2.1 Provider-Specific User Registration

**What**: Each customer is registered independently with each AML provider.
**Columns Involved**: AmlProviderId, Gcid, ProviderUserId
**Rules**:
- In production, unique constraint on (AmlProviderId, Gcid) ensures one registration per customer per provider
- ProviderUserId is a base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> "NDY4NzA1OTQ=")
- Provider distribution: 1=Chainalysis (167,133), 3=Unsupported (27,392), 4=ChainalysisCDN (12,827)
- Registration is triggered by `Wallet.StoreAmlProviderUsers` in production (idempotent insert)

### 2.2 ETL Partition Columns

**What**: Generic Pipeline adds extraction-date partition columns for incremental loading.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date, SynapseUpdateDate
**Rules**:
- etr_y/etr_ym/etr_ymd are NULL for ~43K rows (AmlProviderId=1 subset), populated for providers 3 and 4
- SynapseUpdateDate is NULL for ~163K rows (providers 3 and 4), populated only for provider 1
- partition_date is always populated and matches the date portion of Occurred
- The NCI on partition_date supports date-range pruning for downstream SP_EXW_AMLProviderID

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- HASH(AmlProviderId) — only 3 distinct values, causing significant data skew (81% in one bucket). Not ideal for parallel scans but acceptable for a 207K-row table.
- HEAP — no clustered index. NCI on partition_date enables date-range filtering.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many customers are registered per AML provider? | `SELECT AmlProviderId, COUNT(*) FROM EXW_Wallet.AmlProviderUsers GROUP BY AmlProviderId` |
| Find a customer's AML provider registration | `SELECT * FROM EXW_Wallet.AmlProviderUsers WHERE Gcid = @gcid` |
| Recent registrations in a date range | `SELECT * FROM EXW_Wallet.AmlProviderUsers WHERE partition_date BETWEEN @start AND @end` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | Gcid = EXW_DimUser.GCID | Resolve RealCID for the customer |
| EXW_dbo.EXW_AMLProviderID | AmlProviderId + Gcid (logical) | Compare raw landing vs denormalized downstream |

### 3.4 Gotchas

- **Skewed distribution**: HASH(AmlProviderId) with 3 values means most data sits in one distribution bucket. For large joins, prefer filtering by partition_date first.
- **NULL partition columns**: etr_y/etr_ym/etr_ymd are NULL for AmlProviderId=1 (~81% of rows). SynapseUpdateDate is NULL for providers 3 and 4. Do not assume these are populated.
- **Type narrowing**: Gcid is `int` in Synapse but `bigint` in production — potential truncation risk for very large GCIDs (>2.1B).
- **No uniqueness enforced**: Production has a unique constraint on (AmlProviderId, Gcid), but the Synapse landing table does not. Append strategy could theoretically introduce duplicates.
- **ProviderUserId encoding**: Values are base64-encoded GCIDs with trailing `=` padding. Downstream SP_EXW_AMLProviderID normalizes this by stripping the padding.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL SP code |
| Tier 3 | No production source; grounded in DDL and pipeline metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Auto-incrementing surrogate primary key. (Tier 1 — Wallet.AmlProviderUsers) |
| 2 | AmlProviderId | int | YES | The AML screening provider this registration is for: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. FK to Dictionary.AmlProviders. (Tier 1 — Wallet.AmlProviderUsers) |
| 3 | Gcid | int | YES | Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId. (Tier 1 — Wallet.AmlProviderUsers) |
| 4 | ProviderUserId | varchar(max) | YES | The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> "NDY4NzA1OTQ="). Used in all API calls to the provider. (Tier 1 — Wallet.AmlProviderUsers) |
| 5 | Occurred | datetime2(7) | YES | Timestamp when this customer was first registered with the AML provider. (Tier 1 — Wallet.AmlProviderUsers) |
| 6 | etr_y | varchar(max) | YES | Generic Pipeline extraction year partition column (e.g., "2021"). NULL for ~43K rows (AmlProviderId=1 subset). Not present in production source. (Tier 3 — Generic Pipeline infrastructure) |
| 7 | etr_ym | varchar(max) | YES | Generic Pipeline extraction year-month partition column (e.g., "2021-02"). NULL for ~43K rows (AmlProviderId=1 subset). Not present in production source. (Tier 3 — Generic Pipeline infrastructure) |
| 8 | etr_ymd | varchar(max) | YES | Generic Pipeline extraction year-month-day partition column (e.g., "2021-02-08"). NULL for ~43K rows (AmlProviderId=1 subset). Not present in production source. (Tier 3 — Generic Pipeline infrastructure) |
| 9 | SynapseUpdateDate | datetime | YES | Synapse-side ETL load timestamp. NULL for ~163K rows (AmlProviderId 3 and 4). Not present in production source. (Tier 3 — Generic Pipeline infrastructure) |
| 10 | partition_date | date | YES | Indexed partition date for incremental data loading, matching the date portion of Occurred. Used by downstream SP_EXW_AMLProviderID for date-range filtering. Not present in production source. (Tier 3 — Generic Pipeline infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Id | Wallet.AmlProviderUsers | Id | Passthrough (IDENTITY in prod, nullable in Synapse) |
| AmlProviderId | Wallet.AmlProviderUsers | AmlProviderId | Passthrough |
| Gcid | Wallet.AmlProviderUsers | Gcid | Passthrough (bigint in prod, int in Synapse) |
| ProviderUserId | Wallet.AmlProviderUsers | ProviderUserId | Passthrough (varchar(40) in prod, varchar(max) in Synapse) |
| Occurred | Wallet.AmlProviderUsers | Occurred | Passthrough |
| etr_y | — | — | Generic Pipeline metadata |
| etr_ym | — | — | Generic Pipeline metadata |
| etr_ymd | — | — | Generic Pipeline metadata |
| SynapseUpdateDate | — | — | Generic Pipeline metadata |
| partition_date | — | — | Generic Pipeline metadata |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.AmlProviderUsers (production, ~207K rows)
  |-- Generic Pipeline #715 (Bronze export, Append, daily 1440 min) ---|
  v
Azure Data Lake: Bronze/WalletDB/Wallet/AmlProviderUsers/ (parquet)
  |-- Synapse external table / COPY INTO ---|
  v
EXW_Wallet.AmlProviderUsers (207,352 rows, HASH(AmlProviderId), HEAP)
  |-- SP_EXW_AMLProviderID (daily, JOIN with EXW_DimUser for RealCID) ---|
  v
EXW_dbo.EXW_AMLProviderID (denormalized downstream)
  |-- Generic Pipeline (UC export) ---|
  v
wallet.bronze_walletdb_wallet_amlproviderusers (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AmlProviderId | Dictionary.AmlProviders (WalletDB) | AML screening provider lookup: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN |
| Gcid | Customer account (logical) | Global Customer ID — no enforced FK in Synapse |

### 6.2 Referenced By (other objects point to this)

| Source Object | Description |
|--------------|-------------|
| EXW_dbo.SP_EXW_AMLProviderID | Reads this table, enriches with RealCID from EXW_DimUser, writes to EXW_AMLProviderID |

---

## 7. Sample Queries

### 7.1 Count registrations per AML provider
```sql
SELECT AmlProviderId,
       COUNT(*) AS registrations,
       MIN(Occurred) AS earliest,
       MAX(Occurred) AS latest
FROM EXW_Wallet.AmlProviderUsers
GROUP BY AmlProviderId
ORDER BY registrations DESC;
```

### 7.2 Find a customer's AML provider registrations
```sql
SELECT Id, AmlProviderId, ProviderUserId, Occurred, partition_date
FROM EXW_Wallet.AmlProviderUsers
WHERE Gcid = 32738063
ORDER BY Occurred;
```

### 7.3 Recent registrations in a date window
```sql
SELECT TOP 20 Id, AmlProviderId, Gcid, ProviderUserId, Occurred
FROM EXW_Wallet.AmlProviderUsers
WHERE partition_date >= '2026-04-01'
ORDER BY Occurred DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 5 T1, 0 T2, 5 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 7/10*
*Object: EXW_Wallet.AmlProviderUsers | Type: Table | Production Source: WalletDB.Wallet.AmlProviderUsers (Generic Pipeline #715)*
