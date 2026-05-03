# BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel

> 295K-row staging table holding raw KYC (Know Your Customer) questionnaire answers loaded daily from the Bronze data lake export of `UserApiDB.dbo.V_CustomerAnswers`. Populated by `SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range` via Parquet COPY INTO, then consumed by `SP_KYC_Panel` and `SP_KYC_Questions_Answers_Row_Data_46` to build the downstream KYC Panel analytics tables.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.dbo.V_CustomerAnswers via SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range |
| **Refresh** | Daily — recreated (DROP + COPY INTO) on each SP_KYC_Panel / SP_KYC_Questions_Answers_Row_Data_46 run |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | None (lake partitioned by etr_y/etr_ym/etr_ymd) |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a **transient staging snapshot** of KYC questionnaire answers sourced from the production `UserApiDB.dbo.V_CustomerAnswers` view. It stores one row per customer-question-answer combination, capturing the full question text, answer text, and optional numeric range thresholds (for income/asset bracket questions).

The table is created fresh on each ETL run by `SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range`, which issues a `COPY INTO` from Parquet files stored in the Bronze layer at `/internal-sources/Bronze/UserApiDB/dbo/V_CustomerAnswers/`. The date range loaded depends on the calling SP:
- **SP_KYC_Panel** loads from the max existing `OccurredAt` in `BI_DB_KYC_Questions_Answers_Row_Data` up to the current run date.
- **SP_KYC_Questions_Answers_Row_Data_46** loads a single day for question 46 only.

After loading, the downstream SPs read from this table to extract, pivot, and aggregate KYC answers into the `BI_DB_KYC_Panel` and `BI_DB_KYC_Questions_Answers_Row_Data` analytics tables, then the staging table is dropped on the next run.

The table currently holds ~295K rows. Sample data shows questions covering: annual income, liquid assets, planned investment amounts, risk/reward scenarios, profiling consent, PEP/money management, sources of funds, and crypto trading knowledge assessments.

---

## 2. Business Logic

### 2.1 Transient Staging Pattern

**What**: Table is dropped and recreated on each ETL run — it is not an append-only fact table.
**Columns Involved**: All columns.
**Rules**:
- `SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range` checks `IF OBJECT_ID(@dest_table) IS NOT NULL` and drops the table before loading.
- Data is loaded via `COPY INTO` with `AUTO_CREATE_TABLE = 'ON'` and `FILE_TYPE = 'PARQUET'`.
- The table name is passed as a parameter (`@dest_table`), allowing the same SP to create `_KYC_Panel`, `_KYC_Panel_Full`, and `_KYC_Panel_Fix` variants.

### 2.2 Range-Based Answer Thresholds

**What**: Questions with numeric bracket answers carry MinThreshold and MaxThreshold values.
**Columns Involved**: MinThreshold, MaxThreshold, AnswerText.
**Rules**:
- Income bracket questions (QuestionId 10, 11, 14) populate both threshold columns with dollar amounts (e.g., MinThreshold=10000, MaxThreshold=50000 for "$10K-$50K").
- Non-range questions (e.g., Profiling Consent, PEP/MM) leave both threshold columns NULL.

### 2.3 Multiple Selection Questions

**What**: Some KYC questions allow multiple answer selections per customer.
**Columns Involved**: MultipleSelection, GCID, QuestionId.
**Rules**:
- When `MultipleSelection = True`, a single GCID+QuestionId combination can have multiple rows (one per selected answer).
- When `MultipleSelection = False`, each GCID+QuestionId combination has exactly one row.
- Observed distribution: ~54% False, ~46% True.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution — no co-located joins. Acceptable for a staging table that is scanned sequentially by downstream SPs.
- **HEAP** — no clustered index. The table is recreated on each run, so index maintenance is unnecessary.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| What KYC answers did a specific customer give? | `SELECT * FROM BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel WHERE GCID = @gcid ORDER BY QuestionId` |
| How many customers answered a specific question? | `SELECT COUNT(DISTINCT GCID) FROM BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel WHERE QuestionId = @qid` |
| What are the answer distributions for income questions? | `SELECT AnswerText, COUNT(*) FROM ... WHERE QuestionId = 10 GROUP BY AnswerText` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | GCID, QuestionId | Merge new answers into the persistent row-level KYC store |
| DWH_dbo.Dim_Customer | GCID | Enrich with customer demographics for the KYC Panel |

### 3.4 Gotchas

- **Transient table**: Contents change on every ETL run. Do not rely on row counts or date ranges for historical analysis — use `BI_DB_KYC_Questions_Answers_Row_Data` or `BI_DB_KYC_Panel` instead.
- **FreeText column**: Usually empty; only populated for certain assessment questions (e.g., QuestionId 110 "Crypto Trading Knowledge Assessment" where the customer confirms with "Yes").
- **NULL thresholds**: MinThreshold and MaxThreshold are NULL for non-range questions. Do not assume all rows have thresholds.
- **etr_* partition columns**: These are lake partition keys (year/month/date), not business columns. They reflect the Bronze export date, not necessarily the `OccurredAt` date.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | ETL-computed with documented transform |
| Tier 3 | Source identified but no upstream wiki available |
| Tier 4 | Inferred from name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Global Customer ID. Unique identifier for the customer across the platform. Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 2 | OccurredAt | datetime2(7) | YES | Timestamp of when the customer submitted this KYC answer. Used by downstream SPs to determine incremental load boundaries (MAX(OccurredAt) defines the next load start). Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 3 | FreeText | varchar(max) | YES | Optional free-text response for KYC questions that accept open-ended input. Typically empty for multiple-choice questions; populated for assessment confirmations (e.g., "Yes" for Crypto Trading Knowledge Assessment, QuestionId 110). Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 4 | QuestionId | int | YES | Numeric identifier for the KYC question. Key values: 2=Experience_Old, 3=Financial_Knowledge, 5=Trading_Strategy, 8=Trading_Primary_Purpose, 9=Risk_Reward_Scenario, 10=Annual_Income, 11=Liquid_Assets, 14=Planned_Invested_Amount, 15=Sources_of_Income, 18=Occupation, 23=Knowledge_Assessment, 26=Sources_of_Funds, 27=Planned_Investment_Instrument, 28=Profiling_Consent, 29=Time_Frame_Investing, 30=FINRA, 32=PEP_MM_Question, 33=Experience_Equities, 34=Experience_Crypto, 35=Experience_CFDs, 36=US_Permanent_Resident, 40=W9_Certification, 45=Invested_Amount_CFDs, 46=Question_46, 47=Invested_Amount_Equities, 48=Invested_Amount_Crypto, 50=Vulnerable_Client, 110=Crypto_Trading_Knowledge_Assessment. Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 5 | QuestionText | varchar(max) | YES | Human-readable label of the KYC question (e.g., "What is your net annual income?", "Profiling Consent", "PEP/MM question"). Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 6 | AnswerId | int | YES | Numeric identifier for the selected answer option. Used by downstream SPs in CASE/WHEN logic to classify customer profiles (e.g., experience levels, assessment pass/fail). Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 7 | AnswerText | varchar(max) | YES | Human-readable label of the selected answer (e.g., "$10K-$50K", "Savings", "Confirmed", "80% / -48%", "None Apply To me"). Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 8 | MinThreshold | int | YES | Lower bound of numeric range for bracket-style answers. Populated for income/asset/investment questions (QuestionId 10, 11, 14) with dollar amounts (e.g., 10000 for "$10K-$50K"). NULL for non-range questions. Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 9 | MaxThreshold | int | YES | Upper bound of numeric range for bracket-style answers. Populated for income/asset/investment questions (QuestionId 10, 11, 14) with dollar amounts (e.g., 50000 for "$10K-$50K"). NULL for non-range questions. Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 10 | MultipleSelection | bit | YES | Flag indicating whether the KYC question allows multiple answer selections. True=multiple answers per GCID+QuestionId (e.g., Sources of Funds, Sources of Income); False=single answer per GCID+QuestionId (e.g., Annual Income, Risk/Reward). Distribution: ~54% False, ~46% True. Passthrough from UserApiDB.dbo.V_CustomerAnswers via Bronze Parquet export. (Tier 3 — UserApiDB.dbo.V_CustomerAnswers) |
| 11 | etr_y | varchar(max) | YES | Year partition key from the Bronze data lake export path (`etr_y={year}`). Contains the 4-digit year (e.g., "2026"). Generated by the Generic Pipeline Bronze export, not a production source column. (Tier 3 — Bronze partition path) |
| 12 | etr_ym | varchar(max) | YES | Year-month partition key from the Bronze data lake export path (`etr_ym={year-month}`). Format: "YYYY-MM" (e.g., "2026-04"). Generated by the Generic Pipeline Bronze export, not a production source column. (Tier 3 — Bronze partition path) |
| 13 | etr_ymd | varchar(max) | YES | Date partition key from the Bronze data lake export path (`etr_ymd={date}`). Format: "YYYY-MM-DD" (e.g., "2026-04-25"). Generated by the Generic Pipeline Bronze export, not a production source column. (Tier 3 — Bronze partition path) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| GCID | UserApiDB.dbo.V_CustomerAnswers | GCID | Passthrough (Parquet COPY INTO) |
| OccurredAt | UserApiDB.dbo.V_CustomerAnswers | OccurredAt | Passthrough (Parquet COPY INTO) |
| FreeText | UserApiDB.dbo.V_CustomerAnswers | FreeText | Passthrough (Parquet COPY INTO) |
| QuestionId | UserApiDB.dbo.V_CustomerAnswers | QuestionId | Passthrough (Parquet COPY INTO) |
| QuestionText | UserApiDB.dbo.V_CustomerAnswers | QuestionText | Passthrough (Parquet COPY INTO) |
| AnswerId | UserApiDB.dbo.V_CustomerAnswers | AnswerId | Passthrough (Parquet COPY INTO) |
| AnswerText | UserApiDB.dbo.V_CustomerAnswers | AnswerText | Passthrough (Parquet COPY INTO) |
| MinThreshold | UserApiDB.dbo.V_CustomerAnswers | MinThreshold | Passthrough (Parquet COPY INTO) |
| MaxThreshold | UserApiDB.dbo.V_CustomerAnswers | MaxThreshold | Passthrough (Parquet COPY INTO) |
| MultipleSelection | UserApiDB.dbo.V_CustomerAnswers | MultipleSelection | Passthrough (Parquet COPY INTO) |
| etr_y | Bronze partition path | etr_y | Lake partition key (year) |
| etr_ym | Bronze partition path | etr_ym | Lake partition key (year-month) |
| etr_ymd | Bronze partition path | etr_ymd | Lake partition key (date) |

### 5.2 ETL Pipeline

```
UserApiDB.dbo.V_CustomerAnswers (production, UserApiDB)
  |-- Generic Pipeline (Bronze export to Parquet) ---|
  v
Azure Data Lake: /internal-sources/Bronze/UserApiDB/dbo/V_CustomerAnswers/
  etr_y={year}/etr_ym={year-month}/etr_ymd={date}/*.parquet
  |-- SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range (COPY INTO) ---|
  v
BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel (~295K rows, transient)
  |-- SP_KYC_Panel (reads → pivots → aggregates) ---|
  v
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (persistent row store)
  |-- SP_KYC_Panel (continued) ---|
  v
BI_DB_dbo.BI_DB_KYC_Panel (final analytics table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| GCID | DWH_dbo.Dim_Customer.GCID | Links KYC answers to the customer dimension |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|---|---|---|
| BI_DB_dbo.SP_KYC_Panel | All columns | Reads all KYC answers, applies DENSE_RANK to get latest per GCID+QuestionId, loads into BI_DB_KYC_Questions_Answers_Row_Data |
| BI_DB_dbo.SP_KYC_Questions_Answers_Row_Data_46 | GCID, OccurredAt, QuestionId, QuestionText, AnswerId, AnswerText | Reads question 46 answers for the current date, loads into BI_DB_KYC_Questions_Answers_Row_Data |
| BI_DB_dbo.SP_AML_Singapore_Risk_Classification | GCID | Referenced in commented-out diagnostic query |

---

## 7. Sample Queries

### 7.1 Customer KYC Profile Lookup

```sql
SELECT QuestionId, QuestionText, AnswerId, AnswerText,
       MinThreshold, MaxThreshold, MultipleSelection, OccurredAt
FROM BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel
WHERE GCID = 47956882
ORDER BY QuestionId, OccurredAt DESC;
```

### 7.2 Answer Distribution for Income Questions

```sql
SELECT AnswerText, MinThreshold, MaxThreshold, COUNT(*) AS answer_count
FROM BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel
WHERE QuestionId = 10  -- Annual Income
GROUP BY AnswerText, MinThreshold, MaxThreshold
ORDER BY MinThreshold;
```

### 7.3 Daily Answer Volume by Question

```sql
SELECT etr_ymd, QuestionId, QuestionText, COUNT(*) AS answers
FROM BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel
GROUP BY etr_ymd, QuestionId, QuestionText
ORDER BY etr_ymd DESC, QuestionId;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object. (Atlassian search skipped in regen harness mode.)

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 13 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel | Type: Table | Production Source: UserApiDB.dbo.V_CustomerAnswers*
