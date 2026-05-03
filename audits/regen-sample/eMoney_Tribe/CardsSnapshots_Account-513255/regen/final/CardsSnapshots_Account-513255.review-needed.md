# Review Needed: eMoney_Tribe.CardsSnapshots_Account-513255

## Summary

All 25 columns are Tier 3 — no upstream documentation exists for any column. The upstream bundle explicitly confirms no wiki was resolvable for any source. Column descriptions are grounded in DDL, sample data, and SP usage patterns.

## Tier 3 Items Requiring SME Validation

### Account Status Codes
- **AccountStatus**: Values observed are A, S, B, P, R. Descriptions inferred from common patterns (Active, Suspended, Blocked, Pending, Restricted). SME should confirm exact meanings, especially P and R.

### Account Limits and Fee Groups
- **AccountLimitsGroupName / AccountFeeGroupName**: 8 limits groups and corresponding fee groups observed. Mapping between group names and IDs is inferred from sample data. SME should confirm the relationship between limits groups and fee groups and whether additional groups exist.
- **AccountLimitsGroupId / AccountFeeGroupId**: Numeric IDs observed (44=Green, 45=Black, 80=Black EU EUR, 24=Green Fee, 23=Black Fee, 36=Consumer Black EU). SME should validate these mappings.

### Balance Columns
- **AvailableBalance, BlockedAmount, CurrentBalance, ReservedBalance**: All stored as varchar(max). The logical relationship CurrentBalance = AvailableBalance + BlockedAmount is assumed from naming convention. SME should confirm whether ReservedBalance is included in or separate from CurrentBalance.

### FK Relationship
- **@CardsSnapshots_Accounts@Id-350640**: The DWH column links to CardsSnapshots_Accounts-350640, but the production wiki documents @CardsSnapshots@Id-890718 (linking directly to the root snapshot table). Confirm whether the DWH intentionally uses a different parent relationship than production.

### BankAccounts Column
- **BankAccounts**: Consistently empty in sample data. SME should confirm whether this column is populated for any subset of accounts or is deprecated.

## Missing Context

- No Jira tickets or Confluence pages found referencing this specific table.
- The Tribe card provider documentation is external to the codebase; column semantics are inferred from names and sample data.
- The `etr_y`, `etr_ym`, `etr_ymd` columns are partially populated — SME should clarify why some rows have NULL ETL date fields while others are populated.

---

*Generated: 2026-04-30*
