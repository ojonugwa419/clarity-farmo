;; Farmo Products Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-product-exists (err u101))
(define-constant err-product-not-found (err u102))
(define-constant err-invalid-input (err u103))

;; Data structures
(define-map products
  { product-id: uint }
  {
    owner: principal,
    name: (string-ascii 64),
    description: (string-ascii 256),
    origin: (string-ascii 64),
    created-at: uint,
    status: (string-ascii 20)
  }
)

;; Product history tracking
(define-map product-history
  { product-id: uint, action-id: uint }
  {
    action: (string-ascii 20),
    from: (optional principal),
    to: (optional principal),
    timestamp: uint
  }
)

(define-data-var history-counter uint u0)

;; Helper functions
(define-private (validate-string (value (string-ascii 64)))
  (not (is-eq value "")))

(define-private (log-history (product-id uint) (action (string-ascii 20)) (from (optional principal)) (to (optional principal)))
  (let ((counter (+ (var-get history-counter) u1)))
    (var-set history-counter counter)
    (map-set product-history
      { product-id: product-id, action-id: counter }
      {
        action: action,
        from: from,
        to: to,
        timestamp: block-height
      }
    )
  )
)

;; Product registration
(define-public (register-product 
  (product-id uint)
  (name (string-ascii 64))
  (description (string-ascii 256))
  (origin (string-ascii 64)))
  (let
    ((product-data {
      owner: tx-sender,
      name: name,
      description: description,
      origin: origin,
      created-at: block-height,
      status: "registered"
    }))
    (asserts! (validate-string name) err-invalid-input)
    (asserts! (validate-string origin) err-invalid-input)
    (if (map-get? products { product-id: product-id })
      err-product-exists
      (begin
        (map-set products { product-id: product-id } product-data)
        (log-history product-id "registered" none (some tx-sender))
        (ok true)))))

;; Transfer product ownership
(define-public (transfer-product
  (product-id uint)
  (new-owner principal))
  (let ((product (map-get? products { product-id: product-id })))
    (if (and
          (is-some product)
          (is-eq (get owner (unwrap-panic product)) tx-sender))
      (begin
        (map-set products
          { product-id: product-id }
          (merge (unwrap-panic product) { owner: new-owner }))
        (log-history product-id "transfer" (some tx-sender) (some new-owner))
        (ok true))
      err-product-not-found)))

;; Get product details
(define-read-only (get-product (product-id uint))
  (ok (map-get? products { product-id: product-id })))

;; Get product history
(define-read-only (get-product-history (product-id uint))
  (ok (map-get? product-history { product-id: product-id, action-id: (var-get history-counter) })))
