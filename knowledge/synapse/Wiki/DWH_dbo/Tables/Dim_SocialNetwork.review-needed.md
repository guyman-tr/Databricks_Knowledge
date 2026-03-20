# DWH_dbo.Dim_SocialNetwork - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Current Description | Concern |
|--------|---------------------|---------|
| DWHSocialNetworkID | ETL alias of SocialNetworkID (UNVERIFIED) | No active SP found that populates this table. Tier 4 because the ETL origin is unknown for this frozen table. |
| StatusID | Hardcoded 1 (UNVERIFIED) | Same concern - no active SP found. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Production source | What is the production source for this table? Is it etoro.Dictionary.SocialNetwork? Why is it not in SP_Dictionaries_DL_To_Synapse? |
| UpdateDate/InsertDate (2013-2014) | These timestamps indicate a one-time migration in 2013-2014. Is this table intentionally frozen? Will new social networks (Google, Apple) ever be added? |
| SocialNetworkID usage | Which DWH fact tables carry SocialNetworkID? Is it on CustomerStatic or on a separate registration table? |

## Structural Questions

- **Frozen table with no ETL**: This is a 4-row static table with timestamps from 2013-2014. If new OAuth providers are added (e.g., Google, Apple), would they be added here? Or is this dimension now obsolete?
- **No DWH views or SPs reference this table**: Unlike other Dim_ tables, there are no DWH_dbo views or SPs that join to Dim_SocialNetwork in the SSDT repo. Is this table actually used in analytics?
- **Twitter OAuth likely deprecated**: Twitter OAuth integrations are largely inactive post-2023 API changes. Is SocialNetworkID=2 still meaningful?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
