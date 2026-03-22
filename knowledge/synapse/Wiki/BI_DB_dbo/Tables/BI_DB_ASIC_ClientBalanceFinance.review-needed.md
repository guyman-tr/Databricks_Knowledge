# Review Sidecar — BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 19 columns in DDL, 19 in wiki |
| All columns have tier suffix | ✅ | All 19 descriptions end with (Tier N — source) |
| Writer SP confirmed | ✅ | SP_ASIC_ClientBalanceFinance matches OpsDB |
| Sample data reviewed | ✅ | 5 rows sampled, values consistent with column descriptions |
| Distribution query | ✅ | RegulationName: 2 values (ASIC: 98.6M, ASIC & GAML: 446.8M) |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Deposit (col 6) | Medium | The "Deposit" column includes ChargebackLoss and OtherNegative adjustments, making it NOT a pure deposit figure. Verify this is the intended business definition for ASIC regulatory reporting. |
| 2 | PreviuosDayBalance (col 5) | High | Column name has a typo ("Previuos" vs "Previous"). Confirmed this is the production name — do not rename. |
| 3 | IsGermanBaFin (col 19) | Medium | Added by Guy M with comment "i dont understand what for it's an ASIC report.whatever." — confirm if still in use and purpose. |
| 4 | RealAssetEquity (col 13) | Medium | Formula changed multiple times in Aug 2019 (NOP_Crypto → V_Liabilities). Verify current formula is correct. |
| 5 | V_Liabilities | Low | No upstream wiki exists for V_Liabilities. Balance/equity columns traced to V_Liabilities could benefit from upstream documentation. |
| 6 | Row count | Low | Distribution query shows ~545M total rows. Partition stats showed 915K — the discrepancy is because ROUND_ROBIN spreads across 60 distributions. The ~545M figure from the GROUP BY is authoritative. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 16 | DateID, CID, Date, Customer, PreviuosDayBalance, Deposit, Withdrawal, ClosedPnL, CurrentDayBalance, OpenPosition, Equity, TotalOpenMargin, RealAssetEquity, CurrentLabel, PrevLabel, Country, RegulationName, IsGermanBaFin |
| Tier 3 | 1 | UpdateDate |

No Tier 1 columns — this table has multiple DWH sources with transformations, no single upstream wiki provides verbatim descriptions.
