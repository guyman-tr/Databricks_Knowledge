# Column Lineage: Dealing_dbo.Dealing_Staking_Parameters

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Staking_Parameters` |
| **Primary Source** | Manual configuration (reference data) |
| **ETL SP** | None — manually maintained reference table |
| **Downstream Consumers** | `SP_Staking`, `SP_Staking_US`, `SP_Staking_DailyPool`, `SP_Staking_DailyPool_US`, `SP_Staking_Emails`, `SP_Staking_WelcomeEmail` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Transform | Notes |
|-----------|-----------|-------|
| InstrumentID | reference | Crypto instrument FK (100xxx series) |
| Currency | reference | Crypto symbol (ETH, ADA, TRX, SOL, etc.) |
| IntroDays | reference | Days before staking starts earning |
| LiquidityBuffer | reference | Percentage of staked units reserved for liquidity |
| DailyPool_StartDate | reference | When daily pool calculation begins |
| WelcomeEmail_StartDate | reference | When welcome emails start for this crypto |
| Distribution_StartDate | reference | When reward distribution begins |
| UpdateDate | reference | Last config update timestamp |
