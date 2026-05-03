# Review Needed: BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs

## 1. Tier 3 Columns — No Upstream Wiki

The following 7 columns are sourced from `External_etoro_Billing_CashoutRollbackTracking` (production: `Billing.CashoutRollbackTracking`) which has no upstream wiki documentation. Descriptions are inferred from SP code and column names.

| Column | Current Tier | Review Note |
|--------|-------------|-------------|
| CID | Tier 3 | Customer ID from CashoutRollbackTracking. Confirmed as RealCID in SP context. Needs upstream wiki for authoritative description. |
| DepositWithdrawID | Tier 3 | WithdrawID from CashoutRollbackTracking. Rename confirmed in SP. |
| Occurred | Tier 3 | ModificationDate from CashoutRollbackTracking. Timestamp semantics (status change time vs original event time) should be confirmed with domain owner. |
| Amount | Tier 3 | RollbackAmountInCurrency from CashoutRollbackTracking. Sign convention (can be negative in live data) should be confirmed — is negative Amount meaningful or a data quality issue? |
| ExchangeRate | Tier 3 | ExchangeRate from CashoutRollbackTracking. Unclear if this is the rate at rollback time or original withdrawal time. |
| AmountUSD | Tier 3 | RollbackAmountInUSD from CashoutRollbackTracking. Same sign convention question as Amount. |
| ExternalTransactionID | Tier 3 | ReferenceNumber from CashoutRollbackTracking. Provider reference number for the rollback transaction. |

## 2. SP Noted as Temporary

The SP header comment states: "this is a temporary solution to bring the cashout rollback pips into finance... the end game of this should be to receive in views from DBAs on production." This means:
- Hardcoded business rules (RollbackReasonID mapping, MID resolution cascade, PIPs formulas) may diverge from production over time.
- The table should be monitored for consistency against BackOffice rollback reports.

## 3. MID Resolution Complexity

The MIDValue and Entity columns use a complex multi-source cascade with depot-specific branching. The logic replicates production functions (`Billing.GetMerchantDetailsForOneAccountByDepotOnly`, `BackOffice.GetMerchantDetails`, `BackOffice.CalculateDepositPIPsUSD`) that could change upstream without this SP being updated.

**Action**: Periodically compare MIDValue/Entity output against BackOffice reports to detect drift.

## 4. Hardcoded Columns

- **CreditTypeID = 33**: Hardcoded. If Dictionary.CreditType adds/changes the rollback type code, this SP will not reflect it.
- **CardCategory, BinCountry, MOPCountry = 'NA'**: Could be populated from Fact_BillingWithdraw data (CardCategory and BinCountryIDAsInteger are available) but are currently hardcoded. Consider enriching if these attributes are needed for rollback analysis.

## 5. UC Target

No UC target mapping found for this table. Confirm whether this table should be exported to Unity Catalog or remains Synapse-only.

---

*Review generated: 2026-04-30*
