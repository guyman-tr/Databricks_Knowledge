---
object_fqn: main.billing.bronze_moneybusdb_moneybus_transferlimits
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_moneybusdb_moneybus_transferlimits
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-18T10:58:46Z'
upstreams:
- MoneyBusDB.MoneyBus.TransferLimits
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md
  source_database: MoneyBusDB
  source_schema: MoneyBus
  source_table: TransferLimits
  source_repo: PaymentsDBs
  datalake_path: Bronze/MoneyBusDB/MoneyBus/TransferLimits
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

# bronze_moneybusdb_moneybus_transferlimits

> Bronze ingest in `main.billing` (1:1 passthrough of `MoneyBusDB.MoneyBus.TransferLimits`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_moneybusdb_moneybus_transferlimits` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-18 |
| **Created** | Sun Apr 12 08:34:41 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `MoneyBusDB.MoneyBus.TransferLimits` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md`.

- Lake path: `Bronze/MoneyBusDB/MoneyBus/TransferLimits`
- Copy strategy: `Override`
- Source database: `MoneyBusDB` (`PaymentsDBs`)
- Source schema/table: `MoneyBus.TransferLimits`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | INT | YES | Country filter for the limit rule. NULL means the rule applies to all countries. When set, restricts this limit to users in the specified country. Currently all rows have NULL (global rules) (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 1 | DebitAccountTypeID | INT | YES | Source account type being debited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Defines the "from" side of the transfer direction (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 2 | CreditAccountTypeID | INT | YES | Destination account type being credited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type). (Dictionary.AccountTypes). Defines the "to" side of the transfer direction (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 3 | MinAmount | DECIMAL | YES | Minimum transfer amount allowed in the specified currency. Currently set to 1 for all rules - prevents zero-amount transfers (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 4 | MaxAmount | DECIMAL | YES | Maximum transfer amount allowed in the specified currency. Ranges from 50,000 (flow-specific restriction) to 100,000,000 (default). The application rejects transfers exceeding this (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 5 | CurrencyID | INT | YES | Currency the limit applies to. Each currency requires its own limit row because acceptable ranges differ by currency denomination. Maps to an external currency reference (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 6 | PlayerLevelID | INT | YES | Player/user tier level filter. NULL means the rule applies to all levels. When set, allows different transfer limits for VIP vs. standard users. Currently all rows have NULL (uniform limits) (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |
| 7 | FlowID | INT | YES | Business flow identifier. NULL means "default for all flows." When specified (e.g., FlowID=2), applies a more specific limit that overrides the default. One row uses FlowID=2 with a lower MaxAmount, indicating a restricted flow type (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `MoneyBusDB.MoneyBus.TransferLimits` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` |

### 4.2 Pipeline ASCII Diagram

```
MoneyBusDB.MoneyBus.TransferLimits
        │
        ▼
main.billing.bronze_moneybusdb_moneybus_transferlimits   ←── this object
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
| CountryID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| DebitAccountTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| CreditAccountTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| MinAmount | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| MaxAmount | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| PlayerLevelID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |
| FlowID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.MoneyBus.TransferLimits) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
