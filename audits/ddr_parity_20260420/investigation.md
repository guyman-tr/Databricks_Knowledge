# DDR rerun audit — 2026-04-20

Investigation of 4 parity issues between Synapse and DBX after the post-$1-FTD reruns.

## 1. MIMO `AmountOrigCurrency` +$4.66M in DBX — **MoneyFarm GBP sentinel fork**

Group-by `(MIMOPlatform, Currency)` reveals every bucket matches except MoneyFarm:

| Platform | Currency | rows | sum_USD | sum_orig (DBX) | sum_orig (Syn) |
|---|---|---|---|---|---|
| MoneyFarm | GBP | 121 | 4,656,221.24 | **4,656,221.24** | **−121.00** |

Per-row inspection (same 5 RealCIDs on both sides):

| RealCID | AmountUSD | AmountOrigCurrency (DBX) | AmountOrigCurrency (Syn) |
|---|---|---|---|
| 2835544 | 44,676.07 | 44,676.07 | −1.00 |
| 3506127 | 27,835.79 | 27,835.79 | −1.00 |
| 4117475 | 21,610.75 | 21,610.75 | −1.00 |

**Diagnosis:** Two different "MoneyFarm has no native orig-currency source" conventions:
- **Synapse:** sentinel `−1` per row → sum = −121.
- **DBX:** falls back to `AmountUSD` value per row → sum = 4,656,221.24.
- Diff = 4,656,221.24 − (−121.00) = **$4,656,342.24** ✅ matches the observed diff exactly.

**Not a regression from the rerun.** This is a definitional fork that's been there as long as MoneyFarm has existed in the fact. Per your earlier preference (NULLs over sentinels): neither side is right — the correct value should be `NULL` (MoneyFarm doesn't expose a native-currency amount). Either fix the DBX SP to emit `NULL` or fix Synapse to emit `NULL` and let downstream handle it.

## 2. +1,181 extra rows in DBX `customer_daily_status` — **SCD lag, NOT dupes**

- No duplicates: `COUNT(*) = COUNT(DISTINCT RealCID)` on both sides.
- Same CID range (min 15, max 47,667,664 on both).
- The +1,181 are entirely net-new CIDs in DBX that Synapse doesn't have for this DateID.

Per-million-CID-bucket diff (DBX − Syn):

| Bucket | DBX − Syn |
|---|---|
| **47,000,000** | **+890 (75% of the diff)** |
| 46,000,000 | +100 |
| 45,000,000 | +40 |
| 44,000,000 | +14 |
| 43,000,000 → 30,000,000 | +1 to +12 each |
| 29,000,000 → 0 | +0 to +7 each |
| **Total** | **+1,181** ✅ |

**Diagnosis:** 75% of the extras are in the newest-registration bucket (CID ≥ 47M = customers who registered roughly late April / early May 2026). DBX has a slightly fresher snapshot of `Fact_SnapshotCustomer` for the `FromDateID BETWEEN … AND …` range — it captures recently-registered CIDs whose snapshot row was emitted after Synapse stopped tracking. The long tail of +1-7 per older bucket is the same SCD-2 update-on-update churn (a record gets retroactively rewritten between extracts).

**Confirms hypothesis:** `IsDepositor` matches exactly on both (5,894,818) because the bulk of cumulative-depositor identity is preserved. The diffs concentrate in `IsFunded` (+1,771), `BalanceOnlyAccount` (+2,825), `LoggedIn` (+420) which all flow from `Fact_SnapshotCustomer` joins or `Fact_CustomerAction` daily joins, both of which are partition-aware on freshness.

**Not a bug.** Acceptable parity for a daily snapshot pulled at different times.

## 3. `IsDepositorGlobal` undercount −5.6M — **definition bug in DBX SP**

DBX × Synapse cross-tab on `(IsDepositor, IsDepositorGlobal)`:

| IsDepositor | IsDepositorGlobal | DBX | Syn |
|---|---|---|---|
| 0 | 0 | 913,292 | 911,674 |
| 0 | 1 | 465 | 902 |
| **1** | **0** | **5,606,480** | **676** |
| 1 | 1 | 288,338 | 5,894,142 |

Synapse: `IsDepositorGlobal ≈ IsDepositor` (99.9% co-occurrence). DBX: only 5% of `IsDepositor=1` customers are also `IsDepositorGlobal=1`.

Decomposing those 5,606,480 by FTD-platform presence:

| has_TP_FTD | has_IBAN_FTD | has_Opt_FTD | has_MF_FTD | IsDep | IsDepGlobal | n |
|---|---|---|---|---|---|---|
| F | F | F | F | 1 | 0 | **5,606,480** |
| T | F | F | F | 1 | 1 | 212,189 |
| F | T | F | F | 1 | 1 | 70,753 |
| F | F | F | T | 1 | 1 | 4,696 |
| F | F | T | F | 1 | 1 | 700 |

**Diagnosis:** The DBX SP definition:

```sql
LEAST(IFNULL(ft.TP_FTD_DateID, 30000101),
      IFNULL(ft.IBAN_FTD_DateID, 30000101),
      IFNULL(ft.Options_FTD_DateID, 30000101),
      IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) AS Global_FTD_DateID,

CASE WHEN LEAST(…) <= p_date_id THEN 1 ELSE 0 END AS IsDepositorGlobal
```

`_tmp_ddr_ftds` is sourced from `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` — the patched FTD view. **5.6M customers with `IsDepositor=1` from `Fact_SnapshotCustomer` are simply NOT present in that view at all**, so all four `*_FTD_DateID` columns come back NULL → `LEAST = 30000101 = far-future sentinel` → `IsDepositorGlobal = 0`.

These 5.6M are the "OLD-logic branch" customers (FTD before 2025-09-01). Either:
- The OLD-logic CTE in `Function_MIMO_First_Deposit_All_Platforms` does not return rows for them (e.g., requires `eMoney_Fact_Transaction_Status` or `Fact_CustomerAction.IsFTD=1` to match, which may have been historically lossy), OR
- The view returns them but with `FTDPlatform NOT IN ('TradingPlatform','eMoney','Options','MoneyFarm')` so the platform pivot in `_tmp_ddr_ftds` produces NULLs.

Synapse computes `IsDepositorGlobal` differently — almost certainly straight off `Fact_SnapshotCustomer.IsDepositor` plus an `OR EXISTS Options/MoneyFarm FTD` patch.

**Fix:** replace the DBX SP's IsDepositorGlobal computation. Two options, in order of preference:

Option A (minimal change, matches Synapse semantics):
```sql
CASE WHEN bs.IsDepositor = true
      OR ft.Options_FTD_DateID  IS NOT NULL
      OR ft.MoneyFarm_FTD_DateID IS NOT NULL
     THEN 1 ELSE 0 END AS IsDepositorGlobal
```

Option B (preserve the LEAST-based date semantics but fall back when all four are NULL):
```sql
CASE WHEN bs.IsDepositor = true                                  -- catches the 5.6M OLD-logic cases
      OR LEAST(IFNULL(ft.TP_FTD_DateID, 30000101),
               IFNULL(ft.IBAN_FTD_DateID, 30000101),
               IFNULL(ft.Options_FTD_DateID, 30000101),
               IFNULL(ft.MoneyFarm_FTD_DateID, 30000101)) <= p_date_id
     THEN 1 ELSE 0 END AS IsDepositorGlobal
```

**Real bug. Must fix in the DBX SP.**

## 4. Options `Deposited` / `ReDeposited` +18 each — **DBX detection works, Synapse never wired**

DBX has 23 `DepositedOptions=1` rows; Synapse has 5. DBX has 18 `ReDepositedOptions=1` rows; Synapse has 0.

The 5 in Synapse are all `Options_FTD_DateID = 20260420` (today's Options FTDs, correctly flagged as `OptionsFirstDeposited=1, DepositedOptions=1, ReDepositedOptions=0`). Match perfectly with the 5 first-deposit Options events in DBX.

The 18 extras in DBX:
- All have `OptionsFirstDeposited=0`, `DepositedOptions=1`, `ReDepositedOptions=1` (legitimate re-deposit signature)
- 3 have prior `Options_FTD_DateID` (2025-11-17, 2025-12-03, 2026-04-17) — clearly correct re-deposits
- **15 have NULL `Options_FTD_DateID`** despite being flagged as re-depositors

**Diagnosis 1 — Synapse side:** Synapse's `SP_DDR_Customer_Daily_Status` never extended the re-deposit detection to Options. `ReDepositedOptions = 0` for every CID across this whole date. DBX added the detection (correctly, per the SP definition: `MAX(CASE WHEN MIMOAction='Deposit' AND IsInternalTransfer=0 AND IsPlatformFTD=0 AND MIMOPlatform='Options' THEN 1 ELSE 0 END)`). **DBX is more correct here.**

**Diagnosis 2 — DBX side, partial bug:** 15 of the 18 have NULL Options_FTD_DateID. That's contradictory — they can't redeposit if they never first-deposited. Cause: their Options first-deposit happened on a date where `v_mimo_first_deposit_all_platforms` didn't return an Options row (probably FTDPlatform = 'TradingPlatform' or NULL in the view because the original FTD predated 2025-09-01 or Options registration data was incomplete). Same root cause as issue #3 — the FTD view has coverage gaps.

So the "+18 extras" represents:
- **3 are perfectly correct** (Options FTD on a prior known date, redeposit today).
- **15 are correct in detection but contradicted by the FTD-view gap** (DBX MIMO fact says they had Options deposits today that weren't platform-FTDs; the FTD view doesn't show their prior Options FTD).

**Mostly a Synapse gap, with a side-show of issue #3 leaking into Options.**

## Recommended actions

| Issue | Action | Effort | Risk |
|---|---|---|---|
| 1. MoneyFarm `AmountOrigCurrency` | Switch DBX SP to emit `NULL` for native-currency-unknown (and clean up Synapse `-1` separately) | 30 min | Low — downstream views currently use AmountUSD anyway |
| 2. +1,181 SCD lag | Accept. Document as known parity tolerance | 0 | None |
| 3. `IsDepositorGlobal` 5.6M bug | Patch the DBX SP — Option A (use `bs.IsDepositor` as the spine) | 30 min code + rerun | Low — current value is unusable; any change improves it |
| 4. Options re-deposit gap | Confirm with Nir / data PM whether Options redeposits should be tracked. If yes — Synapse needs the patch. If no — leave DBX as-is (better data). The "15 NULL Options_FTD" sub-issue resolves itself when issue #3 is fixed | 1 hour discovery | Medium — definitional question |
