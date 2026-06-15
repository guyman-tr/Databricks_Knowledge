---
object_fqn: main.billing.bronze_etoro_billing_withdraw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_withdraw
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 28
row_count: null
generated_at: '2026-05-18T10:58:39Z'
upstreams:
- etoro.Billing.Withdraw
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md
  source_database: etoro
  source_schema: Billing
  source_table: Withdraw
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/Withdraw
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 28
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_withdraw

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.Withdraw`). 28 of 28 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_withdraw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 28 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Sep 25 09:15:41 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.Withdraw` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md`.

- Lake path: `Bronze/etoro/Billing/Withdraw`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.Withdraw`
- 28 of 28 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | INT | YES | Primary key. IDENTITY starting at 1. Both a PK NONCLUSTERED and a separate CLUSTERED index exist on this column (unusual pattern - PK is non-clustered to allow covering indexes to reference the clustered key). NOT FOR REPLICATION (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 1 | CurrencyID | INT | YES | Currency of the withdrawal amount. FK to `Dictionary.Currency` (FK_DCUR_BWDR). Indexed (i_CureenyID - note typo in index name) (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 2 | FundingTypeID | INT | YES | Payment method type (Visa/Wire/Neteller/eToroMoney/etc.). References `Dictionary.FundingType` implicitly. 26 distinct values in live data (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 3 | CID | INT | YES | Customer ID. FK to `Customer.CustomerStatic` (FK_CCST_BWDR). Indexed in covering indexes (CashoutStatusID+CID, CoveringNew) (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 4 | ManagerID | INT | YES | Operations manager who processed or last modified this withdrawal. FK to `BackOffice.Manager` (FK_BMNG_BWDR). NULL=system-initiated or customer self-service (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 5 | CashoutStatusID | INT | YES | Current withdrawal status. FK to `Dictionary.CashoutStatus` (FK_DCSS_BWDR). 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5/7/8/14/16/17=specialized states. Indexed (multiple covering indexes) (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 6 | RequestDate | TIMESTAMP | YES | Timestamp when the customer submitted the withdrawal request. Included in covering indexes for date-range queries (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 7 | Amount | DECIMAL | YES | Gross withdrawal amount in `CurrencyID` denomination. `money` type (4 decimal places). Included in covering indexes (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 8 | Commission | DECIMAL | YES | Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers; may be non-zero for professional/partner accounts (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 9 | Approved | BOOLEAN | YES | Whether the withdrawal has received required approval (e.g., compliance/operations sign-off): 1=Approved, 0=Pending approval. DEFAULT=0. Included in covering index for filtered queries (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 10 | IPAddress | DECIMAL | YES | Customer's IP address at request time, stored as integer (IPv4 -> decimal). Fraud detection and audit trail (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 11 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent status change or update. Indexed (ix_BillingWithdraw_ModificationDate). Included in covering index (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 12 | Remark | STRING | YES | Processing note added by the system or operations staff. Included in covering index INCLUDE list (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 13 | Comment | STRING | YES | Additional operations comment. Included in covering index INCLUDE list (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 14 | Fee | DECIMAL | YES | Platform fee charged for this withdrawal. Subtracted from the gross Amount. Included in covering index (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 15 | FundingID | INT | YES | FK to `Billing.Funding` - the payment instrument to which the withdrawal should be paid. NULL if no specific instrument selected at request time. Included in covering index (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 16 | RequestorComments | STRING | YES | Notes added by the requesting party (customer or system). DEFAULT NULL (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 17 | SessionID | LONG | YES | Audit session identifier linking this withdrawal to a specific user session. DEFAULT NULL (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 18 | CashoutReasonID | INT | YES | Internal reason code for the withdrawal decision (e.g., why it was cancelled or flagged). References an internal catalog (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 19 | SuggestedBonusDeductionAmount | DECIMAL | YES | Pre-calculated amount of trading bonus to claw back when the customer withdraws (per bonus terms). DEFAULT=0 (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 20 | ActualBonusDeductionAmount | DECIMAL | YES | Actual bonus amount deducted after processing. May differ from suggested amount if conditions changed. NULL until finalized (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 21 | ClientWithdrawReasonID | INT | YES | Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). References a reason catalog implicitly (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 22 | ClientWithdrawReasonComment | STRING | YES | Customer's free-text explanation for the withdrawal reason. Max 510 characters (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 23 | AccountCurrencyID | INT | YES | Customer's eToro account currency, if different from `CurrencyID`. FK to `Dictionary.Currency` (FK_DCUR_BWAC). Included in covering index. Used when account and withdrawal currencies differ (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 24 | ClientWithdrawCommentID | INT | YES | FK to `Dictionary.ClientWithdrawComment` (FK_BillingWithdraw_DictionaryClientWithdrawComment). Standardized comment category for the withdrawal (used in customer-facing messaging) (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 25 | ExTransactionID | STRING | YES | External transaction identifier from the payment provider. Links this withdrawal record to the provider's transaction reference (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 26 | WithdrawTypeID | INT | YES | Withdrawal type classification added in a later release. NULL=legacy record (55%). 0=standard withdrawal (41%). 1=special/alternate type (3.7%). 2=second alternate type (0.5%). Used by `WithdrawToFundingProcess` to determine MoveMoneyReasonID override: WithdrawTypeID=1 + FlowID=2 -> MoveMoneyReasonID=5; WithdrawTypeID=1 + FlowID=3 -> MoveMoneyReasonID=6 (Tier 1 — inherited from etoro.Billing.Withdraw). |
| 27 | FlowID | INT | YES | Processing flow identifier added in a later release. NULL=legacy (59%). 0=standard flow (38%). 2=eToroMoney local currency withdrawal (2.6%, 42,952 records). 3=specific alternate flow (708 records). 9=rare special case (9 records). 1=one record. FlowID=2 with FundingTypeID=33 triggers eToroMoney-specific balance accounting (Tier 1 — inherited from etoro.Billing.Withdraw). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.Withdraw` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.Withdraw
        │
        ▼
main.billing.bronze_etoro_billing_withdraw   ←── this object
        │
        ▼
main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
main.bi_output.bi_output_operations_yoni_davideresta_alerts
main.bi_output.bi_output_opshighcashoutclientsemail
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
| WithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| CashoutStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| RequestDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| Commission | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| Approved | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| IPAddress | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| Remark | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| Comment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| Fee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| RequestorComments | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| SessionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| CashoutReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| SuggestedBonusDeductionAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ActualBonusDeductionAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ClientWithdrawReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ClientWithdrawReasonComment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| AccountCurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ClientWithdrawCommentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| ExTransactionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| WithdrawTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |
| FlowID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Withdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Withdraw) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 28 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 28/28 | Source: bronze_tier1_inheritance*
