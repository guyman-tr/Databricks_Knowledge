# BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data

> Raw KYC questionnaire responses at the individual answer level. Each row represents one customer (GCID) answering one question with one answer at a specific time (OccurredAt), capturing question and answer text as denormalized strings at submission time. Multi-select questions produce multiple rows per submission. Coverage spans 2013-12-01 to 2026-04-12; 467M rows total; 30M distinct GCIDs. Populated via external ETL from UserApiDB — no Synapse SP writer found.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB KYC microservice (via external ETL pipeline) |
| **Refresh** | External pipeline; OccurredAt range: 2013-12-01 to 2026-04-12 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_KYC_Questions_Answers_Row_Data` is the raw KYC (Know Your Customer) questionnaire response log. Each row captures a single customer's answer to a single question, at the time they answered it, as part of eToro's regulatory compliance process.

The table stores the full questionnaire response history going back to 2013 (467M rows, 30M distinct GCIDs), forming a longitudinal record of customer suitability assessments and compliance disclosures.

Key characteristics:
- **GCID (not CID)**: Uses the Global Customer ID, which spans eToro products and entities. Older accounts predating GCID introduction may have NULL GCID.
- **Multi-row per submission**: Multi-select questions (e.g., "What are your sources of funds?", "In which instruments do you plan to trade?") generate one row per selected answer. A single questionnaire submission may insert 5–13 rows for a single question.
- **Text snapshot**: QuestionText and AnswerText are copied from the dimension tables at submission time. If question/answer wording is later updated in `External_UserApiDB_KYC_Questions` / `External_UserApiDB_KYC_Answers`, historical rows retain the original text.
- **Re-answerable**: Customers can re-answer questions (KYC refresh, regulatory review). Each re-answer creates new rows with a later OccurredAt. To get the most recent answer per customer per question, use MAX(OccurredAt) per GCID+QuestionId.

Most frequently answered questions (2026 YTD): "In which instruments do you plan to trade?" (QuestionId=27, 2.7M rows), "What are your sources of funds" (QuestionId=26, 1.7M rows), "What are your main sources of income?" (QuestionId=15, 1.7M rows).

---

## 2. Business Logic

### 2.1 Multi-Select Question Row Expansion

**What**: Questions with multiple valid simultaneous answers produce multiple rows per GCID+OccurredAt.
**Columns Involved**: `QuestionId`, `AnswerId`, `OccurredAt`, `GCID`
**Rules**:
- `External_UserApiDB_KYC_Questions.MultipleSelection = True` → question accepts multiple selected answers
- Each selected AnswerId creates a separate row with identical GCID, OccurredAt, QuestionId, QuestionText
- Multi-select questions include: QuestionId=3 ("Do you have relevant knowledge?"), 4 ("Which markets have you traded?"), 26 ("What are your sources of funds?"), 27 ("In which instruments do you plan to trade?")
- Average: 1.33 answers per GCID+QuestionId pair; max 13 observed in production
- Single-select questions (MultipleSelection=False) produce exactly 1 row per GCID+OccurredAt+QuestionId

### 2.2 Re-Answer History

**What**: A GCID may have multiple OccurredAt timestamps for the same QuestionId as they re-complete KYC.
**Columns Involved**: `GCID`, `QuestionId`, `OccurredAt`
**Rules**:
- Each full KYC questionnaire submission creates rows with the same OccurredAt (or very close timestamps)
- To get current/latest answers per customer: use ROW_NUMBER() OVER (PARTITION BY GCID, QuestionId ORDER BY OccurredAt DESC) or filter WHERE OccurredAt = MAX(OccurredAt)
- Historical answers are preserved — do NOT deduplicate by (GCID, QuestionId, AnswerId) if the audit trail is needed

### 2.3 Text Denormalization at Snapshot Time

**What**: Question and answer text is captured at submission time, not resolved dynamically.
**Columns Involved**: `QuestionText`, `AnswerText`, `QuestionId`, `AnswerId`
**Rules**:
- At write time: QuestionText = `External_UserApiDB_KYC_Questions.QuestionText` for that QuestionId (LanguageId=1, English)
- At write time: AnswerText = `External_UserApiDB_KYC_Answers.AnswerText` for that AnswerId
- If dimension text changes (question rephrased, answer option renamed), historical rows are NOT updated
- The same QuestionId may have different QuestionText values across different OccurredAt periods — this is valid historical data, not corruption

---

## 3. Query Advisory

### 3.1 Distribution & Index

`HASH(GCID)` — queries filtering or aggregating by GCID are co-located on the same distribution. `CLUSTERED COLUMNSTORE INDEX` enables efficient analytical scans across 467M rows. Always filter by GCID or a date range before full-table aggregations.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest KYC answer per customer per question | `SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY GCID, QuestionId ORDER BY OccurredAt DESC) AS rn FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data] WHERE GCID = @gcid) t WHERE rn = 1` |
| All answers for a specific question | `SELECT AnswerText, COUNT(DISTINCT GCID) AS respondents FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data] WHERE QuestionId = 8 GROUP BY AnswerText ORDER BY respondents DESC` |
| Customers who answered a specific question | `SELECT DISTINCT GCID FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data] WHERE QuestionId = 14` |
| All KYC questions answered by a customer | `SELECT * FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data] WHERE GCID = @gcid ORDER BY OccurredAt, QuestionId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `k.GCID = dc.GCID` | Map GCID to RealCID, CountryID, registration date |
| BI_DB_dbo.External_UserApiDB_KYC_Questions | `k.QuestionId = q.QuestionId AND q.LanguageId = 1` | Get current question text and MultipleSelection flag |
| BI_DB_dbo.External_UserApiDB_KYC_Answers | `k.AnswerId = a.AnswerId AND a.LanguageId = 1` | Get current answer text and StatusID |

### 3.4 Gotchas

- **GCID ≠ CID** — this table uses GCID (Group Customer ID). Do NOT join to Dim_Customer.RealCID directly; use `Dim_Customer.GCID = k.GCID`.
- **Multiple rows per question for multi-select** — for multi-select questions, COUNT(*) per GCID does not equal the number of questions answered. Use COUNT(DISTINCT QuestionId) for distinct question count.
- **Re-answers inflate row count** — a customer who re-completed KYC appears multiple times per QuestionId. Filter by MAX(OccurredAt) for current-state analysis.
- **No Synapse SP writer** — ETL source is an external pipeline. The table is not registered in OpsDB orchestration metadata. Do not assume a daily refresh window like SP-driven tables.
- **467M rows** — always filter by GCID or OccurredAt date range before aggregating. Use COUNT_BIG(*) not COUNT(*).
- **QuestionText/AnswerText may vary for same QuestionId** — historical text snapshots; normalize via QuestionId + join to External_UserApiDB_KYC_Questions for a single current label.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo wiki or production DB_Schema wiki) |
| Tier 2 | Derived from external table structure, data sampling, or naming conventions |
| Tier 3 | Inferred from data sampling, naming conventions, or context |
| Tier 4 | Undetermined — pending review |
| P | Propagation metadata (ETL timestamp columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. FK to Customer.CustomerStatic.GCID. Join to Dim_Customer.GCID (not RealCID) for trading-platform context. (Tier 1 — Customer.CustomerStatic) |
| 2 | OccurredAt | datetime | YES | Timestamp when the customer submitted their KYC questionnaire answers. For re-answers, each submission generates a new OccurredAt batch. Multiple rows from the same questionnaire submission share the same or very close OccurredAt. Range: 2013-12-01 to 2026-04-12. (Tier 2 — naming + data evidence) |
| 3 | QuestionId | smallint | YES | FK to BI_DB_dbo.External_UserApiDB_KYC_Questions.QuestionId. Identifies the specific regulatory or suitability question. 20+ distinct questions observed in 2026; QuestionIds ranging from 1 to 150+. Examples: QuestionId=8 (trading purpose), QuestionId=14 (investment amount), QuestionId=27 (instrument types — multi-select). (Tier 2 — External_UserApiDB_KYC_Questions) |
| 4 | QuestionText | varchar(250) | YES | Denormalized text of the question, copied from External_UserApiDB_KYC_Questions.QuestionText at submission time (LanguageId=1, English). Snapshotted — may differ from current dimension text for historical rows if the question was rephrased. (Tier 2 — External_UserApiDB_KYC_Questions) |
| 5 | AnswerId | smallint | YES | FK to BI_DB_dbo.External_UserApiDB_KYC_Answers.AnswerId. Identifies the specific answer option selected by the customer. For multi-select questions, multiple AnswerIds appear as separate rows. (Tier 3 — External_UserApiDB_KYC_Answers) |
| 6 | AnswerText | varchar(250) | YES | Denormalized text of the selected answer, copied from External_UserApiDB_KYC_Answers.AnswerText at submission time. Snapshotted — may differ from current dimension text for historical rows. (Tier 3 — External_UserApiDB_KYC_Answers) |
| 7 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last written by the ETL pipeline. (P) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | UserApiDB (KYC microservice) | GCID | Passthrough |
| OccurredAt | UserApiDB (KYC submission event) | OccurredAt | Passthrough |
| QuestionId | External_UserApiDB_KYC_Questions | QuestionId | Passthrough |
| QuestionText | External_UserApiDB_KYC_Questions | QuestionText | Denormalized snapshot at write time (LanguageId=1) |
| AnswerId | External_UserApiDB_KYC_Answers | AnswerId | Passthrough |
| AnswerText | External_UserApiDB_KYC_Answers | AnswerText | Denormalized snapshot at write time |
| UpdateDate | ETL pipeline | — | ETL write timestamp |

### 5.2 ETL Pipeline

```
UserApiDB (KYC microservice — compliance answers database)
  |-- External_UserApiDB_KYC_Questions (question dimension, synced into Synapse)
  |-- External_UserApiDB_KYC_Answers (answer dimension, synced into Synapse)
  |-- External ETL pipeline (ADF or SQL Agent — no Synapse SP writer found) ---|
  v
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (467M rows, HASH(GCID), CCI)
  |-- (no confirmed Synapse SP downstream consumers found in sys.sql_modules)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | Customer.CustomerStatic (GCID) | Global customer identifier |
| GCID | DWH_dbo.Dim_Customer (GCID) | Bridge to trading CID and customer demographics |
| QuestionId | BI_DB_dbo.External_UserApiDB_KYC_Questions (QuestionId) | KYC question definition and MultipleSelection flag |
| AnswerId | BI_DB_dbo.External_UserApiDB_KYC_Answers (AnswerId) | KYC answer option definition |

### 6.2 Referenced By

| Object | How Used |
|--------|---------|
| BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | Downstream enrichment — joins KYC answers with customer demographics via QuestionId + AnswerId |
| BI_DB_dbo.BI_DB_KYC_Score_CID_Level | Likely downstream — KYC scoring derivation (ETL source to confirm) |

---

## 7. Sample Queries

### Latest KYC answers for a specific customer

```sql
SELECT GCID, QuestionId, QuestionText, AnswerId, AnswerText, OccurredAt
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY GCID, QuestionId ORDER BY OccurredAt DESC) AS rn
    FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data]
    WHERE GCID = 47574326
) t
WHERE rn = 1
ORDER BY QuestionId;
```

### Answer distribution for trading purpose question (QuestionId=8)

```sql
SELECT
    AnswerText,
    COUNT(DISTINCT GCID) AS respondent_count,
    CAST(COUNT(DISTINCT GCID) * 100.0 / SUM(COUNT(DISTINCT GCID)) OVER() AS decimal(5,2)) AS pct
FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data]
WHERE QuestionId = 8
  AND OccurredAt >= '2026-01-01'
GROUP BY AnswerText
ORDER BY respondent_count DESC;
```

### Customers who selected multiple investment instruments (multi-select question)

```sql
SELECT
    GCID,
    COUNT(*) AS instruments_selected,
    STRING_AGG(AnswerText, ', ') AS selected_instruments
FROM [BI_DB_dbo].[BI_DB_KYC_Questions_Answers_Row_Data]
WHERE QuestionId = 27
  AND OccurredAt >= '2026-04-01'
GROUP BY GCID
HAVING COUNT(*) > 3
ORDER BY instruments_selected DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. No SP author metadata available (no Synapse SP writer). Table is not registered in OpsDB orchestration. KYC question and answer definitions available from `BI_DB_dbo.External_UserApiDB_KYC_Questions` and `External_UserApiDB_KYC_Answers`.

---

*Generated: 2026-04-23 | Quality: 8.1/10 | Phases: 11/14*
*Tiers: 1 T1, 5 T2, 0 T3, 0 T4, 1 P | Elements: 7/7, Logic: 9/10, Data Evidence: 10/10*
*Object: BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | Type: Table | Production Source: UserApiDB KYC microservice (external ETL)*
