---
object_fqn: main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 22
row_count: null
generated_at: '2026-05-19T12:08:01Z'
upstreams:
- WalletBalancesReportDB.Wallet.FinanceReportsBalances
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md
  source_database: WalletBalancesReportDB
  source_schema: Wallet
  source_table: FinanceReportsBalances
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReportsBalances
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 19
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletbalancesreportdb_wallet_financereportsbalances

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletBalancesReportDB.Wallet.FinanceReportsBalances`). 19 of 22 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | unknown |
| **Row count** | n/a |
| **Column count** | 22 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Sep 25 09:09:11 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletBalancesReportDB.Wallet.FinanceReportsBalances` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md`.

- Lake path: `Bronze/WalletBalancesReportDB/Wallet/FinanceReportsBalances`
- Copy strategy: `Append`
- Source database: `WalletBalancesReportDB` (`CryptoDBs`)
- Source schema/table: `Wallet.FinanceReportsBalances`
- 19 of 22 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate key. Part of the composite PK (ReportId, Id, Occurred) to support the partitioning scheme. Sequence reaches ~1.8 billion, reflecting the massive volume of reconciliation data over 5+ years (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 1 | ReportId | LONG | YES | Implicit FK to Wallet.FinanceReports.Id identifying the parent run. No explicit FK constraint exists (partitioning prevents FK on non-partition-aligned columns). Indexed in composite with LevelId and with WalletId+CryptoId (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 2 | WalletId | STRING | YES | Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId) (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 3 | Gcid | LONG | YES | Global Customer ID -- identifies the wallet owner. Denormalized from the external table for efficient customer-level querying (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 4 | CryptoId | INT | YES | Cryptocurrency asset identifier. Completes the composite business key (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 5 | Address | STRING | YES | Blockchain address for this wallet-crypto pair. Passed through from the external table for traceability (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 6 | BitgoWalletId | STRING | YES | BitGo custody platform's wallet identifier for cross-referencing during discrepancy investigation (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 7 | BloxAccountId | STRING | YES | Blox portfolio tracker's account identifier. Appears unused in production (always NULL in sampled data) (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 8 | TotalReceive | DECIMAL | YES | Total received amount for this wallet-crypto pair from blockchain data. Sourced from vu_GetWalletBalanceReport.TotalRecive (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 9 | TotalSend | DECIMAL | YES | Total sent amount for this wallet-crypto pair from blockchain data (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 10 | BloxBalance | DECIMAL | YES | Blockchain-reported net balance. Despite the name, this is the blockchain balance (TotalReceive - TotalSend), not the Blox provider balance. Legacy naming (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 11 | ComputedAmount | DECIMAL | YES | eToro ledger's computed expected balance. Compared against BloxBalance: `ABS(ComputedAmount - BloxBalance) > @Threshold` for discrepancy detection (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 12 | FindDiscrepancy | BOOLEAN | YES | Whether reconciliation found a balance mismatch: 0=no discrepancy (or not yet verified), 1=confirmed discrepancy. Initially 0; updated by UpdateReportRecord (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 13 | BitgoValue | DECIMAL | YES | BitGo custody provider's actual balance from the verification phase. Initially 0; updated by UpdateReportRecord via BalanceType TVP (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 14 | BloxValue | DECIMAL | YES | Blox portfolio tracker's actual balance from the verification phase. Initially 0; updated by UpdateReportRecord via BalanceType TVP (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 15 | ErrorMsg | STRING | YES | Error message from reconciliation verification. Contains API error details. NULL when successful (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 16 | LevelId | INT | YES | Classification of the reconciliation outcome. Implicit reference to Dictionary.FinanceReportLevel (no explicit FK due to partitioning). See [Finance Report Level](../../_glossary.md#finance-report-level) (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 17 | Occurred | TIMESTAMP | YES | UTC timestamp when this record was created. Partition column for DatesToFilegroup. Default constraint DF_FinanceReportsBalances_Occurred. Equivalent to FinanceReportRecords.Created (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 18 | Retries | INT | YES | Number of verification re-attempts. Set via the BalanceType TVP. NULL on initial creation (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances). |
| 19 | etr_y | STRING | YES | Source: WalletBalancesReportDB.Wallet.FinanceReportsBalances.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 20 | etr_ym | STRING | YES | Source: WalletBalancesReportDB.Wallet.FinanceReportsBalances.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | etr_ymd | STRING | YES | Source: WalletBalancesReportDB.Wallet.FinanceReportsBalances.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletBalancesReportDB.Wallet.FinanceReportsBalances` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletBalancesReportDB.Wallet.FinanceReportsBalances
        │
        ▼
main.wallet.bronze_walletbalancesreportdb_wallet_financereportsbalances   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| ReportId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| Gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| Address | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| BitgoWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| BloxAccountId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| TotalReceive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| TotalSend | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| BloxBalance | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| ComputedAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| FindDiscrepancy | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| BitgoValue | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| BloxValue | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| ErrorMsg | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| LevelId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| Occurred | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| Retries | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportsBalances) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportsBalances.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 19 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 22/22 | Source: bronze_tier1_inheritance*
