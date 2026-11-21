[org 0x0100]
;stepdir: al = direction
jmp start
switchinfo: db 4,12,1,3,  20,12,1,2,  12,35,2,1,  12,48,1,3
switches:   db 0,0,0,0
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
    mov al,'-'
    cmp bl,1        ;is it horizontal
    je nextCellDraw
    mov al,'|'
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
    mov ch, [switches+bx] ; ch = selected route
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
    mov al, '-'
    cmp bl, 1           ; horizontal?
    je drawIt
    mov al, '|'
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
    xor byte [switches+bx],1 ;flip switch (0 to 1 or 1 to 0)
    call drawSwitch
    pop bx 
    ret
;keys from 1-4 switch on respective switches from 1-4
handleKeys:
    push ax
    push bx 
    mov ah,1
    int 0x16    ;wait key
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
    ;palyer 1 has keys 1 and 2 and player 2 has keys J/j and K/k
coopKeys:
    push ax
    push bx 
    mov ah,1
    int 0x16    ;wait key
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
start:
    mov ax,0x0003   ; text mode, clears screen
    int 0x10
    mov ax,0xb800   ; es = video memory
    mov es,ax
    call drawTrack
    mov ah,0        ; wait for key
    int 0x16
    mov ax,0x4c00   ; exit
    int 0x21