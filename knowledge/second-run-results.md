# Second Run Results — Dim_Position with Manual Expert Corrections

> Post-generation review of `DWH_dbo.Dim_Position.md` wiki, `.alter.sql`, and `.review-needed.md` outputs.
> Second run date: 2026-03-02 | Expert review date: 2026-03-03

## What Changed Between Runs

### Pipeline Improvements (codified before run 2)
- Constitution v1.3.0 → v1.4.0: Added Tier 5 (domain expert), reviewer corrections, domain glossary
- Phase 11 rules 10-16 added: verbatim inheritance, confidence tiers, review sidecar, full upstream search, corrections on rerun, glossary, Tier 5 tagging
- Phase 9 updated: mandatory reader SP analysis (10 diverse SPs)
- Phase 10 updated: mandatory Atlassian scan (not deferrable)
- Phase 3 updated: sampling adds, never subtracts
- Phase 4 updated: full upstream wiki search scope + glossary consultation

### Clean-Slate Run Results
- Discovered 133 columns (vs 156 claimed in run 1 — run 1 included non-existent columns)
- Corrected data types and nullability from live Synapse metadata
- Successfully executed all 14 phases including Phase 10 (Atlassian scan)
- Analyzed 10 reader SPs for downstream consumption patterns
- Found relevant Confluence pages (Dim_Position summary, BI Dictionary)

### Expert Review Corrections (19 items)

| # | Column(s) | First Run Issue | Expert Correction | Tier |
|---|-----------|----------------|-------------------|------|
| 1 | Volume | [UNVERIFIED] "Trading volume at position open" | Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close. | 5 |
| 2 | VolumeOnClose | "Trading volume at position close" | Same as Volume but at close time. Pro-rated for partial close. | 5 |
| 3 | SettlementTypeID | Missing value 3, only 0/1/2/4/5 | Added 3=CMT (Crypto settled). Found in upstream wiki Trade.PositionTbl §2.2. | 5 |
| 4 | DLTOpen / DLTClose | "Distributed Ledger Technology — blockchain" | German crypto broker used for execution. Not generic DLT. | 5 |
| 5 | RedeemStatus / RedeemID | "NFT / Token redemption to external wallet" | Crypto redemption to eToro wallet. Status of full transaction loop. Nothing to do with NFTs. | 5 |
| 6 | IsAirDrop | "Promotional crypto airdrops" | eToro opens position on behalf of customer. Not just crypto — includes staking, promotions, compensations. | 5 |
| 7 | Commission / CommissionOnClose | "Spread commission" | eToro's markup (additional spread on top of market spread). Synonym: markup. | 5 |
| 8 | FullCommission / FullCommissionOnClose | "Total commission (spread + fees)" | Full spread = market spread (variable spread) + eToro markup. | 5 |
| 9 | CommissionByUnits / FullCommissionByUnits | "Commission/FullCommission prorated by units" | Same as above, prorated for partial close. Descriptions clarified. | 5 |
| 10 | OpenMarketSpread / CloseMarketSpread | "Bid-ask spread in market terms" | Market spread (aka variable spread) = Ask - Bid, before eToro markup. | 5 |
| 11 | OpenMarkup / CloseMarkup / CloseMarkupOnOpen | "Actual markup charged" | eToro's markup (additional spread). Same concept as Commission in spread terms. | 5 |
| 12 | OpenMarkupByUnits | "Open markup prorated by units" | Same, prorated for partial close. | 5 |
| 13 | CommissionVersion | "Computed as IIF(OpenMarketSpread IS NULL, NULL, 2)" | Commission calculation version — different versions/models. Detailed mapping TBD. | 5 |
| 14 | IsCopyFundPosition | "AccountTypeID=9 only" | Also true when MirrorTypeID=4 in Dim_Mirror. | 5 |
| 15 | OpenTotalFees / CloseTotalFees | "Regulatory/exchange fees" | Ticket fees — either fixed $ or % of position volume. Full breakdown in History.Cost. | 5 |
| 16 | Close_PnLInDollars | "End-of-day P&L at close" | Same as PnLInDollars but using closing price, not last (current) price. | 5 |
| 17 | Close_CalculationRate / Close_ConversionRate | "Rate for end-of-day P&L at close" | Rates used specifically to compute Close_PnLInDollars (closing-price-based P&L). | 5 |
| 18 | Close_PriceType | "Price type for close-side P&L" | Closing price source: official close, unofficial close, dealer injection, or last internal price. Value mapping TBD. | 5 |
| 19 | OpenPositionReasonID | "Maps to OpenActionType 0-18" | Confirmed as OpenActionType. 2000-series values in DWH = likely pipeline/ETL error. | 5 |

## Systemic Assessment vs First Run

| Issue from Run 1 | Status in Run 2 |
|------------------|----------------|
| 1. Paraphrasing vs verbatim | **Improved** — upstream wiki descriptions inherited verbatim for most columns. Some still paraphrased. |
| 2. Narrow upstream search | **Fixed** — searched views, related tables, full upstream wiki folder. |
| 3. Fabrication from column names | **Improved** — Tier 4 items flagged [UNVERIFIED], but some inferences still made it through as Tier 2 (e.g., CBH/HBC acronym expansion, DLT meaning). |
| 4. Expert review loop | **Implemented** — review sidecar generated, wiki-review skill created for conversational corrections, Tier 5 mechanism operational. |
| 5. Vectorization | **Not needed** — grep-based search across upstream wiki confirmed sufficient. |

## New Mechanisms Added This Session

| Mechanism | File | Purpose |
|-----------|------|---------|
| Review sidecar corrections | `*.review-needed.md` | Inbound expert corrections, read on rerun as Tier 5 |
| Domain glossary | `knowledge/glossary.md` | Cross-table domain terms at Tier 5 authority |
| wiki-review skill | `.cursor/skills/wiki-review/SKILL.md` | Conversational review — corrections propagate immediately to wiki + ALTER script |
| Constitution v1.4.0 | `.specify/memory/constitution.md` | Tier 5, corrections mechanism, glossary reference |
| Phase 11 rules 14-16 | `11-generate-documentation.mdc` | Read corrections/glossary on rerun, Tier 5 tagging |

## Items Still Unresolved

| Column | Status |
|--------|--------|
| PlatformTypeID | Skipped — always NULL, purpose unknown |
| PositionSegment | Skipped — always NULL, purpose unknown |
| OpenInd | Skipped — mostly NULL, trigger unknown |
| ExitOrderType | Skipped — values 19/20 unexplained |
| CloseDateID = 19000101 | Skipped — sentinel visibility question unanswered |
| CBH / HBC | Not yet corrected in files — user knows the answer (Compute Before Hedge / Hedge Before Compute) but wanted to test rerun flow |

## Next Step

Full clean-slate rerun of all 14 phases to validate that:
1. Sidecar corrections (Tier 5) override pipeline-inferred descriptions
2. Glossary terms override acronym inferences
3. Pipeline produces better baseline output with updated rules

---

*Companion to: knowledge/first-run-results.md*
*Files reviewed: DWH_dbo.Dim_Position.md, .alter.sql, .review-needed.md, glossary.md*
