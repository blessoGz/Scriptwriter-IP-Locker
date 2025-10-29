(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SCRIPT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-LICENSED (err u102))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u103))
(define-constant ERR-INVALID-SCRIPT-HASH (err u104))
(define-constant ERR-SCRIPT-ALREADY-EXISTS (err u105))
(define-constant ERR-INVALID-LICENSE-FEE (err u106))
(define-constant ERR-TRANSFER-FAILED (err u107))
(define-constant ERR-INVALID-TRANSFER-PRICE (err u108))
(define-constant ERR-SELF-TRANSFER (err u109))

(define-constant MIN-LICENSE-FEE u1000000)
(define-constant MIN-TRANSFER-PRICE u1000000)
(define-constant MAX-TITLE-LENGTH u100)
(define-constant MAX-DESCRIPTION-LENGTH u500)

(define-data-var contract-owner principal tx-sender)
(define-data-var platform-fee-percentage uint u5)

(define-map scripts
  { script-id: uint }
  {
    scriptwriter: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    script-hash: (buff 32),
    timestamp: uint,
    block-height: uint,
    license-fee: uint,
    total-earnings: uint,
    is-active: bool
  }
)

(define-map script-licenses
  { script-id: uint, producer: principal }
  {
    license-granted: bool,
    payment-amount: uint,
    license-timestamp: uint,
    license-block-height: uint
  }
)

(define-map scriptwriter-stats
  { scriptwriter: principal }
  {
    total-scripts: uint,
    total-earnings: uint,
    scripts-licensed: uint
  }
)

(define-map producer-stats
  { producer: principal }
  {
    total-licenses: uint,
    total-spent: uint
  }
)

(define-data-var next-script-id uint u1)

(define-public (register-script 
    (title (string-ascii 100)) 
    (description (string-ascii 500))
    (script-hash (buff 32))
    (license-fee uint))
  (let 
    (
      (script-id (var-get next-script-id))
    )
    (asserts! (> (len title) u0) ERR-INVALID-SCRIPT-HASH)
    (asserts! (<= (len title) MAX-TITLE-LENGTH) ERR-INVALID-SCRIPT-HASH)
    (asserts! (<= (len description) MAX-DESCRIPTION-LENGTH) ERR-INVALID-SCRIPT-HASH)
    (asserts! (>= license-fee MIN-LICENSE-FEE) ERR-INVALID-LICENSE-FEE)
    (asserts! (> (len script-hash) u0) ERR-INVALID-SCRIPT-HASH)
    
    (map-set scripts
      { script-id: script-id }
      {
        scriptwriter: tx-sender,
        title: title,
        description: description,
        script-hash: script-hash,
        timestamp: stacks-block-height,
        block-height: stacks-block-height,
        license-fee: license-fee,
        total-earnings: u0,
        is-active: true
      }
    )
    
    (map-set scriptwriter-stats
      { scriptwriter: tx-sender }
      {
        total-scripts: (+ (get-scriptwriter-script-count tx-sender) u1),
        total-earnings: (get-scriptwriter-total-earnings tx-sender),
        scripts-licensed: (get-scriptwriter-licensed-count tx-sender)
      }
    )
    
    (var-set next-script-id (+ script-id u1))
    (ok script-id)
  )
)

(define-public (purchase-license (script-id uint))
  (let 
    (
      (script-data (unwrap! (map-get? scripts { script-id: script-id }) ERR-SCRIPT-NOT-FOUND))
      (license-fee (get license-fee script-data))
      (scriptwriter (get scriptwriter script-data))
      (platform-fee (/ (* license-fee (var-get platform-fee-percentage)) u100))
      (scriptwriter-payment (- license-fee platform-fee))
    )
    (asserts! (get is-active script-data) ERR-SCRIPT-NOT-FOUND)
    (asserts! (is-none (map-get? script-licenses { script-id: script-id, producer: tx-sender })) ERR-ALREADY-LICENSED)
    
    (try! (stx-transfer? license-fee tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? scriptwriter-payment tx-sender scriptwriter)))
    (try! (as-contract (stx-transfer? platform-fee tx-sender (var-get contract-owner))))
    
    (map-set script-licenses
      { script-id: script-id, producer: tx-sender }
      {
        license-granted: true,
        payment-amount: license-fee,
        license-timestamp: stacks-block-height,
        license-block-height: stacks-block-height
      }
    )
    
    (map-set scripts
      { script-id: script-id }
      (merge script-data { total-earnings: (+ (get total-earnings script-data) scriptwriter-payment) })
    )
    
    (map-set scriptwriter-stats
      { scriptwriter: scriptwriter }
      {
        total-scripts: (get-scriptwriter-script-count scriptwriter),
        total-earnings: (+ (get-scriptwriter-total-earnings scriptwriter) scriptwriter-payment),
        scripts-licensed: (+ (get-scriptwriter-licensed-count scriptwriter) u1)
      }
    )
    
    (map-set producer-stats
      { producer: tx-sender }
      {
        total-licenses: (+ (get-producer-license-count tx-sender) u1),
        total-spent: (+ (get-producer-total-spent tx-sender) license-fee)
      }
    )
    
    (ok true)
  )
)

(define-public (update-license-fee (script-id uint) (new-fee uint))
  (let 
    (
      (script-data (unwrap! (map-get? scripts { script-id: script-id }) ERR-SCRIPT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get scriptwriter script-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active script-data) ERR-SCRIPT-NOT-FOUND)
    (asserts! (>= new-fee MIN-LICENSE-FEE) ERR-INVALID-LICENSE-FEE)
    
    (map-set scripts
      { script-id: script-id }
      (merge script-data { license-fee: new-fee })
    )
    (ok true)
  )
)

(define-public (deactivate-script (script-id uint))
  (let 
    (
      (script-data (unwrap! (map-get? scripts { script-id: script-id }) ERR-SCRIPT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get scriptwriter script-data)) ERR-NOT-AUTHORIZED)
    
    (map-set scripts
      { script-id: script-id }
      (merge script-data { is-active: false })
    )
    (ok true)
  )
)

(define-public (reactivate-script (script-id uint))
  (let 
    (
      (script-data (unwrap! (map-get? scripts { script-id: script-id }) ERR-SCRIPT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get scriptwriter script-data)) ERR-NOT-AUTHORIZED)
    
    (map-set scripts
      { script-id: script-id }
      (merge script-data { is-active: true })
    )
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-percentage u20) ERR-INVALID-LICENSE-FEE)
    (var-set platform-fee-percentage new-fee-percentage)
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

(define-public (transfer-script (script-id uint) (new-owner principal) (transfer-price uint))
  (let 
    (
      (script-data (unwrap! (map-get? scripts { script-id: script-id }) ERR-SCRIPT-NOT-FOUND))
      (current-owner (get scriptwriter script-data))
      (platform-fee (/ (* transfer-price (var-get platform-fee-percentage)) u100))
      (owner-payment (- transfer-price platform-fee))
    )
    (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq new-owner current-owner)) ERR-SELF-TRANSFER)
    (asserts! (>= transfer-price MIN-TRANSFER-PRICE) ERR-INVALID-TRANSFER-PRICE)
    (asserts! (get is-active script-data) ERR-SCRIPT-NOT-FOUND)
    
    (try! (stx-transfer? transfer-price new-owner current-owner))
    (try! (stx-transfer? platform-fee new-owner (var-get contract-owner)))
    
    (map-set scripts
      { script-id: script-id }
      (merge script-data { scriptwriter: new-owner })
    )
    
    (map-set scriptwriter-stats
      { scriptwriter: current-owner }
      {
        total-scripts: (- (get-scriptwriter-script-count current-owner) u1),
        total-earnings: (+ (get-scriptwriter-total-earnings current-owner) owner-payment),
        scripts-licensed: (get-scriptwriter-licensed-count current-owner)
      }
    )
    
    (map-set scriptwriter-stats
      { scriptwriter: new-owner }
      {
        total-scripts: (+ (get-scriptwriter-script-count new-owner) u1),
        total-earnings: (get-scriptwriter-total-earnings new-owner),
        scripts-licensed: (get-scriptwriter-licensed-count new-owner)
      }
    )
    
    (ok true)
  )
)

(define-read-only (get-script-info (script-id uint))
  (map-get? scripts { script-id: script-id })
)

(define-read-only (get-license-info (script-id uint) (producer principal))
  (map-get? script-licenses { script-id: script-id, producer: producer })
)

(define-read-only (has-license? (script-id uint) (producer principal))
  (is-some (map-get? script-licenses { script-id: script-id, producer: producer }))
)

(define-read-only (get-scriptwriter-stats (scriptwriter principal))
  (map-get? scriptwriter-stats { scriptwriter: scriptwriter })
)

(define-read-only (get-producer-stats (producer principal))
  (map-get? producer-stats { producer: producer })
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (get-platform-fee-percentage)
  (var-get platform-fee-percentage)
)

(define-read-only (get-next-script-id)
  (var-get next-script-id)
)

(define-read-only (get-min-license-fee)
  MIN-LICENSE-FEE
)

(define-private (get-scriptwriter-script-count (scriptwriter principal))
  (default-to u0 (get total-scripts (map-get? scriptwriter-stats { scriptwriter: scriptwriter })))
)

(define-private (get-scriptwriter-total-earnings (scriptwriter principal))
  (default-to u0 (get total-earnings (map-get? scriptwriter-stats { scriptwriter: scriptwriter })))
)

(define-private (get-scriptwriter-licensed-count (scriptwriter principal))
  (default-to u0 (get scripts-licensed (map-get? scriptwriter-stats { scriptwriter: scriptwriter })))
)

(define-private (get-producer-license-count (producer principal))
  (default-to u0 (get total-licenses (map-get? producer-stats { producer: producer })))
)

(define-private (get-producer-total-spent (producer principal))
  (default-to u0 (get total-spent (map-get? producer-stats { producer: producer })))
)
