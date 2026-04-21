---
object: EXW_dbo.EXW_WalletEntity
type: Table
batch: 9
---

# EXW_WalletEntity — Column Lineage

| DWH Column | Source Column | Source Object | Transform | Tier |
|-----------|---------------|---------------|-----------|------|
| Date | — | SP parameter `@run` | The date passed to the SP; no further transformation | Tier 2 |
| DateID | — | SP parameter `@d_i` | `CAST(CONVERT(VARCHAR(8), @run, 112) AS INT)` — YYYYMMDD integer | Tier 2 |
| GCID | GCID | `DWH_dbo.Fact_SnapshotCustomer` → `etoro.Customer.CustomerStatic` | Passthrough via snapshot join | Tier 1 |
| RealCID | RealCID | `DWH_dbo.Fact_SnapshotCustomer` → `etoro.Customer.CustomerStatic` | Passthrough via snapshot join | Tier 1 |
| WalletEntity | — | Computed (8-branch CASE over multiple temp tables) | 1. T&C entity from last accepted TypeId (EntityName from `BI_DB_dbo.External_WalletDB_Dictionary_EtoroLegalEntities`); 2. Per-customer EXW_Settings Customer tag; 3. eToroDA (CountryID IN(191,54), RegulationID=1, JoinDate 2024-12-18 to 2025-06-11); 4. eToroEU (same countries, JoinDate 2025-06-11 to 2025-06-13); 5. eToroSEY (CountryID=123, RegulationID=9, JoinDate>=2024-12-18); 6. Settings-based entity (JoinDate>=2025-06-13, not Excluded, ResourceId=5904); 7. eToroGermany/eToroUS (SelectedValue IN(2,3)); 8. default eToroX | Tier 2 |
| TermsAndConditionDate | Occured | `CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions` → `Wallet.CustomerTermsAndConditions` | `MAX(CAST(Occured AS DATE))` per GCID+EntityName+TypeId group (most recent entity group's last acceptance date) | Tier 1 |
| TermsAndConditionTime | Occured | `CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions` → `Wallet.CustomerTermsAndConditions` | `MAX(Occured)` per GCID+EntityName+TypeId group (latest acceptance datetime for most recent entity) | Tier 1 |
| RegulationID | RegulationID | `DWH_dbo.Fact_SnapshotCustomer` → `etoro.BackOffice.Customer` | Passthrough via snapshot join | Tier 1 |
| CountryID | CountryID | `DWH_dbo.Fact_SnapshotCustomer` → `etoro.Customer.CustomerStatic` | Passthrough via snapshot join | Tier 1 |
| JoinDate | Occurred | `EXW_Wallet.CustomerWalletsView` | `MIN(Occurred)` per Gcid — first wallet activation date | Tier 2 |
| TermsAndConditionTypeID | TypeId | `CopyFromLake.WalletDB_Wallet_TermsAndConditions` → `Wallet.TermsAndConditions` | Renamed TypeId → TermsAndConditionTypeID; most recent entity group's TypeId | Tier 1 |
| TermsAndConditionVersions | Version | `CopyFromLake.WalletDB_Wallet_TermsAndConditions` → `Wallet.TermsAndConditions` | `STRING_AGG(Version, ',')` per GCID+EntityName+TypeId group | Tier 1 |
| TermsAndConditionIDs | TermsAndConditionId | `CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions` → `Wallet.CustomerTermsAndConditions` | `STRING_AGG(TermsAndConditionId, ',')` per GCID+EntityName+TypeId group | Tier 1 |
| UpdateDate | — | SP_EXW_WalletEntity | `GETDATE()` at insert time | Tier 2 |

## ETL Pipeline

```
etoro.Customer.CustomerStatic + BackOffice.Customer (production OLTP)
  └─ DWH_dbo.Fact_SnapshotCustomer (SCD snapshot)
       ├─ #snapprep (GCID, RealCID, RegulationID, CountryID for @d_i)

WalletDB.Wallet.CustomerTermsAndConditions (production OLTP)
  └─ CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions
       └─ #userstnc → #changes → #orderofchanges → #lastregulation
             (MaxDateOccurred, MaxOccurred, Versions, TermsAndConditionIds, TypeId)

WalletDB.Wallet.TermsAndConditions (production OLTP)
  └─ CopyFromLake.WalletDB_Wallet_TermsAndConditions
       └─ #map (TypeId → EntityName mapping via BI_DB EtoroLegalEntities dictionary)

EXW_Wallet.CustomerWalletsView
  └─ #usersw (MIN(Occurred) per Gcid = JoinDate)

EXW_Settings (ResourceId=5904, domain='wallet')
  └─ #settings → #union → #value (country-level entity resolution)

EXW_dbo.EXW_UserSettingsWalletAllowance
  └─ #blocked (Excluded flag per GCID)

All temp tables → #compile → INSERT INTO EXW_dbo.EXW_WalletEntity
```
