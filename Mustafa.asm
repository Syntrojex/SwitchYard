; ============================================================================
; SHARED DATA BLOCK  (layout agreed with Shauzab - keep identical)
; ============================================================================
TrainTable:     times 48 dw 0           ; 8 records x 6 words, see layout above
Switches:       db 0, 0, 0, 0           ; switches 1-4, each 0 or 1
Ticks:          dw 0                    ; timer ticks since the game began
Score:          dw 0                    ; correct deliveries
Mistakes:       dw 0                    ; wrong deliveries
Mode:           db 0                    ; 0 = single player, 1 = co-op
SpedUp:         db 0                    ; 1 once the speed-up has happened
Claims:         times 16 dw 0           ; cells claimed in this update (DH:DL)
ClaimCount:     dw 0                    ; number of valid entries in Claims
CurInterval:    dw 12                   ; interval given to every new train
GameState:      db 0                    ; 0 playing, 1 won, 2 lost
EntryRow:       db 4, 20                ; row of entrance 1, entrance 2
EntryCol:       db 2, 2                 ; column of entrance 1, entrance 2
; ============================================================================
; MUSTAFA'S PRIVATE DATA
; ============================================================================
oldtimer:       dd 0                    ; space for saving old timer ISR
NextEntrance:   db 0                    ; entrance SpawnTrain tries first
RandSeed:       dw 0x1234               ; seed of the random generator

msgwin:         db 'YOU WIN!'           ; 8
msglose:        db 'GAME OVER'          ; 9
msgscore:       db 'Score:'             ; 6
msgmist:        db 'Mistakes:'          ; 9
msgtime:        db 'Time (s):'          ; 9
msgopt:         db 'R = Replay    Esc = Exit'   ; 24

; ============================================================================
; SUPPORT ROUTINES FROM THE BOOK
; ============================================================================

; ---- subroutine to clear the screen (Example 6.2) ----
clrscr:         push es
                push ax
                push di

                mov    ax, 0xb800
                mov    es, ax             ; point es to video base
                mov    di, 0              ; point di to top left column

nextloc:        mov    word [es:di], 0x0720 ; clear next char on screen
                add    di, 2              ; move to next screen location
                cmp    di, 4000           ; has the whole screen cleared
                jne    nextloc            ; if no clear next position

                pop    di
                pop    ax
                pop    es
                ret

; ---- subroutine to print a string (Example 7.2) ----
; takes x position, y position, attribute, address of string and its length
printstr:       push bp
                mov bp, sp
                push es
                push ax
                push cx
                push si
                push di

                mov    ax, 0xb800
                mov    es, ax             ; point es to video base
                mov    al, 80             ; load al with columns per row
                mul    byte [bp+10]       ; multiply with y position
                add    ax, [bp+12]        ; add x position
                shl    ax, 1              ; turn into byte offset
                mov    di, ax             ; point di to required location
                mov    si, [bp+6]         ; point si to string
                mov    cx, [bp+4]         ; load length of string in cx
                mov    ah, [bp+8]         ; load attribute in ah

                cld                       ; auto increment mode
nextchar:       lodsb                     ; load next char in al
                stosw                     ; print char/attribute pair
                loop nextchar             ; repeat for the whole string

                pop    di
                pop    si
                pop    cx
                pop    ax
                pop    es
                pop    bp
                ret    10

; ---- subroutine to print a number at x,y (Example 6.3 with a position) ----
; takes x position, y position and the number to be printed
PrintNum:       push bp
                mov bp, sp
                push es
                push ax
                push bx
                push cx
                push dx
                push di

                mov    ax, 0xb800
                mov    es, ax             ; point es to video base
                mov    al, 80             ; load al with columns per row
                mul    byte [bp+6]        ; multiply with y position
                add    ax, [bp+8]         ; add x position
                shl    ax, 1              ; turn into byte offset
                mov    di, ax             ; point di to required location

                mov    ax, [bp+4]         ; load number in ax
                mov    bx, 10             ; use base 10 for division
                mov    cx, 0              ; initialize count of digits

pn_digit:       mov dx, 0                 ; zero upper half of dividend
                div bx                    ; divide by 10
                add dl, 0x30              ; convert digit into ascii value
                push dx                   ; save ascii value on stack
                inc cx                    ; increment count of values
                cmp ax, 0                 ; is the quotient zero
                jnz pn_digit              ; if no divide it again

pn_pos:         pop dx                    ; remove a digit from the stack
                mov dh, 0x0F              ; bright white attribute
                mov [es:di], dx           ; print char on screen
                add di, 2                 ; move to next screen location
                loop pn_pos               ; repeat for all digits on stack

                pop    di
                pop    dx
                pop    cx
                pop    bx
                pop    ax
                pop    es
                pop    bp
                ret    6

; ============================================================================
; 1. RandomStation   (3%)
;    in  AL = entrance (0 or 1)      out AL = station letter 'A'..'D'
;    Entrance 0 can reach A,B,C,D (4 choices); entrance 1 only B,C,D (3).
; ============================================================================
RandomStation:  push bx
                push cx
                push dx

                xor ah, ah
                mov bx, ax                ; bx = entrance, 0 or 1

                mov ax, [RandSeed]        ; next number = seed*25173 + 13849
                mov cx, 25173
                mul cx
                add ax, 13849
                add ax, [Ticks]           ; mix in the tick counter
                mov [RandSeed], ax        ; remember it for the next call

                mov cl, 8
                shr ax, cl                ; high byte is the better random part
                mov cx, 4                 ; entrance 0 -> 4 stations
                sub cx, bx                ; entrance 1 -> 3 stations
                xor dx, dx
                div cx                    ; dx = remainder, 0 .. cx-1
                add dx, bx                ; entrance 1 skips 'A'
                mov al, 'A'
                add al, dl                ; turn into the station letter

                pop dx
                pop cx
                pop bx
                ret

; ============================================================================
; 2. ClearClaims   (2%)
;    Forget the cells claimed in the previous update.
; ============================================================================
ClearClaims:    mov word [ClaimCount], 0
                ret

; ============================================================================
; 3. CanEnter   (9%)
;    in  DH = row, DL = col        out AL = 1 (free, now claimed) / 0 (wait)
;    A cell is free if no active train stands on it and nobody claimed it
;    during this update.
; ============================================================================
CanEnter:       push bx
                push cx

                mov bx, TrainTable        ; point bx to the first train
                mov cx, 8                 ; number of train records
ce_occ:         cmp word [bx+10], 0       ; is this slot in use
                je ce_nextocc             ; no, look at the next one
                cmp byte [bx], dh         ; same row
                jne ce_nextocc
                cmp byte [bx+2], dl       ; same column
                jne ce_nextocc
                jmp ce_no                 ; a train is already standing here
ce_nextocc:     add bx, 12                ; advance to next record
                loop ce_occ

                mov cx, [ClaimCount]      ; has it been claimed this update
                cmp cx, 0
                je ce_claim               ; nothing claimed yet
                mov bx, Claims
ce_cl:          cmp [bx], dx              ; claimed cell equals wanted cell
                je ce_no
                add bx, 2
                loop ce_cl

ce_claim:       mov bx, [ClaimCount]
                cmp bx, 16                ; claim table full, be safe
                jae ce_no
                shl bx, 1                 ; word index into byte offset
                mov [Claims+bx], dx       ; claim the cell
                inc word [ClaimCount]
                mov al, 1
                jmp ce_done

ce_no:          mov al, 0
ce_done:        pop cx
                pop bx
                ret

; ============================================================================
; 4. SpawnTrain   (8%)
;    out AL = 1 a train was placed, AL = 0 nothing spawned.
;    Takes the first free slot, tries the entrance after the one used last,
;    then the other. An entrance is usable only if CanEnter says it is empty.
; ============================================================================
SpawnTrain:     push bx
                push cx
                push dx
                push si
                push di

                mov bx, TrainTable
                mov cx, 8
st_find:        cmp word [bx+10], 0       ; is this slot free
                je st_slot
                add bx, 12
                loop st_find
                jmp st_fail               ; all 8 slots are in use

st_slot:        mov si, bx                ; si = address of the free slot
                mov al, [NextEntrance]
                xor ah, ah
                mov di, ax                ; di = first entrance to try
                mov cx, 2                 ; try at most two entrances

st_try:         mov bx, di
                mov dh, [EntryRow+bx]     ; row of this entrance
                mov dl, [EntryCol+bx]     ; column of this entrance
                call CanEnter             ; empty and unclaimed?
                cmp al, 1
                je st_place
                xor di, 1                 ; try the other entrance
                loop st_try
                jmp st_fail

st_place:       mov ax, di
                xor ax, 1
                mov [NextEntrance], al    ; alternate entrances next time

                mov al, dh
                xor ah, ah
                mov [si], ax              ; row
                mov al, dl
                mov [si+2], ax            ; column

                mov ax, di                ; entrance number goes in AL
                call RandomStation        ; AL = destination letter
                xor ah, ah
                mov [si+4], ax            ; destination letter

                mov ax, [CurInterval]
                mov [si+6], ax            ; interval of the new train
                mov [si+8], ax            ; first move after one interval
                mov word [si+10], 1       ; slot is now active
                mov al, 1
                jmp st_done

st_fail:        mov al, 0
st_done:        pop di
                pop si
                pop dx
                pop cx
                pop bx
                ret

; ============================================================================
; 5. HookTimer   (4%)
;    Save the old INT 8 vector and install TimerISR (Example 9.11 style).
; ============================================================================
HookTimer:      push ax
                push es

                xor ax, ax
                mov es, ax                ; point es to IVT base
                mov ax, [es:0x08*4]
                mov [oldtimer], ax        ; save offset of old routine
                mov ax, [es:0x08*4+2]
                mov [oldtimer+2], ax      ; save segment of old routine
                cli                       ; disable interrupts
                mov word [es:0x08*4], TimerISR ; store offset at n*4
                mov [es:0x08*4+2], cs     ; store segment at n*4+2
                sti                       ; enable interrupts

                pop es
                pop ax
                ret

; ============================================================================
; 6. TimerISR   (4%)
;    Counts a tick, counts down every active train, then chains to the old
;    handler, which sends the EOI and executes the iret.
; ============================================================================
TimerISR:       push ds
                push ax
                push bx
                push cx

                push cs
                pop ds                    ; ds = our data segment

                inc word [Ticks]          ; one more tick

                mov bx, TrainTable
                mov cx, 8
ti_next:        cmp word [bx+10], 0       ; is the train active
                je ti_skip                ; no, ignore it
                cmp word [bx+8], 0        ; already ready to move
                je ti_skip
                dec word [bx+8]           ; one tick closer to the next move
ti_skip:        add bx, 12
                loop ti_next

                pop cx
                pop bx
                pop ax
                pop ds
                jmp far [cs:oldtimer]     ; call the original ISR

; ============================================================================
; 7. RecordArrival   (5%)
;    in SI = train index, AL = station letter the train reached.
;    Right station: Score + 1.  Wrong station: Mistakes + 1.
;    The train is removed either way.  At 6 (12 co-op) deliveries SpeedUp runs.
; ============================================================================
RecordArrival:  push ax
                push bx
                push cx
                push dx

                mov cl, al                ; keep the station letter
                mov ax, 12
                mul si                    ; ax = index * 12
                add ax, TrainTable
                mov bx, ax                ; bx = address of the train record

                cmp word [bx+10], 0       ; ignore a train that is not active
                je ra_done

                cmp cl, [bx+4]            ; station letter == destination
                jne ra_wrong

                inc word [Score]          ; right station
                mov word [bx+10], 0       ; remove the train

                cmp byte [SpedUp], 0      ; speed-up happens only once
                jne ra_done
                mov ax, 6                 ; single player threshold
                cmp byte [Mode], 0
                je ra_cmp
                mov ax, 12                ; co-op threshold
ra_cmp:         cmp [Score], ax
                jb ra_done                ; not there yet
                call SpeedUp              ; Shauzab's procedure
                jmp ra_done

ra_wrong:       inc word [Mistakes]       ; wrong station
                mov word [bx+10], 0       ; remove the train

ra_done:        pop dx
                pop cx
                pop bx
                pop ax
                ret

; ============================================================================
; 8. CheckGameOver   (3%)
;    out AL = 0 playing, 1 won (10 / 20 co-op deliveries), 2 lost (5 mistakes)
; ============================================================================
CheckGameOver:  push bx

                mov bx, 10                ; single player target
                cmp byte [Mode], 0
                je cg_chk
                mov bx, 20                ; co-op target
cg_chk:         cmp [Score], bx
                jae cg_win
                cmp word [Mistakes], 5
                jae cg_lose
                mov byte [GameState], 0   ; still playing
                jmp cg_done
cg_win:         mov byte [GameState], 1
                jmp cg_done
cg_lose:        mov byte [GameState], 2
cg_done:        mov al, [GameState]

                pop bx
                ret

; ============================================================================
; 9. ShowResult   (4%)
;    Draws the win / lose screen with score, mistakes and time in seconds
;    (18 ticks per second) and waits for R (replay) or Esc (exit).
;    out AL = 1 replay, AL = 0 exit
; ============================================================================
ShowResult:     push bx
                push dx

                call clrscr

                mov ax, 34
                push ax                   ; x position
                mov ax, 6
                push ax                   ; y position
                cmp byte [GameState], 1
                jne sr_lose
                mov ax, 0x0A              ; green on black
                push ax
                mov ax, msgwin
                push ax
                mov ax, 8
                push ax
                jmp sr_title
sr_lose:        mov ax, 0x0C              ; red on black
                push ax
                mov ax, msglose
                push ax
                mov ax, 9
                push ax
sr_title:       call printstr

                mov ax, 30                ; "Score:"
                push ax
                mov ax, 9
                push ax
                mov ax, 0x07
                push ax
                mov ax, msgscore
                push ax
                mov ax, 6
                push ax
                call printstr
                mov ax, 41                ; the score value
                push ax
                mov ax, 9
                push ax
                push word [Score]
                call PrintNum

                mov ax, 30                ; "Mistakes:"
                push ax
                mov ax, 10
                push ax
                mov ax, 0x07
                push ax
                mov ax, msgmist
                push ax
                mov ax, 9
                push ax
                call printstr
                mov ax, 41                ; the mistakes value
                push ax
                mov ax, 10
                push ax
                push word [Mistakes]
                call PrintNum

                mov ax, 30                ; "Time (s):"
                push ax
                mov ax, 11
                push ax
                mov ax, 0x07
                push ax
                mov ax, msgtime
                push ax
                mov ax, 9
                push ax
                call printstr
                mov ax, 41                ; elapsed seconds = ticks / 18
                push ax
                mov ax, 11
                push ax
                mov ax, [Ticks]
                xor dx, dx
                mov bx, 18
                div bx
                push ax
                call PrintNum

                mov ax, 28                ; "R = Replay    Esc = Exit"
                push ax
                mov ax, 14
                push ax
                mov ax, 0x07
                push ax
                mov ax, msgopt
                push ax
                mov ax, 24
                push ax
                call printstr

sr_key:         mov ah, 0                 ; service 0 - get keystroke
                int 0x16                  ; call BIOS keyboard service
                cmp al, 'R'
                je sr_replay
                cmp al, 'r'
                je sr_replay
                cmp al, 27                ; is the Esc key pressed
                je sr_exit
                jmp sr_key                ; any other key is ignored

sr_replay:      mov al, 1
                jmp sr_end
sr_exit:        mov al, 0
sr_end:         pop dx
                pop bx
                ret

; ============================================================================
; 10. ResetGame   (5%)
;     Puts every game variable back to its starting value. Mode is kept.
; ============================================================================
ResetGame:      push ax
                push cx
                push di
                push es

                push ds
                pop es                    ; es = ds for the string stores
                cld                       ; auto increment mode
                xor ax, ax

                mov di, TrainTable        ; remove every train
                mov cx, 48
                rep stosw

                mov di, Claims            ; forget every claim
                mov cx, 16
                rep stosw

                mov di, Switches          ; all four switches back to route 0
                mov cx, 2
                rep stosw

                mov [ClaimCount], ax
                mov [Score], ax
                mov [Mistakes], ax
                mov [SpedUp], al
                mov [GameState], al
                mov [NextEntrance], al
                mov [Ticks], ax
                mov word [CurInterval], 12 ; starting interval in ticks

                pop es
                pop di
                pop cx
                pop ax
                ret

; ============================================================================
; 11. UnhookTimer   (3%)
;     Put the saved INT 8 vector back. Must run before returning to DOS.
; ============================================================================
UnhookTimer:    push ax
                push es

                cmp word [oldtimer+2], 0  ; was the timer ever hooked
                je ut_done                ; no, nothing to restore

                xor ax, ax
                mov es, ax                ; point es to IVT base
                mov ax, [oldtimer]        ; read old offset in ax
                cli                       ; disable interrupts
                mov [es:0x08*4], ax       ; restore old offset
                mov ax, [oldtimer+2]      ; read old segment in ax
                mov [es:0x08*4+2], ax     ; restore old segment
                sti                       ; enable interrupts

ut_done:        pop es
                pop ax
                ret