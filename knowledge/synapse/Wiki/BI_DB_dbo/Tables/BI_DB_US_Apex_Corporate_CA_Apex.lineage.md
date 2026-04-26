# Lineage: BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex

**Generated**: 2026-04-22 | **Writer SP**: SP_US_Apex_Corporate_Cash_Actions_Recon | **Frequency**: Daily

## ETL Source Chain

```
Apex SOD869 file (External_Sodreconciliation_apex_EXT869_CashActivity)
  + External_Sodreconciliation_apex_SodFiles          (latest valid SOD869 file for @Date)
  + External_USABroker_Apex_ApexData / UserData        (eToroCID lookup via AccountNumber)
  + External_etoro_Trade_TerminalIDToCorporateAction   (TerminalID→CA mapping)
  + External_etoro_Dictionary_CorporateAction          (eToro CA type descriptions)
  + External_etoro_BackOffice_CompensationReason       (CompensationReason lookup)
    |-- SP_US_Apex_Corporate_Cash_Actions_Recon @Date (Daily) ---|
    |   DELETE WHERE ProcessDate=@Date + INSERT
    v
BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex
  (455,993 rows, Oct 2021 – Apr 2026, ROUND_ROBIN, HEAP)
  (UC: Not Migrated)

Companion table: BI_DB_US_Apex_Corporate_CA_etoro (eToro side of same reconciliation)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | AccountNumber | External_Sodreconciliation_apex_EXT869_CashActivity | AccountNumber | Passthrough — Apex account ID | Tier 2 |
| 2 | eToroCID | External_USABroker_Apex_UserData | CID | LEFT JOIN via #apex (AccountNumber→ApexID); NULL when no eToro CID match | Tier 2 |
| 3 | ProcessDate | External_Sodreconciliation_apex_EXT869_CashActivity | ProcessDate | Passthrough — same as @Date parameter | Tier 2 |
| 4 | TerminalID | External_Sodreconciliation_apex_EXT869_CashActivity | TerminalID | Passthrough — Apex corporate action type code | Tier 2 |
| 5 | Cusip | External_Sodreconciliation_apex_EXT869_CashActivity | Cusip | Passthrough — security CUSIP; NULL for non-equity CAs | Tier 2 |
| 6 | ApexDescription | External_Sodreconciliation_apex_EXT869_CashActivity | Description | Passthrough — Apex instrument/action full description | Tier 2 |
| 7 | eToroDescription | External_etoro_Dictionary_CorporateAction | Description (via TerminalID→CorporateActionTypeID) | Mapped via TerminalID lookup; NULL when no mapping | Tier 2 |
| 8 | eToroCorporateActionTypeID | External_etoro_Trade_TerminalIDToCorporateAction | CorporateActionTypeID | Mapped from TerminalID | Tier 2 |
| 9 | CompensationReasonID | External_etoro_BackOffice_CompensationReason | CompensationReasonID | Mapped via CorporateAction lookup; NULL when no mapping | Tier 2 |
| 10 | OriginalQuantity | External_Sodreconciliation_apex_EXT869_CashActivity | OriginalQuantity | ISNULL(OriginalQuantity, 0) — share count for equity CAs | Tier 2 |
| 11 | Amount | External_Sodreconciliation_apex_EXT869_CashActivity | Amount | ISNULL(Amount * -1, 0) — sign-flipped: positive=payment to customer | Tier 2 |
| 12 | UpdateDate | — | — | GETDATE() at ETL run time | Tier 2 |
