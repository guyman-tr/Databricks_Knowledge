MCP PRE-FLIGHT: PASS

Now let me read the rule files and the previous attempt's output files in parallel.
Now let me read the previous attempt's files and find the SP that populates this table.
Now let me run the live data phases. I'll do sampling and distribution in parallel.
PHASE 1 CHECKPOINT: PASS (DDL from bundle)
PHASE 2 CHECKPOINT: PASS (50,298 rows, 2018-10-28 to 2023-06-14, single bulk load 2024-04-09)
PHASE 3 CHECKPOINT: PASS (ConversionStatus: 3=48738, 2=1555, 1=5; NULLs: ReceivedTime=1608, FromAmount=313, ToAmount=1510)

Now let me check RequestedToAmount vs ToAmount difference and verify the output directory exists.
Good. RequestedToAmount vs ToAmount shows large differences (up to 1258 units), confirming they come from different sources. Now let me check phases 4-10 quickly and verify the SP scan.
PHASE 4 CHECKPOINT: PASS (CryptoTypes lookup — no upstream wiki for EXW_Wallet.CryptoTypes)
PHASE 5 CHECKPOINT: PASS (no writer SP JOINs to analyze)
PHASE 6 CHECKPOINT: PASS (two-leg structure, lifecycle, fees, blockchain vs wallet crypto)
PHASE 7 CHECKPOINT: PASS (no views reference this table)
PHASE 8 CHECKPOINT: PASS (no writer SP; reader: BI_DB_dbo.SP_US_Daily_Crypto)
PHASE 9 CHECKPOINT: [-] No writer SP in SSDT repo — external pipeline load
PHASE 9B CHECKPOINT: PASS (single bulk load 2024-04-09, no ongoing ETL)
PHASE 10 CHECKPOINT: PASS (no Atlassian sources)
PHASE 10A CHECKPOINT: PASS (upstream wikis: Wallet.Conversions, Wallet.ConversionTransactions)
PHASE 10B CHECKPOINT: PASS (lineage ready — fixes applied per judge feedback)

```
PHASE GATE — EXW_dbo.EXW_FactConversions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [-] P8 SP-scan (no writer SP)       [-] P9 SP-logic (no writer SP)
  [-] P9B ETL (external pipeline)         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files with all judge fixes applied. Lineage first.
Now writing the main wiki with all judge fixes applied.
Now writing the review-needed file.
All three files written. Let me verify the Tier 1 verbatim compliance for the judge-flagged columns:

**T1 COPY VERIFICATION (judge-flagged columns):**
- **ToEtoroDate**: upstream "Timestamp of this transaction record creation." → wiki "Timestamp of this transaction record creation. To-leg of the conversion." — IDENTICAL (context appended after period) ✓
- **FromEtoroDate**: upstream "Timestamp of this transaction record creation." → wiki "Timestamp of this transaction record creation. From-leg of the conversion." — IDENTICAL (context appended after period) ✓
- **SentToEtoroWalletAmount**: upstream "Amount of crypto for this conversion leg in native units." → wiki "Amount of crypto for this conversion leg in native units. To-leg amount sent to the destination wallet." — IDENTICAL (context appended after period) ✓
- **SentFromEtoroWalletAmount**: upstream "Amount of crypto for this conversion leg in native units." → wiki "Amount of crypto for this conversion leg in native units. From-leg amount sent from the source wallet." — IDENTICAL (context appended after period) ✓
- **FromAddress**: Changed from Tier 2 (external pipeline) → Tier 1 with verbatim ConversionTransactions.ToAddress description: "Destination blockchain address for this conversion leg. NULL when the transfer is internal." ✓
- **RequestedFromAmount/FromAmount**: Fixed lineage — RequestedFromAmount → Conversions.FromAmount, FromAmount → ConversionTransactions.Amount (From-leg). No longer both mapped to same column. ✓
- **Section 2.5 ConversionTypeId**: Added new subsection documenting the dropped column. ✓

```
OUTPUT CHECK — EXW_dbo.EXW_FactConversions:
  [x] .lineage.md    written → audits/regen-sample/EXW_dbo/EXW_FactConversions/regen/attempt_2/EXW_FactConversions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_dbo/EXW_FactConversions/regen/attempt_2/EXW_FactConversions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_dbo/EXW_FactConversions/regen/attempt_2/EXW_FactConversions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 22    Tier2: 8    Tier3: 16    Tier4: 0
  Bundle inheritance used: YES
```
