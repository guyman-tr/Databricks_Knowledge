# Dictionary.AppropriatenessProduct

**Schema:** Dictionary
**Table:** AppropriatenessProduct
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.AppropriatenessProduct` is a static reference table that classifies the financial products for which an appropriateness assessment must be performed before a user may trade. Appropriateness testing is a regulatory requirement — under frameworks such as MiFID II and equivalent US rules — that obligates the broker to evaluate whether a client has sufficient knowledge and experience for a given product type.

Each row represents a product category that has its own appropriateness questionnaire, scoring logic, and eligibility outcome. The `None` entry (ID 0) acts as a sentinel value for contexts where no specific product has yet been evaluated. The remaining three entries cover the major retail product lines offered: CFDs (Contracts for Difference), FPSL (Fully Paid Securities Lending), and Options.

This table is referenced by `Apex.Options` (to record which product a user's appropriateness decision relates to) and by `Apex.UserFpslEnrolment` (to record the appropriateness product evaluated at the point of FPSL enrolment).

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| AppropriatenessProductID | int | NOT NULL | Yes | Numeric identifier for the product category; 0 is the conventional null/not-applicable sentinel. |
| Name | varchar(50) | NOT NULL | No | Short product code used throughout the application layer to identify the assessed product type. |

**Constraints:**
- `PK_AppropriatenessProduct` — clustered primary key on `AppropriatenessProductID`

---

## 3. Data Overview

4 rows as of 2026-04-14.

| AppropriatenessProductID | Name | Meaning |
|---|---|---|
| 0 | None | No specific product has been assessed; used as the default/uninitialised state in referencing tables. |
| 1 | CFD | Contract for Difference products — a leveraged derivative product class requiring suitability evaluation under retail client protection rules. |
| 2 | FPSL | Fully Paid Securities Lending — a programme in which users lend out fully paid shares; appropriateness is assessed at enrolment. |
| 3 | Options | Listed equity and index options — complex instruments requiring the user to demonstrate knowledge before trading is enabled. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | AppropriatenessProductID | Records which product category the options application's appropriateness decision is associated with. |
| Apex.UserFpslEnrolment | AppropriatenessProductID | Records the appropriateness product evaluated when a user enrols in the FPSL programme. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count options applications by product type
SELECT ap.Name AS Product,
       COUNT(*) AS ApplicationCount
FROM   Apex.Options o WITH (NOLOCK)
JOIN   Dictionary.AppropriatenessProduct ap WITH (NOLOCK)
       ON o.AppropriatenessProductID = ap.AppropriatenessProductID
GROUP  BY ap.Name
ORDER  BY ApplicationCount DESC;
```

```sql
-- Find FPSL enrolments where appropriateness product is not None
SELECT ue.*
FROM   Apex.UserFpslEnrolment ue WITH (NOLOCK)
WHERE  ue.AppropriatenessProductID <> 0;
```

---

## 6. Data Quality Notes

- ID 0 (`None`) is used as a sentinel rather than a NULL FK, ensuring referential integrity is maintained even when no product applies.
- The value set is small and stable; new product categories require coordinated changes across questionnaire configuration, scoring rules, and this table.
- `Name` uses `varchar(50)` (non-Unicode), which is appropriate given all product codes are ASCII.
- No `DisplayName` or `Description` column exists; descriptive text must be maintained in application-layer resource files.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 4 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | Fact table recording the appropriateness assessment outcome per user per product. |
| Apex.UserFpslEnrolment | Table | Records FPSL programme enrolment including the appropriateness product evaluated. |
| Dictionary.AppropriatenessTestResult | Table | Sibling dictionary: records the pass/fail outcome of each appropriateness assessment. |
| Dictionary.AppropriatenessRecalculationReason | Table | Sibling dictionary: records why an appropriateness assessment was recalculated. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
