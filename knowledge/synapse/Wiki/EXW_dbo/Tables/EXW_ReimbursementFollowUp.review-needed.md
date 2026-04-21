# EXW_dbo.EXW_ReimbursementFollowUp — Review Needed

**Generated**: 2026-04-20 | **Quality**: 8.5/10 | **Phase 16 evaluator**: Pending

## Tier 4 Items (Low-Confidence — Reviewer Verification Needed)

None — 3 columns are Tier 1 (CurrentCountryID, CurrentRegulationID, VerificationLevelID via EXW_DimUser upstream wiki) and 53 are Tier 2 with clear SP traceability.

## Open Questions for Reviewer

1. **Extraction cutoff date 2024-01-18 is hardcoded**: TotalExtractedUnitsPerCrypto, TotalExtractedUSDPerCrypto, and LastExtractionDatePerCrypto only reflect extractions since 2024-01-18 (TransactionTypeID=13, TranStatusID=2). Confirm whether this date was chosen to correspond to the start of a specific compensation program, and whether it should be updated as new programs are initiated. Any extraction before this date is silently excluded.

2. **WalletVsPlatform 'ToCheck' catch-all**: The 'ToCheck' case in the WalletVsPlatform CASE expression is the default — it fires when no other condition matches. Confirm what actions (if any) the compliance team takes for 'ToCheck' rows, and whether the current classification covers all expected reconciliation states. The CASE uses a difference threshold of $1 (`ABS(...) < 1`) which may miss cent-level discrepancies.

3. **Platform compensation filter (CompensationReasonID IN (101, 102))**: PlatformUSDCompensationPerGCID aggregates Fact_CustomerAction where ActionTypeID=36 AND CompensationReasonID IN (101, 102). Confirm that these are the correct and complete compensation reason IDs for all reimbursement programs tracked in this table — specifically whether AML_EEA (added 2025-07-27) uses the same reason IDs, or whether new IDs were introduced.

4. **Duplicate rows (Rn > 1) still appear as WalletVsPlatform='Dups'**: The SP uses ROW_NUMBER on EXW_CompensationClosingCountries to de-prioritize duplicates (Rn>1 rows are excluded from balance joins) but they still flow into EXW_ReimbursementFollowUp with WalletVsPlatform='Dups'. Confirm whether 'Dups' rows should be excluded from reporting, or whether they are intentionally retained for audit purposes.

5. **SP also writes EXW_ReimbursementSumTable**: The same SP run that builds this table also TRUNCATE+INSERT into EXW_ReimbursementSumTable (7 population segments). Confirm whether EXW_ReimbursementSumTable is documented and whether the two tables should always be queried together for a complete picture of the reimbursement program status.

6. **[Date Rate For  Reimbursement] — double space**: The DDL column name has two spaces between "For" and "Reimbursement". Confirm this is intentional (not a typo) and that all consuming queries (reports, BI tools) correctly reference the double-space form.

7. **Legacy country-closure rows and EXW_WalletEntity**: WalletEntity and LastWalletEntity are joined from EXW_WalletEntity by CompensationDate and MAX(Date) respectively. For legacy country-closure rows, the CompensationDate may predate the EXW_WalletEntity data. Confirm whether NULL WalletEntity/LastWalletEntity is expected for legacy project rows.

## Carry-Forward Notes

- 13 of 56 columns have spaces in their names — bracket-quoting is mandatory for all.
- `[Date Rate For  Reimbursement]` has a double space — must be preserved verbatim.
- Extraction cutoff 2024-01-18 is hardcoded in the SP.
- PlatformUSDCompensationPerGCID and WalletDataUSDReimbursementPerGCID are GCID-level totals (same value repeated on every GCID×CryptoId row for a given GCID).
- AMLStatus filter already applied at EXW_CompensationClosingCountries stage — no pending/in-progress AML rows in this table.
