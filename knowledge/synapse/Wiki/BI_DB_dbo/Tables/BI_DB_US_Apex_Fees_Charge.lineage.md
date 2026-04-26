# Lineage: BI_DB_dbo.BI_DB_US_Apex_Fees_Charge

**Generated**: 2026-04-22 | **Writer SP**: SP_US_Apex_Fees_Charge | **Frequency**: Daily

## ETL Source Chain

```
Apex SOD869 file (BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity)
  + DWH_dbo.Sodreconciliation_apex_SodFiles  (latest valid SOD869 file for @Date, Status=2, ApexFormat=869)
  |
  |-- Branch A: MSB (AccountNumber='3ET05007', TerminalID NOT IN OMJNL, FWWRD)
  |-- Branch B: Customers (AccountType IN ('1','2'), Amount>0, AccountNumber NOT IN MSB/reserve accounts,
  |                         TerminalID NOT IN dividend/CA list: OMJNL,DVRED,$+DIV,RERTS,OTMMR,OTINT,
  |                                          MGJNL,RGMER,SPDIV,DGDIV,RGRED,DVDIV,DVREI,DJDIV,XCINT)
  |-- UNION of Branch A and Branch B
    |-- SP_US_Apex_Fees_Charge @Date (Daily, step 04) ---|
    |   DELETE WHERE ProcessDate=@Date + INSERT
    v
BI_DB_dbo.BI_DB_US_Apex_Fees_Charge
  (209,246 rows, Oct 2021 – Apr 2026, ROUND_ROBIN, CLUSTERED(ProcessDate))
  (UC: Not Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | AccountNumber | External_Sodreconciliation_apex_EXT869_CashActivity | AccountNumber | Passthrough — Apex account identifier | Tier 2 |
| 2 | AccountType | External_Sodreconciliation_apex_EXT869_CashActivity | AccountType | Passthrough — Apex account type code ('1' or '2') | Tier 2 |
| 3 | Amount | External_Sodreconciliation_apex_EXT869_CashActivity | Amount | Passthrough — NOT sign-flipped (unlike CA_Apex.Amount); Customer branch: Amount>0 filter applied upstream | Tier 2 |
| 4 | Description | External_Sodreconciliation_apex_EXT869_CashActivity | Description | Passthrough — Apex human-readable transaction description | Tier 2 |
| 5 | CurrencyCode | External_Sodreconciliation_apex_EXT869_CashActivity | CurrencyCode | Passthrough — always 'USD' in practice (100% of rows) | Tier 2 |
| 6 | ProcessDate | External_Sodreconciliation_apex_EXT869_CashActivity | ProcessDate | Passthrough — equals @Date parameter; clustered index column | Tier 2 |
| 7 | BatchCode | External_Sodreconciliation_apex_EXT869_CashActivity | BatchCode | Passthrough — Apex batch processing reference ID | Tier 2 |
| 8 | Cusip | External_Sodreconciliation_apex_EXT869_CashActivity | Cusip | Passthrough — NULL for ~30% of rows (non-security transactions) | Tier 2 |
| 9 | SourceProgram | External_Sodreconciliation_apex_EXT869_CashActivity | SourceProgram | Passthrough — Apex system program that generated the record | Tier 2 |
| 10 | EnteredBy | External_Sodreconciliation_apex_EXT869_CashActivity | EnteredBy | Passthrough — Apex user/process that entered the record; 41 NULLs | Tier 2 |
| 11 | EntryTypeCode | External_Sodreconciliation_apex_EXT869_CashActivity | EntryTypeCode | Passthrough — Apex entry type (MD=62.8%, CJ=37.1%) | Tier 2 |
| 12 | PayTypeCode | External_Sodreconciliation_apex_EXT869_CashActivity | PayTypeCode | Passthrough — Apex payment type (D=debit 99.99%, C=credit 0.01%) | Tier 2 |
| 13 | TerminalID | External_Sodreconciliation_apex_EXT869_CashActivity | TerminalID | Passthrough — Apex transaction type code; dividend/CA terminals excluded by WHERE filter | Tier 2 |
| 14 | Account | — | — | ETL-derived: hardcoded 'MSB' (Branch A) or 'Customers' (Branch B) — not from Apex source | Tier 2 |
| 15 | UpdateDate | — | — | GETDATE() at ETL run time | Tier 2 |
