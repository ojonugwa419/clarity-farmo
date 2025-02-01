;; Farmo Participants Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-already-registered (err u101))

;; Data structures
(define-map participants
  { address: principal }
  {
    name: (string-ascii 64),
    role: (string-ascii 32),
    verified: bool,
    registration-date: uint
  }
)

;; Register participant
(define-public (register-participant
  (name (string-ascii 64))
  (role (string-ascii 32)))
  (let
    ((participant-data {
      name: name,
      role: role,
      verified: false,
      registration-date: block-height
    }))
    (if (map-get? participants { address: tx-sender })
      err-already-registered
      (begin
        (map-set participants { address: tx-sender } participant-data)
        (ok true)))))

;; Verify participant
(define-public (verify-participant (address principal))
  (if (is-eq tx-sender contract-owner)
    (let ((participant (map-get? participants { address: address })))
      (if (is-some participant)
        (begin
          (map-set participants
            { address: address }
            (merge (unwrap-panic participant) { verified: true }))
          (ok true))
        (err u102)))
    err-not-owner))

;; Get participant details
(define-read-only (get-participant (address principal))
  (ok (map-get? participants { address: address })))
