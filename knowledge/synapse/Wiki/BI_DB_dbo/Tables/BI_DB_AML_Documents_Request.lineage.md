# BI_DB_dbo.BI_DB_AML_Documents_Request — Column Lineage

**Generated**: 2026-04-22  
**Schema**: BI_DB_dbo  
**Object**: BI_DB_AML_Documents_Request  
**Writer SP**: SP_AML_Documents_Request  
**Load Pattern**: TRUNCATE + INSERT (full daily rebuild, no date parameter)  

---

## ETL Pipeline

```
Population base:
  DWH_dbo.Dim_Customer
    WHERE IsValidCustomer=1 AND VerificationLevelID>1
    INNER JOIN Dim_PlayerStatus NOT IN (2=Blocked, 4=BUR)
    → Only active, non-blocked customers who have entered the KYC process

Dimension enrichment (Step 01 — #pop):
  Dim_Regulation          → Regulation name
  Dim_Country (x3)        → Country (KYC), CitizenshipCountry, POBCountry
  Dim_PlayerStatus        → PlayerStatus name (INNER JOIN, Blocked/BUR excluded)
  Dim_PlayerStatusReasons → PlayerStatusReason name (LEFT JOIN)
  Dim_PlayerStatusSubReasons → PlayerStatusSubReasonName (LEFT JOIN)
  Dim_PlayerLevel         → Club name (INNER JOIN)
  Dim_ScreeningStatus     → ScreeningStatus name (LEFT JOIN)
  Dim_AccountType         → AccountType name (LEFT JOIN)
  Dim_EvMatchStatus       → EvMatchStatusName (LEFT JOIN)
  External_RiskClassification_dbo_V_RiskClassificationDataLake → RiskScoreName (LEFT JOIN)
  Computed from Dim_Customer: Age = DATEDIFF(YEAR, BirthDate, GETDATE())

Financial enrichment (Steps 02-06):
  Step 02 — #equity: V_Liabilities (Liabilities+ActualNWA) for DateID = yesterday
  Step 03 — #lastLogin: MAX(Fact_CustomerAction.DateID) WHERE ActionTypeID=14 (LoggedIn)
  Step 04 — #open_position: DISTINCT CID from BI_DB_PositionPnL WHERE DateID = yesterday
  Step 05 — #last_document_upload: MAX(External_etoro_BackOffice_CustomerDocument.DateAdded)
  Step 06 — #deposits: SUM(Fact_CustomerAction.Amount) WHERE ActionTypeID=7 (Deposits)

Document enrichment (Steps 02b-05 in SP naming: #Proof_of_Identity, #Proof_of_Address, #Selfie, #ProofOfIncome, #VideoIdent):
  Source: External_etoro_BackOffice_CustomerDocument (cd)
  Join:   External_etoro_BackOffice_CustomerDocumentToDocumentType (dt) → DocumentTypeID
          External_etoro_Dictionary_DocumentType (ddt) → Name (assigned type)
          External_etoro_Dictionary_DocumentType (ddt1) → Name (suggested type)
          External_etoro_Dictionary_DocumentRejectReason (rr) → RejectReasonName
  Filter: (ddt.Name = '{type}' OR ddt1.Name = '{type}') AND rr.RejectReasonName IS NULL
  Select: Most recent document per CID per type (ROW_NUMBER OVER PARTITION BY CID ORDER BY DateAdded DESC = 1)
  Types:
    - 'Proof of Identity'                    → POI columns
    - 'Proof of address'                     → POA columns
    - 'Selfie' / 'SelfieLiveliness' / 'Selfie Motion' → Selfie columns
    - 'Proof of Income'                      → POIncome columns
    - 'VideoIdent'                           → VideoIdent columns

Final assembly (#Final step):
  #pop + Dim_Customer (rejoin for IsIDProof, IsIDProofExpiryDate, IsAddressProof, IsAddressProofExpiryDate)
  Is_HRC = CASE WHEN AML_Rank IN (1,2,3) THEN 1 ELSE 0 END
  Equity  = ISNULL(ee.Equity, 0)
  Total_Deposits = ISNULL(ds.Total_Deposits, 0)
  Has_Open_position = CASE WHEN op.CID IS NOT NULL THEN 1 ELSE 0 END

TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Documents_Request
INSERT SELECT #Final + GETDATE() AS UpdateDate
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (alias) | T1 |
| 2 | Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID; INNER JOIN | T1 |
| 3 | Country | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.CountryID; INNER JOIN (KYC country of residence) | T1 |
| 4 | AML_Rank | DWH_dbo.Dim_Country | RiskGroupID | Lookup via Dim_Customer.CountryID; same join as Country | T1 |
| 5 | Is_HRC | — | AML_Rank | CASE WHEN AML_Rank IN (1,2,3) THEN 1 ELSE 0 END (0=not HRC, 1=High Risk Country) | T2 |
| 6 | CitizenshipCountry | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.CitizenshipCountryID; LEFT JOIN | T1 |
| 7 | POBCountry | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.POBCountryID; LEFT JOIN | T1 |
| 8 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Lookup via Dim_Customer.PlayerStatusID; INNER JOIN (excludes status 2=Blocked, 4=BUR) | T1 |
| 9 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Lookup via Dim_Customer.PlayerStatusReasonID; LEFT JOIN | T1 |
| 10 | PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Lookup via Dim_Customer.PlayerStatusSubReasonID; LEFT JOIN | T1 |
| 11 | Club | DWH_dbo.Dim_PlayerLevel | Name | Lookup via Dim_Customer.PlayerLevelID; INNER JOIN | T1 |
| 12 | RiskScoreName | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | LEFT JOIN ON CID = RealCID; passthrough from RiskClassification.dbo.V_RiskClassificationDataLake | T1 |
| 13 | ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | Lookup via Dim_Customer.ScreeningStatusID; LEFT JOIN (NULL = no screening status) | T3 |
| 14 | AccountType | DWH_dbo.Dim_AccountType | Name | Lookup via Dim_Customer.AccountTypeID; LEFT JOIN | T1 |
| 15 | EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | Lookup via Dim_Customer.EvMatchStatus; LEFT JOIN | T2 |
| 16 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough | T2 |
| 17 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | T1 |
| 18 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough | T1 |
| 19 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough | T2 |
| 20 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough; always >1 due to population filter | T1 |
| 21 | Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) — recalculated on each SP run | T2 |
| 22 | Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(Liabilities,0)+ISNULL(ActualNWA,0); WHERE DateID = yesterday | T2 |
| 23 | Total_Deposits | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 (Deposits); ISNULL(sum, 0) | T2 |
| 24 | Last_Login_Date | DWH_dbo.Fact_CustomerAction | DateID | MAX(DateID) WHERE ActionTypeID=14 (LoggedIn) — stored as INT YYYYMMDD | T2 |
| 25 | Has_Open_position | BI_DB_dbo.BI_DB_PositionPnL | CID | CASE WHEN CID IS NOT NULL THEN 1 ELSE 0 END; WHERE DateID = yesterday | T2 |
| 26 | last_document_upload | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | DateAdded | MAX(DateAdded) across all document types per CID | T2 |
| 27 | Has_POI | DWH_dbo.Dim_Customer | IsIDProof | Passthrough (renamed); NULL if never had POI document | T2 |
| 28 | POI_ExpiryDate | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | Passthrough (renamed); NULL if no POI or no expiry | T2 |
| 29 | DocumentType_POI | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | Formally assigned document type name for most recent POI document (ddt.Name); NULL if no POI | T2 |
| 30 | DocumentDateAdded_POI | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | DateAdded | DateAdded of most recent POI document (ROW_NUMBER DESC); NULL if no POI | T2 |
| 31 | SuggestedDocumentType_POI | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | AI-suggested document type name (ddt1.Name via SuggestedDocumentTypeID) for most recent POI document; NULL if no POI | T2 |
| 32 | Has_POA | DWH_dbo.Dim_Customer | IsAddressProof | Passthrough (renamed); NULL if never had POA document | T2 |
| 33 | POA_ExpiryDate | DWH_dbo.Dim_Customer | IsAddressProofExpiryDate | Passthrough (renamed); NULL if no POA or no expiry | T2 |
| 34 | DocumentType_POA | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | Formally assigned document type name for most recent POA document; NULL if no POA | T2 |
| 35 | DocumentDateAdded_POA | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | DateAdded | DateAdded of most recent POA document (ROW_NUMBER DESC); NULL if no POA | T2 |
| 36 | SuggestedDocumentType_POA | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | AI-suggested document type name for most recent POA document; NULL if no POA | T2 |
| 37 | DocumentType_POIncome | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | Formally assigned document type name for most recent Proof of Income document; NULL if none | T2 |
| 38 | DocumentDateAdded_POIncome | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | DateAdded | DateAdded of most recent Proof of Income document (ROW_NUMBER DESC); NULL if none | T2 |
| 39 | SuggestedDocumentType_POIncome | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | AI-suggested document type name for most recent Proof of Income document; NULL if none | T2 |
| 40 | DocumentType_Selfie | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | Formally assigned document type name for most recent Selfie/SelfieLiveliness/Selfie Motion document; NULL if none | T2 |
| 41 | DocumentDateAdded_Selfie | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | DateAdded | DateAdded of most recent Selfie document (ROW_NUMBER DESC); NULL if none | T2 |
| 42 | SuggestedDocumentType_Selfie | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | AI-suggested document type name for most recent Selfie document; NULL if none | T2 |
| 43 | DocumentType_VideoIdent | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | Formally assigned document type name for most recent VideoIdent document; NULL if none | T2 |
| 44 | DocumentDateAdded_VideoIdent | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | DateAdded | DateAdded of most recent VideoIdent document (ROW_NUMBER DESC); NULL if none | T2 |
| 45 | SuggestedDocumentType_VideoIdent | BI_DB_dbo.External_etoro_Dictionary_DocumentType | Name | AI-suggested document type name for most recent VideoIdent document; NULL if none | T2 |
| 46 | UpdateDate | — | — | GETDATE() at INSERT time | Propagation blacklist |

---

## UC External Lineage

**UC Target**: Not migrated — AML compliance daily workbench, no UC target.

---

## Source Objects

| Object | Type | Notes |
|--------|------|-------|
| DWH_dbo.Dim_Customer | Dimension | Population base, customer attributes (CID, VerificationLevelID, IsValidCustomer, IsDepositor, HasWallet, RegisteredReal, FirstDepositDate, BirthDate, IsIDProof/ExpiryDate, IsAddressProof/ExpiryDate) |
| DWH_dbo.Dim_Regulation | Dimension | Regulation name |
| DWH_dbo.Dim_Country | Dimension | Country name (KYC, citizenship, POB) and RiskGroupID/AML_Rank |
| DWH_dbo.Dim_PlayerStatus | Dimension | Player status name (INNER JOIN — excludes Blocked ID=2, BUR ID=4) |
| DWH_dbo.Dim_PlayerStatusReasons | Dimension | Status change reason name |
| DWH_dbo.Dim_PlayerStatusSubReasons | Dimension | Status change sub-reason name |
| DWH_dbo.Dim_PlayerLevel | Dimension | Club/loyalty tier name |
| DWH_dbo.Dim_ScreeningStatus | Dimension | World-Check screening outcome name |
| DWH_dbo.Dim_AccountType | Dimension | Account type name |
| DWH_dbo.Dim_EvMatchStatus | Dimension | Electronic verification match status name |
| DWH_dbo.V_Liabilities | View | Customer equity: Liabilities + ActualNWA |
| DWH_dbo.Fact_CustomerAction | Fact | Login history (ActionTypeID=14) and deposit amounts (ActionTypeID=7) |
| BI_DB_dbo.BI_DB_PositionPnL | Table | Open positions check for yesterday |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | External Table | AML risk score level (RiskScoreName) from RiskClassification.dbo.V_RiskClassificationDataLake |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | External Table | Document upload metadata (DateAdded, CID, SuggestedDocumentTypeID) |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | External Table | Formal document type assignment (DocumentID → DocumentTypeID) |
| BI_DB_dbo.External_etoro_Dictionary_DocumentType | External Table | Document type name lookup (Name for assigned and suggested types) |
| BI_DB_dbo.External_etoro_Dictionary_DocumentRejectReason | External Table | Reject reason lookup (RejectReasonName IS NULL filter = accepted documents only) |
