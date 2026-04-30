# Infra Schema Overview - WalletDB

## Purpose

The Infra schema provides **data integrity infrastructure** for WalletDB. It stores and manages cryptographic checksums (JWT signatures) that attest to the integrity of wallet-related entities. This is a security and compliance subsystem - not a business domain schema.

## Core Concept: Checksum-Based Data Integrity

The schema implements a tamper-detection system where:
1. The application computes an RS256-signed JWT containing a snapshot of an entity's critical fields
2. The JWT signature is stored in Infra.Checksum, keyed by entity ID + entity type
3. To verify integrity, the application retrieves the stored signature and compares it against a freshly computed one
4. A mismatch indicates the entity's data has been modified since the last checksum

## Entity Coverage

Three types of wallet entities are checksummed:

| ChecksumType | Source Entity | Volume | Description |
|-------------|--------------|--------|-------------|
| WalletPool | Wallet.WalletPool | 2.46M | Wallet-to-blockchain-crypto associations (dominant type) |
| Wallet | Wallet.CustomerWalletsView | 1.49M | Individual customer wallet records |
| EtoroExternalAddress | Wallet.EtoroExternalAddresses | 170 | eToro-owned crypto deposit/withdrawal addresses |

## Object Inventory

| Object | Type | Role |
|--------|------|------|
| Infra.Checksum | Table | Central store for all checksum records (~3.95M rows) |
| Infra.ChecksumType | UDT | TVP for batch checksum insertion |
| Infra.ChecksumKey | UDT | TVP for batch checksum lookup |
| Infra.InsertChecksum | SP | Single-record idempotent insert |
| Infra.InsertChecksumList | SP | Batch idempotent insert via ChecksumType TVP |
| Infra.ReadChecksum | SP | Single-record lookup by composite key |
| Infra.ReadChecksums | SP | Batch lookup via ChecksumKey TVP (LEFT JOIN preserves all input keys) |

## Data Flow

```
[Backfill Discovery]                    [Write Path]                [Read/Verify Path]
Wallet.GetWalletsWithNoChecksums        InsertChecksum (single)     ReadChecksum (single)
Wallet.GetWalletPoolWithNoChecksums     InsertChecksumList (batch)  ReadChecksums (batch)
Wallet.GetExternalAddressesWithNo..
        |                                      |                          |
        v                                      v                          v
  "Entities needing              ┌─────────────────────────┐    "Return stored
   checksums"                    │   Infra.Checksum        │     signatures for
        |                        │   ~3.95M rows           │     verification"
        └──── generate JWT ──────│   PAGE compressed       │
              + insert ──────────│   Unique: Id+Type       │
                                 └─────────────────────────┘
```

## Key Design Patterns

1. **Idempotent Inserts**: Both insert SPs skip records that already exist for the same ChecksumId + ChecksumType. Safe for retry/reprocessing.
2. **Immutable Records**: No UPDATE or DELETE procedures exist. Once written, a checksum is permanent.
3. **Batch Operations**: TVP-based batch SPs (InsertChecksumList, ReadChecksums) support high-throughput pipeline processing.
4. **Gap Detection**: LEFT JOIN patterns in both ReadChecksums and the Wallet-schema discovery SPs identify entities without checksums.
5. **Cross-Schema Integration**: The Infra schema is referenced by 3 Wallet-schema SPs that drive the backfill pipeline.

## Quality Summary

| Metric | Value |
|--------|-------|
| Total Objects | 7 |
| Documented | 7 (100%) |
| Average Quality | 8.9 |
| Lowest Quality | 8.2 (Infra.ChecksumKey) |
| Highest Quality | 9.2 (Infra.Checksum) |
| NAME-INFERRED Elements | 0 |

*Generated: 2026-04-15*
