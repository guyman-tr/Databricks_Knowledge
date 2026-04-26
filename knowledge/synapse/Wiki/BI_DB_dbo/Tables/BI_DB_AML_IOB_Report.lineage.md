# BI_DB_dbo.BI_DB_AML_IOB_Report — Column Lineage

**Generated**: 2026-04-22  
**Schema**: BI_DB_dbo  
**Object**: BI_DB_AML_IOB_Report  
**Writer SP**: SP_AML_IOB_Report  
**Author**: Lior Ben Dor (2025-07-03)  
**Load Pattern**: TRUNCATE + INSERT (full daily rebuild, no date parameter)  

---

## ETL Pipeline

```
Population base (Step 01 — #BasePop):
  BI_DB_dbo.External_Interest_Trade_InterestConsent WHERE ConsentStatusID=1
  → Only customers who have opted in to the IOB (Interest on Balance) program

Customer enrichment (Step 02 — #pop):
  DWH_dbo.Dim_Customer (INNER JOIN on #BasePop.CID = Dim_Customer.RealCID)
    WHERE IsValidCustomer=1
    INNER JOIN Dim_PlayerStatus NOT IN (2=Blocked, 4=BUR)
    INNER JOIN Dim_Regulation, Dim_Country, Dim_PlayerLevel
    LEFT JOINs: Dim_Country (x2 for citizenship/POB), Dim_PlayerStatusReasons,
                Dim_PlayerStatusSubReasons
  Is_Eligible computed here:
    CASE WHEN PlayerStatusID=1 (Normal)
         AND RegulationID IN (1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA)
         AND CountryID NOT IN (219=United States, 250=eToro entity)
         AND PlayerLevelID IN (1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond)
    THEN 1 ELSE 0 END

Account_Balance (Step 03 — #equity):
  DWH_dbo.V_Liabilities WHERE DateID = yesterday
  RealizedEquity column specifically (not Liabilities+ActualNWA)

Interest payments (Step 04 — #interest):
  DWH_dbo.etoro_History_Credit
    WHERE CompensationReasonID IN (57,62) AND CreditTypeID=6
    AND Occurred >= '20250601' AND Occurred < '20250701'  [HARDCODED JUNE 2025]
  SUM(Payment) per CID → Payment_interest_June

Open positions (Step 05 — #open_position):
  BI_DB_dbo.BI_DB_PositionPnL WHERE DateID = yesterday
  DISTINCT CID existence check

Deposits since IOB date (Step 06 — #deposits):
  DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=7 (Deposits)
  AND DateID >= #BasePop.ValidFromInt (since IOB consent date)
  SUM(Amount) per CID

Withdrawals since IOB date (Step 07 — #CO):
  DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=8 (cash-out/withdrawal)
  AND DateID >= #BasePop.ValidFromInt (since IOB consent date)
  SUM(Amount) per CID

DateAdded_Proof_of_Income (Step 08 — #final):
  LEFT JOIN BI_DB_dbo.BI_DB_AML_Documents_Request ON CID
  → DocumentDateAdded_POIncome passthrough
  WARNING: BI_DB_AML_Documents_Request has multiple rows per CID (multi-regulation),
  causing fan-out in the final table (~4.97M rows for ~318K distinct CIDs ≈ 15.6x)

TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_IOB_Report
INSERT SELECT #final + GETDATE() AS UpdateDate
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough via #BasePop.CID JOIN | T1 |
| 2 | Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID; INNER JOIN | T1 |
| 3 | Country | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.CountryID; INNER JOIN | T1 |
| 4 | CitizenshipCountry | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.CitizenshipCountryID; LEFT JOIN | T1 |
| 5 | POBCountry | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.POBCountryID; LEFT JOIN | T1 |
| 6 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Lookup via Dim_Customer.PlayerStatusID; INNER JOIN (excludes Blocked/BUR) | T1 |
| 7 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Lookup via Dim_Customer.PlayerStatusReasonID; LEFT JOIN | T1 |
| 8 | PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Lookup via Dim_Customer.PlayerStatusSubReasonID; LEFT JOIN | T1 |
| 9 | Club | DWH_dbo.Dim_PlayerLevel | Name | Lookup via Dim_Customer.PlayerLevelID; INNER JOIN | T1 |
| 10 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | T1 |
| 11 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough; computed by SP_Dim_Customer | T2 |
| 12 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough; no filter (includes levels 1,2,3) | T1 |
| 13 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough; computed by SP_Dim_Customer | T2 |
| 14 | Is_Eligible | — | Multiple Dim_Customer fields | CASE WHEN PlayerStatusID=1 AND RegulationID IN(1,2,4,9,10,11) AND CountryID NOT IN(219,250) AND PlayerLevelID IN(1,2,3,5,6,7) THEN 1 ELSE 0 END | T2 |
| 15 | Account_Balance | DWH_dbo.V_Liabilities | RealizedEquity | ISNULL(RealizedEquity,0) for yesterday's DateID | T2 |
| 16 | Date_IOB_switched_on | BI_DB_dbo.External_Interest_Trade_InterestConsent | ValidFrom | Passthrough; date customer opted into IOB | T2 |
| 17 | Deposits_since_IOB_date | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=7 AND DateID >= ValidFromInt; ISNULL→0 | T2 |
| 18 | Withdrawals_since_IOB_date | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=8 AND DateID >= ValidFromInt; ISNULL→0 | T2 |
| 19 | Has_Open_Position | BI_DB_dbo.BI_DB_PositionPnL | CID | CASE WHEN CID IS NOT NULL THEN 1 ELSE 0 END; WHERE DateID = yesterday | T2 |
| 20 | DateAdded_Proof_of_Income | BI_DB_dbo.BI_DB_AML_Documents_Request | DocumentDateAdded_POIncome | Passthrough via LEFT JOIN ON CID; may duplicate due to multi-row source | T2 |
| 21 | Payment_interest_June | DWH_dbo.etoro_History_Credit | Payment | SUM WHERE CompensationReasonID IN(57,62) AND CreditTypeID=6 AND Occurred IN [2025-06-01, 2025-07-01); ISNULL→0; HARDCODED June 2025 | T2 |
| 22 | UpdateDate | — | — | GETDATE() at INSERT time | Propagation blacklist |

---

## UC External Lineage

**UC Target**: Not migrated — AML compliance IOB monitoring report.

---

## Source Objects

| Object | Type | Notes |
|--------|------|-------|
| BI_DB_dbo.External_Interest_Trade_InterestConsent | External Table | IOB opt-in population (ConsentStatusID=1); provides CID, GCID, ValidFrom (IOB consent date) |
| DWH_dbo.Dim_Customer | Dimension | Customer attributes (IsValidCustomer=1 filter) |
| DWH_dbo.Dim_Regulation | Dimension | Regulation name |
| DWH_dbo.Dim_Country | Dimension | Country name (x3: residence, citizenship, POB) |
| DWH_dbo.Dim_PlayerStatus | Dimension | Status name (INNER JOIN, excludes Blocked/BUR) |
| DWH_dbo.Dim_PlayerLevel | Dimension | Club tier name |
| DWH_dbo.Dim_PlayerStatusReasons | Dimension | Status reason name |
| DWH_dbo.Dim_PlayerStatusSubReasons | Dimension | Status sub-reason name |
| DWH_dbo.V_Liabilities | View | Account_Balance = RealizedEquity for yesterday |
| DWH_dbo.etoro_History_Credit | Table | IOB interest payments (June 2025, hardcoded) |
| DWH_dbo.Fact_CustomerAction | Fact | Deposits (ActionTypeID=7) and withdrawals (ActionTypeID=8) since IOB date |
| BI_DB_dbo.BI_DB_PositionPnL | Table | Open position check for yesterday |
| BI_DB_dbo.BI_DB_AML_Documents_Request | Table | Source of DateAdded_Proof_of_Income (DocumentDateAdded_POIncome) — WARNING: multi-row source |
