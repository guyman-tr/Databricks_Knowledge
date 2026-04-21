# Review Needed — eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

Generated: 2026-04-21 | Reviewer: Data Engineering / eTM Finance Team

## Tier 4 Items (Requires Verification)

None — all 3 columns are Tier 2 sourced directly from SP_eMoney_Client_Balance_Check_Opening_Balance code.

## Open Questions

1. **Is the SP still being called?** SP_eMoney_ClientBalance calls this SP at line 1002 (`EXEC SP_eMoney_Client_Balance_Check_Opening_Balance @d`). Confirm whether SP_eMoney_ClientBalance is still running on a schedule. The table has 0 rows as of 2026-04-21.

2. **Table currently empty**: As with eMoney_Client_Balance_Check_Exceptions_Gap, 0 rows could mean:
   - (a) Opening balance checks are consistently passing, OR
   - (b) The SP is no longer being called
   Verification needed: check ADF/Synapse pipeline for SP_eMoney_ClientBalance schedule.

3. **Column name typo**: `Openning_Balance_Gap` has a double 'n'. This is the actual DDL column name. Confirm whether this should be corrected in a future ALTER TABLE migration, or preserved for backward compatibility.

4. **OpeningBalance vs OpeningBalanceByCB**: The gap measures `OpeningBalanceByCB − OpeningBalance`. What exactly do these two values represent? Verification with the eTM finance team would clarify whether `OpeningBalanceByCB` is more reliable than `OpeningBalance` or vice versa.

## Reviewer Corrections

*[To be filled by reviewer]*

## Flagged Risks

- `OpeningBalanceGAP` formula documentation is inferred from SP_eMoney_ClientBalance code; the precise business meaning should be verified with the eTM finance/data team.
- The typo "Openning" in the column name is a known issue and has been documented explicitly.
