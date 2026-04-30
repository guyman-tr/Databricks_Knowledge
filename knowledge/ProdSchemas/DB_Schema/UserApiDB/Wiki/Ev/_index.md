# Ev Schema - UserApiDB

| Metric | Value |
|--------|-------|
| **Database** | UserApiDB |
| **Schema** | Ev |
| **Total Objects** | 9 |
| **Documented** | 9 (100%) |
| **Remaining** | 0 |
| **Last Updated** | 2026-04-12 |

---

## Tables

| Object | Quality | Status |
|--------|---------|--------|
| [Ev.CountryToProvider](Tables/Ev.CountryToProvider.md) | 8.2 | Done (Batch 1) |
| [Ev.CustomerResult](Tables/Ev.CustomerResult.md) | 8.6 | Done (Batch 1) |
| [Ev.FieldToCountry](Tables/Ev.FieldToCountry.md) | 8.0 | Done (Batch 1) |
| [Ev.ProviderSetting](Tables/Ev.ProviderSetting.md) | 8.0 | Done (Batch 1) |

## Stored Procedures

| Object | Quality | Status |
|--------|---------|--------|
| [Ev.CreateCustomerResultAndHistory](Stored Procedures/Ev.CreateCustomerResultAndHistory.md) | 8.4 | Done (Batch 1) |
| [Ev.GetAllEvRequiredFields](Stored Procedures/Ev.GetAllEvRequiredFields.md) | 7.4 | Done (Batch 1) |
| [Ev.GetEvRequiredFields](Stored Procedures/Ev.GetEvRequiredFields.md) | 7.4 | Done (Batch 1) |
| [Ev.GetProviderForCountry](Stored Procedures/Ev.GetProviderForCountry.md) | 7.2 | Done (Batch 1) |
| [Ev.GetProviderSettings](Stored Procedures/Ev.GetProviderSettings.md) | 7.4 | Done (Batch 1) |

## Dependency Graph

### Level 0 - All Tables
All 4 tables depend only on Dictionary.EvProvider [done] and Dictionary.EvStatus [done].
- CountryToProvider -> Dictionary.EvProvider (FK)
- CustomerResult -> Dictionary.EvStatus + Dictionary.EvProvider (FKs)
- FieldToCountry -> Dictionary.EvProvider (FK)
- ProviderSetting -> Dictionary.EvProvider (FK)

### Stored Procedures
All SPs read from Ev tables (all L0).
