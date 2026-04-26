# BI_DB_dbo.BI_DB_Copyfunds_SignificantAllocation — Lineage

**Generated**: 2026-04-23  
**Writer SP**: SP_Copyfunds_SignificantAllocation  
**Load Pattern**: TRUNCATE + INSERT (daily snapshot — no history)  

---

## Source Objects

| Object | Schema | Type | Role |
|---|---|---|---|
| Fact_CustomerAction | DWH_dbo | Fact | CopyFund add/remove money flows (ActionTypeID 15=Mirror In, 16=Mirror Out, 17=New Mirror, 18=UnMirror) for yesterday; source for AddMoneyIn, AddMoneyOut, NetMoneyOut |
| Dim_Customer (copier) | DWH_dbo | Dimension | Customer attributes (IsValidCustomer=1); provides UserName |
| Dim_Customer (parent/manager) | DWH_dbo | Dimension | Identifies CopyFund or PI being copied (AccountTypeID=9 OR GuruStatusID>=2) |
| Dim_Mirror | DWH_dbo | Dimension | MirrorID → joins Fact_CustomerAction to the copied entity (ParentCID) |
| Dim_Country | DWH_dbo | Dimension | Geographic region for the copier's registered country (Dim_Country.Region) |
| Dim_Manager | DWH_dbo | Dimension | Account manager name (FirstName + ' ' + LastName) via dc.AccountManagerID |
| V_Liabilities | DWH_dbo | View | Copier's current account Balance (Credit) and RealizedEquity as of @YestardayDateID |
| BI_DB_UsageTracking_SF | BI_DB_dbo | Table | Salesforce contact history: last contacted date for 'Completed_Contact_Email__c' and 'Phone_Call_Succeed__c' actions; INNER JOIN — customers with no contact record are EXCLUDED |

---

## Writer

| SP | Load Pattern | Parameters |
|---|---|---|
| SP_Copyfunds_SignificantAllocation | TRUNCATE + INSERT | None — hardcoded @Date = GETDATE()-1 |

---

## Downstream Consumers

None identified in the SSDT repository. Operational email alert table for account managers to identify clients with significant CopyFund allocation changes (>$10K net or bilateral >$200K).

---

## ETL Data Flow

```
@Date = DATEADD(day, -1, GETDATE())   [yesterday, hardcoded]
@YestardayDateID = Convert(varchar(10), @Date, 112)

[Significant Money Movements]
Fact_CustomerAction (ActionTypeID BETWEEN 15 AND 18, DateID = @YestardayDateID)
  JOIN Dim_Customer (copier: IsValidCustomer=1)
  JOIN Dim_Mirror hm (MirrorID → identifies the CopyFund/PI being copied)
  JOIN Dim_Customer (parent: AccountTypeID=9 OR GuruStatusID>=2)
  GROUP BY RealCID, UserName
  HAVING |NetMoneyIn| >= 10000
    OR (AddMoneyIn >= 200000 AND AddMoneyOut >= 200000)
  → #NetMoneyIn (RealCID, UserName, AddMoneyIn, AddMoneyOut, NetMoneyIn)
    ActionTypeID 15,17 → AddMoneyIn:  -1 * SUM(Amount)
    ActionTypeID 16,18 → AddMoneyOut: -1 * SUM(Amount)
    All 4 types      → NetMoneyIn:   -1 * SUM(Amount)   [note: column inserted as NetMoneyOut]

[CopyFund Listing — which CopyFunds/PIs the customer copied]
Fact_CustomerAction (same filter) JOIN Dim_Mirror JOIN Dim_Customer (copier) JOIN Dim_Customer (parent)
  JOIN #NetMoneyIn → limits to significant-movement customers
  Row_Number() OVER (PARTITION BY RealCID ORDER BY ParentUserName) → [Order of Copyfund]
  PI/CP classification: AccountTypeID=9 → 'CopyPortfolio'; GuruStatusID>=2 → 'PI'
  → #OrderOfCopyfund

STRING_AGG(ParentUserName) GROUP BY RealCID → #CopyfundAgg1 (ParentUserNameList, PI/CP_ind)
  CASE on PI/CP_ind → 'PI', 'CopyPortfolio', 'Both PI and CopyPortfolio'
  → #CopyfundAgg (RealCID, ParentUserNameList, PI_CopyPortfolio_ind)

[Contact History]
BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c')
  GROUP BY CID → MAX(CreatedDate) AS LastContactedDate
  → #Contact
  [CRITICAL: INNER JOIN in final step — customers with NO Salesforce contact are EXCLUDED]

[Final Assembly]
#NetMoneyIn a
JOIN Dim_Customer dc
JOIN #Contact ct ON ct.CID = dc.RealCID          → INNER JOIN excludes never-contacted customers
JOIN Dim_Country country ON dc.CountryID          → Region
JOIN Dim_Manager dm ON dc.AccountManagerID        → Manager (FirstName + ' ' + LastName)
JOIN #CopyfundAgg cfa ON a.RealCID               → CopyfundsListing, PI_CopyPortfolio_ind
JOIN V_Liabilities vl ON a.RealCID, DateID=@YestardayDateID → Balance (Credit), RealizedEquity
CASE WHEN DATEDIFF(DAY, ct.LastContactedDate, GETDATE()) > 30 THEN 'Not Contacted' ELSE 'Contacted'
  → ContactedLastMonth

TRUNCATE TABLE BI_DB_dbo.BI_DB_Copyfunds_SignificantAllocation
INSERT INTO BI_DB_dbo.BI_DB_Copyfunds_SignificantAllocation (... UpdateDate = GETDATE())
```
