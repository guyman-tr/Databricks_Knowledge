# Column Lineage: main.bi_output.finance_tables_functions_revenue_sdrt

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.finance_tables_functions_revenue_sdrt` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\finance_tables_functions_revenue_sdrt.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\finance_tables_functions_revenue_sdrt.json` (rows: 45, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
        │
        ▼
main.bi_output.finance_tables_functions_revenue_sdrt   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `—` | `RealCID` | `passthrough` | — | f.RealCID |
| 2 | `Occurred` | `—` | `Occurred` | `passthrough` | — | f.Occurred |
| 3 | `DateID` | `—` | `DateID` | `passthrough` | — | f.DateID |
| 4 | `GCID` | `—` | `GCID` | `passthrough` | — | f.GCID |
| 5 | `CountryID` | `—` | `CountryID` | `passthrough` | — | f.CountryID |
| 6 | `LabelID` | `—` | `LabelID` | `passthrough` | — | f.LabelID |
| 7 | `LanguageID` | `—` | `LanguageID` | `passthrough` | — | f.LanguageID |
| 8 | `VerificationLevelID` | `—` | `VerificationLevelID` | `passthrough` | — | f.VerificationLevelID |
| 9 | `DocsOK` | `—` | `DocsOK` | `passthrough` | — | f.DocsOK |
| 10 | `PlayerStatusID` | `—` | `PlayerStatusID` | `passthrough` | — | f.PlayerStatusID |
| 11 | `Bankruptcy` | `—` | `Bankruptcy` | `passthrough` | — | f.Bankruptcy |
| 12 | `RiskStatusID` | `—` | `RiskStatusID` | `passthrough` | — | f.RiskStatusID |
| 13 | `RiskClassificationID` | `—` | `RiskClassificationID` | `passthrough` | — | f.RiskClassificationID |
| 14 | `CommunicationLanguageID` | `—` | `CommunicationLanguageID` | `passthrough` | — | f.CommunicationLanguageID |
| 15 | `PremiumAccount` | `—` | `PremiumAccount` | `passthrough` | — | f.PremiumAccount |
| 16 | `Evangelist` | `—` | `Evangelist` | `passthrough` | — | f.Evangelist |
| 17 | `GuruStatusID` | `—` | `GuruStatusID` | `passthrough` | — | f.GuruStatusID |
| 18 | `RegulationID` | `—` | `RegulationID` | `passthrough` | — | f.RegulationID |
| 19 | `AccountStatusID` | `—` | `AccountStatusID` | `passthrough` | — | f.AccountStatusID |
| 20 | `AccountManagerID` | `—` | `AccountManagerID` | `passthrough` | — | f.AccountManagerID |
| 21 | `PlayerLevelID` | `—` | `PlayerLevelID` | `passthrough` | — | f.PlayerLevelID |
| 22 | `AccountTypeID` | `—` | `AccountTypeID` | `passthrough` | — | f.AccountTypeID |
| 23 | `DateRangeID` | `—` | `DateRangeID` | `passthrough` | — | f.DateRangeID |
| 24 | `IsDepositor` | `—` | `IsDepositor` | `passthrough` | — | f.IsDepositor |
| 25 | `PendingClosureStatusID` | `—` | `PendingClosureStatusID` | `passthrough` | — | f.PendingClosureStatusID |
| 26 | `DocumentStatusID` | `—` | `DocumentStatusID` | `passthrough` | — | f.DocumentStatusID |
| 27 | `SuitabilityTestStatusID` | `—` | `SuitabilityTestStatusID` | `passthrough` | — | f.SuitabilityTestStatusID |
| 28 | `MifidCategorizationID` | `—` | `MifidCategorizationID` | `passthrough` | — | f.MifidCategorizationID |
| 29 | `IsEmailVerified` | `—` | `IsEmailVerified` | `passthrough` | — | f.IsEmailVerified |
| 30 | `IsValidCustomer` | `—` | `IsValidCustomer` | `passthrough` | — | f.IsValidCustomer |
| 31 | `DesignatedRegulationID` | `—` | `DesignatedRegulationID` | `passthrough` | — | f.DesignatedRegulationID |
| 32 | `EvMatchStatus` | `—` | `EvMatchStatus` | `passthrough` | — | f.EvMatchStatus |
| 33 | `RegionID` | `—` | `RegionID` | `passthrough` | — | f.RegionID |
| 34 | `PlayerStatusReasonID` | `—` | `PlayerStatusReasonID` | `passthrough` | — | f.PlayerStatusReasonID |
| 35 | `IsCreditReportValidCB` | `—` | `IsCreditReportValidCB` | `passthrough` | — | f.IsCreditReportValidCB |
| 36 | `AffiliateID` | `—` | `AffiliateID` | `passthrough` | — | f.AffiliateID |
| 37 | `Email` | `—` | `Email` | `passthrough` | — | f.Email |
| 38 | `City` | `—` | `City` | `passthrough` | — | f.City |
| 39 | `Address` | `—` | `Address` | `passthrough` | — | f.Address |
| 40 | `Zip` | `—` | `Zip` | `passthrough` | — | f.Zip |
| 41 | `PhoneNumber` | `—` | `PhoneNumber` | `passthrough` | — | f.PhoneNumber |
| 42 | `IsPhoneVerified` | `—` | `IsPhoneVerified` | `passthrough` | — | f.IsPhoneVerified |
| 43 | `PhoneVerificationDateID` | `—` | `PhoneVerificationDateID` | `passthrough` | — | f.PhoneVerificationDateID |
| 44 | `PlayerStatusSubReasonID` | `—` | `PlayerStatusSubReasonID` | `passthrough` | — | f.PlayerStatusSubReasonID |
| 45 | `SDRT` | `—` | `—` | `arithmetic` | — | -1 * f.Amount AS SDRT |

## Cross-check vs system.access.column_lineage

- Total target columns: **45**
- OK: **45**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **1**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fca.RealCID = fsc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID
