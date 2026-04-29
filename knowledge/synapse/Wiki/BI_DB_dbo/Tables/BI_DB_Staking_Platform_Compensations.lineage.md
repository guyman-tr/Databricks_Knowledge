# BI_DB_dbo.BI_DB_Staking_Platform_Compensations — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | BI_DB_dbo.External_etoro_History_Credit_Yesterday | External | Staking compensation credits (CreditTypeID=6, MoveMoneyReasonID=3, CompensationReasonID=3) | Occurred = @Date |
| 2 | BI_DB_dbo.External_etoro_Dictionary_MoveMoneyReason | External | MoveMoneyReason name lookup | MoveMoneyReasonID join |
| 3 | DWH_dbo.Dim_CompensationReason | DWH_dbo | Compensation reason name | CompensationReasonID join |
| 4 | DWH_dbo.Dim_CreditType | DWH_dbo | Credit type name | CreditTypeID join |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | CID | External_etoro_History_Credit_Yesterday | CID | Passthrough |
| 2 | CreditID | External_etoro_History_Credit_Yesterday | CreditID | Passthrough |
| 3 | CreditTypeID | External_etoro_History_Credit_Yesterday | CreditTypeID | Passthrough (always 6=Compensation) |
| 4 | CreditTypeName | Dim_CreditType | CreditTypeName | Dim-lookup passthrough |
| 5 | CreditDateTime | External_etoro_History_Credit_Yesterday | Occurred | CAST to DATETIME |
| 6 | CreditDate | External_etoro_History_Credit_Yesterday | Occurred | CAST to DATE |
| 7 | Payment | External_etoro_History_Credit_Yesterday | Payment | Passthrough |
| 8 | CompensationReasonID | External_etoro_History_Credit_Yesterday | CompensationReasonID | Passthrough (always 3=Technical Problems) |
| 9 | CompensationReason | Dim_CompensationReason | Name | Dim-lookup passthrough |
| 10 | MoveMoneyReasonID | External_etoro_History_Credit_Yesterday | MoveMoneyReasonID | Passthrough (always 3=Staking) |
| 11 | MoveMoneyReason | External_etoro_Dictionary_MoveMoneyReason | MoveMoneyReason | Passthrough |
| 12 | CreditDescription | External_etoro_History_Credit_Yesterday | Description | Passthrough (e.g., "Staking May 2025 Cash Equivalent") |
| 13 | UpdateDate | ETL | GETDATE() | Metadata |
