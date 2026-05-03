# Lineage: eMoney_Tribe.Authorizes_RiskActions-796100

## Source Objects

| # | Source Object | Source Type | Relationship | Schema | Database |
|---|---|---|---|---|---|
| 1 | Authorizes_RiskActions-796100 | Table | Direct source (Generic Pipeline Append) | Tribe | FiatDwhDB |
| 2 | Authorizes_Authorize-312243 | Table | Parent table (FK via @Id) | eMoney_Tribe | Synapse |
| 3 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | Reader (LEFT JOIN consumer) | eMoney_dbo | Synapse |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | @Id | Passthrough (raw Bronze ingest) | Tier 3 |
| 2 | @Authorizes_Authorize@Id-312243 | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | @Authorizes_Authorize@Id-312243 | Passthrough (raw Bronze ingest) | Tier 3 |
| 3 | MarkTransactionAsSuspicious | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | MarkTransactionAsSuspicious | Passthrough (raw Bronze ingest) | Tier 3 |
| 4 | NotifyCardholderBySendingTAIsNotification | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | NotifyCardholderBySendingTAIsNotification | Passthrough (raw Bronze ingest) | Tier 3 |
| 5 | ChangeCardStatusToRisk | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeCardStatusToRisk | Passthrough (raw Bronze ingest) | Tier 3 |
| 6 | ChangeAccountStatusToSuspended | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeAccountStatusToSuspended | Passthrough (raw Bronze ingest) | Tier 3 |
| 7 | RejectTransaction | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | RejectTransaction | Passthrough (raw Bronze ingest) | Tier 3 |
| 8 | etr_y | Generic Pipeline | etr_y | ETL partition key — year (pipeline-generated) | Tier 3 |
| 9 | etr_ym | Generic Pipeline | etr_ym | ETL partition key — year-month (pipeline-generated) | Tier 3 |
| 10 | etr_ymd | Generic Pipeline | etr_ymd | ETL partition key — year-month-day (pipeline-generated) | Tier 3 |
| 11 | SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Synapse load timestamp (pipeline-generated) | Tier 3 |
| 12 | Created | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | Created | Passthrough (raw Bronze ingest) | Tier 3 |
| 13 | partition_date | Generic Pipeline | partition_date | Date partition key (pipeline-generated) | Tier 3 |
| 14 | ChangeAccountStatusToReceiveOnly | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeAccountStatusToReceiveOnly | Passthrough (raw Bronze ingest) | Tier 3 |
| 15 | ChangeAccountStatusToSpendOnly | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeAccountStatusToSpendOnly | Passthrough (raw Bronze ingest) | Tier 3 |
