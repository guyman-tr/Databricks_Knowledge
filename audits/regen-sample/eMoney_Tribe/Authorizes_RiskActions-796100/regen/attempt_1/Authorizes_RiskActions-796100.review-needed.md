# Review Needed: eMoney_Tribe.Authorizes_RiskActions-796100

## Summary

All 15 columns are Tier 3 (grounded in DDL + live data + SP code). No upstream wiki with column-level descriptions was available for Tier 1 inheritance. The production wiki (BankingDBs/FiatDwhDB) documents only 4 generic metadata columns (@Created, @Id, @Authorizes@Id-837045, Created) with minimal descriptions, and uses a different FK column name than the Synapse version.

## Items Requiring Human Review

### 1. Newer Columns Not Consumed by ETL

- **ChangeAccountStatusToReceiveOnly** and **ChangeAccountStatusToSpendOnly** exist in the DDL but are not consumed by `SP_eMoney_Reconciliation_ETLs`. All observed values are empty strings. Confirm whether these columns are being populated by the Tribe platform and whether the SP should be updated to include them.

### 2. NotifyCardholderBySendingTAIsNotification Behavior

- Column name suggests a TAIs (Transaction Alert) notification is sent. Confirm with eMoney team whether "TAIs" refers to a specific Tribe notification system and what the cardholder experience is when this flag = '1'.

### 3. RejectTransaction vs ResponseCode Relationship

- The SP passes RejectTransaction through to ETL_Authorize, but the parent table `Authorizes_Authorize-312243` also has ResponseCode. Clarify with eMoney team: does RejectTransaction='1' always correlate with a non-'00' ResponseCode, or can an authorization be approved at the network level but rejected by Tribe's risk engine?

### 4. Data Starts 2023-12-20

- The parent table `Authorizes_Authorize-312243` has data from 2021-09-05, but this risk actions child table only starts from 2023-12-20. This may indicate the risk actions feature was added to the Tribe export later. Confirm with eMoney team whether risk action data before 2023-12 exists elsewhere or was not captured.

### 5. Production Source Confidence

- **Production Source**: FiatDwhDB.Tribe.Authorizes_RiskActions-796100 (prod-banking). Confirmed via Generic Pipeline mapping. The production wiki is sparse -- the FiatDwhDB wiki documents only 4 structural columns. Richer upstream documentation may exist in the Tribe Payments platform documentation outside the repo.

---

*Generated: 2026-04-30 | Review items: 5*
