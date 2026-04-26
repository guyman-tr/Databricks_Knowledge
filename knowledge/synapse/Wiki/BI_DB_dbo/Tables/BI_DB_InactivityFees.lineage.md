# Lineage: BI_DB_dbo.BI_DB_InactivityFees

**Writer SP**: `SP_Inactivity_Fees`
**Scope**: Customers eligible for inactivity fees — liabilities >$20, last login >1 year ago, no open positions, valid/active, deposited
**Pattern**: TRUNCATE + INSERT (full snapshot refresh per SP run)
**UC Target**: Not Migrated

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough | Tier 1 |
| 2 | ID | DWH_dbo.Dim_Customer | ID | Passthrough | Tier 1 |
| 3 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough | Tier 1 |
| 4 | FTD_Month | DWH_dbo.Dim_Customer | FirstDepositDate | EOMONTH(FirstDepositDate) — last day of FTD month | Tier 2 |
| 5 | FTD_Date | DWH_dbo.Dim_Customer | FirstDepositDate | CAST(FirstDepositDate AS DATE) | Tier 2 |
| 6 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Dim_Customer.RegulationID | Tier 2 |
| 7 | UKunderFCA | DWH_dbo.Dim_Customer | RegulationID, CountryID | CASE WHEN RegulationID=2 AND CountryID=218 THEN 'Yes' ELSE 'No' | Tier 2 |
| 8 | AccountStatusName | DWH_dbo.Dim_AccountStatus | AccountStatusName | JOIN via Dim_Customer.AccountStatusID | Tier 2 |
| 9 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN via Dim_Customer.PlayerStatusID | Tier 2 |
| 10 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN via Dim_Customer.PlayerLevelID | Tier 2 |
| 11 | AccountType | DWH_dbo.Dim_AccountType | Name | JOIN via Dim_Customer.AccountTypeID | Tier 2 |
| 12 | Country | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID | Tier 2 |
| 13 | Language | DWH_dbo.Dim_Language | Name | JOIN via Dim_Customer.LanguageID | Tier 2 |
| 14 | LastLogin | DWH_dbo.Fact_CustomerAction | Occurred | MAX(Occurred) per RealCID WHERE ActionTypeID=14, filtered ≤ 1 year before @Date | Tier 2 |
| 15 | UpdateDate | ETL | GETDATE() | ETL run timestamp | Tier 3 |
| 16 | IsAffiliate | DWH_dbo.Dim_Affiliate | TradingAccount_RealCID | CASE WHEN IS NOT NULL THEN 1 ELSE 0 | Tier 2 |
| 17 | Liabilities | DWH_dbo.V_Liabilities | Liabilities | Passthrough; pre-filtered WHERE Liabilities > 20 at @DateID | Tier 2 |
| 18 | Credit | DWH_dbo.V_Liabilities | Credit | Passthrough at @DateID | Tier 2 |

## Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Customer | Primary customer dimension: identity, FTD dates, regulatory classification, status |
| DWH_dbo.V_Liabilities | Balance view: Liabilities + Credit at @DateID; entry filter >$20 |
| DWH_dbo.Fact_CustomerAction | Login history (ActionTypeID=14); last-login derivation + inactivity filter |
| DWH_dbo.Dim_Position | Open position exclusion filter (CloseDateID=0 = still-open positions) |
| DWH_dbo.Dim_Regulation | Regulation name lookup |
| DWH_dbo.Dim_AccountStatus | Account status label |
| DWH_dbo.Dim_PlayerStatus | Player status label |
| DWH_dbo.Dim_PlayerLevel | Club/tier label (Bronze, Silver, Gold, etc.) |
| DWH_dbo.Dim_AccountType | Account type label (Private, Corporate, etc.) |
| DWH_dbo.Dim_Country | Country name |
| DWH_dbo.Dim_Language | Language name |
| DWH_dbo.Dim_Affiliate | Affiliate membership check (DISTINCT TradingAccount_RealCID) |

## Inclusion Criteria (SP Filter Logic)

A customer is included in the inactivity fees report if ALL of:
1. `V_Liabilities.Liabilities > 20` at @DateID — has meaningful balance
2. `Fact_CustomerAction.Occurred ≤ DATEADD(DAY,1,DATEADD(year,-1,@Date))` — last login >1 year ago
3. `Dim_Position.CloseDateID <> 0` (NOT IN #OpenPositions) — no currently open positions
4. `Dim_Customer.CountryID NOT IN (38)` — not Canadian (Canada excluded; USA was removed in 2024-03-06)
5. `Dim_Customer.IsValidCustomer = 1`
6. `Dim_Customer.AccountStatusID <> 2` — account not closed
7. `Dim_Customer.PlayerStatusID NOT IN (2, 4)` — not blocked (2=Blocked Upon Request, 4=Blocked)
8. `Dim_Customer.FirstDepositDate > '1900-01-01'` — has made at least one deposit

## ETL Pipeline

```
Customer.Customer (production)
  |-- SP_Dim_Customer ---|
  v
DWH_dbo.Dim_Customer (full customer dimension)
  |
  +-- SP_Inactivity_Fees @Date --|
  |   TRUNCATE BI_DB_InactivityFees |
  |   INSERT (#finaltable)         |
  |   JOIN: V_Liabilities          |
  |   JOIN: Fact_CustomerAction    |
  |   EXCL: #OpenPositions         |
  v
BI_DB_dbo.BI_DB_InactivityFees (63.5K rows, inactivity fee candidates)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 3 | RealCID, ID, GCID |
| Tier 2 | 14 | FTD_Month, FTD_Date, Regulation, UKunderFCA, AccountStatusName, PlayerStatus, Club, AccountType, Country, Language, LastLogin, IsAffiliate, Liabilities, Credit |
| Tier 3 | 1 | UpdateDate |
