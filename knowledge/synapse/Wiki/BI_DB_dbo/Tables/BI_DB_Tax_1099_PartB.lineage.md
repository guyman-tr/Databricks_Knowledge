# Column Lineage — BI_DB_dbo.BI_DB_Tax_1099_PartB

**Writer SP**: `BI_DB_dbo.SP_Tax_1099_PartB` (Author: Adi Meidan, 2024-10-01)
**ETL Pattern**: TRUNCATE+INSERT (full reload, no date partitioning)
**Population Filter**: Customers from `External_Fivetran_google_sheets_population_1_1099` (US 1099 population list). Positions filtered to: IsBuy=1, IsSettled=1, InstrumentTypeID IN (5,6) on Nasdaq/NYSE OR ISIN/ISINCountryCode starts with 'US', closed within the reporting year.
**Execution Guard**: Only runs when @Date > last day of reporting year AND within 3 days of the last Fivetran sync date.

---

## Source Chain

```
External_Fivetran_google_sheets_population_1_1099 (1099 population list)
  + DWH_dbo.Dim_Date (reporting year boundaries)
  + DWH_dbo.Dim_Customer (customer demographics, name, email)
  + DWH_dbo.Dim_PlayerStatus (player status name)
  + DWH_dbo.Dim_Regulation (regulation name, end-of-year via Fact_SnapshotCustomer)
  + DWH_dbo.Fact_SnapshotCustomer (end-of-year regulation snapshot)
  + DWH_dbo.Dim_Range (date range resolution for snapshot)
  + External_UserApiDB_Customer_ExtendedUserField (TIN, FieldId=6)
  + External_UserApiDB_KYC_CountryTaxType (country tax type filter)
  + External_UserApiDB_Dictionary_ExtendedUserValueType (value type filter)
  + DWH_dbo.Dim_Position (position amounts, P&L, open/close dates)
  + DWH_dbo.Dim_Instrument (instrument name, ISIN, CUSIP, exchange)
         |
         |-- #pop (customer demographics)
         |-- #regulation_EOY (end-of-year regulation via snapshot)
         |-- #taxdata (TIN values, US country only, CountryID=219)
         |-- #positions (settled US-exchange positions closed in reporting year)
         |
         v
    #final (JOIN all temp tables)
         |
         v
    TRUNCATE + INSERT → BI_DB_dbo.BI_DB_Tax_1099_PartB
```

---

## Column-Level Lineage

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer (dc) | RealCID | Direct. Customer real CID from population list join. |
| Regulation_EOY | DWH_dbo.Dim_Regulation (dr1) | Name | End-of-year regulation. Resolved via Fact_SnapshotCustomer + Dim_Range where @lastDayOfYearDateID BETWEEN FromDateID AND ToDateID. |
| ClientName | DWH_dbo.Dim_Customer (dc) | FirstName, MiddleName, LastName | CONCAT(FirstName, ' ', MiddleName, ' ', LastName). Full name concatenation. |
| Client_Middle_Name | DWH_dbo.Dim_Customer (dc) | MiddleName | Direct. |
| Client_Surname | DWH_dbo.Dim_Customer (dc) | LastName | Direct. |
| Email | DWH_dbo.Dim_Customer (dc) | Email | Direct. |
| TIN_Value | External_UserApiDB_Customer_ExtendedUserField (euf) | Value | CASE WHEN LEN(ISNULL(Value,0)) IN (0,1) THEN 'Null' ELSE Value END. FieldId=6, US CountryID=219 only. ROW_NUMBER partitioned by CID, first record kept. |
| Gross_Proceed | DWH_dbo.Dim_Position (dp1) | Amount, NetProfit | Computed: Amount + NetProfit. Total gross proceeds from the position. |
| Cost | DWH_dbo.Dim_Position (dp1) | Amount | Direct. Original position cost basis. |
| NetProfit | DWH_dbo.Dim_Position (dp1) | NetProfit | Direct. Net profit/loss on the position. |
| IsLongTerm | DWH_dbo.Dim_Position (dp1) | OpenOccurred, CloseOccurred | CASE WHEN DATEDIFF(DAY, OpenOccurred, CloseOccurred) >= 365 THEN 'Yes' ELSE 'No'. IRS long-term holding period test. |
| CloseDate | DWH_dbo.Dim_Position (dp1) | CloseOccurred | CAST(CloseOccurred AS DATE). Position close date. |
| OpenDate | DWH_dbo.Dim_Position (dp1) | OpenOccurred | CAST(OpenOccurred AS DATE). Position open date. |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument (di1) | InstrumentDisplayName | Direct. |
| ISINCode | DWH_dbo.Dim_Instrument (di1) | ISINCode | Direct. |
| Exchange | DWH_dbo.Dim_Instrument (di1) | Exchange | Direct. Filtered to Nasdaq/NYSE or US ISIN. |
| CUSIP | DWH_dbo.Dim_Instrument (di1) | CUSIP | Direct. |
| PositionID | DWH_dbo.Dim_Position (dp1) | PositionID | Direct. Unique position identifier. |
| UpdateDate | computed | GETDATE() | SP execution timestamp. |
