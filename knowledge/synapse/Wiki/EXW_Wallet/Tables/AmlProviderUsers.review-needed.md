# EXW_Wallet.AmlProviderUsers — Review Needed

Generated: 2026-04-30 | Pipeline: DWH Semantic Doc

## 1. Tier 3 Columns (no production source)

Five columns (etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date) are Generic Pipeline infrastructure columns not present in the production source table. Descriptions are grounded in DDL structure and live data observation. A domain expert could confirm:
- Whether etr_y/etr_ym/etr_ymd are derived from `Occurred` or from the pipeline extraction timestamp
- Why etr_* columns are NULL for AmlProviderId=1 but populated for providers 3 and 4
- Why SynapseUpdateDate is populated only for AmlProviderId=1

## 2. Type Narrowing Risk

- **Gcid**: Production type is `bigint`, Synapse landing type is `int`. If any customer GCID exceeds 2,147,483,647, data truncation would occur silently. Current max Gcid in the table should be verified against the int range.

## 3. No Uniqueness Enforcement

The production table has a unique constraint on (AmlProviderId, Gcid). The Synapse landing table (HEAP, no constraints) does not enforce this. With Append strategy, duplicate rows could accumulate if the Generic Pipeline replays data. Confirm whether deduplication is handled downstream in SP_EXW_AMLProviderID (current SP uses date-range DELETE+INSERT which would not deduplicate within a day).

## 4. Upstream Wiki Discovery

The harness marked this object with `_no_upstream_found.txt`, but the writer process independently located the upstream wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlProviderUsers.md`. The harness upstream resolution may need to be updated to include the CryptoDBs/WalletDB routing path for EXW_Wallet schema objects.

## 5. Distribution Key Skew

HASH(AmlProviderId) with only 3 distinct values (1, 3, 4) causes severe distribution skew (81% of rows in one bucket). For a 207K-row table this is acceptable, but if the table grows significantly, consider HASH(Gcid) or ROUND_ROBIN.
