;; Sensor Data Contract
;; Tracks operational metrics and conditions for industrial equipment

;; Data structures
(define-map sensor-readings
  { asset-id: uint, timestamp: uint }
  {
    temperature: int,
    pressure: int,
    vibration: int,
    power-consumption: uint,
    operational-status: (string-utf8 20),
    recorded-by: principal
  }
)

;; Track the latest reading timestamp for each asset
(define-map latest-reading
  { asset-id: uint }
  { timestamp: uint }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-INVALID-DATA u2)
(define-constant ERR-NO-READINGS u3)

;; Record a new sensor reading
(define-public (record-sensor-data
    (asset-id uint)
    (temperature int)
    (pressure int)
    (vibration int)
    (power-consumption uint)
    (operational-status (string-utf8 20))
  )
  (let ((timestamp (unwrap-panic (get-block-info? time u0))))
    ;; Store the sensor reading
    (map-set sensor-readings
      { asset-id: asset-id, timestamp: timestamp }
      {
        temperature: temperature,
        pressure: pressure,
        vibration: vibration,
        power-consumption: power-consumption,
        operational-status: operational-status,
        recorded-by: tx-sender
      }
    )

    ;; Update the latest reading timestamp
    (map-set latest-reading
      { asset-id: asset-id }
      { timestamp: timestamp }
    )

    (ok timestamp)
  )
)

;; Get the latest sensor reading for an asset
(define-read-only (get-latest-reading (asset-id uint))
  (match (map-get? latest-reading { asset-id: asset-id })
    latest-info (match (map-get? sensor-readings { asset-id: asset-id, timestamp: (get timestamp latest-info) })
      reading (ok reading)
      (err ERR-NO-READINGS)
    )
    (err ERR-NO-READINGS)
  )
)

;; Get a specific sensor reading
(define-read-only (get-reading-at-time (asset-id uint) (timestamp uint))
  (match (map-get? sensor-readings { asset-id: asset-id, timestamp: timestamp })
    reading (ok reading)
    (err ERR-NO-READINGS)
  )
)

;; Check if temperature is within safe range
(define-read-only (is-temperature-safe (asset-id uint))
  (match (get-latest-reading asset-id)
    success (ok (and (> (get temperature success) (- 0 50)) (< (get temperature success) 100)))
    error (err ERR-NO-READINGS)
  )
)

;; Check if pressure is within safe range
(define-read-only (is-pressure-safe (asset-id uint))
  (match (get-latest-reading asset-id)
    success (ok (and (> (get pressure success) 0) (< (get pressure success) 1000)))
    error (err ERR-NO-READINGS)
  )
)
