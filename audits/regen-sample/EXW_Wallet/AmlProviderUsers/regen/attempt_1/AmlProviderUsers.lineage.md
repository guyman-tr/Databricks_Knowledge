# EXW_Wallet.AmlProviderUsers — Column Lineage

Generated: 2026-04-30 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_Wallet.AmlProviderUsers |
| **Writer SP** | None (Generic Pipeline bronze landing) |
| **ETL Type** | Append — daily incremental from WalletDB.Wallet.AmlProviderUsers via Generic Pipeline |
| **Primary Source** | WalletDB.Wallet.AmlProviderUsers (AML provider–customer registration mapping) |
| **Refresh Pattern** | Daily (1440 min); data range: 2020-05-27 to present |
| **Row Count** | 207,352 |
| **UC Target** | `wallet.bronze_walletdb_wallet_amlproviderusers` |

## Source Objects

| Source | Object | Role |
|--------|--------|------|
| WalletDB.Wallet.AmlProviderUsers | Production AML provider–user registration table | Primary source (Generic Pipeline Append) |
| WalletDB.Dictionary.AmlProviders | AML provider lookup (1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN) | FK target for AmlProviderId |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | Id | Passthrough | Wallet.AmlProviderUsers | Id | Direct passthrough; production IDENTITY PK, landed as nullable bigint | Tier 1 — Wallet.AmlProviderUsers |
| 2 | AmlProviderId | Passthrough | Wallet.AmlProviderUsers | AmlProviderId | Direct passthrough; FK to Dictionary.AmlProviders | Tier 1 — Wallet.AmlProviderUsers |
| 3 | Gcid | Passthrough | Wallet.AmlProviderUsers | Gcid | Direct passthrough; production bigint landed as int | Tier 1 — Wallet.AmlProviderUsers |
| 4 | ProviderUserId | Passthrough | Wallet.AmlProviderUsers | ProviderUserId | Direct passthrough; production varchar(40) landed as varchar(max) | Tier 1 — Wallet.AmlProviderUsers |
| 5 | Occurred | Passthrough | Wallet.AmlProviderUsers | Occurred | Direct passthrough; datetime2(7) | Tier 1 — Wallet.AmlProviderUsers |
| 6 | etr_y | Pipeline metadata | — | — | Generic Pipeline extraction year partition column | Tier 3 — no production source |
| 7 | etr_ym | Pipeline metadata | — | — | Generic Pipeline extraction year-month partition column | Tier 3 — no production source |
| 8 | etr_ymd | Pipeline metadata | — | — | Generic Pipeline extraction year-month-day partition column | Tier 3 — no production source |
| 9 | SynapseUpdateDate | Pipeline metadata | — | — | Synapse-side ETL load timestamp | Tier 3 — no production source |
| 10 | partition_date | Pipeline metadata | — | — | Indexed partition date for incremental loading | Tier 3 — no production source |

## Consumers (Downstream)

| Object | Usage |
|--------|-------|
| EXW_dbo.SP_EXW_AMLProviderID | Reads this table daily, enriches with RealCID from EXW_DimUser, writes to EXW_dbo.EXW_AMLProviderID |
| EXW_dbo.EXW_AMLProviderID | Downstream denormalized AML table (via SP_EXW_AMLProviderID) |
