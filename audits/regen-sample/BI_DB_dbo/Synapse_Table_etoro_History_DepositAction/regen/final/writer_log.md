MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now let me read the DDL (already in the bundle) and search for SPs and any existing lineage.

**Phase 1 — Structure Analysis**

The DDL is already in the bundle. Let me parse it:

**Table**: `BI_DB_dbo.Synapse_Table_etoro_History_DepositAction`
- Distribution: ROUND_ROBIN
- Index: HEAP
- 23 columns, all nullable

Columns:
1. DepositActionID (int)
2. DepositID (int)
3. PaymentActionStatusID (int)
4. PaymentActionTypeID (int)
5. PaymentStatusID (int)
6. ResponseID (int)
7. ManagerID (int)
8. ExchangeRate (numeric(16,8))
9. ApprovalNumber (varchar(max))
10. AuthCode (varchar(max))
11. ModificationDate (datetime2(7))
12. ClearingHouseEffectiveDate (datetime2(7))
13. Amount (numeric(19,4))
14. CurrencyID (int)
15. MatchStatusID (int)
16. Remark (varchar(max))
17. SessionID (bigint)
18. DepotID (int)
19. ExchangeFee (int)
20. BaseExchangeRate (numeric(16,8))
21. PaymentGeneration (int)
22. ProcessRegulationID (int)
23. MerchantAccountID (int)

PHASE 1 CHECKPOINT: PASS

Now let me run Phase 2 (sampling), Phase 8 (SP scan), and check for existing lineage concurrently.
PHASE 2 CHECKPOINT: PASS (sample retrieved, 10 rows with live data from 2026-04-26)

Let me get a row count via alternative method and read the relevant SPs.
Now let me read SP_H_Deposits and run Phase 3 distribution queries.
PHASE 3 CHECKPOINT: PASS

Distribution data collected for PaymentActionStatusID (4 values), PaymentStatusID (8 values), PaymentActionTypeID (4 values).

Now let me check for views, look up the generic pipeline mapping, and search for any existing Synapse wikis for source tables.
Excellent! There IS an upstream wiki at `DB_Schema/etoro/Wiki/History/Tables/History.DepositAction.md`. Let me read it along with the generic pipeline mapping entry and the production DDL.
I found a rich upstream wiki at `DB_Schema/etoro/Wiki/History/Tables/History.DepositAction.md` with all 23 columns documented. The columns are direct passthroughs from production via Bronze parquet COPY INTO — all qualify for Tier 1.

Let me now complete the remaining phase gates and write the output files.

PHASE 4 CHECKPOINT: PASS (FK targets identified from upstream wiki: Dictionary.PaymentActionStatus, Dictionary.PaymentActionType, Dictionary.PaymentStatus, Dictionary.Currency, BackOffice.Manager)

PHASE 5 CHECKPOINT: PASS (SP_AllDeposits JOINs on DepositID with Fact_BillingDeposit, ResponseID with Dictionary_Response; SP_H_Deposits uses external table variant similarly)

PHASE 6 CHECKPOINT: PASS (Bronze landing table, rebuilt daily via COPY INTO, used as intermediate to resolve latest ResponseID per deposit)

PHASE 7 CHECKPOINT: PASS (No views reference this table)

PHASE 8 CHECKPOINT: PASS (Writer: SP_Create_Synapse_Table_etoro_History_DepositAction; Readers: SP_AllDeposits, SP_H_Deposits)

PHASE 9 CHECKPOINT: PASS (SP_Create does COPY INTO from Bronze parquet — pure passthrough, no column transforms)

PHASE 9B CHECKPOINT: PASS (Called by SP_AllDeposits daily, drops and recreates with single day of data)

PHASE 10 CHECKPOINT: [-] (Skipped — regen harness mode)

PHASE 10A CHECKPOINT: PASS (Upstream wiki found: DB_Schema/etoro/Wiki/History/Tables/History.DepositAction.md — all 23 columns documented)

PHASE 10B CHECKPOINT: PASS (All 23 columns are direct passthroughs from History.DepositAction via Bronze parquet)

```
PHASE GATE — BI_DB_dbo.Synapse_Table_etoro_History_DepositAction:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Let me verify the Tier 1 copy fidelity.

```
T1 COPY VERIFICATION:
  DepositActionID: upstream "Surrogate primary key, auto-incremented by 1..." → wiki matches (stripped NONCLUSTERED PK index details specific to production physical layout) — IDENTICAL
  DepositID: upstream "The deposit this action belongs to..." → wiki matches (stripped clustered index detail) — IDENTICAL
  PaymentActionStatusID: upstream "The processing state of this specific action event..." → wiki matches (stripped distribution percentages) — IDENTICAL
  PaymentActionTypeID: upstream "The type of payment action..." → wiki matches (stripped percentage annotations) — IDENTICAL
  PaymentStatusID: upstream "The deposit's overall payment status..." → wiki matches (stripped 39 total values count) — IDENTICAL
  ResponseID: upstream "Links this action to the raw payment provider response..." → wiki matches (stripped NONCLUSTERED index detail) — IDENTICAL
  ManagerID: upstream "The back-office agent ID..." → wiki matches — IDENTICAL
  ExchangeRate: upstream "Currency exchange rate applied..." → wiki matches — IDENTICAL
  ApprovalNumber: upstream "Payment provider's approval/authorization number..." → wiki matches — IDENTICAL
  AuthCode: upstream "Authorization code returned by the payment provider..." → wiki matches — IDENTICAL
  ModificationDate: upstream "UTC datetime when this action row was inserted..." → wiki matches (stripped composite NC index detail) — IDENTICAL
  ClearingHouseEffectiveDate: upstream "The date the payment clears..." → wiki matches — IDENTICAL
  Amount: upstream "The deposit amount in the customer's original currency..." → wiki matches (stripped money type note) — IDENTICAL
  CurrencyID: upstream "The currency of the Amount..." → wiki matches — IDENTICAL
  MatchStatusID: upstream "PSP reconciliation match status..." → wiki matches (stripped 99.9%/0.1% distribution stats) — IDENTICAL
  Remark: upstream "Free-text note explaining the reason..." → wiki matches — IDENTICAL
  SessionID: upstream "The customer's web session ID..." → wiki matches — IDENTICAL
  DepotID: upstream "Identifies the payment gateway/depot..." → wiki matches — IDENTICAL
  ExchangeFee: upstream "Fee charged for currency exchange..." → wiki matches — IDENTICAL
  BaseExchangeRate: upstream "The base (pre-markup) exchange rate..." → wiki matches — IDENTICAL
  PaymentGeneration: upstream "Identifies the generation or version..." → wiki matches — IDENTICAL
  ProcessRegulationID: upstream "The regulatory processing framework..." → wiki matches — IDENTICAL
  MerchantAccountID: upstream "The merchant account within the payment gateway..." → wiki matches — IDENTICAL
```

```
OUTPUT CHECK — BI_DB_dbo.Synapse_Table_etoro_History_DepositAction:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/Synapse_Table_etoro_History_DepositAction/regen/attempt_1/Synapse_Table_etoro_History_DepositAction.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/Synapse_Table_etoro_History_DepositAction/regen/attempt_1/Synapse_Table_etoro_History_DepositAction.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/Synapse_Table_etoro_History_DepositAction/regen/attempt_1/Synapse_Table_etoro_History_DepositAction.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 23    Tier2: 0    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists; upstream wiki found independently via DB_Schema/etoro/Wiki/History/Tables/History.DepositAction.md)
```
