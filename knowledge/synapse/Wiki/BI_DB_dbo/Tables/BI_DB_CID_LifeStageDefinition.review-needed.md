# BI_DB_CID_LifeStageDefinition — Review Notes

## Items Requiring Human Verification

### HIGH — Functional Impact

1. **PlayerLevelID >= 2 "Club" definition**: The SP uses `PlayerLevelID >= 2` to determine Club vs. non-Club variants (Active Open Club, Holder Club). Since PlayerLevelID IDs are non-sequential (1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=PP, 7=Diamond), `>= 2` effectively includes Silver (5), Gold (3), Platinum (2), PP (6), Diamond (7) — all above Bronze. This IS the correct behavior (all non-Bronze = Club), but confirm with data owners that this was intentional and not a bug that excluded Silver (5 is NOT >= 2 if you expect linear ordering). Specifically: 5 >= 2 is TRUE, 3 >= 2 is TRUE — so all non-Bronze tiers correctly get the Club variant. Document this explicitly to prevent future confusion.

2. **Churn window uses previous LSD for gate-keeping**: The churn buckets (14-30d, 31-60d, over 60d) use `#lastStatus` (previous LSD) as a gate. A customer who was "Active Open" and drops below $20 equity doesn't immediately become "Churn 14-30 days" — they need `LSD NOT IN ('Churn over 60 days','Dump Churn','Churn 31-60 days')` in their last status. This sticky-bucket logic means churn escalation is gated by the previous bucket, not purely time-based. Confirm this is the intended design and document whether customers can "skip" churn buckets.

3. **Date column is varchar(10) not date**: The `Date` column is stored as `varchar(10)` (e.g., '2026-04-12'), not as a `DATE` or `DATETIME` type. This is unusual and could cause sorting/comparison issues if not explicitly CAST. Confirm whether this is intentional or a historical artifact — changing the type would require SP modification.

### MEDIUM — Data Quality / Coverage

4. **Gap-fill behavior and recalculation**: The SP fills gaps from MAX(Date)+1 to yesterday on each daily run. If the SP missed multiple days, the gap-fill recalculates using current state (not the historical state for each missed day). This means backfill may not perfectly reconstruct historical stage assignments for missed days. Confirm whether this is acceptable and whether there are monitoring alerts for SP failures.

5. **Self-reference creates dependency chain**: The SP reads the table itself for Winback and sticky-period logic. If the table is corrupted or the SP is run out of order, incorrect previous LSD values propagate forward. Confirm whether there is a validation check before production reports rely on this table.

6. **Fact_SnapshotEquity source for churn**: Churn calculation uses `Fact_SnapshotEquity` (not `V_Liabilities`) to find the last date a customer had equity >= $20 in the past year. Confirm that `Fact_SnapshotEquity` and `V_Liabilities` use the same equity definition. If they differ, the churn date calculation may not align with current equity readings.

7. **No historical data before 2022-01-01**: MIN(DateID) = 20220101. Customers who churned or changed stages before 2022 have no history in this table. Confirm whether a pre-2022 backfill was done or if the data starts fresh from 2022.

### LOW — Documentation Gaps

8. **Win Back 14-day sticky period**: The `prevdefwinback_status` logic extends Win Back Deposit → Win Back Active Open transitions within 14 days. The full state machine for Win Back → Active Open transitions after 14 days is documented in the SP but complex. Consider adding a state diagram to Confluence for CRM team reference.

9. **UC migration**: This table has `UC Target: _Not_Migrated`. The monthly snapshot (`BI_DB_Snapshot_CID_LifeStageDefinition`) is also not migrated. Confirm if migration is planned or permanently excluded.
