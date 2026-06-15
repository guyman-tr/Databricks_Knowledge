---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 99
row_count: null
generated_at: '2026-05-19T12:12:58Z'
upstreams:
- fiktivo.dbo.tblaff_PaymentHistory
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_PaymentHistory
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_PaymentHistory
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 29
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 70
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_paymenthistory

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_PaymentHistory`). 29 of 99 columns inherited from Tier 1 source wiki; 70 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 99 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 04:16:40 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_PaymentHistory` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_PaymentHistory`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_PaymentHistory`
- 29 of 99 columns inherited; 70 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentID | INT | YES | Auto-incrementing primary key. NOT FOR REPLICATION. Referenced by all _Commissions tables' PaymentID column and tblaff_Files.PaymentID (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 1 | AffiliateID | INT | YES | The affiliate receiving this payment. Trigger enforces RI against tblaff_Affiliates (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 2 | PaymentDate | TIMESTAMP | YES | When the payment record was created (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 3 | PaymentAmount | DOUBLE | YES | Total payment amount: sum of all tier commissions + adjustment (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 4 | PaymentAdjustment | DOUBLE | YES | Manual adjustment amount applied by finance. Positive = bonus, negative = deduction (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 5 | PaymentDescription | STRING | YES | Short description/label for this payment (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 6 | Tier1CPA | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1CPA. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 7 | Tier2CPA | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2CPA. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 8 | Tier3CPA | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3CPA. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 9 | Tier4CPA | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4CPA. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | Tier5CPA | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5CPA. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | Tier1CPACommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1CPACommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 12 | Tier2CPACommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2CPACommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 13 | Tier3CPACommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3CPACommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 14 | Tier4CPACommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4CPACommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 15 | Tier5CPACommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5CPACommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 16 | Tier1Sales | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1Sales. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 17 | Tier2Sales | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2Sales. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 18 | Tier3Sales | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3Sales. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 19 | Tier4Sales | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4Sales. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 20 | Tier5Sales | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5Sales. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | Tier1SalesCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1SalesCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | Tier2SalesCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2SalesCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 23 | Tier3SalesCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3SalesCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 24 | Tier4SalesCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4SalesCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 25 | Tier5SalesCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5SalesCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 26 | Tier1Registrations | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1Registrations. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 27 | Tier2Registrations | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2Registrations. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 28 | Tier3Registrations | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3Registrations. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 29 | Tier4Registrations | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4Registrations. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 30 | Tier5Registrations | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5Registrations. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 31 | Tier1RegistrationsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1RegistrationsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 32 | Tier2RegistrationsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2RegistrationsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 33 | Tier3RegistrationsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3RegistrationsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 34 | Tier4RegistrationsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4RegistrationsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 35 | Tier5RegistrationsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5RegistrationsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 36 | Tier1Leads | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1Leads. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 37 | Tier2Leads | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2Leads. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 38 | Tier3Leads | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3Leads. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 39 | Tier4Leads | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4Leads. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 40 | Tier5Leads | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5Leads. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 41 | Tier1LeadsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1LeadsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 42 | Tier2LeadsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2LeadsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 43 | Tier3LeadsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3LeadsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 44 | Tier4LeadsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4LeadsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 45 | Tier5LeadsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5LeadsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 46 | Tier1Clicks | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1Clicks. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 47 | Tier2Clicks | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2Clicks. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 48 | Tier3Clicks | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3Clicks. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 49 | Tier4Clicks | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4Clicks. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 50 | Tier5Clicks | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5Clicks. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 51 | Tier1ClicksCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1ClicksCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 52 | Tier2ClicksCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2ClicksCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 53 | Tier3ClicksCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3ClicksCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 54 | Tier4ClicksCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4ClicksCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 55 | Tier5ClicksCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5ClicksCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 56 | PaymentRange | STRING | YES | Date range label for this payment period (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 57 | Comment | STRING | YES | Free-text comment from finance/approver (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 58 | ManagerApproved | BOOLEAN | YES | First-level approval by account manager (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 59 | Approved | BOOLEAN | YES | Final aggregate approval flag (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 60 | ApprovalDate | TIMESTAMP | YES | When the final approval was granted (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 61 | RequestedBy | INT | YES | Admin user ID who created/requested this payment (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 62 | ApprovedBy | INT | YES | Admin user ID who gave final approval (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 63 | VPMarketingApproved | BOOLEAN | YES | Second-level VP Marketing approval (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 64 | CurrencyID | INT | YES | Payment currency. Default 1 = USD. References Dictionary.Currency (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 65 | LastApprovalDate | TIMESTAMP | YES | Timestamp of the most recent approval step (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 66 | Tier1eCostCommission | DOUBLE | YES | eCost commission amount (Tier 1 only - no multi-tier for eCost in this summary) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 67 | PaymentDetailsID | LONG | YES | References the affiliate's payment method/bank details (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 68 | PaymentDetailsOnApprove | STRING | YES | Snapshot of payment details captured at approval time for audit (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 69 | PaymentMethodOnApprove | INT | YES | Payment method code captured at approval time (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 70 | Tier1CopyTraders | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1CopyTraders. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 71 | Tier2CopyTraders | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2CopyTraders. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 72 | Tier3CopyTraders | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3CopyTraders. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 73 | Tier4CopyTraders | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4CopyTraders. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 74 | Tier5CopyTraders | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5CopyTraders. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 75 | Tier1CopyTradersCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1CopyTradersCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 76 | Tier2CopyTradersCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2CopyTradersCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 77 | Tier3CopyTradersCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3CopyTradersCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 78 | Tier4CopyTradersCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4CopyTradersCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 79 | Tier5CopyTradersCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5CopyTradersCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 80 | Tier1FirstPositions | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1FirstPositions. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 81 | Tier2FirstPositions | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2FirstPositions. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 82 | Tier3FirstPositions | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3FirstPositions. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 83 | Tier4FirstPositions | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4FirstPositions. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 84 | Tier5FirstPositions | INT | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5FirstPositions. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 85 | Tier1FirstPositionsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier1FirstPositionsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 86 | Tier2FirstPositionsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier2FirstPositionsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 87 | Tier3FirstPositionsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier3FirstPositionsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 88 | Tier4FirstPositionsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier4FirstPositionsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 89 | Tier5FirstPositionsCommission | DOUBLE | YES | Source: fiktivo.dbo.tblaff_PaymentHistory.Tier5FirstPositionsCommission. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 90 | PaymentRowStatusID | INT | YES | Payment processing status. FK to Dictionary.PaymentRowStatus: 1=Pending, 2=Partially Approved, 4=Approved, 8=Processed, 16=Rejected. See [Payment Row Status](../../_glossary.md#payment-row-status) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 91 | eCostHistoryID | INT | YES | References tblaff_eCostHistory.eCostHistoryID (explicit FK). Links this payment to an eCost reconciliation record. NULL when no eCost linkage (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 92 | FinanceApproved | BOOLEAN | YES | Third-level finance team approval (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 93 | PaymentPeriod | DATE | YES | The payment period this batch covers (first day of month). E.g., 2026-02-01 = February 2026 commissions (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 94 | PaymentGroupCode | STRING | YES | GUID grouping related payment rows into a single batch for bulk processing (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 95 | AmountInCurrency | DECIMAL | YES | Payment amount converted to the affiliate's preferred currency (per CurrencyID) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 96 | ReferenceNumber | STRING | YES | External payment reference number (bank transfer reference, wire confirmation, etc.) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 97 | RowVersion | BINARY | YES | Optimistic concurrency control. Auto-incrementing binary value used to detect concurrent updates (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |
| 98 | FinanceManagerApproved | BOOLEAN | YES | Fourth-level finance manager approval for high-value payments (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_PaymentHistory` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_PaymentHistory
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory   ←── this object
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
| PaymentID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentAmount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentAdjustment | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentDescription | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| Tier1CPA | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1CPA` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2CPA | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2CPA` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3CPA | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3CPA` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4CPA | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4CPA` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5CPA | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5CPA` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1CPACommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1CPACommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2CPACommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2CPACommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3CPACommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3CPACommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4CPACommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4CPACommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5CPACommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5CPACommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1Sales | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1Sales` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2Sales | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2Sales` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3Sales | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3Sales` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4Sales | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4Sales` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5Sales | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5Sales` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1SalesCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1SalesCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2SalesCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2SalesCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3SalesCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3SalesCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4SalesCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4SalesCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5SalesCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5SalesCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1Registrations | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1Registrations` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2Registrations | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2Registrations` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3Registrations | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3Registrations` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4Registrations | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4Registrations` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5Registrations | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5Registrations` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1RegistrationsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1RegistrationsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2RegistrationsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2RegistrationsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3RegistrationsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3RegistrationsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4RegistrationsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4RegistrationsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5RegistrationsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5RegistrationsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1Leads | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1Leads` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2Leads | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2Leads` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3Leads | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3Leads` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4Leads | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4Leads` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5Leads | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5Leads` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1LeadsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1LeadsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2LeadsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2LeadsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3LeadsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3LeadsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4LeadsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4LeadsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5LeadsCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5LeadsCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1Clicks | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1Clicks` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2Clicks | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2Clicks` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3Clicks | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3Clicks` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4Clicks | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4Clicks` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5Clicks | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5Clicks` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1ClicksCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1ClicksCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2ClicksCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2ClicksCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3ClicksCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3ClicksCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4ClicksCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4ClicksCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5ClicksCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5ClicksCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| PaymentRange | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| Comment | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| ManagerApproved | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| Approved | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| ApprovalDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| RequestedBy | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| ApprovedBy | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| VPMarketingApproved | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| LastApprovalDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| Tier1eCostCommission | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentDetailsID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentDetailsOnApprove | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| PaymentMethodOnApprove | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentHistory) |
| Tier1CopyTraders | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1CopyTraders` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2CopyTraders | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2CopyTraders` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3CopyTraders | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3CopyTraders` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4CopyTraders | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4CopyTraders` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5CopyTraders | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5CopyTraders` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier1CopyTradersCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier1CopyTradersCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier2CopyTradersCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier2CopyTradersCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier3CopyTradersCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier3CopyTradersCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier4CopyTradersCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier4CopyTradersCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| Tier5CopyTradersCommission | would inherit from `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md` but column `Tier5CopyTradersCommission` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| ... +19 more rows | ... | ... | ... |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 29 T1, 0 T2, 0 T3, 0 T4, 0 T5, 70 TN, 0 U | Elements: 99/99 | Source: bronze_tier1_inheritance*
