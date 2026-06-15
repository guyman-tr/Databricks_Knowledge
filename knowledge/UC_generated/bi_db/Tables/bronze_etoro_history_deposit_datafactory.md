---
object_fqn: main.bi_db.bronze_etoro_history_deposit_datafactory
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_deposit_datafactory
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 46
row_count: null
generated_at: '2026-05-19T12:12:47Z'
upstreams:
- etoro.History.Deposit_DataFactory
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md
  source_database: etoro
  source_schema: History
  source_table: Deposit_DataFactory
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/Deposit_DataFactory
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 43
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_etoro_history_deposit_datafactory

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.Deposit_DataFactory`). 43 of 46 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_deposit_datafactory` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 46 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 19 12:35:24 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.Deposit_DataFactory` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md`.

- Lake path: `Bronze/etoro/History/Deposit_DataFactory`
- Copy strategy: `Append`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.Deposit_DataFactory`
- 43 of 46 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Occurred | TIMESTAMP | YES | UTC timestamp of this deposit event. The base table CLUSTERED index sorts on (Occurred, DepositID). Primary time axis for BI time-series analysis (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 1 | DepositID | INT | YES | Identifier of the deposit record being audited. One DepositID appears multiple times as the deposit progresses through status stages. FK to Billing.Deposit (implicit) (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 2 | CID | INT | YES | Customer who made the deposit. Filtered: CID=43496401 excluded (spam account). Central key for per-customer deposit analytics (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 3 | FundingID | INT | YES | Specific payment instrument used (credit card, bank account, PayPal, etc.). References Billing.Funding (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 4 | CurrencyID | INT | YES | Currency of the deposit amount. Live data shows 2=EUR, 3=other currencies. References Dictionary.Currency (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 5 | PaymentStatusID | INT | YES | Deposit processing state at this event. 1=New, 2=Approved, 5=InProcess, 13=Failed, 11=Chargeback, 36=PendingReview. The primary "what changed" field in the event log. (Source: Dictionary.PaymentStatus) (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 6 | ManagerID | INT | YES | Back-office manager who manually triggered this deposit state change. NULL for automated payment processor events (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 7 | RiskManagementStatusID | INT | YES | Risk engine evaluation result for this deposit event. Non-null when a risk rule was applied (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 8 | Amount | DECIMAL | YES | Gross deposit amount in the deposit's currency before fees/commissions. The face value requested by the customer (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 9 | ExchangeRate | DECIMAL | YES | Exchange rate applied to convert the deposit currency to the account's base currency. NULL if same-currency deposit (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 10 | PaymentDate | TIMESTAMP | YES | Payment provider's confirmed transaction date. May differ from Occurred when provider confirmation is delayed (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 11 | ModificationDate | TIMESTAMP | YES | Timestamp of the last modification to the source Billing.Deposit record at the time this history row was captured (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 12 | TransactionID | STRING | YES | Short 6-character internal transaction reference code. Legacy field from early eToro (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 13 | IPAddress | DECIMAL | YES | Customer's IP address at deposit time, stored as a numeric integer (legacy IP-as-integer format). Used for fraud geo-analysis (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 14 | Approved | BOOLEAN | YES | Legacy approval flag. 1=deposit was approved. Predates the full PaymentStatusID system; maintained for backward compatibility (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 15 | Commission | DECIMAL | YES | Platform commission (fee) deducted from the deposit. 0 for most standard deposits (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 16 | ClearingHouseEffectiveDate | TIMESTAMP | YES | Date the clearing house (bank) recognized the transaction. May lag PaymentDate by 1-3 business days for wire transfers (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 17 | OldPaymentID | INT | YES | Reference to a superseded/replaced payment record. Used when a deposit is re-submitted from a legacy payment system (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 18 | IsFTD | BOOLEAN | YES | First-Time Deposit flag. 1=this event was the customer's qualifying first deposit. Critical for marketing attribution, bonus eligibility, and KYC compliance triggers (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 19 | ProcessorValueDate | TIMESTAMP | YES | Value date assigned by the payment processor - when funds become available to eToro. Important for treasury/cash management (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 20 | RefundVerificationCode | STRING | YES | Verification code required to authorize a refund. Security measure ensuring refunds match the original deposit (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 21 | DepotID | INT | YES | Depot/vault identifier for the funds. Used in multi-entity or multi-jurisdiction fund segregation. NULL for standard retail deposits (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 22 | MatchStatusID | INT | YES | Wire transfer matching status. For bank wire deposits where the incoming transfer must be matched to the deposit request (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 23 | FunnelID | INT | YES | Marketing/acquisition funnel the customer was on at deposit time. Used for conversion analytics and campaign ROI (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 24 | Code | STRING | YES | Promotional or campaign code applied at deposit time. NULL for no-promo deposits (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 25 | ExTransactionID | STRING | YES | External transaction ID from the payment provider. Used for provider-side reconciliation and dispute filing (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 26 | CampaignCodeID | INT | YES | Campaign code that qualified this deposit for a bonus. NULL if deposit was not part of a bonus campaign (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 27 | BonusStatusID | INT | YES | Processing state of the bonus associated with this deposit. Tracks whether bonus was awarded, failed, or pending (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 28 | BonusAmount | DECIMAL | YES | Bonus credit amount granted based on this deposit. NULL if no bonus was applicable (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 29 | BonusErrorCode | INT | YES | Error code when bonus processing failed. 1=Campaign inactive, 2=Already received, 3=Max users reached, 4=Max amount reached, 5=User cap reached, 6=Bonus max reached. NULL=no error (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 30 | SessionID | LONG | YES | Web/API session ID at deposit submission time. Links to session audit tables for end-to-end request tracing (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 31 | DepositTypeID | INT | YES | Deposit transaction type. Live data shows 5=RecurringInvestment. 1=Regular, 2=CvvFree, 3=Recurring, 4=MoneyTransfer, 5=RecurringInvestment. (Source: Dictionary.DepositType) (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 32 | ID | LONG | YES | Surrogate PK for this audit event row. Auto-incrementing - higher ID = later event. Not the same as DepositID (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 33 | DRStatusID | INT | YES | Dispute/Reversal status. 0=no dispute. Non-zero=chargeback or reversal process active (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 34 | DRDate | TIMESTAMP | YES | Date when the dispute/reversal was opened or last updated. NULL when DRStatusID=0 (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 35 | ProtocolMIDSettingsID | INT | YES | Merchant ID configuration at the time of this deposit. Identifies which payment gateway MID processed this deposit. References History.ProtocolMIDSettings (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 36 | ExchangeFee | INT | YES | Fixed fee component for currency exchange in minor units. Applied when deposit currency differs from account currency (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 37 | BaseExchangeRate | DECIMAL | YES | Base exchange rate before markup. Paired with ExchangeRate to calculate the markup applied on top of the mid-market rate (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 38 | PaymentGeneration | INT | YES | Payment system generation/version indicator. Live data shows 1=first-generation pipeline. Distinguishes deposits processed by different versions (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 39 | ProcessRegulationID | INT | YES | Regulatory jurisdiction under which this deposit was processed. Determines compliance rules and reporting requirements. (Source: Dictionary.Regulation) (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 40 | IsSetBalanceCompleted | BOOLEAN | YES | Whether the Customer.SetBalance call that accompanies deposit approval completed successfully. 1=balance updated; NULL/0=pending or failed (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 41 | RoutingReasonID | INT | YES | Reason the deposit was routed to a specific payment processor. Used in multi-processor setups (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 42 | MerchantAccountID | INT | YES | Specific merchant account within a payment provider that processed this deposit. More granular than ProtocolMIDSettingsID (Tier 1 — inherited from etoro.History.Deposit_DataFactory). |
| 43 | etr_y | INT | YES | Source: etoro.History.Deposit_DataFactory.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 44 | etr_ym | STRING | YES | Source: etoro.History.Deposit_DataFactory.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 45 | etr_ymd | DATE | YES | Source: etoro.History.Deposit_DataFactory.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.Deposit_DataFactory` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.Deposit_DataFactory
        │
        ▼
main.bi_db.bronze_etoro_history_deposit_datafactory   ←── this object
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
| Occurred | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| DepositID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| PaymentStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| RiskManagementStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| PaymentDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| TransactionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| IPAddress | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| Approved | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| Commission | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ClearingHouseEffectiveDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| OldPaymentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| IsFTD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ProcessorValueDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| RefundVerificationCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| DepotID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| MatchStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| Code | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ExTransactionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| CampaignCodeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| BonusStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| BonusAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| BonusErrorCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| SessionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| DepositTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| DRStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| DRDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ProtocolMIDSettingsID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ExchangeFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| BaseExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| PaymentGeneration | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| ProcessRegulationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| IsSetBalanceCompleted | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| RoutingReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| MerchantAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.Deposit_DataFactory) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Deposit_DataFactory.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 43 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 46/46 | Source: bronze_tier1_inheritance*
