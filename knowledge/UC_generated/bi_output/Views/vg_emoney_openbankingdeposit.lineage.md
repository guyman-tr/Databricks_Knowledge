# Column Lineage: main.bi_output.vg_emoney_openbankingdeposit

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_openbankingdeposit` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoney_openbankingdeposit.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoney_openbankingdeposit.json` (rows: 6, mismatches: 2) |
| **Primary upstream** | `main.bi_db.bronze_moneytransfer_billing_transfers` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.bronze_moneytransfer_billing_transfers` | Primary (FROM) | ✓ `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |

## Lineage Chain

```
main.bi_db.bronze_moneytransfer_billing_transfers   ←── primary upstream
        │
        ▼
main.bi_output.vg_emoney_openbankingdeposit   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.bronze_moneytransfer_billing_transfers` | `CID` | `passthrough` | — | CID |
| 2 | `OpenBankingDeposit_Attempt_ID` | `main.bi_db.bronze_moneytransfer_billing_transfers` | `TransferID` | `rename` | — | TransferID AS OpenBankingDeposit_Attempt_ID |
| 3 | `OpenBankingDeposit_Attempt_Status` | `main.bi_db.bronze_moneytransfer_billing_transfers` | `—` | `case` | — | CASE WHEN TransferStatusID = 10 THEN 'Success' ELSE 'Pending_or_Failed' END AS OpenBankingDeposit_Attempt_Status |
| 4 | `OpenBankingDeposit_Provider` | `main.bi_db.bronze_moneytransfer_billing_transfers` | `—` | `case` | — | CASE WHEN LEFT(p.ExReferenceID, 2) = 'TZ' THEN 'Volt' WHEN LEFT(p.ExReferenceID, 2) = 'TK' THEN 'Tink' ELSE 'Other' END AS OpenBankingDeposi |
| 5 | `OpenBankingDeposit_Attempt_USDAmount` | `main.bi_db.bronze_moneytransfer_billing_transfers` | `Amount` | `rename` | — | Amount AS OpenBankingDeposit_Attempt_USDAmount |
| 6 | `OpenBankingDeposit_Attempt_Date` | `main.bi_db.bronze_moneytransfer_billing_transfers` | `ModificationDate` | `rename` | — | ModificationDate AS OpenBankingDeposit_Attempt_Date |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **4**, WARN: **0**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `OpenBankingDeposit_Attempt_Status` | — | `main.bi_db.bronze_moneytransfer_billing_transfers.transferstatusid` | ERROR |
| `OpenBankingDeposit_Provider` | — | `main.bi_db.bronze_moneytransfer_billing_transfers.exreferenceid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
