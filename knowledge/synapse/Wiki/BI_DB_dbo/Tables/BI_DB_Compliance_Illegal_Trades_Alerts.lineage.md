# BI_DB_dbo.BI_DB_Compliance_Illegal_Trades_Alerts — Column Lineage

> Generated: 2026-04-23 | Batch 71

## Object Metadata

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Writer SP | SP_Compliance_Forbidden_Trades |
| Load Pattern | DELETE WHERE Date = @Date + INSERT (daily incremental; cumulative) |
| Population | All valid customers (IsValidCustomer=1) who triggered at least one active compliance rule on @Date |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Customer + Dim_Regulation + Dim_Country + Dim_Manager
  + Dim_MifidCategorization + Dim_Language + Dim_PlayerStatus + Dim_PlayerStatusReasons
  + Dim_PlayerStatusSubReasons + Dim_PlayerLevel + BI_DB_CIDFirstDates + #lastBlocked
  + External_etoro_BackOffice_Customer (SeychellesCategorizationID)
    → #pop (all valid customers with full customer context as of @Date)

Per-rule temp tables (30+ rules):
  #bu1  — Blocked Users Opened Trade
  #bc3  — Blocked Countries Registration succeeded
  #bc4  — High Risk Countries rank 1 deposit   (uses #pop_last_deposit_data)
  #bc7  — Client Traded Sanctioned stock        (uses position + instrument data)
  #pc1..#pc53 — Position/Country/Regulation restriction violations (use Dim_Position + Dim_Instrument)

UNION all active rules → #final
  + ROW_NUMBER() + max(existing RecordID) → #final2 (adds RecordID)
  |-- SP_Compliance_Forbidden_Trades (@Date) DELETE(@Date)+INSERT ---|
  v
BI_DB_dbo.BI_DB_Compliance_Illegal_Trades_Alerts (259,077 rows, 798 daily dates)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Notes | Tier |
|---|-----------|--------------|---------------|-------|------|
| 1 | Date | SP parameter | @Date | Reporting date for all rows in this batch | Tier 2 — SP |
| 2 | AlertType | SP literal | — | Hardcoded rule code per rule temp table (e.g., 'PC17', 'BC4') | Tier 2 — SP |
| 3 | Synopsis | SP literal | — | Hardcoded description per rule (e.g., 'Trade exceeded leverage restrictions') | Tier 2 — SP |
| 4 | RealCID | DWH_dbo.Fact_SnapshotCustomer / Dim_Position | RealCID | Customer ID stored as varchar(100); actual CID value | Tier 1 — Customer.CustomerStatic |
| 5 | Country | DWH_dbo.Dim_Country | Name | Via #pop from Fact_SnapshotCustomer.CountryID | Tier 1 — Dim_Country wiki |
| 6 | AccountMgr | DWH_dbo.Dim_Manager | FirstName + LastName | Concatenated; truncated to 10 chars in some rules | Tier 2 — SP_Compliance_Forbidden_Trades |
| 7 | UserName | DWH_dbo.Dim_Customer | UserName | Customer platform username | Tier 2 — Dim_Customer |
| 8 | Language | DWH_dbo.Dim_Language | Name | Via #pop from Fact_SnapshotCustomer.LanguageID | Tier 2 — SP_Compliance_Forbidden_Trades |
| 9 | MifidCategorization | DWH_dbo.Dim_MifidCategorization | Name | Via #pop; e.g., 'Retail', 'Professional', 'Elective professional' | Tier 2 — SP_Compliance_Forbidden_Trades |
| 10 | Regulation | DWH_dbo.Dim_Regulation | Name | Via #pop from Fact_SnapshotCustomer.RegulationID | Tier 1 — Dim_Regulation wiki |
| 11 | PositionID | DWH_dbo.Dim_Position | PositionID | NULL for non-position alerts (e.g., BC4 deposit alerts) | Tier 2 — Dim_Position wiki |
| 12 | OpenDateID | DWH_dbo.Dim_Position | OpenDateID | Position open date as varchar YYYYMMDD; NULL for non-position alerts | Tier 2 — Dim_Position wiki |
| 13 | InvestedAmount | DWH_dbo.Dim_Position | Amount / Volume | Position invested amount as varchar; NULL for non-position alerts | Tier 3 — SP inferred |
| 14 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Via Dim_Instrument JOIN; NULL for non-position alerts | Tier 2 — Dim_Instrument wiki |
| 15 | IsSettled | DWH_dbo.Dim_Position | IsSettled | '1'=Real, '0'=CFD stored as varchar; NULL for non-position alerts | Tier 2 — Dim_Position wiki |
| 16 | Leverage | DWH_dbo.Dim_Position | Leverage | Position leverage ratio as varchar; NULL for non-position alerts | Tier 3 — SP inferred |
| 17 | IsCopy | DWH_dbo.Dim_Position | MirrorID / ParentPositionID | Copy indicator as varchar; NULL for non-position alerts | Tier 2 — SP_Compliance_Forbidden_Trades |
| 18 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Via #pop; e.g., 'Normal', 'Blocked' | Tier 2 — SP_Compliance_Forbidden_Trades |
| 19 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Via #pop; block reason name | Tier 2 — SP_Compliance_Forbidden_Trades |
| 20 | PlayerSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Via #pop; sub-reason name | Tier 2 — SP_Compliance_Forbidden_Trades |
| 21 | VerificationLevelID | DWH_dbo.Fact_SnapshotCustomer | VerificationLevelID | Stored as varchar(100); 0=None, 1=Basic, 2=Enhanced, 3=Full | Tier 2 — SP_Compliance_Forbidden_Trades |
| 22 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Real account registration date as varchar (ISO format) | Tier 2 — Dim_Customer |
| 23 | UpdateDate | ETL | GETDATE() | Runtime timestamp | Propagation |
| 24 | BlockDate | #lastBlocked | DateFrom | Most recent block date from PlayerStatus history; NULL if never blocked | Tier 2 — SP_Compliance_Forbidden_Trades |
| 25 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Date of first deposit | Tier 2 — Dim_Customer |
| 26 | PlayerStatusReasonID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusReasonID | Integer reason ID | Tier 2 — SP_Compliance_Forbidden_Trades |
| 27 | PlayerStatusSubReasonID | DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | Integer sub-reason ID | Tier 2 — SP_Compliance_Forbidden_Trades |
| 28 | DepositDate | BI_DB_CIDFirstDates | LastDepositDate | Last deposit date; NULL for non-deposit alerts | Tier 2 — SP_Compliance_Forbidden_Trades |
| 29 | GCID | DWH_dbo.Dim_Customer | GCID | Global Customer ID (cross-platform) stored as varchar | Tier 2 — Dim_Customer |
| 30 | TranID | Deposit/transaction source | DepositID | Transaction/deposit ID for deposit-related alerts; NULL for position alerts | Tier 3 — SP inferred |
| 31 | Occurred | Deposit/transaction source | Occurred | Deposit or transaction occurred timestamp as varchar; NULL for non-deposit alerts | Tier 3 — SP inferred |
| 32 | AmountUSD | Deposit/transaction source | Amount | Transaction amount in USD as varchar; NULL for non-deposit alerts | Tier 3 — SP inferred |
| 33 | State | Deposit/transaction source | State | Transaction state as varchar (rule-specific); NULL for most rules | Tier 3 — SP inferred |
| 34 | CryptoName | Crypto/instrument source | Name | Crypto asset name; populated only for crypto-specific rules | Tier 3 — SP inferred |
| 35 | CryptoID | Crypto/instrument source | ID | Crypto asset ID; populated only for crypto-specific rules | Tier 3 — SP inferred |
| 36 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Instrument display label; NULL for non-position alerts | Tier 2 — Dim_Instrument |
| 37 | UpdatedClub | DWH_dbo.Dim_PlayerLevel | Name | Current Club tier at time of alert (via #pop); e.g., 'Silver', 'Gold' | Tier 2 — SP_Compliance_Forbidden_Trades |
| 38 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | FK to Dim_Instrument; NULL for non-position alerts | Tier 2 — Dim_Instrument |
| 39 | SeychellesCategorizationID | External_etoro_BackOffice_Customer | SeychellesCategorizationID | FSA Seychelles categorization ID (2=Advanced, else Basic); NULL for non-FSA customers | Tier 2 — SP_Compliance_Forbidden_Trades |
| 40 | SeychellesCategorization | #fsa_categorization | CASE expression | 'Advanced' (SeychellesCategorizationID=2) or 'Basic' (else); NULL for non-FSA | Tier 2 — SP_Compliance_Forbidden_Trades |
| 41 | RecordID | SP computation | ROW_NUMBER() | Running unique record ID: max(existing RecordID) + ROW_NUMBER() per batch. NULL for rows pre-dating 2025-03-09 addition. | Tier 2 — SP_Compliance_Forbidden_Trades |
