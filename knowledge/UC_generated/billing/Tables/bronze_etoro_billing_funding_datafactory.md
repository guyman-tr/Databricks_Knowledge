---
object_fqn: main.billing.bronze_etoro_billing_funding_datafactory
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_funding_datafactory
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-18T10:58:34Z'
upstreams:
- etoro.Billing.Funding_DataFactory
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md
  source_database: etoro
  source_schema: Billing
  source_table: Funding_DataFactory
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/Funding_DataFactory
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_funding_datafactory

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.Funding_DataFactory`). 11 of 11 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_funding_datafactory` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 05 13:55:16 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.Funding_DataFactory` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md`.

- Lake path: `Bronze/etoro/Billing/Funding_DataFactory`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.Funding_DataFactory`
- 11 of 11 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingID | INT | YES | Payment instrument PK. From Billing.Funding. IDENTITY(1000,1) (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 1 | FundingTypeID | INT | YES | Payment method type. From Billing.Funding. 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 33=eToroMoney, etc (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 2 | ManagerID | INT | YES | Operations manager ID. NULL=self-registered. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 3 | IsBlocked | BOOLEAN | YES | 1=instrument blocked. 0=active. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 4 | BlockedDescription | STRING | YES | Block reason text. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 5 | BlockedAt | TIMESTAMP | YES | Block timestamp. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 6 | FundingData | STRING | YES | Provider-specific instrument data as native XML. Not CAST to NVARCHAR (unlike other Funding views). Subject to DDM masking. ADF pipelines must handle XML serialization (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 7 | IsRefundExcluded | BOOLEAN | YES | 1=excluded from automatic refund. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 8 | DocumentRequired | BOOLEAN | YES | 1=KYC documentation required. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 9 | DateCreated | TIMESTAMP | YES | UTC timestamp of instrument registration. From Billing.Funding (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |
| 10 | PaymentDetails | STRING | YES | Pre-computed human-readable payment account identifier. Trigger-maintained column from Billing.Funding (populated by TR_FundingPaymentDetails via Billing.FormatFundingPaymentDetailsForWithdraw on each FundingData change). Unlike other views where PaymentDetails is computed in the view's CASE expression, this is a stored column from the base table (Tier 1 — inherited from etoro.Billing.Funding_DataFactory). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.Funding_DataFactory` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.Funding_DataFactory
        │
        ▼
main.billing.bronze_etoro_billing_funding_datafactory   ←── this object
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
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| IsBlocked | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| BlockedDescription | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| BlockedAt | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| FundingData | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| IsRefundExcluded | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| DocumentRequired | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| DateCreated | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |
| PaymentDetails | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Funding_DataFactory) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
