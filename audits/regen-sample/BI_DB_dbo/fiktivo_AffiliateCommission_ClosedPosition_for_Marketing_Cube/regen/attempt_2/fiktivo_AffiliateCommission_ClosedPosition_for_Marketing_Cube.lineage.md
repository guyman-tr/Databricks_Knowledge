# Lineage: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | ClosedPositionVW | View | AffiliateCommission | fiktivo | Primary source — Bronze lake Parquet export via Generic Pipeline |
| 2 | ClosedPositionFromEtoro | Table | AffiliateCommission | fiktivo | Upstream of ClosedPositionVW — trading data from Service Broker |
| 3 | RegistrationMetaData | Table | AffiliateCommission | fiktivo | Upstream of ClosedPositionVW — affiliate/campaign metadata per CID |
| 4 | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | Stored Procedure | BI_DB_dbo | Synapse | Writer — COPY INTO from Parquet, date-range loop |
| 5 | SP_Marketing_Cube | Stored Procedure | BI_DB_dbo | Synapse | Orchestrator — calls writer, reads table for marketing aggregations |
| 6 | External_fiktivo_AffiliateCommission_ClosedPositionCommission | External Table | BI_DB_dbo | Synapse | Downstream consumer — joined on ClosedPositionID for commission calculations |
| 7 | Dim_Affiliate | Table | DWH_dbo | Synapse | Downstream consumer — joined on AffiliateID |

## Column Lineage

All columns originate from the Bronze lake Parquet export of `fiktivo.AffiliateCommission.ClosedPositionVW`. No upstream wiki was available for any column.

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | ClosedPositionID | ClosedPositionVW | ClosedPositionID | Passthrough from Parquet | Tier 3 |
| 2 | CommissionDate | ClosedPositionVW | CommissionDate | Passthrough from Parquet | Tier 3 |
| 3 | Amount | ClosedPositionVW | Amount | Passthrough from Parquet | Tier 3 |
| 4 | HedgeCommission | ClosedPositionVW | HedgeCommission | Passthrough from Parquet | Tier 3 |
| 5 | CID | ClosedPositionVW | CID | Passthrough from Parquet | Tier 3 |
| 6 | OriginalCID | ClosedPositionVW | OriginalCID | Passthrough from Parquet | Tier 3 |
| 7 | AffiliateID | ClosedPositionVW | AffiliateID | Passthrough from Parquet | Tier 3 |
| 8 | AffiliateCampaign | ClosedPositionVW | AffiliateCampaign | Passthrough from Parquet | Tier 3 |
| 9 | ProviderID | ClosedPositionVW | ProviderID | Passthrough from Parquet | Tier 3 |
| 10 | OriginalProviderID | ClosedPositionVW | OriginalProviderID | Passthrough from Parquet | Tier 3 |
| 11 | RealProviderID | ClosedPositionVW | RealProviderID | Passthrough from Parquet | Tier 3 |
| 12 | CountryID | ClosedPositionVW | CountryID | Passthrough from Parquet | Tier 3 |
| 13 | NetProfit | ClosedPositionVW | NetProfit | Computed in ClosedPositionVW from position P&L | Tier 2 |
| 14 | FunnelID | ClosedPositionVW | FunnelID | Passthrough from Parquet (via RegistrationMetaData) | Tier 3 |
| 15 | LabelID | ClosedPositionVW | LabelID | Hardcoded NULL in ClosedPositionVW | Tier 2 |
| 16 | PlayerLevelID | ClosedPositionVW | PlayerLevelID | Passthrough from Parquet (via RegistrationMetaData) | Tier 3 |
| 17 | DownloadID | ClosedPositionVW | DownloadID | Passthrough from Parquet (via RegistrationMetaData) | Tier 3 |
| 18 | LotCount | ClosedPositionVW | LotCount | Passthrough from Parquet | Tier 3 |
| 19 | BannerID | ClosedPositionVW | BannerID | Passthrough from Parquet | Tier 3 |
| 20 | Valid | ClosedPositionVW | Valid | Computed eligibility flag in ClosedPositionVW | Tier 2 |
| 21 | TrackingDate | ClosedPositionVW | TrackingDate | Passthrough from Parquet | Tier 3 |
| 22 | IsProcessed | ClosedPositionVW | IsProcessed | Computed processing status in ClosedPositionVW | Tier 2 |
| 23 | ValidFrom | ClosedPositionVW | ValidFrom | System-generated audit timestamp | Tier 2 |
| 24 | UpdateDate | ClosedPositionVW | UpdateDate | System-generated update timestamp | Tier 2 |
| 25 | AdditionalData | ClosedPositionVW | AdditionalData | Passthrough from Parquet | Tier 3 |
| 26 | etr_y | Lake path | YEAR(@date) | Lake partitioning column — extracted from Parquet file path | Tier 2 |
| 27 | etr_ym | Lake path | LEFT(CAST(@date),7) | Lake partitioning column — extracted from Parquet file path | Tier 2 |
| 28 | etr_ymd | Lake path | @date | Lake partitioning column — extracted from Parquet file path | Tier 2 |
