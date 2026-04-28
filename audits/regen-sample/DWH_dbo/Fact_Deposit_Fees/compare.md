# Compare — `DWH_dbo.Fact_Deposit_Fees`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +2.35; slop 14 -> 0 (delta -14))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 6.6 | 8.95 | 2.35 |
| Slop hits (`Tier 4 ... inferred`) | 14 | 0 | -14 |
| Element rows | 49 | 47 | -2 |
| Untagged count | 2 | 0 | -2 |
| T1 count | 0 | 0 | +0 |
| T2 count | 20 | 2 | -18 |
| T3 count | 7 | 45 | +38 |
| T4 count | 20 | 0 | -20 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 10 |
| data_evidence | 7 | 8 |
| shape_fidelity | 7 | 9 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `48` | 0.0 | None | None | (see row 24 above) |  |
| `49` | 0.0 | None | None | (see row 40 above) |  |
| `47` | 0.037 | 4 | 2 | Deposit type classification. NULL for most rows in live data. [UNVERIFIED] (Tier 4 - inferred) | ETL load timestamp. Set to `GETDATE()` when the row is inserted by SP_Fact_Deposit_Fees_DL_To_Synapse. Reflects when the row was loaded into the DWH, not when the deposit occurred. (Tier 2 — SP_Fact_D |
| `25` | 0.051 | 2 | 3 | Merchant ID code for the payment processor. Used for settlement reconciliation. (Tier 2 - SP passthrough; BackOffice changelog: MIMOPS-4487) | Customer account status at the time of deposit. Values: Normal, Warning, Deposit Blocked, Trade & MIMO Blocked, Block Deposit & Trading, Copy Block, Blocked Upon Request, Pending Verification, Blocked |
| `12` | 0.06 | 4 | 3 | Value date for accounting purposes — when funds are formally recognized. May differ from DepositTime for wire transfers where settlement takes 1-3 business days. (Tier 4 — Confluence, Deposit issues) | Deposit amount converted to a base currency (USD equivalent). When Currency=USD, equals DepositAmount. For non-USD deposits, reflects the converted value using the applicable exchange rate. (Tier 3 —  |
| `8` | 0.063 | 2 | 2 | Timestamp of last status change. Used to derive ModificationDateID. Primary ETL filter timestamp. (Tier 2 - SP passthrough) | Integer date key in YYYYMMDD format, derived from StatusModificationTime. ETL-computed: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, StatusModificationTime), 0), 112))`. Range: 2021120 |
| `45` | 0.068 | 4 | 3 | First Time Deposit flag. Identifies whether this is the customer's first ever deposit. FTD is a key business event — triggers affiliate commission payouts and customer lifecycle classification. (Tier  | Merchant ID name identifying the payment processing configuration. Combines entity and gateway (e.g. "eToroEU", "eToroUK"). Empty for some older records. (Tier 3 — BackOffice.BillingDepositsPCIVersion |
| `46` | 0.07 | 4 | 3 | Customer acquisition funnel label. From Dictionary.Funnel. [UNVERIFIED] (Tier 4 - inferred) | Merchant ID code for the payment processing configuration. Combines gateway and region (e.g. "CheckoutEUEEA", "WorldpayUK", "PayPalEU", "iDEALEU"). Empty for some older records. (Tier 3 — BackOffice.B |
| `39` | 0.072 | 4 | 3 | Customer tier/level at time of deposit (e.g., Silver, Gold, Platinum). [UNVERIFIED] (Tier 4 - inferred) | Transaction identifier from the external payment provider. Format varies by gateway: PayPal transaction IDs, Checkout pay_ tokens, WorldPay D_ prefixed IDs. (Tier 3 — BackOffice.BillingDepositsPCIVers |
| `28` | 0.082 | 2 | 3 | Payment processor's own transaction reference ID. Used for cross-system reconciliation. (Tier 2 - SP passthrough; MIMOPSA-14499) | Additional payment details. For cards: BinCode prefix (e.g. "BinCode:535585"). For bank transfers: BIC, IBAN, bank name, account holder. Empty for PayPal/eToroMoney. (Tier 3 — BackOffice.BillingDeposi |

## Top issues — regen wiki (per judge)

- [low] `Section 1 / SP code` — SP WHERE clause is entirely commented out — each run inserts ALL staging rows. Wiki mentions 'append-only mode' in Gotchas but Section 1 should state duplicate risk more prominently given the full-reload-without-delete pattern.
- [low] `DepositCollarAmount` — Description states 'Deposit amount converted to a base currency (USD equivalent)' as fact, but this is inferred from data patterns with no upstream documentation. Should be phrased as observed/inferred.
- [low] `Section 1` — Claims '~99.99% Approved in 2024 data' but 2024 data only covers H1 (through June 2024). The percentage scope should match the stated data scope.
- [low] `ExchangeRate` — Description says 'May differ from BaseExchangeRate due to spread or fee adjustments' — this is speculative with no upstream documentation confirming the relationship.
- [info] `Section 8` — Atlassian scan skipped for dormant table. Potential Jira/Confluence context about decommissioning rationale is missing.
