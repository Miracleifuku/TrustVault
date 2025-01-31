# TrustVaultEscrow

## Overview
TrustVaultEscrow is a secure escrow service implemented in Clarity, designed to facilitate safe transactions between buyers and sellers by holding funds in escrow until both parties approve the release.

## Features
- Secure escrow creation and fund deposit.
- Approval mechanism for both buyer and seller.
- Automatic fund release upon mutual approval.
- Refund option if conditions are unmet.
- Read-only functions to check escrow details.

## Error Codes
| Code | Description |
|------|-------------|
| `ERR-NOT-AUTHORIZED` (u100) | Unauthorized action |
| `ERR-ALREADY-INITIALIZED` (u101) | Contract already initialized |
| `ERR-NOT-ACTIVE` (u102) | Escrow is not active |
| `ERR-INSUFFICIENT-FUNDS` (u103) | Insufficient funds to create escrow |
| `ERR-ALREADY-COMPLETED` (u104) | Escrow already completed |

## Data Structures
- **Data Variables**
  - `contract-owner`: Stores the contract deployer's principal.
  - `escrow-fee`: A 0.1% fee (1000 basis points).
- **Data Maps**
  - `escrows`: Stores escrow transactions by ID.
  - `next-escrow-id`: Tracks the next available escrow ID.

## Public Functions
### `create-escrow (seller principal, amount uint) → (response uint)`
Creates a new escrow where the buyer commits funds for a purchase. The amount must be at least 1 STX.

### `deposit (escrow-id uint) → (response bool)`
Allows the buyer to deposit funds into the escrow. The escrow status updates to `FUNDED`.

### `approve-escrow (escrow-id uint) → (response bool)`
Allows either the buyer or the seller to approve the escrow completion.

### `release-funds (escrow-id uint) → (response bool)`
Releases funds to the seller after both parties approve, deducting the escrow fee.

### `refund (escrow-id uint) → (response bool)`
If 24 hours pass without both approvals, the buyer can request a refund.

## Read-Only Functions
### `get-escrow (escrow-id uint) → (response (optional escrow))`
Fetches details of a specific escrow transaction.

### `escrow-exists (escrow-id uint) → (response bool)`
Checks if an escrow exists for the given ID.

## License
This project is open-source under the MIT License.

