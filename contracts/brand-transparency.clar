;; Brand Transparency Contract
;; Provides fashion brand supply chain transparency and traceability

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_PRODUCT_NOT_FOUND (err u501))
(define-constant ERR_BRAND_NOT_FOUND (err u502))

;; Brand registration data structure
(define-map fashion-brands
  { brand-id: uint }
  {
    name: (string-ascii 100),
    owner: principal,
    transparency-score: uint,
    total-products: uint,
    sustainable-products: uint,
    registered-at: uint,
    verified: bool
  }
)

;; Product transparency data structure
(define-map product-transparency
  { product-id: uint }
  {
    brand-id: uint,
    product-name: (string-ascii 100),
    production-id: uint,
    material-batch-ids: (list 10 uint),
    manufacturer-id: uint,
    sustainability-score: uint,
    carbon-footprint: uint,
    water-footprint: uint,
    labor-compliance-score: uint,
    price: uint,
    created-at: uint,
    public: bool
  }
)

(define-data-var next-brand-id uint u1)
(define-data-var next-product-id uint u1)

;; Register fashion brand
(define-public (register-brand (name (string-ascii 100)))
  (let ((brand-id (var-get next-brand-id)))
    (map-set fashion-brands
      { brand-id: brand-id }
      {
        name: name,
        owner: tx-sender,
        transparency-score: u0,
        total-products: u0,
        sustainable-products: u0,
        registered-at: block-height,
        verified: false
      }
    )
    (var-set next-brand-id (+ brand-id u1))
    (ok brand-id)
  )
)

;; Create transparent product record
(define-public (create-product-record
  (brand-id uint)
  (product-name (string-ascii 100))
  (production-id uint)
  (material-batch-ids (list 10 uint))
  (manufacturer-id uint)
  (price uint)
)
  (let ((product-id (var-get next-product-id)))
    (begin
      ;; Calculate sustainability metrics
      (let ((sustainability-score (calculate-product-sustainability production-id material-batch-ids manufacturer-id)))
        (map-set product-transparency
          { product-id: product-id }
          {
            brand-id: brand-id,
            product-name: product-name,
            production-id: production-id,
            material-batch-ids: material-batch-ids,
            manufacturer-id: manufacturer-id,
            sustainability-score: sustainability-score,
            carbon-footprint: u0,
            water-footprint: u0,
            labor-compliance-score: u0,
            price: price,
            created-at: block-height,
            public: false
          }
        )
        (var-set next-product-id (+ product-id u1))
        (update-brand-stats brand-id sustainability-score)
        (ok product-id)
      )
    )
  )
)

;; Make product information public
(define-public (make-product-public (product-id uint))
  (match (map-get? product-transparency { product-id: product-id })
    product-data
    (begin
      (map-set product-transparency
        { product-id: product-id }
        (merge product-data { public: true })
      )
      (ok true)
    )
    ERR_PRODUCT_NOT_FOUND
  )
)

;; Update brand transparency statistics
(define-private (update-brand-stats (brand-id uint) (sustainability-score uint))
  (match (map-get? fashion-brands { brand-id: brand-id })
    brand-data
    (let ((new-total (+ (get total-products brand-data) u1))
          (new-sustainable (if (>= sustainability-score u3)
            (+ (get sustainable-products brand-data) u1)
            (get sustainable-products brand-data)
          )))
      (map-set fashion-brands
        { brand-id: brand-id }
        (merge brand-data {
          total-products: new-total,
          sustainable-products: new-sustainable,
          transparency-score: (/ (* new-sustainable u100) new-total)
        })
      )
      true
    )
    false
  )
)

;; Calculate product sustainability score
(define-private (calculate-product-sustainability
  (production-id uint)
  (material-batch-ids (list 10 uint))
  (manufacturer-id uint)
)
  ;; Simplified calculation - in real implementation would call other contracts
  u3
)

;; Get brand details
(define-read-only (get-brand (brand-id uint))
  (map-get? fashion-brands { brand-id: brand-id })
)

;; Get product transparency details
(define-read-only (get-product-transparency (product-id uint))
  (map-get? product-transparency { product-id: product-id })
)

;; Get public product information only
(define-read-only (get-public-product-info (product-id uint))
  (match (map-get? product-transparency { product-id: product-id })
    product-data
    (if (get public product-data)
      (some product-data)
      none
    )
    none
  )
)

;; Calculate brand transparency score
(define-read-only (get-brand-transparency-score (brand-id uint))
  (match (map-get? fashion-brands { brand-id: brand-id })
    brand-data (some (get transparency-score brand-data))
    none
  )
)
