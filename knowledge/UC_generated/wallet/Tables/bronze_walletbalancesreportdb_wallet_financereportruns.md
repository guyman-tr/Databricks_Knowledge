---
object_fqn: main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 4
row_count: null
generated_at: '2026-05-19T12:08:01Z'
upstreams:
- WalletBalancesReportDB.Wallet.FinanceReportRuns
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md
  source_database: WalletBalancesReportDB
  source_schema: Wallet
  source_table: FinanceReportRuns
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReportRuns
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

# bronze_walletbalancesreportdb_wallet_financereportruns

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletBalancesReportDB.Wallet.FinanceReportRuns`). 4 of 4 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 4 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Nov 05 07:17:12 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletBalancesReportDB.Wallet.FinanceReportRuns` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md`.

- Lake path: `Bronze/WalletBalancesReportDB/Wallet/FinanceReportRuns`
- Copy strategy: `Override`
- Source database: `WalletBalancesReportDB` (`CryptoDBs`)
- Source schema/table: `Wallet.FinanceReportRuns`
- 4 of 4 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key identifying each reconciliation run. Referenced as ReportId by Wallet.FinanceReportRecords (FK) to link individual wallet-crypto results back to their parent run. Also read by Wallet.UpdateReportRecords to extract Parameters JSON (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns). |
| 1 | StartTime | TIMESTAMP | YES | UTC timestamp when the reconciliation run began. Set to GETUTCDATE() by Wallet.CreateNewReportRun at the start of the transaction. Used by Wallet.GetLastReportRun (ORDER BY Id DESC) to identify the most recent run. Indexed (IX_FinanceReportRuns__StartTime DESC) for efficient latest-run lookups (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns). |
| 2 | EndTime | TIMESTAMP | YES | Timestamp when the reconciliation run completed. NULL while the run is in progress; set to GETDATE() by Wallet.UpdateReportRun after all reconciliation results have been processed. In production, all 621 historical runs have EndTime populated -- no abandoned runs exist. Note: uses GETDATE() (local time) rather than GETUTCDATE(), creating a potential timezone inconsistency with StartTime (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns). |
| 3 | Parameters | STRING | YES | JSON-serialized execution parameters that controlled this run's behavior. Structure: {"Threshold": decimal, "ProcessAllRecords": bool, "RetryDays": int}. Threshold = balance difference tolerance for flagging discrepancies; ProcessAllRecords = whether to recheck all wallets or only changed ones; RetryDays = lookback window for retrying discrepant records. Read at runtime by Wallet.UpdateReportRecords to determine pruning behavior. All production runs use identical parameters: Threshold=0, ProcessAllRecords=false, RetryDays=1 (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletBalancesReportDB.Wallet.FinanceReportRuns` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletBalancesReportDB.Wallet.FinanceReportRuns
        │
        ▼
main.wallet.bronze_walletbalancesreportdb_wallet_financereportruns   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns) |
| StartTime | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns) |
| EndTime | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns) |
| Parameters | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRuns.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRuns) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 4 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 4/4 | Source: bronze_tier1_inheritance*
