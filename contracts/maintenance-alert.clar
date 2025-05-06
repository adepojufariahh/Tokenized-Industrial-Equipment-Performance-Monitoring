;; Maintenance Alert Contract
;; Triggers service based on performance metrics

;; Data structures
(define-map maintenance-alerts
  { alert-id: uint }
  {
    asset-id: uint,
    alert-type: (string-utf8 50),
    description: (string-utf8 200),
    severity: uint,  ;; 1-5, with 5 being most severe
    timestamp: uint,
    resolved: bool,
    resolution-timestamp: (optional uint),
    resolution-notes: (optional (string-utf8 200))
  }
)

;; Track alerts by asset
(define-map asset-alerts
  { asset-id: uint }
  { alert-count: uint, open-alerts: uint }
)

;; Counter for alert IDs
(define-data-var last-alert-id uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ALERT-NOT-FOUND u2)
(define-constant ERR-ALREADY-RESOLVED u3)

;; Create a new maintenance alert
(define-public (create-alert
    (asset-id uint)
    (alert-type (string-utf8 50))
    (description (string-utf8 200))
    (severity uint)
  )
  (let (
    (new-alert-id (+ (var-get last-alert-id) u1))
    (timestamp (unwrap-panic (get-block-info? time u0)))
    (current-asset-alerts (default-to { alert-count: u0, open-alerts: u0 }
                          (map-get? asset-alerts { asset-id: asset-id })))
  )
    ;; Validate severity (1-5)
    (asserts! (and (>= severity u1) (<= severity u5)) (err u4))

    ;; Store the alert
    (map-set maintenance-alerts
      { alert-id: new-alert-id }
      {
        asset-id: asset-id,
        alert-type: alert-type,
        description: description,
        severity: severity,
        timestamp: timestamp,
        resolved: false,
        resolution-timestamp: none,
        resolution-notes: none
      }
    )

    ;; Update asset alerts count
    (map-set asset-alerts
      { asset-id: asset-id }
      {
        alert-count: (+ (get alert-count current-asset-alerts) u1),
        open-alerts: (+ (get open-alerts current-asset-alerts) u1)
      }
    )

    ;; Update the alert ID counter
    (var-set last-alert-id new-alert-id)

    (ok new-alert-id)
  )
)

;; Resolve an alert
(define-public (resolve-alert
    (alert-id uint)
    (resolution-notes (string-utf8 200))
  )
  (let ((timestamp (unwrap-panic (get-block-info? time u0))))
    (match (map-get? maintenance-alerts { alert-id: alert-id })
      alert (begin
        ;; Check if already resolved
        (asserts! (not (get resolved alert)) (err ERR-ALREADY-RESOLVED))

        ;; Update the alert
        (map-set maintenance-alerts
          { alert-id: alert-id }
          (merge alert {
            resolved: true,
            resolution-timestamp: (some timestamp),
            resolution-notes: (some resolution-notes)
          })
        )

        ;; Update open alerts count
        (match (map-get? asset-alerts { asset-id: (get asset-id alert) })
          asset-alert-data (map-set asset-alerts
            { asset-id: (get asset-id alert) }
            (merge asset-alert-data { open-alerts: (- (get open-alerts asset-alert-data) u1) })
          )
          false
        )

        (ok true)
      )
      (err ERR-ALERT-NOT-FOUND)
    )
  )
)

;; Get alert details
(define-read-only (get-alert (alert-id uint))
  (match (map-get? maintenance-alerts { alert-id: alert-id })
    alert (ok alert)
    (err ERR-ALERT-NOT-FOUND)
  )
)

;; Get open alerts count for an asset
(define-read-only (get-open-alerts-count (asset-id uint))
  (match (map-get? asset-alerts { asset-id: asset-id })
    asset-alert-data (ok (get open-alerts asset-alert-data))
    (err u0)
  )
)
