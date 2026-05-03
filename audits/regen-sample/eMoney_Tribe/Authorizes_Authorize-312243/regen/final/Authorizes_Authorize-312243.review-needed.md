# Review Needed: eMoney_Tribe.Authorizes_Authorize-312243

## Summary

All 81 columns are Tier 3 (grounded in DDL + live data + SP code). No upstream production wiki exists for FiatDwhDB.Tribe — the `_no_upstream_found.txt` marker is present. Every description is derived from DDL structure, live data sampling (Phase 2), distribution analysis (Phase 3), and SP code reading (Phase 9).

## Items for Human Review

### 1. Column Count Discrepancy (DDL vs Elements)

- DDL defines 80 columns but the table has a duplicate column situation: `PosDatDe61` (legacy typo) and `PosDataDe61` (corrected name) are separate DDL columns. Both are documented as distinct elements (#62 and #80). The Elements table has 81 rows because the DDL has 81 CREATE TABLE column definitions (counting the duplicate PosDataDe61 entry which appears at position 80, distinct from PosDatDe61 at position 62).

### 2. No Upstream Wiki Available

- Production source is `FiatDwhDB.Tribe` on prod-banking server. No documentation exists in any upstream wiki repository (DB_Schema, ExperianceDBs, CryptoDBs, BankingDBs, PaymentsDBs, ComplianceDBs). All descriptions are based on column names, live data patterns, and ISO 8583 standard field semantics.
- **Action**: If Tribe Payments provides an API data dictionary, column descriptions should be upgraded to Tier 1 with verbatim vendor definitions.

### 3. PII Considerations

- `CardNumber` is masked at source (last 4 digits only) — low PII risk.
- `HolderId` and `AccountId` are Tribe internal IDs — may link to individuals when cross-referenced with cardholder tables.
- `MerchantName` contains merchant names and locations in freeform text.

### 4. Schema Evolution Columns

- `PosDataExtendedDe61`, `Created`, `PosDataDe61`, `TokenizedRequest` — all added in later schema revisions and are NULL on older rows. The boundary date for when these columns started being populated should be confirmed (estimated ~2024 based on sample data).

### 5. Single Network Observation

- All sampled data shows Network = 'Visa'. If Mastercard or other networks are expected in the future, the documentation should be updated.

### 6. etr_y / etr_ym / etr_ymd Partition Keys

- These ETL partition key columns are NULL on older rows. Their exact population start date and purpose (Generic Pipeline internal vs. business use) should be confirmed with the eMoney Data Analytics team.
