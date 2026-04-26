# Lineage: BI_DB_dbo.BI_DB_AML_KYC_SOF

## Writer SP

`BI_DB_dbo.SP_AML_KYC_SOF` — TRUNCATE + INSERT pattern. Runs at OpsDB Priority 0 (base layer). Full refresh on each run.

## Source Objects

| # | Source Object | Type | Role | Columns Contributed |
|---|--------------|------|------|---------------------|
| 1 | DWH_dbo.Dim_Customer | Dim | Primary population base; identity, demographics, financial profile | CID (RealCID), GCID, FirstDepositDate, FirstDepositAmount, RegisteredReal, Gender, UserName, AccountManagerID (for Dim_Manager JOIN); filter: IsValidCustomer=1, VerificationLevelID=3, IsDepositor=1 |
| 2 | DWH_dbo.Dim_Regulation | Dim | Resolve regulation name | Regulation = Name |
| 3 | DWH_dbo.Dim_PlayerStatus | Dim | Resolve player status name (no exclusion for Blocked) | PlayerStatus = Name |
| 4 | DWH_dbo.Dim_PlayerLevel | Dim | Resolve customer tier name | Club = Name |
| 5 | DWH_dbo.Dim_Country | Dim | Resolve country name and marketing region | Country = Name, Region = Region |
| 6 | DWH_dbo.Dim_Manager | Dim | Resolve account manager name | ManagerFullName = FirstName + ' ' + LastName |
| 7 | BI_DB_dbo.BI_DB_KYC_Panel | Table | KYC questionnaire answers (annual income, liquid assets, planned investment) | Q10_Annual_Income, Q10_AnswerText, Q11_Liquid_Assets, Q11_AnswerText, Q14_Planned_Invested_Amount, Q14_AnswerText |
| 8 | DWH_dbo.Fact_CustomerAction | Fact | All-time approved deposits (ActionTypeID=7) | Total_Deposit = SUM(Amount) |
| 9 | DWH_dbo.V_Liabilities | View | Net equity snapshot as of yesterday | Equity = Liabilities + ActualNWA |
| 10 | BI_DB_dbo.BI_DB_PositionPnL | Table | Open position flag for yesterday | HasOpenPosition = MAX(1 if PositionID IS NOT NULL, else 0) WHERE DateID=yesterday |
| 11 | DWH_dbo.Dim_Position | Dim | Last open/close position dates | Last_Open_Position_Date = MAX(OpenOccurred), Last_Close_Position_Date = MAX(CloseOccurred) |
| 12 | DWH_dbo.Fact_CustomerAction (ActionTypeID=14) | Fact | Last login DateID | Last_Login_Date = MAX(DateID) WHERE ActionTypeID=14 (Login) |
| 13 | BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | External Table | Customer-submitted proof of income documents | DocumentType, DocumentDateAdded, SuggestedDocumentType |
| 14 | BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | External Table | Document-to-type mapping | Links DocumentID to DocumentTypeID |
| 15 | BI_DB_dbo.External_etoro_BackOffice_Customer | External Table | Customer BackOffice record | DocumentStatusID for document status lookup |
| 16 | BI_DB_dbo.External_etoro_Dictionary_DocumentType | External Table | Document type name lookup (used twice: actual type + suggested type) | DocumentType = Name, SuggestedDocumentType = Name |
| 17 | BI_DB_dbo.External_etoro_Dictionary_DocumentStatus | External Table | Document status name lookup | DocumentStatus |
| 18 | BI_DB_dbo.External_etoro_Dictionary_DocumentRejectReason | External Table | Document reject reason name | RejectReasonName |
| 19 | BI_DB_dbo.BI_DB_SF_Cases_Panel | Table | Salesforce AML open cases | HasOpenTicket (computed but UNUSED in final output — orphaned temp table) |

## Data Flow

```
VL3 Depositors Base Population:
  DWH_dbo.Dim_Customer (IsValidCustomer=1, VerificationLevelID=3, IsDepositor=1)
  JOIN Dim_Regulation → Regulation
  JOIN Dim_PlayerLevel → Club
  JOIN Dim_Country → Country, Region
  JOIN Dim_PlayerStatus → PlayerStatus
  LEFT JOIN Dim_Manager → ManagerFullName
           ↓ #pop
  INNER JOIN BI_DB_KYC_Panel (requires KYC questionnaire completion)
           → Q10/Q11/Q14 question labels + answer texts
           ↓ #KYC
  JOIN Fact_CustomerAction (ActionTypeID=7) → Total_Deposit
           ↓ #deposit
  Computed:
    Max_Q14_Answer = map Q14_AnswerText to numeric cap via CASE
    RemainingAmount = Max_Q14_Answer - Total_Deposit
    %RemainingAmount = (RemainingAmount/Max_Q14_Answer) * 100
    SOF_Predication = 'SOF should be checked' | 'SOF' | 'Do not check SOF'
    ReasonType = 'HNWI' | 'More then decleared deposit' | 'Less then 15% left' | 'Normal'
    HasBusinessPotential = 1 if %RemainingAmount >= 85
           ↓ #BusinessPotential
  LEFT JOIN BI_DB_SF_Cases_Panel (AML open tickets) → HasOpenTicket [ORPHANED — not in final]
  LEFT JOIN V_Liabilities → Equity
  LEFT JOIN BI_DB_PositionPnL → HasOpenPosition
  LEFT JOIN Dim_Position → Last_Open_Position_Date, Last_Close_Position_Date
  LEFT JOIN Fact_CustomerAction (ActionTypeID=14) → Last_Login_Date
           ↓ #consolidate
  LEFT JOIN External BackOffice CustomerDocument chain → DocumentType, DocumentStatus,
    HasProofOfIncome, HasSOFLast6Months
           ↓ #ProofOfIncome2 → #final

  SP_AML_KYC_SOF
    TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_KYC_SOF
    INSERT INTO ... FROM #final
         ↓
  BI_DB_dbo.BI_DB_AML_KYC_SOF
```

## SOF Prediction Business Logic

| Condition | SOF_Predication | ReasonType |
|-----------|----------------|-----------|
| Q14_AnswerText = 'Above $1M' | SOF should be checked | HNWI |
| RemainingAmount < 0 | SOF | More then decleared deposit |
| RemainingAmount / Max_Q14_Answer < 0.15 AND RemainingAmount > 0 | SOF | Less then 15% left |
| All others | Do not check SOF | Normal |

HasBusinessPotential = 1 when `%RemainingAmount >= 85` (≥85% of planned investment not yet deposited).

## Q14 Answer Mapping (Max_Q14_Answer derivation)

| Q14_AnswerText | Max_Q14_Answer | Note |
|---------------|---------------|------|
| Up to $1k | 1,000 | |
| $1k - $5k | 5,000 | |
| $5k - $20k | 20,000 | |
| Up to $20K | 20,000 | Same cap as $5k-$20k |
| $20k - $50k | 50,000 | |
| $50k-$200k | 200,000 | |
| $200k - $500k | 500,000 | |
| $500k - $1M | 1,000,000 | |
| Above $1M | 1,000,000 | Triggers 'SOF should be checked' regardless |
| $20k - $100k | 0 (ELSE case) | Missing from CASE — division by zero risk |
| More than $100k | 0 (ELSE case) | Missing from CASE — division by zero risk |

## Known Data Issues

1. **`%RemainingAmount` column name**: Special character `%` in column name. Must be quoted as `[%RemainingAmount]` in all SQL queries.
2. **`SOF_Predication` spelling**: "Predication" may be a misspelling of "Prediction." The value is hardcoded in the SP. Not a data quality issue, but column naming is unusual.
3. **`ReasonType` typos**: Values have spelling errors preserved from SP code: "More then decleared deposit" (should be "declared") and "Less then 15% left" (should be "than"). Do NOT attempt to fix in queries — match the exact stored strings.
4. **Orphaned #AMLticket temp table**: SP computes `HasOpenTicket` from BI_DB_SF_Cases_Panel but this column is NOT present in the final DDL or INSERT statement. The temp table and Salesforce JOIN are dead code — potentially a legacy feature.
5. **Q14 CASE statement gap**: Q14_AnswerText values '$20k-$100k' and 'More than $100k' are not handled in the CASE statement; they fall through to ELSE '0'. This results in Max_Q14_Answer=0, making %RemainingAmount and RemainingAmount unreliable for these ~1,505 rows.
6. **SP uses WITH(NOLOCK)**: Synapse uses snapshot isolation; NOLOCK is unnecessary and is a code smell. No data correctness impact.

---
*Generated: 2026-04-22 | Object: BI_DB_dbo.BI_DB_AML_KYC_SOF | Writer SP: SP_AML_KYC_SOF*
