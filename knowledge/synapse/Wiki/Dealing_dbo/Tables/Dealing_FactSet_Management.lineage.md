# Lineage: Dealing_dbo.Dealing_FactSet_Management

## Source Tables
| Source | Role |
|--------|------|
| DWH_dbo.Fact_SnapshotCustomer | PI detection (GuruStatusID>=2 = active PI/CP) |
| DWH_dbo.Dim_Range | CopyType/tier classification |
| DWH_dbo.Dim_Customer | Customer registration date, username |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| CID | Fact_SnapshotCustomer.CID | PI/CP customer ID |
| CopyType | Dim_Range | 'PI' or 'CP' classification |
| RegistrationDate | Dim_Customer.RegistrationDate | Customer registration date |
| PI_From | Derived | First date when GuruStatusID>=2 (became PI/CP) |
| PI_To | Derived | Last date when GuruStatusID dropped to <2 (stopped being PI); NULL if still active |
| IsActive | Derived | 1 if currently GuruStatusID>=2, 0 if deregistered |
| HistorySendFlag | Manual/Operational | Flag set externally to trigger history send (1=send needed, 0=sent) |
| HistorySentDate | Updated by SP | Date when history data was last sent to FactSet |
| DailyFirstSentDate | Updated by SP | Date when daily sends first started for this CID |
| DailyLastSentDate | Updated by SP | Last date successfully sent to FactSet |
| UpdateDate | Generated | `GETDATE()` at each SP run |

## UPSERT Logic
- INSERT: New rows for CIDs whose first PI date = @Date (newly activated PIs)
- UPDATE IsActive=0 + PI_To: PIs who stopped being PI yesterday (GuruStatusID < 2 on @Date)
- DELETE: Rows where DailyFirstSentDate IS NULL AND IsActive=1 (cleanup of never-sent active rows)

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_FactSet_Management/ |
| Notes | STALE — last data 2024-06-04. Control table only — no data grain, one row per CID. |
