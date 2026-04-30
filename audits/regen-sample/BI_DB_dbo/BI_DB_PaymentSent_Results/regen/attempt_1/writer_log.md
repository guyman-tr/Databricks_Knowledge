MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `BI_DB_dbo.BI_DB_PaymentSent_Results`.

**PHASE 1 — DDL Structure (from bundle)**

DDL has 11 columns: CID, Regulation, Currency, Amount$Withdraw, DaysInPaymentSentStatus, ModificationDate, WithdrawID, WithdrawProcessingID, FundingID, Provider, UpdateDate. Distribution: ROUND_ROBIN, CLUSTERED INDEX on CID.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and Phase 3 (distribution) queries.
Phase 2 sample shows **0 rows** currently in the table. Let me try a different row count approach and check distribution columns.
Table has **0 rows**. This is expected — the SP truncates and reloads daily, and it filters for cashouts in "Payment Sent" status with specific currency/timing rules. The table may be empty when no cashouts currently match.

PHASE 2 CHECKPOINT: PASS (0 rows — table is a truncate-reload operational snapshot; empty is a valid state)

**PHASE 3 — Distribution Analysis**

Categorical columns matching the regex: `Regulation`, `Currency`. Only 2 match. Table is empty so distribution queries would return nothing. Phase 3 is complete with no data to analyze.

PHASE 3 CHECKPOINT: PASS (0 rows — no distribution data available)

**PHASE 4 — Lookup Resolution**

From the SP code:
- `Dim_Customer` (RealCID → CID) — wiki in bundle
- `Dim_Currency` (CurrencyID → ProcessCurrencyID, Abbreviation → Currency) — wiki in bundle
- `Dim_CashoutStatus` (CashoutStatusID → filters for "Payment Sent") — wiki in bundle
- `Dim_FundingType` (FundingTypeID, filtered =2 for WIRES) — wiki in bundle
- `Dim_Regulation` (ID → RegulationID, Name → Regulation) — wiki in bundle

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis** (from SP code)

The SP has these JOINs:
1. `External_etoro_Billing_Withdraw fbd` — base withdraw table
2. `External_etoro_Billing_vWithdrawToFunding wtf ON wtf.WithdrawID=fbd.WithdrawID` — withdraw-to-funding details
3. `DWH_dbo.Dim_Customer dc ON dc.RealCID=fbd.CID` — customer dimension
4. `DWH_dbo.Dim_Currency CURR1 ON CURR1.CurrencyID=wtf.ProcessCurrencyID` — currency lookup
5. `DWH_dbo.Dim_CashoutStatus cs ON cs.CashoutStatusID=wtf.CashoutStatusID` — status lookup (used in filter)
6. `External_etoro_Billing_Funding_Datafactory Funding ON wtf.FundingID=Funding.FundingID` — funding details (filtered to FundingTypeID=2)
7. `DWH_dbo.Dim_FundingType ft ON ft.FundingTypeID=Funding.FundingTypeID` — funding type lookup
8. `DWH_dbo.Dim_Regulation dr ON dr.ID=dc.RegulationID` — regulation lookup
9. `External_etoro_Billing_Depot depo ON depo.DepotID=wtf.DepotID` — depot/provider lookup
10. `External_etoro_History_vWithdrawToFundingAction` — for LastUpdatedDate (Payment Sent status timing)

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**

Key business rules from SP:
1. **Wire-only filter**: Only FundingTypeID=2 (Wire transfers)
2. **Currency filter**: Only USD(1), EUR(2), GBP(3), AUD(5), CAD(7)
3. **Payment Sent status**: Only rows where CashoutStatus_Funding = 'Payment Sent' (CashoutStatusID=6 in history)
4. **4-week lookback**: ModificationDate >= 4 weeks ago
5. **Aging thresholds**: Different DaysInPaymentSentStatus thresholds by currency/regulation:
   - USD/EUR: >=1 day
   - AUD + CySEC: >2 days
   - AUD + non-CySEC: >1 day
   - GBP: >=1 day

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependencies**

Let me check for views referencing this table.
No views reference this table. Only the SP and DDL files exist.

PHASE 7 CHECKPOINT: PASS (no views reference this table)

**PHASE 8 — SP Scan**

Writer SP: `SP_H_PaymentSent_Results` (already in bundle). No other SPs reference this table.

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic** (traced from bundle SP code)

Column lineage traced through SP_H_PaymentSent_Results:

| Column | SP Source | Transform |
|--------|----------|-----------|
| CID | `fbd.CID` from External_etoro_Billing_Withdraw | Passthrough |
| Regulation | `dr.Name` from Dim_Regulation via Dim_Customer.RegulationID | Dim-lookup passthrough |
| Currency | `CURR1.Abbreviation` from Dim_Currency via wtf.ProcessCurrencyID | Dim-lookup passthrough |
| Amount$Withdraw | `wtf.Amount` from External_etoro_Billing_vWithdrawToFunding | Rename (Amount → Amount$Withdraw) |
| DaysInPaymentSentStatus | `CAST(GETDATE()-lu.LastUpdatedDate AS int)` | Computed (date arithmetic) |
| ModificationDate | `lu.LastUpdatedDate` = `MAX(w.ModificationDate)` from External_etoro_History_vWithdrawToFundingAction | Aggregated (MAX) |
| WithdrawID | `fbd.WithdrawID` / `c.WithdrawID` from External_etoro_Billing_Withdraw | Passthrough |
| WithdrawProcessingID | `wtf.ID` from External_etoro_Billing_vWithdrawToFunding | Rename (ID → WithdrawProcessingID) |
| FundingID | `wtf.FundingID` from External_etoro_Billing_vWithdrawToFunding | Passthrough |
| Provider | `depo.Name` from External_etoro_Billing_Depot | Rename (Name → Provider) |
| UpdateDate | `GETDATE()` | Purely synthesized |

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**

The SP performs TRUNCATE + INSERT daily. No orchestration dependencies beyond the external tables and DWH dimensions.

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**

No Atlassian MCP available for this session.

PHASE 10 CHECKPOINT: [-] (no Atlassian MCP)

**PHASE 10A — Upstream Wiki**

Bundle contains 5 upstream wikis: Dim_Customer, Dim_Currency, Dim_CashoutStatus, Dim_FundingType, Dim_Regulation. All used for dim-lookup passthrough columns (Regulation, Currency). CID inherits from Dim_Customer → Customer.CustomerStatic.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage** (writing .lineage.md FIRST)

Tier assignments:
1. **CID** — Passthrough from Billing_Withdraw.CID; Dim_Customer joins on RealCID=CID confirming same concept. Dim_Customer documents RealCID as Tier 1 — Customer.CustomerStatic. → **Tier 1 — Customer.CustomerStatic**
2. **Regulation** — Dim-lookup passthrough: `dr.Name`. Dim_Regulation.Name is Tier 1 — Dictionary.Regulation. → **Tier 1 — Dictionary.Regulation**
3. **Currency** — Dim-lookup passthrough: `CURR1.Abbreviation`. Dim_Currency.Abbreviation is Tier 1 — Dictionary.Currency. → **Tier 1 — Dictionary.Currency**
4. **Amount$Withdraw** — Rename of wtf.Amount, no upstream wiki. → **Tier 2 — External_etoro_Billing_vWithdrawToFunding**
5. **DaysInPaymentSentStatus** — Computed: `CAST(GETDATE()-LastUpdatedDate AS int)`. → **Tier 2 — External_etoro_History_vWithdrawToFundingAction**
6. **ModificationDate** — `MAX(ModificationDate)` aggregation. → **Tier 2 — External_etoro_History_vWithdrawToFundingAction**
7. **WithdrawID** — Passthrough from Billing_Withdraw, no upstream wiki. → **Tier 2 — External_etoro_Billing_Withdraw**
8. **WithdrawProcessingID** — Rename of wtf.ID, no upstream wiki. → **Tier 2 — External_etoro_Billing_vWithdrawToFunding**
9. **FundingID** — Passthrough from wtf.FundingID, no upstream wiki. → **Tier 2 — External_etoro_Billing_vWithdrawToFunding**
10. **Provider** — Rename of depo.Name, no upstream wiki. → **Tier 2 — External_etoro_Billing_Depot**
11. **UpdateDate** — `GETDATE()`. Purely synthesized. → **Tier 2 — SP_H_PaymentSent_Results**

PHASE 10B CHECKPOINT: PASS

```
PHASE GATE — BI_DB_dbo.BI_DB_PaymentSent_Results:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no Atlassian MCP)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final verification:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PaymentSent_Results:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PaymentSent_Results/regen/attempt_1/BI_DB_PaymentSent_Results.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PaymentSent_Results/regen/attempt_1/BI_DB_PaymentSent_Results.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PaymentSent_Results/regen/attempt_1/BI_DB_PaymentSent_Results.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 3    Tier2: 8    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
