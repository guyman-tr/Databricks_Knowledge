# Schema Overview: RiskClassification.RiskClassification

## Purpose

The `RiskClassification` schema contains two distinct subsystems within the RiskClassification database:

1. **Customer Onboarding Risk Classification** - A new-generation weighted scoring model that produces continuous decimal risk scores with full JSON scoring breakdowns during customer onboarding
2. **CySEC-Specific Scoring Configuration** - A separate set of CySEC-regulation scoring rules with temporal versioning, independent from the main BackOffice scoring configuration

## Architecture

```
Onboarding Subsystem:
  External Risk Engine
        |
        v
  UpsertCustomerOnboardingRiskClassification (SP)
        |
        v
  CustomerOnboardingRiskClassification (table)
        |
        v
  GetCustomerOnboardingRiskClassification (SP)
        |
        v
  Onboarding Services / Compliance Tools


CySEC Configuration Subsystem:
  CySecRiskClassificationParameter (table, temporal)
        |
        v
  CySecRiskClassificationParameterView (view)
        |
        v
  Compliance Audit / Rule Review
```

## Key Differences from dbo Schema

| Aspect | dbo Schema (Legacy) | RiskClassification Schema (New) |
|--------|-------------------|-------------------------------|
| Score model | Discrete tiers (0/50/100/200) | Continuous weighted decimal (4.5, 10.0, 14.5) |
| Score storage | Denormalized wide columns | Single Score + JSON Data column |
| Transparency | Separate columns per parameter | Full JSON breakdown in Data column |
| History | Temporal system-versioning | No temporal (simple LastUpdate timestamp) |
| Scope | All regulations, all customers | Onboarding-only + CySEC-specific config |

## Objects

| Object | Type | Purpose | Rows |
|--------|------|---------|------|
| CustomerOnboardingRiskClassification | Table | Onboarding risk scores with JSON | ~488K |
| CySecRiskClassificationParameter | Table (Temporal) | CySEC scoring rules config | 65 |
| CySecRiskClassificationParameterView | View | Enriched CySEC rules with names | - |
| GetCustomerOnboardingRiskClassification | SP | Read endpoint for onboarding score | - |
| UpsertCustomerOnboardingRiskClassification | SP | Write endpoint for onboarding score | - |

## Cross-Schema Dependencies

- **Dictionary.CySecRiskClassificationParameter** - FK from CySecRiskClassificationParameter.ParameterID
- **Dictionary.RiskClassificationParameter** - JOIN in CySecRiskClassificationParameterView
- **Dictionary.Regulation** - JOIN in CySecRiskClassificationParameterView
- **Dictionary.RiskClassificationRegulation** - JOIN in CySecRiskClassificationParameterView
- **History.cySecRiskClassificationParameter** - Temporal history table

---

*Generated: 2026-04-14 | Objects: 5 (2 tables, 1 view, 2 stored procedures) | Average quality: 8.9*
