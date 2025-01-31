;; Solar Panel Shares Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_SHARES (err u102))
(define-constant ERR_PANEL_NOT_FOUND (err u103))
(define-constant ERR_NO_EARNINGS (err u104))
(define-constant ERR_ALREADY_CLAIMED (err u105))

;; Data Variables 
(define-data-var total-panels uint u0)
(define-data-var watts-per-panel uint u300) ;; Assuming 300W panels
(define-data-var earnings-per-kwh uint u100000) ;; $0.10 per kWh in micro-STX

;; Data Maps
(define-map panels
    uint ;; panel-id
    {
        total-shares: uint,
        available-shares: uint,
        price-per-share: uint,
        energy-generated: uint,
        last-payout: uint,
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

(define-map earnings-claimed
    {panel-id: uint, investor: principal, block-height: uint}
    bool
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
                    last-payout: block-height,
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

;; Record energy generation and calculate earnings
(define-public (record-energy (panel-id uint) (watts uint))
    (let
        (
            (panel (unwrap! (map-get? panels panel-id) ERR_PANEL_NOT_FOUND))
            (kwh (/ watts u1000))
            (earnings (* kwh (var-get earnings-per-kwh)))
        )
        (if (is-eq tx-sender CONTRACT_OWNER)
            (begin
                (map-set panels panel-id
                    (merge panel {
                        energy-generated: (+ (get energy-generated panel) watts),
                        last-payout: block-height
                    })
                )
                (ok true)
            )
            ERR_NOT_AUTHORIZED
        )
    )
)

;; Claim earnings for a specific panel
(define-public (claim-earnings (panel-id uint))
    (let
        (
            (panel (unwrap! (map-get? panels panel-id) ERR_PANEL_NOT_FOUND))
            (shares-owned (get-shares panel-id tx-sender))
            (total-shares (get total-shares panel))
            (last-payout (get last-payout panel))
            (energy-generated (get energy-generated panel))
            (kwh (/ energy-generated u1000))
            (total-earnings (* kwh (var-get earnings-per-kwh)))
            (investor-share (/ (* total-earnings shares-owned) total-shares))
        )
        (if (and
                (> shares-owned u0)
                (not (default-to false (map-get? earnings-claimed {
                    panel-id: panel-id,
                    investor: tx-sender,
                    block-height: last-payout
                })))
            )
            (begin
                (try! (stx-transfer? investor-share CONTRACT_OWNER tx-sender))
                (map-set earnings-claimed
                    {panel-id: panel-id, investor: tx-sender, block-height: last-payout}
                    true
                )
                (map-set investor-earnings
                    tx-sender
                    (+ (default-to u0 (map-get? investor-earnings tx-sender)) investor-share)
                )
                (ok investor-share)
            )
            ERR_NO_EARNINGS
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

;; Get investor's total earnings
(define-read-only (get-investor-earnings (investor principal))
    (default-to u0 (map-get? investor-earnings investor))
)

;; Update earnings rate per kWh
(define-public (set-earnings-rate (new-rate uint))
    (if (is-eq tx-sender CONTRACT_OWNER)
        (begin
            (var-set earnings-per-kwh new-rate)
            (ok true)
        )
        ERR_NOT_AUTHORIZED
    )
)
