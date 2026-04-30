# History.GetOnePipValueDollarForDealing_org

> Identical to History.GetOnePipValueDollarForDealing_old - the original ("_org") version of the Dealing pip value function before SpreadGroup-based cross-pair adjustment was added.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetOnePipValueDollarForDealing_org(@CID, @InstrumentID, @ProviderID, @IsBuy, @pSpreadedPipBid, @pSpreadedPipAsk, @pPercision) RETURNS MONEY` |
| **Purpose** | Original version of GetOnePipValueDollarForDealing - identical to _old variant |

---

## 1. Business Meaning

`History.GetOnePipValueDollarForDealing_org` ("_org" = original) is byte-for-byte identical to `History.GetOnePipValueDollarForDealing_old`. Both are the pre-SpreadGroup version of the Dealing pip value function. The `_org` suffix was added to preserve the original code when the function was upgraded.

This function has EXECUTE permission granted to the Dealing role (from `UsersPermissions/Dealing.sql`), suggesting it was once called from the Dealing application before being replaced. No SSDT stored procedures reference it.

**For full documentation, see `History.GetOnePipValueDollarForDealing_old.md`** - the behavior is identical.

---

## 2. Business Logic

Identical to `History.GetOnePipValueDollarForDealing_old`. Uses Trade.LastWeekPrices. Cross pairs use simple `@SpreadBid` adjustment (no SpreadGroup joins).

---

## 3. Data Overview

N/A - no active consumers.

---

## 4. Elements

Identical to `History.GetOnePipValueDollarForDealing_old` - see that document.

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `History.GetOnePipValueDollarForDealing_old`: Trade.Provider, Trade.Instrument, Dictionary.Currency, Customer.Customer, Trade.LastWeekPrices.

### 5.2 Referenced By (other objects point to this)

No active SSDT repo consumers. Has EXECUTE GRANT for Dealing role (application-level grant only).

---

## 6. Dependencies

Same as `History.GetOnePipValueDollarForDealing_old`.

---

## 7. Technical Details

Together with `History.GetOnePipValueDollarForDealing_old`, this is a duplicate legacy artifact. Candidate for removal.

---

## 8. Sample Queries

See `History.GetOnePipValueDollarForDealing.md`.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 7.8/10, Logic: 8.0/10, Relationships: 7.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/5 (1, 8, 10, 11) - legacy function*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOnePipValueDollarForDealing_org | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetOnePipValueDollarForDealing_org.sql*
