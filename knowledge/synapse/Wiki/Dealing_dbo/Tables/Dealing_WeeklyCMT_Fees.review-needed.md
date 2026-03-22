# Review Notes — Dealing_dbo.Dealing_WeeklyCMT_Fees

**Status**: STALE ⚠️ (~36 months stale; last data 2023-04-09; program appears discontinued)

## Items Requiring Human Review

1. **Program appears discontinued**: The underlying population of pre-2021 leveraged long crypto positions (OpenDateID <= 20210108) is effectively exhausted — no positions meeting this criterion remain open. Confirm whether the table should be formally decommissioned or retained as a historical archive.

2. **No OpsDB entry**: `SP_Crypto_CMT_Fees` is not tracked in OpsDB/SB_Daily. Even if the program were reactivated, there is no automated scheduling mechanism. Confirm whether this was always manually triggered or was removed from scheduling.

3. **Sunday-only execution gate**: The SP silently does nothing if called on a non-Sunday (`DATENAME(WEEKDAY, @Date) != 'Sunday'`). This is a subtle behavior that can cause confusion if the SP is called for diagnostics. Confirm that any future callers are aware of this gate.

4. **StopRate ≤ pip threshold filter**: Only positions with StopRate at or below the instrument's pip value are included. This is an unusual filter suggesting these positions are "effectively stopped out" but haven't formally triggered. Confirm whether this definition is still correct and aligned with current risk management practice.

5. **HEAP storage**: The table has no clustered index (HEAP). For a historical archive with 54K rows this is acceptable, but any reactivation would benefit from adding a clustered index on `EndDate` for efficient date-range queries.
