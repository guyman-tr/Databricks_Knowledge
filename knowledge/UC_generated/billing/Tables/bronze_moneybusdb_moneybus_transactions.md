---
object_fqn: main.billing.bronze_moneybusdb_moneybus_transactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_moneybusdb_moneybus_transactions
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 37
row_count: null
generated_at: '2026-05-18T10:58:45Z'
upstreams:
- MoneyBusDB.MoneyBus.Transactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md
  source_database: MoneyBusDB
  source_schema: MoneyBus
  source_table: Transactions
  source_repo: PaymentsDBs
  datalake_path: Bronze/MoneyBusDB/MoneyBus/Transactions
  copy_strategy: Merge
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 29
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 8
  unverified_columns: 0
---

# bronze_moneybusdb_moneybus_transactions

> Bronze ingest in `main.billing` (1:1 passthrough of `MoneyBusDB.MoneyBus.Transactions`). 29 of 37 columns inherited from Tier 1 source wiki; 8 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_moneybusdb_moneybus_transactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 37 |
| **Generated** | 2026-05-18 |
| **Created** | Sun Aug 04 10:00:54 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `MoneyBusDB.MoneyBus.Transactions` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md`.

- Lake path: `Bronze/MoneyBusDB/MoneyBus/Transactions`
- Copy strategy: `Merge`
- Source database: `MoneyBusDB` (`PaymentsDBs`)
- Source schema/table: `MoneyBus.Transactions`
- 29 of 37 columns inherited; 8 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | LONG | YES | Auto-incrementing primary key. Part of composite clustered key with PartitionCol. Referenced by Containers.TransactionID. Used with modulo partitioning for efficient lookups (WHERE ID = @ID AND PartitionCol = @ID % 100) (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 1 | GCID | LONG | YES | Global Customer ID - identifies the user who owns this transaction. Indexed (IX_Transactions_GCID) for user-level queries. Nullable for system-generated transactions (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 2 | Created | TIMESTAMP | YES | UTC timestamp when the transaction was created. Set to GETUTCDATE() by TransactionAdd/TransactionsAndGroupAdd if not provided. Indexed (IX_Transactions_Created). Range: 2023-05-07 to present (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 3 | CreditorTypeID | INT | YES | Account type receiving funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Paired with DebitorTypeID to define the transfer direction (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 4 | DebitorTypeID | INT | YES | Account type sending funds: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). The combination CreditorTypeID+DebitorTypeID defines the money flow direction (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 5 | StatusID | INT | YES | High-level transaction lifecycle state: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See [Transaction Status](../../_glossary.md#transaction-status). (Dictionary.TransactionStatuses). ~98% reach Success (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 6 | GroupID | LONG | YES | FK to MoneyBus.TransactionsGroup.ID. Links this transaction to its parent group, tying together the debit and credit legs of a single business operation. Set by TransactionsAndGroupAdd after creating the group (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 7 | ReferenceID | STRING | YES | External reference identifier from the calling system (typically a UUID). Used for cross-system correlation and idempotency (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 8 | Amount | DECIMAL | YES | Transaction amount in the currency specified by CurrencyID. Pre-calculated by the application. Ranges from small fractional amounts to large sums (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 9 | CurrencyID | INT | YES | Currency of the transaction amount. Common values: 1 (USD), 2 (EUR), 3 (GBP). Maps to an external currency reference (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 10 | Modified | TIMESTAMP | YES | UTC timestamp of the last status change. Updated by TransactionUpdate on every pipeline step transition (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 11 | CreditorAccountID | STRING | YES | Identifier of the creditor's specific account within the creditor account type. May be a trading account number, IBAN, or internal account reference (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 12 | DebitorAccountID | STRING | YES | Identifier of the debitor's specific account within the debitor account type. Paired with CreditorAccountID to fully specify both ends of the transfer (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 13 | StatusReasonID | INT | YES | Detailed pipeline step: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason). (Dictionary.TransactionStatusReasons) (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 14 | PartitionCol | LONG | YES | Computed: `ID % 100`. Persisted computed column used as the partition key in the PS_Transactions partition scheme. Distributes rows across 100 partitions for parallel query performance. Part of the composite clustered key (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 15 | Trace | STRING | YES | Computed: `CONCAT('{"HostName":"',HOST_NAME(),...})`. Non-persisted JSON audit trail capturing SQL Server session context (hostname, app name, login, SPID, database, procedure) at the time of last modification (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 16 | ValidFrom | TIMESTAMP | YES | System-versioning start timestamp. Auto-managed by SQL Server temporal tables (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 17 | ValidTo | TIMESTAMP | YES | System-versioning end timestamp. 9999-12-31 for current version. Old versions move to History.MoneyBusTransactions on UPDATE (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 18 | CreditorReferenceID | STRING | YES | Provider-side reference ID for the credit leg. Populated by TransactionUpdate after credit initiation. Used for reconciliation with the credit provider (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 19 | DebitorReferenceID | STRING | YES | Provider-side reference ID for the debit leg. Populated by TransactionUpdate after debit initiation. Used for reconciliation with the debit provider (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 20 | BaseExchangeRate | DECIMAL | YES | Source: MoneyBusDB.MoneyBus.Transactions.BaseExchangeRate. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | ExchangeRate | DECIMAL | YES | Source: MoneyBusDB.MoneyBus.Transactions.ExchangeRate. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | ExchangeFee | DECIMAL | YES | Source: MoneyBusDB.MoneyBus.Transactions.ExchangeFee. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 23 | FlowID | INT | YES | Business flow classifier: 1=Open position (buy), 2=Close position (sell), 3=Deposit/withdrawal. Determines which pipeline logic is applied. ~42% flow 1, ~43% flow 2, ~15% flow 3. NULL/0 for legacy transactions (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 24 | ExtraData | STRING | YES | JSON metadata carrying rich trading context. For Open flows: units, leverage, instrumentName, isBuy, isReal. For Close flows: positionId, orderId, action="Close". Always contains creditorData/debitorData with per-side Amount/Currency/CurrencyId (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 25 | CreditorBaseExchangeRate | DECIMAL | YES | Market exchange rate for converting to the creditor's currency. Used with CreditorExchangeFee to compute the effective CreditorExchangeRate (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 26 | CreditorExchangeFee | DECIMAL | YES | Fee/spread applied to the creditor-side currency conversion, expressed as a rate adjustment (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 27 | CreditorExchangeRate | DECIMAL | YES | Effective exchange rate applied to the creditor side (base rate adjusted by fee). Creditor amount = Amount * CreditorExchangeRate (approximately) (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 28 | DebitorBaseExchangeRate | DECIMAL | YES | Market exchange rate for the debitor's currency conversion (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 29 | DebitorExchangeFee | DECIMAL | YES | Fee/spread applied to the debitor-side currency conversion (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 30 | DebitorExchangeRate | DECIMAL | YES | Effective exchange rate applied to the debitor side. Debitor amount = Amount * DebitorExchangeRate (approximately) (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 31 | etr_y | STRING | YES | Source: MoneyBusDB.MoneyBus.Transactions.etr_y. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 32 | etr_ym | STRING | YES | Source: MoneyBusDB.MoneyBus.Transactions.etr_ym. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 33 | etr_ymd | STRING | YES | Source: MoneyBusDB.MoneyBus.Transactions.etr_ymd. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 34 | HoldReferenceID | STRING | YES | Provider-side reference ID for the hold/reserve operation. Used to release or settle held funds. Populated during HoldInitiated step (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions). |
| 35 | ReconciliationReservedUntil | TIMESTAMP | YES | Source: MoneyBusDB.MoneyBus.Transactions.ReconciliationReservedUntil. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 36 | ReconciliationAttemptCount | INT | YES | Source: MoneyBusDB.MoneyBus.Transactions.ReconciliationAttemptCount. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `MoneyBusDB.MoneyBus.Transactions` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` |

### 4.2 Pipeline ASCII Diagram

```
MoneyBusDB.MoneyBus.Transactions
        │
        ▼
main.billing.bronze_moneybusdb_moneybus_transactions   ←── this object
        │
        ▼
main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
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
| ID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| GCID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| Created | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CreditorTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| DebitorTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| StatusID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| GroupID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| ReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| Amount | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| Modified | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CreditorAccountID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| DebitorAccountID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| StatusReasonID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| PartitionCol | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| Trace | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| ValidFrom | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| ValidTo | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CreditorReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| DebitorReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| BaseExchangeRate | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `BaseExchangeRate` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ExchangeRate | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `ExchangeRate` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ExchangeFee | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `ExchangeFee` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| FlowID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| ExtraData | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CreditorBaseExchangeRate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CreditorExchangeFee | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| CreditorExchangeRate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| DebitorBaseExchangeRate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| DebitorExchangeFee | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| DebitorExchangeRate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| etr_y | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `etr_y` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `etr_ym` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `etr_ymd` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| HoldReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.Transactions) |
| ReconciliationReservedUntil | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `ReconciliationReservedUntil` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ReconciliationAttemptCount | would inherit from `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.Transactions.md` but column `ReconciliationAttemptCount` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 29 T1, 0 T2, 0 T3, 0 T4, 8 T5, 0 U | Elements: 37/37 | Source: bronze_tier1_inheritance*
