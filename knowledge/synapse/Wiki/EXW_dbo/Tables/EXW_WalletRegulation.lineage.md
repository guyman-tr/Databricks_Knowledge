# EXW_dbo.EXW_WalletRegulation — Column Lineage

Generated: 2026-04-20 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_dbo.EXW_WalletRegulation |
| **Writer SP** | EXW_dbo.SP_EXW_WalletRegulation |
| **ETL Type** | Full reload — DELETE entire table (no WHERE), then INSERT from WalletDB T&C data |
| **Primary Source** | CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions (user T&C acceptances) |
| **Secondary Source** | CopyFromLake.WalletDB_Wallet_TermsAndConditions (T&C type/version map) |
| **Scope Filter** | EXW_dbo.EXW_DimUser (only Wallet users with confirmed DWH identity) |
| **Refresh Pattern** | Daily; FromDate range: 2018-08-20 to 2026-04-11 |
| **Row Count** | 717,733 |
| **UC Target** | _Not_Migrated (to be verified) |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | GCID | Passthrough | EXW_dbo.EXW_DimUser | GCID | INNER JOIN EXW_DimUser on GCID; scope filter — only users in EXW_DimUser are included | Tier 2 — SP_EXW_WalletRegulation |
| 2 | RealCID | Passthrough | EXW_dbo.EXW_DimUser | RealCID | Direct passthrough from EXW_DimUser (inherits T1 from Customer.CustomerStatic) | Tier 1 — Customer.CustomerStatic (via EXW_DimUser) |
| 3 | TypeID | Passthrough | CopyFromLake.WalletDB_Wallet_TermsAndConditions | TypeId | Direct passthrough; regulatory T&C type identifier; values restricted to 1–5 | Tier 2 — SP_EXW_WalletRegulation |
| 4 | WalletRegulation | Computed | CopyFromLake.WalletDB_Wallet_TermsAndConditions | TypeId | CASE WHEN TypeId: 1→eToroX, 2→US, 3→Germany, 4→eToro DA, 5→eToro SEY | Tier 2 — SP_EXW_WalletRegulation |
| 5 | FromDate | Computed | CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions | Occured | MAX(DateOccurred) per GCID + TypeId group; ISNULL(…,'1900-01-01') for users with no dated T&C | Tier 2 — SP_EXW_WalletRegulation |
| 6 | ToDate | Computed | — | — | '2999-01-01' for current row (IsCurrent=1); DATEADD(dd,-1, current.FromDate) for previous row (IsCurrent=0) | Tier 2 — SP_EXW_WalletRegulation |
| 7 | FromDateID | Computed | — | — | CAST(CONVERT(VARCHAR(8), FromDate, 112) AS INT); YYYYMMDD integer | Tier 2 — SP_EXW_WalletRegulation |
| 8 | ToDateID | Computed | — | — | CAST(CONVERT(VARCHAR(8), ToDate, 112) AS INT); YYYYMMDD integer | Tier 2 — SP_EXW_WalletRegulation |
| 9 | IsCurrent | Computed | — | — | 1 for latest regulation (ROW_NUMBER()=1 by MaxDatePerRegulation DESC); 0 for immediately prior regulation | Tier 2 — SP_EXW_WalletRegulation |
| 10 | Occurred | Passthrough | CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions | Occured | MAX(Occurred) per GCID + TypeId + WalletRegulation group; timestamp of most recent T&C acceptance | Tier 2 — SP_EXW_WalletRegulation |
| 11 | UpdateDate | Computed | — | — | GETDATE() at INSERT | Tier 2 — SP_EXW_WalletRegulation |

## Source Objects

| Source | Object | Role |
|--------|--------|------|
| CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions | User T&C acceptance events (one row per user per T&C version accepted) | Primary acceptance data source |
| CopyFromLake.WalletDB_Wallet_TermsAndConditions | T&C type and version registry | TypeId → regulation name mapping |
| EXW_dbo.EXW_DimUser | Wallet user dimension | INNER JOIN for GCID scope and RealCID |

## Consumers (Downstream)

No downstream SPs or views found referencing EXW_WalletRegulation in the EXW_dbo or BI_DB_dbo schema. This table is likely queried directly from analytics tools or reporting dashboards.
