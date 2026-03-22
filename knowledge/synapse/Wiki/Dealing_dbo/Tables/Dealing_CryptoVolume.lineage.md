# Lineage: Dealing_dbo.Dealing_CryptoVolume

## Source Tables
| Source | Role |
|--------|------|
| Unknown | No active writer SP found in SSDT repository |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| InstrumentID | Unknown | Crypto instrument ID |
| Date | Unknown | Trading date |
| StartHour | Unknown | Hourly interval start |
| EndHour | Unknown | Hourly interval end |
| InstrumentName | Unknown | Crypto instrument name |
| IsBuy | Unknown | 1=buy, 0=sell |
| Clients_Volume | Unknown | Client side trade count |
| Clients_Units | Unknown | Client side position units |
| Clients_Commission | Unknown | Client side commission USD |
| HS_Volume | Unknown | Hedge server trade count |
| HS_Units | Unknown | Hedge server position units |
| MM_Volume | Unknown | Market maker trade count |
| MM_Units | Unknown | Market maker position units |
| UpdateDate | Unknown | Row write timestamp |
| MM_Crypto_Spot_Units | Unknown | Market maker spot crypto units |
| MM_Crypto_Spot_Volume | Unknown | Market maker spot crypto volume |
| IsSettled | Unknown | Settlement flag |

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_CryptoVolume/ |
| Notes | Table is STALE — last date 2024-04-02. No active writer SP found in SSDT. Likely written by a now-deleted or renamed SP. |
