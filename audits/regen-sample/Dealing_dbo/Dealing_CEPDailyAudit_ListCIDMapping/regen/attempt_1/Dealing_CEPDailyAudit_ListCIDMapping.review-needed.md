# Review Needed — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

## Items for Human Review

### 1. LoginName Null-Byte Padding

Sampled data shows `LoginName` values with trailing null-byte characters (e.g., `charilaosch\0\0\0...`). This appears to be a source data artifact from the CEP temporal tables. Confirm whether this is expected behavior or a data quality issue that should be flagged upstream.

### 2. LoginName Empty for ~85% of Rows

455 of 537 rows have NULL or empty `LoginName`. This is documented as "system-driven changes" in the wiki. Confirm with the Dealing team whether this is accurate or whether there is a bug in the `COALESCE(AppLoginName, PreviousAppLoginName)` logic for ListCIDMappings specifically.

### 3. PII Governance

The `CID` column contains customer identifiers. Confirm appropriate access controls and masking policies are in place for any UC migration target. Named List names (e.g., "Big Clients to HBC", "German Clients - Tests", "Falaknaz and Family") may also be business-sensitive.

### 4. No Views Reference This Table

Unlike some sibling CEPDailyAudit tables (e.g., Rules has `V_Dealing_CEPDailyAudit_Rules_Last180Days`), no views reference ListCIDMapping. Confirm this is intentional — the per-CID detail may be too sensitive or granular for view-based access patterns.

### 5. Tier Coverage

All 8 columns are Tier 2 (SP code). No Tier 1 columns because all values are either SP parameters (@Date), SP-derived (TypeOfChange), SP-resolved via JOINs (ListName, LoginName), or staging passthroughs with no upstream wiki for the staging tables. No Tier 3 or Tier 4 columns — all columns have clear SP evidence.

---

*Generated: 2026-04-28 | Regen harness attempt 1*
