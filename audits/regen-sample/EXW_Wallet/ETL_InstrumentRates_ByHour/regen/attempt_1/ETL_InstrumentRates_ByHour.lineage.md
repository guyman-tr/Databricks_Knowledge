# Lineage: EXW_Wallet.ETL_InstrumentRates_ByHour

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---------------|------|--------|----------|--------------|
| 1 | EXW_Currency.vInstrumentRatesForWeek | Table | EXW_Currency | Synapse | Direct source — hourly rate data read by writer SP |
| 2 | EXW_Wallet.SP_ETL_InstrumentRates_ByHour | Stored Procedure | EXW_Wallet | Synapse | Writer SP — aggregates rates by hour |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|---------------|---------------|-----------|------|
| InstrumentID | EXW_Currency.vInstrumentRatesForWeek | InstrumentId | Passthrough | Tier 2 |
| AskRateAvg | EXW_Currency.vInstrumentRatesForWeek | AskRate | AVG(AskRate) grouped by instrument and hour | Tier 2 |
| BidRateAvg | EXW_Currency.vInstrumentRatesForWeek | BidRate | AVG(BidRate) grouped by instrument and hour | Tier 2 |
| DateHour | EXW_Currency.vInstrumentRatesForWeek | DateFrom | CASE: if DateFrom falls within target day → truncated to hour; else → target day start | Tier 2 |
| Date | EXW_Currency.vInstrumentRatesForWeek | DateFrom | CASE: if DateFrom falls within target day → CAST(DateFrom AS DATE); else → target date | Tier 2 |
| DateID | EXW_Currency.vInstrumentRatesForWeek | DateFrom | CASE: if DateFrom falls within target day → CONVERT(VARCHAR(8), CAST(DateFrom AS DATE), 112); else → target date as int | Tier 2 |
| UpdateDate | EXW_Wallet.SP_ETL_InstrumentRates_ByHour | — | GETDATE() at insert time | Tier 2 |
