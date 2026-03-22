---
object: Dealing_FailReasons
schema: Dealing_dbo
type: table
lineage_type: column
batch: 11
---

## Column Lineage — Dealing_FailReasons

Source SP: `Dealing_dbo.SP_CommissionsAndFails_PerCID`

### Column-Level Lineage

| Column | Source Expression | Source Table(s) | Tier |
|--------|-------------------|-----------------|------|
| Date | `@Date` parameter | SP parameter | 2 |
| FailReason | `FailReason2` from #Merge_Fails (CASE WHEN ... LIKE '%...%' THEN '...' ELSE 'Other' END applied to raw FailReason) | CopyFromLake.PositionFailReal_History_PositionFail_DWH | 2 |
| Count_Fails | `COUNT(*)` grouped by FailReason2, HedgeServerID | CopyFromLake.PositionFailReal_History_PositionFail_DWH | 2 |
| UpdateDate | `GETDATE()` | System timestamp | 2 |
| HedgeServerID | `hf.HedgeServerID` from PositionFailReal_History_PositionFail_DWH | CopyFromLake.PositionFailReal_History_PositionFail_DWH | 2 |

### Pipeline Flow

```
CopyFromLake.PositionFailReal_History_PositionFail_DWH
    (FailOccurred BETWEEN @Date AND @NextDate, excludes 'Open Open Position cannot be opened')
    + Dealing_staging.External_Etoro_Dictionary_FailType  (JOIN on FailTypeID)
    + DWH_dbo.Dim_Customer  (JOIN on CID — IsValidCustomer filter, player level lookup)
    + DWH_dbo.Dim_GuruStatus  (GuruStatus lookup)
    │
    ▼  #Fails  (all fails for @Date with customer metadata)
    ▼  #Merge_Fails  (+ standardized FailReason2 via LIKE patterns)
    ▼  #Fails_Data  (GROUP BY FailReason2, HedgeServerID → COUNT_Fails)
    │
    ▼
Dealing_dbo.Dealing_FailReasons
```

### FailReason Standardization Map

The 28 LIKE patterns (from SP code) map to these labels:
- `%insufficient funds%` / `%InsufficientFunds%` → `'Insufficient Funds for the Position'`
- `%Initial Leveraged Position Amount%` → `'Initial Leveraged Position Amount is Under the Minimum Defined'`
- `%blocked for editing%` → `'Instrument is Blocked for Editing'`
- `%in inactive state%` → `'Instrument is in Inactive State'`
- `%insufficient credit%` → `'Insufficient Credit'`
- `%exceeds User MaxLeverage%` → `'Exceeds User Max Leverage'`
- `%blocked for trading%` → `'User is blocked for trading'`
- `%MinPositionAmount%` → `'Min Position Amount'`
- `%pending for execution%` → `'The PositionID is pending for execution'`
- `%Unable to retrieve%` → `'Unable to retrieve position data'`
- `%DB failure%` → `'DB failure'`
- `%Error hedging for closing position%` → `'Error hedging for closing position'`
- `%opening position is disallowed%` → `'opening position is disallowed'`
- `%Restricted By SmartCopy%` → `'Restricted By SmartCopy'`
- `%Initial Position Amount is under the minimum defined in the system%` → `'Initial Position Amount is under the minimum defined in the system'`
- `%TPS validation%` → `'TPS validation'`
- `%LimitRatePips is less than 1%` → `'LimitRatePips is less than 1'`
- `%StopRatePips is less than 1%` → `'StopRatePips is less than 1'`
- `%Max exposure limit reached%` → `'Max exposure limit reached'`
- `%Order already executed or cancelled%` → `'Order already executed or cancelled'`
- `%position units is higher then the allowed%` → `'position units is higher then the allowed'`
- `%PositionHedgeClose%` or `%PositionHedgeOpen%` → `'HedgeFailReasin (Open or Close)'`
- `%SL and TP values are invalid%` → `'SL and TP values are invalid'`
- `%Trade range exceeded%` → `'Trade range exceeded'`
- `%W8Ben validations failed%` → `'W8Ben validations failed'`
- `%Blocked from CFD Validation Settings%` → `'Blocked from CFD Validation Settings'`
- `%Take Profit%` → `'Error editing Take Profit'`
- `%Stop Loss%` → `'Error editing Stop Loss'`
- Unmatched → `'Other'`
- Excluded: `%Open Open Position cannot be opened%`
