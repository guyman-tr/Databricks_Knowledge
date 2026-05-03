# Pre-Resolved Upstream Bundle for `BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel.sql`

```sql
CREATE TABLE [BI_DB_dbo].[UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel]
(
	[GCID] [int] NULL,
	[OccurredAt] [datetime2](7) NULL,
	[FreeText] [varchar](max) NULL,
	[QuestionId] [int] NULL,
	[QuestionText] [varchar](max) NULL,
	[AnswerId] [int] NULL,
	[AnswerText] [varchar](max) NULL,
	[MinThreshold] [int] NULL,
	[MaxThreshold] [int] NULL,
	[MultipleSelection] [bit] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
