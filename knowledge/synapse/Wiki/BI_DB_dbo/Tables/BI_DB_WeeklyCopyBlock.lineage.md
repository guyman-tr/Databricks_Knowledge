# BI_DB_dbo.BI_DB_WeeklyCopyBlock — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| External_etoro_Customer_BlockedCustomerOperations | BI_DB_dbo (External) | Current copy-trading blocks (production: etoro.Customer.BlockedCustomerOperations) | Tier 1 — SP code confirmed |
| External_etoro_History_BlockedCustomerOperations | BI_DB_dbo (External) | Historical copy-trading blocks (production: etoro.History.BlockedCustomerOperations) | Tier 1 — SP code confirmed |
| general.etoroGeneral_History_GuruCopiers | general | AUM and copier counts at block start/end dates | Tier 1 — SP code confirmed |
| DWH_dbo.V_Liabilities | DWH_dbo | Equity (RealizedEquity + PositionPnL) at block start/end | Tier 1 — SP code confirmed |
| BI_DB_dbo.DWH_CIDs7DaysDeviation | BI_DB_dbo | 7-day deviation → Risk Score at block start/end | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Customer | DWH_dbo | UserName, AccountManagerID | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Manager | DWH_dbo | Manager FirstName + LastName | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| CID | BlockedCustomerOperations | CID | passthrough |
| OperationTypeID | BlockedCustomerOperations | OperationTypeID | passthrough (always 2 = copy block) |
| BlockStart | BlockedCustomerOperations (current: Occurred, history: BlockStart) | Occurred / BlockStart | passthrough — first occurrence for current blocks |
| BlockEnd | BlockedCustomerOperations | BlockEnd | passthrough — 2999-12-31 for currently active blocks |
| BlockReasonID | BlockedCustomerOperations | BlockReasonID | passthrough — filtered to 1 or 2 only |
| IsBlock | — | — | computed — 1 if from current blocks (still active), 0 if from history (resolved) |
| AUMStart | etoroGeneral_History_GuruCopiers | Cash + Investment + PnL | computed — SUM(Cash+Investment+PnL) at BlockStart date |
| AUMEnd | etoroGeneral_History_GuruCopiers | Cash + Investment + PnL | computed — SUM(Cash+Investment+PnL) at BlockEnd date |
| CopiersStart | etoroGeneral_History_GuruCopiers | COUNT(CID) | computed — copier count at BlockStart date |
| CopiersEnd | etoroGeneral_History_GuruCopiers | COUNT(CID) | computed — copier count at BlockEnd date |
| EquityStart | DWH_dbo.V_Liabilities | PositionPnL + RealizedEquity | computed — equity at BlockStart date |
| EquityEnd | DWH_dbo.V_Liabilities | PositionPnL + RealizedEquity | computed — equity at BlockEnd date |
| RiskScoreStart | BI_DB_dbo.DWH_CIDs7DaysDeviation | Deviation | computed — 10-bucket CASE on deviation thresholds at BlockStart |
| RiskScoreEnd | BI_DB_dbo.DWH_CIDs7DaysDeviation | Deviation | computed — 10-bucket CASE on deviation thresholds at BlockEnd |
| BlockReason | — | BlockReasonID | computed — CASE: 1='Requested by BO Admin', 2='High Risk Score' |
| UserName | DWH_dbo.Dim_Customer | UserName | passthrough — customer login username |
| Manager | DWH_dbo.Dim_Manager | FirstName + LastName | computed — concatenation of manager first + last name |
| UserStatus | — | IsBlock | computed — CASE: 1='Blocked', 0='UnBlocked' |
| WeekBlockEnd | — | BlockEnd | computed — 1 if BlockEnd falls within the reporting week, else 0 |
| WeekBlockStart | — | BlockStart | computed — 1 if BlockStart falls within the reporting week, else 0 |
| UpdateDate | — | — | computed — GETDATE() |

## Lineage Notes

- Production source: etoro.Customer.BlockedCustomerOperations (current) + etoro.History.BlockedCustomerOperations (resolved)
- No UC mapping exists — _Not_Migrated.
- UserName inherits Tier 1 from Customer.CustomerStatic via Dim_Customer.
