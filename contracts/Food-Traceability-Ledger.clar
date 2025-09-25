(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PARTICIPANT (err u102))
(define-constant ERR_PRODUCT_EXISTS (err u103))
(define-constant ERR_INVALID_TRANSFER (err u104))
(define-constant ERR_ALREADY_REGISTERED (err u105))
(define-constant ERR_INVALID_STATUS (err u106))
(define-constant ERR_RECALL_EXISTS (err u107))
(define-constant ERR_RECALL_NOT_FOUND (err u108))
(define-constant ERR_INVALID_SEVERITY (err u109))

(define-data-var next-product-id uint u1)
(define-data-var next-participant-id uint u1)
(define-data-var next-transfer-id uint u1)
(define-data-var next-recall-id uint u1)

(define-map participants
  { participant-id: uint }
  {
    address: principal,
    participant-type: (string-ascii 20),
    name: (string-ascii 100),
    location: (string-ascii 200),
    certified: bool,
    registration-block: uint
  }
)

(define-map participant-by-address
  { address: principal }
  { participant-id: uint }
)

(define-map products
  { product-id: uint }
  {
    name: (string-ascii 100),
    category: (string-ascii 50),
    origin-farm: uint,
    current-owner: uint,
    creation-block: uint,
    status: (string-ascii 20),
    quality-score: uint,
    batch-number: (string-ascii 50)
  }
)

(define-map product-history
  { product-id: uint, transfer-id: uint }
  {
    from-participant: uint,
    to-participant: uint,
    transfer-block: uint,
    transfer-type: (string-ascii 30),
    notes: (string-ascii 500),
    quality-check: bool,
    temperature: (optional int),
    location: (string-ascii 200)
  }
)

(define-map quality-records
  { product-id: uint, record-id: uint }
  {
    inspector: principal,
    inspection-block: uint,
    quality-score: uint,
    notes: (string-ascii 500),
    passed: bool
  }
)

(define-map product-quality-count
  { product-id: uint }
  { count: uint }
)

(define-map recalls
  { recall-id: uint }
  {
    product-id: uint,
    initiator: uint,
    reason: (string-ascii 500),
    severity-level: uint,
    recall-date: uint,
    status: (string-ascii 20),
    affected-participants: (list 50 uint),
    resolved: bool
  }
)

(define-map recall-notifications
  { recall-id: uint, participant-id: uint }
  {
    notified: bool,
    acknowledged: bool,
    acknowledgment-date: (optional uint)
  }
)

(define-public (register-participant (participant-type (string-ascii 20)) (name (string-ascii 100)) (location (string-ascii 200)))
  (let (
    (participant-id (var-get next-participant-id))
    (caller tx-sender)
    (current-block stacks-block-height)
  )
    (asserts! (is-none (map-get? participant-by-address { address: caller })) ERR_ALREADY_REGISTERED)
    (asserts! (or (is-eq participant-type "farm") (is-eq participant-type "distributor") (is-eq participant-type "restaurant")) ERR_INVALID_PARTICIPANT)
    
    (map-set participants
      { participant-id: participant-id }
      {
        address: caller,
        participant-type: participant-type,
        name: name,
        location: location,
        certified: false,
        registration-block: current-block
      }
    )
    
    (map-set participant-by-address
      { address: caller }
      { participant-id: participant-id }
    )
    
    (var-set next-participant-id (+ participant-id u1))
    (ok participant-id)
  )
)

(define-public (certify-participant (participant-id uint))
  (let (
    (participant (unwrap! (map-get? participants { participant-id: participant-id }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set participants
      { participant-id: participant-id }
      (merge participant { certified: true })
    )
    (ok true)
  )
)

(define-public (create-product (name (string-ascii 100)) (category (string-ascii 50)) (batch-number (string-ascii 50)))
  (let (
    (product-id (var-get next-product-id))
    (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
    (participant-id (get participant-id caller-info))
    (participant (unwrap! (map-get? participants { participant-id: participant-id }) ERR_NOT_FOUND))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq (get participant-type participant) "farm") ERR_UNAUTHORIZED)
    
    (map-set products
      { product-id: product-id }
      {
        name: name,
        category: category,
        origin-farm: participant-id,
        current-owner: participant-id,
        creation-block: current-block,
        status: "created",
        quality-score: u100,
        batch-number: batch-number
      }
    )
    
    (map-set product-quality-count
      { product-id: product-id }
      { count: u0 }
    )
    
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

(define-public (transfer-product (product-id uint) (to-participant-id uint) (transfer-type (string-ascii 30)) (notes (string-ascii 500)) (temperature (optional int)) (location (string-ascii 200)))
  (let (
    (product (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
    (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
    (from-participant-id (get participant-id caller-info))
    (to-participant (unwrap! (map-get? participants { participant-id: to-participant-id }) ERR_NOT_FOUND))
    (transfer-id (var-get next-transfer-id))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq (get current-owner product) from-participant-id) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq from-participant-id to-participant-id)) ERR_INVALID_TRANSFER)
    
    (map-set products
      { product-id: product-id }
      (merge product { 
        current-owner: to-participant-id,
        status: "transferred"
      })
    )
    
    (map-set product-history
      { product-id: product-id, transfer-id: transfer-id }
      {
        from-participant: from-participant-id,
        to-participant: to-participant-id,
        transfer-block: current-block,
        transfer-type: transfer-type,
        notes: notes,
        quality-check: false,
        temperature: temperature,
        location: location
      }
    )
    
    (var-set next-transfer-id (+ transfer-id u1))
    (ok transfer-id)
  )
)

(define-public (conduct-quality-check (product-id uint) (quality-score uint) (notes (string-ascii 500)) (passed bool))
  (let (
    (product (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
    (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
    (inspector-id (get participant-id caller-info))
    (inspector (unwrap! (map-get? participants { participant-id: inspector-id }) ERR_NOT_FOUND))
    (quality-count-info (unwrap! (map-get? product-quality-count { product-id: product-id }) ERR_NOT_FOUND))
    (record-id (get count quality-count-info))
    (current-block stacks-block-height)
  )
    (asserts! (<= quality-score u100) ERR_INVALID_STATUS)
    (asserts! (get certified inspector) ERR_UNAUTHORIZED)
    
    (map-set quality-records
      { product-id: product-id, record-id: record-id }
      {
        inspector: tx-sender,
        inspection-block: current-block,
        quality-score: quality-score,
        notes: notes,
        passed: passed
      }
    )
    
    (map-set product-quality-count
      { product-id: product-id }
      { count: (+ record-id u1) }
    )
    
    (map-set products
      { product-id: product-id }
      (merge product { 
        quality-score: quality-score,
        status: (if passed "quality-passed" "quality-failed")
      })
    )
    
    (ok record-id)
  )
)

(define-public (update-product-status (product-id uint) (new-status (string-ascii 20)))
  (let (
    (product (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
    (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
    (participant-id (get participant-id caller-info))
  )
    (asserts! (is-eq (get current-owner product) participant-id) ERR_UNAUTHORIZED)
    (asserts! (or (is-eq new-status "processing") (is-eq new-status "ready") (is-eq new-status "delivered") (is-eq new-status "consumed")) ERR_INVALID_STATUS)
    
    (map-set products
      { product-id: product-id }
      (merge product { status: new-status })
    )
    (ok true)
  )
)

(define-read-only (get-participant (participant-id uint))
  (map-get? participants { participant-id: participant-id })
)

(define-read-only (get-participant-by-address (address principal))
  (match (map-get? participant-by-address { address: address })
    participant-info (map-get? participants { participant-id: (get participant-id participant-info) })
    none
  )
)

(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

(define-read-only (get-product-history (product-id uint) (transfer-id uint))
  (map-get? product-history { product-id: product-id, transfer-id: transfer-id })
)

(define-read-only (get-quality-record (product-id uint) (record-id uint))
  (map-get? quality-records { product-id: product-id, record-id: record-id })
)

(define-read-only (get-product-quality-count (product-id uint))
  (default-to { count: u0 } (map-get? product-quality-count { product-id: product-id }))
)

(define-read-only (get-recall (recall-id uint))
  (map-get? recalls { recall-id: recall-id })
)

(define-read-only (get-recall-notification (recall-id uint) (participant-id uint))
  (map-get? recall-notifications { recall-id: recall-id, participant-id: participant-id })
)

(define-read-only (is-participant-certified (participant-id uint))
  (match (map-get? participants { participant-id: participant-id })
    participant (get certified participant)
    false
  )
)

(define-read-only (get-current-product-owner (product-id uint))
  (match (map-get? products { product-id: product-id })
    product (some (get current-owner product))
    none
  )
)

(define-read-only (can-transfer-product (product-id uint) (from-address principal))
  (match (map-get? participant-by-address { address: from-address })
    participant-info
      (match (map-get? products { product-id: product-id })
        product (is-eq (get current-owner product) (get participant-id participant-info))
        false
      )
    false
  )
)

(define-read-only (get-product-origin (product-id uint))
  (match (map-get? products { product-id: product-id })
    product (map-get? participants { participant-id: (get origin-farm product) })
    none
  )
)

(define-public (initiate-recall
  (product-id uint)
  (reason (string-ascii 500))
  (severity-level uint)
)
  (let
    (
      (product (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
      (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
      (initiator-id (get participant-id caller-info))
      (recall-id (var-get next-recall-id))
      (current-block stacks-block-height)
    )
    (asserts! (<= severity-level u5) ERR_INVALID_SEVERITY)
    (asserts! (> (len reason) u0) ERR_INVALID_STATUS)
    
    (map-set recalls
      { recall-id: recall-id }
      {
        product-id: product-id,
        initiator: initiator-id,
        reason: reason,
        severity-level: severity-level,
        recall-date: current-block,
        status: "active",
        affected-participants: (list),
        resolved: false
      }
    )
    
    (map-set products
      { product-id: product-id }
      (merge product { status: "recalled" })
    )
    
    (var-set next-recall-id (+ recall-id u1))
    (ok recall-id)
  )
)

(define-public (acknowledge-recall (recall-id uint))
  (let
    (
      (recall (unwrap! (map-get? recalls { recall-id: recall-id }) ERR_RECALL_NOT_FOUND))
      (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
      (participant-id (get participant-id caller-info))
      (notification-key { recall-id: recall-id, participant-id: participant-id })
      (existing-notification (default-to { notified: false, acknowledged: false, acknowledgment-date: none } (map-get? recall-notifications notification-key)))
      (current-block stacks-block-height)
    )
    (asserts! (not (get acknowledged existing-notification)) ERR_ALREADY_REGISTERED)
    
    (map-set recall-notifications
      notification-key
      {
        notified: true,
        acknowledged: true,
        acknowledgment-date: (some current-block)
      }
    )
    
    (ok true)
  )
)

(define-public (resolve-recall (recall-id uint))
  (let
    (
      (recall (unwrap! (map-get? recalls { recall-id: recall-id }) ERR_RECALL_NOT_FOUND))
      (caller-info (unwrap! (map-get? participant-by-address { address: tx-sender }) ERR_UNAUTHORIZED))
      (participant-id (get participant-id caller-info))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq (get initiator recall) participant-id)) ERR_UNAUTHORIZED)
    (asserts! (not (get resolved recall)) ERR_INVALID_STATUS)
    
    (map-set recalls
      { recall-id: recall-id }
      (merge recall {
        status: "resolved",
        resolved: true
      })
    )
    
    (ok true)
  )
)

(define-read-only (get-product-recall-status (product-id uint))
  (match (map-get? products { product-id: product-id })
    product (is-eq (get status product) "recalled")
    false
  )
)

(define-read-only (get-active-recalls)
  (ok (filter is-recall-active (enumerate-recalls)))
)

(define-private (enumerate-recalls)
  (map get-recall-id (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20))
)

(define-private (get-recall-id (id uint))
  id
)

(define-private (is-recall-active (recall-id uint))
  (match (map-get? recalls { recall-id: recall-id })
    recall (and (is-eq (get status recall) "active") (not (get resolved recall)))
    false
  )
)

(define-read-only (get-contract-info)
  {
    total-participants: (var-get next-participant-id),
    total-products: (var-get next-product-id),
    total-transfers: (var-get next-transfer-id),
    total-recalls: (var-get next-recall-id),
    contract-owner: CONTRACT_OWNER
  }
)
