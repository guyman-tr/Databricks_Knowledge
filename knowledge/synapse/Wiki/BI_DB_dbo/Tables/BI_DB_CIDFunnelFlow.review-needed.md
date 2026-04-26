# Review Needed: BI_DB_dbo.BI_DB_CIDFunnelFlow

## Items Requiring Human Review

### Tier 4 / Low-Confidence Items

None — all 37 columns are Tier 2 with clear SP code traceability.

### Questions for Reviewers

1. **POA_POI_Phone orphan column**: The DDL defines `[POA_POI_Phone] [int] NULL` but SP_CIDFunnelFlow never inserts a value — always NULL. The commented-out `#POAPOI` block in the SP suggests a broader document verification approach was planned. Is this column intentionally unused, or is it a bug/regression? Should it be removed from the DDL, or is there a plan to implement it?

2. **FunnelFrom vs Funnel duplication**: Both columns resolve to Dim_Funnel.Name for the same FunnelFromID — they contain identical values in practice. FunnelFrom is resolved in the #POP staging table; Funnel is re-resolved in the main query. Is this intentional (e.g., do they ever differ for a specific customer class)? Should one be deprecated?

3. **DesignatedRegulation RANK=1 edge case**: The DesignatedRegulation logic takes the earliest Fact_SnapshotCustomer record with non-null DesignatedRegulationID on or after the customer's registration date. If a customer has no Fact_SnapshotCustomer record at all (e.g., very new customers not yet snapshotted), DesignatedRegulation will be NULL. How frequently does this occur? Should it fall back to the current RegulationID?

4. **ConvOver96H when FTD=0**: When FirstDepositDate = '19000101' (sentinel for no deposit), DATEDIFF(hh, RegisteredReal, '19000101') produces a large negative number, which fails the > 96 check — correctly setting ConvOver96H=0. This is the intended behavior, but should this column be documented as only interpretable for FTD=1 customers, or is the 0-for-non-converters behavior actively relied upon in reports?

5. **Rolling window churn**: On each daily run, customers registered exactly 12 months ago age out of the table (approximately 12K per day). Historical cohort funnel rates are therefore unavailable from this table alone. Is there a separate historical snapshot table or archive for pre-12-month cohorts? If not, does this limit the usefulness for year-over-year analysis?

6. **IsContacted "before FTD" logic for non-converters**: The contact flag condition includes `cast(DC.FirstDepositDate as date) = '19000101' and sf.CreatedDate_SF > RegisteredReal` — meaning any Salesforce action after registration counts as "contact" for customers who never deposited. This means IsContacted=1 can grow indefinitely for long-tenured non-converters even years after registration (as long as they're in the 12-month cohort). Is this the intended measurement? Should there be a recency cap on the contact window?

7. **Regulation JOIN on DR2.ID (not DR2.DWHRegulationID)**: The SP joins `DC.RegulationID = DR2.ID`. For most regulations this is equivalent, but if any DWH regulation has RegulationID ≠ ID, the join would miss the match. Same concern applies to DR (DesignatedRegulation join). Can this be confirmed as safe?

### Potential Issues

- **ProofOfAddress / ProofOfIdentity run-time expiry**: These flags are evaluated with an expiry check (`IsAddressProofExpiryDate >= @Date`). A customer who had POA=1 yesterday may have POA=0 today if their document expired. This means historical queries are impossible — the table only shows today's document validity state, not the state at registration or FTD time.
- **SendToEV ≈ EV in data**: Currently both EV (status=2) and SendToEV (status IN 1,2,3) show 17.6% — suggesting that status=1 and status=3 are very rare in the cohort. If EvMatchStatus=1 and =3 records existed, SendToEV would be higher than EV.
- **DepositAttempt > FTD**: 388,791 deposit attempts vs 340,593 FTD — 48,198 customers attempted a deposit but did not succeed. This gap is worth monitoring for payment failure trends.

### Corrections from Prior Reviews

None.
