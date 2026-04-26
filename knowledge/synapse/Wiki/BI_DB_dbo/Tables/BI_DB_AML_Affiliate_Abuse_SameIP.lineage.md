# Lineage: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP

## Object
- **Schema**: BI_DB_dbo
- **Object**: BI_DB_AML_Affiliate_Abuse_SameIP
- **Type**: Table
- **Writer SP**: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)
- **UC Target**: Not_Migrated

## ETL Pipeline
```
DWH_dbo.Dim_Customer + DWH_dbo.Dim_Affiliate + Dim_Country + Dim_Regulation + Dim_PlayerLevel
  |-- SP Step 03: #cidlevel (CIDs, IPs, enriched demographics) ---|
  v
V_Liabilities + Fact_BillingWithdraw + Fact_BillingDeposit + Dim_Position
  |-- SP Steps 04-06: #final_CID (CID-level enriched snapshot) ---|
  v
#SameIP → PARTITION BY AffiliateID → #calSameIP → CHECKSUM(IP) grouping
  |-- SP Step 09: #finalSameIP ---|
  v
TRUNCATE + INSERT (SP disabled 2024-12-31)
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP (1,178,451 rows, frozen 2024-12-31)
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| AffiliateID | Dim_Customer → Dim_Affiliate | AffiliateID | passthrough |
| NumOfClientsSameIP | #final_CID | CID | COUNT DISTINCT per IP per AffiliateID |
| TotalClients | #calSameIP | NumOfClientsSameIP | SUM OVER (PARTITION BY AffiliateID) |
| Group | #final_CID | IP | CHECKSUM(IP) — integer hash of IP string |
| %SameIP | #finalSameIP | NumOfClientsSameIP / TotalClients | ROUND(* 100.0 / TotalClients, 2) as DECIMAL(10,2) |
| UpdateDate | ETL metadata | — | GETDATE() |

## Source Objects
- `DWH_dbo.Dim_Customer` — CID, AffiliateID, IP per customer
- `DWH_dbo.Dim_Affiliate` — SubChannelID filter
- `DWH_dbo.V_Liabilities` — equity snapshot (INNER JOIN → drops customers without liability record)
