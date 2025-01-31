;; TrustVaultEscrow
;; A secure escrow service implemented in Clarity

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-NOT-ACTIVE (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-ALREADY-COMPLETED (err u104))

;; Data vars
(define-data-var contract-owner principal tx-sender)
(define-data-var escrow-fee uint u1000) ;; 0.1% fee in basis points

;; Data maps
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    status: (string-ascii 20),
    buyer-approved: bool,
    seller-approved: bool,
    created-at: uint
  }
)

(define-data-var next-escrow-id uint u1)

;; Public functions

;; Initialize a new escrow
(define-public (create-escrow (seller principal) (amount uint))
  (let ((escrow-id (var-get next-escrow-id)))
    (if (>= amount (* u1000000 u1)) ;; Minimum 1 STX
        (begin
          (map-set escrows
            { escrow-id: escrow-id }
            {
              buyer: tx-sender,
              seller: seller,
              amount: amount,
              status: "PENDING",
              buyer-approved: false,
              seller-approved: false,
              created-at: block-height
            }
          )
          (var-set next-escrow-id (+ escrow-id u1))
          (ok escrow-id)
        )
        (err ERR-INSUFFICIENT-FUNDS)
    )
  )
)

;; Deposit funds into escrow
(define-public (deposit (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-NOT-ACTIVE))
    (amount (get amount escrow))
  )
    (if (and
          (is-eq (get buyer escrow) tx-sender)
          (is-eq (get status escrow) "PENDING")
        )
        (begin
          (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
          (map-set escrows
            { escrow-id: escrow-id }
            (merge escrow { status: "FUNDED" })
          )
          (ok true)
        )
        ERR-NOT-AUTHORIZED
    )
  )
)

;; Approve escrow completion
(define-public (approve-escrow (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-NOT-ACTIVE))
  )
    (if (is-eq (get status escrow) "FUNDED")
        (begin
          (if (is-eq tx-sender (get buyer escrow))
              (begin
                (map-set escrows
                  { escrow-id: escrow-id }
                  (merge escrow { buyer-approved: true })
                )
                (ok true)
              )
              (if (is-eq tx-sender (get seller escrow))
                  (begin
                    (map-set escrows
                      { escrow-id: escrow-id }
                      (merge escrow { seller-approved: true })
                    )
                    (ok true)
                  )
                  ERR-NOT-AUTHORIZED
              )
          )
        )
        ERR-NOT-ACTIVE
    )
  )
)

;; Release funds to seller
(define-public (release-funds (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-NOT-ACTIVE))
    (amount (get amount escrow))
    (fee (/ (* amount (var-get escrow-fee)) u100000))
  )
    (if (and
          (is-eq (get status escrow) "FUNDED")
          (get buyer-approved escrow)
          (get seller-approved escrow)
        )
        (begin
          ;; Transfer main amount to seller
          (try! (as-contract (stx-transfer? (- amount fee) tx-sender (get seller escrow))))
          ;; Transfer fee to contract owner
          (try! (as-contract (stx-transfer? fee tx-sender (var-get contract-owner))))
          (map-set escrows
            { escrow-id: escrow-id }
            (merge escrow { status: "COMPLETED" })
          )
          (ok true)
        )
        ERR-NOT-AUTHORIZED
    )
  )
)

;; Refund buyer if conditions are unmet
(define-public (refund (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-NOT-ACTIVE))
    (amount (get amount escrow))
  )
    (if (and
          (is-eq (get status escrow) "FUNDED")
          (> block-height (+ (get created-at escrow) u1440)) ;; 24h timeout
        )
        (begin
          (try! (as-contract (stx-transfer? amount tx-sender (get buyer escrow))))
          (map-set escrows
            { escrow-id: escrow-id }
            (merge escrow { status: "REFUNDED" })
          )
          (ok true)
        )
        ERR-NOT-AUTHORIZED
    )
  )
)

;; Read-only functions

;; Get escrow details
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

;; Check if escrow exists
(define-read-only (escrow-exists (escrow-id uint))
  (is-some (map-get? escrows { escrow-id: escrow-id }))
)