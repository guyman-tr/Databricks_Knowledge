# SQL-grounded column audit

Total rows audited: 19

## Compat verdict distribution
- **UNVERIFIABLE**: 16
- **PASS**: 3

## Raw SQL verdict distribution
- **UNVERIFIABLE**: 11
- **EXTRACTOR**: 5
- **VERIFIED**: 3

---

## CONTRADICTED rows


## UNVERIFIABLE rows (skipped by apply)

- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Compliance_Surveillance_Snapshot.md:52` IsCopy — The SQL is a passthrough from #Snapshot with no visible CASE/logic defining IsCopy, so the MirrorID derivation and distribution stats cannot be verified from the provided SQL alone.
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.md:162` Amount — The SQL is a simple passthrough (r.Amount from #revenue) whose upstream construction—UNION/GROUP aggregation, TVF monetary columns, sign conventions—is not visible in the provided snippets.
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Deposits.md:102` Amount — The SQL visible here is a simple passthrough of a.[Amount] with no CASE expression; the claimed CASE capping may exist further upstream in BI_DB_Deposits_updates but is not visible in the provided SQL
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Deposit_Reversals_PIPs.md:106` Amount — The SQL subquery aliased as T is truncated, so the claimed upstream source External_etoro_Billing_DepositRollbackTracking.RollbackAmountInCurrency cannot be confirmed or denied from the visible SQL.
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_EY_Audit_BO_Deposits_With_PIPs.md:151` Amount — The SQL shows a passthrough of dwc.Amount from #allDepsWithCBValid with no visible CAST to DECIMAL(16,2); the CAST may occur upstream in the temp table population or in the stored procedure but is not
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_EY_Audit_Cashouts.md:148` Amount — The SQL is a simple passthrough (m.Amount from #COsWithRefunds) and no visible expression confirms or contradicts the upstream claims about History.Credit, Fact_CustomerAction, PositionOpen cent-to-do
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_LargeCashoutReport.md:157` Amount — The SQL is a passthrough (t.Amount from #temp) whose upstream population logic is not visible, so claims about casting from money type, sourcing from Billing.Withdraw, and the ≥$20K filter cannot be c
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Operations_Monthly_KPIs_Affiliates.md:144` Amount — The SQL only shows Amount selected from #BillingWithdrawAll; we cannot verify the claimed mapping to Amount_Withdraw in Fact_BillingWithdraw or the stated range/average since the temp table's upstream
- `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Execution_Slippage.md:128` IsBuy — The SQL shows IsBuy as a bare passthrough column from #ExecutionRate / CopyFromLake.PriceLog_History_CurrencyPrice with no visible CASE logic; the description's specific claim about inverting HP.IsBuy
- `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Fails_PI.md:124` Amount — The SQL passes through pf.Amount without any currency conversion or unit annotation, so the claim that it is 'in USD' cannot be verified from the visible SQL alone.
- `knowledge/synapse/Wiki/DWH_dbo/Views/VU_FactBilling_ForBigQuery.md:58` Amount — The view simply passes through [Amount] with no transformation visible; the wiki documents upstream ETL capping logic that cannot be confirmed or denied from this SELECT alone.

## LOCATOR/EXTRACTOR failures

- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Compliance_Surveillance_ShortTermTrades.md:50` IsCopy — EXTRACTOR: extractor: INSERT col list has 33 entries but SELECT has only 1
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL_UK_Custody.md:110` Amount — EXTRACTOR: extractor: no INSERT INTO BI_DB_PositionPnL_UK_Custody found in SP body
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL_UK_Custody.md:114` IsBuy — EXTRACTOR: extractor: no INSERT INTO BI_DB_PositionPnL_UK_Custody found in SP body
- `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Daily_Slippage_Positions_TriggerVSReceived.md:123` IsBuy — EXTRACTOR: extractor: could not parse INSERT-side SELECT statement
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md:147` Amount — EXTRACTOR: extractor: no INSERT INTO Fact_CustomerAction found in SP body
