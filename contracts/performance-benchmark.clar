;; Performance Benchmark Contract
;; Establishes expected parameters for industrial equipment

;; Data structures
(define-map performance-benchmarks
  { asset-id: uint }
  {
    min-temperature: int,
    max-temperature: int,
    min-pressure: int,
    max-pressure: int,
    max-vibration: int,
    expected-power-consumption: uint,
    expected-uptime-percent: uint,
    last-updated: uint,
    set-by: principal
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-BENCHMARK-NOT-FOUND u2)
(define-constant ERR-INVALID-PARAMETERS u3)

;; Set performance benchmarks for an asset
(define-public (set-benchmarks
    (asset-id uint)
    (min-temperature int)
    (max-temperature int)
    (min-pressure int)
    (max-pressure int)
    (max-vibration int)
    (expected-power-consumption uint)
    (expected-uptime-percent uint)
  )
  (let ((timestamp (unwrap-panic (get-block-info? time u0))))
    ;; Validate parameters
    (asserts! (< min-temperature max-temperature) (err ERR-INVALID-PARAMETERS))
    (asserts! (< min-pressure max-pressure) (err ERR-INVALID-PARAMETERS))
    (asserts! (<= expected-uptime-percent u100) (err ERR-INVALID-PARAMETERS))

    ;; Store the benchmarks
    (map-set performance-benchmarks
      { asset-id: asset-id }
      {
        min-temperature: min-temperature,
        max-temperature: max-temperature,
        min-pressure: min-pressure,
        max-pressure: max-pressure,
        max-vibration: max-vibration,
        expected-power-consumption: expected-power-consumption,
        expected-uptime-percent: expected-uptime-percent,
        last-updated: timestamp,
        set-by: tx-sender
      }
    )

    (ok true)
  )
)

;; Get benchmarks for an asset
(define-read-only (get-benchmarks (asset-id uint))
  (match (map-get? performance-benchmarks { asset-id: asset-id })
    benchmarks (ok benchmarks)
    (err ERR-BENCHMARK-NOT-FOUND)
  )
)

;; Check if a sensor reading is within benchmarks
(define-read-only (is-within-benchmarks
    (asset-id uint)
    (temperature int)
    (pressure int)
    (vibration int)
    (power-consumption uint)
  )
  (match (map-get? performance-benchmarks { asset-id: asset-id })
    benchmarks (ok (and
      (>= temperature (get min-temperature benchmarks))
      (<= temperature (get max-temperature benchmarks))
      (>= pressure (get min-pressure benchmarks))
      (<= pressure (get max-pressure benchmarks))
      (<= vibration (get max-vibration benchmarks))
      (<= power-consumption (+ (get expected-power-consumption benchmarks)
                              (/ (* (get expected-power-consumption benchmarks) u10) u100)))
    ))
    (err ERR-BENCHMARK-NOT-FOUND)
  )
)
