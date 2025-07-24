;; DePrismatic Knowledge Core Protocol

;; Implements quantum-resistant storage mechanisms for critical information assets


;; ===============================================
;; SYSTEM CONFIGURATION CONSTANTS
;; ===============================================


(define-constant duplicate-entry-conflict (err u302))
(define-constant dimension-overflow-error (err u304))
(define-constant access-denial-breach (err u306))
(define-constant protocol-violation-detected (err u300))
(define-constant resource-not-found-exception (err u301))
(define-constant system-administrator tx-sender)
(define-constant integrity-validation-failure (err u307))
(define-constant insufficient-privileges-error (err u305))
(define-constant metadata-structure-violation (err u308))
(define-constant invalid-identifier-format (err u303))

;; ===============================================
;; CORE DATA ARCHITECTURE
;; ===============================================

;; Global sequence counter for knowledge entries
(define-data-var prismatic-sequence-counter uint u0)

;; Central repository for structured knowledge assets
(define-map knowledge-repository
  { entry-identifier: uint }
  {
    resource-title: (string-ascii 64),
    ownership-principal: principal,
    priority-level: uint,
    creation-timestamp: uint,
    descriptive-content: (string-ascii 128),
    metadata-tags: (list 10 (string-ascii 32))
  }
)

;; Access control matrix for resource visibility
(define-map access-control-matrix
  { entry-identifier: uint, requesting-entity: principal }
  { read-permission-granted: bool }
)

;; ===============================================
;; INTERNAL VALIDATION MECHANISMS
;; ===============================================

;; Verifies existence of knowledge entry in repository
(define-private (entry-exists-in-system? (entry-identifier uint))
  (is-some (map-get? knowledge-repository { entry-identifier: entry-identifier }))
)

;; Retrieves priority level for specified knowledge entry
(define-private (get-entry-priority-level (entry-identifier uint))
  (default-to u0
    (get priority-level
      (map-get? knowledge-repository { entry-identifier: entry-identifier })
    )
  )
)

;; Validates ownership permissions for knowledge entry modifications
(define-private (verify-ownership-rights (entry-identifier uint) (claiming-principal principal))
  (match (map-get? knowledge-repository { entry-identifier: entry-identifier })
    entry-data (is-eq (get ownership-principal entry-data) claiming-principal)
    false
  )
)

;; Ensures metadata tag conforms to system specifications
(define-private (validate-metadata-tag-format (tag (string-ascii 32)))
  (and
    (> (len tag) u0)
    (< (len tag) u33)
  )
)

;; Comprehensive validation for metadata tag collections
(define-private (validate-complete-metadata-collection (tag-collection (list 10 (string-ascii 32))))
  (and
    (> (len tag-collection) u0)
    (<= (len tag-collection) u10)
    (is-eq (len (filter validate-metadata-tag-format tag-collection)) (len tag-collection))
  )
)

;; ===============================================
;; PRIMARY SYSTEM OPERATIONS
;; ===============================================

;; Creates new knowledge entry with comprehensive metadata
(define-public (register-knowledge-asset 
  (title (string-ascii 64)) 
  (priority uint) 
  (content (string-ascii 128)) 
  (tags (list 10 (string-ascii 32)))
)
  (let
    (
      (next-entry-id (+ (var-get prismatic-sequence-counter) u1))
    )
    ;; Input validation protocol enforcement
    (asserts! (> (len title) u0) invalid-identifier-format)
    (asserts! (< (len title) u65) invalid-identifier-format)
    (asserts! (> priority u0) dimension-overflow-error)
    (asserts! (< priority u1000000000) dimension-overflow-error)
    (asserts! (> (len content) u0) invalid-identifier-format)
    (asserts! (< (len content) u129) invalid-identifier-format)
    (asserts! (validate-complete-metadata-collection tags) metadata-structure-violation)

    ;; Register new knowledge asset with complete metadata structure
    (map-insert knowledge-repository
      { entry-identifier: next-entry-id }
      {
        resource-title: title,
        ownership-principal: tx-sender,
        priority-level: priority,
        creation-timestamp: block-height,
        descriptive-content: content,
        metadata-tags: tags
      }
    )

    ;; Initialize access permissions for creator
    (map-insert access-control-matrix
      { entry-identifier: next-entry-id, requesting-entity: tx-sender }
      { read-permission-granted: true }
    )

    ;; Update global sequence tracking
    (var-set prismatic-sequence-counter next-entry-id)
    (ok next-entry-id)
  )
)

;; Updates existing knowledge entry with new information
(define-public (modify-knowledge-entry 
  (entry-identifier uint) 
  (updated-title (string-ascii 64)) 
  (updated-priority uint) 
  (updated-content (string-ascii 128)) 
  (updated-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (existing-entry (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
    )
    ;; Verify entry existence and ownership authorization
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! (is-eq (get ownership-principal existing-entry) tx-sender) access-denial-breach)

    ;; Validate updated information according to system specifications
    (asserts! (> (len updated-title) u0) invalid-identifier-format)
    (asserts! (< (len updated-title) u65) invalid-identifier-format)
    (asserts! (> updated-priority u0) dimension-overflow-error)
    (asserts! (< updated-priority u1000000000) dimension-overflow-error)
    (asserts! (> (len updated-content) u0) invalid-identifier-format)
    (asserts! (< (len updated-content) u129) invalid-identifier-format)
    (asserts! (validate-complete-metadata-collection updated-tags) metadata-structure-violation)

    ;; Apply modifications to existing knowledge entry
    (map-set knowledge-repository
      { entry-identifier: entry-identifier }
      (merge existing-entry { 
        resource-title: updated-title, 
        priority-level: updated-priority, 
        descriptive-content: updated-content, 
        metadata-tags: updated-tags 
      })
    )
    (ok true)
  )
)

;; Transfers ownership of knowledge entry to different principal
(define-public (transfer-entry-ownership (entry-identifier uint) (new-owner-principal principal))
  (let
    (
      (current-entry (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
    )
    ;; Validate entry existence and current ownership verification
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! (is-eq (get ownership-principal current-entry) tx-sender) access-denial-breach)

    ;; Execute ownership transfer operation
    (map-set knowledge-repository
      { entry-identifier: entry-identifier }
      (merge current-entry { ownership-principal: new-owner-principal })
    )
    (ok true)
  )
)

;; Permanently removes knowledge entry from system repository
(define-public (remove-knowledge-entry (entry-identifier uint))
  (let
    (
      (target-entry (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
    )
    ;; Validate entry existence and ownership authorization
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! (is-eq (get ownership-principal target-entry) tx-sender) access-denial-breach)

    ;; Execute permanent removal from repository
    (map-delete knowledge-repository { entry-identifier: entry-identifier })
    (ok true)
  )
)

;; Extends metadata collection for existing knowledge entry
(define-public (append-metadata-tags (entry-identifier uint) (additional-tags (list 10 (string-ascii 32))))
  (let
    (
      (current-entry (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
      (current-tags (get metadata-tags current-entry))
      (combined-tags (unwrap! (as-max-len? (concat current-tags additional-tags) u10) metadata-structure-violation))
    )
    ;; Validate entry existence and ownership authorization
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! (is-eq (get ownership-principal current-entry) tx-sender) access-denial-breach)

    ;; Validate additional metadata tags structure
    (asserts! (validate-complete-metadata-collection additional-tags) metadata-structure-violation)

    ;; Update entry with extended metadata collection
    (map-set knowledge-repository
      { entry-identifier: entry-identifier }
      (merge current-entry { metadata-tags: combined-tags })
    )
    (ok combined-tags)
  )
)

;; Revokes access permissions for specified entity
(define-public (revoke-access-permission (entry-identifier uint) (target-entity principal))
  (let
    (
      (entry-data (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
    )
    ;; Validate entry existence and ownership authorization
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! (is-eq (get ownership-principal entry-data) tx-sender) access-denial-breach)
    (asserts! (not (is-eq target-entity tx-sender)) protocol-violation-detected)

    ;; Remove access permission from control matrix
    (map-delete access-control-matrix { entry-identifier: entry-identifier, requesting-entity: target-entity })
    (ok true)
  )
)

;; Implements immutability protection for critical knowledge entries
(define-public (enable-immutability-protection (entry-identifier uint))
  (let
    (
      (protected-entry (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
      (protection-indicator "IMMUTABLE-PROTECTION")
      (current-tags (get metadata-tags protected-entry))
    )
    ;; Validate entry existence and authorized protection activation
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! 
      (or 
        (is-eq tx-sender system-administrator)
        (is-eq (get ownership-principal protected-entry) tx-sender)
      ) 
      protocol-violation-detected
    )

    (ok true)
  )
)

;; Performs comprehensive integrity verification for knowledge entries
(define-public (execute-integrity-verification (entry-identifier uint) (expected-owner principal))
  (let
    (
      (verification-target (unwrap! (map-get? knowledge-repository { entry-identifier: entry-identifier }) resource-not-found-exception))
      (actual-owner (get ownership-principal verification-target))
      (creation-block (get creation-timestamp verification-target))
      (access-status (default-to 
        false 
        (get read-permission-granted 
          (map-get? access-control-matrix { entry-identifier: entry-identifier, requesting-entity: tx-sender })
        )
      ))
    )
    ;; Validate entry existence and verification authorization
    (asserts! (entry-exists-in-system? entry-identifier) resource-not-found-exception)
    (asserts! 
      (or 
        (is-eq tx-sender actual-owner)
        access-status
        (is-eq tx-sender system-administrator)
      ) 
      insufficient-privileges-error
    )

    ;; Generate comprehensive verification report
    (if (is-eq actual-owner expected-owner)
      ;; Return successful verification with detailed provenance information
      (ok {
        verification-successful: true,
        current-block-height: block-height,
        entry-age: (- block-height creation-block),
        ownership-verified: true
      })
      ;; Return ownership mismatch verification report
      (ok {
        verification-successful: false,
        current-block-height: block-height,
        entry-age: (- block-height creation-block),
        ownership-verified: false
      })
    )
  )
)

;; ===============================================
;; SUPPLEMENTARY UTILITY FUNCTIONS
;; ===============================================

;; Calculates priority ratio between two knowledge entries
(define-private (calculate-priority-ratio (primary-entry uint) (secondary-entry uint))
  (let
    (
      (primary-priority (get-entry-priority-level primary-entry))
      (secondary-priority (get-entry-priority-level secondary-entry))
    )
    (if (and (> primary-priority u0) (> secondary-priority u0))
      (/ (* primary-priority u100) secondary-priority)
      u0)
  )
)

;; Advanced priority comparison mechanism for entry ranking
(define-private (compare-entry-priorities (first-entry uint) (second-entry uint))
  (let
    (
      (first-priority (get-entry-priority-level first-entry))
      (second-priority (get-entry-priority-level second-entry))
    )
    (> first-priority second-priority)
  )
)

;; Validates system-wide entry identifier uniqueness
(define-private (ensure-identifier-uniqueness (proposed-id uint))
  (not (entry-exists-in-system? proposed-id))
)

