---
object_fqn: main.wallet.bronze_walletdb_wallet_amlvalidations
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletdb_wallet_amlvalidations
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 17
row_count: null
generated_at: '2026-05-19T12:08:04Z'
upstreams:
- WalletDB.Wallet.AmlValidations
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md
  source_database: WalletDB
  source_schema: Wallet
  source_table: AmlValidations
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletDB/Wallet/AmlValidations
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 14
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletdb_wallet_amlvalidations

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletDB.Wallet.AmlValidations`). 14 of 17 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletdb_wallet_amlvalidations` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 17 |
| **Generated** | 2026-05-19 |
| **Created** | Mon May 26 04:16:35 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletDB.Wallet.AmlValidations` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md`.

- Lake path: `Bronze/WalletDB/Wallet/AmlValidations`
- Copy strategy: `Append`
- Source database: `WalletDB` (`CryptoDBs`)
- Source schema/table: `Wallet.AmlValidations`
- 14 of 17 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | INT | YES | Auto-incrementing surrogate primary key (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 1 | AmlProviderId | INT | YES | Which AML provider performed this screening: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 2 | IsSend | BOOLEAN | YES | Direction of the transaction: 1=outbound (screening destination before sending), 0=inbound (screening sender after receiving) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 3 | Address | STRING | YES | The blockchain address being screened. For sends, this is the destination address. For receives, this is the sender address. NULL when screening is provider-level (not address-specific) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 4 | WalletId | STRING | YES | The eToro wallet involved in the transaction. FK to Wallet.WalletPool.WalletId. For sends, the source wallet. For receives, the receiving wallet (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 5 | Amount | DECIMAL | YES | Transaction amount in the crypto's native units. Used for risk scoring (higher amounts may trigger additional scrutiny) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 6 | ProviderStatus | STRING | YES | Raw status string returned by the AML provider. Provider-specific format (e.g., Chainalysis risk score) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 7 | IsPositiveDecision | BOOLEAN | YES | Final compliance decision: 1=approved (transaction can proceed), 0=rejected (transaction blocked). This is the field that gates transaction execution (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 8 | CorrelationId | STRING | YES | Links this screening to the parent request in Wallet.Requests via CorrelationId. Enables end-to-end tracing of the AML check within the request lifecycle (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 9 | Created | TIMESTAMP | YES | Timestamp when this screening was performed (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 10 | BlockchainTransactionId | STRING | YES | For receive screenings, the blockchain transaction hash being evaluated. NULL for pre-send screenings (transaction not yet broadcast) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 11 | DetailsJson | STRING | YES | Full JSON response from the AML provider. Contains detailed risk scores, alerts, cluster information, and screening metadata. Used for audit and investigation purposes (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 12 | CryptoId | INT | YES | The cryptocurrency being transacted. FK to Wallet.CryptoTypes.CryptoID. Determines which AML provider contract is used (via Wallet.AmlProviderContracts) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 13 | CategoryId | INT | YES | Chainalysis risk category if a risk factor was identified. NULL for clean transactions. Implicit reference to Dictionary.ChainalysisCategoryId. See [Chainalysis Category](../../_glossary.md#chainalysis-category) (Tier 3 — inherited from WalletDB.Wallet.AmlValidations). |
| 14 | etr_y | INT | YES | Source: WalletDB.Wallet.AmlValidations.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 15 | etr_ym | STRING | YES | Source: WalletDB.Wallet.AmlValidations.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 16 | etr_ymd | DATE | YES | Source: WalletDB.Wallet.AmlValidations.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletDB.Wallet.AmlValidations` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletDB.Wallet.AmlValidations
        │
        ▼
main.wallet.bronze_walletdb_wallet_amlvalidations   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| AmlProviderId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| IsSend | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| Address | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| ProviderStatus | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| IsPositiveDecision | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| Created | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| BlockchainTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| DetailsJson | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| CategoryId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletDB.Wallet.AmlValidations) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlValidations.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 14 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 17/17 | Source: bronze_tier1_inheritance*
