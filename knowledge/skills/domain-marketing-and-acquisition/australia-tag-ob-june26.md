---
name: domain-marketing-and-acquisition
description: "Campaign audience-tag view for Australia in BI Output. Covers customer-facing tag exports, identifier handling constraints, and GCID-based linkage expectations for downstream marketing analysis."
triggers:
  - australia_tag_ob_june26
  - australia tag ob june26
  - audience tag
  - marketing cohort list
  - campaign extract
required_tables:
  - main.bi_output.australia_tag_ob_june26
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-19"
---

# Australia Tag OB June26 Audience View

## When to Use
Use when the question is about the Australia campaign cohort extract in `main.bi_output.australia_tag_ob_june26`, including who is tagged, what identity fields are present, or how to link the extract to enterprise customer identity safely.

## Scope
In scope: campaign audience-tag rows and fields in `main.bi_output.australia_tag_ob_june26`, including `$distinct_id`, `$GCID`, geo fields, and direct identifiers carried by the export.
Out of scope: canonical customer lifecycle definitions, customer master identity modeling, and product-wide attribution frameworks from sibling hubs.
Last verified: 2026-06-19

## Critical Warnings
1. **Tier 1 - silent wrong:** Do not treat this view as a canonical customer master; it is a campaign extract and can include temporary or campaign-specific states.
2. **Tier 2 - inflat:** Avoid counting unique customers by raw email/name fields without deduping on stable identifiers (`$GCID` or `$distinct_id`) to prevent inflated audience counts.
3. **Tier 3 - dependency:** Prefer GCID-based joins into enterprise models; direct identifier joins depend on export hygiene and may drift by campaign run.

## Field Guidance
- `$distinct_id`: source campaign identity key for audience membership.
- `$GCID`: preferred bridge to enterprise customer identity.
- `$name`, `$email`: direct identifiers; treat as sensitive.
- `$country_code`, `$region`, `$city`, `$last_seen`: targeting and recency context for campaign analysis.
