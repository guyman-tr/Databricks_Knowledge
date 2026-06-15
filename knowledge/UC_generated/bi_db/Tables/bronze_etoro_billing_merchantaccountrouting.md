---
object_fqn: main.bi_db.bronze_etoro_billing_merchantaccountrouting
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_billing_merchantaccountrouting
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-19T12:12:43Z'
upstreams:
- etoro.Billing.MerchantAccountRouting
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md
  source_database: etoro
  source_schema: Billing
  source_table: MerchantAccountRouting
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/MerchantAccountRouting
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 10
  unverified_columns: 0
---

# bronze_etoro_billing_merchantaccountrouting

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Billing.MerchantAccountRouting`). 0 of 10 columns inherited from Tier 1 source wiki; 10 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_billing_merchantaccountrouting` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-19 |
| **Created** | Sat Feb 10 19:30:53 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.MerchantAccountRouting` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md`.

- Lake path: `Bronze/etoro/Billing/MerchantAccountRouting`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.MerchantAccountRouting`
- 0 of 10 columns inherited; 10 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.ID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 1 | DepotID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.DepotID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 2 | DepotModeID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.DepotModeID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 3 | RegulationID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.RegulationID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 4 | CurrencyID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.CurrencyID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 5 | PaymentTypeID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.PaymentTypeID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | CountryID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.CountryID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | SubTypeID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.SubTypeID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | MerchantAccountID | INT | YES | Source: etoro.Billing.MerchantAccountRouting.MerchantAccountID. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | Description | STRING | YES | Source: etoro.Billing.MerchantAccountRouting.Description. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.MerchantAccountRouting` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.MerchantAccountRouting
        │
        ▼
main.bi_db.bronze_etoro_billing_merchantaccountrouting   ←── this object
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
| ID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `ID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| DepotID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `DepotID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| DepotModeID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `DepotModeID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| RegulationID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `RegulationID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| CurrencyID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `CurrencyID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| PaymentTypeID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `PaymentTypeID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| CountryID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `CountryID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| SubTypeID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `SubTypeID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| MerchantAccountID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `MerchantAccountID` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Description | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MerchantAccountRouting.md` but column `Description` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 0 T5, 10 TN, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
