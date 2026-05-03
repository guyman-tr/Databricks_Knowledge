# BI_DB_dbo.BI_DB_KYC_Questions_Answers

> Dormant KYC question-and-answer lookup table with 0 rows. Defines a question/answer pair structure (QuestionId, AnswerId) with text labels and a multiple-selection flag. No writer SP populates this table; the active equivalent is `BI_DB_KYC_Questions_Answers_Row_Data`. ROUND_ROBIN distribution, clustered on QuestionId.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — no SP writes to this table |
| **Refresh** | None (table is empty, no ETL pipeline) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (QuestionId ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | None |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_KYC_Questions_Answers` appears to be a reference/lookup table designed to hold the master list of Know Your Customer (KYC) questionnaire questions and their possible answers. Each row represents one question-answer combination, with columns for the question ID and text, the answer ID and text, whether the question supports multiple selections, and a last-update timestamp.

The table is currently **empty (0 rows)** and **no stored procedure** in the Synapse codebase writes to it. The actively used table for KYC question-answer data at the row level is `BI_DB_KYC_Questions_Answers_Row_Data`, which is populated daily by `SP_KYC_Questions_Answers_Row_Data_46` from the production `UserApiDB_dbo_V_CustomerAnswers_Range` staging view. That Row_Data table stores per-customer responses (with GCID and OccurredAt columns), whereas this table's schema suggests it was intended as a static question/answer definition catalog without a customer dimension.

This table is likely a deprecated precursor or orphaned artifact from an earlier KYC pipeline design.

---

## 2. Business Logic

### 2.1 Question-Answer Pair Model

**What**: Each row maps one QuestionId to one AnswerId, forming a many-to-many relationship between questions and answers.
**Columns Involved**: QuestionId, QuestionText, AnswerId, AnswerText
**Rules**:
- QuestionId and AnswerId are both NOT NULL integers — every row must specify both.
- QuestionText and AnswerText are NOT NULL nvarchar(250) — human-readable labels are mandatory.

### 2.2 Multiple Selection Flag

**What**: Indicates whether a question allows the user to select more than one answer.
**Columns Involved**: MultipleSelection
**Rules**:
- Stored as a NOT NULL bit (0 = single selection, 1 = multiple selection allowed).
- In the related `SP_KYC_Panel`, multi-select questions (e.g., Q15 Sources of Income, Q26 Sources of Funds) are aggregated via STRING_AGG, suggesting this flag would distinguish aggregation-eligible questions.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no hash key, data spread evenly across distributions.
- **Index**: CLUSTERED INDEX on QuestionId ASC — optimized for question-level lookups.
- Since the table is empty, distribution choice has no performance impact.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| List all answers for a question | `SELECT * FROM BI_DB_dbo.BI_DB_KYC_Questions_Answers WHERE QuestionId = @qid` |
| Find multi-select questions | `SELECT DISTINCT QuestionId, QuestionText FROM BI_DB_dbo.BI_DB_KYC_Questions_Answers WHERE MultipleSelection = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_KYC_Questions_Answers_Row_Data | QuestionId = QuestionId AND AnswerId = AnswerId | Decode customer responses with canonical question/answer text |

### 3.4 Gotchas

- **Table is empty**: As of 2026-04-30, this table contains 0 rows. Any query will return no results.
- **Not the active KYC data table**: The active per-customer KYC responses live in `BI_DB_KYC_Questions_Answers_Row_Data`. Do not confuse the two.
- **No writer SP**: No ETL process populates this table — it would need manual or ad-hoc loading.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL + related SP context, no direct upstream |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | QuestionId | int | NO | Unique identifier for a KYC questionnaire question. Used as the clustered index key. In the related SP_KYC_Panel pipeline, known QuestionIds include: 2=Experience, 3=Financial Knowledge, 5=Trading Strategy, 8=Trading Primary Purpose, 9=Risk/Reward Scenario, 10=Annual Income, 11=Liquid Assets, 14=Planned Investment, 15=Sources of Income, 18=Occupation, 23=Knowledge Assessment, 26=Sources of Funds, 27=Planned Investment Instrument, 29=Time Frame, 30=FINRA, 32=PEP/MM, 33=Experience Equities, 34=Experience Crypto, 35=Experience CFDs, 36=US Permanent Resident, 40=W9 Certification, 45=Invested Amount CFDs, 46=Question 46, 47=Invested Amount Equities, 48=Invested Amount Crypto, 50=Vulnerable Client. (Tier 3 — no upstream wiki, grounded in SP_KYC_Panel question mapping) |
| 2 | QuestionText | nvarchar(250) | NO | Human-readable text of the KYC question, e.g. the question as presented to the customer during onboarding. Max 250 characters. (Tier 3 — no upstream wiki, grounded in DDL + SP_KYC_Panel usage) |
| 3 | MultipleSelection | bit | NO | Flag indicating whether the question allows the customer to select multiple answers (1) or only one answer (0). Multi-select questions like Sources of Income (Q15) and Sources of Funds (Q26) are aggregated via STRING_AGG in downstream SP_KYC_Panel processing. (Tier 3 — no upstream wiki, grounded in DDL + SP_KYC_Panel aggregation logic) |
| 4 | AnswerId | int | NO | Unique identifier for a specific answer option within a question. Known answer IDs from the SP_KYC_Panel pipeline include assessment answers (84-87, 101-104, 127, 142-146), experience levels (49=Non, 122=Low, 123/210=Med, 124/211=High), and various FINRA/PEP flags (93-96, 106-109). (Tier 3 — no upstream wiki, grounded in SP_KYC_Panel answer mapping) |
| 5 | AnswerText | nvarchar(250) | NO | Human-readable text of the answer option as presented to the customer. Max 250 characters. (Tier 3 — no upstream wiki, grounded in DDL + SP_KYC_Panel usage) |
| 6 | UpdateDate | datetime | YES | Timestamp of the last update to this question-answer record. NULL if not yet set. In the related Row_Data table, this is populated via GETDATE() at insert time. (Tier 3 — no upstream wiki, grounded in DDL + SP_KYC_Questions_Answers_Row_Data_46 pattern) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| QuestionId | Unknown | — | No writer SP found |
| QuestionText | Unknown | — | No writer SP found |
| MultipleSelection | Unknown | — | No writer SP found |
| AnswerId | Unknown | — | No writer SP found |
| AnswerText | Unknown | — | No writer SP found |
| UpdateDate | Unknown | — | No writer SP found |

### 5.2 ETL Pipeline

```
(Unknown production source — no ETL pipeline exists)
  |
  v
BI_DB_dbo.BI_DB_KYC_Questions_Answers (0 rows, dormant)
  |-- No downstream UC target (Not_Migrated)

Related active pipeline (different table):
UserApiDB.dbo.V_CustomerAnswers (production, per-customer)
  |-- SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range (staging)
  v
BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel (staging)
  |-- SP_KYC_Questions_Answers_Row_Data_46 @Date
  v
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (active, per-customer Q&A)
  |-- SP_KYC_Panel (aggregation)
  v
BI_DB_dbo.BI_DB_KYC_Panel (final KYC flat table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| (none) | — | No FK constraints defined in DDL |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| (none) | — | No SPs or views reference this table directly |

---

## 7. Sample Queries

### 7.1 List All Questions and Their Answers

```sql
SELECT QuestionId, QuestionText, MultipleSelection, AnswerId, AnswerText
FROM BI_DB_dbo.BI_DB_KYC_Questions_Answers
ORDER BY QuestionId, AnswerId
```

### 7.2 Find Multi-Select Questions

```sql
SELECT DISTINCT QuestionId, QuestionText
FROM BI_DB_dbo.BI_DB_KYC_Questions_Answers
WHERE MultipleSelection = 1
ORDER BY QuestionId
```

### 7.3 Count Answers Per Question

```sql
SELECT QuestionId, QuestionText, COUNT(*) AS AnswerCount
FROM BI_DB_dbo.BI_DB_KYC_Questions_Answers
GROUP BY QuestionId, QuestionText
ORDER BY QuestionId
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant table.

---

*Generated: 2026-04-30 | Quality: 5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 6 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 4/10, Lineage: 2/10*
*Object: BI_DB_dbo.BI_DB_KYC_Questions_Answers | Type: Table | Production Source: Unknown (dormant)*
