---
object: EXW_dbo.EXW_Coin_Transfer_Allowed_Country
type: Table
generated: 2026-04-20
phase: review-needed
---

# Review Needed — EXW_dbo.EXW_Coin_Transfer_Allowed_Country

## Tier 4 Items (Best Guess — No Code or Wiki Evidence)

None. All 18 columns are Tier 1 (CryptoTypes upstream wiki) or Tier 2 (SP code analysis + MCP live data). No Tier 4 assignments.

---

## Open Questions for Reviewers

### Q1 — ResourceId=5903 Hardcoded in SP

**Observation**: The SP filters `EXW_Settings.Resources` with `ResourceId=5903` for the "redeem/allow" resource family. The constant is hardcoded — no lookup or variable is used.
**Question**: Is ResourceId=5903 stable? Could a Synapse migration or EXW_Settings platform upgrade reassign this ResourceId? If so, the SP would silently pull from the wrong resource family, producing an incorrect eligibility matrix. Is there documentation of this ResourceId in a settings registry?

### Q2 — `[Coin Transfer Allowed]` Column Name Contains a Space

**Observation**: The column name `[Coin Transfer Allowed]` contains spaces and requires bracket quoting in all SQL references. This is inconsistent with the rest of the EXW_dbo schema (which uses CamelCase or snake_case column names without spaces).
**Question**: Is this an intentional design choice (e.g., for readability in Excel reports)? Are there known cases where downstream consumers fail to quote this column correctly?

### Q3 — `SelectedValue` = 'true'/'false' (String Booleans)

**Observation**: The eligibility flag is stored as 'true'/'false' strings in EXW_Settings and transformed to 0/1 integers in `[Coin Transfer Allowed]`. The SP uses `LOWER(f.SelectedValue)='true'` for the CASE expression.
**Question**: Are there known SelectedValue values other than 'true'/'false' in the EXW_Settings.SystemRestrictions table for ResourceId=5903? If a settings admin accidentally enters 'True', 'TRUE', 'yes', or '1', the LOWER() normalization handles case but not different true-values. Has this been a source of misconfiguration incidents?

### Q4 — `redeem/allow/crypto` vs `redeem/allow/{InstrumentId}` Precedence

**Observation**: The SP builds two parallel ResourceName keys per crypto: a generic 'crypto' key and an instrument-specific key (e.g., 'redeem/allow/100000' for BTC). Both can match for the same (country, playerLevel, regulation, crypto) combination. The max-weight resolution in `#maxvalue1` and `#maxvalue2` handles this, but the logic uses two separate temp tables joined with LEFT JOIN coalesce.
**Question**: Is there a documented rule for when an instrument-specific setting should override the generic 'crypto' setting? For example, if BTC is allowed globally (crypto=true) but specifically blocked for Diamond level in the UK (redeem/allow/100000=false for diamond_united_kingdom), which rule wins? The answer depends on RestrictionWeight values in EXW_Settings.

### Q5 — US State-Level Eligibility (RegionByIP_ID)

**Column**: StateProvince (#17), RegionByIP_ID (#18)
**Observation**: For CountryID=219 (United States), the table includes rows per state from `DWH_dbo.Dim_State_and_Province`. The EXW platform uses `RegionByIP_ID` to route US users to state-appropriate rules.
**Question**: Are RegionByIP_ID values stable and maintained in sync between `Dim_State_and_Province` and the EXW platform's IP-geolocation service? If a user's detected IP region doesn't match any `RegionByIP_ID` in this table, does the platform fall back to country-level rules (where RegionByIP_ID=0)?

### Q6 — SP_EXW_CompensationClosingCountries References This Table

**Observation**: At line 2741 of SP_EXW_CompensationClosingCountries: `SELECT * FROM EXW_dbo.EXW_Coin_Transfer_Allowed_Country ectac`. The context at that line appears to be building a temp table that references this table's data.
**Question**: What specific columns from `EXW_Coin_Transfer_Allowed_Country` does SP_EXW_CompensationClosingCountries use? Is it using `[Coin Transfer Allowed]` to filter eligible GCIDs, or is it using `SelectedValue` / `TagType` for other purposes? Understanding this dependency is important for change impact analysis.

---

## Cross-Object Consistency Notes

### Note 1 — EXW_WalletElligibleCountries as Sibling

`EXW_WalletElligibleCountries` is populated by the same SP (`SP_EXW_WalletElligibleCountries`) but for a different resource (wallet open/close status). Both tables use the same tag resolution logic. The wiki documents this sibling relationship. CONSISTENT with SP code.

### Note 2 — CryptoTypes T1 Source

InstrumentID, CryptoID, and Crypto are T1 from `EXW_Wallet.CryptoTypes` (which mirrors `Wallet.CryptoTypes` from WalletDB). The T1 descriptions are copied verbatim from `CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.CryptoTypes.md`. CONSISTENT with upstream wiki.

### Note 3 — SP Filter: IsActive=1 AND DisplayName NOT LIKE 'eToro%'

The SP filters EXW_Wallet.CryptoTypes with `IsActive=1` and `DisplayName NOT LIKE 'eToro%'` before building the combination matrix. This means internal eToro crypto types (if any) are excluded from the eligibility matrix. CONSISTENT with the SP code (lines 357–369).

---

## Known Limitations in This Wiki

1. **EXW_Settings schema undocumented**: The source tables (Resources, SystemRestrictions, Tags) have no upstream wiki. The semantics of TagType values and RestrictionWeight ranges are inferred solely from SP code analysis.
2. **SP_EXW_CompensationClosingCountries reference unclear**: The downstream reference to this table at line 2741 of that SP was not fully traced in this wiki session (SP was too large to read fully). The exact use case requires further investigation.
3. **No historical eligibility tracking**: Since the table is rebuilt entirely on each SP run, there is no way to determine what eligibility was in place on a prior date. Historical analysis requires logs or snapshots external to this table.
