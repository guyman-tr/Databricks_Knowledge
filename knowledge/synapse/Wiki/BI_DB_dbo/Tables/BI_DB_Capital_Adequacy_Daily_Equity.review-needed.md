# Review Needed: BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_Equity

**Generated:** 2026-04-21 | **Batch:** 19 | **Reviewer:** —

## Tier 2 Items (Reviewer Verification Needed)

- [ ] **RegulationID mapping**: SP filters `RegulationID IN (1,2,4,5,10)`. Confirm the mapping: 1=CySEC, 2=BVI, 4=FCA, 5=ASIC, 10=ASIC+GAML? Verify against Dim_Regulation or a compliance reference document.
- [ ] **K-CMH definition**: Confirm "Capital Requirement for Client Money Holdings" is the correct full name and regulatory context for this metric. Which specific regulation/article mandates it (IFR, CRD, MiFID II)? The table name suffix "Daily_Equity" suggests equity-based K-CMH — confirm this interpretation.
- [ ] **V_Liabilities definition**: What does V_Liabilities aggregate? Is it raw cash balance, net of open position margin, or something else? The SP uses it as the cash equity component of K-CMH — confirm this is the correct regulatory interpretation.
- [ ] **IsCreditReportValidCB=1 filter**: Why are customers with invalid credit reports excluded from the K-CMH calculation? Confirm with Risk/Compliance whether this is a regulatory requirement or a data quality filter.
- [ ] **VerLevelID≥2 threshold**: The SP restricts cash balances to VerLevelID≥2 (verified customers). Does this mean unverified customers' cash balances are excluded from the K-CMH? Confirm whether this is intentional regulatory scoping.

## Potential Data Quality Issues

- **IsFuture = NULL dominance (~70%)**: Most rows have no CFD equity component. This reflects the FULL OUTER JOIN design — cash-only customer segments carry NULL IsFuture. Downstream consumers must handle NULL explicitly and should not treat NULL as "not a future instrument."
- **Historical backfill**: Rows with Date < 2022-02-23 carry UpdateDate = '2022-02-23' (backfill timestamp). Cannot distinguish backfilled from live rows by UpdateDate alone for the period starting 2022-02-23.
- **Regulation is current-time snapshot**: Regulation and Player_Status reflect the ETL run date, not any historical assignment. Time-series capital analysis by Regulation may be misleading for customers who changed regulatory jurisdiction mid-period.
- **Unrealized_Equity can be negative**: No floor/cap is applied in the SP. Negative equity rows are expected (net short CFD positions or negative cash). Downstream regulatory reports should confirm expected handling.

## Open Questions

1. What downstream regulatory reports consume this table directly? (Not confirmed via Atlassian MCP)
2. Is Unrealized_Equity used raw in capital adequacy reports, or is it capped/floored at the reporting layer?
3. How does this table relate to external regulatory submissions — is it read directly, or is there an intermediate aggregation step?
4. Are all five regulations (RegulationID 1,2,4,5,10) subject to the same K-CMH rules, or does each have different capital treatment?

## Corrections Log

*No corrections applied.*
