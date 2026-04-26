# BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData — Review Items

> Items requiring human review, schema investigation, or cross-team confirmation. Generated during Batch 68 documentation (2026-04-23).

---

## HIGH PRIORITY

### 1. Revenue_Total vs Revenue_Total_New — Which Is Active for Reporting?

**Issue**: Two parallel total revenue columns exist:
- `Revenue_Total` (col 77, `money`): Legacy formula — FullCommissions only. Populated since 2019.
- `Revenue_Total_New` (col 187, `decimal(38,2)`): New formula — FullCommissions + AdminFee + TicketFees + ConversionFees + SpotAdjustFee + TicketFeeByPercent. Added by Or Filizer (2025).

**Concern**: Historical rows before 2025 will have `Revenue_Total_New` = 0 or NULL for the additional fee components. Pre-2025 `Revenue_Total_New` may understate revenue compared to `Revenue_Total` for periods when function fees were not tracked. Is there a cutover date after which `Revenue_Total` is no longer maintained? What is the official reporting column for finance KPIs?

**Action needed**: Confirm with Or Filizer or BI team: (a) is Revenue_Total still maintained/updated after the 2025 change, or is it frozen? (b) what is the cutover date for Revenue_Total_New to be considered complete/accurate?

---

### 2. Lev1/LevCFD Flag Columns Stored as [money] Type — DDL Mismatch

**Issue**: The following columns are semantically binary flags (0 or 1) but are declared as `[money]` type in the DDL:
- `Active_Real_Stocks_Lev1`, `Active_CFD_Stocks_LevCFD`, `Active_Real_Crypto_Lev1`, `Active_CFD_Crypto_LevCFD`
- `ActiveOpen_Real_Stocks_Lev1`, `ActiveOpen_CFD_Stocks_LevCFD`, `ActiveOpen_Real_Crypto_Lev1`, `ActiveOpen_CFD_Crypto_LevCFD`
- `NewTrades_Real_Stocks_Lev1`, `NewTrades_CFD_Stocks_LevCFD`, `NewTrades_Real_Crypto_Lev1`, `NewTrades_CFD_Crypto_LevCFD`

Observed values in live data: `0.0000` or `1.0000` — confirming these are flags masquerading as money.

Note: `AmountIn_NewTrades_*_Lev1/LevCFD` correctly use `[money]` as they represent USD amounts, not flags.

**Concern**: Any query that sums these flag columns (e.g., `SUM(Active_Real_Stocks_Lev1)`) behaves correctly, but the column type implies a monetary value which may mislead analysts.

**Action needed**: Flag as a known schema quirk. Confirm whether a DDL correction is planned or whether analysts should be warned in documentation.

---

### 3. Duplicate #Cashier Definition in SP (Dead Code / Correctness Risk)

**Issue**: In `SP_CID_MonthlyPanel_FullData`, the `#Cashier` temp table is defined TWICE in the stored procedure:
- **First definition** (earlier in SP): Filters using `DateID = @startDateINT` (single-day window) — WRONG for a monthly panel
- **Second definition** (later in SP, lines ~915–931): Filters using `DateID BETWEEN @startDateINT AND @endDateINT` (full month window) — CORRECT

The second definition overwrites the first, so the final behavior is correct (full month window wins). However:
1. The first definition is dead code that is never used — it creates an unnecessary temp table that gets immediately dropped
2. If someone adds logic between the two definitions in a future SP change, they might unknowingly use the first (incorrect) #Cashier

**Action needed**: Remove the first (dead-code) `#Cashier` definition in a scheduled SP cleanup. No data impact in the current version, but a maintenance risk.

---

## MEDIUM PRIORITY

### 4. EOM_IsFunded (col 114) vs IsEOM_Funded_NEW (col 170) — Relationship Unclear

**Issue**: Two columns track end-of-month funded status with similar but potentially different semantics:
- `EOM_IsFunded` (col 114, `tinyint`): Legacy funded flag from `Fact_SnapshotCustomer` snapshot
- `IsEOM_Funded_NEW` (col 170, `tinyint`): New funded definition at EOM (SP assigns `CID.EOM_IsFunded_NEW`)

**Concern**: The relationship between these two columns is not fully documented. Do they differ? For which customers? Which one matches `IsFunded_New` (col 158)?

**Action needed**: Clarify with the BI team: (a) what is the exact definition of the "new" funded status? (b) are EOM_IsFunded and IsEOM_Funded_NEW ever different for the same CID/month? (c) is EOM_IsFunded now deprecated in favor of IsEOM_Funded_NEW?

---

### 5. LTV Columns Always 0 — SP_LTV_BI_Actual Scheduling Unclear

**Issue**: `SP_CID_MonthlyPanel_FullData` hardcodes all 6 LTV columns to `0` (to avoid a circular SP dependency loop). `SP_LTV_BI_Actual` runs separately and UPDATEs these columns. 

**Concern**: The OpsDB scheduling relationship between `SP_CID_MonthlyPanel_FullData` (Priority 0) and `SP_LTV_BI_Actual` is not confirmed. If `SP_LTV_BI_Actual` is not scheduled or has failed, LTV columns will show all-zero values silently.

**Action needed**: Confirm in OpsDB that `SP_LTV_BI_Actual` runs after `SP_CID_MonthlyPanel_FullData` on a monthly schedule, and verify LTV columns are non-zero for at least the last 3 closed months.

---

### 6. EOM_Segment Always NULL

**Issue**: `EOM_Segment` (col 29, `varchar(50)`) is always NULL in practice. In the SP INSERT, it is assigned the `EOM_Segment` field from `#CIDs`, but analysis of live data (April 2026 slice, 10-row sample) confirms NULL for all rows observed.

**Concern**: This column may be a reserved placeholder from a planned segmentation feature that was never implemented, or a feature that was removed but the column was kept for schema compatibility.

**Action needed**: Confirm whether `EOM_Segment` will ever be populated. If not, flag as permanently NULL/deprecated in documentation and exclude from dashboards.

---

### 7. TotalCoFee Definition

**Issue**: `TotalCoFee` column name is ambiguous. Could be interpreted as:
- **Copy-out fee** — fee charged when a customer stops copying a trader
- **Cashout fee** — fee charged on withdrawal transactions

In eToro's codebase, "Co" prefix often indicates "Copy". The column appears in the #Cashier temp table context (billing data), which could support either interpretation.

**Action needed**: Confirm the exact business definition of TotalCoFee with the BI/finance team. Update the column description in this wiki once confirmed.

---

## LOW PRIORITY

### 8. A_Revenue_Equities vs A_ACC_Revenue_Equities Naming Inconsistency

**Issue**: The SP produces `A_ACCRevenue_Equities` (no underscore before Revenue, line 1341 alias: `A_ACCRevenue_Equities`) but the actual DDL column is `A_ACC_Revenue_Equities` (with underscore). The SP uses position-based INSERT so the actual column name in the DDL is what matters — the alias does not. However, the inconsistency is confusing for SP readers.

**Action needed**: Document as a known SP alias inconsistency. The correct column name is `A_ACC_Revenue_Equities` (with underscore) as defined in the DDL.

---

### 9. CountryID Populated via POST-INSERT or Main INSERT?

**Issue**: `CountryID` (col 172) is assigned in the main INSERT as `CID.CountryID` from the `#CIDs` temp table. However, `LastAMLTicketDate`, `IsChurn_ThisM`, and `IsWB_ThisM` at positions 173–175 are inserted as NULL and updated via POST-INSERT UPDATEs. The 3 NULL positions at lines 1347–1349 of the SP map to these three POST-UPDATE columns.

**No action required**: This mapping is confirmed correct. Documenting for future SP readers.

---

### 10. Active_Month Trailing Space

**Issue**: `Active_Month` is `char(7)` but the YYYY-MM format is 7 characters (e.g., '202604 ' with 1 trailing space). The trailing space is by design (char type right-pads to declared length). Filtering on `Active_Month = '202604'` will fail (6-char literal vs 7-char column).

**Action needed**: Ensure all queries use `ActiveDate` (DATE type, first day of month) rather than `Active_Month` for filtering. `Active_Month` is provided for display/grouping only. This is documented in Section 3 but worth repeating here for awareness.

---

*Documentation batch: 68 | Date: 2026-04-23 | Documented by: Claude (claude-sonnet-4-6)*
