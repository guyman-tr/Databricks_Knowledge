# DWH_dbo.Dim_CountryIP

> IP address range to country and region mapping — resolves IPv4 addresses (stored as bigint ranges) to geographic location. ~6.9M rows covering global IP allocations.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension / Reference) |
| **Key Identifier** | Composite: IPFrom + IPTo + CountryID (CLUSTERED INDEX) |
| **Row Count** | ~6,864,024 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on (IPFrom ASC, IPTo ASC, CountryID ASC) |

---

## 1. Business Meaning

`Dim_CountryIP` maps IP address ranges to countries and regions. Used in customer action processing to determine the geographic origin of user activity based on their IP address. The IP addresses are stored as bigint values (IPv4 converted to integer).

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.CountryIP` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_CountryIP` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CountryID | int | NO | Tier 2 | Country identifier. References Dim_Country. |
| 2 | IPFrom | bigint | NO | Tier 2 | Start of IP range (IPv4 as integer). |
| 3 | IPTo | bigint | NO | Tier 2 | End of IP range (IPv4 as integer). |
| 4 | RegionID | int | YES | Tier 2 | Sub-country region/state identifier. |
| 5 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE — despite ~6.9M rows |
| **Clustered Index** | (IPFrom, IPTo, CountryID) — optimized for range lookups: `WHERE @IP BETWEEN IPFrom AND IPTo` |
| **Typical Usage** | Range lookup in SP_Fact_CustomerAction for IP-to-country resolution |

---

*Generated: 2026-03-18 | Quality: 7.5/10 | Confidence: 0 Tier 1, 5 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CountryIP.sql*
