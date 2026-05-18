---
object_fqn: main.billing.bronze_etoro_billing_withdrawrejects
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_withdrawrejects
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 10
row_count: null
generated_at: '2026-05-18T10:58:40Z'
upstreams:
- etoro.Billing.WithdrawRejects
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md
  source_database: etoro
  source_schema: Billing
  source_table: WithdrawRejects
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/WithdrawRejects
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 10
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_withdrawrejects

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.WithdrawRejects`). 10 of 10 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_withdrawrejects` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 10 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 19 13:16:17 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.WithdrawRejects` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md`.

- Lake path: `Bronze/etoro/Billing/WithdrawRejects`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.WithdrawRejects`
- 10 of 10 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RejectID | INT | YES | Surrogate primary key, auto-incremented. NOT FOR REPLICATION. No business meaning beyond row identity (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 1 | WithdrawID | INT | YES | FK to Billing.Withdraw (WithdrawID) - enforced by FK_BWWR_BW. Identifies the withdrawal being rejected. The CLUSTERED index on this column enables fast lookup of all rejection records for a withdrawal (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 2 | RejectReasonID | INT | YES | FK to Dictionary.CashoutRejectReason (RejectReasonID) - enforced by FK_BWWR_DCRR. Reason the withdrawal was rejected. Key values: 0=Wrong Details MOP, 1=Missing Documents, 2=Missing Payment Info, 3=Missing Alternative MOP, 4=Unclaimed, 5=Denied, 6=Bonus Abuse, 7=Risk, 8=Off Market Abuse, 9=Management Approval, 10=Other, 11=Alternative Payment method (dominant), 15=CO Issues, 19=Missing/incorrect payment info, 27=Deceased client. Full list in Dictionary.CashoutRejectReason (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 3 | ManagerID | INT | YES | FK to BackOffice.Manager (ManagerID) - enforced by FK_BWWR_BMNG. The operations/compliance manager who performed the rejection. Value 0 appears in recent automated/system rejections (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 4 | RejectDate | TIMESTAMP | YES | Timestamp when the rejection was recorded. Set by `Billing.WithdrawReject` as @RejectDate parameter (caller provides timestamp). Used to sequence multiple rejections per withdrawal (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 5 | FollowupDate | TIMESTAMP | YES | Date by which the operations team should follow up on this rejection (check if customer responded, re-submitted, or needs chasing). Typically set 3-7 business days from RejectDate. Updated by `Billing.FollowupEdit`. Drives the operations team's work queue (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 6 | CaseNumber | INT | YES | External support/CRM ticket number linked to this rejection. NULL on initial insert (set by `Billing.FollowupEdit` when a support case is created). Allows linking the DB rejection record to a support platform case (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 7 | CaseDate | TIMESTAMP | YES | Date the external support case was created. NULL on initial insert, set alongside CaseNumber by `Billing.FollowupEdit` (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 8 | IsActive | BOOLEAN | YES | Whether this rejection record is the current active rejection for the withdrawal. 1=active (this is the current rejection), 0=superseded (a newer rejection has been recorded). Set to 1 on insert by `Billing.WithdrawReject`. Set to 0 by `Billing.SetRejectsAsInactiveForWithdraw` when a re-rejection occurs. Only one IsActive=1 record should exist per WithdrawID at any time (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |
| 9 | Comment | STRING | YES | Free-text notes from the rejecting manager. May contain case reference numbers, customer instructions, or context for the rejection (e.g., "Missing IBAN for wire transfer", "25402491 follow up"). NULL is allowed but rarely used in practice (Tier 1 — inherited from etoro.Billing.WithdrawRejects). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.WithdrawRejects` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.WithdrawRejects
        │
        ▼
main.billing.bronze_etoro_billing_withdrawrejects   ←── this object
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
| RejectID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| WithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| RejectReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| RejectDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| FollowupDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| CaseNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| CaseDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |
| Comment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.WithdrawRejects.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.WithdrawRejects) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 10/10 | Source: bronze_tier1_inheritance*
