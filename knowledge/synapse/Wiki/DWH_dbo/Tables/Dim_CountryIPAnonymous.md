# DWH_dbo.Dim_CountryIPAnonymous

> Anonymous/proxy IP address range mapping — identifies VPN, TOR, and other proxy IP ranges for fraud detection and compliance. ~4.8M rows. Loaded by SP_Dictionaries_Country_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension / Reference) |
| **Key Identifier** | Composite: IPFrom + IPTo (CLUSTERED INDEX) |
| **Row Count** | ~4,818,011 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on (IPFrom ASC, IPTo ASC) |

---

## 1. Business Meaning

`Dim_CountryIPAnonymous` maps IP ranges that are associated with anonymous proxy services (VPN, TOR, data center IPs). Used in customer action processing to flag users accessing the platform through anonymizing services — important for:
- Fraud detection and prevention
- Regulatory compliance (geographic restrictions)
- Risk scoring

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Load SP** | `DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse` (separate from main SP_Dictionaries) |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Active ETL** | Yes — UpdateDate shows 2026-03-11 |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | IPFrom | bigint | YES | Tier 2 | Start of anonymous IP range (IPv4 as integer). |
| 2 | IPTo | bigint | YES | Tier 2 | End of anonymous IP range (IPv4 as integer). |
| 3 | ProxyType | varchar(3) | YES | Tier 2 | Proxy classification code (e.g., VPN, TOR, DCH for data center hosting). |
| 4 | CountryCode | varchar(50) | YES | Tier 2 | ISO country code of the proxy exit node. |
| 5 | CountryName | varchar(500) | YES | Tier 2 | Full country name. |
| 6 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp. |
| 7 | CountryID | int | YES | Tier 2 | Country identifier. References Dim_Country. |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE — ~4.8M rows |
| **Clustered Index** | (IPFrom, IPTo) — range lookup for IP matching |
| **Known Consumer** | SP_Fact_CustomerAction — checks if user IP falls within anonymous proxy ranges |

---

*Generated: 2026-03-18 | Quality: 7.3/10 | Confidence: 0 Tier 1, 7 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CountryIPAnonymous.sql*
