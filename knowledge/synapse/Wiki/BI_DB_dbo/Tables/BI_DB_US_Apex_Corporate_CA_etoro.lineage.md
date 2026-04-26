# Lineage: BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro

**Generated**: 2026-04-22 | **Writer SP**: SP_US_Apex_Corporate_Cash_Actions_Recon | **Frequency**: Daily

## ETL Source Chain

```
External_etoro_history_credit_Apex_Artyom  (CreditTypeID=14, RegulationID=8 USA)
  + External_etoro_BackOffice_Customer     (RegulationID=8 filter)
  + External_USABroker_Apex_ApexData       (ApexID lookup via CID)
  + External_etoro_Trade_TerminalIDToCorporateAction + External_etoro_Dictionary_CorporateAction
    (CompensationReason mapping, with CASE fallback for Cash Dividend / Not defined)
    |-- SP_US_Apex_Corporate_Cash_Actions_Recon @Date (Daily) ---|
    |   DELETE WHERE Date=@Date + INSERT
    v
BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro
  (987,192 rows, Oct 2021 – Apr 2026, ROUND_ROBIN, HEAP)
  (UC: Not Migrated)

Companion table: BI_DB_US_Apex_Corporate_CA_Apex (Apex SOD869 side of same reconciliation)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | Date | External_etoro_history_credit_Apex_Artyom | Occurred | CAST(Occurred AS DATE) | Tier 2 |
| 2 | CID | External_etoro_history_credit_Apex_Artyom | CID | Passthrough — eToro customer ID | Tier 2 |
| 3 | CompensationReasonID | External_etoro_history_credit_Apex_Artyom | CompensationReasonID | Passthrough (NULL when no matching mapping in #cadesc) | Tier 2 |
| 4 | Payment | External_etoro_history_credit_Apex_Artyom | Payment | Passthrough — payment amount | Tier 2 |
| 5 | TotalCashChange | External_etoro_history_credit_Apex_Artyom | TotalCashChange | Passthrough — total cash balance change | Tier 2 |
| 6 | Description | External_etoro_history_credit_Apex_Artyom | Description | Passthrough — eToro credit description text | Tier 2 |
| 7 | ApexID | External_USABroker_Apex_ApexData | ApexID via CID | LEFT JOIN via #apex; NULL when no Apex account linked | Tier 2 |
| 8 | UpdateDate | — | — | GETDATE() at ETL run time | Tier 2 |
| 9 | eToroCorporateActionTypeID | External_etoro_Trade_TerminalIDToCorporateAction | CorporateActionTypeID | Mapped from CompensationReasonID; NULL for unmatched rows | Tier 2 |
| 10 | CA_Desc_ID | External_etoro_history_credit_Apex_Artyom | Description | Numeric CA ID extracted from Description text via PATINDEX | Tier 2 |
| 11 | CA_Description | External_etoro_Dictionary_CorporateAction | Description | Looked up by CA_Desc_ID integer; description of the CA type | Tier 2 |
| 12 | eToroDescription | External_etoro_Dictionary_CorporateAction | Description (via CompensationReasonID) | CASE: mapped desc if CompensationReasonID matched; 'Cash Dividend' if Description LIKE '%Cash Dividend%'; else 'Not defined' | Tier 2 |
