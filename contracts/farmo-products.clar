;; Farmo Products Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-product-exists (err u101))
(define-constant err-product-not-found (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-invalid-status (err u104))

;; Valid status values
(define-constant status-registered "registered")
(define-constant status-in-transit "in-transit")
(define-constant status-delivered "delivered")

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
    metadata: (optional (string-ascii 256)),
    timestamp: uint
  }
)

(define-data-var history-counter uint u0)

;; Helper functions
(define-private (validate-string (value (string-ascii 64)))
  (and 
    (not (is-eq value ""))
    (<= (len value) u64)))

(define-private (validate-status (status (string-ascii 20)))
  (or
    (is-eq status status-registered)
    (is-eq status status-in-transit)
    (is-eq status status-delivered)))

(define-private (log-history 
  (product-id uint) 
  (action (string-ascii 20)) 
  (from (optional principal)) 
  (to (optional principal))
  (metadata (optional (string-ascii 256))))
  (let ((counter (+ (var-get history-counter) u1)))
    (var-set history-counter counter)
    (map-set product-history
      { product-id: product-id, action-id: counter }
      {
        action: action,
        from: from,
        to: to,
        metadata: metadata,
        timestamp: block-height
      }
    )
  ))

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
      status: status-registered
    }))
    (asserts! (validate-string name) err-invalid-input)
    (asserts! (validate-string origin) err-invalid-input)
    (if (map-get? products { product-id: product-id })
      err-product-exists
      (begin
        (map-set products { product-id: product-id } product-data)
        (log-history product-id "registered" none (some tx-sender) none)
        (ok true)))))

;; Update product status
(define-public (update-status
  (product-id uint)
  (new-status (string-ascii 20)))
  (let ((product (map-get? products { product-id: product-id })))
    (asserts! (is-some product) err-product-not-found)
    (asserts! (validate-status new-status) err-invalid-status)
    (asserts! (is-eq (get owner (unwrap-panic product)) tx-sender) err-not-owner)
    (begin
      (map-set products
        { product-id: product-id }
        (merge (unwrap-panic product) { status: new-status }))
      (log-history 
        product-id 
        "status-update" 
        (some tx-sender) 
        none 
        (some (concat "Status changed to: " new-status)))
      (ok true))))

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
        (log-history product-id "transfer" (some tx-sender) (some new-owner) none)
        (ok true))
      err-product-not-found)))

;; Get product details
(define-read-only (get-product (product-id uint))
  (ok (map-get? products { product-id: product-id })))

;; Get product history with pagination
(define-read-only (get-product-history 
  (product-id uint) 
  (page uint) 
  (limit uint))
  (let 
    ((start (* page limit))
     (end (+ start limit)))
    (ok (map-get? product-history 
      { product-id: product-id, action-id: (var-get history-counter) }))))
