# EXW_dbo.EXW_AMLProviderID — Column Lineage

Generated: 2026-04-20 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_dbo.EXW_AMLProviderID |
| **Writer SP** | EXW_dbo.SP_EXW_AMLProviderID |
| **ETL Type** | Daily delta replace — DELETE WHERE DateID = @dt, then INSERT from AmlProviderUsers WHERE Occurred in [@dt, @dt+1) |
| **Primary Source** | EXW_Wallet.AmlProviderUsers (AML provider submission events) |
| **Secondary Source** | EXW_dbo.EXW_DimUser (RealCID enrichment via GCID JOIN) |
| **Refresh Pattern** | Daily; DateID range: 20200527 to 20260411 |
| **Row Count** | 206,407 |
| **UC Target** | _Not_Migrated (to be verified) |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | RealCID | Join-derived | EXW_dbo.EXW_DimUser | RealCID | JOIN on a.Gcid = b.GCID; enriched from EXW_DimUser (which inherits T1 from Customer.CustomerStatic) | Tier 1 — Customer.CustomerStatic (via EXW_DimUser) |
| 2 | GCID | Passthrough | EXW_Wallet.AmlProviderUsers | Gcid | Direct passthrough; HASH distribution key | Tier 2 — SP_EXW_AMLProviderID |
| 3 | ProviderUserID | Passthrough | EXW_Wallet.AmlProviderUsers | ProviderUserId | Direct passthrough; base64-encoded GCID string for AML provider's external system; may include trailing '=' padding | Tier 2 — SP_EXW_AMLProviderID |
| 4 | AMLProviderID | Passthrough | EXW_Wallet.AmlProviderUsers | AmlProviderId | Direct passthrough; integer identifier for AML compliance provider | Tier 2 — SP_EXW_AMLProviderID |
| 5 | DateID | Computed | EXW_Wallet.AmlProviderUsers | Occurred | CONVERT(varchar(8), Occurred, 112); YYYYMMDD integer — partition key for daily replace | Tier 2 — SP_EXW_AMLProviderID |
| 6 | UpdateDate | Computed | — | — | GETDATE() at INSERT | Tier 2 — SP_EXW_AMLProviderID |
| 7 | ProviderUserIDNormalized | Computed | EXW_Wallet.AmlProviderUsers | ProviderUserId | CASE WHEN ProviderUserId LIKE '%=' THEN SUBSTRING(ProviderUserId, 0, CHARINDEX('=', ProviderUserId)) ELSE ProviderUserId END; strips base64 trailing '=' padding | Tier 2 — SP_EXW_AMLProviderID |

## Source Objects

| Source | Object | Role |
|--------|--------|------|
| EXW_Wallet.AmlProviderUsers | AML provider event log — one row per user per AML provider submission | Primary source (date-filtered) |
| EXW_dbo.EXW_DimUser | Wallet user dimension | RealCID enrichment JOIN |

## Consumers (Downstream)

| Object | Usage |
|--------|-------|
| EXW_dbo.GetProviderUserIDNormalized | View that surfaces ProviderUserIDNormalized enriched with Country, Regulation, and WalletAllowance |
| BI_DB_dbo.SP_W_Tue_Email_for_KYT | Weekly KYT (Know Your Transaction) email report — JOINs on ProviderUserID / ProviderUserIDNormalized |
| EXW_dbo.SP_EXW_UserSettingsWalletAllowance | Reads EXW_AMLProviderID as part of wallet allowance determination |
| BI_DB_dbo.JUNK_SP_AML_Email_for_KYT | Deprecated AML KYT email SP (JUNK prefix indicates retired) |
