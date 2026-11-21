; ---------- direction codes stored in TrackMap ----------
DIR_R       equ 1           ; move right  (col+1)
DIR_U       equ 2           ; move up     (row-1)
DIR_D       equ 3           ; move down   (row+1)
SW_CODE     equ 10h         ; switch n is stored as 10h+n (n = 0..3)
                            ; stations are stored as their letter 'A'..'D'
; ---------- colours (text-mode attribute bytes) ----------
ATTR_RAIL    equ 07h        ; grey rails
ATTR_SWITCH  equ 1Eh        ; yellow digit on blue box
ATTR_STATION equ 2Fh        ; white letter on green
ATTR_TEXT    equ 0Fh        ; bright white text
ATTR_ON      equ 0Eh        ; selected route  (yellow)
ATTR_OFF     equ 08h        ; unselected route (dark grey)
; ---------- trains ----------
MAXTRAINS   equ 6           ; brief needs at least 5
TR_SIZE     equ 6           ; bytes per train record
TR_ROW      equ 0
TR_COL      equ 1
TR_DEST     equ 2           ; station letter 'A'..'D'
TR_INTERVAL equ 3           ; ticks between moves
TR_COUNT    equ 4           ; ticks left until next move
TR_ACTIVE   equ 5           ; 1 = on screen, 0 = free slot
TrainTable  times MAXTRAINS*TR_SIZE db 0
; ---------- game state ----------
Switches    db 0,0,0,0      ; route of switch 1..4 (0 or 1)
Ticks       dw 0            ; raised by TimerISR
Seconds     dw 0            ; elapsed time for HUD
Score       db 0
Mistakes    db 0
Mode        db 0            ; 0 = single-player, 1 = co-op
SpedUp      db 0            ; 1 once SpeedUp has run
BaseInterval db 6           ; interval for newly spawned trains
; ---------- the map: one byte per screen cell ----------
TrackMap    times 25*80 db 0
Claims      times 25*80 db 0    ; cells claimed during this update
; ---------- layout tables ----------
; rails: row, col, direction, length  (vertical lines listed top-down)
LineTable:
    db  4,  2, DIR_R, 10    ; Entry 1 -> switch 1
    db  4, 13, DIR_R, 48    ; switch 1 -> A
    db  5, 12, DIR_D,  7    ; switch 1 down to shared track
    db 20,  2, DIR_R, 10    ; Entry 2 -> switch 2
    db 20, 13, DIR_R, 18    ; switch 2 -> D (left)
    db 13, 12, DIR_U,  7    ; switch 2 up to shared track
    db 12, 12, DIR_R, 23    ; shared track -> switch 3
    db  9, 35, DIR_U,  3    ; switch 3 up toward B
    db  8, 35, DIR_R, 26    ; ... then right to B
    db 12, 36, DIR_R, 12    ; switch 3 -> switch 4
    db 12, 49, DIR_R, 12    ; switch 4 -> C
    db 13, 48, DIR_D,  3    ; switch 4 down toward D
    db 16, 48, DIR_R, 13    ; ... then right to D
LINECOUNT   equ 13
; switches: row, col, route-0 direction, route-1 direction
SwitchInfo:
    db  4, 12, DIR_R, DIR_D     ; 1: A  / shared
    db 20, 12, DIR_R, DIR_U     ; 2: D  / shared
    db 12, 35, DIR_U, DIR_R     ; 3: B  / switch 4
    db 12, 48, DIR_R, DIR_D     ; 4: C  / D
; stations: row, col, letter
StationInfo:
    db  4, 61, 'A'
    db  8, 61, 'B'
    db 12, 61, 'C'
    db 16, 61, 'D'
    db 20, 31, 'D'
STATIONCOUNT equ 5
; entrances: row, col   (SpawnTrain uses these)
Entrances   db 4, 2,  20, 2
StrTitle    db 'S W I T C H Y A R D', 0
StrEntry1   db 'ENTRY 1', 0
StrEntry2   db 'ENTRY 2', 0