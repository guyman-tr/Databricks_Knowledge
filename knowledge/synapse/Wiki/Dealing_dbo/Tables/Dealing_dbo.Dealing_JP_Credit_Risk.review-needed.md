# Review: Dealing_dbo.Dealing_JP_Credit_Risk

## Unverified Claims
1. **Fivetran HS mapping**: Assumed `External_Fivetran_dealing_active_hs_mappings` correctly identifies all JPM servers — confirm completeness
2. **FULL OUTER JOIN**: This means rows can exist where either Clients_NOP or LP_NOP is NULL — confirm this is intentional

## Questions for Domain Expert
1. How many distinct HedgeServerIDs does JPM currently have?
2. Is the FULL OUTER JOIN (vs inner join in GS variant) a deliberate design choice to capture LP-only exposure?

## Reviewer Corrections
_(none yet)_
