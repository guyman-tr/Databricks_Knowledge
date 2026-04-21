# EXW_dbo.EXW_ETH_FeeData_Blockchain — Review Needed

**Generated**: 2026-04-20 | **Quality**: 8.5/10 | **Phase 16 evaluator**: Pending

## Tier 4 Items (Low-Confidence — Reviewer Verification Needed)

None — all 18 columns are Tier 2 with clear SP traceability to Fivetran source. No upstream wiki exists for the Google Sheets external table.

## Open Questions for Reviewer

1. **SP comment mismatch**: SP header says "Bring Date when User and his Wallet was inserted into Inventory" — this is the WRONG description (copied from SP_New_UsersAndWallets_Inventory). The actual SP loads Etherscan ETH fee data. Confirm if there is a known ticket to fix the SP documentation header.
2. **Data staleness**: Coverage ends at 2024-09-09. The Etherscan → Google Sheets export is manual/semi-automated. Confirm whether new data is actively loaded or if this table is effectively frozen as of September 2024.
3. **`current_value_eth` origin**: The source column `current_value_411_37_eth` is named after a snapshot ETH price ($411.37). This price is clearly outdated — confirm whether this column is still used by SP_EXW_EthFeeSent_Blockchain or can be deprecated.
4. **Two "blank" status values**: The distribution query showed 350,914 blank-string rows and 49,284 additional blank-string rows. This may indicate different character encoding (empty string vs whitespace vs NULL collapse). Confirm with: `SELECT COUNT(*), LEN(status), ASCII(LEFT(status,1)) FROM EXW_ETH_FeeData_Blockchain GROUP BY status`.
5. **`from` always = eToro hot wallet**: All 10 sampled rows show `from = 0x8c4b7870fc7dff2cb1e854858533ceddaf3eebf4`. Confirm whether this is structurally guaranteed (i.e., the Google Sheet always contains only eToro hot wallet transactions) or whether other addresses could appear in future exports.
6. **`method` NULL handling in EXW_EthFeeSent_Blockchain**: SP_EXW_EthFeeSent_Blockchain uses `contract_address IS NOT NULL OR method = 'Create Wallet'` to detect wallet creation. With 47% NULL method rows, confirm that this dual-condition correctly identifies all wallet creation events including pre-2022 records.

## Carry-Forward Notes

- All 18 columns are Tier 2 (Fivetran Google Sheets source, no upstream wiki).
- CAST pattern for numeric strings: `CAST(CAST(col AS FLOAT) AS MONEY)` — required due to scientific notation.
- `[from]` and `[to]` are reserved SQL keywords — bracket-quoting is mandatory.
