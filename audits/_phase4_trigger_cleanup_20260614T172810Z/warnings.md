# Phase 4 warnings - DRY-RUN

## Files emptied (1)

Files where the triggers list dropped to size 0 after removals.
These hubs will be unroutable until someone adds replacement triggers.

- `knowledge/skills/domain-revenue-and-fees/revenue-moneyfarm.md`

## Unmatched drop_from entries (45)

Ledger entries where drop_from listed a hub but no file in that hub
had the concept as a literal trigger. Most likely cause: the concept
appeared in required_tables or sample_questions in that hub (NOT in
triggers), and the inventory flagged it because we scanned all three
fields. No edit needed.

| Hub | Concept |
|---|---|
| `domain-revenue-and-fees` | `actiontypeid` |
| `domain-revenue-and-fees` | `apex` |
| `domain-revenue-and-fees` | `apexrecon_holdings` |
| `domain-revenue-and-fees` | `apexrecon_tradeactivity` |
| `domain-revenue-and-fees` | `australian investment` |
| `domain-revenue-and-fees` | `bincountry` |
| `domain-revenue-and-fees` | `bronze_spaceship_metabase` |
| `domain-revenue-and-fees` | `cardtype` |
| `domain-revenue-and-fees` | `chargeback` |
| `domain-revenue-and-fees` | `compensationreasonid` |
| `domain-revenue-and-fees` | `f30dd` |
| `domain-revenue-and-fees` | `ftd` |
| `domain-revenue-and-fees` | `fum` |
| `domain-revenue-and-fees` | `funded accounts` |
| `domain-revenue-and-fees` | `isbuy` |
| `domain-revenue-and-fees` | `isleveraged` |
| `domain-revenue-and-fees` | `issettled` |
| `domain-revenue-and-fees` | `issqf` |
| `domain-revenue-and-fees` | `mid` |
| `domain-revenue-and-fees` | `midname` |
| `domain-revenue-and-fees` | `midvalue` |
| `domain-revenue-and-fees` | `mirrorid` |
| `domain-revenue-and-fees` | `net deposits` |
| `domain-revenue-and-fees` | `options` |
| `domain-revenue-and-fees` | `options eligibility` |
| `domain-revenue-and-fees` | `payment for order flow` |
| `domain-revenue-and-fees` | `refund` |
| `domain-revenue-and-fees` | `reversal` |
| `domain-revenue-and-fees` | `revshare` |
| `domain-revenue-and-fees` | `rewards distribution` |
| `domain-revenue-and-fees` | `settlementtypeid` |
| `domain-revenue-and-fees` | `sodreconciliation` |
| `domain-revenue-and-fees` | `spaceship` |
| `domain-revenue-and-fees` | `staking` |
| `domain-revenue-and-fees` | `staking rewards` |
| `domain-revenue-and-fees` | `us options` |
| `domain-revenue-and-fees` | `usabroker` |
| `domain-revenue-and-fees` | `v_mimo_options_platform` |
| `domain-revenue-and-fees` | `v_mimo_optionsplatform` |
| `domain-revenue-and-fees` | `v_options_aum` |
| `domain-revenue-and-fees` | `v_revenue_optionsplatform` |
| `domain-revenue-and-fees` | `v_spaceship_aum` |
| `domain-revenue-and-fees` | `v_spaceship_fees` |
| `domain-revenue-and-fees` | `v_spaceship_mimo` |
| `domain-revenue-and-fees` | `weekend fill-forward` |
