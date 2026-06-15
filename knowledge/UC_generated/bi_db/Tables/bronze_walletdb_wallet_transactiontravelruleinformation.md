---
object_fqn: main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 15
row_count: null
generated_at: '2026-05-19T12:13:12Z'
upstreams:
- WalletDB.Wallet.TransactionTravelRuleInformation
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: TransactionTravelRuleInformation
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/TransactionTravelRuleInformation
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 12
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_transactiontravelruleinformation

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletDB.Wallet.TransactionTravelRuleInformation`). 12 of 15 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 15 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 30 08:16:53 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.TransactionTravelRuleInformation` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md`.

- Lake path: `Bronze/WalletDB/Wallet/TransactionTravelRuleInformation`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.TransactionTravelRuleInformation`
- 12 of 15 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing PK. FK target for TransactionTravelRuleStatuses and TransactionTravelRuleBeneficiaryDetails (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 1 | RequestId | LONG | YES | Parent request. FK to Wallet.Requests.Id. Links Travel Rule data to the transaction request (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 2 | RequestCorrelationId | STRING | YES | Parent request's CorrelationId for cross-service lookups (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 3 | FiatSymbol | STRING | YES | Fiat currency used for threshold calculation (e.g., "USD", "EUR") (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 4 | FiatAmount | DECIMAL | YES | Transaction value in fiat for threshold comparison (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 5 | Occurred | TIMESTAMP | YES | Record creation timestamp (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 6 | FiatRateCalculationTime | TIMESTAMP | YES | When the fiat conversion rate was fetched (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 7 | CounterpartyAddress | STRING | YES | Blockchain address of the counterparty (recipient for sends, sender for receives) (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 8 | FiatConversionTime | TIMESTAMP | YES | When the fiat conversion was performed (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 9 | FiatRate | DECIMAL | YES | Crypto-to-fiat conversion rate used (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 10 | BeneficiaryAddressType | STRING | YES | Whether the counterparty address is "Private" (self-hosted wallet) or "Hosted" (VASP-custodied). Determines compliance requirements (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 11 | ProviderMessageId | STRING | YES | Message ID from the Travel Rule provider (e.g., Notabene) for inter-VASP information sharing (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation). |
| 12 | etr_y | INT | YES | Source: WalletDB.Wallet.TransactionTravelRuleInformation.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | etr_ym | STRING | YES | Source: WalletDB.Wallet.TransactionTravelRuleInformation.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 14 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.TransactionTravelRuleInformation.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.TransactionTravelRuleInformation` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.TransactionTravelRuleInformation
        │
        ▼
main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| RequestId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| RequestCorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| FiatSymbol | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| FiatAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| FiatRateCalculationTime | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| CounterpartyAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| FiatConversionTime | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| FiatRate | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| BeneficiaryAddressType | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| ProviderMessageId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.TransactionTravelRuleInformation) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.TransactionTravelRuleInformation.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 12 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 15/15 | Source: bronze_tier1_inheritance*
