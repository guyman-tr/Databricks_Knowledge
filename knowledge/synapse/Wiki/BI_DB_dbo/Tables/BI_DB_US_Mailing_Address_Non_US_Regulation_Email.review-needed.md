# BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Single row currently**: Table has only 1 row as of 2026-04-08. Is this expected, or has the detection pipeline slowed significantly?
2. **Email consumer unknown**: What system reads this table for email delivery? No downstream consumers found in wiki inventory.
3. **TRUNCATE timing**: If the email system reads mid-refresh, it could see an empty table. Is there a dependency/ordering guarantee?
