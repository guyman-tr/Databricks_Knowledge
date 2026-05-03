# Review Needed: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

## Summary

22 of 28 columns are Tier 1 (passthrough from production wikis). 6 columns are Tier 2 (computed). No Tier 3 or Tier 4 columns.

## Items for Human Review

### 1. UC Target Not Determined

This table is marked `_Not_Migrated`. If the Marketing Cube pipeline migrates to Databricks, a UC target will need to be assigned.

### 2. Ephemeral Table Pattern

This table is dropped and rebuilt on every SP_Marketing_Cube execution. It is an intermediate staging artifact, not a persistent analytical table. Consider whether it should be documented as a persistent object or flagged as transient infrastructure.

### 3. CID Source Ambiguity

CID exists in both ClosedPosition (the position holder) and RegistrationMetaData (the registered customer). In ClosedPositionVW, CID is selected from RegistrationMetaData (M.CID). They are equal due to the JOIN condition (A.CID = M.CID), but the semantic origin differs slightly between the two source tables. The wiki uses the ClosedPosition description for business context since this is a closed-position table.

### 4. OriginalCID Overloaded Usage

In SP_Marketing_Cube, OriginalCID is used as OriginalCID+17 (aliased as Optional3) to join with #NotValidCustomer. This non-obvious transformation should be understood by anyone modifying the Marketing Cube logic.

### 5. LabelID — Permanently NULL

LabelID is hardcoded as NULL in ClosedPositionVW. It exists only for backward compatibility. Consider whether this column adds value or should be excluded from downstream consumption.

### 6. Atlassian Sources Not Searched

Jira/Confluence search was skipped in this regen harness run. A full batch run should search for relevant Jira tickets (e.g., Marketing Cube changes, fiktivo/Affwiz migration tickets).

### 7. OriginalCID Nullable Behavior

The upstream ClosedPosition wiki says OriginalCID is "NULL for independently opened positions." However, the RegistrationMetaData wiki says OriginalCID "For standard registrations, equals CID or another reference." The ClosedPositionVW selects M.OriginalCID from RegistrationMetaData, so the NULL semantic from ClosedPosition may not apply here. Live data shows OriginalCID values are always populated (non-NULL) in the sampled rows. A reviewer should verify whether NULL OriginalCID is possible in this table.

---

*Generated: 2026-04-30*
