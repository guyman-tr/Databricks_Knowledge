# Dealing_dbo.Dealing_WeeklyCMT_Fees

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_WeeklyCMT_Fees |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_Crypto_CMT_Fees(@Date)` — runs only on Sundays |
| **Refresh** | ⚠️ STALE — last data 2023-04-09; program appears discontinued |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Rows** | ~54.2K |
| **Date Range** | 2021-09-13 → 2023-04-09 (stale ⚠️) |
| **PII** | CID (client identifier) |

---

## 1. Business Meaning

Weekly rollover fee report for legacy leveraged long crypto positions (CMT = Crypto Margin Trading). Each Sunday, the SP identifies clients with pre-2021 leveraged long crypto positions that are still open and near-zero stop-out (StopRate ≤ instrument pip threshold), aggregates their weekly rollover fees (ActionTypeID=35, IsFeeDividend=1), and records the result.

The program tracked rollover fees for legacy leveraged crypto positions opened before January 8, 2021. These positions are classified as essentially stopped-out (stop rate at or below pip value). The table has been inactive since April 2023 — no positions meeting the `OpenDateID <= 20210108` criterion remain active.

---

## 2. Grain

One row = one PositionID for one weekly window (StartDate → EndDate, where EndDate is a Sunday). The window covers Monday through Sunday.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `EndDate` | date | Sunday end of the weekly window |
| `StartDate` | date | Monday start (DATEADD(DAY,-6,@Date)) |
| `CID` | int | Client identifier |
| `GCID` | int | Group/consolidated client ID from Dim_Customer |
| `PositionID` | bigint | Position identifier |
| `InstrumentDisplayName` | nvarchar | Instrument name from Dim_Instrument |
| `Leverage` | int | Position leverage |
| `IsSettled` | int | Settlement flag |
| `OpenOccurred` | datetime | Exact timestamp when position was opened |
| `Club` | varchar | Client club tier from Dim_PlayerLevel |
| `Regulation` | varchar | Regulatory jurisdiction name |
| `AccountManager` | varchar | Account manager full name (FirstName + ' ' + LastName) |
| `RollOverFee` | money | SUM of weekly rollover fees (negated: -Amount for ActionTypeID=35) |
| `StopRate` | float | Position stop-loss rate (must be ≤ pip threshold to be included) |
| `UpdateDate` | datetime | ETL metadata timestamp |

---

## 4. Common Query Patterns

```sql
-- Historical weekly fee totals
SELECT EndDate, StartDate, COUNT(DISTINCT CID) AS Clients,
       SUM(RollOverFee) AS TotalFees
FROM Dealing_dbo.Dealing_WeeklyCMT_Fees
GROUP BY EndDate, StartDate
ORDER BY EndDate DESC;

-- Positions still captured in final week
SELECT PositionID, CID, InstrumentDisplayName, Leverage, OpenOccurred, RollOverFee
FROM Dealing_dbo.Dealing_WeeklyCMT_Fees
WHERE EndDate = '2023-04-09'
ORDER BY RollOverFee DESC;
```

> ⚠️ **Stale since 2023-04-09** — no new data. The underlying legacy position program has ended; all pre-2021 leveraged crypto positions have been settled or closed.

---

## 5. Known Issues & Quirks

- **Sunday gate**: SP includes `IF DATENAME(WEEKDAY, @Date) = 'Sunday'` — calling with a non-Sunday date is a no-op
- **Hard cutoff**: `OpenDateID <= 20210108` — positions opened after January 8, 2021 are categorically excluded
- **Near-zero stop filter**: Only positions with StopRate ≤ pip value for the instrument (essentially stopped out) are included
- **HEAP storage**: No clustered index — consistent with a small operational table that was never expected to grow large
- **ActionTypeID=35**: Rollover fee action type; IsFeeDividend=1 ensures only true rollover fees (not dividends) are included
- **Program discontinued**: Table effectively EOL — no positions remain eligible

---

## 6. Lineage Summary

Sources: DWH_dbo.Dim_Position (pre-2021 open leveraged long crypto) + DWH_dbo.Fact_CustomerAction (ActionTypeID=35 rollover fees) + DWH_dbo.Dim_Customer + Dim_Instrument + Dim_Regulation + Dim_Manager + Dim_PlayerLevel. See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `DWH_dbo.Dim_Position` | Source — legacy pre-2021 crypto positions |
| `DWH_dbo.Fact_CustomerAction` | Weekly rollover fees (ActionTypeID=35) |
| `DWH_dbo.Dim_Customer` | Client data (GCID) |
| `DWH_dbo.Dim_Manager` | Account manager names |

---

*Quality score: 4.5/10 — stale since 2023-04-09, program discontinued, historical reference only*
