---
object_fqn: main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:13:08Z'
upstreams:
- WalletConversionDB.C2F.CryptoTransactions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md
  source_database: WalletConversionDB
  source_schema: C2F
  source_table: CryptoTransactions
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletConversionDB/C2F/CryptoTransactions
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletconversiondb_c2f_cryptotransactions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `WalletConversionDB.C2F.CryptoTransactions`). 7 of 10 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Mar 21 13:14:46 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletConversionDB.C2F.CryptoTransactions` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md`.

- Lake path: `Bronze/WalletConversionDB/C2F/CryptoTransactions`
- Copy strategy: `Append`
- Source database: `WalletConversionDB` (`CryptoDBs`)
- Source schema/table: `C2F.CryptoTransactions`
- 7 of 10 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate PK (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 1 | ConversionId | LONG | YES | FK to C2F.Conversions.Id. Links the blockchain transaction to its parent conversion. One crypto transaction per conversion (when present) (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 2 | BlockchainTransactionId | STRING | YES | On-chain transaction hash/identifier. Unique across all rows (UNIQUE constraint). Format varies by blockchain: Ethereum "0x" + 64 hex chars, Ripple uppercase hex, etc. Serves as proof of on-chain execution (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 3 | ToAddress | STRING | YES | Destination blockchain address where crypto was sent. May include chain-specific qualifiers (Ripple destination tags as "?dt=..."). Repeated addresses across transactions suggest omnibus wallet patterns (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 4 | Amount | DECIMAL | YES | Quantity of cryptocurrency transferred on-chain. Matches or closely tracks C2F.Conversions.CryptoAmount for the same conversion (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 5 | BlockchainFee | DECIMAL | YES | Network/gas fee charged by the blockchain for processing the transaction. Very small values observed (0.000045 XRP, 6e-8 for ERC-20). Deducted from the transfer, not from the conversion amount (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 6 | Occurred | TIMESTAMP | YES | UTC timestamp when the crypto transaction was recorded. Default constraint auto-sets (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions). |
| 7 | etr_y | INT | YES | Source: WalletConversionDB.C2F.CryptoTransactions.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | etr_ym | STRING | YES | Source: WalletConversionDB.C2F.CryptoTransactions.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | etr_ymd | DATE | YES | Source: WalletConversionDB.C2F.CryptoTransactions.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletConversionDB.C2F.CryptoTransactions` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletConversionDB.C2F.CryptoTransactions
        │
        ▼
main.bi_db.bronze_walletconversiondb_c2f_cryptotransactions   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| ConversionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| BlockchainTransactionId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| ToAddress | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| Amount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| BlockchainFee | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletConversionDB.C2F.CryptoTransactions) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletConversionDB/Wiki/C2F/Tables/C2F.CryptoTransactions.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
