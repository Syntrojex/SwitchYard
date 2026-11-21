[org 0x0100]
;SwitchYard By Shauzab Mukhtar (25L-3084) and Muhammad Mustafa Amir (25L-3107)
[org 0x0100]           
jmp start           
%include "data.asm"
%include "Shauzab.asm"
%include "mustafa.asm"
start:
    mov ax, 3       ; 80x25 text mode, clears screen
    int 10h
    mov ax, 0B800h  
    mov es, ax
    call DrawTrack
    mov ah, 0       
    int 16h
    mov ax, 4C00h   
    int 21h
mov ax, 0x4c00
int 0x21