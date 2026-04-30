# Schema Overview: C2P - WalletConversionDB

> The C2P (Crypto-to-Position) schema links crypto-to-fiat conversions to trading positions opened with the converted fiat proceeds on the eToro platform.

## Purpose

When a customer converts cryptocurrency with TargetPlatformId=3 (EtoroPosition), the fiat proceeds are used to open a trading position. The C2P schema records this link, providing end-to-end traceability from crypto sell to position open. This is one of three possible conversion destinations (the others being IbanAccount and EtoroPlatform, handled by the fiat payment system).

## Architecture

```
C2F.Conversions (TargetPlatformId=3)
         |
         | ConversionId
         v
C2P.Positions
  - ConversionId -> C2F.Conversions.Id
  - PositionId -> Trading Platform Position GUID
```

## Data Profile

| Metric | Value |
|--------|-------|
| Positions recorded | 2,415 |
| Data range | 2025-12-11 to present |
| Related conversions | ~2,815 (EtoroPosition target) |
| Coverage | ~86% (some conversions fail before position step) |

## Documentation Quality

| Metric | Value |
|--------|-------|
| **Total Objects** | 2 |
| **Average Quality** | 9.0/10 |
| **Sessions Used** | 1 |
| **Completed** | 2026-04-15 |

---

*Generated: 2026-04-15*
