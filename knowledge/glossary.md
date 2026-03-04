# Domain Glossary

**Version**: 1.0.0 | **Purpose**: Shared domain terminology for all pipeline runs.
**Authority**: Tier 5 (domain-expert confirmed). Entries here override any pipeline-inferred expansions.

> The pipeline MUST read this file before generating any wiki documentation (Phase 11).
> Acronyms and terms listed here are the authoritative expansions — the pipeline must NOT
> infer alternative meanings from column names, code comments, or general knowledge.

---

## Acronyms & Terms

| Term | Expansion | Context | Added By | Date |
|------|-----------|---------|----------|------|
| CBH | Compute Before Hedge | Standard hedging model: the client trade is computed/placed first, then the hedge is executed afterward. Stored in InitHedgeType/EndHedgeType columns. NOT "Client-Based Hedging". | Guy | 2026-03-03 |
| HBC | Hedge Before Compute | Reverse hedging model: the hedge is placed before the client order is computed/executed. Stored in InitHedgeType/EndHedgeType columns. | Guy | 2026-03-03 |
| DLT (in position context) | German crypto broker | DLT refers to a specific German crypto broker used for trade execution — NOT generic Distributed Ledger Technology. DLTOpen/DLTClose indicate positions opened/closed on their platform. | Guy | 2026-03-03 |
| Airdrop | eToro opens position on behalf of customer | Not limited to crypto. Includes: crypto staking rewards, promotions, compensations. IsAirDrop=1 means eToro created the position for the customer. | Guy | 2026-03-03 |
| Commission (in trading context) | eToro's markup / additional spread | eToro's additional spread on top of the market spread (Ask-Bid). Synonym: markup. Manifests as AskSpreaded/BidSpreaded minus Ask/Bid. NOT a flat fee. | Guy | 2026-03-03 |
| FullCommission | Full spread = market spread + eToro markup | Total spread cost = market spread (variable spread) + Commission (eToro markup). | Guy | 2026-03-03 |
| Market Spread / Variable Spread | Ask - Bid (market-side spread) | The bid-ask spread from the market/LP before eToro's markup is added. Sometimes called "variable spread." Stored in OpenMarketSpread / CloseMarketSpread columns. | Guy | 2026-03-03 |
| Markup | Synonym for Commission | eToro's additional spread on top of market spread. Stored in OpenMarkup / CloseMarkup and Commission / CommissionOnClose columns. | Guy | 2026-03-03 |
| Ticket Fees / TotalFees | Fixed or % fees at open/close | Either a fixed dollar amount or a percentage of position volume. At-time-of-event snapshot; additional fees may be added later. Full breakdown in History.Cost table. | Guy | 2026-03-03 |

---

## Value Maps

> Domain-expert confirmed value mappings that override or supplement pipeline-discovered mappings.
> Format: `Table.Column` → value → meaning.

| Table.Column | Value | Meaning | Added By | Date |
|-------------|-------|---------|----------|------|
| *.SettlementTypeID | 0 | CFD — no asset ownership, contract-for-difference | Guy | 2026-03-03 |
| *.SettlementTypeID | 1 | REAL — customer owns actual shares | Guy | 2026-03-03 |
| *.SettlementTypeID | 2 | TRS — Total Return Swap (crypto) | Guy | 2026-03-03 |
| *.SettlementTypeID | 3 | CMT — Crypto settled (isSettled=true + crypto instrument) | Guy | 2026-03-03 |
| *.SettlementTypeID | 4 | REAL_FUTURES — real futures contract | Guy | 2026-03-03 |
| *.SettlementTypeID | 5 | MARGIN_TRADE — settled margin position (isSettled=true + leverage > 1) | Guy | 2026-03-03 |

---

*Consumed by: Phase 11 (Generate Documentation), Phase 4 (Lookup Resolution)*
*Location: knowledge/glossary.md*
