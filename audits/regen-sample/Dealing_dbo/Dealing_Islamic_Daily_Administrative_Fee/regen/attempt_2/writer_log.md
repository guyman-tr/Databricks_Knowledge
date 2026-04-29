Starting MCP pre-flight check.
MCP PRE-FLIGHT: PASS

Now loading the required rule files and the previous attempt's output to understand what needs fixing.
Now let me check for the previous attempt's files and read them so I know what to fix.
Now I have a clear picture of the judge's feedback. Let me run the pipeline phases. I'll start with Phase 2 (sampling) and Phase 3 (distribution) via MCP.
PHASE 2 CHECKPOINT: PASS — 17.9M rows, 2022-12-30 to 2026-04-25, live sampling confirmed.
PHASE 3 CHECKPOINT: PASS — Distribution by asset class confirmed, ~54% of rows actually charged.

Now I have all the data I need. The previous attempt's structure (Sections 1-3, 5-8) is solid. I need to fix the specific columns flagged by the judge. Let me write all three output files.

PHASE GATE — Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no Atlassian MCP)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Writing all three files now. First the lineage, then the wiki, then review-needed.
Now writing the main wiki with all judge-flagged fixes applied.
All three files written. Let me verify the tier counts match.

```
T1 COPY VERIFICATION:
  PositionID (#3):     upstream "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." — IDENTICAL
  RealCID (#4):        upstream "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." — IDENTICAL
  GCID (#5):           upstream "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." — IDENTICAL
  UserName (#6):       upstream "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." — IDENTICAL
  OpenDateID (#7):     upstream "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default." — IDENTICAL
  CloseDateID (#8):    upstream "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause." — IDENTICAL
  OpenOccurred (#9):   upstream "When position was persisted (mapped from Occurred in production). Default getutcdate()." — IDENTICAL
  CloseOccurred (#11): upstream "When close was persisted." — IDENTICAL
  InstrumentID (#16):  upstream "FK to Trade.Instrument. Financial instrument being traded." — IDENTICAL
  IsBuy (#24):         upstream "1 = Long/Buy (profit when price rises), 0 = Short/Sell." — IDENTICAL
  Leverage (#25):      upstream "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." — IDENTICAL
  Bid (#28):           upstream "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread." — IDENTICAL
  Ask (#29):           upstream "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread." — IDENTICAL
  ConvertRateIsBuy_1 (#30): upstream "Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined." — IDENTICAL (stripped "Added 2023-02-26" snapshot stat)
  ConvertRateIsBuy_0 (#31): upstream "Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined." — IDENTICAL (stripped "Added 2023-02-26" snapshot stat)
  AmountInUnitsDecimal (#33): upstream "Position size in units/shares. Fractional lots." — IDENTICAL
  InstrumentType_ID_InstrumentGroup (#18): upstream "Asset class: 1=Currencies, 2=Commodities, 4=Indices." — IDENTICAL
  InstrumentName_InstrumentGroup (#19): upstream "Instrument name (e.g., "EUR/USD", "GBP/USD"). From manual configuration." — IDENTICAL
  InstrumentGroup (#20): upstream "Fee tier group (1-4). Maps to Dealing_Islamic_Admin_Fee_Per_Group.instrument_group for fee rate lookup." — IDENTICAL
  Units_per_Contract (#21): upstream "Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces." — IDENTICAL
  Admin_Fee_USD (#34): upstream "Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4)." — IDENTICAL
  GracePeriod (#36):   upstream "Number of trading days before fee starts. Currently 7 for all groups." — IDENTICAL
  CountryID (#42):     upstream "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." — IDENTICAL
```

```
OUTPUT CHECK — Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_2/Dealing_Islamic_Daily_Administrative_Fee.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_2/Dealing_Islamic_Daily_Administrative_Fee.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Islamic_Daily_Administrative_Fee/regen/attempt_2/Dealing_Islamic_Daily_Administrative_Fee.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 23    Tier2: 19    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
