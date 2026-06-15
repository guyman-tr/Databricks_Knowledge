# Semantic Concept Hierarchy + Ownership Ledger

Phase 2 deliverable. Organizes the 184 trigger-overlap concepts into
super-concept families and assigns each one a primary owner + a
disambiguation pattern. Phase 3 (codify-contract) embeds this into
cross-cutting/routing-disambiguation-contract.md. Phase 4 executes
the trigger edits implied by `drop_from`.

## Pattern legend

- **primary_only** - bare form belongs to one hub; secondaries drop the trigger entirely.
- **qualified_wins** - bare form goes to primary; secondaries keep ONLY qualified forms (e.g., `spaceship X`, `options X`).
- **context_dispatch** - bare form has multiple legitimate owners; contract codifies intent-based routing.

## Distribution

- Total ledger entries: **185**
- `context_dispatch`: 4
- `primary_only`: 173
- `qualified_wins`: 8

## Concept families

### `aum_aua` (10 concepts)

Assets-under-management and assets-under-administration.
domain-aum-and-aua is the dedicated hub. Niche-platform AUM views
stay with the niche hub.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `assets under management` | `domain-aum-and-aua` | primary_only | domain-trading |  |
| `aum` | `domain-aum-and-aua` | qualified_wins | domain-payments, domain-trading | Dedicated hub for AUM/AUA. Niche platforms keep qualified forms ('moneyfarm AUM', 'spaceship AUM'). |
| `equityglobal` | `domain-aum-and-aua` | primary_only | domain-trading | EquityGlobal = TP-side AUM column. |
| `ibanbalance` | `domain-aum-and-aua` | primary_only | domain-trading |  |
| `moneyfarm aum` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `optionstotalequity` | `domain-aum-and-aua` | primary_only | domain-trading |  |
| `totalequitytp` | `domain-aum-and-aua` | primary_only | domain-trading |  |
| `v_moneyfarm_aum` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `v_options_aum` | `domain-options` | primary_only | domain-payments, domain-revenue-and-fees |  |
| `v_spaceship_aum` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |

### `broker_provider_identity` (12 concepts)

US-broker (Apex/Gatsby/USABroker) and payment-processor identifier
strings. Multiple hubs reference these but the canonical
reconciliation story lives in domain-cross/provider-reconciliation.md.
Payment-processor MIDs are payment-flow-only.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `apex` | `domain-cross` | primary_only | domain-options, domain-payments, domain-revenue-and-fees | Apex = US broker. Canonical recon in domain-cross. Trading-via-Apex stays in domain-options via 'apex options' qualified form. |
| `apex buyingpower` | `domain-cross` | primary_only | domain-payments |  |
| `apex sod` | `domain-cross` | primary_only | domain-options, domain-payments | Apex Start-of-Day reconciliation. Lives in domain-cross/provider-reconciliation.md. |
| `gatsby` | `domain-cross` | primary_only | domain-options, domain-payments, domain-revenue-and-fees | Gatsby = same US broker (legacy name). Same as Apex. |
| `mid` | `domain-payments` | primary_only | domain-cross, domain-revenue-and-fees | Payment-processor Merchant Identifier. |
| `midname` | `domain-payments` | primary_only | domain-cross, domain-revenue-and-fees |  |
| `midvalue` | `domain-payments` | primary_only | domain-cross, domain-revenue-and-fees |  |
| `simplex` | `domain-payments` | primary_only | domain-exw-wallet | Simplex = card-purchase-of-crypto provider; payment-flow primary. |
| `sodreconciliation` | `domain-cross` | primary_only | domain-revenue-and-fees | SOD recon table family - cross-broker scope. |
| `tangany` | `domain-exw-wallet` | primary_only | domain-payments, domain-staking | Tangany = custodian for crypto wallet. |
| `treezor` | `domain-payments` | primary_only | domain-cross | Treezor = eMoney IBAN provider. |
| `usabroker` | `domain-cross` | primary_only | domain-options, domain-payments, domain-revenue-and-fees | USABroker = same US broker (alt name). |

### `compliance_aml` (4 concepts)

AML/KYC events, alerts, multi-account detection.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `alertid` | `domain-compliance-and-aml` | primary_only | domain-ops-and-onboarding |  |
| `appropriateness test` | `domain-customer-and-identity` | primary_only | domain-options | Appropriateness test = pre-trade KYC quiz; customer-and-identity primary. Options keeps 'options appropriateness' qualified. |
| `multipleaccounts` | `domain-compliance-and-aml` | primary_only | domain-ops-and-onboarding |  |
| `regulation` | `domain-compliance-and-aml` | primary_only | domain-customer-and-identity |  |

### `cross_cutting_utilities` (4 concepts)

Global filter macros and infrastructure flags. cross-cutting hub
is primary; all other claims drop.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `iscreditreportvalidcb` | `cross-cutting` | primary_only | domain-customer-and-identity, domain-options, domain-staking | IsCreditReportValidCB = global valid-customer-fingerprint filter; lives in cross-cutting. |
| `isvalidcustomer` | `cross-cutting` | primary_only | domain-customer-and-identity, domain-options | Global valid-customer macro. |
| `latency` | `cross-cutting` | primary_only | domain-trading | MCP latency signal lives in cross-cutting (mcp-latency-signal rule). |
| `reconciliation` | `domain-cross` | qualified_wins | domain-staking, domain-trading | Bare 'reconciliation' = broker/SOD recon (domain-cross). Trading drops bare, keeps 'trade reconciliation' qualified. Staking drops bare. |

### `customer_identity_columns` (14 concepts)

ID columns and dimension fields on Dim_Customer and friends.
customer-and-identity is the canonical lookup hub. Compliance and
ops drop bare column triggers but keep workflow-scoped forms.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `accounttypeid` | `domain-customer-and-identity` | primary_only | domain-staking |  |
| `citizenshipcountryid` | `domain-customer-and-identity` | primary_only | domain-compliance-and-aml |  |
| `compensationreasonid` | `domain-customer-and-identity` | primary_only | domain-revenue-and-fees |  |
| `countryid` | `domain-customer-and-identity` | primary_only | domain-staking |  |
| `externaluserid` | `domain-customer-and-identity` | primary_only | domain-moneyfarm |  |
| `moneyfarmuserid` | `domain-moneyfarm` | primary_only | domain-customer-and-identity | moneyfarmUserId is the MF-side identifier; MF hub owns. |
| `movemoneyreasonid` | `domain-customer-and-identity` | primary_only | domain-payments |  |
| `playerlevelid` | `domain-customer-and-identity` | primary_only | domain-compliance-and-aml, domain-staking |  |
| `playerstatus` | `domain-customer-and-identity` | primary_only | domain-compliance-and-aml, domain-ops-and-onboarding, domain-staking | PlayerStatus = lifecycle enum on Dim_Customer. Compliance has KYC-flow scope, ops has onboarding scope - both keep 'PlayerStatus KYC' / 'PlayerStatus onboarding' qualified. |
| `playerstatusid` | `domain-customer-and-identity` | primary_only | domain-staking |  |
| `regulationid` | `domain-customer-and-identity` | primary_only | domain-compliance-and-aml, domain-staking |  |
| `screeningstatus` | `domain-compliance-and-aml` | primary_only | domain-customer-and-identity, domain-ops-and-onboarding | ScreeningStatus = AML/KYC outcome - compliance is primary, NOT customer-and-identity. |
| `sessionid` | `domain-customer-and-identity` | primary_only | domain-ops-and-onboarding |  |
| `verificationlevelid` | `domain-compliance-and-aml` | primary_only | domain-customer-and-identity, domain-ops-and-onboarding | VerificationLevelID = KYC level - compliance primary. |

### `customer_lifecycle_populations` (9 concepts)

Funded / active / churned / FTD / first-trade populations. The
v_population_* family lives in customer-and-identity. Payments
and ops drop bare triggers for the populations.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `active traders` | `domain-customer-and-identity` | primary_only | domain-payments |  |
| `audit trail` | `domain-cross` | context_dispatch | - | Two legitimate angles: (a) tribe-emoney-audit (cross-domain audit trail) -> domain-cross; (b) Fact_CustomerAction history (per-customer activity audit) -> domain-customer-and-identity. CONTRACT: 'audit trail for [transaction\|emoney\|broker recon]' -> cross; 'audit trail for [customer\|accountid\|history]' -> customer-and-identity. |
| `customer_daily_status` | `domain-customer-and-identity` | primary_only | domain-payments |  |
| `customer_periodic_status` | `domain-customer-and-identity` | primary_only | domain-payments |  |
| `funded accounts` | `domain-customer-and-identity` | qualified_wins | domain-revenue-and-fees, domain-spaceship | PHASE 5 ADDITION: 'funded accounts' is currently NOT a trigger on customer-populations-and-lifecycle.md. Must be ADDED. Spaceship keeps 'spaceship funded accounts' qualified form. |
| `isdepositor` | `domain-customer-and-identity` | primary_only | domain-ops-and-onboarding |  |
| `onboarding funnel` | `domain-ops-and-onboarding` | primary_only | domain-customer-and-identity | Funnel = ops/onboarding KPI; customer-and-identity has populations but drops the funnel term. |
| `v_population_active_traders` | `domain-customer-and-identity` | primary_only | domain-payments |  |
| `v_population_first_time_funded` | `domain-customer-and-identity` | primary_only | domain-payments |  |

### `fees_revenue` (28 concepts)

Trading commissions, deposit/withdraw fees, conversion fees,
dividends, payment for order flow, share lending, dormant fees,
sdrt, etc. domain-revenue-and-fees is the canonical fee hub.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `bi_db_depositwithdrawfee` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `commission` | `domain-revenue-and-fees` | qualified_wins | domain-marketing-and-acquisition | Bare 'commission' = trading commission. Marketing must qualify ('affiliate commission', 'partner commission'). |
| `conversion fee` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `depositwithdrawfee` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `depositwithdrawfee_reversals` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `depot` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `interest on balance` | `domain-revenue-and-fees` | primary_only | domain-customer-and-identity |  |
| `iob` | `domain-revenue-and-fees` | primary_only | domain-customer-and-identity |  |
| `moneyfarm cohort` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `moneyfarm fees` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `moneyfarm mimo` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `options revenue` | `domain-options` | primary_only | domain-revenue-and-fees | Niche-platform-scoped revenue belongs to the niche hub. |
| `overnight fee` | `domain-revenue-and-fees` | primary_only | domain-customer-and-identity |  |
| `payment for order flow` | `domain-options` | primary_only | domain-revenue-and-fees |  |
| `pfof` | `domain-options` | primary_only | domain-revenue-and-fees |  |
| `pipscalculation` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `sdrt` | `domain-revenue-and-fees` | primary_only | domain-customer-and-identity |  |
| `share lending` | `domain-revenue-and-fees` | primary_only | domain-payments |  |
| `silver_moneyfarm_etoro_mf_aum` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `ticket fee` | `domain-revenue-and-fees` | primary_only | domain-customer-and-identity |  |
| `us options` | `domain-options` | primary_only | domain-revenue-and-fees |  |
| `v_mimo_options_platform` | `domain-options` | primary_only | domain-payments, domain-revenue-and-fees |  |
| `v_mimo_optionsplatform` | `domain-options` | primary_only | domain-revenue-and-fees |  |
| `v_moneyfarm_fees` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `v_moneyfarm_mimo` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `v_revenue_optionsplatform` | `domain-options` | primary_only | domain-revenue-and-fees |  |
| `v_spaceship_fees` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |
| `v_spaceship_mimo` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |

### `marketing` (2 concepts)

Marketing & acquisition concepts.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `airdrop` | `domain-marketing-and-acquisition` | primary_only | domain-staking, domain-trading | Airdrop = promo crypto distribution (marketing channel). Staking/trading drop bare. |
| `dma` | `domain-marketing-and-acquisition` | primary_only | domain-trading | DMA = direct mail attribution channel; marketing primary. |

### `money_flow_crypto` (14 concepts)

Crypto-to-fiat (C2F), crypto-to-platform (C2P), and on-chain
mechanics. domain-cross owns the end-to-end E2E stories;
domain-exw-wallet owns the on-chain mechanics.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `blockchaincryptoid` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `blockchaintransactionid` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `c2f` | `domain-cross` | primary_only | domain-exw-wallet, domain-payments, domain-revenue-and-fees | C2F end-to-end story lives in domain-cross/crypto-to-fiat.md. Secondaries keep qualified forms ('C2F revenue', 'C2F leg'). |
| `c2p` | `domain-payments` | primary_only | domain-exw-wallet, domain-trading | Crypto-to-Platform = trading deposit via crypto. Payments primary. |
| `crypto to fiat` | `domain-cross` | primary_only | domain-exw-wallet, domain-revenue-and-fees |  |
| `crypto-to-fiat` | `domain-cross` | primary_only | domain-exw-wallet, domain-payments |  |
| `exw_c2f_e2e` | `domain-cross` | primary_only | domain-exw-wallet, domain-payments | EXW_C2F_E2E table is the canonical C2F join; lives in domain-cross. |
| `exw_c2p_e2e` | `domain-payments` | primary_only | domain-exw-wallet |  |
| `gas fee` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `iscryptotofiat` | `domain-cross` | primary_only | domain-payments | IsCryptoToFiat flag on Fact_MIMO_AllPlatforms - C2F marker. |
| `off-ramp` | `domain-cross` | primary_only | domain-exw-wallet, domain-payments |  |
| `on-chain` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `public address` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `redemption` | `domain-exw-wallet` | primary_only | domain-payments |  |

### `money_flow_fiat` (15 concepts)

Fiat deposit/withdraw lifecycle, card refunds/chargebacks/reversals,
and FTD detection.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `bincountry` | `domain-payments` | primary_only | domain-revenue-and-fees |  |
| `card lifecycle` | `domain-cross` | primary_only | domain-payments |  |
| `cardtype` | `domain-payments` | primary_only | domain-revenue-and-fees |  |
| `chargeback` | `domain-cross` | primary_only | domain-payments, domain-revenue-and-fees | Refund-chargeback chain lives in domain-cross/refund-chargeback-chain.md. |
| `ftd` | `domain-customer-and-identity` | qualified_wins | domain-payments, domain-revenue-and-fees | FTD = first time deposit = customer lifecycle event. Payments has the deposit event; rev has the FTD-revenue marker. Both keep qualified forms ('FTD revenue', 'FTD deposit table'). Bare FTD goes to lifecycle owner. |
| `global ftd` | `domain-customer-and-identity` | primary_only | domain-payments | Phrase form of IsGlobalFTD. Added in Phase 5 to customer-populations-and-lifecycle.md; was previously only claimed by domain-payments/mimo-panel-and-ddr.md (removed in follow-up cleanup). |
| `isftd` | `domain-customer-and-identity` | primary_only | domain-options |  |
| `isglobalftd` | `domain-customer-and-identity` | primary_only | domain-cross, domain-options, domain-payments | IsGlobalFTD = lifecycle FTD across all platforms; lives in customer-populations-and-lifecycle.md. |
| `isrecurring` | `domain-cross` | primary_only | domain-payments | Recurring deposit flag - lives in recurring-deposit-to-trade story. |
| `moneyfarm ftd` | `domain-moneyfarm` | primary_only | domain-payments |  |
| `net deposits` | `domain-payments` | qualified_wins | domain-revenue-and-fees, domain-spaceship | Bare 'net deposits' = global NTD on the trading platform. Niche platforms must use qualified form ('spaceship net deposits'). revenue-and-fees has NTD as input to revenue calc - drops bare. |
| `options ftd` | `domain-options` | primary_only | domain-payments | Niche-platform-scoped FTD - belongs to the niche hub by definition. |
| `recurring investment` | `domain-cross` | primary_only | domain-trading |  |
| `refund` | `domain-cross` | primary_only | domain-payments, domain-revenue-and-fees |  |
| `reversal` | `domain-cross` | primary_only | domain-payments, domain-revenue-and-fees |  |

### `niche_platform_moneyfarm` (10 concepts)

MoneyFarm-only (UK robo-advisor). domain-moneyfarm is the niche hub.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `ben thompson` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `benth` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `bi_output_moneyfarm_customers` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `bi_output_moneyfarm_fact_portfolio_snapshot` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `bi_output_moneyfarm_fact_transactions` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `bronze_moneyfarm_users` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `isa` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `money farm` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `moneyfarm` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |
| `uk isa` | `domain-moneyfarm` | primary_only | domain-revenue-and-fees |  |

### `niche_platform_options` (2 concepts)

US Options-only. domain-options is the niche hub.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `options` | `domain-options` | primary_only | domain-revenue-and-fees |  |
| `options eligibility` | `domain-options` | primary_only | domain-revenue-and-fees |  |

### `niche_platform_spaceship` (10 concepts)

Spaceship-only terms (Australian investment platform).
domain-spaceship is the niche hub. revenue-and-fees sub-skill
(revenue-spaceship.md) drops the bare niche-platform terms but
stays discoverable via cross-hub link.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `australian investment` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |
| `bronze_spaceship_metabase` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |
| `f30dd` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |
| `fum` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |
| `is_ftd` | `domain-spaceship` | context_dispatch | - | Niche-platform flag column. Spaceship uses for SPS FTD detection; moneyfarm uses same column name on MF tables. CONTRACT: 'is_ftd spaceship/SPS' -> spaceship; 'is_ftd moneyfarm/MF' -> moneyfarm; bare 'is_ftd' is too generic - re-rank by platform mention or required_tables. |
| `is_funded` | `domain-spaceship` | context_dispatch | - | Same shape as is_ftd; routing depends on platform mention. |
| `is_internal_transfer` | `domain-options` | context_dispatch | - | Options + spaceship both have this flag. Context: 'is_internal_transfer options' -> options; bare or 'is_internal_transfer spaceship' -> spaceship via 'spaceship' qualifier. |
| `isinternaltransfer` | `domain-options` | primary_only | domain-payments | CamelCase form of is_internal_transfer; options + payments both claim. Payments drops bare - keeps qualified ('IsInternalTransfer payment'). |
| `spaceship` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |
| `weekend fill-forward` | `domain-spaceship` | primary_only | domain-revenue-and-fees |  |

### `niche_platform_staking` (4 concepts)

Staking platform (crypto staking rewards).

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `revshare` | `domain-staking` | primary_only | domain-revenue-and-fees |  |
| `rewards distribution` | `domain-staking` | primary_only | domain-revenue-and-fees |  |
| `staking` | `domain-staking` | primary_only | domain-revenue-and-fees |  |
| `staking rewards` | `domain-staking` | primary_only | domain-revenue-and-fees |  |

### `trading_concepts` (29 concepts)

Trade-action enum columns and trading-fact tables. Trading is
primary; customer-and-identity holds the lookup mappings as a
utility but should not claim the bare column triggers.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `actiontypeid` | `domain-trading` | primary_only | domain-customer-and-identity, domain-revenue-and-fees | ActionTypeID is the trade-action enum on Fact_CustomerAction. Customer-and-identity has the lookup table but routing goes to trading. |
| `apexrecon_holdings` | `domain-trading` | primary_only | domain-revenue-and-fees |  |
| `apexrecon_tradeactivity` | `domain-trading` | primary_only | domain-revenue-and-fees |  |
| `bi_db_first5actions` | `domain-customer-and-identity` | primary_only | domain-cross | First-5-actions = early lifecycle table; customer-and-identity owns. |
| `copypositionopen` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `crypto` | `domain-trading` | qualified_wins | domain-payments | Bare 'crypto' = instrument category. Payments uses qualified forms ('crypto deposit', 'crypto wallet'). |
| `dim_position` | `domain-trading` | primary_only | domain-staking |  |
| `eth` | `domain-trading` | qualified_wins | domain-staking | ETH as instrument. Staking keeps 'ETH staking' qualified form. |
| `fact_currencypricewithsplit` | `domain-trading` | primary_only | domain-moneyfarm, domain-spaceship | Fact_CurrencyPriceWithSplit is the global FX-price table; trading owns. Niche platforms reference it as input but drop as trigger. |
| `fact_customeraction` | `domain-trading` | primary_only | domain-customer-and-identity | Fact_CustomerAction is the trade fact. Customer-and-identity uses it for lifecycle - drops as trigger. |
| `fact_customeraction_w_metrics` | `domain-trading` | primary_only | domain-cross, domain-revenue-and-fees |  |
| `fact_trading_volumes_and_amounts` | `domain-trading` | primary_only | domain-payments |  |
| `instrumentid` | `domain-trading` | primary_only | domain-staking |  |
| `isactivetrade` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `isbuy` | `domain-trading` | primary_only | domain-revenue-and-fees |  |
| `isfeedividend` | `domain-revenue-and-fees` | primary_only | domain-customer-and-identity |  |
| `isleveraged` | `domain-trading` | primary_only | domain-revenue-and-fees |  |
| `ispartialclosechild` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `ispartialcloseparent` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `issettled` | `domain-trading` | primary_only | domain-customer-and-identity, domain-revenue-and-fees |  |
| `issqf` | `domain-trading` | primary_only | domain-revenue-and-fees |  |
| `manualpositionopen` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `mirrorid` | `domain-trading` | primary_only | domain-revenue-and-fees | MirrorID = copy-trading mirror identifier. |
| `popular investor` | `domain-trading` | primary_only | domain-customer-and-identity | Popular Investor program lives in trading. Customer-and-identity has profile fields - drops as trigger. |
| `settlementtypeid` | `domain-trading` | primary_only | domain-revenue-and-fees |  |
| `smart portfolio` | `domain-trading` | primary_only | domain-staking | CopyPortfolio product (called Smart Portfolio in UI). Trading-side product. |
| `volumeonclose` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `volumeonopen` | `domain-trading` | primary_only | domain-customer-and-identity |  |
| `w_metrics` | `domain-trading` | primary_only | domain-cross |  |

### `wallet_infrastructure` (18 concepts)

EXW wallet objects, balances, addresses, validations.
domain-exw-wallet is the primary owner. Payments holds bridge
knowledge but the wallet objects themselves belong to EXW.

| Concept | Primary owner | Pattern | Drop from | Notes |
|---|---|---|---|---|
| `aml wallet` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `amlvalidations` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `bronze_walletdb_wallet` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `correlationid` | `domain-exw-wallet` | primary_only | domain-payments | CorrelationId is the EXW chain-stitch column; only meaningful in wallet context. |
| `crypto wallet` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `customerwalletsview` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `etoro wallet` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `exw` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `exw_dimuser` | `domain-exw-wallet` | primary_only | domain-customer-and-identity, domain-payments | EXW_DimUser = wallet user dimension; lives in domain-exw-wallet. |
| `exw_dimuser_enriched` | `domain-exw-wallet` | primary_only | domain-customer-and-identity |  |
| `exw_ethfeesent_blockchain` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `exw_facttransactions` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `exw_financereportsbalancesnew` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `exw_walletinventory` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `sendrequestcorrelationid` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `walletbalances` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `walletid` | `domain-exw-wallet` | primary_only | domain-payments |  |
| `walletpool` | `domain-exw-wallet` | primary_only | domain-payments |  |

