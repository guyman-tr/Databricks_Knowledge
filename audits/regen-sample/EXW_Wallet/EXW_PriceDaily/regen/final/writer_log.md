MCP PRE-FLIGHT: PASS

Now loading the rule files.
Rules loaded. Starting the pipeline.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 10 columns, HASH(CryptoID), CLUSTERED INDEX(FullDateID ASC, CryptoID ASC).

Now running Phase 2 (sampling) and row count.
**PHASE 2 CHECKPOINT: PASS** — 414,589 rows, date range 2018-04-23 to 2026-04-25. Sample retrieved.

Now Phase 3 — Distribution analysis. Categorical columns matching the regex: `CryptoName`, `BlockchainCryptoName`. Those are the only matches. Let me run distribution queries.
**PHASE 3 CHECKPOINT: PASS** — 173 distinct CryptoIDs, 13 distinct BlockchainCryptoName values (ETH dominant at 391K rows), 191 distinct InstrumentIDs, 61 distinct eToroInstrumentIDs (344K NULLs). No NULL AvgPrice.

**PHASE 4 CHECKPOINT: PASS** — No dim/dictionary FK lookups in this table. All IDs are internal wallet crypto identifiers.

**PHASE 5 CHECKPOINT: PASS** — SP_Prices JOIN pattern analyzed from bundle: joins EXW_Currency.Instruments, EXW_Currency.Currencies, EXW_Wallet.CryptoMarketRatesMappings, EXW_Wallet.CryptoTypes, EXW_Wallet.ETL_InstrumentRates_ByHour.

**PHASE 6 CHECKPOINT: PASS** — Business logic: daily crypto price aggregation. AvgPrice = (BidRateAvg + AskRateAvg)/2 from hourly rates, Rn=1 filter takes last hour's snapshot per CryptoId per day.

**PHASE 7 CHECKPOINT: [-]** — View scan skipped for regen-harness single-object mode (no grep across full SSDT).

**PHASE 8 CHECKPOINT: PASS** — Writer SP identified: EXW_Wallet.SP_Prices (from bundle).

**PHASE 9 CHECKPOINT: PASS** — SP logic fully analyzed from bundle. Column source mapping:

From the SP's final INSERT into EXW_PriceDaily:
- `InstrumentID` ← from #prices, which is CASE: if eToroInstrumentID >= 100000 then eToroInstrumentID else CryptoId. Source: #mapping (EXW_Currency.Instruments.Id / CryptoMarketRatesMappings.CryptoId)
- `eToroInstrumentID` ← #mapping.eToroInstrumentID ← EXW_Wallet.CryptoTypes.InstrumentId
- `CryptoID` ← #mapping.CryptoId ← EXW_Wallet.CryptoMarketRatesMappings.CryptoId
- `CryptoName` ← #mapping.CryptoName ← EXW_Wallet.CryptoMarketRatesMappings.MarketRatesCurrencySymbol
- `AvgPrice` ← #prices.AvgPrice ← computed (BidRateAvg + AskRateAvg)/2 from ETL_InstrumentRates_ByHour, with gap-fill from EXW_Wallet.EXW_Price
- `BlockchainCryptoId` ← #mapping.BlockchainCryptoId ← EXW_Wallet.CryptoTypes.BlockchainCryptoId
- `BlockchainCryptoName` ← #mapping.BlockchainCryptoName ← EXW_Wallet.CryptoTypes.Name (via ct1 alias)
- `FullDate` ← CAST(irh.DateHour AS DATE) from ETL_InstrumentRates_ByHour
- `FullDateID` ← CONVERT(VARCHAR(8), irh.DateHour, 112) from ETL_InstrumentRates_ByHour
- `UpdateDate` ← GETDATE()

**PHASE 9B CHECKPOINT: PASS** — SP_Prices runs daily with @dt parameter (date-partitioned DELETE+INSERT pattern).

**PHASE 10 CHECKPOINT: [-]** — Jira/Confluence scan skipped in regen-harness mode.

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki found (confirmed by `_no_upstream_found.txt`). All columns grounded via DDL + SP code.

Now writing Phase 10B (lineage) then Phase 11 (wiki + review-needed).
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.

Now writing the main wiki and review-needed files.
All three files written. Printing gate and output checks:

```
PHASE GATE — EXW_Wallet.EXW_PriceDaily:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (regen-harness, no full SSDT grep)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen-harness skip)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```

```
OUTPUT CHECK — EXW_Wallet.EXW_PriceDaily:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/EXW_PriceDaily/regen/attempt_1/EXW_PriceDaily.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/EXW_PriceDaily/regen/attempt_1/EXW_PriceDaily.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/EXW_PriceDaily/regen/attempt_1/EXW_PriceDaily.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 10    Tier3: 0    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
