# Column Lineage: main.bi_output.v_external_france_wealth_contracts_transactions

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.v_external_france_wealth_contracts_transactions` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\v_external_france_wealth_contracts_transactions.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\v_external_france_wealth_contracts_transactions.json` (rows: 13, mismatches: 0) |
| **Primary upstream** | `main.bi_db.bronze_wealth_france_wealth_france_users_data` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.bronze_wealth_france_wealth_france_users_data` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_wealth_france_wealth_france_users_data.md` |

## Lineage Chain

```
main.bi_db.bronze_wealth_france_wealth_france_users_data   ←── primary upstream
        │
        ▼
main.bi_output.v_external_france_wealth_contracts_transactions   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `ClientId` | `—` | `cliendId` | `join_enriched` | — | data.cliendId AS ClientId |
| 2 | `contractNo` | `—` | `contractNo` | `join_enriched` | — | data.contractNo AS contractNo |
| 3 | `netAmount` | `—` | `netAmount` | `cast` | — | cast to DOUBLE — CAST(data.netAmount AS DOUBLE) AS netAmount |
| 4 | `taxAmount` | `—` | `taxAmount` | `cast` | — | cast to DOUBLE — CAST(data.taxAmount AS DOUBLE) AS taxAmount |
| 5 | `grossAmount` | `—` | `grossAmount` | `cast` | — | cast to DOUBLE — CAST(data.grossAmount AS DOUBLE) AS grossAmount |
| 6 | `introducerCommission` | `—` | `introducerCommission` | `cast` | — | cast to DOUBLE — CAST(data.introducerCommission AS DOUBLE) AS introducerCommission |
| 7 | `taxAmountExcludingWithholdingTaxes` | `—` | `taxAmountExcludingWithholdingTaxes` | `cast` | — | cast to DOUBLE — CAST(data.taxAmountExcludingWithholdingTaxes AS DOUBLE) AS taxAmountExcludingWithholdingTaxes |
| 8 | `creationDate` | `—` | `—` | `unknown` | — | TO_DATE(data.creationDate) AS creationDate |
| 9 | `effectiveDate` | `—` | `—` | `unknown` | — | TO_DATE(data.effectiveDate) AS effectiveDate |
| 10 | `transactionId` | `—` | `transactionId` | `join_enriched` | — | data.transactionId AS transactionId |
| 11 | `transactionType` | `—` | `transactionType` | `join_enriched` | — | data.transactionType AS transactionType |
| 12 | `referenceCurrency` | `—` | `referenceCurrency` | `join_enriched` | — | data.referenceCurrency AS referenceCurrency |
| 13 | `transactionStatus` | `—` | `transactionStatus` | `join_enriched` | — | data.transactionStatus AS transactionStatus |

## Cross-check vs system.access.column_lineage

- Total target columns: **13**
- OK: **13**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **6**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**
