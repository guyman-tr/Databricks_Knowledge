# Lineage: eMoney_Tribe.AccountsActivities_RiskActions-322546

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|---|---|---|---|---|
| 1 | eMoney Tribe Generic Pipeline | Data Lake Ingestion | eMoney_Tribe | Synapse | Writer — raw data ingested from eMoney (Modulr) card management platform via data lake pipeline |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Reader — LEFT JOINs this table to build ETL_AccountsActivities |
| 3 | AccountsActivities_AccountActivity-833937 | Table | eMoney_Tribe | Synapse | Parent — joined via [@Id] to provide account activity context |
| 4 | AccountsActivities_862157 | Table | eMoney_Tribe | Synapse | Sibling — root table in the AccountsActivities hierarchy |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | eMoney Tribe Generic Pipeline | @Id | Direct ingestion — GUID primary key from eMoney platform | Tier 3 |
| 2 | @AccountsActivities_AccountActivity@Id-833937 | eMoney Tribe Generic Pipeline | @AccountsActivities_AccountActivity@Id-833937 | Direct ingestion — FK to parent AccountActivity record | Tier 3 |
| 3 | MarkTransactionAsSuspicious | eMoney Tribe Generic Pipeline | MarkTransactionAsSuspicious | Direct ingestion — boolean flag (0/1) from risk engine | Tier 3 |
| 4 | NotifyCardholderBySendingTAIsNotification | eMoney Tribe Generic Pipeline | NotifyCardholderBySendingTAIsNotification | Direct ingestion — boolean flag (0/1) from risk engine | Tier 3 |
| 5 | ChangeCardStatusToRisk | eMoney Tribe Generic Pipeline | ChangeCardStatusToRisk | Direct ingestion — boolean flag (0/1) from risk engine | Tier 3 |
| 6 | ChangeAccountStatusToSuspended | eMoney Tribe Generic Pipeline | ChangeAccountStatusToSuspended | Direct ingestion — boolean flag (0/1) from risk engine | Tier 3 |
| 7 | RejectTransaction | eMoney Tribe Generic Pipeline | RejectTransaction | Direct ingestion — boolean flag (0/1) from risk engine | Tier 3 |
| 8 | etr_y | eMoney Tribe Generic Pipeline | etr_y | Direct ingestion — extraction year partition key | Tier 3 |
| 9 | etr_ym | eMoney Tribe Generic Pipeline | etr_ym | Direct ingestion — extraction year-month partition key | Tier 3 |
| 10 | etr_ymd | eMoney Tribe Generic Pipeline | etr_ymd | Direct ingestion — extraction year-month-day partition key | Tier 3 |
| 11 | SynapseUpdateDate | Synapse ETL | GETDATE() | Synapse load timestamp — set at ingestion time | Tier 3 |
| 12 | Created | eMoney Tribe Generic Pipeline | Created | Direct ingestion — record creation timestamp from eMoney platform | Tier 3 |
| 13 | partition_date | eMoney Tribe Generic Pipeline | partition_date | Direct ingestion — date partition key derived from Created | Tier 3 |
| 14 | ChangeAccountStatusToReceiveOnly | eMoney Tribe Generic Pipeline | ChangeAccountStatusToReceiveOnly | Direct ingestion — boolean flag (0/1) from risk engine. Added after initial schema. | Tier 3 |
| 15 | ChangeAccountStatusToSpendOnly | eMoney Tribe Generic Pipeline | ChangeAccountStatusToSpendOnly | Direct ingestion — boolean flag (0/1) from risk engine. Added after initial schema. | Tier 3 |
