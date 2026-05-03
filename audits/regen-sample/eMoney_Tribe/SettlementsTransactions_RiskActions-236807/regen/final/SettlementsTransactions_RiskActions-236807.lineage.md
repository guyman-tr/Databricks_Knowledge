# Lineage: eMoney_Tribe.SettlementsTransactions_RiskActions-236807

## Source Objects

| # | Source Object | Source Type | Schema | Database | Server | Relationship |
|---|---|---|---|---|---|---|
| 1 | SettlementsTransactions_RiskActions-236807 | Table | Tribe | FiatDwhDB | prod-banking | Generic Pipeline passthrough (Append, daily) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Id | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | @Id | Passthrough | Tier 3 |
| 2 | @SettlementsTransactions_SettlementTransaction@Id-637239 | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | @SettlementsTransactions_SettlementTransaction@Id-637239 | Passthrough | Tier 3 |
| 3 | MarkTransactionAsSuspicious | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | MarkTransactionAsSuspicious | Passthrough | Tier 3 |
| 4 | NotifyCardholderBySendingTAIsNotification | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | NotifyCardholderBySendingTAIsNotification | Passthrough | Tier 3 |
| 5 | ChangeCardStatusToRisk | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeCardStatusToRisk | Passthrough | Tier 3 |
| 6 | ChangeAccountStatusToSuspended | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeAccountStatusToSuspended | Passthrough | Tier 3 |
| 7 | RejectTransaction | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | RejectTransaction | Passthrough | Tier 3 |
| 8 | etr_y | Generic Pipeline | Created | YEAR(Created) | Tier 2 |
| 9 | etr_ym | Generic Pipeline | Created | FORMAT(Created, 'yyyy-MM') | Tier 2 |
| 10 | etr_ymd | Generic Pipeline | Created | FORMAT(Created, 'yyyy-MM-dd') | Tier 2 |
| 11 | SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load time | Tier 2 |
| 12 | Created | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | Created | Passthrough | Tier 3 |
| 13 | partition_date | Generic Pipeline | Created | CAST(Created AS DATE) | Tier 2 |
| 14 | ChangeAccountStatusToReceiveOnly | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeAccountStatusToReceiveOnly | Passthrough | Tier 3 |
| 15 | ChangeAccountStatusToSpendOnly | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeAccountStatusToSpendOnly | Passthrough | Tier 3 |

## Notes

- No upstream wiki exists for FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807.
- No writer SP — data loaded via Generic Pipeline #539 (Append strategy, daily).
- Reader SP: eMoney_dbo.SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id, reads 5 risk-action flag columns into ETL_SettlementsTransactions).
- etr_y, etr_ym, etr_ymd, SynapseUpdateDate, and partition_date are ETL-framework columns added by the Generic Pipeline, not present in the production source.
