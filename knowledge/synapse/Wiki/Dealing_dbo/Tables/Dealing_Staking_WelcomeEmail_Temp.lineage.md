# Column Lineage: Dealing_dbo.Dealing_Staking_WelcomeEmail_Temp

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_Staking_WelcomeEmail

## Pipeline Summary

```
DWH_dbo.Dim_Customer          ─┐
DWH_dbo.Dim_Position          ─┤─► SP_Staking_WelcomeEmail ──► Dealing_Staking_WelcomeEmail_Temp
DWH_dbo.Fact_SnapshotCustomer ─┤                              (TRUNCATE + INSERT, Sun/Wed only)
Dealing_Staking_Parameters    ─┘
                                                    │
                                                    └──► EXE_dbo.EXE_Staking_AirDrop_sent_email
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| GCID | DWH_dbo.Dim_Customer | GCID | Direct passthrough — customers with new staking positions in last 7 days |

## Key Filters Applied in SP

| Filter | Value | Source |
|--------|-------|--------|
| Run day | DayNumberOfWeek_Sun_Start IN (3, 7) | Internal date check |
| Country exclusion | Exclude US, Tangany-regulated, None-regulation | DWH_dbo.Fact_SnapshotCustomer.RegulationID |
| New staker | First staking-eligible position opened in last 7 days | DWH_dbo.Dim_Position.OpenDateID |
| Supported cryptos | ETH, ADA, TRX, SOL, DOT, NEAR, ATOM, AVAX, SUI, POL | Dealing_dbo.Dealing_Staking_Parameters |

## ETL Pattern

- TRUNCATE → INSERT (no history retained)
- Table reflects only the most recent run's output
