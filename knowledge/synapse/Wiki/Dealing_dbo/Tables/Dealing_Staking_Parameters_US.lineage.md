# Lineage — Dealing_dbo.Dealing_Staking_Parameters_US

## Writer
**Manually maintained configuration table** — no automated ETL SP. Updated directly by the Dealing team when new instruments are added or parameters change. SP_Staking_US and SP_Staking_DailyPool_US read from this table; nothing writes to it automatically.

## Column Lineage

All columns are manually configured values — no upstream source system.

| Column | Type | Description |
|---|---|---|
| InstrumentID | int | eToro instrument ID for the staking asset |
| Currency | varchar(50) | Asset ticker (ADA, ETH, SOL, SUI) |
| IntroDays | int | Minimum holding period before a position qualifies for staking rewards |
| LiquidityBuffer | decimal | Fraction of opted-in units available for staking (e.g., 0.9 = 10% liquidity reserve) |
| DailyPool_StartDate | date | Date when daily pool tracking begins in SP_Staking_DailyPool_US |
| WelcomeEmail_StartDate | date | Date when welcome email notifications start |
| Distribution_StartDate | date | Date from which SP_Staking_US begins producing distributions |
| UpdateDate | datetime | Last manual update timestamp |
