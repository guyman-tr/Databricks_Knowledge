# Lineage: BI_DB_US_Stocks_MAU_DAU_KPI

**Schema:** BI_DB_dbo  
**Writer SP:** `SP_US_Stocks_MAU_DAU_KPI`  
**Author:** Artyom Bogomolsky (2022-06-19; RegulationID 7 + monthly logic fix added 2022-09-15)  
**ETL Pattern:** DELETE WHERE Date=@Date → INSERT SELECT  
**Frequency:** Daily (SB_Daily, Priority 20)

## Column Lineage

| Target Column | Source Table | Source Column / Expression | Transformation |
|---|---|---|---|
| DateID | SP input | CONVERT(VARCHAR, @Date, 112) | YYYYMMDD integer from @Date parameter |
| Date | SP input | @Date | Direct assignment |
| EOM | SP input | EOMONTH(@Date) | End of current month |
| StocksPotential | DWH_dbo.Fact_SnapshotCustomer + Dim_Range | RegulationID | SUM(CASE WHEN RegulationID=8 THEN 1 ELSE 0 END) — NYDFS-regulated US customers who are valid, depositors, VerificationLevelID=3 |
| CryptoPotential | DWH_dbo.Fact_SnapshotCustomer + Dim_Range | RealCID | COUNT(DISTINCT RealCID) WHERE RegulationID IN(7,8), IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 — all US customers (NFA + NYDFS) |
| Daily_RealStocks_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | Customer-day count: DISTINCT customers with settled real stock position (InstrumentTypeID IN(5,6), IsSettled=1) where OpenDateID=@DateID OR CloseDateID=@DateID |
| Daily_RealCrypto_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | Customer-day count: DISTINCT customers with settled real crypto position (InstrumentTypeID=10, IsSettled=1) where OpenDateID=@DateID OR CloseDateID=@DateID |
| Daily_Dual_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | Customer-day count: customers with BOTH real stocks AND real crypto activity on @Date |
| Daily_Any_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | COUNT(*) of all US customers (RegulationIDOnOpen IN(7,8)) with any position event on @Date |
| Monthly_RealStocks_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | Customer-month count: customers with any real stock settled position active during @StartDate to @Date (month-to-date window) |
| Monthly_RealCrypto_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | Customer-month count: customers with any real crypto position (InstrumentTypeID=10) active month-to-date |
| Monthly_Dual_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | Customer-month count: customers with both stocks AND crypto activity in the month |
| Monthly_Any_Activity | DWH_dbo.Dim_Position + Dim_Instrument | CID | COUNT(*) of all US customers with any position event month-to-date |
| UpdateDate | ETL runtime | GETDATE() | Always current ETL run timestamp |

## Source Tables

| Table | Role | Filter |
|---|---|---|
| `DWH_dbo.Dim_Position` | Daily and monthly activity tracking | RegulationIDOnOpen IN(7,8); OpenDateID=@DateID OR CloseDateID=@DateID (daily); BETWEEN @StartDateID and @DateID (monthly) |
| `DWH_dbo.Dim_Instrument` | Instrument type classification | InstrumentTypeID IN(5,6)=RealStocks, =10 RealCrypto |
| `DWH_dbo.Fact_SnapshotCustomer` | Potential population base | IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3, RegulationID IN(7,8) |
| `DWH_dbo.Dim_Range` | SCD validity period join | @DateID BETWEEN FromDateID AND ToDateID — aligns snapshot attributes to the given date |

## ETL Notes

- **DELETE uses Date not DateID**: DELETE WHERE Date=@Date. This is the date column (type=date), not DateID (int). Important for backfill: pass the date as DATE type, not an integer.
- **RegulationIDOnOpen**: Activity uses `Dim_Position.RegulationIDOnOpen` — the regulatory state at position open time. Regulatory changes after open do not affect historical activity attribution.
- **StocksPotential vs CryptoPotential filter difference**:
  - StocksPotential: `RegulationID=8` only (NYDFS)
  - CryptoPotential: `COUNT(DISTINCT RealCID)` with `RegulationID IN(7,8)` — includes NFA (7) and NYDFS (8). This is why CryptoPotential is always larger.
- **Monthly window resets on month start**: @StartDate = DATEADD(month, DATEDIFF(month, 0, @Date), 0) = first day of month. Monthly metrics rebuild from scratch each month — there is no carry-forward.
- **Activity definition**: A position is "active" on @Date if it was opened on @Date (OpenDateID=@DateID) OR closed on @Date (CloseDateID=@DateID). Positions open before and closing after @Date (i.e., held through the day) are included via the close date check.
- **RegulationID 7 added 2022-09-15**: Before this date, CryptoPotential excluded NFA-regulated customers.
