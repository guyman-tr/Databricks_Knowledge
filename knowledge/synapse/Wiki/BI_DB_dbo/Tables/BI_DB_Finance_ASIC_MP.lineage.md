# Column Lineage — BI_DB_dbo.BI_DB_Finance_ASIC_MP

**Writer SP**: `BI_DB_dbo.SP_Finance_ASIC_MP` (Priority 0 — SB_Daily)
**ETL Pattern**: DELETE-INSERT by DateID (daily incremental)
**Population Filter**: RegulationIDOnOpen IN (4, 10) for opens; RegulationID IN (4, 10) via Fact_SnapshotCustomer for closes; IsPartialCloseChild = 0 for opens; IsCreditReportValidCB = 1

**Note**: The SP produces three phases — Open positions, Close positions, and IsSettled-Changed positions — via UNION ALL. It also calls `SP_Create_External_etoro_History_PositionChangeLog` to stage the PositionChangeLog external table for the change-detection phase.

---

## Source Chain

```
Dim_Position (dp) ────────────┐
Dim_Instrument (di) ──────────┤
Fact_SnapshotCustomer (fsc) ──┤
Dim_Range (ddr) ──────────────┤──→ #Open_Positions_Phase
Dim_Regulation (dr) ──────────┤      (open positions for @DateID)
Fact_CustomerAction (fca) ────┤
Fact_CurrencyPriceWithSplit ──┘
                                     │
Dim_Position (dp) ────────────┐      │
Dim_Instrument (di) ──────────┤      │
Fact_SnapshotCustomer (fsc) ──┤      │
Dim_Range (ddr) ──────────────┤──→ #Close_Positions_Phase
Dim_Regulation (dr) ──────────┤      (close positions for @DateID)
Fact_CurrencyPriceWithSplit ──┘      │
                                     │
External_etoro_History_              │
  PositionChangeLog_Yesterday ─┐     │
Fact_CustomerAction (fca) ─────┤     │
Dim_Instrument (di) ───────────┤──→ #Change_Positions_Phase
Dim_Position (dp) ─────────────┤      (IsSettled changes for @DateID)
Fact_SnapshotCustomer (fsc) ───┤     │
Dim_Range (ddr) ───────────────┤     │
Dim_Regulation (dr) ───────────┤     │
Fact_CurrencyPriceWithSplit ───┘     │
                                     │
              UNION ALL ◄────────────┘
                   ↓
    INSERT INTO BI_DB_Finance_ASIC_MP
```

---

## Column-Level Lineage

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Position_Phase | literal | — | 'Open_Position' or 'Close_Position' depending on phase |
| DateID | Dim_Position (dp) | OpenDateID / CloseDateID | Direct. YYYYMMDD integer |
| DateOccurred | Dim_Position (dp) | OpenOccurred / CloseOccurred | CAST(CONVERT(CHAR(8), Occurred, 112) AS DATE) |
| EOW | computed | OpenOccurred / CloseOccurred | DATEADD(dd, -(DATEPART(dw, Occurred) - 7), Occurred) — end of week (Saturday) |
| EOM | computed | OpenOccurred / CloseOccurred | EOMONTH(Occurred, 0) — end of month |
| HedgeServerID | Dim_Position (dp) | HedgeServerID | Direct passthrough |
| ISINCountryCode | Dim_Instrument (di) | ISINCode | SUBSTRING logic: first 2 chars if 3rd is numeric, else first 3 chars; '-' if null/empty |
| InstrumentTypeID | Dim_Instrument (di) | InstrumentTypeID | Direct passthrough |
| InstrumentTypeName | Dim_Instrument (di) | InstrumentType | Direct passthrough |
| InstrumentID | Dim_Position (dp) / Dim_Instrument (di) | InstrumentID | Direct passthrough |
| InstrumentName | Dim_Instrument (di) | Name | Direct passthrough |
| CID | Dim_Position (dp) | CID | Direct passthrough |
| PositionID | Dim_Position (dp) | PositionID | Direct passthrough |
| IsSettled_OnOpen | Fact_CustomerAction (fca) | IsSettled | Open phase: from #IsSettled_OnOpen temp table (ActionTypeID IN 1,2,3); Close phase: -1 literal |
| IsSettled_OnClose | Dim_Position (dp) | IsSettled | Close phase: from dp.IsSettled; Open phase: -1 literal |
| Leverage | Dim_Position (dp) | Leverage | Direct passthrough |
| SellCurrencyID | Dim_Instrument (di) | SellCurrencyID | Direct passthrough |
| SellCurrency | Dim_Instrument (di) | SellCurrency | Direct passthrough |
| Amount_OnOpen_USD | Dim_Position (dp) | InitialAmountCents | Open phase: InitialAmountCents / 100; Close phase: 0 |
| Amount_OnOpen_GBP | computed | InitialAmountCents, Ask | Open phase: Amount_OnOpen_USD / GBP Ask price when SellCurrencyID IN (666, 3); else 0 |
| Amount_OnOpen_EUR | computed | InitialAmountCents, Ask | Open phase: Amount_OnOpen_USD / EUR Ask price when SellCurrencyID = 2; else 0 |
| Notional_Value | Dim_Position (dp) | AmountInUnitsDecimal, InitForexRate / EndForexRate | Open: AmountInUnitsDecimal * InitForexRate; Close: AmountInUnitsDecimal * EndForexRate |
| Amount_OnClose_USD | Dim_Position (dp) | Amount | Close phase: dp.Amount; Open phase: 0 |
| Amount_OnClose_GBP | computed | Amount, Ask | Close phase: Amount / GBP Ask price when SellCurrencyID IN (666, 3); else 0 |
| Amount_OnClose_EUR | computed | Amount, Ask | Close phase: Amount / EUR Ask price when SellCurrencyID = 2; else 0 |
| RegulationID_OnOpen | Dim_Position (dp) | RegulationIDOnOpen | Open phase: direct; Close phase: -1 literal |
| RegulationName_OnOpen | Dim_Regulation (dr) | Name | Open phase: via dp.RegulationIDOnOpen → dr.DWHRegulationID; Close phase: 'N/A' |
| RegulationID_OnClose | Fact_SnapshotCustomer (fsc) | RegulationID | Close phase: fsc.RegulationID; Open phase: -1 literal |
| RegulationName_OnClose | Dim_Regulation (dr) | Name | Close phase: via fsc.RegulationID → dr.DWHRegulationID; Open phase: 'N/A' |
| Is_Copy | Dim_Position (dp) | MirrorID | CASE WHEN MirrorID <> 0 THEN 1 ELSE 0 END |
| Position_Quantity | literal | — | Always 1 |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
