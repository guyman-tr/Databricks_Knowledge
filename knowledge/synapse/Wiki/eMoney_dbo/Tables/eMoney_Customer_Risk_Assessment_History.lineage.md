# eMoney_dbo.eMoney_Customer_Risk_Assessment_History — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Database** | Same sources as eMoney_Customer_Risk_Assessment (see CRA lineage for full source list) |
| **Population Source** | eMoney_Customer_Risk_Assessment (intermediate #final temp table in SP) |
| **ETL SP** | SP_eMoney_Customer_Risk_Assessment (Step 32 only — INSERT, no TRUNCATE) |
| **Insert Trigger** | Class-change only: WHERE trg.CID IS NULL OR src.ClientRisk <> trg.ClientRisk |
| **Upstream Wiki** | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md (Tier 1 source for 5 columns) |
| **UC Target** | _Not_Migrated |

## ETL Pipeline Summary

```
Steps 01-29: Identical to eMoney_Customer_Risk_Assessment — see CRA lineage file for full detail.
             These steps build #final with all 120 columns and apply override logic.

Step 30: TRUNCATE TABLE eMoney_Customer_Risk_Assessment (snapshot only — History NOT touched)

Step 31: INSERT INTO eMoney_Customer_Risk_Assessment FROM #final (snapshot rebuild)

Step 32: INSERT INTO eMoney_Customer_Risk_Assessment_History FROM #final src
         LEFT JOIN #eMoney_Customer_Risk_Assessment_History trg ON src.CID = trg.CID
         WHERE trg.CID IS NULL                          -- new customer (first history row)
            OR (src.ClientRisk <> trg.ClientRisk)       -- class changed from last history row

         Note: trg is read at Step 27 (latest row per CID, ROW_NUMBER DESC) BEFORE Step 30-31.
               This means the History comparison uses yesterday's final classification, not today's CRA state.

Change History:
  2025-02-25 Ofir Ovadia: Changed WHERE to (src.Risk_Final_Result <> trg.Risk_Final_Result) — score-change trigger
  2025-03-12 Ofir Ovadia: Reverted to class-change trigger (src.ClientRisk <> trg.ClientRisk)
             Reason: score-change produced large daily volumes; RnD requested rollback.
```

## Column Lineage

*Identical to eMoney_Customer_Risk_Assessment (same 120 columns, same SP, same transformations). See CRA lineage for full per-column mapping. The only operational difference is the insert condition (class-change filter at Step 32).*

| # | DWH Column | Source Table | Source Column | Transform |
|---|-----------|-------------|---------------|-----------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename: RealCID→CID |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| 3 | ClientRiskDate | eMoney_Customer_Risk_Assessment_History (prior rows) | ClientRiskDate | Preserved if class unchanged; @Date if class changed |
| 4 | ClientRisk | Fivetran classification table | RiskText thresholds | CASE on Risk_Final_Result; overridden by PEP/Manual |
| 5 | ClientRiskAssignmentType | Computed | — | 'Regular' / 'PEP Override' / 'Manual Override' |
| 6 | Risk_Final_Result | Fivetran classification table | RiskID × ParameterWeight | SUM(P1_RiskID×P1_Weight + … + P32_RiskID×P32_Weight) |
| 7 | PreviousClientRisk | eMoney_Customer_Risk_Assessment_History (prior rows) | ClientRisk | Latest history row before today's run; ISNULL→'None' |
| 8 | PreviousClientRiskDate | eMoney_Customer_Risk_Assessment_History (prior rows) | ClientRiskDate | Latest history row before today's run |
| 9–120 | All remaining columns | Same as eMoney_Customer_Risk_Assessment | Same transforms | See CRA lineage rows 9-120 |
