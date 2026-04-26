# Lineage: BI_DB_dbo.BI_DB_AssignmentToolBacklog

**Generated**: 2026-04-23
**Writer SP**: `SP_AssignmentToolBacklog`
**Load Pattern**: TRUNCATE + INSERT (daily full refresh — active tasks only)
**UC Target**: `_Not_Migrated`

## ETL Pipeline

```
Assignment.Assignment.V_Tasks (Bronze lake, filtered: IsActive=1)
  └── External_Assignment_Assignment_V_Tasks
        |
Assignment.Assignment.ManagerTeam (current) ──┐
  └── External_Assignment_Assignment_ManagerTeam  |
                                                  ├── combined + deduped → latest TeamID per ManagerID
Assignment.History.ManagerTeam (historical) ───┘
  └── External_Assignment_History_ManagerTeam
        |
Assignment.Assignment.Teams
  └── External_Assignment_Assignment_Teams
        |
ComplianceStateDB.History.KycFlow ──────┐
  └── External_ComplianceStateDB_History_KycFlow   |
                                                    ├── KYCFlowTypeID 1,2,3 → via BI_DB_Operations_Monthly_KPIs_Verifications
ComplianceStateDB.Compliance.KycFlow ───┘
  └── External_ComplianceStateDB_Compliance_KycFlow
        |
ComplianceStateDB.Dictionary.KYCFlowType
  └── External_ComplianceStateDB_Dictionary_KYCFlowType
        |
DWH_dbo.Dim_Customer (IsValidCustomer=1) → DWH_dbo.Dim_Regulation (via DesignatedRegulationID)
                                         → DWH_dbo.Dim_Country    (via CountryID)
        |
BI_DB_dbo.BI_DB_AllDeposits (LEFT JOIN, IsFTD=1 check)
        |
        v
SP_AssignmentToolBacklog [TRUNCATE + INSERT]
        |
        v
BI_DB_dbo.BI_DB_AssignmentToolBacklog (27,060 rows — active task snapshot)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | ID | ETL pipeline | — | IDENTITY — auto-incremented at INSERT; not in INSERT list | Propagation |
| 2 | AssigneeID | Assignment.Assignment.V_Tasks | AssigneeID | passthrough | Tier 2 |
| 3 | CreateDate | Assignment.Assignment.V_Tasks | CreateDate | passthrough | Tier 2 |
| 4 | GCID | Assignment.Assignment.V_Tasks | GCID | passthrough | Tier 2 |
| 5 | CID | Assignment.Assignment.V_Tasks | CID | passthrough | Tier 2 |
| 6 | Depositors | BI_DB_dbo.BI_DB_AllDeposits | IsFTD | computed: CASE WHEN IsFTD IS NOT NULL THEN 'Depositors' ELSE 'Non-depositors' END (LEFT JOIN on CID where IsFTD=1) | Tier 2 |
| 7 | DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | passthrough via Dim_Customer.DesignatedRegulationID | Tier 2 |
| 8 | IsActive | Assignment.Assignment.V_Tasks | IsActive | passthrough (all rows filtered to IsActive=1) | Tier 2 |
| 9 | Priority | Assignment.Assignment.V_Tasks | Priority | passthrough | Tier 2 |
| 10 | TeamID | Assignment.Assignment.V_Tasks | TeamID | passthrough | Tier 2 |
| 11 | TaskID | Assignment.Assignment.V_Tasks | TaskID | passthrough | Tier 2 |
| 12 | Country | DWH_dbo.Dim_Country | Name | passthrough via Dim_Customer.CountryID | Tier 2 |
| 13 | RiskGroupID | DWH_dbo.Dim_Country | RiskGroupID | passthrough via Dim_Customer.CountryID | Tier 2 |
| 14 | Teams | Assignment.Assignment.Teams | Name | computed: CASE WHEN AssigneeID IS NULL THEN 'Unassigned' ELSE teams1.Name END; team resolved via ManagerTeam union (current + historical, latest per ManagerID) | Tier 2 |
| 15 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough | Tier 2 |
| 16 | kycFlow | ComplianceStateDB.Dictionary.KYCFlowType | Name | computed: CASE WHEN RiskGroupID IN (1,2) THEN 'Rank 1 or 2' WHEN kyc.Name IS NULL THEN 'Normal' ELSE kyc.Name END; KycFlow sourced from History + Compliance union (KYCFlowTypeID 1,2,3) via BI_DB_Operations_Monthly_KPIs_Verifications | Tier 2 |
| 17 | UpdateDate | ETL pipeline | — | GETDATE() at INSERT time | Propagation |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| Assignment.Assignment.V_Tasks | External Table | Primary — active assignment tasks (IsActive=1) |
| Assignment.Assignment.ManagerTeam | External Table | Current manager-to-team mapping |
| Assignment.History.ManagerTeam | External Table | Historical manager-to-team mapping (unioned with current for full coverage) |
| Assignment.Assignment.Teams | External Table | Lookup — maps TeamID to team Name |
| ComplianceStateDB.History.KycFlow | External Table | KYC flow history per GCID |
| ComplianceStateDB.Compliance.KycFlow | External Table | Current KYC flow state per GCID |
| ComplianceStateDB.Dictionary.KYCFlowType | External Table | Lookup — maps KYCFlowTypeID to flow type Name |
| DWH_dbo.Dim_Customer | Table | Dimension — maps CID to regulation, country, verification level |
| DWH_dbo.Dim_Regulation | Table | Dimension — maps DesignatedRegulationID to regulation Name |
| DWH_dbo.Dim_Country | Table | Dimension — maps CountryID to country Name and RiskGroupID |
| BI_DB_dbo.BI_DB_AllDeposits | Table | First-time depositor flag (IsFTD=1 check for Depositors classification) |
| BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications | Table | Bridge — resolves GCID to RealCID for KycFlow join |

## Notes

- `SP_AssignmentToolBacklog` was created 2022-06-10 to replace a custom Tableau query for the "Assignment tool – docs backlog analysis" report
- The table always contains the current active-task snapshot (all rows have IsActive=1); historical task data is not retained
- Manager-team resolution combines Assignment.Assignment.ManagerTeam and Assignment.History.ManagerTeam using ROW_NUMBER() OVER (PARTITION BY ManagerID ORDER BY BeginTime DESC) to get the most recent team per manager
- KycFlow resolution: KYCFlowTypeID 1, 2, 3 from both History and Compliance schemas; RiskGroupID 1–2 overrides the KYC name with 'Rank 1 or 2'
- No upstream wiki available for Assignment or ComplianceStateDB databases
