# BI_DB_dbo.BI_DB_VerificationStatus30Days — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Questions for Reviewer

1. **OR precedence in population filter**: The SP has `WHERE (cc.FirstDepositDate >= @ftd_sd) OR (cc.RegisteredReal > GETDATE()-15 AND cc.FirstDepositDate IS NULL) and cc.PlayerLevelID <> 4 AND cc.CountryID <> 250 AND cc.LabelID <> 30`. Without explicit parentheses, the AND conditions may only apply to the second OR branch. Is this the intended behavior?
2. **CountryID=250 exclusion**: Which country is ID 250? Should be documented for audit purposes.
3. **LabelID=30 exclusion**: What label is ID 30? Not documented in SP comments.
4. **EvMatchStatus read from production**: The SP reads EvMatchStatus from External_etoro_BackOffice_Customer (production) rather than Dim_Customer. This gives fresher data but may diverge from DWH values.
5. **Priority algorithm day count**: The algorithm uses `15 - DATEDIFF(dd, FirstDepositDate, GETDATE())` which is days remaining until FTD+15, not FTD+14. The column FTD_Plus_14 is at 14 days, but priority uses 15 days. Is this intentional?

## Corrections Log

- Column count matches DDL: 25 columns documented.

## Cross-Object Consistency

- **RealCID** description inherited verbatim from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic)
- **Country** description inherited verbatim from Dim_Country.Name wiki (Tier 1 — Dictionary.Country)
- **PendingClosureStatusID** inherited from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic)
- **CurrentPlayerStatus** inherited from Dim_Customer.PlayerStatusID wiki (Tier 1 — Customer.CustomerStatic)
- **PlayerStatusReasonID** inherited from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic)
- **RegulationID** inherited from Dim_Customer wiki (Tier 1 — BackOffice.Customer)
- **EvMatchStatus** inherited verbatim from Dim_Customer wiki (Tier 1 — BackOffice.Customer)
