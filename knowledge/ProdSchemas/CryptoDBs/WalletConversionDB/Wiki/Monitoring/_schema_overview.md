# Schema Overview: Monitoring - WalletConversionDB

> The Monitoring schema provides operational health checks, data integrity validation, compliance monitoring, and alerting procedures for the crypto-to-fiat conversion system.

## Purpose

The Monitoring schema contains 12 stored procedures (no tables) that query the C2F and Dictionary tables to detect operational issues. These procedures are called by automated monitoring systems and operational dashboards to ensure the conversion pipeline is healthy, data is consistent, and regulatory limits are respected.

## Procedure Categories

### Compliance Monitoring (2 SPs)
| Procedure | What It Detects |
|-----------|----------------|
| C2FUserBreachLimitations | Accounts exceeding USD conversion limits ($25K/day, $250K/month, $2.5M/year) |
| C2FUserBreachLimitations_temp | Same logic with lower thresholds ($6K/$60K/$250K) for testing/stricter monitoring |

### Conversion Listing (2 SPs)
| Procedure | What It Shows |
|-----------|---------------|
| GetAllC2FConversions | All completed C2F conversions (IbanAccount + EtoroPlatform targets) |
| GetAllC2PConversions | All completed C2P conversions (EtoroPosition target) |

### Pipeline Health (3 SPs)
| Procedure | What It Detects |
|-----------|----------------|
| GetFailedC2Fs | Failed conversions with error details (last N hours) |
| GetOpenConversionsForLongTime | Stuck Pending conversions older than threshold (default 10 hours) |
| GetDoneConversionsWithoutFiatTransactions | Completed conversions missing fiat credit (critical) |

### Data Integrity (3 SPs)
| Procedure | What It Detects |
|-----------|----------------|
| GetConversionStatusesWithoutConversion | Orphaned status records |
| GetEstimatedFiatTransactionsWithoutConversion | Orphaned estimate records |
| GetFiatTransactionsWithoutEstimatedFiatTransactions | Fiat records missing estimates |

### Rate Monitoring (1 SP)
| Procedure | What It Detects |
|-----------|----------------|
| GetFiatTransactionsToEstimatedFiatTransactionsLargeDifference | Conversions with >5% rate slippage between estimate and actual |

### Wallet Reconciliation (1 SP)
| Procedure | What It Shows |
|-----------|---------------|
| GetAmountPerCryptoAndWallet | Total crypto and USD amounts per blockchain address |

## Documentation Quality

| Metric | Value |
|--------|-------|
| **Total Objects** | 12 |
| **Average Quality** | 9.0/10 |
| **Sessions Used** | 1 |
| **Completed** | 2026-04-15 |

---

*Generated: 2026-04-15*
