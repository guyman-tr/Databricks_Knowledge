---
object: Dealing_Islamic_Daily_Administrative_Fee
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_Islamic_Daily_Administrative_Fee

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ 25 suspended instruments blacklist | Hardcoded in SP (SR-258928). If instruments are re-activated or newly suspended, SP requires manual update. |
| ⚠️ InstrumentID=62 triple-day | Uses Count_Thu (Thursdays=3) instead of Count_Wed. Confirm what instrument 62 is and why it differs. |
| ⚠️ German Crypto exclusion | CountryID=79, leverage=1, IsBuy=1 excluded. Confirm this is a BaFin regulatory requirement (not commercial). |
| ⚠️ ClosedOnWeekend | Weekend-closed positions (`ClosedOnWeekend=1`) are excluded from stored rows (commented-out code in SP). Confirm this is intentional. |
| ℹ️ Manual fee config | Admin_Fee_USD and GracePeriod come from Dealing_Islamic_Admin_Fee_Per_Group — manual table. Changes need table updates. |

## Questions for Reviewer

1. Is the 25-instrument blacklist still current as of today, or have any instruments been re-activated/newly suspended since SR-258928?
2. What is InstrumentID=62 and why does it use Thursday as its triple day instead of Wednesday?
3. Is the German Crypto exclusion (CountryID=79) a BaFin requirement or an eToro commercial decision? Are other jurisdictions similarly excluded?
4. Weekend-closed positions are excluded: is this by design (they've already been charged the gap days), or a known data gap?
5. Are there any Islamic clients on Count_All (ExchangeID=8)? What instrument types use ExchangeID=8?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
