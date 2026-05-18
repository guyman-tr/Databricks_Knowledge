---
object_fqn: main.billing.bronze_etoro_billing_depot
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_depot
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-18T10:58:34Z'
upstreams:
- etoro.Billing.Depot
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md
  source_database: etoro
  source_schema: Billing
  source_table: Depot
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/Depot
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_depot

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.Depot`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_depot` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Mar 11 09:36:59 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.Depot` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md`.

- Lake path: `Bronze/etoro/Billing/Depot`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.Depot`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepotID | INT | YES | Primary key. Manually assigned (no IDENTITY). Stable identifier referenced by deposits, MID settings, and routing tables (Tier 1 — inherited from etoro.Billing.Depot). |
| 1 | FundingTypeID | INT | YES | Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References `Dictionary.FundingType` implicitly (no FK constraint in DDL). 38 distinct values across 163 depots (Tier 1 — inherited from etoro.Billing.Depot). |
| 2 | PaymentTypeID | INT | YES | Direction of payment flow. FK to `Dictionary.PaymentType` (FK_DPMT_BDPT): 1=Deposit, 2=Cashout, 3=Refund. Indexed (BDPT_PAYMENTTYPE) (Tier 1 — inherited from etoro.Billing.Depot). |
| 3 | ProtocolID | INT | YES | Payment processing protocol/gateway. FK to `Dictionary.Protocol` (FK_DPRT_BDPT). Identifies the specific API or connection used (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). Indexed (BDPT_PROTOCOL) (Tier 1 — inherited from etoro.Billing.Depot). |
| 4 | Name | STRING | YES | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). UNIQUE (BDPT_NAME index). Used in admin dashboards, routing logs, and discrepancy reports (Tier 1 — inherited from etoro.Billing.Depot). |
| 5 | IsActive | BOOLEAN | YES | Whether this depot is currently accepting transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. Queried as `IsActive = 1` in routing logic (Tier 1 — inherited from etoro.Billing.Depot). |
| 6 | PayoutGeneration | INT | YES | Controls automated payout file generation capability: 1=enabled (system can generate payment batch files for this depot); 0=disabled (manual or provider-managed). Default=0 (Tier 1 — inherited from etoro.Billing.Depot). |
| 7 | Features | STRING | YES | Depot-specific configuration features in structured text (JSON or XML format). Used for newer integrations requiring behavioral flags (e.g., 3DS2 settings, specific API options). NULL or empty for most legacy depots (Tier 1 — inherited from etoro.Billing.Depot). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.Depot` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.Depot
        │
        ▼
main.billing.bronze_etoro_billing_depot   ←── this object
        │
        ▼
main.bi_output.vg_fact_billingwithdraw_for_genie
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
| DepotID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| PaymentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| ProtocolID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| PayoutGeneration | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |
| Features | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Depot.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Depot) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
