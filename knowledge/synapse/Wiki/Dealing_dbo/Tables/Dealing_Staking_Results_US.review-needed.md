# Review Needed — Dealing_Staking_Results_US

1. **Post-execution columns** (AirdropID, AirdropOccurred, IsAirdropSuccess, FailReasonID, ActualAirdropUnits): Confirm which system updates these after the airdrop executes (Apex broker system or internal pipeline). What is the typical delay between SP_Staking_US run and airdrop execution?

2. **Cash-equivalent countries**: Confirm current list of IsCashEquivalentCountry=1 countries in the US program. Global version had Hungary + 6 others. US may have a different set.

3. **ClubCategory groupings**: The SP uses Bronze / Silver+Gold+Platinum / Diamond+Platinum Plus. Confirm this tripartite grouping matches the current US $1 minimum threshold policy.

4. **GCID vs CID**: Results_US has both. Confirm use case — is CID or GCID the authoritative join key for downstream US reporting?
