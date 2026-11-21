[org 0x0100]
;stepdir: al = direction
stepdir:
    cmp al, 1      
    jne checkup
    inc dl
    ret
checkup:
    cmp al, 2        
    jne godown
    dec dh
    ret
godown:
    inc dh             
    ret
; drawswitch: bl = switch number (between 0 and 3)
drawswitch:
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
nextroute:
    mov dh, [si]        ; switch row
    mov dl, [si+1]      ; switch col
    mov bl, cl
    mov bh, 0
    mov al, [si+bx+2]   ; this route's direction
    call stepdir        ; move to route's first cell
    mov ah, 0x08        ; grey = not selected
    cmp cl, ch
    jne pickchar
    mov ah, 0x0E        ; yellow = selected
pickchar:
    mov bl, al
    mov al, '-'
    cmp bl, 1           ; horizontal?
    je drawit
    mov al, '|'
drawit:
    call putchar
    inc cl
    cmp cl, 2           ; both routes done?
    jb nextroute
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret