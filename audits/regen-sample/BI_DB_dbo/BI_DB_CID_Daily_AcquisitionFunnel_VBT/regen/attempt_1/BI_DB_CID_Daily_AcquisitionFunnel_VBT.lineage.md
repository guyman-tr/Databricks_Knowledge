# Lineage — BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT

## Source Objects

| # | Source Object | Schema | Type | Relationship | Wiki |
|---|--------------|--------|------|-------------|------|
| 1 | Fact_SnapshotCustomer | DWH_dbo | Table | Primary customer state (SCD2 snapshot) | [Fact_SnapshotCustomer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md) |
| 2 | Dim_Range | DWH_dbo | Table | Date range decode for SCD2 filter | [Dim_Range.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md) |
| 3 | BI_DB_CIDFirstDates | BI_DB_dbo | Table | Customer milestone dates and resolved dimension names | [BI_DB_CIDFirstDates.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CIDFirstDates.md) |
| 4 | Dim_PlayerStatus | DWH_dbo | Table | Player status name resolution | [Dim_PlayerStatus.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.md) |
| 5 | Dim_Regulation | DWH_dbo | Table | Regulation name resolution (×2 joins) | [Dim_Regulation.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md) |
| 6 | External_ComplianceStateDB_Compliance_KycFlow | BI_DB_dbo | External Table | VBT KYC flow detection (KYCFlowTypeID=2) | — |
| 7 | External_ComplianceStateDB_History_KycFlow | BI_DB_dbo | External Table | VBT KYC flow history (KYCFlowTypeID=2) | — |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Rename (RealCID → CID) | Tier 1 — Fact_SnapshotCustomer |
| 2 | Date | ETL-computed | @date parameter | SP input parameter, the run date | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 3 | DateID | ETL-computed | @date parameter | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 4 | YearMonth | ETL-computed | @date parameter | YEAR(@date) * 100 + MONTH(@date) | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 5 | Desk | BI_DB_dbo.BI_DB_CIDFirstDates | PotentialDesk | Rename (PotentialDesk → Desk) | Tier 1 — BI_DB_CIDFirstDates |
| 6 | Region | BI_DB_dbo.BI_DB_CIDFirstDates | Region | Passthrough | Tier 1 — BI_DB_CIDFirstDates |
| 7 | Country | BI_DB_dbo.BI_DB_CIDFirstDates | Country | Passthrough | Tier 1 — BI_DB_CIDFirstDates |
| 8 | Channel | BI_DB_dbo.BI_DB_CIDFirstDates | Channel | Passthrough | Tier 1 — BI_DB_CIDFirstDates |
| 9 | SubChannel | BI_DB_dbo.BI_DB_CIDFirstDates | SubChannel | Passthrough | Tier 1 — BI_DB_CIDFirstDates |
| 10 | Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via sc.RegulationID = dr1.DWHRegulationID | Tier 1 — Dictionary.Regulation |
| 11 | DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via sc.DesignatedRegulationID = dr2.DWHRegulationID | Tier 1 — Dictionary.Regulation |
| 12 | Reg_Date | BI_DB_dbo.BI_DB_CIDFirstDates | registered | CAST(fd.registered AS DATE) — type narrowing only | Tier 1 — BI_DB_CIDFirstDates |
| 13 | Registration | ETL-computed | fd.registered + @date | CASE WHEN CAST(fd.registered AS date) = @date THEN 1 ELSE 0 END | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 14 | V2_Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel2Date | CAST(fd.VerificationLevel2Date AS DATE) — type narrowing only | Tier 1 — BI_DB_CIDFirstDates |
| 15 | V2 | ETL-computed | fd.VerificationLevel2Date + @date | CASE WHEN CAST(fd.VerificationLevel2Date AS date) = @date THEN 1 ELSE 0 END | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 16 | V3_Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | CAST(fd.VerificationLevel3Date AS DATE) — type narrowing only | Tier 1 — BI_DB_CIDFirstDates |
| 17 | V3 | ETL-computed | fd.VerificationLevel3Date + @date | CASE WHEN CAST(fd.VerificationLevel3Date AS date) = @date THEN 1 ELSE 0 END | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 18 | FTD_Date | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | CAST(fd.FirstDepositDate AS DATE) — type narrowing only | Tier 1 — BI_DB_CIDFirstDates |
| 19 | FTD | ETL-computed | fd.FirstDepositDate + @date | CASE WHEN CAST(fd.FirstDepositDate AS date) = @date THEN 1 ELSE 0 END | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 20 | FTDA | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositAmount | Passthrough (renamed FirstDepositAmount → FTDA) | Tier 1 — BI_DB_CIDFirstDates |
| 21 | FirstPosOpen_Date | BI_DB_dbo.BI_DB_CIDFirstDates | FirstPosOpenDate | CAST(fd.FirstPosOpenDate AS DATE) — type narrowing only | Tier 1 — BI_DB_CIDFirstDates |
| 22 | FirstPosOpen | ETL-computed | fd.FirstPosOpenDate + @date | CASE WHEN CAST(fd.FirstPosOpenDate AS date) = @date THEN 1 ELSE 0 END | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 23 | IsVBT | ETL-computed | #VBT_CIDs.GCID + sc.GCID | CASE WHEN vbt.GCID IS NULL THEN 0 ELSE 1 END — VBT flag from ComplianceStateDB KycFlow (KYCFlowTypeID=2) | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |
| 24 | PlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | Passthrough | Tier 1 — Fact_SnapshotCustomer |
| 25 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Dim-lookup via sc.PlayerStatusID = ps.PlayerStatusID | Tier 1 — Dictionary.PlayerStatus |
| 26 | UpdateDate | ETL-computed | — | GETDATE() at ETL execution | Tier 2 — SP_CID_Daily_AcquisitionFunnel_VBT |

---

*Generated: 2026-04-28 | Object: BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT*
