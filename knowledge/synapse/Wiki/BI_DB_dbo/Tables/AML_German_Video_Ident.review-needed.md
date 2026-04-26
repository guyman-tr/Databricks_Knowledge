# AML_German_Video_Ident — Review Notes

**Generated**: 2026-04-23
**Reviewer**: —

## Items Needing Human Verification

1. **EquityRealCrypto always NULL**: The SP computes crypto equity in temp table #crypto but does NOT include EquityRealCrypto in the final INSERT. This was confirmed by reading the SP code — the column exists in the DDL but is never populated. Confirm this is intentional (abandoned feature) or whether the SP should be updated to include it.

2. **PlayerStatusID NOT IN (2, 4)**: The SP excludes two status IDs. Verify: what are status IDs 2 and 4 in Dictionary.PlayerStatus? (Sample data shows 'Normal' and 'Trade & MIMO Blocked' passing through — so 2 and 4 are different statuses, likely 'Demo' or 'Closed').

3. **RiskClassification join rate**: LEFT JOIN ON CID — verify what fraction of the 198,613 customers have a RiskClassification entry. If many have NULL RiskScoreName, this may indicate gaps in the RiskClassification data lake coverage.

4. **General schema sources**: The SP reads from `general.SolarisBankIdentDb_SolarisBankIdent` and `general.VideoIdentDb_VideoIdent`. These are cross-database references — confirm these external DB connections are stable and their schema is documented.

5. **Is_Pass_BankIdent rate**: Sample showed predominantly 0 for Is_Pass_BankIdent. Confirm this reflects the actual completion rate for Bank Ident among German customers, not a pipeline issue.

6. **@Date parameter**: SP accepts @Date parameter. Confirm OpsDB passes the correct date — is it run date (today) or previous day?

7. **BaFin regulation context**: Confirm the legal basis for Video Ident and Bank Ident requirements in the German customer AML context. The table name implies these are BaFin-mandated identity verification methods for German customers with crypto exposure.

8. **198,613 row count**: Confirm this is typical daily volume. Population depends on VerificationLevelID=3 filter — any KYC backlog changes could significantly affect volume.

## Quality Score

8.8/10 — 23-column AML compliance table. 14 columns Tier 1 from DWH_dbo.Dim_Customer wiki. 8 columns Tier 2 from SP logic clearly documented. Business meaning strong (German crypto AML, BaFin Video Ident monitoring). Data evidence good (198,613 rows, sample distribution confirmed). Notable discovery: EquityRealCrypto is always NULL (dead column). Minor deductions: complex multi-source lineage with some uncertainty on general-schema tables; no Confluence documentation found.
