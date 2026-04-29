# Lineage: BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

**Generated:** 2026-04-21 | **Writer SP:** SP_CID_Daily_AcquisitionFunnel_VBT | **Pattern:** DELETE WHERE Date=@date + INSERT

## ETL Pipeline

```
External_ComplianceStateDB_Compliance_KycFlow (KYCFlowTypeID=2)
External_ComplianceStateDB_History_KycFlow (KYCFlowTypeID=2)
  |── #VBT_CIDs temp table (GCID of VBT-flow customers)
  |
DWH_dbo.Fact_SnapshotCustomer (sc) — daily player snapshot
  JOIN DWH_dbo.Dim_Range (dr) ON DateRangeID → date window filter
  JOIN BI_DB_dbo.BI_DB_CIDFirstDates (fd) ON CID — milestone dates
  LEFT JOIN DWH_dbo.Dim_PlayerStatus (ps) ON PlayerStatusID
  LEFT JOIN DWH_dbo.Dim_Regulation (dr1/dr2) ON RegulationID/DesignatedRegulationID
  LEFT JOIN #VBT_CIDs ON GCID
  WHERE IsValidCustomer=1, PlayerStatusID NOT IN (2,4,13)
  AND any milestone event occurred on @date
    |
    v
SP_CID_Daily_AcquisitionFunnel_VBT (@date)
    |
    v
BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT
(DELETE WHERE Date=@date + INSERT, ~44M rows)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|--------------|-----------|
| 1 | CID | Fact_SnapshotCustomer | RealCID | Passthrough (GCID→RealCID alias) |
| 2 | Date | SP parameter | @date | ETL run date passthrough |
| 3 | DateID | SP computed | @date | CONVERT(VARCHAR(8), @date, 112)::int |
| 4 | YearMonth | SP computed | @date | YEAR(@date)*100+MONTH(@date) |
| 5 | Desk | BI_DB_CIDFirstDates | PotentialDesk | Passthrough (fd.PotentialDesk) |
| 6 | Region | BI_DB_CIDFirstDates | Region | Passthrough |
| 7 | Country | BI_DB_CIDFirstDates | Country | Passthrough |
| 8 | Channel | BI_DB_CIDFirstDates | Channel | Passthrough |
| 9 | SubChannel | BI_DB_CIDFirstDates | SubChannel | Passthrough |
| 10 | Regulation | Dim_Regulation (dr1) | Name | Resolved via sc.RegulationID=dr1.DWHRegulationID |
| 11 | DesignatedRegulation | Dim_Regulation (dr2) | Name | Resolved via sc.DesignatedRegulationID=dr2.DWHRegulationID |
| 12 | Reg_Date | BI_DB_CIDFirstDates | registered | CAST(fd.registered AS DATE) |
| 13 | Registration | BI_DB_CIDFirstDates | registered | CASE WHEN CAST(fd.registered AS date)=@date THEN 1 ELSE 0 |
| 14 | V2_Date | BI_DB_CIDFirstDates | VerificationLevel2Date | CAST(fd.VerificationLevel2Date AS DATE) |
| 15 | V2 | BI_DB_CIDFirstDates | VerificationLevel2Date | CASE WHEN CAST(fd.VerificationLevel2Date AS date)=@date THEN 1 ELSE 0 |
| 16 | V3_Date | BI_DB_CIDFirstDates | VerificationLevel3Date | CAST(fd.VerificationLevel3Date AS DATE) |
| 17 | V3 | BI_DB_CIDFirstDates | VerificationLevel3Date | CASE WHEN CAST(fd.VerificationLevel3Date AS date)=@date THEN 1 ELSE 0 |
| 18 | FTD_Date | BI_DB_CIDFirstDates | FirstDepositDate | CAST(fd.FirstDepositDate AS date) |
| 19 | FTD | BI_DB_CIDFirstDates | FirstDepositDate | CASE WHEN CAST(fd.FirstDepositDate AS date)=@date THEN 1 ELSE 0 |
| 20 | FTDA | BI_DB_CIDFirstDates | FirstDepositAmount | Passthrough (fd.FirstDepositAmount) |
| 21 | FirstPosOpen_Date | BI_DB_CIDFirstDates | FirstPosOpenDate | CAST(fd.FirstPosOpenDate AS date) |
| 22 | FirstPosOpen | BI_DB_CIDFirstDates | FirstPosOpenDate | CASE WHEN CAST(fd.FirstPosOpenDate AS date)=@date THEN 1 ELSE 0 |
| 23 | IsVBT | External_ComplianceStateDB | GCID (KYCFlowTypeID=2) | CASE WHEN vbt.GCID IS NULL THEN 0 ELSE 1 |
| 24 | PlayerStatusID | Fact_SnapshotCustomer | PlayerStatusID | Passthrough |
| 25 | PlayerStatus | Dim_PlayerStatus | Name | Resolved via sc.PlayerStatusID |
| 26 | UpdateDate | SP metadata | GETDATE() | ETL run timestamp |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| Fact_SnapshotCustomer | DWH_dbo | Primary source — daily customer snapshot (RealCID, PlayerStatusID, Reg/Desig regulationIDs) |
| BI_DB_CIDFirstDates | BI_DB_dbo | Milestone dates source (registered, VerificationLevel2/3Date, FirstDepositDate/Amount, FirstPosOpenDate, Desk/Region/Country/Channel) |
| Dim_Range | DWH_dbo | Date-range dimension for snapshot date-window filter |
| Dim_Regulation | DWH_dbo | Regulation name resolver (queried twice: RegulationID, DesignatedRegulationID) |
| Dim_PlayerStatus | DWH_dbo | Player status name resolver |
| External_ComplianceStateDB_Compliance_KycFlow | BI_DB_dbo | VBT KYC flow customers (KYCFlowTypeID=2) |
| External_ComplianceStateDB_History_KycFlow | BI_DB_dbo | VBT KYC flow history (KYCFlowTypeID=2) |

## Tier Assignment Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream production wiki available for this lineage chain) |
| Tier 2 | 26 | All columns — SP-computed or passthrough from BI_DB_CIDFirstDates (itself Tier 2) |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## UC External Lineage

UC Target: `_Not_Migrated`
