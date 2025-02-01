;; Farmo Products Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-product-exists (err u101))
(define-constant err-product-not-found (err u102))

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
    (if (map-get? products { product-id: product-id })
      err-product-exists
      (begin
        (map-set products { product-id: product-id } product-data)
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
        (ok true))
      err-product-not-found)))

;; Get product details
(define-read-only (get-product (product-id uint))
  (ok (map-get? products { product-id: product-id })))
