# Review Needed: eMoney_dbo.eMoney_Card_Monthly_Snapshot

**Generated**: 2026-04-21  
**Reviewer**: Data Engineering / eToro Money Analytics Team  
**Priority**: Medium

---

## Tier 4 Items (Unverified — Require Business Confirmation)

None. All 23 columns traced to SP code, upstream DWH tables (Fact_SnapshotCustomer, Dim_PlayerLevel, Dim_Country), or documented eMoney_dbo sources (eMoney_Card_Instance_Summary, eMoney_Dim_Transaction).

---

## Open Questions

1. **SP not in Execute_Group_One**: SP_eMoney_Card_Monthly_Snapshot was created 2025-06-29, after the Execute_Group_One orchestrator was disabled. Confirm: is this SP triggered by an ADF pipeline, a SQL Agent job, or manually? What are its declared dependencies (eMoney_Card_Instance_Summary must complete first) and what is the expected monthly run schedule?

2. **Tx dates are not snapshot-bounded**: Columns Tx1_AfterFirst, Tx2_AfterFirst, Tx1_AfterLast, Tx2_AfterLast reflect the lifetime first/second transaction date after activation — they are NOT bounded to ≤ SnapShotDate. This means for a historical EOM snapshot row, Tx1_AfterFirst could post-date the SnapShotDate. Confirm: is this intentional (reflecting current settled state) or should these be bounded to ≤ SnapShotDate to represent "transactions made by that EOM"? This is critical for accurate cohort funnel analysis.

3. **Country/Club are static across all EOM rows**: The `Country` and `Club` columns are set at SP execution time from Dim_Customer, not at the EOM date. This means they will be identical for ALL 27 snapshot rows for the same customer. Analysts who trend these columns over time will see no change — only SnapshotCountry/SnapshotClub reflect true historical state. Confirm: should Country/Club be removed from the table since they duplicate information already derivable via Dim_Customer JOIN? Or is there a downstream system that requires them denormalized?

4. **34-country filter uses current Dim_Country_Rollout state**: The SP joins `eMoney_dbo.eMoney_Dim_Country_Rollout` at execution time, not the rollout state as of the EOM. If a new country is added to the rollout after historical EOM dates, would a backfill run include customers from that country in historical snapshots where they weren't yet in rollout? Confirm: has any backfill occurred and does the rollout table cover the full 2024-01-31 to current range correctly?

5. **AccountSubProgram NULL rate for card customers**: The wiki notes that ~99.65% of rows have NULL CardCreateDate (non-card customers). But for the ~0.35% who have cards, what percentage also have NULL AccountSubProgram? If card holders consistently have NULL AccountSubProgram, the LEFT JOIN may have a gap in eMoney_Dim_Account coverage that should be investigated.

---

## Validation Flags

- **Tx date columns not snapshot-bounded**: Tx1_AfterFirst / Tx2_AfterFirst / Tx1_AfterLast / Tx2_AfterLast may post-date SnapShotDate for historical snapshot rows. This is semantically inconsistent with a "point-in-time snapshot" table — the card dates (CardCreateDate, InstanceCreatedDate, InstanceActivationDate) ARE bounded to the SP run date, but the Tx dates are lifetime values.
- **Country/Club current-only**: These columns do not change across EOM rows for the same customer. Documentation warns analysts, but the column naming (no "Snapshot" prefix vs. Snapshot* columns) may cause confusion. Consider if a DDL comment or view alias would help.
- **eMoney_Card_Instance_Summary as intermediary**: All card date aggregations pass through eMoney_Card_Instance_Summary. If CIS is stale or has not yet run for a given day, the monthly snapshot will reflect the previous day's card data. No lag indicator is present in the snapshot.

---

## Cross-Object Consistency Check

| Shared Column | Source Description (eMoney_Card_Instance_Summary or eMoney_Account_Mappings) | This Wiki Description | Match? |
|--------------|----------------------------------------------|----------------------|--------|
| CID | "Customer ID - platform-internal primary key…" | Verbatim copy | YES |
| GCID | "Global Customer ID. Identifies the customer across all eToro platforms…" | Verbatim copy | YES |
| FMI_Date | From eMoney_Card_Instance_Summary #10 | Verbatim copy with source noted | YES |
| AccountSubProgram | From eMoney_Dim_Account | LEFT JOIN GCID_Unique_Count=1; NULL for non-matches | YES |

---

*Review generated: 2026-04-21 | Object: eMoney_dbo.eMoney_Card_Monthly_Snapshot*
