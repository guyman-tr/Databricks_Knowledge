# Lineage: BI_DB_dbo.BI_DB_InvestorsDetail

**Writer SP**: `SP_InvestorReportDetails`
**Scope**: Manual and Copy trading activity per customer per day; linked to account manager contact history
**Pattern**: DELETE WHERE DateID=@EndddINT + INSERT (date-keyed incremental)
**UC Target**: Not Migrated

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | Date | DWH_dbo.Fact_CustomerAction | Occurred | CAST(Occurred AS DATE) — trade/copy event date | Tier 2 |
| 2 | DateID | DWH_dbo.Fact_CustomerAction | DateID | Passthrough — INT date key (YYYYMMDD) | Tier 2 |
| 3 | RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough — customer performing the action | Tier 1 |
| 4 | InstrumentType | DWH_dbo.Dim_Instrument (Manual) / DWH_dbo.Dim_MirrorType (Copy) | InstrumentType / MirrorTypeName | Manual: Dim_Instrument.InstrumentType. Copy: CASE WHEN MirrorTypeID IN(1,2) THEN 'Copy Trading' WHEN MirrorTypeID=4 THEN 'Copy Portfolio' ELSE MirrorTypeName | Tier 2 |
| 5 | ParentUserName | DWH_dbo.Dim_Instrument (Manual) / DWH_dbo.Dim_Mirror (Copy) | InstrumentDisplayName / ParentUserName | **DUAL SOURCE**: Manual rows = Dim_Instrument.InstrumentDisplayName (instrument name); Copy rows = Dim_Mirror.ParentUserName (Popular Investor username) | Tier 2 |
| 6 | ActionType | ETL constant | — | Hardcoded: 'Manual' for manual trade pipeline; 'Copy' for copy investment pipeline | Tier 2 |
| 7 | AssetType | DWH_dbo.Fact_CustomerAction / Dim_Instrument | Leverage / InstrumentTypeID | Manual: CASE WHEN InstrumentTypeID IN(4,5,6) AND Leverage<3 THEN 'Investment' ELSE 'Trade'. Copy: always 'Investment' | Tier 2 |
| 8 | MoneyOut | DWH_dbo.Fact_CustomerAction | Amount | SUM WHERE ActionTypeID=4 (Manual close) or ActionTypeID IN(16,18) (Copy stop/clear). Zero if no qualifying action on Date. | Tier 2 |
| 9 | MoneyIn | DWH_dbo.Fact_CustomerAction | Amount | SUM(-1 × Amount) WHERE ActionTypeID=1 (Manual open) or ActionTypeID IN(15,17) (Copy start/add). -1 applied because Amount is negative on debit events. | Tier 2 |
| 10 | DaysContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | MIN(DATEDIFF(DAY, ContactedDate, fca.Occurred)) per (CID, ManagerID) across any contact type (Phone or Email) in last 90 days | Tier 2 |
| 11 | AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough via Fact_SnapshotCustomer at @date | Tier 2 |
| 12 | CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Passthrough via Fact_SnapshotCustomer at @date (int FK, not label) | Tier 2 |
| 13 | UpdateDate | ETL | GETDATE() | ETL run timestamp | Tier 3 |
| 14 | DaysContactedPhone | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | Same as DaysContacted but filtered to ActionName='Phone_Call_Succeed__c' only | Tier 2 |
| 15 | IsDepositor | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | Passthrough via Fact_SnapshotCustomer at @date | Tier 2 |
| 16 | Club | DWH_dbo.Dim_PlayerLevel / V_Liabilities | Name / ActualNWA+Liabilities | CASE WHEN PlayerLevelID=1 AND (ActualNWA+Liabilities)<1000 THEN 'Low Bronze' WHEN PlayerLevelID=1 THEN 'High Bronze' ELSE Dim_PlayerLevel.Name — sub-divides Bronze tier by portfolio value | Tier 2 |

## Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Fact_CustomerAction | Primary event source: manual trades (ActionTypeID 1,4) and copy actions (ActionTypeID 15,16,17,18) |
| DWH_dbo.Dim_Instrument | Instrument metadata for manual trades (InstrumentType, InstrumentDisplayName, InstrumentTypeID) |
| DWH_dbo.Dim_Mirror | Copy relationship (PopularInvestor ParentUserName, MirrorID→MirrorTypeID) |
| DWH_dbo.Dim_MirrorType | Copy type label (Copy Trading vs Copy Portfolio) |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot at @date: AccountManagerID, CountryID, IsDepositor, IsValidCustomer, PlayerLevelID |
| DWH_dbo.Dim_Range | Snapshot date range join for Fact_SnapshotCustomer |
| DWH_dbo.Dim_Manager | Account manager validation (join to verify AccountManagerID) |
| DWH_dbo.Dim_PlayerLevel | Club/VIP tier label |
| DWH_dbo.V_Liabilities | Portfolio value (ActualNWA + Liabilities) for Bronze sub-tier splitting |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Salesforce contact history for DaysContacted / DaysContactedPhone |

## Action Type Mapping

| ActionTypeID | Meaning | Pipeline | Column Impact |
|---|---------|---------|------|
| 1 | Manual position open | Manual | MoneyIn += (-1 × Amount) |
| 4 | Manual position close | Manual | MoneyOut += Amount |
| 15 | Copy invest start | Copy | MoneyIn += (-1 × Amount) |
| 16 | Copy invest stop | Copy | MoneyOut += Amount |
| 17 | Copy add funds | Copy | MoneyIn += (-1 × Amount) |
| 18 | Copy clear | Copy | MoneyOut += Amount |

## ETL Pipeline

```
Fact_CustomerAction (ActionTypeID 1,4)        → #fca → #Trade (Manual)
Fact_CustomerAction (ActionTypeID 15,16,17,18) → #fca_copy → #CopyInvestment (Copy)
BI_DB_UsageTracking_SF (last 90 days)         → #contacted (contact history)

                    UNION
                      ↓
               #union → #final
                      ↓
DELETE WHERE DateID=@EndddINT
INSERT INTO BI_DB_dbo.BI_DB_InvestorsDetail (898M rows, May 2021–Apr 2026)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 1 | RealCID |
| Tier 2 | 14 | Date, DateID, InstrumentType, ParentUserName, ActionType, AssetType, MoneyOut, MoneyIn, DaysContacted, AccountManagerID, CountryID, DaysContactedPhone, IsDepositor, Club |
| Tier 3 | 1 | UpdateDate |
