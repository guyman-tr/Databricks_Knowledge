# Review Needed: BI_DB_dbo.BI_DB_KYC_Questions_Answers

## 1. Dormant / Orphaned Status

- **Table is empty (0 rows)** as of 2026-04-30.
- **No stored procedure** in the Synapse codebase writes to or reads from this exact table.
- The similarly named `BI_DB_KYC_Questions_Answers_Row_Data` is the active table, populated by `SP_KYC_Questions_Answers_Row_Data_46`.
- **Action needed**: Confirm whether this table is deprecated and can be dropped, or whether it is intended to be populated manually/externally as a static question-answer catalog.

## 2. All Columns Are Tier 3

- No upstream production wiki exists for any column.
- No writer SP provides traceable lineage.
- Column descriptions are grounded in the DDL structure and the related `SP_KYC_Panel` pipeline (which uses the Row_Data variant, not this table).
- **Action needed**: If a production source for this table is known (e.g., a manual load from UserApiDB or Compliance tooling), update the lineage and promote descriptions to Tier 1 or Tier 2.

## 3. Relationship to Row_Data Table

- This table's schema (QuestionId, QuestionText, MultipleSelection, AnswerId, AnswerText, UpdateDate) is a subset of the Row_Data table's schema (which adds GCID, OccurredAt for per-customer tracking).
- It is unclear whether this was intended as a dimension/lookup for Row_Data or a deprecated prototype.
- **Action needed**: Clarify the intended relationship and document accordingly.

## 5. UC Migration

- Table is marked `_Not_Migrated`.
- Given dormant status, UC migration is likely not required unless the table is revived.
