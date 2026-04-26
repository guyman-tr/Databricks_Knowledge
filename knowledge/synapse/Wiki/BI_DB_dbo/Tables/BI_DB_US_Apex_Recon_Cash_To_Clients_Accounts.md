# BI_DB_US_Apex_Recon_Cash_To_Clients_Accounts

**Schema:** BI_DB_dbo  
**Type:** Table  
**Distribution:** ROUND_ROBIN  
**Index:** CLUSTERED INDEX (ProcessDate ASC)  
**Writer SP:** `SP_US_Apex_Recon_Cash_To_Clients_Accounts`  
**Author:** Artyom Bogomolsky (2021-09-29)  
**Frequency:** Daily (SB_Daily, Priority 20)

---

## 1. Summary

Daily reconciliation table for US customer Apex Clearing accounts. Each row represents one Apex account's trading activity on a given day, cross-referencing three independent data sources: cash journal entries from Apex (EXT869), net trading activity from Apex (EXT872), and internal eToro fund-of-funds (FOF) transfers from ExternalOperations. Also includes the intraday High Water Mark (HWM) — the maximum cumulative net trade equity reached during the day.

Used by the US regulatory and reconciliation team to verify that cash flows, trading, and fund transfers are consistent across eToro's Apex Clearing integration.

---

## 2. Business Context

- **Domain**: US equities / Apex Clearing reconciliation
- **Purpose**: Cross-validate three independent data streams (Apex cash journals, Apex trade records, eToro ExternalOperations fund transfers) at the account-day level. Discrepancies between CashFlowAmount, Trade_Amount, and FOFAmount surface reconciliation breaks.
- **Population**: Apex Clearing accounts with trade activity on the given day. Driver is EXT872 (trade records) — accounts with only journal entries but no trades are not included.
- **Exclusions**: AccountNumber='3ET00001' (MSB/Money Service Business account) is explicitly excluded.
- **Producers**: `SP_US_Apex_Recon_Cash_To_Clients_Accounts` (Artyom Bogomolsky, 2021-09-29).
- **Consumers**: US regulatory reporting, Apex reconciliation workflows, compliance monitoring.

**Scale**: ~853K rows (2021-09-22 to 2026-04-10). ~1,041 distinct dates; 58,668 distinct Apex accounts; 51,162 with eToro CID mapping.

---

## 3. Column Descriptions

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | AccountNumber | varchar(40) | NOT NULL | Apex Clearing account identifier (e.g., "3ET76387", "5GU18555"). Primary key for Apex accounts. Format prefixes vary (3ET=standard US retail, 5GU=institutional/sub-account). Driver column — every row has a trade record in EXT872. MSB account '3ET00001' excluded. (Tier 2 — External_Sodreconciliation_apex_EXT872_TradeActivity) |
| 2 | CID | int | YES | eToro customer ID — platform-internal identifier. Sourced from External_USABroker_Apex_UserData via GCID join on ApexData. NULL for ~21% of rows where the Apex account is not linked to an eToro customer (institutional accounts, sub-accounts, unmapped 5GU-prefix accounts). (Tier 2 — External_USABroker_Apex_UserData) |
| 3 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. Sourced from External_USABroker_Apex_UserData. NULL when Apex account is not linked to an eToro customer. (Tier 1 — DWH_dbo.Dim_Customer concept) |
| 4 | ProcessDate | date | NOT NULL | Trading day this reconciliation row covers. Equals the @Date SP input parameter. Clustered index column — primary query key for date-based filtering. |
| 5 | CashFlowAmount | money | YES | Cash journal amount for this account on ProcessDate from Apex EXT869 (format 869). Aggregated as SUM(Amount) where TerminalID='OMJNL', Description='Journal from'. Always negative when present (represents cash credited/journaled into the account). NULL for ~49% of rows — accounts with trade activity but no journal entry that day. (Tier 2 — External_Sodreconciliation_apex_EXT869_CashActivity) |
| 6 | Trade_Amount | money | YES | Net trading amount for this account on ProcessDate from Apex EXT872 (format 872). Aggregated as SUM(NetAmount) across all trades. Net of buys and sells — can be positive (net buys) or negative (net sells). The driver field: every row has EXT872 data; NULL only for data anomalies. (Tier 2 — External_Sodreconciliation_apex_EXT872_TradeActivity.NetAmount) |
| 7 | FOFAmount | money | YES | Fund-of-funds transfer amount for this account on ProcessDate from eToro's internal ExternalOperations funding log. Aggregated as SUM(AggregatedAmount) from UserTransactionsAggregation. Represents internal transfers between eToro BD and the Apex account. NULL for ~45% of rows — accounts without an internal fund transfer on that day. (Tier 2 — External_ExternalOperations_Funding_UserTransactionsAggregation) |
| 8 | HWM | money | YES | High Water Mark — the maximum cumulative net trading equity reached during intraday trading. Computed by ordering EXT872 trades by ExecutionTime, building a running sum of NetAmount (BuySellCode IN ('B','S')), then taking MAX(running sum). Only populated when MAX(running sum) > 0 (HAVING clause). NULL for ~28% of rows — accounts whose cumulative net never exceeded zero during the day. Always non-negative when present. (Tier 2 — SP_US_Apex_Recon_Cash_To_Clients_Accounts, computed from EXT872) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Always set to GETDATE() at ETL run time. |

---

## 4. Distribution & Partitioning

- **Distribution**: ROUND_ROBIN — no hash key; rows spread evenly across distributions.
- **Index**: CLUSTERED INDEX on ProcessDate ASC — optimized for daily DELETE+INSERT ETL pattern and date-range scans.
- **ETL Pattern**: DELETE WHERE ProcessDate=@Date → INSERT SELECT from #final. Single-date replace.

---

## 5. Relationships

**Upstream (inputs to this table):**

| Source Table | Join Type | Role |
|---|---|---|
| `External_Sodreconciliation_apex_EXT872_TradeActivity` | INNER (driver) | All output rows anchored here; provides AccountNumber, ProcessDate, Trade_Amount |
| `External_Sodreconciliation_apex_EXT869_CashActivity` | LEFT JOIN | Cash journals (EXT869): CashFlowAmount |
| `External_Sodreconciliation_apex_SodFiles` | INNER | File validation: ensures most recent Status=2 import file is used |
| `External_ExternalOperations_Funding_MoneyTransferRequestLog` | LEFT JOIN | FOF transfer log: links AggregationID to CID |
| `External_ExternalOperations_Funding_UserTransactionsAggregation` | LEFT JOIN | FOF amounts: provides FOFAmount |
| `External_USABroker_Apex_ApexData` | LEFT JOIN | Apex account → GCID mapping |
| `External_USABroker_Apex_UserData` | LEFT JOIN | GCID → CID/GCID for eToro customer identity |

**Downstream (tables that read from this table):**
- US regulatory reconciliation reports
- Apex compliance monitoring
- No confirmed downstream SP references found in BI_DB_dbo SP set.

---

## 6. ETL & Lifecycle

- **Frequency**: Daily, run via SB_Daily scheduler.
- **Priority**: 20 (third wave — depends on Priority 0 staging loads from Apex external tables).
- **ProcessType**: 1 (SQL stored procedure).
- **Backfill**: Single-date pattern; rerun SP with specific @Date to refresh that day.
- **File validation**: SP selects the most recently imported Apex files for @Date (max ImportEndDate, Status=2) to handle multiple daily file deliveries.
- **Data start**: 2021-09-22 (Apex Clearing integration launch).
- **Latest data**: 2026-04-10 (confirmed via live Synapse query).

---

## 7. Known Caveats & Gotchas

- **EXT872 is the driver**: Only accounts with trade records appear. Accounts with EXT869 journal entries only (no trades) are NOT in this table.
- **Trade_Amount was changed**: Originally captured Buy Amount only; changed 2021-10-13 to Net Amount (buys + sells net). Historical rows before this date may represent buy-only figures.
- **CashFlowAmount is always negative**: This is by design — represents cash being journaled (credited) into the account from Apex's perspective. A NULL means no journal entry was recorded for that account that day.
- **HWM requires positive cumulative**: The HAVING MAX > 0 clause means accounts with net negative trading throughout the day have NULL HWM. This is expected behavior.
- **5GU-prefix accounts**: These appear to be institutional or sub-accounts that lack CID/GCID mapping. They account for most of the NULL CID rows (180,742, ~21%).
- **MSB account excluded**: AccountNumber='3ET00001' is explicitly excluded from the INSERT — this is eToro's internal Money Service Business account used for operational purposes, not a customer account.
- **Collation sensitivity**: Multiple JOINs use COLLATE SQL_Latin1_General_CP1_CI_AS to handle potential collation mismatches between EXT tables.

---

## 8. Sample Data (2026-04-10)

| AccountNumber | CID | ProcessDate | CashFlowAmount | Trade_Amount | FOFAmount | HWM |
|---|---|---|---|---|---|---|
| 3ET76387 | 18180249 | 2026-04-10 | -99,531.20 | 99,531.17 | 99,531.20 | 99,531.17 |
| 3ET10413 | 25881623 | 2026-04-10 | -74,998.31 | 74,998.30 | 74,998.31 | 74,998.30 |
| 3EW95384 | 34950503 | 2026-04-10 | -13,999.75 | -69.16 | 13,999.75 | 13,999.73 |
| 5GU18555 | NULL | 2026-04-10 | NULL | 22,273.74 | NULL | 22,273.74 |

Note: 3EW95384 shows Trade_Amount=-69.16 (net sells) while CashFlowAmount=-13,999.75 and HWM=13,999.73 — the HWM captures the peak equity reached earlier in the day before the net sell-down.
