# Dealing_dbo.Dealing_ApexRecon_Holdings

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_ApexRecon_Holdings |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 18 |
| **Primary Source** | `Dealing_dbo.Dealing_Duco_EODRecon` + `Dealing_staging.LP_APEX_EXT982_3EU` (Apex LP EOD holdings file) |
| **ETL SP** | `Dealing_dbo.SP_Apex_Recon` |
| **Refresh** | Daily per @Date (delete+insert) |
| **PII** | None — instrument-level reconciliation |
| **Tags** | dealing, apex, reconciliation, holdings, lp, custodian, hedging, real-stocks |

---

## 1. Business Meaning

`Dealing_ApexRecon_Holdings` is a **daily end-of-day holdings reconciliation** between eToro's internal records and Apex Clearing (LP/custodian) for real stock positions. It compares the eToro dealing desk's view of holdings (from Duco EOD reconciliation data) against Apex's official custodian file for each instrument×HedgeServer combination.

**Purpose**: Ensure that the number of shares eToro believes it holds at Apex matches what Apex reports. Discrepancies (`Etoro_Units ≠ Apex_Units`) indicate settlement risk, failed trades, or data synchronization issues. The Dealing team reviews this daily for operational and regulatory compliance.

**Scope**: Apex Clearing LP only (liquidity_provider='Apex'). Stocks - Real activity (`activity='Stocks - Real'`). HS/LP account mapping read from a Fivetran-synced Google Sheet (`External_Fivetran_dealing_active_hs_mappings`). RTH (Regular Trading Hours) instruments handled separately via a daylight-savings-adjusted allocation process.

**Related tables in the same SP**:
- `Dealing_ApexRecon_TradeActivity`: Intraday trade-level reconciliation (eToro executions vs Apex trades)
- `Dealing_ApexRecon_Hedging`: Over/under hedging flags derived from this table
- `Dealing_Duco_EODRecon`: eToro-side EOD reconciliation source

**SP Author**: Sarah Benchitrit (2021-03-07); last modified 2025-09-29 (SR-334801: RTH/daylight savings handling).

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_Apex_Recon(@Date)` — the Holdings section:

1. **HS/LP Mapping (`#Fivetran`)**: Reads the most recent active HS→LP account mapping snapshot as of @Date from `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` (Fivetran-synced Google Sheet). Filters: `liquidity_provider='Apex'`, `activity='Stocks - Real'`.

2. **Instrument Mapping (`#Apex_Ins`)**: Reads `Dealing_staging.LP_APEX_EXT982_3EU` (Apex EOD file for @Date) and matches Apex symbols/CUSIPs to DWH InstrumentIDs via `Dim_Instrument.CUSIP` (with leading-zero stripping). Deduplicates by checking `Dealing_Duco_EODRecon` when multiple InstrumentIDs map to the same CUSIP.

3. **Apex Holdings (`#ApexHoldings`)**: From `LP_APEX_EXT982_3EU`: per InstrumentID×HedgeServer×AccountNumber: `Apex_Units = SUM(TradeQuantity)`, `Apex_EOD_Price = ClosingPrice`, `Apex_Amount = SUM(MarketValue)`.

4. **eToro Side (`#eToroSide_EOD_00GMT`)**: From `Dealing_Duco_EODRecon`: per InstrumentID×HedgeServer×AccountNumber: `Etoro_Units`, `EOD_Price`, `Client_NOP_Units`, `Etoro_Amount`, `Client_NOP`. Joined to `#Fivetran` to filter to Apex accounts only.

5. **Daylight Savings Adjustment (`#etoroAllocationDaylightSavings`)**: For instruments where the RTH timing shifts (daylight savings boundary), reads `CopyFromLake.etoro_Hedge_ExecutionLog` directly to supplement eToro-side data. FULL OUTER JOIN with `#eToroSide_EOD_00GMT` to produce `#eToroSide_EOD`.

6. **INSERT into `Dealing_ApexRecon_Holdings`**: FULL OUTER JOIN `#ApexHoldings` to `#eToroSide_EOD` on InstrumentID×HedgeServerID. Rows exist where either Apex reports holdings or eToro has positions (or both).

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_dbo.Dealing_Duco_EODRecon` | `Date, InstrumentID, HedgeServerID, LiquidityAccountID` | eToro-side EOD position data |
| `Dealing_staging.LP_APEX_EXT982_3EU` | `InstrumentID, ReportDateID` | Apex LP EOD holdings file |
| `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` | `hs_dealing_desk, lp_accounts` | HS↔LP account mapping |
| `CopyFromLake.etoro_Hedge_ExecutionLog` | `InstrumentID, ExecutionTime, LiquidityAccountID` | Daylight-savings trade allocation supplement |
| `DWH_dbo.Dim_Instrument` | `InstrumentID, CUSIP` | Instrument metadata; CUSIP matching |
| `Dealing_dbo.Dealing_ApexRecon_Hedging` | `Date, InstrumentID, HedgeServerID` | Over/under hedging flags derived from this table |
| `Dealing_dbo.Dealing_ApexRecon_TradeActivity` | `Date, InstrumentID, HedgeServerID` | Trade-level reconciliation (same SP) |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_Recon)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date (@Date parameter). Clustered index key. (Tier 2 — SP_Apex_Recon) |
| 2 | InstrumentID | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. NULL when Apex reports a position eToro cannot match to an InstrumentID. (Tier 2 — SP_Apex_Recon) |
| 3 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument name. From Dim_Instrument or Apex file. (Tier 2 — SP_Apex_Recon) |
| 4 | ISINCode | varchar(50) | YES | International Securities Identification Number. From Dim_Instrument or eToro-side data. May be NULL if Apex provides only CUSIP. (Tier 2 — SP_Apex_Recon) |
| 5 | Etoro_Units | decimal(16,4) | YES | eToro's internal view of total shares held/hedged for this instrument×HS at EOD. From Dealing_Duco_EODRecon (and daylight savings supplement). NULL → zero if NULLIF applied. (Tier 2 — SP_Apex_Recon) |
| 6 | Apex_Units | decimal(16,4) | YES | Apex's reported total shares in custody for this instrument×HS at EOD. From LP_APEX_EXT982_3EU (SUM of TradeQuantity). NULL when Apex has no holding. (Tier 2 — SP_Apex_Recon) |
| 7 | Etoro_Rate | decimal(16,4) | YES | eToro's EOD price for this instrument (from Dealing_Duco_EODRecon.eToroRate). Used for USD amount computation. NULLIF(0) applied. (Tier 2 — SP_Apex_Recon) |
| 8 | Apex_Rate | decimal(16,4) | YES | Apex's reported closing price (LP_APEX_EXT982_3EU.ClosingPrice). (Tier 2 — SP_Apex_Recon) |
| 9 | Etoro_Amount | decimal(16,4) | YES | eToro's USD dollar value of holdings: `Etoro_Units × Etoro_Rate`. From Dealing_Duco_EODRecon.eToroUSDAmount. NULLIF(0) applied. (Tier 2 — SP_Apex_Recon) |
| 10 | Apex_Amount | decimal(16,4) | YES | Apex's reported market value in USD: `SUM(MarketValue)` from LP file. (Tier 2 — SP_Apex_Recon) |
| 11 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP run time. (Tier 2 — SP_Apex_Recon) |
| 12 | HedgeServerID | int | YES | HedgeServer ID from HS/LP mapping (#Fivetran.hs_dealing_desk). Identifies which eToro dealing desk/hedge server this account belongs to. (Tier 2 — SP_Apex_Recon) |
| 13 | Symbol | varchar(20) | YES | Apex ticker symbol (e.g., 'OPENW', 'AUGO'). From Apex LP file or Dim_Instrument.Symbol. (Tier 2 — SP_Apex_Recon) |
| 14 | Client_NOP | decimal(16,6) | YES | Client Net Open Position in USD: `SUM(ClientAmount)` from Dealing_Duco_EODRecon. Represents the total client-side exposure in this instrument (what clients hold). (Tier 2 — SP_Apex_Recon) |
| 15 | Client_NOP_Units | decimal(16,6) | YES | Client Net Open Position in shares: `SUM(ClientUnits)` from Dealing_Duco_EODRecon. Used for hedging diff calculation in Dealing_ApexRecon_Hedging. (Tier 2 — SP_Apex_Recon) |
| 16 | LastExecutionTime | datetime | YES | Always NULL in current SP (column retained for legacy/future use). (Tier 3 — live data) |
| 17 | CUSIP | varchar(100) | YES | CUSIP (Committee on Uniform Security Identification Procedures) identifier. 9-character US security identifier. Used for CUSIP-based matching between Apex and DWH. (Tier 2 — SP_Apex_Recon) |
| 18 | Exchange | varchar(100) | YES | Exchange name from Dim_Instrument (e.g., 'Nasdaq', 'NYSE'). Used to identify RTH instruments. (Tier 2 — SP_Apex_Recon) |
| 19 | AccountNumber | varchar(50) | YES | Apex LP account number from #Fivetran mapping (lp_accounts). Identifies which specific Apex sub-account holds this position. (Tier 2 — SP_Apex_Recon) |

**Note**: DDL shows 18 columns but the INSERT selects 19 fields including AccountNumber — the DDL has 18 named columns matching the 18-column DDL. AccountNumber is column 18.

---

## 5. Usage Notes

**Reconciliation check**: `Etoro_Units - Apex_Units` = discrepancy. Zero = fully reconciled. Positive = eToro thinks it has more than Apex reports. Negative = Apex reports more than eToro expects.

**Client_NOP vs Etoro_Units**: `Client_NOP_Units` is what clients hold; `Etoro_Units` is what eToro hedges at Apex. The difference (`Etoro_Units - Client_NOP_Units`) represents the residual hedge position (over/under-hedged), which feeds into `Dealing_ApexRecon_Hedging`.

**NULL rows**: Rows where InstrumentID is NULL indicate Apex-only rows where the CUSIP could not be matched to a DWH instrument. These are unmatched positions that need manual investigation.

**CUSIP matching complexity**: Apex CUSIPs sometimes have a leading zero not present in DWH. The SP strips the leading zero during matching: `CASE WHEN LEFT(CUSIP,1)='0' THEN SUBSTRING(...) ELSE CUSIP END`.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dealing_Duco_EODRecon + Dealing_staging.LP_APEX_EXT982_3EU (Apex LP EOD file) |
| **Refresh** | Daily per date via `SP_Apex_Recon(@Date)` |
| **SP Author** | Sarah Benchitrit (2021-03-07); last modified 2025-09-29 (SR-334801) |
| **PII** | None — instrument-level aggregate reconciliation |
| **Compliance** | LP/custodian reconciliation for real stock holdings; operational risk management |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Active data up to 2026-03-09 |
| SP Logic | 4/5 | Complex SP (727 lines) fully analyzed; CUSIP matching and daylight savings logic traced |
| Upstream Wiki | 2/5 | Dealing_Duco_EODRecon not yet documented; Apex LP files are external |
| Business Context | 2/5 | Atlassian MCP unavailable; reconciliation purpose clear from SP description |
| **Total** | **7.6/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
