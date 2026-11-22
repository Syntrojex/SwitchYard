;Shauzab's data
switchinfo: db 4,12,1,3,  20,12,1,2,  12,35,2,1,  12,48,1,3
; rails: row, col, direction, length
lineTable:  db 4,2,1,10,   4,13,1,48,  5,12,3,7
            db 20,2,1,10,  20,13,1,18, 13,12,2,7
            db 12,12,1,23, 9,35,2,3,   8,35,1,26
            db 12,36,1,12, 12,49,1,12, 13,48,3,3
            db 16,48,1,13
; stations: row, col, letter
stationInfo: db 4,61,'A', 8,61,'B', 12,61,'C', 16,61,'D', 20,31,'D'
entry1:     db 'ENTRY 1',0
entry2:     db 'ENTRY 2',0
trackMap:   times 2000 db 0     ; 25x80 hidden map for trains
menuTitle:  db 'S W I T C H Y A R D',0
menuOpt1:   db '1 - Single Player',0
menuOpt2:   db '2 - Two Player Co-op',0
menuHint:   db 'Press 1 or 2 to start',0
hudScore:   db 'Score:',0
hudMist:    db 'Mistakes:',0
hudTime:    db 'Time:',0
;subroutines
putChar:
    push ax
    push bx
    push di
    mov bx,ax       ; save char and the colour
    mov al,80
    mul dh
    add al,dl
    adc ah,0        ;add and carry operation
    shl ax,1        ;double
    mov di,ax
    mov [es:di],bx  ;display on video base
    pop di
    pop bx
    pop ax
    ret
; here dh=row, dl=col and bl=code
setMap:
    push ax
    push di
    mov al,80
    mul dh
    add al,dl
    adc ah,0        ;add and carry operation
    mov di,ax
    mov [trackMap+di],bl
    pop di
    pop ax
    ret
;display chars
printStr:
    push ax
    push dx
    push si
nextChar:
    mov al,[si]
    cmp al,0
    je printDone
    call putChar
    inc si
    inc dl
    jmp nextChar
printDone:
    pop si
    pop dx
    pop ax
    ret
drawTrack:
    push ax
    push bx
    push cx
    push dx
    push si
    ;rails
    mov si,lineTable
    mov cx,13       ; 13 rail lines
nextLine:
    push cx
    mov dh,[si]     ; row
    mov dl,[si+1]   ; col
    mov bl,[si+2]   ; direction
    mov cl,[si+3]   ; length
    mov ch,0
    mov al,0xC4     ;solid horizontal line
    cmp bl,1        ;is it horizontal or not
    je nextCellDraw
    mov al,0xB3     ;solid vertical line
nextCellDraw:
    mov ah,0x07     ;grey color
    call putChar    ;drawing on screen
    call setMap     ;save direction in map
    cmp bl,1
    jne stepDown
    inc dl          ;go right
    jmp cellDone
stepDown:
    inc dh          ;go down
cellDone:
    loop nextCellDraw
    add si,4
    pop cx
    loop nextLine
    ;switches
    mov si,switchinfo
    mov cl,0
nextSwitch:
    mov dh,[si]
    mov dl,[si+1]
    mov bl,cl
    add bl,0x10     ; map code equals 0x10+n
    call setMap
    mov al,cl
    add al,'1'      ;digit between 1 and 4
    mov ah,0x1E     ;yellow on blue bg
    call putChar
    mov bl,cl
    call drawSwitch ;colour its routes
    add si,4
    inc cl
    cmp cl,4
    jb nextSwitch
    ;stations
    mov si,stationInfo
    mov cx,5
nextStation:
    mov dh,[si]
    mov dl,[si+1]
    mov bl,[si+2]   ;letter equals a map code
    call setMap
    mov al,bl
    mov ah,0x2F     ;white on green
    call putChar
    add si,3
    loop nextStation
    ;labels
    mov ah,0x0F
    mov dh,3
    mov dl,2
    mov si,entry1
    call printStr
    mov dh,21
    mov si,entry2
    call printStr
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
;stepdir: al = direction
stepDir:
    cmp al, 1
    jne checkUp
    inc dl
    ret
checkUp:    ;is it up?
    cmp al, 2
    jne goDown
    dec dh
    ret
goDown:     ;is it down?
    inc dh
    ret
; drawswitch: bl = switch number (between 0 and 3)
drawSwitch:
    push ax
    push bx
    push cx
    push dx
    push si
    mov bh, 0
    mov si, bx
    shl si, 1
    shl si, 1           ; si = n*4
    add si, switchinfo  ; si -> this switch's record
    mov ch, [Switches+bx] ; ch = selected route
    mov cl, 0           ; cl = route being drawn
nextRoute:
    mov dh, [si]        ; switch row
    mov dl, [si+1]      ; switch col
    mov bl, cl
    mov bh, 0
    mov al, [si+bx+2]   ; this route's direction
    call stepDir        ; move to route's first cell
    mov ah, 0x08        ; grey = not selected
    cmp cl, ch
    jne pickChar
    mov ah, 0x0E        ; yellow means selected
pickChar:
    mov bl, al
    mov al, 0xC4        ;solid horizontal line
    cmp bl, 1           ; horizontal?
    je drawIt
    mov al, 0xB3        ;solid vertical line
drawIt:
    call putChar
    inc cl
    cmp cl, 2           ; both routes done?
    jb nextRoute
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
;bl is our switch number (between 0 and 3)
toggleSwitch:
    push bx
    mov bh,0
    xor byte [Switches+bx],1 ;flip switch (0 to 1 or 1 to 0)
    call drawSwitch
    pop bx
    ret
;keys from 1-4 switch on respective switches from 1-4
handleKeys:
    push ax
    push bx
    mov ah,1
    int 0x16    ;check key
    jz noKey
    mov ah,0
    int 0x16    ;read key
    cmp al,'1'
    jb noKey
    cmp al,'4'
    ja noKey
    sub al,'1'   ;2 becomes 1, 3 becomes 2 etc
    mov bl,al
    call toggleSwitch   ;flips switches
noKey:
    pop bx
    pop ax
    ret
;player 1 has keys 1 and 2 and player 2 has keys J/j and K/k
coopKeys:
    push ax
    push bx
    mov ah,1
    int 0x16    ;check key
    jz coopDone
    mov ah,0
    int 0x16    ;read key
    ;compare  and try
    cmp al,'1'
    jne try2
    mov bl,0    ;switch 1
    jmp coopFlip
try2:
    cmp al,'2'
    jne tryJ
    mov bl,1    ;switch 2
    jmp coopFlip
tryJ:
    or al,0x20  ;handles uppercase and lowercase alphabets
    cmp al,'j'
    jne tryK
    mov bl,2    ;switch 3
    jmp coopFlip
tryK:
    cmp al,'k'
    jne coopDone
    mov bl,3    ;switch 4
    jmp coopFlip
coopFlip:
    call toggleSwitch
coopDone:
    pop bx
    pop ax
    ret
; nextCell: dh(row) and dl(col) of the train
; returns the cell it wants to move to
nextCell:
    push ax
    push bx
    push di
    mov al,80
    mul dh
    add al,dl
    adc ah,0
    mov di,ax
    mov al,[trackMap+di] ; code under the train
    cmp al,0x10
    jb plainRail        ; 1,2 or 3 = normal rail
    cmp al,0x13
    ja noMove
    sub al,0x10         ; al = switch number  between 0 and 3
    mov bl,al
    mov bh,0
    mov al,[Switches+bx] ; al = selected route (0 or 1)
    shl bx,1
    shl bx,1
    add bl,al
    mov al,[switchinfo+bx+2]
plainRail:
    call stepDir        ; move dh and dl just one cell
noMove:
    pop di
    pop bx
    pop ax
    ret
;di stores the index
getIndex:
    push ax
    mov al,80
    mul dh
    add al,dl
    adc ah,0
    mov di,ax
    pop ax
    ret
;restoreCell: repaints the track at dh and dl after a train has left
restoreCell:
    push ax
    push bx
    push di
    call getIndex
    mov bl,[trackMap+di]
    mov ah,0x07
    mov al,0xC4           ;solid horizontal line
    cmp bl,1              ;horizontal rail
    je rcDraw
    mov al,0xB3           ;solid vertical line
    cmp bl,0x10           ;vertical rail
    jb rcDraw
    cmp bl,0x13
    ja rcStation
    mov al,bl             ;switch is its digit
    sub al,0x10
    add al,'1'
    mov ah,0x1E
    jmp rcDraw
rcStation:
    mov al,bl             ;station is its letter
    mov ah,0x2F
rcDraw:
    call putChar
    pop di
    pop bx
    pop ax
    ret
; moveTrains: moves every train whose countdown hit 0 (TimerISR counts down)
moveTrains:
    push ax
    push bx
    push cx
    push dx
    push si
    call ClearClaims      ;fresh claims for this update
    mov si,TrainTable
    mov cx,8              ;8 train slots, 12 bytes each
nextTrain:
    cmp word [si+10],0    ;is it active?
    je skipTrain
    cmp word [si+8],0     ;countdown reached 0?
    jne skipTrain         ;not its turn yet
    mov dh,[si]           ;row
    mov dl,[si+2]         ;col
    mov bx,dx             ;bx = old cell
    call nextCell         ;dh and dl is the wanted cell
    call CanEnter         ;al=1 free (claimed), al=0 wait
    cmp al,1
    jne skipTrain         ;blocked, try again next update
    mov ax,[si+6]
    mov [si+8],ax         ;reload countdown -> interval
    mov [si],dh           ;save new position
    mov [si+2],dl
    mov al,[si+4]         ;destination letter
    mov ah,0x4F           ;white on red bg
    call putChar          ;draw train
    mov dx,bx             ;old cell
    call restoreCell      ;repaint where it was
    call CanEnter         ;claim old cell so nobody enters it this update
    call checkArrival
    call CheckGameOver    ;stop the moment the game is won or lost
    cmp al,0
    jne moveDone
skipTrain:
    add si,12             ;next record
    loop nextTrain
moveDone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
; checkArrival: si points to the train that just moved
checkArrival:
    push ax
    push bx
    push dx
    push di
    push si
    mov dh,[si]
    mov dl,[si+2]
    call getIndex
    mov bl,[trackMap+di]  ;what is under the train
    cmp bl,'A'
    jb notArrived         ;rail or switch means keep going
    call restoreCell      ;repaint the station letter
    mov ax,si
    sub ax,TrainTable
    mov dl,12
    div dl                ;al = train index
    mov ah,0
    mov si,ax             ;si = index (Mustafa's RecordArrival wants this)
    mov al,bl             ;al = station letter
    call RecordArrival
notArrived:
    pop si
    pop di
    pop dx
    pop bx
    pop ax
    ret
; SpeedUp: halves all intervals once (RecordArrival checks 6/12)
SpeedUp:
    push cx
    push si
    cmp byte [SpedUp],1
    je speedDone          ;already done, so never again
    mov byte [SpedUp],1   ;mark it as done
    shr word [CurInterval],1   ;new trains get half
    jnz baseOk
    mov word [CurInterval],1   ;minimum 1
baseOk:
    mov si,TrainTable
    mov cx,8
halveLoop:
    cmp word [si+10],0    ;active train?
    je halveNext
    shr word [si+6],1     ;interval halved
    jnz intervalOk
    mov word [si+6],1     ;minimum 1
intervalOk:
    shr word [si+8],1     ;countdown halved too
    jnz halveNext
    mov word [si+8],1
halveNext:
    add si,12
    loop halveLoop
speedDone:
    pop si
    pop cx
    ret
; showMenu: sets mode = 0 (single player) or 1 (two player)
showMenu:
    push ax
    push cx               ;cx is used to hide the cursor
    push dx
    push si
    mov ax,0x0003
    int 0x10              ;clear screen
    mov ah,0x0E           ;yellow
    mov dh,8
    mov dl,30
    mov si,menuTitle
    call printStr
    mov ah,0x0F           ;white
    mov dh,11
    mov dl,30
    mov si,menuOpt1
    call printStr
    mov dh,13
    mov si,menuOpt2
    call printStr
    mov ah,0x07           ;grey
    mov dh,16
    mov dl,29
    mov si,menuHint
    call printStr
menuWait:
    mov ah,0
    int 0x16              ;wait for a key
    cmp al,'1'
    je pickSingle
    cmp al,'2'
    jne menuWait          ;anything else means wait again
    mov byte [Mode],1     ;two player
    jmp menuDone
pickSingle:
    mov byte [Mode],0     ;single-player
menuDone:
    mov ax,0x0003
    int 0x10              ;clear screen for the game
    mov ah,1
    mov cx,0x2000
    int 0x10              ;hide the blinking cursor
    pop si
    pop dx
    pop cx
    pop ax
    ret
;drawHUD: show score, mistakes and time on row number 23
drawHUD:
    push ax
    push dx
    push si
    mov ah,0x0F           ;white
    mov dh,23
    mov dl,2
    mov si,hudScore
    call printStr
    mov dl,16
    mov si,hudMist
    call printStr
    mov dl,33
    mov si,hudTime
    call printStr
    mov ax,9              ;x of score
    push ax
    mov ax,23             ;y
    push ax
    push word [Score]
    call PrintNum         ;Mustafa's number printer
    mov ax,26             ;x of mistakes
    push ax
    mov ax,23
    push ax
    push word [Mistakes]
    call PrintNum
    mov ax,[Ticks]
    xor dx,dx
    mov si,18
    div si                ;ax = seconds (18 ticks per second)
    mov dx,39             ;x of time
    push dx
    mov dx,23
    push dx
    push ax
    call PrintNum
    pop si
    pop dx
    pop ax
    ret