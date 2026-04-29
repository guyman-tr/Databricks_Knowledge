# BI_DB_dbo.BI_DB_AffData — Column Lineage

## Source Objects

| Source Table | Source Type | Relationship |
|---|---|---|
| Unknown (no writer SP in SSDT) | — | Table is dormant with 0 rows. Likely a legacy migration from on-prem BI_DB that was never re-implemented in Synapse. |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| RealCID | Unknown | — | Likely Customer.CustomerStatic.CID (standard RealCID pattern) |
| AffiliateID | Unknown | — | Likely fiktivo affiliate system ID |
| Aff_Registration | Unknown | — | Affiliate registration date |
| Aff_LoginName | Unknown | — | Affiliate login name |
| Aff_Email | Unknown | — | Affiliate email (masked with dynamic data masking) |
| ContractName | Unknown | — | Affiliate contract name |
| ContractType | Unknown | — | Affiliate contract type classification |
| Aff_eLanguage | Unknown | — | Affiliate language preference |
| AffGroup | Unknown | — | Affiliate group/tier classification |
| Channel | Unknown | — | Marketing channel attribution |
| UpdateDate | Unknown | — | ETL metadata timestamp |
