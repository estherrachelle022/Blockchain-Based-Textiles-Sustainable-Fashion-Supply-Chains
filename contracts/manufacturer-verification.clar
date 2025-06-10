;; Manufacturer Verification Contract
;; Validates and manages textile manufacturer credentials

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MANUFACTURER_EXISTS (err u101))
(define-constant ERR_MANUFACTURER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Manufacturer status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Manufacturer data structure
(define-map manufacturers
  { manufacturer-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    certification-level: uint,
    status: uint,
    verified-at: uint,
    verified-by: principal
  }
)

(define-data-var next-manufacturer-id uint u1)

;; Register a new manufacturer
(define-public (register-manufacturer (name (string-ascii 100)) (location (string-ascii 100)))
  (let ((manufacturer-id (var-get next-manufacturer-id)))
    (asserts! (is-none (map-get? manufacturers { manufacturer-id: manufacturer-id })) ERR_MANUFACTURER_EXISTS)
    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      {
        name: name,
        location: location,
        certification-level: u0,
        status: STATUS_PENDING,
        verified-at: u0,
        verified-by: tx-sender
      }
    )
    (var-set next-manufacturer-id (+ manufacturer-id u1))
    (ok manufacturer-id)
  )
)

;; Verify manufacturer (admin only)
(define-public (verify-manufacturer (manufacturer-id uint) (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
      manufacturer-data
      (begin
        (map-set manufacturers
          { manufacturer-id: manufacturer-id }
          (merge manufacturer-data {
            certification-level: certification-level,
            status: STATUS_VERIFIED,
            verified-at: block-height,
            verified-by: tx-sender
          })
        )
        (ok true)
      )
      ERR_MANUFACTURER_NOT_FOUND
    )
  )
)

;; Get manufacturer details
(define-read-only (get-manufacturer (manufacturer-id uint))
  (map-get? manufacturers { manufacturer-id: manufacturer-id })
)

;; Check if manufacturer is verified
(define-read-only (is-manufacturer-verified (manufacturer-id uint))
  (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
    manufacturer-data (is-eq (get status manufacturer-data) STATUS_VERIFIED)
    false
  )
)
