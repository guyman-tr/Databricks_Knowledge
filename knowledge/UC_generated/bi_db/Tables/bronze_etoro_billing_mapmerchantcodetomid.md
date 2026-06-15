---
object_fqn: main.bi_db.bronze_etoro_billing_mapmerchantcodetomid
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_billing_mapmerchantcodetomid
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 4
row_count: null
generated_at: '2026-05-19T12:12:43Z'
upstreams:
- etoro.Billing.MapMerchantCodeToMid
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md
  source_database: etoro
  source_schema: Billing
  source_table: MapMerchantCodeToMid
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/MapMerchantCodeToMid
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_mapmerchantcodetomid

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Billing.MapMerchantCodeToMid`). 4 of 4 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_billing_mapmerchantcodetomid` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 4 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Feb 07 20:12:47 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.MapMerchantCodeToMid` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md`.

- Lake path: `Bronze/etoro/Billing/MapMerchantCodeToMid`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.MapMerchantCodeToMid`
- 4 of 4 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RegulationID | INT | YES | eToro regulatory entity under which the transaction was processed. 1=CySEC (EU), 2=FCA (UK), 4=ASIC (Australia), 9=FSA Seychelles. Forms part of the composite PK. Explicit FK to Dictionary.Regulation(ID). Used in Billing.GetMIDDescription to scope the MID lookup by the deposit's ProcessRegulationID or the customer's RegulationID (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid). |
| 1 | CurrencyID | INT | YES | Account denomination currency of the transaction. Explicit FK to Dictionary.Currency. Combined with RegulationID to narrow the merchant code lookup. The same MerchantCode often has different underlying MID values per currency (different numeric merchant accounts per currency) (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid). |
| 2 | MerchantCode | STRING | YES | The raw merchant identifier as provided by the payment provider or used in eToro's own systems. Three formats: (1) Numeric string = Skrill merchant account code (e.g., "5075493"); (2) Alphanumeric string = Neteller merchant account code (e.g., "AAABbn2n6r56x4Qe"); (3) eToro internal code = eToro's own merchant account identifier (e.g., "ETOROEUOCTPT", "ETOROEUSALES"). Joined against Billing.ProtocolMIDSettings.Value in Billing.GetMIDDescription (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid). |
| 3 | MID | STRING | YES | Human-readable Merchant ID label or numeric merchant account number. Two forms: (1) Label = friendly name used in BackOffice UI (SkrillEU, SkrillUK, SkrillAU, NetellerEU, NetellerFCA); (2) Numeric = eToro's actual merchant account number at the payment gateway (e.g., 18986763). Returned by Billing.GetMIDDescription and displayed in payment investigation views (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.MapMerchantCodeToMid` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.MapMerchantCodeToMid
        │
        ▼
main.bi_db.bronze_etoro_billing_mapmerchantcodetomid   ←── this object
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
| RegulationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid) |
| MerchantCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid) |
| MID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.MapMerchantCodeToMid.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.MapMerchantCodeToMid) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 4/4 | Source: bronze_tier1_inheritance*
