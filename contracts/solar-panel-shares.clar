;; Solar Panel Shares Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_SHARES (err u102))
(define-constant ERR_PANEL_NOT_FOUND (err u103))

;; Data Variables
(define-data-var total-panels uint u0)
(define-data-var watts-per-panel uint u300) ;; Assuming 300W panels

;; Data Maps
(define-map panels
    uint ;; panel-id
    {
        total-shares: uint,
        available-shares: uint,
        price-per-share: uint,
        energy-generated: uint,
        active: bool
    }
)

(define-map investor-shares
    {panel-id: uint, investor: principal}
    uint ;; number of shares owned
)

(define-map investor-earnings
    principal
    uint
)

;; Add new solar panel
(define-public (add-panel (price-per-share uint) (total-shares uint))
    (let 
        (
            (panel-id (var-get total-panels))
        )
        (if (is-eq tx-sender CONTRACT_OWNER)
            (begin
                (map-set panels panel-id {
                    total-shares: total-shares,
                    available-shares: total-shares,
                    price-per-share: price-per-share,
                    energy-generated: u0,
                    active: true
                })
                (var-set total-panels (+ panel-id u1))
                (ok panel-id)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Purchase shares
(define-public (buy-shares (panel-id uint) (shares uint))
    (let
        (
            (panel (unwrap! (map-get? panels panel-id) ERR_PANEL_NOT_FOUND))
            (available-shares (get available-shares panel))
            (price-per-share (get price-per-share panel))
            (total-cost (* shares price-per-share))
        )
        (if (and
                (<= shares available-shares)
                (is-eq (stx-transfer? total-cost tx-sender CONTRACT_OWNER) (ok true))
            )
            (begin
                (map-set panels panel-id
                    (merge panel {available-shares: (- available-shares shares)})
                )
                (map-set investor-shares 
                    {panel-id: panel-id, investor: tx-sender}
                    (default-to u0 (+ shares (get-shares panel-id tx-sender)))
                )
                (ok true)
            )
            ERR_INVALID_AMOUNT
        )
    )
)

;; Record energy generation
(define-public (record-energy (panel-id uint) (watts uint))
    (let
        (
            (panel (unwrap! (map-get? panels panel-id) ERR_PANEL_NOT_FOUND))
        )
        (if (is-eq tx-sender CONTRACT_OWNER)
            (begin
                (map-set panels panel-id
                    (merge panel {energy-generated: (+ (get energy-generated panel) watts)})
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Get shares owned by investor for a panel
(define-read-only (get-shares (panel-id uint) (investor principal))
    (default-to u0 
        (map-get? investor-shares {panel-id: panel-id, investor: investor})
    )
)

;; Get panel details
(define-read-only (get-panel-info (panel-id uint))
    (map-get? panels panel-id)
)

;; Get total number of panels
(define-read-only (get-total-panels)
    (var-get total-panels)
)
