# Review Notes: BI_DB_dbo.BI_DB_Subsidieries_Realized_Commissions_Adjustments

**Generated**: 2026-04-22 | **Batch**: 34 | **Quality**: 9.5/10

## Tier 4 / Uncertain Items

None — all 16 columns traced to SP code or upstream production wikis (Dim_Position.md, Dim_Regulation.md, Dim_Instrument.md).

## Questions for SME Review

1. **DELETE key mismatch**: The SP deletes `WHERE EOMonth = @Date` but inserts `EOMONTH(@Date)` as the EOMonth value. These are equal only when @Date is the last day of the month. If the SP is ever run mid-month (e.g., for debugging or re-processing), rows accumulate rather than replace. Is there a safeguard in the orchestration ensuring @Date is always month-end? Or has this scenario been observed?

2. **Downstream consumers**: No SP or table references to `BI_DB_Subsidieries_Realized_Commissions_Adjustments` were found in the SSDT scan. Is this consumed by BI tools, Excel reports, or a finance reconciliation process outside of Synapse? Documenting the consumer would complete the lineage.

3. **"Subsidieries" typo in table/SP name**: The table name contains a misspelling ("Subsidieries" vs "Subsidiaries"). Is this intentional for backwards-compatibility, or is there a planned rename? This affects any downstream references.

4. **IsSettled definition**: Dim_Position.md marks `IsSettled` as Tier 5 (Expert Review) with description "1 = real asset, 0 = CFD asset." Can this be confirmed for the context of this table? CFD vs. real-asset classification may have specific accounting/reporting implications for the subsidiary commission adjustment.

5. **CreditInvalidClose/CreditInvalidOpen rows**: The SP requires at least one of the two snapshots to have `IsCreditReportValidCB = 1`. This means rows with CreditValidClose='CreditInvalidClose' AND CreditValidOpen='CreditValidOpen' (or vice versa) ARE included. Are commission amounts for CreditInvalid positions excluded from downstream calculations, or are they used for audit purposes?

## Corrections Applied

- Removed "6 distinct values observed" from InstrumentType description (snapshot stat rule).

## Ghost Columns

None identified. All 16 DDL columns are present in the SP INSERT list.
