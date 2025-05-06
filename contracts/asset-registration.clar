;; Asset Registration Contract
;; Records details of industrial machinery as non-fungible tokens

(define-non-fungible-token asset uint)

;; Data structures
(define-map asset-details
  { asset-id: uint }
  {
    name: (string-utf8 100),
    manufacturer: (string-utf8 100),
    model: (string-utf8 100),
    serial-number: (string-utf8 100),
    installation-date: uint,
    warranty-expiration: uint,
    location: (string-utf8 100),
    owner: principal
  }
)

;; Counter for asset IDs
(define-data-var last-asset-id uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ASSET-EXISTS u2)
(define-constant ERR-ASSET-NOT-FOUND u3)

;; Register a new asset
(define-public (register-asset
    (name (string-utf8 100))
    (manufacturer (string-utf8 100))
    (model (string-utf8 100))
    (serial-number (string-utf8 100))
    (installation-date uint)
    (warranty-expiration uint)
    (location (string-utf8 100))
  )
  (let ((new-asset-id (+ (var-get last-asset-id) u1)))
    ;; Mint a new NFT for the asset
    (try! (nft-mint? asset new-asset-id tx-sender))

    ;; Store asset details
    (map-set asset-details
      { asset-id: new-asset-id }
      {
        name: name,
        manufacturer: manufacturer,
        model: model,
        serial-number: serial-number,
        installation-date: installation-date,
        warranty-expiration: warranty-expiration,
        location: location,
        owner: tx-sender
      }
    )

    ;; Update the asset ID counter
    (var-set last-asset-id new-asset-id)

    ;; Return the new asset ID
    (ok new-asset-id)
  )
)

;; Get asset details
(define-read-only (get-asset-details (asset-id uint))
  (match (map-get? asset-details { asset-id: asset-id })
    details (ok details)
    (err ERR-ASSET-NOT-FOUND)
  )
)

;; Transfer asset ownership
(define-public (transfer-asset (asset-id uint) (recipient principal))
  (begin
    ;; Check if sender is the owner
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (err ERR-NOT-AUTHORIZED))

    ;; Transfer the NFT
    (try! (nft-transfer? asset asset-id tx-sender recipient))

    ;; Update the owner in asset details
    (match (map-get? asset-details { asset-id: asset-id })
      details (begin
        (map-set asset-details
          { asset-id: asset-id }
          (merge details { owner: recipient })
        )
        (ok true)
      )
      (err ERR-ASSET-NOT-FOUND)
    )
  )
)

;; Update asset details
(define-public (update-asset-location (asset-id uint) (new-location (string-utf8 100)))
  (begin
    ;; Check if sender is the owner
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? asset asset-id) (err ERR-ASSET-NOT-FOUND)))
      (err ERR-NOT-AUTHORIZED))

    ;; Update the location
    (match (map-get? asset-details { asset-id: asset-id })
      details (begin
        (map-set asset-details
          { asset-id: asset-id }
          (merge details { location: new-location })
        )
        (ok true)
      )
      (err ERR-ASSET-NOT-FOUND)
    )
  )
)
