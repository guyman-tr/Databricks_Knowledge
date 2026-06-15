---
object_fqn: main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords
schema: wallet
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 23
row_count: null
generated_at: '2026-05-19T12:08:01Z'
upstreams:
- WalletBalancesReportDB.Wallet.FinanceReportRecords
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md
  source_database: WalletBalancesReportDB
  source_schema: Wallet
  source_table: FinanceReportRecords
  source_repo: CryptoDBs
  datalake_path: Bronze/WalletBalancesReportDB/Wallet/FinanceReportRecords
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 20
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_walletbalancesreportdb_wallet_financereportrecords

> Bronze ingest in `main.wallet` (1:1 passthrough of `WalletBalancesReportDB.Wallet.FinanceReportRecords`). 20 of 23 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 23 |
| **Generated** | 2026-05-19 |
| **Created** | Tue Nov 05 07:17:00 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `WalletBalancesReportDB.Wallet.FinanceReportRecords` (`CryptoDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md`.

- Lake path: `Bronze/WalletBalancesReportDB/Wallet/FinanceReportRecords`
- Copy strategy: `Append`
- Source database: `WalletBalancesReportDB` (`CryptoDBs`)
- Source schema/table: `Wallet.FinanceReportRecords`
- 20 of 23 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing primary key. Part of unique index IX_FinanceReportRecords__ReportId_WalletId_CryptoId for efficient lookups (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 1 | ReportId | LONG | YES | FK to Wallet.FinanceReportRuns.Id identifying which reconciliation run produced this record. Constraint: FK__FinanceReportRecords__ReportId. Indexed in composite with LevelId and with WalletId+CryptoId (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 2 | WalletId | STRING | YES | Crypto wallet identifier (GUID). Part of the composite business key (ReportId, WalletId, CryptoId). Used in CROSS APPLY joins by CreateNewReportRun and GetFinanceSnapshot to correlate with external table data (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 3 | Gcid | LONG | YES | Global Customer ID -- identifies the wallet owner. Carried from the external table for denormalized customer-level querying without joining back to WalletDB (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 4 | CryptoId | INT | YES | Cryptocurrency asset identifier. Completes the composite business key. Same CryptoId may appear multiple times per run if a customer has multiple wallets for the same crypto (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 5 | Address | STRING | YES | Blockchain address associated with this wallet-crypto pair. Passed through from the external table for traceability during discrepancy investigation. NULL for wallets without dedicated on-chain addresses (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 6 | BitgoWalletId | STRING | YES | BitGo custody platform's wallet identifier. Enables cross-referencing with BitGo's API for discrepancy investigation. Aliased as ProviderWalletId in GetFinanceReportRunDiscrepancies output (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 7 | BloxAccountId | STRING | YES | Blox portfolio tracker's account identifier. Always NULL in production data -- the current reconciliation system (CreateNewReportRun) does not populate this field, suggesting Blox account mapping was deprecated or moved to the application layer (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 8 | TotalReceive | DECIMAL | YES | Total amount received into this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalRecive (note: mapped from the misspelled column). Represents the cumulative incoming blockchain transactions (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 9 | TotalSend | DECIMAL | YES | Total amount sent from this wallet-crypto pair. Sourced from vu_GetWalletBalanceReport.TotalSend. Represents the cumulative outgoing blockchain transactions (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 10 | BloxBalance | DECIMAL | YES | Blockchain-reported net balance (TotalReceive - TotalSend). Despite the name suggesting "Blox balance," this is actually the blockchain/computed balance from the external table's TotalBalance column. The naming reflects the legacy system where Blox was the primary comparison source (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 11 | ComputedAmount | DECIMAL | YES | Internally computed expected balance from eToro's ledger system. Sourced from vu_GetWalletBalanceReport.TotalAmount. The reconciliation threshold check compares this against BloxBalance: `ABS(ComputedAmount - BloxBalance) > @Threshold` (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 12 | FindDiscrepancy | BOOLEAN | YES | Whether the final reconciliation result found a balance mismatch: 0 = no discrepancy (or not yet verified), 1 = confirmed discrepancy. Initially set to 0 by CreateNewReportRun; updated to 1 by UpdateReportRecords when verification confirms a mismatch (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 13 | BitgoValue | DECIMAL | YES | Balance amount reported by BitGo custody provider during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual BitGo API response. NULL/0 until the verification phase processes this record (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 14 | BloxValue | DECIMAL | YES | Balance amount reported by Blox portfolio tracker during the verification phase. Initially 0 (set by CreateNewReportRun). Updated by UpdateReportRecords with the actual Blox API response. NULL/0 until verification (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 15 | ErrorMsg | STRING | YES | Error message from the reconciliation verification phase. Contains API error details from BitGo or Blox when their endpoints fail. NULL when verification completes successfully. Set by UpdateReportRecords via the BalanceType TVP (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 16 | LevelId | INT | YES | FK to Dictionary.FinanceReportLevel classifying the reconciliation outcome. Initially set to 100 (InitialDiscrepancy) if balance exceeds threshold, NULL otherwise. Refined by UpdateReportRecords: 1=EventualyConsolidated, 2=AllDiff, 3=EtoroDiffBoth, 5-11=API errors, 12=InternalError. See [Finance Report Level](../../_glossary.md#finance-report-level) (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 17 | Created | TIMESTAMP | YES | UTC timestamp when this record was inserted by CreateNewReportRun. Default constraint DF_FinanceReportRecords_Created. Indexed in ix_FinanceReportRecords__WalletId_CryptoId_Created (DESC) for efficient "latest record per wallet" lookups used by CreateNewReportRun's incremental processing (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 18 | LastChecked | TIMESTAMP | YES | UTC timestamp of the most recent verification check for this record. NULL until the record is processed by UpdateReportRecords, which sets it to GETUTCDATE(). Used by CreateNewReportRun's incremental logic: `DATEDIFF(DAY, ISNULL(LastChecked, '2000-01-01'), GETUTCDATE()) >= @RetryDays` to determine if the record should be rechecked (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 19 | Retries | INT | YES | Number of times this wallet-crypto pair has been re-verified. Set by UpdateReportRecords via the BalanceType TVP. NULL on initial creation; 0+ after verification. Used to track persistent discrepancies that don't resolve after multiple attempts (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords). |
| 20 | etr_y | INT | YES | Source: WalletBalancesReportDB.Wallet.FinanceReportRecords.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | etr_ym | STRING | YES | Source: WalletBalancesReportDB.Wallet.FinanceReportRecords.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | etr_ymd | DATE | YES | Source: WalletBalancesReportDB.Wallet.FinanceReportRecords.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `WalletBalancesReportDB.Wallet.FinanceReportRecords` | Primary | `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` |

### 4.2 Pipeline ASCII Diagram

```
WalletBalancesReportDB.Wallet.FinanceReportRecords
        │
        ▼
main.wallet.bronze_walletbalancesreportdb_wallet_financereportrecords   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| ReportId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| WalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| Gcid | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| CryptoId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| Address | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| BitgoWalletId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| BloxAccountId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| TotalReceive | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| TotalSend | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| BloxBalance | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| ComputedAmount | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| FindDiscrepancy | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| BitgoValue | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| BloxValue | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| ErrorMsg | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| LevelId | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| Created | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| LastChecked | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| Retries | upstream wiki `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` (bronze passthrough) | 1 | (Tier 1 — inherited from WalletBalancesReportDB.Wallet.FinanceReportRecords) |
| etr_y | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/CryptoDBs/WalletBalancesReportDB/Wiki/Wallet/Tables/Wallet.FinanceReportRecords.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 20 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 23/23 | Source: bronze_tier1_inheritance*
