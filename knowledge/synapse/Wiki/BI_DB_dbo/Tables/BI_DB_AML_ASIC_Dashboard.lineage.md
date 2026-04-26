# Lineage: BI_DB_dbo.BI_DB_AML_ASIC_Dashboard

**Writer SP**: SP_AML_ASIC_Dashboard  
**Load Pattern**: TRUNCATE TABLE + INSERT (full refresh, no date parameter)  
**Frequency**: Daily  

---

## Source Tables

| Source | Role | Columns Used |
|--------|------|--------------|
| `DWH_dbo.Dim_Customer` | Customer master | RealCID, RegulationID, CountryID, PlayerStatusID, PlayerLevelID, RegisteredReal, FirstDepositDate, FirstDepositAmount, VerificationLevelID, HasWallet |
| `DWH_dbo.Dim_Regulation` | Regulation label + population filter | DWHRegulationID (filter: IN (4,10)), Name |
| `DWH_dbo.Dim_Country` | Country name | DWHCountryID, Name |
| `DWH_dbo.Dim_PlayerStatus` | Account status label + filter | PlayerStatusID (filter: NOT IN (2,4)), Name |
| `DWH_dbo.Dim_PlayerLevel` | Club/loyalty tier label | PlayerLevelID, Name |
| `BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake` | Risk score filter | CID, RiskScoreName (filter: = 'High') |
| `DWH_dbo.V_Liabilities` | Customer equity | CID, Liabilities, ActualNWA, DateID (= yesterday) |
| `DWH_dbo.Fact_CustomerAction` | Total deposit amount | RealCID, Amount, ActionTypeID (= 7, Deposits) |
| `DWH_dbo.Fact_SnapshotCustomer` | Regulation change history | RealCID, RegulationID, DateRangeID |
| `DWH_dbo.Dim_Range` | Date range for regulation changes | DateRangeID, FromDateID |
| `BI_DB_dbo.BI_DB_SF_Cases_Panel` | Open AML Salesforce cases | CID_Last, ActionType_AtOpen, TicketStatus |

---

## Population Filters

```
Dim_Customer:       IsValidCustomer = 1, IsDepositor = 1, VerificationLevelID >= 2
Dim_Regulation:     DWHRegulationID IN (4, 10)  -- ASIC, ASIC & GAML only
Dim_PlayerStatus:   PlayerStatusID NOT IN (2, 4)  -- excludes Blocked, Blocked Upon Request
External_RiskClass: RiskScoreName = 'High'  -- high-risk AML customers only
```

---

## Column-Level Lineage

| Column | Source | Derivation |
|--------|--------|------------|
| CID | Dim_Customer.RealCID | Alias |
| Regulation | Dim_Regulation.Name | JOIN on DWHRegulationID = RegulationID |
| KYC_Country | Dim_Country.Name | JOIN on DWHCountryID = CountryID |
| PlayerStatus | Dim_PlayerStatus.Name | JOIN on PlayerStatusID |
| Club | Dim_PlayerLevel.Name | JOIN on PlayerLevelID |
| RegisteredReal | Dim_Customer.RegisteredReal | Passthrough |
| FirstDepositDate | Dim_Customer.FirstDepositDate | Passthrough |
| FirstDepositAmount | Dim_Customer.FirstDepositAmount | Passthrough |
| VerificationLevelID | Dim_Customer.VerificationLevelID | Passthrough |
| HasWallet | Dim_Customer.HasWallet | Passthrough |
| RiskScoreName | External_RiskClassification.RiskScoreName | JOIN filter — always 'High' |
| Total_Deposits | Fact_CustomerAction.Amount | SUM where ActionTypeID=7 (Deposits); ISNULL → 0 |
| Equity | V_Liabilities.Liabilities + ActualNWA | Yesterday DateID; ISNULL → 0 |
| Has_Changed_Regulation | Computed | MAX(CASE WHEN status03.Change_Date IS NOT NULL THEN 1 ELSE 0 END) |
| Last_Regulation_Change_Date | Fact_SnapshotCustomer via Dim_Range.FromDateID | Most recent change date (rn=1 DESC); NULL if none |
| Pre_Regulation_Change | Dim_Regulation.Name | Previous regulation before ASIC change; NULL if none |
| Has_Open_AML_Case | Computed | MAX(CASE WHEN amlSF.CID IS NOT NULL THEN 1 ELSE 0 END) |
| UpdateDate | GETDATE() | ETL timestamp |

---

## Regulation Change Logic (3-Step Pipeline)

```
Step 1: #status01  ← Fact_SnapshotCustomer + Dim_Range + Dim_Regulation
         Uses LAG to identify RegulationID transitions (rows where RegulationID ≠ Previous_RegulationID)

Step 2: #status02  ← #status01
         Computes DaysBetweenChanges using LAG on Change_Date

Step 3: #status03  ← #status02 (rn=1 by Change_Date DESC)
         Filters to: Curr_Regulation IN ('ASIC','ASIC & GAML')
                 AND Previous_Regulation NOT IN ('BVI','None','ASIC','ASIC & GAML')
         Keeps only the most recent qualifying change per customer
```
