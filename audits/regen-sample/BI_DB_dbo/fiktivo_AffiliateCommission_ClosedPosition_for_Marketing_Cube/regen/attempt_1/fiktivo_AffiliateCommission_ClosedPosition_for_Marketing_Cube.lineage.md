# Lineage: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Schema | Documented |
|---|--------------|-------------|-------------- |----------|--------|------------|
| 1 | AffiliateCommission.ClosedPosition | Table | Data source (via ClosedPositionVW) | fiktivo | AffiliateCommission | Yes — ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.ClosedPosition.md |
| 2 | AffiliateCommission.RegistrationMetaData | Table | Data source (via ClosedPositionVW) | fiktivo | AffiliateCommission | Yes — ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.RegistrationMetaData.md |
| 3 | AffiliateCommission.ClosedPositionVW | View | Direct Bronze export source | fiktivo | AffiliateCommission | Yes — ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md |
| 4 | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | Stored Procedure | Writer (COPY INTO from Bronze parquet) | Synapse | BI_DB_dbo | No |
| 5 | SP_Marketing_Cube | Stored Procedure | Orchestrator (calls writer SP, then consumes table) | Synapse | BI_DB_dbo | No |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | ClosedPositionID | AffiliateCommission.ClosedPosition | ClosedPositionID | Passthrough via ClosedPositionVW | Tier 1 |
| 2 | CommissionDate | AffiliateCommission.ClosedPosition | CommissionDate | Passthrough via ClosedPositionVW | Tier 1 |
| 3 | Amount | AffiliateCommission.ClosedPosition | Amount | Passthrough via ClosedPositionVW | Tier 1 |
| 4 | HedgeCommission | AffiliateCommission.ClosedPosition | HedgeCommission | Passthrough via ClosedPositionVW | Tier 1 |
| 5 | CID | AffiliateCommission.RegistrationMetaData | CID | Passthrough via ClosedPositionVW | Tier 1 |
| 6 | OriginalCID | AffiliateCommission.RegistrationMetaData | OriginalCID | Passthrough via ClosedPositionVW | Tier 1 |
| 7 | AffiliateID | AffiliateCommission.RegistrationMetaData | AffiliateID | Passthrough via ClosedPositionVW | Tier 1 |
| 8 | AffiliateCampaign | AffiliateCommission.RegistrationMetaData | AffiliateCampaign | Passthrough via ClosedPositionVW | Tier 1 |
| 9 | ProviderID | AffiliateCommission.ClosedPosition | ProviderID | Passthrough via ClosedPositionVW | Tier 1 |
| 10 | OriginalProviderID | AffiliateCommission.ClosedPosition | OriginalProviderID | Passthrough via ClosedPositionVW | Tier 1 |
| 11 | RealProviderID | AffiliateCommission.ClosedPosition | RealProviderID | Passthrough via ClosedPositionVW | Tier 1 |
| 12 | CountryID | AffiliateCommission.ClosedPosition | CountryID | Passthrough via ClosedPositionVW | Tier 1 |
| 13 | NetProfit | AffiliateCommission.ClosedPosition | NetProfit | Passthrough via ClosedPositionVW | Tier 1 |
| 14 | FunnelID | AffiliateCommission.RegistrationMetaData | FunnelID | Passthrough via ClosedPositionVW | Tier 1 |
| 15 | LabelID | AffiliateCommission.ClosedPositionVW | LabelID | Hardcoded NULL in view | Tier 1 |
| 16 | PlayerLevelID | AffiliateCommission.RegistrationMetaData | PlayerLevelID | Passthrough via ClosedPositionVW | Tier 1 |
| 17 | DownloadID | AffiliateCommission.RegistrationMetaData | DownloadID | Passthrough via ClosedPositionVW | Tier 1 |
| 18 | LotCount | AffiliateCommission.ClosedPosition | LotCount | Passthrough via ClosedPositionVW | Tier 1 |
| 19 | BannerID | AffiliateCommission.RegistrationMetaData | BannerID | Passthrough via ClosedPositionVW | Tier 1 |
| 20 | Valid | AffiliateCommission.ClosedPosition | Valid | Passthrough via ClosedPositionVW | Tier 1 |
| 21 | TrackingDate | AffiliateCommission.ClosedPosition | TrackingDate | Passthrough via ClosedPositionVW | Tier 1 |
| 22 | IsProcessed | AffiliateCommission.ClosedPosition | IsProcessed | Passthrough via ClosedPositionVW | Tier 1 |
| 23 | ValidFrom | AffiliateCommission.RegistrationMetaData | ValidFrom | Passthrough via ClosedPositionVW | Tier 1 |
| 24 | UpdateDate | AffiliateCommission.ClosedPosition / AffiliateCommission.RegistrationMetaData | CommissionDate, ValidFrom | CONVERT(datetime, GREATEST(CommissionDate, ValidFrom)) in ClosedPositionVW | Tier 2 |
| 25 | AdditionalData | AffiliateCommission.RegistrationMetaData | AdditionalData | Passthrough via ClosedPositionVW | Tier 1 |
| 26 | etr_y | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | — | Data lake partition key: YEAR(@date) from COPY INTO path | Tier 2 |
| 27 | etr_ym | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | — | Data lake partition key: YYYY-MM from COPY INTO path | Tier 2 |
| 28 | etr_ymd | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | — | Data lake partition key: YYYY-MM-DD from COPY INTO path | Tier 2 |
