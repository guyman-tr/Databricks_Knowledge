# Review Needed: eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239

## 1. Tier 3 Column Coverage

107 of 112 columns are Tier 3 — no upstream column-level wiki exists. The upstream production source (FiatDwhDB.Tribe) has no resolvable wiki in the bundle. All column descriptions are grounded in DDL structure, SP code analysis (SP_eMoney_Reconciliation_ETLs), and live data sampling.

**Action needed**: When an upstream production wiki for FiatDwhDB.Tribe is created and added to the bundle, re-run this wiki to promote Tier 3 columns to Tier 1.

## 2. TransactionCode Value Mapping

TransactionCode values (2=POS, 3=ATM) are inferred from sampled data. A complete mapping of all TransactionCode values used by the Tribe platform would improve documentation quality.

**Action needed**: Confirm the full TransactionCode value set with the eMoney/Tribe data team.

## 3. FeeGroupId / FeeGroupName Mapping

FeeGroupId values "23" and "24" map to "eToro Black" and "eToro Green" in sampled data. Confirm whether additional fee tiers exist (e.g., Silver, Platinum, Diamond).

## 4. SettlementFlag Values

SettlementFlag shows values "8" and "0" in sampled data. The business meaning of these codes is unclear from DDL and SP code alone.

**Action needed**: Clarify SettlementFlag value semantics with the payments team.

## 5. CardType Single Value

CardType shows "1" exclusively in sampled data. Confirm whether this represents "Debit" and whether other CardType values are possible.

## 6. Duplicate Indexes

Two NCIs on `@Id` exist (ClusteredIndex_ST_637239 and idx_637239_Id). One may be redundant and could be removed for storage optimization.

## 7. All-VARCHAR Schema

All 107 business columns are `varchar(max)`. This prevents type-safe queries and efficient storage. Consider typed staging/ETL views if downstream consumers need numeric or date operations.

## 8. PCI Sensitivity

`CardNumber` contains masked card data (last 4 digits visible). `BankAccountId` may contain sensitive financial identifiers. Review PII tagging requirements for UC Bronze export.

---

*Generated: 2026-04-30*
*Object: eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239*
