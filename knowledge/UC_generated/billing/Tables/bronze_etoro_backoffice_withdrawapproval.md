---
object_fqn: main.billing.bronze_etoro_backoffice_withdrawapproval
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_withdrawapproval
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-18T10:58:27Z'
upstreams:
- etoro.BackOffice.WithdrawApproval
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md
  source_database: etoro
  source_schema: BackOffice
  source_table: WithdrawApproval
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/WithdrawApproval
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_withdrawapproval

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.WithdrawApproval`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_withdrawapproval` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Oct 07 07:03:38 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.WithdrawApproval` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md`.

- Lake path: `Bronze/etoro/BackOffice/WithdrawApproval`
- Copy strategy: `Append`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.WithdrawApproval`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ApprovedWithdrawID | INT | YES | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each approval record. ~3.7M records as of 2026-03-17 (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 1 | WithdrawID | INT | YES | FK to Billing.Withdraw.WithdrawID (FK_BWIT_BWAP). Identifies the withdrawal request being approved. Multiple rows share a WithdrawID (one per approval group). Part of UNIQUE index (WithdrawID + UserGroupID) (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 2 | UserGroupID | INT | YES | FK to Dictionary.UserGroup.UserGroupID (FK_DUGR_BWAP). Identifies which approval group this row represents. 1=Admin, 3=Risk, 4=Marketing, 6=Trading. Each group submits one row per withdrawal (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 3 | ManagerID | INT | YES | FK to BackOffice.Manager.ManagerID (FK_BMNG_BWAP). The manager who submitted this group's decision. ManagerID=0 indicates automated/system approval without human review (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 4 | WithdrawApprovalReasonID | INT | YES | FK to Dictionary.WithdrawApprovalReason (FK_DWAP_BWAP). Reason for the approval decision. 7=Other (default for automated approvals). 1-6 and 8-16 indicate specific compliance reasons for manual holds/approvals (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 5 | Approved | BOOLEAN | YES | 1=This group approved the withdrawal. 0=This group rejected/held. A withdrawal proceeds only when all required groups (per Maintenance.Feature thresholds) have Approved=1 (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 6 | Occurred | TIMESTAMP | YES | Timestamp when this approval decision was recorded. Defaults to GETDATE() for direct inserts; set to GetDate() in WithdrawApprovalAdd SP (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |
| 7 | Comment | STRING | YES | Free-text comment from the approving/rejecting manager. Required field (NOT NULL). Contains compliance notes, rejection rationale, or auto-generated notes for system approvals (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.WithdrawApproval` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.WithdrawApproval
        │
        ▼
main.billing.bronze_etoro_backoffice_withdrawapproval   ←── this object
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
| ApprovedWithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| WithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| UserGroupID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| WithdrawApprovalReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| Approved | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| Occurred | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |
| Comment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.WithdrawApproval.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.WithdrawApproval) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
