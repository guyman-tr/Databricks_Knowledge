# BI_DB_CID_VerificationLevel — Review Notes

## Items Requiring Human Verification

### HIGH — Functional Impact

1. **FromDateID is FSC SCD2 change date, not KYC event date**: The `FromDateID` stored is the date the Fact_SnapshotCustomer SCD2 row *started* (i.e., a change was detected by the DWH pipeline), not the actual KYC approval timestamp from the production BackOffice system. For customers who had many attribute changes, the FromDateID may closely track the actual verification date. For customers with sparse changes, the FromDateID could lag the actual KYC date. Confirm with the KYC analytics team whether this approximation is acceptable, or whether a more precise source should be used.

2. **SP missed days → gaps in first-achievement records**: If SP_CID_VerificationLevel fails on day D, and a customer achieves Level 2 on day D, their Level 2 achievement is never recorded (the dedup LEFT JOIN will prevent insertion when the SP next runs, since the customer's later FSC rows won't have `FromDateID = D`). Confirm whether monitoring exists for SP failures and whether a backfill procedure exists to recover missed days.

3. **Level 0 excluded from table**: The SP filters `v.ID NOT IN (-1, 0)`, so Level 0 (unverified) customers have zero rows in this table. Consumers who expect all customers to appear here will see ~22M "missing" customers (those who never progressed beyond Level 0 = 46M total customers - 24.6M with Level 1+ rows). Confirm whether this is documented for all consuming queries.

### MEDIUM — Data Quality / Coverage

4. **Customer with Level 3 from day 1**: The cross-join logic generates Level 1, 2, and 3 rows simultaneously for a customer who is already Level 3 on their first FSC snapshot change. Their Level 1, 2, and 3 FromDateID would all be the same date. Confirm whether this is valid or whether customers can actually skip levels in production (e.g., via manual override).

5. **RANK() function appears to be a no-op**: The RANK() OVER (PARTITION BY RealCID, ID ORDER BY FromDateID) in the SP generates rn=1 for all rows because all rows from the inner query share the same FromDateID = @dateID. This means the rn=1 filter does not actually perform any additional deduplication beyond what the outer dedup LEFT JOIN accomplishes. This appears to be leftover code from an earlier version of the SP. Confirm whether this is intentional or dead code.

6. **ROUND_ROBIN on a 54M-row reference table**: CID-based JOINs against this table require data movement in Synapse. Consider whether re-distributing on HASH(RealCID) would improve JOIN performance in commonly-used queries that join this table with customer-level data. Evaluate query performance before recommending a change.

### LOW — Documentation Gaps

7. **Relationship with BI_DB_VerificationStatus**: A separate table `BI_DB_VerificationStatus` likely tracks current verification status or full history. Confirm the distinction between these two tables and whether `BI_DB_CID_VerificationLevel` replaces, supplements, or duplicates coverage.

8. **UC migration**: This table has `UC Target: _Not_Migrated`. Confirm if migration is planned.
