---
name: domain-marketing-and-acquisition
description: Marketing audience cohort artifacts in bi_output, including campaign-specific CSV-backed audience tags and identity link fields for downstream analytics.
required_tables:
  - main.bi_output.australia_tag_ob_june26
version: 1
owner: dataplatform
---

# Australia Tag OB June26 Audience View

## Object
- main.bi_output.australia_tag_ob_june26
- Type: VIEW
- Source: CSV file in BI_OUTPUT Marketing Bar path

## Semantic Meaning
This object represents a campaign-oriented audience tag extract for Australia.
It is a marketing cohort list rather than a stable product semantic model.

## Fields and Usage Notes
- $distinct_id: campaign identity key from source export
- $name, $email: direct identifiers (PII-like fields); restricted handling required
- $last_seen, $country_code, $region, $city: campaign targeting and segmentation context
- $GCID: bridge field for controlled linkage to enterprise customer identity

## Guidance
- Treat this as campaign/supporting metadata, not a canonical customer master.
- Prefer GCID-based joins over direct identifier joins where possible.
- Keep clear retention boundaries because this object is likely campaign-temporary.
