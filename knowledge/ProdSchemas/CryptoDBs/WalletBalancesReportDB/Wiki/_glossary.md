# Business Glossary - WalletBalancesReportDB

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-16 | Terms: 1 lookup-backed, 0 concept-based | Sources: 1 Dictionary tables, 0 object docs*

---

## Lookup-Backed Terms

### Finance Report Level {#finance-report-level}

**Definition**: Classification outcome of the crypto wallet balance reconciliation process. Each reconciliation run compares balances reported by three systems - eToro (internal ledger), BitGo (custody provider), and Blox (portfolio tracking) - and assigns a level describing whether the numbers agree, which system disagrees, or whether an API error prevented comparison.

**Source Table**: `Dictionary.FinanceReportLevel`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | EventualyConsolidated | Initial discrepancy was detected but resolved on its own - balances eventually matched across all sources |
| 2 | AllDiff | All three sources (BitGo, Blox, eToro) report different balances - full three-way mismatch requiring investigation |
| 3 | EtoroDiffBoth | BitGo and Blox agree with each other but eToro's internal ledger differs - suggests an eToro booking or sync issue |
| 4 | MultipleAddresses | The account holds crypto across multiple blockchain addresses, complicating balance aggregation |
| 5 | BitgoError | BitGo API returned an error, so custody-side balance could not be retrieved for comparison |
| 6 | BloxError | Blox API returned an error, so portfolio-tracker balance could not be retrieved for comparison |
| 7 | InvalidBloxAccount | The Blox account identifier is invalid or not found - likely a configuration or mapping issue |
| 8 | BloxErrorAndBitgoDiffEtoro | Blox API failed AND BitGo balance differs from eToro - partial comparison with confirmed discrepancy |
| 9 | BitgoErrorAndBloxDiffEtoro | BitGo API failed AND Blox balance differs from eToro - partial comparison with confirmed discrepancy |
| 10 | BitgoErrorAndBloxMatchEtoro | BitGo API failed but Blox and eToro balances match - likely no real discrepancy despite missing custodian data |
| 11 | BloxErrorAndBitgoMatchEtoro | Blox API failed but BitGo and eToro balances match - likely no real discrepancy despite missing tracker data |
| 12 | InternalError | Reconciliation engine encountered an unclassifiable error - the classification logic itself failed |
| 100 | InitialDiscrepancy | Catch-all for new/unhandled discrepancies detected on the first reconciliation pass before specific classification |

**Key Characteristics**:
- Values 1-4 represent classifiable reconciliation outcomes (data was available from all sources)
- Values 5-11 represent degraded comparisons where one or more API calls failed
- Value 12 is a system-level fallback indicating a bug or unmapped scenario
- Value 100 (gap from 12) serves as a default/initial classification before deeper analysis

**Used By**: Wallet.FinanceReportRecords (LevelId FK), Wallet.FinanceReportsBalances_old (LevelId FK), History.FinanceReportsBalances (LevelId implicit FK)

---

## Business Concepts

*(No concept entries yet - will be populated as objects are documented)*
