# Review Needed — Dealing_dbo.Dealing_Staking_Emails_US

**Batch**: 10 | **Date**: 2026-03-21 | **Quality**: 7.5/10

## Open Questions

1. **Row-store index inconsistency**: This table uses CLUSTERED INDEX on StakingMonthID while other US staking tables (Club_US, DailyPool_US, Compensation_US) use COLUMNSTORE. Is this intentional?

2. **SUI missing from email list**: SUI is tracked in DailyPool_US (4 instruments) but absent from this email table. Is SUI US staking distribution happening but not notified via email, or has it not started yet?
