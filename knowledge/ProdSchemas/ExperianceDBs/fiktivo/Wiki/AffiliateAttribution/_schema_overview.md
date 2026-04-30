# AffiliateAttribution Schema Overview

> Databricks-driven affiliate re-attribution workflow - three procedures that look up, update, and signal re-processing when a customer is transferred from one affiliate to another.

## Purpose

The AffiliateAttribution schema provides the database-side operations for the affiliate re-attribution process. When business rules or operations staff determine that a customer should be attributed to a different affiliate, a Databricks notebook orchestrates a three-step workflow that reads eligibility data, updates commission records, and signals the event pipeline for re-processing.

## Architecture

```
Databricks Re-Attribution Notebook
    |
    | Step 1: Eligibility Check
    | EXEC GetAffiliateInfo @CID, @TargetAffiliateID
    |   -> Returns: current affiliate's MarketingExpenseID
    |   -> Returns: target affiliate's MarketingExpenseID
    |   -> Notebook evaluates: can this customer be re-attributed?
    |
    | Step 2: Commission Re-Attribution (if eligible)
    | EXEC UpdateAffiliationInfo @AffiliateID, @CID
    |   -> Updates CreditCommission.AffiliateID (Tier 1)
    |   -> Updates ClosedPositionCommission.AffiliateID (Tier 1)
    |   -> Updates RegistrationCommission.AffiliateID (Tier 1)
    |   -> All within a single XACT_ABORT transaction
    |
    | Step 3: Signal Event Re-Processing
    | EXEC UpdateEvents @AffiliateID, @CID
    |   -> Sets ReAttributeUpdated = GETUTCDATE() on CreditEvent
    |   -> Sets ReAttributeUpdated = GETUTCDATE() on ClosedPositionEvent
    |   -> Commission pipeline detects and re-evaluates events
    v
Commission Pipeline Re-Processing
    -> Sub-affiliate commissions recalculated
    -> Eligibility rules re-evaluated
    -> Event states updated
```

## Object Summary

| Object | Type | Role |
|--------|------|------|
| GetAffiliateInfo | SP | Step 1: Reads current + target affiliate MarketingExpenseID for eligibility |
| UpdateAffiliationInfo | SP | Step 2: Updates AffiliateID on 3 Tier-1 commission tables (transactional) |
| UpdateEvents | SP | Step 3: Timestamps event records to trigger pipeline re-processing |

## Key Design Patterns

- **Three-step workflow**: Lookup -> Update -> Signal. Each step is a separate procedure for modularity.
- **XACT_ABORT transactions**: Both write procedures use XACT_ABORT ON + explicit transactions for atomicity.
- **Tier-1 only**: Only direct affiliate (Tier=1) commission records are modified. Sub-affiliate tiers are recalculated by the pipeline.
- **Event signaling via timestamp**: ReAttributeUpdated column on event tables serves as a "dirty flag" for the commission pipeline.
- **No RegistrationMetaData**: Originally updated RegistrationMetaData, but this was moved to a separate SP (PART-2757).

## Cross-Schema Dependencies

All 3 procedures operate on objects in the AffiliateCommission schema:

| AffiliateCommission Object | Used By | Operation |
|---------------------------|---------|-----------|
| RegistrationVW | GetAffiliateInfo | READ (find current affiliate) |
| CreditCommission | UpdateAffiliationInfo | UPDATE (set AffiliateID) |
| Credit | UpdateAffiliationInfo | READ (JOIN filter by CID) |
| ClosedPositionCommission | UpdateAffiliationInfo | UPDATE (set AffiliateID) |
| ClosedPosition | UpdateAffiliationInfo | READ (JOIN filter by CID) |
| RegistrationCommission | UpdateAffiliationInfo | UPDATE (set AffiliateID) |
| Registration | UpdateAffiliationInfo | READ (JOIN filter by CID) |
| CreditEvent | UpdateEvents | UPDATE (set ReAttributeUpdated) |
| ClosedPositionEvent | UpdateEvents | UPDATE (set ReAttributeUpdated) |

Also depends on: dbo.tblaff_Affiliates (MarketingExpenseID lookup)

## JIRA References

- **PART-1999**: Original implementation - Databricks notebook re-attribution (Oct 2023, Gil Haba)
- **PART-2440**: Fixed CPA revenue support in re-attribution (Jan 2024, Gil Haba)
- **PART-2757**: Removed RegistrationMetaData update, moved to separate SP (Feb 2024, Gil Haba)
