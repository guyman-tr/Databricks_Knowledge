# Review Needed — Dealing_Staking_OptedOut_PerCID_US

## Open Questions

1. **Country column naming**: The `Country` column stores US state names (e.g., "Massachusetts", "Texas"), not countries. This is a known legacy naming issue. Confirm whether a rename or alias is planned, or if downstream consumers rely on the column name `Country`.

2. **SUI inclusion**: SUI (InstrumentID=100340) was added to OptedOut_PerCID_US starting 2026-02-26, but does not yet appear in Dealing_Staking_Position_US or Dealing_Staking_Results_US (which only have 3 instruments). Confirm whether SUI will be added to Position_US and Results_US once Distribution_StartDate (2026-04-01) passes, or if these tables are intentionally scoped to distributing instruments only.

3. **IntroDays not stored here**: This table does not capture whether a client has met the IntroDays holding period (that logic lives in SP_Staking_US → Position_US). Confirm whether daily opt-in monitoring (OptedOut_PerCID_US) is considered independent of the IntroDays eligibility gate.

4. **ETH opt-in rate 4.4%**: On 2026-03-10, only ~1,160 of 26,084 eligible ETH clients are opted in. Is this expected? Confirm whether there is any effort to increase ETH opt-in participation, or whether the default opt-OUT behavior for ETH is a permanent regulatory design choice.
