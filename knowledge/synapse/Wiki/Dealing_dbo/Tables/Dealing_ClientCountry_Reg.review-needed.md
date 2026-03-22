---
object: Dealing_ClientCountry_Reg
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientCountry_Reg — Review Notes

## Auto-Generated Flags

- **Global regulation IDs (3,5,11)**: These regulations (NFA, FSRA and one other) have Region=NULL in the SP — meaning all customers under them are counted as IsSameRegion=1 regardless of geography. Is this still the correct treatment?
- **Count_DiffRegion > 0**: Sample data shows 8 customers under FinCEN+FINRA in a different region. Is this expected (e.g., dual-national accounts) or actionable?
- **No CountryID population check**: The SP uses all customers from Dim_Customer. Customers with NULL CountryID map to ISNULL(r.Country, c.Name) — are NULL country customers counted?

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
