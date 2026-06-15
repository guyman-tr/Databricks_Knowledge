---
object_fqn: main.bi_db.bronze_etoro_backoffice_bonustype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_backoffice_bonustype
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:12:40Z'
upstreams:
- etoro.BackOffice.BonusType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md
  source_database: etoro
  source_schema: BackOffice
  source_table: BonusType
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/BonusType
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_bonustype

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.BackOffice.BonusType`). 9 of 9 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_backoffice_bonustype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 9 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Feb 12 09:07:27 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.BonusType` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md`.

- Lake path: `Bronze/etoro/BackOffice/BonusType`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.BonusType`
- 9 of 9 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | BonusTypeID | INT | YES | Auto-generated unique identifier for each bonus type. PK referenced by BackOffice.Bonus (BonusTypeID FK) and BackOffice.CampaignToBonusType. Also used as ParentID for child types in the hierarchy (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 1 | ParentID | INT | YES | Self-referential FK to BonusTypeID. NULL = root/department category (9 root nodes). Non-NULL = specific bonus program under a department. FK constraint FK_BBNT_BBNT enforces referential integrity. Has BBNT_PARENT index for efficient children lookups (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 2 | Name | STRING | YES | Internal name used by BackOffice staff for identification, reporting, and operational routing. Shown in the BackOffice UI dropdowns. NOT the customer-visible name - see DisplayName. Examples: "Dormant Fee", "Hedge Abuser", "Request for Documents", "Cashout Fee Reimbursment" (note: typo in production data). Has BBNT_NAME index (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 3 | Configuration | STRING | YES | XML configuration payload for parameterized bonus types. Only one active bonus type has this populated (BonusTypeID=2: `<DepositBonus/>`). Intended for deposit bonus configuration rules but largely unused - 69 of 70 types have NULL configuration (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 4 | IsWithdrawable | BOOLEAN | YES | Whether the bonus amount can be withdrawn by the customer. Currently 0 (false) for ALL 70 active bonus types - this field is either a planned feature or bonus withdrawability is controlled elsewhere in the bonus lifecycle (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 5 | IsActive | BOOLEAN | YES | Whether this bonus type is still in active use. 0=deprecated (should not be assigned to new bonuses). Active=0 types: 17=Refill-Negative Balance, 23=Championship Winner Demo. All other 68 types are IsActive=1 (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 6 | HideFromAffwiz | INT | YES | Controls visibility in the Affiliate Wizard (AffWiz) portal used by affiliate partners. 1=hide from affiliates (internal operational types not relevant to affiliate programs). 0 or NULL=visible. NULL represents rows created before this column was added. Types with HideFromAffwiz=1 include operational adjustments (Dormant Fee, Foreclosure, Hedge Abuser, P&L Adjustment, Merge Accounts) that affiliates should not access (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 7 | DisplayName | STRING | YES | Customer-facing label shown in the customer's account statement for this bonus type. Decouples internal classification from customer-visible text. Examples: "eToro credits adjustment" (generic ops adjustment), "Account maintenance fee" (Dormant Fee), "Withdraw Fee Reimbursement" (Cashout Fee Reimbursement), "Trading credits" (R&D technical bonus). Multiple bonus types share the same DisplayName (e.g., many types show "eToro credits adjustment") (Tier 1 — inherited from etoro.BackOffice.BonusType). |
| 8 | IsDepositRelated | INT | YES | Whether this bonus type is triggered by or associated with a customer deposit event. 1=deposit-related (first deposit promos, retention deposit bonuses, NWA adjustment, referral-when-invited bonuses). 0=non-deposit operational credit or promotional grant. Used in reporting to distinguish promotional deposit incentives from operational adjustments (Tier 1 — inherited from etoro.BackOffice.BonusType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.BonusType` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.BonusType
        │
        ▼
main.bi_db.bronze_etoro_backoffice_bonustype   ←── this object
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
| BonusTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| ParentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| Configuration | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| IsWithdrawable | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| HideFromAffwiz | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| DisplayName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |
| IsDepositRelated | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.BonusType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: bronze_tier1_inheritance*
