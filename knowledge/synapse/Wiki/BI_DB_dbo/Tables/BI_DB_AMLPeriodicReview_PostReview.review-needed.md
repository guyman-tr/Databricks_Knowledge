# Review Needed: BI_DB_AMLPeriodicReview_PostReview

**Generated**: 2026-04-22  
**Batch**: 44  
**Reviewer**: Domain SME (Pavlina Masoura / AML compliance team)

---

## 1. DATA BUG — `POA_ExpiryDate` stores IssueDate, not expiry date

**Priority**: HIGH  
**Location**: SP_BI_DB_AMLPeriodicReview_PostReview.sql, line ~167

The SP has a no-op CASE expression:
```sql
CASE 
    WHEN docs.IssueDate < DATEADD(YEAR, -1, GETDATE()) THEN docs.IssueDate 
    ELSE docs.IssueDate 
END AS POA_ExpiryDate
```
Both branches return `docs.IssueDate`. The column name `POA_ExpiryDate` implies an actual document expiry date, but the field stores the **document issue date** (MAX IssueDate of DocumentTypeID=1).

`Is_POA_Expired` is correctly computed as `1 if IssueDate > 1 year ago`, so the expiry logic itself works — but any downstream consumer reading `POA_ExpiryDate` expecting a true expiry date will get the wrong value.

**Action**: Confirm whether a true POA expiry date is available from the document source, and whether the column should be renamed to `POA_IssueDate` or corrected to store an actual expiry date.

---

## 2. VERIFY — `EVStatus` and `EvMatchStatusName` are duplicates

**Priority**: LOW  
Column 14 (`EvMatchStatusName`) and column 30 (`EVStatus`) are both set to `pop.EvMatchStatusName` in the SP. Intentional for UI display convenience, or a legacy artifact? If intentional, document as alias.

---

## 3. VERIFY — `LastEPUpdateDate` duplicates `KYC_LastUpdateDate`

**Priority**: LOW  
Column 34 (`KYC_LastUpdateDate`) and column 40 (`LastEPUpdateDate`) are both `kyc.KYC_LastUpdateDate`. Same source, same value. Intentional redundancy (one for KYC team, one for EP team), or should they differ?

---

## 4. VERIFY — `TotalDepositsCurrentYear` includes future deposits

**Priority**: MEDIUM  
`TotalDepositsCurrentYear` uses `ModificationDateID >= @StratDateCurrYear` with no upper bound (`@EndDateCurrYear` is declared but not used as an upper bound in the WHERE). This means deposits after `@Date` in the same calendar year are included. Verify if this is intentional (full-year view) or should be capped at `@DateID`.

---

## 5. VERIFY — `LatestBIAlertDate` not restricted to post-review period

**Priority**: LOW  
`BIAMLAlerts` correctly filters to alerts after `Review_Due_Date`. However, `LatestBIAlertDate` is the overall MAX AlertDate from `BI_DB_AML_BI_Alerts_New` for the customer (no date filter). This means `LatestBIAlertDate` may predate `Review_Due_Date`. Confirm if this is intentional (showing last ever alert date) or should be the MAX AlertDate within the post-review window.

---

## 6. VERIFY — `Screening_StatusChange` uses 'Changed' not 'OK'

**Priority**: INFO  
Unlike the other 7 `*_StatusChange` fields (which use 'OK' as the else value), `Screening_StatusChange` uses 'Changed' as the ELSE. Values: Resolved / New / No Change / Changed. Confirm this is intentional — it means a change in ScreeningStatus that doesn't fit the Resolved/New/NoChange pattern (e.g., going from PEP to Sanctions) produces 'Changed', not 'OK'. If so, document the distinction clearly for report consumers.
