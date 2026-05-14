# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status — Column Lineage

> Column-level routing from **`BI_DB_dbo.SP_DDR_Customer_Daily_Status`** (`DataPlatform/SynapseSQLPool1/sql_dp_prod_we/BI_DB_dbo/Stored Procedures/BI_DB_dbo.SP_DDR_Customer_Daily_Status.sql`).
> Canonical attribute semantics where applicable: `DWH_dbo.Fact_SnapshotCustomer.md`, `DWH_dbo.Dim_Customer.md`, `DWH_dbo.Dim_Country.md`; sibling rollup: `BI_DB_DDR_Customer_Periodic_Status.md`.

---

## PHASE 9 CHECKPOINT: PASS — SP Logic Read

The loader **DELETE + INSERT per `DateID`** and builds `#population`, joins **`Fact_SnapshotCustomer` + `Dim_Range`** for the `@dateID` snapshot window, merges **population TVFs**, **MIMO** prep from **`BI_DB_DDR_Fact_MIMO_AllPlatforms`**, **logged-in depositor splits** via **`Fact_CustomerAction`** (ActionTypeID 14), then **INSERT-select** with **`Dim_Country.MarketingRegionManualName`** and **`WHERE RN = 1`** for rare duplicate suppression.

---

## Phase 9 — Verbatim excerpt (target definition)

The following excerpt is copied **verbatim from the authoritative SP body** (`SP_DDR_Customer_Daily_Status.sql`) as referenced in the sprint card — illustrating (1) `Fact_SnapshotCustomer` enrichment and (2) the final `INSERT`:

```sql
SELECT fsc.RealCID 
	, fsc.RegulationID
	, fsc.DesignatedRegulationID
	, fsc.PlayerStatusID
	, fsc.IsCreditReportValidCB
	, fsc.IsValidCustomer
	, fsc.AccountTypeID
	, fsc.CountryID
	, fsc.MifidCategorizationID
	, fsc.PlayerLevelID
	, fsc.IsDepositor
	, p.FTDPlatformName
FROM DWH_dbo.Fact_SnapshotCustomer fsc
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND @dateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN #population p
		ON fsc.RealCID = p.RealCID
```

```sql
DELETE FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status  WHERE DateID = @dateID

INSERT INTO BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status (
[Date],[DateID],[RealCID],[TP_FTD_DateID],[TP_FTD_Date],[TP_FTDA],[IBAN_FTD_DateID],[IBAN_FTD_Date],[IBAN_FTDA],[TP_External_FTDA],[Global_FTD_DateID],[Global_FTD_Date],[Global_FTDA],[IsDepositorGlobal],[GlobalDeposited],[GlobalFirstDeposited],[GlobalRedeposited],[GlobalCashedOut],[Redeemed],[DepositedTP],[DepositedIBAN],[ReDepositedTP],[ReDepositedIBAN],[TPFirstDeposited],[IBANFirstDeposited],[TPExternalFirstDeposited],[ActiveTraded],[BalanceOnlyAccount],[Portfolio_Only],[AccountActive],[AccountInActive],[RegulationID],[DesignatedRegulationID],[PlayerStatusID],[IsCreditReportValidCB],[IsValidCustomer],[AccountTypeID],[CountryID],[MarketingRegion],[MifidCategorizationID],[PlayerLevelID],[IsDepositor],[IsFunded],[FirstTimeFunded],[FirstFundedDateID],[FirstActionType],[FirstActionDateID],[LoggedIn],[LoggedInTPDepositor],[LoggedInIBANDepositor],[LoggedInGlobalDepositor],[UpdateDate],[FirstIOBDateID],[FirstIOBTime],[Options_FTD_DateID],[Options_FTD_Date],[Options_FTDA],[OptionsFirstDeposited],[DepositedOptions],[ReDepositedOptions],[MoneyFarm_FTD_DateID],[MoneyFarm_FTD_Date],[MoneyFarm_FTDA],[MoneyFarmFirstDeposited]
)
...
FROM #enrichStatusActions sa
JOIN DWH_dbo.Dim_Country dc
    ON sa.CountryID = dc.CountryID
WHERE RN = 1
```

---

## Source inventory (rollup)

| Source object | Synapse schema | Role in SP |
|----------------|----------------|-----------|
| `BI_DB_Client_Balance_CID_Level_New` | BI_DB_dbo | Primary TP universe for `@dateID` |
| `Dim_Customer` | DWH_dbo | FTDs, platform membership, enrichment |
| `Dim_FTDPlatform` | DWH_dbo | `FTDPlatformName` joins |
| `Fact_SnapshotCustomer` + `Dim_Range` | DWH_dbo | As-of `@dateID` lifecycle / compliance snapshot |
| `Function_Population_Funded` | BI_DB_dbo | `IsFunded` cohort |
| `Function_Population_First_Time_Funded` | BI_DB_dbo | `FirstTimeFunded`, `FirstFundedDateID`, `FirstIOB*` |
| `Function_Population_First_Trading_Action` | BI_DB_dbo | `FirstActionType`, `FirstActionDateID` |
| `Function_Population_Balance_Only_Accounts` | BI_DB_dbo | `BalanceOnlyAccount` |
| `Function_Population_Portfolio_Only` | BI_DB_dbo | `Portfolio_Only` |
| `Function_Population_Active_Traders` | BI_DB_dbo | `ActiveTraded` |
| `BI_DB_DDR_Fact_MIMO_AllPlatforms` | BI_DB_dbo | Daily MIMO deposit/withdraw / FTD indicators |
| `BI_DB_DDR_Fact_MIMO_Options_Platform` | BI_DB_dbo | Options-only population extension |
| `eMoney_Fact_Transaction_Status` | eMoney_dbo | IBAN-only population + IBAN transaction keys |
| `Fact_CustomerAction` | DWH_dbo | Login (ActionTypeID 14) |
| `Dim_Country` | DWH_dbo | `MarketingRegion` ← `MarketingRegionManualName` |

---

## Column Lineage (64 elements)

| DWH Column | Source Table / Object | Source Column / Logic | Transform | Notes |
|------------|----------------------|------------------------|-----------|-------|
| Date | SP parameter | `@date` | literal | Business calendar date |
| DateID | SP parameter | `@dateID` | `CAST(CONVERT(VARCHAR(8),@date,112) AS INT)` | Delete key |
| RealCID | `#population` / `#enrichStatusActions` | `RealCID` | passthrough | HASH distribution key |
| TP_FTD_DateID | `#globalDepositorsAlltime` | `FirstDepositDateIDTP` | CASE on `FTDPlatformID` from `Dim_Customer` | Platform-scoped FTD |
| TP_FTD_Date | `#globalDepositorsAlltime` | `FirstDepositDateTP` | CASE | |
| TP_FTDA | `#globalDepositorsAlltime` | `FirstDepositAmountTP` | CASE | |
| IBAN_FTD_DateID | `#globalDepositorsAlltime` | `FirstDepositDateIDIBAN` | CASE | |
| IBAN_FTD_Date | `#globalDepositorsAlltime` | `FirstDepositDateIBAN` | CASE | |
| IBAN_FTDA | `#globalDepositorsAlltime` | `FirstDepositAmountIBAN` | CASE | |
| TP_External_FTDA | `#enrichStatusActions` | `TP_External_FTDA` | from `#mimoUsers` aggregates | MIMO-derived |
| Global_FTD_DateID | `#globalDepositorsAlltime` | `MinFirstDepositDateID` | MIN across platform FTD branches | |
| Global_FTD_Date | `#globalDepositorsAlltime` | `MinFirstDepositDate` | MIN date | |
| Global_FTDA | `#globalDepositorsAlltime` | `FirstDepositAmount` | paired to min-date branch | |
| IsDepositorGlobal | `#globalDepositorsAlltime` | `IsDepositorGlobal` | CASE on `FirstDepositDate` | |
| GlobalDeposited | `#mimoUsers` / UPDATE patch | `GlobalDeposited` | MAX/CASE over MIMO prep; Options patch | |
| GlobalFirstDeposited | `#mimoUsers` / UPDATE patch | `GlobalFirstDeposited` | MAX/CASE; Options patch | |
| GlobalRedeposited | `#mimoUsers` | `GlobalRedeposited` | MAX/CASE | |
| GlobalCashedOut | `#mimoUsers` | `GlobalCashedOut` | MAX/CASE + coerced withdraw branch | |
| Redeemed | `#mimoUsers` | `Redeemed` | MAX/CASE | |
| DepositedTP | `#mimoUsers` | `DepositedTP` | MAX/CASE | |
| DepositedIBAN | `#mimoUsers` | `DepositedIBAN` | MAX/CASE | |
| ReDepositedTP | `#mimoUsers` | `ReDepositedTP` | MAX/CASE | |
| ReDepositedIBAN | `#mimoUsers` | `ReDepositedIBAN` | MAX/CASE | |
| TPFirstDeposited | `#mimoUsers` | `TPFirstDeposited` | MAX/CASE | |
| IBANFirstDeposited | `#mimoUsers` | `IBANFirstDeposited` | MAX/CASE | |
| TPExternalFirstDeposited | `#mimoUsers` | `TPExternalFirstDeposited` | MAX/CASE | |
| ActiveTraded | `#activeTraders` (`Function_Population_Active_Traders`) | flag | LEFT JOIN presence | SP § active trader |
| BalanceOnlyAccount | `#balanceOnly` (`Function_Population_Balance_Only_Accounts`) | measure | LEFT JOIN presence | Numeric flag pattern |
| Portfolio_Only | `#portfolioOnly` (`Function_Population_Portfolio_Only`) | `Portfolio_Only` | ISNULL / join | CCI stores `decimal`; logic uses numeric |
| AccountActive | `#enrichStatusActions` | computed | `(ActiveTraded=1 OR Portfolio_Only=1)` | Derived |
| AccountInActive | `#inactive` except logic | computed | `#basicStatuses MINUS tiers` | Derived |
| RegulationID | `Fact_SnapshotCustomer` | `RegulationID` | passthrough | JOIN `Dim_Range` `@dateID` |
| DesignatedRegulationID | `Fact_SnapshotCustomer` | `DesignatedRegulationID` | passthrough | |
| PlayerStatusID | `Fact_SnapshotCustomer` | `PlayerStatusID` | passthrough | |
| IsCreditReportValidCB | `Fact_SnapshotCustomer` | `IsCreditReportValidCB` | passthrough | CB reporting filter semantics |
| IsValidCustomer | `Fact_SnapshotCustomer` | `IsValidCustomer` | passthrough | Same analytic role as “valid user”; see wiki §2 filter contract |
| AccountTypeID | `Fact_SnapshotCustomer` | `AccountTypeID` | passthrough | |
| CountryID | `Fact_SnapshotCustomer` | `CountryID` | passthrough | Stored as `decimal(16,6)` DDL |
| MarketingRegion | `Dim_Country` | `MarketingRegionManualName` | INNER JOIN after enrich | Overrides / manual region label |
| MifidCategorizationID | `Fact_SnapshotCustomer` | `MifidCategorizationID` | passthrough | |
| PlayerLevelID | `Fact_SnapshotCustomer` | `PlayerLevelID` | passthrough | |
| IsDepositor | `Fact_SnapshotCustomer` | `IsDepositor` | passthrough + `ISNULL(...,0)` | |
| IsFunded | `#funded` (`Function_Population_Funded`) | `Equity` presence | `CASE WHEN f1.RealCID IS NOT NULL` | Funded cohort |
| FirstTimeFunded | `#firstTimeFunded` (`Function_Population_First_Time_Funded`) | calendar match | `CASE WHEN FirstFundedDateID=@dateID` | |
| FirstFundedDateID | `#firstTimeFunded` | `FirstFundedDateID` | passthrough | |
| FirstActionType | `Function_Population_First_Trading_Action` via `#FirstActions` | `FirstActionType` | CASE vs `@dateID` cutoff | `'NoAction'` sentinel |
| FirstActionDateID | `#basicStatuses` | `FirstTradeDateID` renamed | mapped to `FirstActionDateID` | |
| LoggedIn | `#loggedIn` (`Fact_CustomerAction`) | aggregated | EXISTS ActionTypeID=14 per CID | |
| LoggedInTPDepositor | `#depositorsLoggedIn` | TPDepositor | CASE joined to `#loggedIn` | |
| LoggedInIBANDepositor | `#depositorsLoggedIn` | IBANDepositor | CASE | |
| LoggedInGlobalDepositor | `#depositorsLoggedIn` | GlobalDepositor | CASE | |
| UpdateDate | SQL runtime | `GETDATE()` | load stamp | |
| FirstIOBDateID | `Function_Population_First_Time_Funded` | `FirstIOBDateID` | passthrough | |
| FirstIOBTime | `Function_Population_First_Time_Funded` | `FirstIOBTime` | passthrough | |
| Options_FTD_DateID | `#globalDepositorsAlltime` | `FirstDepositDateIDOptions` | CASE | |
| Options_FTD_Date | `#globalDepositorsAlltime` | `FirstDepositDateOptions` | CASE | |
| Options_FTDA | `#globalDepositorsAlltime` | `FirstDepositAmountOptions` | CASE | |
| OptionsFirstDeposited | `#mimoUsers` | `OptionsFirstDeposited` | MAX/CASE | |
| DepositedOptions | `#mimoUsers` | `DepositedOptions` | MAX/CASE | |
| ReDepositedOptions | `#mimoUsers` | `ReDepositedOptions` | MAX/CASE | |
| MoneyFarm_FTD_DateID | `#globalDepositorsAlltime` | `FirstDepositDateIDMoneyFarm` | CASE | |
| MoneyFarm_FTD_Date | `#globalDepositorsAlltime` | `FirstDepositDateMoneyFarm` | CASE | |
| MoneyFarm_FTDA | `#globalDepositorsAlltime` | `FirstDepositAmountMoneyFarm` | CASE | |
| MoneyFarmFirstDeposited | SP expression | `MoneyFarm_FTD_DateID` | `CASE WHEN MoneyFarm_FTD_DateID=@dateID THEN 1 ELSE 0` | |

---

## PHASE 10B CHECKPOINT: PASS

Lineage table row count **64** matches `INFORMATION_SCHEMA.COLUMNS` / SSDT DDL for `BI_DB_DDR_Customer_Daily_Status`.
