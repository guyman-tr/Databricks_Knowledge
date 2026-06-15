---
object_fqn: main.billing.bronze_etoro_billing_vwithdrawtofunding
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_vwithdrawtofunding
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 33
row_count: null
generated_at: '2026-05-18T10:58:39Z'
upstreams:
- etoro.Billing.vWithdrawToFunding
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md
  source_database: etoro
  source_schema: Billing
  source_table: vWithdrawToFunding
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/vWithdrawToFunding
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 30
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 3
  unverified_columns: 0
---

# bronze_etoro_billing_vwithdrawtofunding

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.vWithdrawToFunding`). 30 of 33 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_vwithdrawtofunding` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 33 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Sep 25 11:15:20 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.vWithdrawToFunding` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md`.

- Lake path: `Bronze/etoro/Billing/vWithdrawToFunding`
- Copy strategy: `Merge`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.vWithdrawToFunding`
- 30 of 33 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | INT | YES | FK to Billing.Withdraw. The parent withdrawal request. One WithdrawID can have multiple payment legs (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 1 | FundingID | INT | YES | FK to Billing.Funding. The payment instrument used for this withdrawal leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 2 | CashoutStatusID | INT | YES | Current status of this withdrawal leg. References Dictionary.CashoutStatus. 3=Processed (money sent). NOT filtered in this view - all statuses returned (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 3 | ProcessCurrencyID | INT | YES | Currency in which the withdrawal was processed. References Dictionary.Currency (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 4 | ManagerID | INT | YES | Assigned manager/agent ID for manual review of this withdrawal leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 5 | ExchangeRate | DECIMAL | YES | Exchange rate applied to convert the withdrawal to USD. The customer-facing rate including FX markup (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 6 | Amount | DECIMAL | YES | Withdrawal leg amount in ProcessCurrencyID (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 7 | ModificationDate | TIMESTAMP | YES | Last modification timestamp of this withdrawal leg record (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 8 | ID | INT | YES | PK of Billing.WithdrawToFunding. Unique identifier for this withdrawal payment leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 9 | DepositID | INT | YES | FK to Billing.Deposit. Set when the withdrawal is a refund of a specific deposit (e.g., credit card refund must go back to original deposit's card) (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 10 | RefundAmountInDepositCurrency | DECIMAL | YES | The USD-equivalent amount of this withdrawal leg. Used in FX fee calculations in GetWithdrawToFundingFXFeeAmount (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 11 | CashoutTypeID | INT | YES | Type of cashout/withdrawal. References Dictionary.CashoutType (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 12 | VerificationCode | STRING | YES | Verification/confirmation code for this withdrawal leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 13 | ProcessorValueDate | TIMESTAMP | YES | Value date from the payment processor for this leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 14 | MatchStatusID | INT | YES | Reconciliation matching status (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 15 | DepotID | INT | YES | FK to Billing.Depot. Gateway/depot that processed this withdrawal leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 16 | BaseExchangeRate | DECIMAL | YES | Market/interbank exchange rate (without FX markup) at time of processing. Used with ExchangeRate to compute FX fee spread (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 17 | CashoutModeID | INT | YES | Mode of the cashout operation. References Dictionary.CashoutMode (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 18 | AutoPaymentStartDate | TIMESTAMP | YES | Start date of the automatic payment schedule (for recurring withdrawals) (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 19 | ProtocolMIDSettingsID | INT | YES | FK to Billing.ProtocolMIDSettings. The specific MID configuration used for this withdrawal (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 20 | ExchangeFee | INT | YES | Raw FX fee value in the rate's decimal form. Used in BaseExchangeRate derivation (WireTransfer path): BaseRate = ExchangeRate - ExchangeFee/10^Multiplier (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 21 | CreationDate | TIMESTAMP | YES | Timestamp when this withdrawal leg was created (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 22 | AdditionalInformation | STRING | YES | Free-text additional context for this withdrawal leg (notes, processor responses) (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 23 | VendorCode | STRING | YES | Vendor/processor-specific reference code for this withdrawal (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 24 | MerchantAccountID | INT | YES | FK to merchant account used for processing (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 25 | SchemeId | STRING | YES | Payment scheme identifier (e.g., Visa, Mastercard scheme for card withdrawals) (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 26 | ResponseID | INT | YES | Payment processor response identifier for this withdrawal leg (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 27 | RequestExecuteEntryMethodId | INT | YES | Entry method used when this withdrawal request was executed (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 28 | etr_y | STRING | YES | Source: etoro.Billing.vWithdrawToFunding.etr_y. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 29 | etr_ym | STRING | YES | Source: etoro.Billing.vWithdrawToFunding.etr_ym. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 30 | etr_ymd | STRING | YES | Source: etoro.Billing.vWithdrawToFunding.etr_ymd. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 31 | ExchangeFeeInUSD | DECIMAL | YES | FX fee expressed in USD. Added 17/09/2024 by Ran Ovadia. Part of the 2024 FX fee transparency initiative. NULL for pre-2024 records (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |
| 32 | ExchangeFeeInPercentage | DECIMAL | YES | FX fee expressed as a percentage of the withdrawal amount. Added 17/09/2024. NULL for pre-2024 records (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.vWithdrawToFunding` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.vWithdrawToFunding
        │
        ▼
main.billing.bronze_etoro_billing_vwithdrawtofunding   ←── this object
        │
        ▼
main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| WithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| CashoutStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ProcessCurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| DepositID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| RefundAmountInDepositCurrency | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| CashoutTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| VerificationCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ProcessorValueDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| MatchStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| DepotID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| BaseExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| CashoutModeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| AutoPaymentStartDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ProtocolMIDSettingsID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ExchangeFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| CreationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| AdditionalInformation | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| VendorCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| MerchantAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| SchemeId | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ResponseID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| RequestExecuteEntryMethodId | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` but column `etr_y` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` but column `etr_ym` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` but column `etr_ymd` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ExchangeFeeInUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |
| ExchangeFeeInPercentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.vWithdrawToFunding.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.vWithdrawToFunding) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 30 T1, 0 T2, 0 T3, 0 T4, 3 T5, 0 U | Elements: 33/33 | Source: bronze_tier1_inheritance*
