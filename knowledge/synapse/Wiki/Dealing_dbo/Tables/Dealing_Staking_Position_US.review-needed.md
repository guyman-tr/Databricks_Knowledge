# Review Needed — Dealing_Staking_Position_US

1. **IsPI and IsOptedIn_ETH always NULL**: DDL has these columns but SP inserts NULL. Confirm whether a future SP update plans to populate them, or if they should be removed from DDL.

2. **UK_Prohibited always 0**: Confirm this is intentional carryover from the global version DDL; safe to ignore for US queries.

3. **Excluded states scope**: Nevada and Hawaii excluded; Alabama was added (SR-337325) then removed (SR-339857). Confirm current excluded state list is exactly {Nevada, Hawaii}.

4. **IsRegulationEligible vs IsClientEligible**: The SP comments out `OR u.IsRegulationEligible = 0` from the IsClientEligible computation, meaning regulation filtering happens upstream in #Eligible_Pool_US (RegulationID=8 filter) rather than here. Confirm this is the intended design.

5. **GCID scope**: Opt-in/out is tracked at GCID level — a client's opt-out on one account affects all their accounts. Confirm this GCID-level logic is still correct for US regulatory compliance.
