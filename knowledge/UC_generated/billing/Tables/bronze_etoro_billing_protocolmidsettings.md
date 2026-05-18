---
object_fqn: main.billing.bronze_etoro_billing_protocolmidsettings
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_protocolmidsettings
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-18T10:58:36Z'
upstreams:
- etoro.Billing.ProtocolMIDSettings
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md
  source_database: etoro
  source_schema: Billing
  source_table: ProtocolMIDSettings
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/ProtocolMIDSettings
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 10
  unverified_columns: 0
---

# bronze_etoro_billing_protocolmidsettings

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.ProtocolMIDSettings`). 0 of 10 columns inherited from Tier 1 source wiki; 10 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_protocolmidsettings` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-18 |
| **Created** | Wed Jan 18 07:39:15 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.ProtocolMIDSettings` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md`.

- Lake path: `Bronze/etoro/Billing/ProtocolMIDSettings`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.ProtocolMIDSettings`
- 0 of 10 columns inherited; 10 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.ID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 1 | ParameterID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.ParameterID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 2 | DepotID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.DepotID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 3 | DepotModeID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.DepotModeID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 4 | Value | STRING | YES | Source: etoro.Billing.ProtocolMIDSettings.Value. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 5 | RegulationID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.RegulationID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 6 | CurrencyID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.CurrencyID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | Description | STRING | YES | Source: etoro.Billing.ProtocolMIDSettings.Description. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | SubTypeID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.SubTypeID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | MerchantAccountID | INT | YES | Source: etoro.Billing.ProtocolMIDSettings.MerchantAccountID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.ProtocolMIDSettings` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.ProtocolMIDSettings
        │
        ▼
main.billing.bronze_etoro_billing_protocolmidsettings   ←── this object
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
| ID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `ID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| ParameterID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `ParameterID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| DepotID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `DepotID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| DepotModeID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `DepotModeID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| Value | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `Value` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| RegulationID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `RegulationID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| CurrencyID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `CurrencyID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| Description | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `Description` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| SubTypeID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `SubTypeID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| MerchantAccountID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ProtocolMIDSettings.md` but column `MerchantAccountID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 0 T1, 0 T2, 0 T3, 0 T4, 10 T5, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
