---
object: Dealing_PreviouslyIdentifiedAbusers
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_PreviouslyIdentifiedAbusers — Review Notes

## Auto-Generated Flags

- **⚠️ SENSITIVE DATA**: Contains real first/last names of identified abusers. Confirm access controls are in place.
- **Hardcoded name list in SP**: ~120 name entries are in the SP body. Is there a request process to update this list? Who is responsible for maintaining it? Last update: June 2024.
- **Exact name matching only**: No fuzzy matching. Abusers registering under slight name variations (misspellings, different name order) will not be caught. Is this limitation documented for the Trading team?
- **HASH(CID) distribution**: The table has very few rows and CID is NULL for sentinel rows. HASH on a nullable column with many NULLs may cause distribution skew. Worth reviewing.
- **Date = datetime (not date)**: Consistent with SuspiciousActivityTrading_24H. Time is always 00:00:00.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
