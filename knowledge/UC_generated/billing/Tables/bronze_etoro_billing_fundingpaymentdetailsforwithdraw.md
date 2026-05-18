---
object_fqn: main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-18T10:58:35Z'
upstreams:
- etoro.Billing.FundingPaymentDetailsForWithdraw
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md
  source_database: etoro
  source_schema: Billing
  source_table: FundingPaymentDetailsForWithdraw
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/FundingPaymentDetailsForWithdraw
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

# bronze_etoro_billing_fundingpaymentdetailsforwithdraw

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.FundingPaymentDetailsForWithdraw`). 11 of 11 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 19 13:16:01 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.FundingPaymentDetailsForWithdraw` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md`.

- Lake path: `Bronze/etoro/Billing/FundingPaymentDetailsForWithdraw`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.FundingPaymentDetailsForWithdraw`
- 11 of 11 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingID | INT | YES | Payment instrument PK. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 1 | FundingTypeID | INT | YES | Payment method type. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 2 | ManagerID | INT | YES | Operations manager who created/modified this instrument. NULL=self-registered (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 3 | IsBlocked | BOOLEAN | YES | 1=instrument blocked. 0=active. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 4 | BlockedDescription | STRING | YES | Reason for block. NULL if not blocked. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 5 | BlockedAt | TIMESTAMP | YES | When blocked. NULL if not blocked. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 6 | FundingData | STRING | YES | FundingData XML CAST to NVARCHAR(4000). Subject to DDM masking (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 7 | IsRefundExcluded | BOOLEAN | YES | 1=excluded from automatic refund. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 8 | DocumentRequired | BOOLEAN | YES | 1=KYC documentation required. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 9 | DateCreated | TIMESTAMP | YES | UTC timestamp of instrument registration. From Billing.Funding (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |
| 10 | PaymentDetails | STRING | YES | Computed human-readable payment account identifier from FundingData XML with country name from Dictionary.Country. WireTransfer (type 2) includes country name (unlike FundingPaymentDetailsForDeposit). eToroMoney (type 33) is commented out. Covers more types than the deposit variant: adds 20, 21, 22, 28, 34, 35 (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.FundingPaymentDetailsForWithdraw` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.FundingPaymentDetailsForWithdraw
        │
        ▼
main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw   ←── this object
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
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| IsBlocked | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| BlockedDescription | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| BlockedAt | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| FundingData | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| IsRefundExcluded | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| DocumentRequired | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| DateCreated | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |
| PaymentDetails | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.FundingPaymentDetailsForWithdraw) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
