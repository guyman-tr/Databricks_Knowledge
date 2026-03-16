# DWH_dbo.Dim_Position — Review Needed

> Items requiring human domain expert review. Generated alongside the wiki documentation.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed) override on the next pipeline rerun. Use `glossary` in the Scope column if the term should also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| Volume | Trading volume at position open. | Open volume = rounded(Units * Price * ConversionRate). Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal. | table | Guy | 2026-03-03 |
| OpenPositionReasonID | Maps to upstream OpenActionType (0-18) but DWH shows 2013-2023 values | Column IS OpenActionType — the 2000-series values are likely a pipeline/ETL error. The upstream dictionary (0=Customer, 1=Hierarchical, etc.) is correct. Flag data quality issue. | table | Guy | 2026-03-03 |
| Close_PriceType | No description | Closing price source type. Indicates how the closing price was determined: from a price provider (official exchange close), from dealer injection (a few minutes before market close), or the last price in the internal price feed. Exact value-to-source mapping TBD. | table | Guy | 2026-03-03 |
| CommissionVersion | Computed as IIF(OpenMarketSpread IS NULL, NULL, 2) | Commission calculation version. Different values represent different versions/models of how commission is computed on the position. Detailed value mapping TBD — pending documentation upload. | table | Guy | 2026-03-03 |
| VolumeOnClose | Cast(AmountInUnitsDecimal as Float) | Close volume = rounded(Units * Price * ConversionRate) at close. Same calculation as Volume but using close-time values. Pro-rated for partial close — parents and children each show volume pro-rated to their own AmountInUnitsDecimal. | table | Guy | 2026-03-03 |
| Table size (133 cols) | 133 columns — mismatch with production 117+ | Approved. 133 is correct. DWH intentionally excludes some production columns and adds derived columns (InitForex_*, OpenMarket_*, IsPartialCloseParent, etc.). | table | Guy | 2026-03-03 |
| OpenMarket_* columns | NULL for pre-2023 positions, backfill? | Dismissed — no backfill planned. Analysts should expect NULLs for pre-2023 positions. | table | Guy | 2026-03-03 |
| SWITCH PARTITION | Monitoring for schema-out-of-sync failures? | Dismissed — not in scope for wiki documentation. Operational concern. | table | Guy | 2026-03-03 |
| SettlementTypeID | Missing value 3, incomplete map | Full value map: 0=CFD, 1=REAL (owns shares), 2=TRS (Total Return Swap — crypto), 3=CMT (Crypto settled — isSettled=true + crypto instrument), 4=REAL_FUTURES, 5=MARGIN_TRADE. Source: upstream wiki Trade.PositionTbl §2.2 | glossary | Guy | 2026-03-03 |
| DLTOpen / DLTClose | DLT = Distributed Ledger Technology, blockchain execution | DLT refers to a German crypto broker used for execution. DLTOpen=1 means position was opened on the DLT broker platform. DLTClose=1 means closed on their platform. Not a generic blockchain/DLT indicator. | glossary | Guy | 2026-03-03 |
| RedeemStatus / RedeemID | NFT / Token redemption to external wallet | Crypto redemption to eToro wallet. User can redeem an eToro crypto position to actual crypto in their eToro crypto wallet. Nothing to do with NFTs. 0=N/A, 1=PositionPending, 6=PositionClosed (closed by redeem), 20=Terminated (closed by other reason while pending), 21=FailedToCancel | table | Guy | 2026-03-03 |
| IsAirDrop | Promotional crypto airdrops only | Not just crypto. Airdrop = eToro opens a position on behalf of the customer. Examples: crypto staking rewards, promotions, compensations. IsAirDrop=1 means position was created this way. | glossary | Guy | 2026-03-03 |
| Commission / CommissionOnClose | Spread commission | eToro's additional spread (markup) on top of market spread. Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid. | glossary | Guy | 2026-03-03 |
| FullCommission / FullCommissionOnClose | Total commission (spread + fees) | Full spread = market spread (variable spread, Ask-Bid) + eToro markup (Commission). Total spread cost to customer. | glossary | Guy | 2026-03-03 |
| OpenMarketSpread / CloseMarketSpread | Bid-ask spread | Market spread (aka variable spread) = Ask - Bid. Market-side spread before eToro markup. | glossary | Guy | 2026-03-03 |
| OpenMarkup / CloseMarkup | Actual markup charged | eToro's markup (additional spread) amount. Same concept as Commission in spread terms. | glossary | Guy | 2026-03-03 |
| IsCopyFundPosition | AccountTypeID=9 only | Also true when MirrorTypeID=4 in Dim_Mirror. | table | Guy | 2026-03-03 |
| OpenTotalFees / CloseTotalFees | Regulatory/exchange fees | Ticket fees — either fixed $ or % of volume. More fees may be added later; full breakdown in History.Cost. | glossary | Guy | 2026-03-03 |

---

## Tier 4 (UNVERIFIED) Columns

These columns received descriptions based only on column name inference. A domain expert should verify or correct.

| # | Column | Current Description | Question for Reviewer |
|---|--------|--------------------|-----------------------|
| 31 | PlatformTypeID | Platform type identifier. Not populated — always NULL. | Is this column deprecated? Should it be dropped? What platform types were it intended to reference? |
| 32 | PositionSegment | Position segment classification. Not populated — always NULL. | What segmentation was this intended for? Is it a candidate for removal? |
| 35 | OpenInd | Open indicator flag. Values: NULL, 0, or 1. Purpose unknown. | What does this flag indicate? Why is it mostly NULL? What triggers the 0 and 1 values? |

## Columns Needing Clarification

| Column | Tier | Question |
|--------|------|----------|
| OpenPositionReasonID | 5 | [RESOLVED] Expert confirmed: column IS OpenActionType. 2000-series values are ETL data quality issue. Upstream dictionary (0-18) is correct. |
| Close_PriceType | 2 | 2026 distribution: 2=63.5%, NULL=18%, 1=11.8%, 0=6.6%, 3=0.05%. Expert says: official close, unofficial close, dealer injection, or last internal price. Exact value-to-source mapping still TBD. |
| ExitOrderType | 2 | 2026 distribution: 20=56%, NULL=44%, 19=rare. What do values 19 and 20 represent? They don't match standard `Dictionary.OrderType` values. |
| CommissionVersion | 5 | [RESOLVED] Expert confirmed: commission calculation version with multiple models. Detailed value mapping TBD. |
| VolumeOnClose | 5 | [RESOLVED] Expert confirmed: same as Volume but at close time. rounded(Units * Price * ConversionRate). Pro-rated for partial close. |

## Structural Questions

| Topic | Question |
|-------|----------|
| Table size vs production | [RESOLVED] Expert approved: 133 is correct. DWH intentionally excludes some production columns and adds derived columns. |
| CloseDateID = 19000101 | Unanswered. Can analysts encounter the 19000101 sentinel, or is it always overwritten within the same ETL run? |
| OpenMarket_* columns | [RESOLVED] Expert dismissed: no backfill planned. Analysts should expect NULLs for pre-2023 positions. |
| SWITCH PARTITION | [RESOLVED] Expert dismissed: operational concern, not in scope for wiki documentation. |

---

*Generated: 2026-03-02 | Updated: 2026-03-13 | Companion to Dim_Position.md*
