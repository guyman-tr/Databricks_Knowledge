---
object_fqn: main.bi_db.bronze_etoro_customer_customermoney
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_customer_customermoney
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-19T12:12:44Z'
upstreams:
- etoro.Customer.CustomerMoney
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md
  source_database: etoro
  source_schema: Customer
  source_table: CustomerMoney
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Customer/CustomerMoney
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_customer_customermoney

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Customer.CustomerMoney`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_customer_customermoney` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 12 05:18:33 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Customer.CustomerMoney` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md`.

- Lake path: `Bronze/etoro/Customer/CustomerMoney`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Customer.CustomerMoney`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID - primary key. Matches CID in Customer.CustomerStatic. One row per customer (Tier 1 — inherited from etoro.Customer.CustomerMoney). |
| 1 | GCID | INT | YES | Group Customer ID - same as Customer.CustomerStatic.GCID. Redundant storage for lookup performance - avoids join to CustomerStatic for GCID resolution. Confirmed as account-level field (not per-currency) in multi-currency design (Tier 1 — inherited from etoro.Customer.CustomerMoney). |
| 2 | Credit | DECIMAL | YES | Credit balance for the customer account. Semantics inherited from source table Customer.CustomerMoney; exact definition pending upstream wiki resolution. (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| 3 | BonusCredit | DECIMAL | YES | Promotional/bonus credits, separate from real funds. Default = 0. Confirmed as account-level (USD-only) in multi-currency design (March 8 decision) (Tier 1 — inherited from etoro.Customer.CustomerMoney). |
| 4 | RealizedEquity | DECIMAL | YES | Running total of realized value: increases on deposits and position close proceeds, decreases on withdrawals. Answers "how much has the customer realized?" Confirmed as account-level (single USD number) in multi-currency design - Mor: "Realized equity is per account." (Tier 1 — inherited from etoro.Customer.CustomerMoney). |
| 5 | TotalCash | DECIMAL | YES | Reconciled cash total maintained by Trade.UpdateTotalCash reconciliation job. Uses dtPrice UDT (higher decimal precision than money). Per-currency vs account-level classification is open in multi-currency design (Tier 1 — inherited from etoro.Customer.CustomerMoney). |
| 6 | BSLRealFunds | DECIMAL | YES | Real funds threshold for Balance Stop Loss (BSL) system. Updated by PostMIMOOperations. When customer equity drops to this level, BSL liquidation triggers. BSL is account-wide (USD aggregate), confirmed as account-level field. Default = 0 (Tier 1 — inherited from etoro.Customer.CustomerMoney). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Customer.CustomerMoney` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Customer.CustomerMoney
        │
        ▼
main.bi_db.bronze_etoro_customer_customermoney   ←── this object
        │
        ▼
main.etoro_kpi.v_raf
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
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| Credit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| BonusCredit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| RealizedEquity | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| TotalCash | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |
| BSLRealFunds | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerMoney.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.CustomerMoney) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
