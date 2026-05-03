# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

> 91.5M-row transaction-level MIMO (Money In / Money Out) fact table unifying deposits and withdrawals across all four platforms — TradingPlatform, eMoney, Options (Apex), and MoneyFarm — with first-time deposit flags at both platform and global levels. Sourced from three sub-platform MIMO tables plus `Function_MIMO_First_Deposit_All_Platforms` for cross-platform FTD reconciliation, assembled by `SP_DDR_Fact_Fact_MIMO_AllPlatforms` with daily DELETE/INSERT by DateID for TP+eMoney and full DELETE/re-INSERT for Options and MoneyFarm.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multiple — `BI_DB_DDR_Fact_MIMO_Trading_Platform`, `BI_DB_DDR_Fact_MIMO_eMoney_Platform`, `BI_DB_DDR_Fact_MIMO_Options_Platform`, `Function_MIMO_First_Deposit_All_Platforms` |
| **Refresh** | Daily — DELETE/INSERT by DateID (TP+eMoney); full DELETE/re-INSERT (Options, MoneyFarm) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table is the **unified MIMO (Money In / Money Out) fact table** within the DDR (Daily Data Report) framework. Each row represents a single financial transaction — deposit or withdrawal — for a customer on a specific date, tagged with the originating platform and enriched with first-time deposit indicators at both the platform level (`IsPlatformFTD`) and global cross-platform level (`IsGlobalFTD`).

The table answers: "What deposits and withdrawals occurred for each customer on each day, across which platform, and which of those represent first-time deposits?"

Data flows through a three-tier architecture:
1. **Sub-platform tables** — `BI_DB_DDR_Fact_MIMO_Trading_Platform` (TP), `BI_DB_DDR_Fact_MIMO_eMoney_Platform` (eMoney/IBAN), and `BI_DB_DDR_Fact_MIMO_Options_Platform` (Apex options) each capture platform-specific MIMO transactions with platform-level FTD flags.
2. **Global FTD function** — `Function_MIMO_First_Deposit_All_Platforms(0)` determines which deposit is the customer's very first across all platforms.
3. **Unification SP** — `SP_DDR_Fact_Fact_MIMO_AllPlatforms` merges all platforms via UNION ALL, joins with global FTDs, adds MoneyFarm FTD-only records from `Dim_Customer`, and runs post-insert UPDATE corrections for FTD recovery and Crypto-to-Fiat tagging.

The SP runs daily via Service Broker (`SB_Daily`). It was authored 2024-07-02 and has undergone significant evolution: C2F support (2025-03-17), recurring deposits (2025-05-06), IBAN quick transfer (2025-06-16), Options platform (2025-10-06), MoneyFarm (2025-11-18), C2USD broad tagging (2025-12-04), and null handling for lake merge keys (2025-12-07).

---

## 2. Business Logic

### 2.1 Multi-Platform Unification

**What**: Combines MIMO transactions from four distinct platforms into a single queryable table

**Columns Involved**: `MIMOPlatform`, all transaction columns

**Rules**:
- TradingPlatform and eMoney are UNION ALL'd with consistent column ordering, then DELETE/INSERT'd by DateID (idempotent daily refresh)
- Options platform is fully deleted and re-inserted every run (data arrives unreliably; small dataset ~98K rows)
- MoneyFarm is FTD-only — only first deposits appear, no general MIMO (full delete/re-insert)
- Column mappings differ by platform: `IsIBANTrade` in eMoney ↔ `IsIBANTrade` in TP become `IsTradeFromIBAN`; `IsFTD` becomes `IsPlatformFTD`

### 2.2 Global FTD Reconciliation

**What**: Identifies whether a deposit is the customer's very first across ALL platforms, not just the originating one

**Columns Involved**: `IsGlobalFTD`, `IsPlatformFTD`

**Rules**:
- `IsGlobalFTD = 1` when a LEFT JOIN to `Function_MIMO_First_Deposit_All_Platforms` matches on `RealCID + IsFTD=1 + FTDPlatformID`
- A deposit can be `IsPlatformFTD = 1` (first on eMoney) but `IsGlobalFTD = 0` (customer already deposited on TP before)
- Post-insert UPDATE recovery: matches Dim_Customer.FTDTransactionID to eMoney_Fact_Transaction_Status and direct TransactionID for TP to set both flags to 1 for DateID >= 20250901

### 2.3 Crypto-to-Fiat Classification

**What**: Dual-source tagging for deposits that convert crypto to fiat currency

**Columns Involved**: `IsCryptoToFiat`

**Rules**:
- Sub-platform tables provide their own `IsCryptoToFiat` flag (from eMoney `TxTypeID=14`)
- Post-insert UPDATE additionally sets `IsCryptoToFiat = 1` for TradingPlatform deposits where `FundingTypeID = 27` and `DateID >= 20250701`
- Both paths are additive — a deposit tagged by either source or the UPDATE gets `IsCryptoToFiat = 1`

### 2.4 MoneyFarm Special Handling

**What**: MoneyFarm only contributes FTD records, not general MIMO activity

**Columns Involved**: `MIMOPlatform = 'MoneyFarm'`

**Rules**:
- Only deposits with `FTDPlatform = 'MoneyFarm'` from `Function_MIMO_First_Deposit_All_Platforms` are included
- Hardcoded values: `AmountOrigCurrency = -1`, `FundingTypeID = -1`, `CurrencyID = 3`, `Currency = 'GBP'`
- All boolean flags (`IsRedeem`, `IsTradeFromIBAN`, `IsCryptoToFiat`, `IsRecurring`, `IsIBANQuickTransfer`) are hardcoded to 0

<!-- TABLEAU-SEMANTICS-TABLE v2 -->
### Tableau-Discovered Conventions

> _LLM-curated business definitions extracted from downstream Tableau calculated fields. Discard-by-default; only definitions that add semantic value beyond the existing wiki are kept._

- **Transaction Description taxonomy** - Downstream dashboards classify every MIMO row into one of six business categories by combining MIMOAction, IsInternalTransfer, and IsTradeFromIBAN: 'Internal Transfer: Local Account → USD Account' (Deposit+Internal+¬IBAN), 'Internal Transfer: USD Account → Local Account' (Withdraw+Internal+¬IBAN), 'Open Position from Local Account' (Deposit+Internal+IBAN), 'Close Position to Local Account' (Withdraw+Internal+IBAN), 'Deposit from External' (Deposit+¬Internal+¬IBAN), 'Withdraw to External' (Withdraw+¬Internal+¬IBAN).
  Formula: `IF MIMOAction='Deposit' AND IsInternalTransfer=1 AND IsTradeFromIBAN=0 THEN 'Internal Transfer: Local Account → USD Account' ELSEIF MIMOAction='Withdraw' AND IsInternalTransfer=1 AND IsTradeFromIBAN=0 THEN 'Internal Transfer: USD Account...`
  Workbook(s): *Account Statement Report - Beta version*
- **eMoney MOP reclassification (OpenBanking vs WireTransfer)** - For eMoney-platform external deposits (IsInternalTransfer=0 AND IsTradeFromIBAN=0), the standard Dim_FundingType name is replaced by a cross-table lookup: if the transaction's ReferenceNumber matches an approved (TransferStatusID=10) record in External_MoneyTransfer_Billing_Transfers, the MOP is 'OpenBanking'; otherwise it falls back to 'WireTransfer'. Non-eMoney or internal/IBAN transactions use the standard Dim_FundingType.Name.
  Formula: `CASE WHEN MIMOPlatform='eMoney' AND IsInternalTransfer=0 AND IsTradeFromIBAN=0 THEN (CASE WHEN External_MoneyTransfer_Billing_Transfers.CID IS NOT NULL THEN 'OpenBanking' ELSE 'WireTransfer' END) ELSE Dim_FundingType.Name END`
  Workbook(s): *Local Currencies MIMO Dashboard  (Beta)*, *Local Currencies MIMO Dashboard  (Beta) TestVersion*
- **Net Deposits KPI (AML context)** - Net Deposits is defined as (Trading Deposits − Trading Withdrawals + eMoney Inbound − eMoney Outbound), where Trading flows exclude FundingTypeID 33 and eMoney flows exclude internal transfers (IsInternalTransfer=1). This KPI is used for AML-flagged customers sourced from BI_DB_AML_BI_Alerts_New and BI_DB_RiskAlertManagementTool (CategoryName='AML').
  Formula: `SUM(CASE WHEN MIMOPlatform='TradingPlatform' AND MIMOAction='Deposit' AND FundingTypeID<>33 THEN AmountUSD ELSE 0 END) - SUM(CASE WHEN MIMOPlatform='TradingPlatform' AND MIMOAction='Withdraw' AND FundingTypeID<>33 THEN AmountUSD ELSE 0 E...`
  Workbook(s): *AML Clients – Trading & eMoney Net Deposits*

_(auto-generated by `tools/tableau/judge_wiki_tableau_semantics.py`; safe to delete - regenerable)_
<!-- /TABLEAU-SEMANTICS-TABLE -->


---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX. Always include `RealCID` in WHERE or JOIN conditions for optimal distribution-aligned queries. With 91.5M rows, always filter by `DateID` and/or `MIMOPlatform` to limit scan scope.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total deposits/withdrawals for a customer | `WHERE RealCID = @cid AND DateID BETWEEN @s AND @e` — SUM `AmountUSD` by `MIMOAction` |
| FTD count by platform and date | `WHERE IsPlatformFTD = 1 GROUP BY DateID, MIMOPlatform` — COUNT(*) |
| Global FTDs per day | `WHERE IsGlobalFTD = 1 AND MIMOAction = 'Deposit' GROUP BY DateID` |
| Platform comparison of deposit volumes | `WHERE MIMOAction = 'Deposit' GROUP BY DateID, MIMOPlatform` — SUM `AmountUSD` |
| Crypto-to-fiat deposit trends | `WHERE IsCryptoToFiat = 1 GROUP BY DateID` — SUM `AmountUSD` |
| Recurring deposit analysis | `WHERE IsRecurring = 1 GROUP BY DateID` — COUNT and SUM |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `ON m.RealCID = dc.RealCID` | Customer demographics, registration, country |
| `DWH_dbo.Dim_FundingType` | `ON m.FundingTypeID = dft.FundingTypeID` | Payment method name (Wire, CC, e-Wallet, etc.) |
| `DWH_dbo.Dim_Currency` | `ON m.CurrencyID = dc.CurrencyID` | Full currency details |
| `BI_DB_dbo.BI_DB_DDR_CID_Level` | `ON m.RealCID = cl.RealCID AND m.DateID = cl.DateID` | Full DDR daily picture per customer |

### 3.4 Gotchas

- **91.5M rows** — always filter by `DateID`. Unfiltered scans are expensive.
- **IsPlatformFTD ≠ IsGlobalFTD** — a customer can have multiple platform FTDs but only one global FTD. Use `IsGlobalFTD` for unique first-deposit counting.
- **Options TransactionID = 0** — Options platform transactions have TransactionID set to 0 (varchar/int incompatibility with lake schemas); do not join on TransactionID for Options rows.
- **MoneyFarm is FTD-only** — only first deposits appear. No withdrawals or subsequent deposits.
- **AmountOrigCurrency = -1 for MoneyFarm** — sentinel value indicating original currency amount not available.
- **IsTradeFromIBAN column** — renamed from `IsIBANTrade` in sub-platform tables; always 0 for Options/MoneyFarm.
- **IsCryptoToFiat dual source** — set by both sub-platform flag AND post-insert UPDATE for FundingTypeID=27. Historical data before 2025-07 may have gaps in TP tagging.
- **FTD recovery runs for DateID >= 20250901** — older records may have under-counted FTDs that were corrected later via Dim_Customer.
- **NULL coercion** — all boolean flags are ISNULL'd to 0; NULLs never appear in flag columns.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date key in YYYYMMDD integer format. Partition/filter key for daily DELETE/INSERT (TP+eMoney). Direct passthrough from sub-platform tables. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. `@date` SP input parameter. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 3 | RealCID | int | YES | Customer identifier. Distribution key. Passthrough from sub-platform tables. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 4 | MIMOAction | varchar(100) | YES | Transaction direction. `'Deposit'` for money in, `'Withdraw'` for money out. Passthrough from sub-platform tables. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 5 | OrigIdentifier | varchar(100) | YES | Type label for the source transaction ID. Values: `'TransactionID'` (eMoney deposit), `'WithdrawPaymentID'` (withdrawal), `'DepositID'` (TP deposit/MoneyFarm). Passthrough from sub-platform tables. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 6 | TransactionID | int | YES | Source transaction identifier. `CAST(f.TransactionID AS VARCHAR(50))` for TP/eMoney; hardcoded `0` for Options and MoneyFarm (varchar incompatibility with lake schemas). (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 7 | AmountUSD | decimal(16,6) | YES | Transaction amount in USD equivalent. Passthrough from sub-platform tables. Negative values may appear for withdrawals depending on platform source. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 8 | AmountOrigCurrency | decimal(16,6) | YES | Transaction amount in original currency. Passthrough from sub-platform tables. `-1` sentinel for MoneyFarm (original amount unavailable). Negative for withdrawals on TP. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 9 | FundingTypeID | int | YES | Payment method identifier. Passthrough from sub-platform tables. `-1` sentinel for MoneyFarm. JOIN to `DWH_dbo.Dim_FundingType` for name. `FundingTypeID = 27` triggers C2USD UPDATE for TP. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 10 | CurrencyID | int | YES | Currency identifier. Passthrough from sub-platform tables. `3` (GBP) hardcoded for MoneyFarm. JOIN to `DWH_dbo.Dim_Currency`. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 11 | Currency | varchar(20) | YES | Currency ISO code. Passthrough from sub-platform tables. `'GBP'` hardcoded for MoneyFarm. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 12 | IsPlatformFTD | int | YES | **Platform-level first-time deposit flag.** 1 = first deposit on this specific platform (TP, eMoney, Options, or MoneyFarm evaluated independently). Renamed from IsFTD in sub-platform tables. FTD recovery logic corrects missed FTDs for DateID >= 20250901. **Critical caveat:** 13K bad-FTD cohort (Aug 18-20 2025, $1 first deposits with no subsequent real deposit) excluded via REMOVE_BAD_FTDS CTE in Function_MIMO_First_Deposit_All_Platforms. (Tier 1 — Function_MIMO_First_Deposit_All_Platforms) |
| 13 | IsInternalTransfer | int | YES | Internal fund transfer flag. `ISNULL(f.IsInternalTransfer, 0)`. 1 = transfer between platforms (TP↔eMoney), not an external deposit/withdrawal. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 14 | IsRedeem | int | YES | eMoney redemption flag. `ISNULL(f.IsRedeem, 0)`. 1 = eMoney balance redeemed to bank account. Always 0 for Options/MoneyFarm. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 15 | IsTradeFromIBAN | int | YES | eMoney-initiated trade flag. `ISNULL(f.IsIBANTrade, 0)`. Renamed from `IsIBANTrade` in sub-platform tables. 1 = deposit originated from eMoney IBAN. Always 0 for Options/MoneyFarm. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 16 | MIMOPlatform | varchar(20) | YES | **Platform discriminator.** Values: `TradingPlatform` (main CFD/stocks platform), `eMoney` (IBAN/wallet deposits via the eMoney payment system), `Options` (US Options via Apex/Gatsby broker — full delete/re-insert every run due to unreliable data arrival), `MoneyFarm` (UK managed investment — FTD-only records, no withdrawals, AmountOrigCurrency=-1 sentinel). (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 17 | IsGlobalFTD | int | YES | **Cross-platform first-time deposit flag.** 1 = this specific deposit is the customer's very first across ALL platforms (TP, eMoney, Options, MoneyFarm). A deposit can be IsPlatformFTD=1 (first on eMoney) but IsGlobalFTD=0 if the customer already deposited on TP earlier. Function uses date-routed logic: old IBAN+TP union for FTDs before 2025-09-01; Dim_Customer-driven for FTDs on/after 2025-09-01. Excludes bad-FTD cohort. Updated by FTD recovery for DateID >= 20250901. (Tier 1 — Function_MIMO_First_Deposit_All_Platforms) |
| 18 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 19 | IsCryptoToFiat | int | YES | Crypto-to-fiat deposit flag. `ISNULL(f.IsCryptoToFiat, 0)` from sub-platform tables; additionally `UPDATE SET IsCryptoToFiat=1 WHERE FundingTypeID=27 AND MIMOPlatform='TradingPlatform' AND DateID >= 20250701`. Dual-source indicator. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 20 | IsRecurring | int | YES | Recurring deposit flag. `ISNULL(f.IsRecurring, 0)`. 1 = deposit made via recurring/auto-deposit feature. Always 0 for Options/MoneyFarm. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 21 | IsIBANQuickTransfer | int | YES | eMoney internal transfer flag (MoveMoneyReasonID = 6). `ISNULL(f.IsIBANQuickTransfer, 0)`. 1 = eMoney "Internal Transfer" feature (distinct from TP internal transfers). Always 0 for Options/MoneyFarm. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |

<!-- TABLEAU-SEMANTICS-COLS v2 -->
### Tableau-Discovered Column Semantics

_LLM-curated definitions extracted from downstream Tableau calc fields, mapped to specific wiki columns. Each item is a Tableau-side rule that adds semantic context to the column above; the wiki Element row itself is unchanged._

- **`FundingTypeID`** (`FundingTypeID 33 exclusion`) - FundingTypeID 33 is excluded from Trading Platform deposit and withdrawal calculations in the Net Deposits KPI, indicating it represents a non-cash or non-standard funding type that should not count toward real money movement on the Trading Platform. Formula: `FundingTypeID <> 33`. Workbook: *AML Clients – Trading & eMoney Net Deposits*.

_(auto-generated by `tools/tableau/judge_wiki_tableau_semantics.py`; safe to delete - regenerable)_
<!-- /TABLEAU-SEMANTICS-COLS -->


---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateID | Sub-platform tables | DateID | passthrough |
| RealCID | Sub-platform tables | RealCID | passthrough |
| MIMOAction | Sub-platform tables | MIMOAction | passthrough |
| TransactionID | Sub-platform tables | TransactionID | CAST to VARCHAR(50); 0 for Options/MoneyFarm |
| IsPlatformFTD | Sub-platform tables | IsFTD | rename + ISNULL + FTD recovery UPDATE |
| IsTradeFromIBAN | Sub-platform tables | IsIBANTrade | rename + ISNULL |
| MIMOPlatform | — | — | Literal per UNION branch |
| IsGlobalFTD | Function_MIMO_First_Deposit_All_Platforms | RealCID match | LEFT JOIN + CASE + FTD recovery UPDATE |
| IsCryptoToFiat | Sub-platform tables + FundingTypeID | IsCryptoToFiat | passthrough + UPDATE for FundingTypeID=27 |

### 5.2 ETL Pipeline

```
BI_DB_DDR_Fact_MIMO_Trading_Platform  ──┐
BI_DB_DDR_Fact_MIMO_eMoney_Platform   ──┤── UNION ALL → #globalMIMO
                                        │
BI_DB_DDR_Fact_MIMO_Options_Platform  ──┤── Separate DELETE/INSERT (full reload)
                                        │
Function_MIMO_First_Deposit_All_Platforms ── #globalFTDs (global FTD reference)
DWH_dbo.Dim_Customer                    ── MoneyFarm FTDs + FTD recovery
eMoney_dbo.eMoney_Fact_Transaction_Status── FTD recovery (eMoney)
  |
  |-- SP_DDR_Fact_Fact_MIMO_AllPlatforms(@date):
  |     LEFT JOIN globalFTDs → IsGlobalFTD
  |     DELETE/INSERT by DateID
  |     + DELETE ALL Options → re-INSERT
  |     + DELETE ALL MoneyFarm → INSERT FTD-only
  |     + UPDATE FTD recovery
  |     + UPDATE C2USD
  v
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (91.5M rows, transaction-level grain)
```

| Step | Object | Description |
|------|--------|-------------|
| Source 1 | BI_DB_DDR_Fact_MIMO_Trading_Platform | TP deposits & withdrawals (68.2M rows) |
| Source 2 | BI_DB_DDR_Fact_MIMO_eMoney_Platform | eMoney deposits & withdrawals (23.2M rows) |
| Source 3 | BI_DB_DDR_Fact_MIMO_Options_Platform | Options deposits & withdrawals (98K rows) |
| Source 4 | Function_MIMO_First_Deposit_All_Platforms | Cross-platform FTD reference |
| Source 5 | Dim_Customer | MoneyFarm FTDs + FTD recovery joins |
| ETL | SP_DDR_Fact_Fact_MIMO_AllPlatforms | UNION ALL + global FTD JOIN + platform-specific inserts + recovery UPDATEs |
| Target | BI_DB_DDR_Fact_MIMO_AllPlatforms | Unified MIMO fact table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method name |
| CurrencyID | DWH_dbo.Dim_Currency | Currency details |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | BI_DB_DDR_Fact_MIMO_AllPlatforms | Self-reference: function reads this table for existing MIMO data |
| BI_DB_dbo.BI_DB_V_DDR_MIMO_AllPlatforms | — | View for DDR reporting |
| BI_DB_dbo.Function_DDR_Aggregation_* | — | Aggregation functions for time-range rollups |
| BI_DB_dbo.BI_DB_DDR_CID_Level | — | CID-level daily DDR aggregation |

---

## 7. Sample Queries

### 7.1 Daily deposit volume by platform

```sql
SELECT DateID,
       MIMOPlatform,
       COUNT(*) AS DepositCount,
       SUM(AmountUSD) AS TotalUSD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
WHERE MIMOAction = 'Deposit'
  AND DateID BETWEEN 20260301 AND 20260309
GROUP BY DateID, MIMOPlatform
ORDER BY DateID, MIMOPlatform;
```

### 7.2 Global FTD count by platform and date

```sql
SELECT DateID,
       MIMOPlatform,
       COUNT(*) AS GlobalFTDs,
       SUM(AmountUSD) AS FTD_Amount_USD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
WHERE IsGlobalFTD = 1
  AND MIMOAction = 'Deposit'
  AND DateID BETWEEN 20260301 AND 20260309
GROUP BY DateID, MIMOPlatform
ORDER BY DateID, MIMOPlatform;
```

### 7.3 Customer MIMO timeline with payment method

```sql
SELECT m.DateID,
       m.MIMOAction,
       m.MIMOPlatform,
       m.AmountUSD,
       m.Currency,
       dft.FundingTypeName,
       m.IsPlatformFTD,
       m.IsGlobalFTD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms m
LEFT JOIN DWH_dbo.Dim_FundingType dft ON m.FundingTypeID = dft.FundingTypeID
WHERE m.RealCID = 12345678
ORDER BY m.DateID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | Type: Table | Production Source: Sub-platform MIMO tables + Function_MIMO_First_Deposit_All_Platforms*
