# Cluster 17 brief — `eMoney_dbo.eMoney_Dim_Account`

_Size: 61, intra-cluster weight: 266.0_
_Schema mix: {'BI_DB_dbo': 6, 'Dictionary': 7, 'Dim_Country': 1, 'Dim_Customer': 1, 'Dim_PlayerLevel': 1, 'Dim_PlayerStatus': 1, 'Dim_Regulation': 1, 'SubPrograms': 1, 'dbo': 8, 'eMoney_Dictionary_AccountProgram': 1, 'eMoney_Dim_Account': 3, 'eMoney_dbo': 30}_
_Edge sources: {'wiki': 266}_

## Top members (ranked by intra-cluster weight)

- `eMoney_dbo.eMoney_Dim_Account` — w 80.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dim_Account.md)
- `eMoney_dbo.eMoney_Dim_Transaction` — w 58.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dim_Transaction.md)
- `eMoney_dbo.eMoney_Panel_FirstDates` — w 39.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Panel_FirstDates.md)
- `eMoney_dbo.eMoney_Card_Monthly_Snapshot` — w 23.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Card_Monthly_Snapshot.md)
- `eMoney_dbo.eMoney_Card_Instance_Summary` — w 22.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Card_Instance_Summary.md)
- `eMoney_dbo.eMoney_Fact_Transaction_Status` — w 21.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Fact_Transaction_Status.md)
- `eMoney_dbo.eMoney_Reports_AcquisitionFunnel` — w 21.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Reports_AcquisitionFunnel.md)
- `eMoney_dbo.eMoney_Marketing_EmailTracking` — w 16.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Marketing_EmailTracking.md)
- `eMoney_dbo.eMoney_UserData_Marketing` — w 16.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_UserData_Marketing.md)
- `eMoney_dbo.eMoney_Snapshot_Settled_Balance` — w 14.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Snapshot_Settled_Balance.md)
- `eMoney_dbo.eMoney_Dictionary_AccountSubProgram` — w 13.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dictionary_AccountSubProgram.md)
- `eMoney_dbo.eMoney_Dictionary_AccountProgram` — w 11.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dictionary_AccountProgram.md)
- `eMoney_dbo.eMoney_Dictionary_TransactionType` — w 10.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dictionary_TransactionType.md)
- `Dim_Customer.RealCID` — w 9.0 (no wiki)
- `dbo.FiatAccount` — w 9.0 (no wiki)
- `eMoney_dbo.eMoney_Account_Mappings` — w 9.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Account_Mappings.md)
- `eMoney_dbo.eMoney_BankPaymentsUK` — w 9.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_BankPaymentsUK.md)
- `BI_DB_dbo.BI_DB_SFMC_Report` — w 7.0 (no wiki)
- `dbo.FiatCardStatuses` — w 7.0 (no wiki)
- `eMoney_dbo.eMoney_Dictionary_TransactionStatus` — w 7.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dictionary_TransactionStatus.md)
- `eMoney_dbo.v_eMoney_Card_Instance_Summary` — w 7.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/v_eMoney_Card_Instance_Summary.md)
- `dbo.FiatTransactions` — w 6.0 (no wiki)
- `eMoney_dbo.eMoney_Dictionary_AccountStatus` — w 6.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dictionary_AccountStatus.md)
- `eMoney_dbo.eMoney_Dictionary_CardStatus` — w 6.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Dictionary_CardStatus.md)
- `eMoney_dbo.eMoney_Reports_ClubUpgrade` — w 6.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Reports_ClubUpgrade.md)

## Wiki §3.3 Common JOINs (top members)

### `eMoney_dbo.eMoney_Dim_Account`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON da.CID = dc.RealCID | Full trading profile for eTM customer |
| eMoney_dbo.eMoney_Dim_Transaction | ON da.CID = dt.CID | Transaction history for this account |
| eMoney_dbo.eMoney_Fact_Transaction_Status | ON da.CID = fts.CID | All transaction status events |
| eMoney_dbo.eMoneyClientBalance | ON da.CurrencyBalanceID = cb.CurrencyBalanceID | Daily balance reconciliation |
| DWH_dbo.Dim_Country | ON da.CountryID = c.CountryID | Country name/region lookup |
| DWH_dbo.Dim_Regulation | ON da.RegulationID = r.DWHRegulationID | Regulation name |

### `eMoney_dbo.eMoney_Dim_Transaction`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Dim_Account | ON dt.CID = da.CID AND da.GCID_Unique_Count=1 | Current account attributes |
| eMoney_dbo.eMoney_Fact_Transaction_Status | ON dt.TransactionID = fts.TransactionID | Full status event history |
| DWH_dbo.Dim_Customer | ON dt.CID = dc.RealCID | Trading platform customer profile |
| DWH_dbo.Dim_Regulation | ON dt.RegulationIDTxDate = r.DWHRegulationID | Regulation name at tx date |
| DWH_dbo.Dim_Country | ON dt.CountryIDTxDate = c.CountryID | Country name at tx date |

### `eMoney_dbo.eMoney_Panel_FirstDates`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Reports_AcquisitionFunnel | `CID` | Enrich funnel customer grain with FMI/FMO dates |
| eMoney_Dim_Account | `AccountID` | Add account metadata (currency, country) |
| DWH_dbo.Dim_Customer | `CID` | Add trading-side customer attributes |

### `eMoney_dbo.eMoney_Card_Monthly_Snapshot`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Card_Instance_Summary | ON snap.CID = cis.CID | Detailed card instance timelines per customer |
| eMoney_dbo.eMoney_Panel_FirstDates | ON snap.CID = fd.CID | FMI/FMO milestone cross-reference (eTM wallet history) |
| DWH_dbo.Dim_Customer | ON snap.CID = dc.RealCID | Current trading profile (regulation, segment) |
| eMoney_dbo.eMoney_Dim_Account | ON snap.GCID = mda.GCID AND mda.GCID_Unique_Count=1 | eTM account sub-program, validity |

### `eMoney_dbo.eMoney_Card_Instance_Summary`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Dim_Account | ON CIS.CID = mda.CID AND mda.GCID_Unique_Count=1 | Extend with account status, entity, sub-program |
| eMoney_dbo.eMoney_Card_Monthly_Snapshot | ON CIS.CID = snapshot.CID | Monthly card funnel — CIS feeds monthly snapshots |
| DWH_dbo.Dim_Customer | ON CIS.CID = dc.RealCID | Trading profile (club, country, regulation) |

### `eMoney_dbo.eMoney_Fact_Transaction_Status`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Dim_Transaction | ON fts.TransactionID = dt.TransactionID | Current-state context for status event rows |
| eMoney_dbo.eMoney_Dim_Account | ON fts.CID = da.CID AND da.GCID_Unique_Count=1 | Account attributes |
| DWH_dbo.Dim_Customer | ON fts.CID = dc.RealCID | Trading platform customer |
| DWH_dbo.Dim_Regulation | ON fts.RegulationIDTxDate = r.DWHRegulationID | Regulation name at tx date |

### `eMoney_dbo.eMoney_Reports_AcquisitionFunnel`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Dim_Account | `eMoney_Dim_Account.GCID = eMoney_Reports_AcquisitionFunnel.GCID` | Enrich with account details, card type, balance |
| eMoney_Panel_FirstDates | `eMoney_Panel_FirstDates.CID = eMoney_Reports_AcquisitionFunnel.CID` | Enrich with first action dates and amounts |
| DWH_dbo.Dim_Customer | `Dim_Customer.RealCID = eMoney_Reports_AcquisitionFunnel.CID` | Add registration date, language, regulation |

### `eMoney_dbo.eMoney_Marketing_EmailTracking`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Dim_Account | `CID = (customer from campaign)` | Enrich with eTM account details |
| eMoney_dbo.eMoney_Panel_FirstDates | `CID` | Card activation events |

### `eMoney_dbo.eMoney_UserData_Marketing`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Dim_Account | `eMoney_UserData_Marketing.GCID = eMoney_Dim_Account.GCID AND GCID_Unique_Count=1` | Full account details |
| DWH_dbo.Dim_Customer | `eMoney_UserData_Marketing.RealCID = Dim_Customer.RealCID` | Trading account attributes |
| eMoney_dbo.eMoney_AM_Target | `eMoney_UserData_Marketing.GCID = eMoney_AM_Target.GCID AND Report_Date='...'` | Add AM assignment |

### `eMoney_dbo.eMoney_Snapshot_Settled_Balance`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.eMoney_Dim_Account | ON ssb.AccountID = mda.AccountID | Full account attributes (IsValidETM, AccountProgram, etc.) |
| eMoney_dbo.eMoney_Panel_FirstDates | ON ssb.CID = fd.CID | FMI/FMO milestone cross-reference |
| DWH_dbo.Dim_Customer | ON ssb.CID = dc.RealCID | Current customer trading profile |

### `eMoney_dbo.eMoney_Dictionary_AccountSubProgram`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Dim_Account | AccountSubProgramID = AccountSubProgramID | Decode sub-program on account records |
| eMoney_Dictionary_AccountProgram | AccountProgramID = AccountProgramID | Navigate up to program level |

### `eMoney_dbo.eMoney_Dictionary_AccountProgram`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Dim_Account | AccountProgramID = AccountProgramID | Decode program type on account records |
| eMoney_Calculated_Balance | AccountProgramID = AccountProgramID | Segment balance by card vs IBAN |
| eMoney_Dictionary_AccountSubProgram | AccountProgramID = AccountProgramID | Navigate to sub-program level |

### `eMoney_dbo.eMoney_Dictionary_TransactionType`

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Fact_Transaction_Status | TransactionTypeID = TransactionTypeID | Decode all transaction type events |
| eMoney_Dim_Transaction | TransactionTypeID = TransactionTypeID | Decode latest transaction type |
| eMoney_Snapshot_Settled_Balance | (by type group) | Balance reconciliation by category |

## KPI views in this cluster

## Genie spaces overlapping this cluster

## Out-cluster neighbors (likely bridge candidates)

- `DWH_dbo.Dim_Customer` — outflow weight 30.5
- `DWH_dbo.Dim_Country` — outflow weight 11.0
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform` — outflow weight 10.0
- `DWH_dbo.Fact_SnapshotCustomer` — outflow weight 8.5
- `DWH_dbo.Dim_PlayerLevel` — outflow weight 8.5
- `DWH_dbo.Dim_Regulation` — outflow weight 7.0
- `eMoney_dbo.eMoneyClientBalance` — outflow weight 5.0
- `BI_DB_dbo.BI_DB_W_AML_PEP_Customers` — outflow weight 4.0
- `BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun` — outflow weight 4.0
- `Customer.CustomerStatic` — outflow weight 4.0
- `eMoney_dbo.eMoney_Dim_Country_Rollout` — outflow weight 4.0
- `eMoney_dbo.eMoney_AM_Target` — outflow weight 3.0
- `BI_DB_dbo.BI_DB_AML_SubEntity_Categorization` — outflow weight 3.0
- `BI_DB_dbo.BI_DB_Blocked_Customers` — outflow weight 3.0
- `DWH_dbo.Fact_CurrencyPriceWithSplit` — outflow weight 3.0
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` — outflow weight 2.5
- `BI_DB_dbo.BI_DB_AML_Terror_Monitor_Dashboard` — outflow weight 2.0
- `Dim_Customer.GCID` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_ClubChangeLogProduct` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting` — outflow weight 2.0
