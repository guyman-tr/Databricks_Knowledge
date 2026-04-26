# Review Needed: BI_DB_dbo.BI_DB_Publications

## Tier 4 / Low-Confidence Items

No Tier 4 columns. All columns traced to SP code (Tier 2) or inferred from data patterns (Tier 3). No upstream UserApiDB wiki was available.

## Reviewer Questions

1. **Sticky and LanguageCode are frozen at first insert** — is this intentional? The SP only updates `AboutMe` and does not maintain `Sticky` or `LanguageCode`. If a user changes their pinned sticky or the system re-detects a different language, those changes are invisible here. Was this omission deliberate (these fields are considered immutable for analysis) or a maintenance gap?

2. **NULL→non-NULL AboutMe transitions may be missed**: The SP UPDATE uses `WHERE p.AboutMe <> pl.AboutMe`. In SQL, NULL <> 'some text' evaluates to UNKNOWN, not TRUE — so if a customer's AboutMe is NULL in the table and they write a bio later in UserApiDB, the UPDATE will not fire. The row only gets corrected if the customer is deleted from and re-inserted into BI_DB_Publications. Is there a known workaround for this?

3. **LanguageCode semantics — detected vs. user-set?** The 153 distinct codes include values like 'ar-latn', 'zh-latn', 'hi-latn' (transliterated script markers) which are typical of machine language detection APIs (e.g., Google Cloud Translation). Confirm whether LanguageCode is: (a) user-selected language preference, or (b) auto-detected from the AboutMe text. This affects whether it can be used for customer segmentation by preferred language.

4. **No delete handling** — if a user deletes their profile or bio in UserApiDB, does this table ever remove their row? Currently the SP has no DELETE step. Stale rows for deleted accounts will accumulate indefinitely.

5. **Sticky = empty string vs. NULL**: 46,059 rows have Sticky='' (empty string). Is this a user action (intentionally cleared sticky) or an ETL artifact (UserApiDB stores empty string for "no sticky")? Clarifying this affects null-handling in queries.

## Known Anomalies

- Only 62 rows have a non-empty, non-null Sticky value — this field appears nearly unused despite being in the schema.
- `LanguageCode` = empty string for 14.9% of rows — likely customers without detected bio language (empty bio at time of insert).
- SP uses `WITH (NOLOCK)` on the UPDATE join — dirty read risk if External table is mid-ETL refresh.
- Table has accumulated since 2020-05-17 with no purge mechanism. Old rows for inactive/deleted customers persist indefinitely.
