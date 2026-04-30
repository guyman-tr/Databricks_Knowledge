# History Schema - UserApiDB

| Metric | Value |
|--------|-------|
| **Database** | UserApiDB |
| **Schema** | History |
| **Total Objects** | 14 |
| **Documented** | 14 (100%) |
| **Remaining** | 0 |
| **Last Updated** | 2026-04-12 |

---


## User Defined Types

| Object | Quality | Status |
|--------|---------|--------|
| [History.EvRequestRow](User Defined Types/History.EvRequestRow.md) | 7.0 | Done (Batch 1) |

## Tables

| Object | Quality | Status |
|--------|---------|--------|
| [History.AccountUserInfo](Tables/History.AccountUserInfo.md) | 8.4 | Done (Batch 1) |
| [History.AdditionalCitizenship](Tables/History.AdditionalCitizenship.md) | 7.4 | Done (Batch 1) |
| [History.BasicUserInfo](Tables/History.BasicUserInfo.md) | 8.0 | Done (Batch 1) |
| [History.ContactUserInfo](Tables/History.ContactUserInfo.md) | 8.0 | Done (Batch 1) |
| [History.CustomerAnswers](Tables/History.CustomerAnswers.md) | 8.2 | Done (Batch 1) |
| [History.EvRequest](Tables/History.EvRequest.md) | 8.2 | Done (Batch 1) |
| [History.FastVerificationData](Tables/History.FastVerificationData.md) | 7.4 | Done (Batch 1) |
| [History.FunnelToAttribute](Tables/History.FunnelToAttribute.md) | 7.2 | Done (Batch 1) |
| [History.LogErrorGeneral](Tables/History.LogErrorGeneral.md) | 7.8 | Done (Batch 1) |
| [History.Publications](Tables/History.Publications.md) | 7.4 | Done (Batch 1) |
| [History.RiskUserInfo](Tables/History.RiskUserInfo.md) | 8.4 | Done (Batch 1) |
| [History.UserAttributes](Tables/History.UserAttributes.md) | 7.4 | Done (Batch 1) |
| [History.UserSettings](Tables/History.UserSettings.md) | 7.4 | Done (Batch 1) |

## Dependency Graph

### All History Tables - Level 0
All History tables are populated by triggers on Customer tables or serve as system versioning history targets. No intra-schema dependencies.

### Population Sources
- AccountUserInfo: Trigger on Customer.AccountUserInfo (INSERT/UPDATE/DELETE)
- BasicUserInfo: Trigger on Customer.BasicUserInfo (INSERT/UPDATE/DELETE)
- ContactUserInfo: Trigger on Customer.ContactUserInfo (INSERT/UPDATE/DELETE)
- RiskUserInfo: Trigger on Customer.RiskUserInfo (INSERT/UPDATE/DELETE)
- UserSettings: Trigger on Customer.UserSettings (INSERT/UPDATE/DELETE)
- AdditionalCitizenship: System versioning target for Customer.AdditionalCitizenship
- FastVerificationData: System versioning target for Customer.FastVerificationData
- Publications: System versioning target for dbo.Publications
- FunnelToAttribute: System versioning target
- UserAttributes: System versioning target
- CustomerAnswers: Archive from KYC.ClearCustomerAnswers
- EvRequest: Populated by Ev schema operations
- LogErrorGeneral: Error logging from InsertLogErrorGeneral synonym
