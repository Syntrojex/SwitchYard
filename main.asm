[org 0x0100]
cpu 8086
    jmp start
%include "Mustafa.asm"
%include "Shauzab.asm"
lastTick:   dw 0
spawnTimer: db 1
start:
    mov ax,0xb800
    mov es,ax             ;es = video memory for putChar
    call HookTimer
    call showMenu
restart:
    call ResetGame
    call clrscr
    call drawTrack
    mov word [lastTick],0
    mov byte [spawnTimer],1
gameLoop:
    mov ax,[Ticks]
    cmp ax,[lastTick]
    je checkKeys          ;same tick, nothing to update
    mov [lastTick],ax
    dec byte [spawnTimer]
    jnz noSpawn
    mov byte [spawnTimer],36   ;new train every 2 seconds
    call SpawnTrain
noSpawn:
    call moveTrains
    call drawHUD
    call CheckGameOver    ;al = 0 playing, 1 won, 2 lost
    cmp al,0
    jne gameOver
checkKeys:
    mov ah,1
    int 0x16              ;check key
    jz gameLoop
    cmp al,27             ;Esc quits
    je quit
    cmp byte [Mode],1
    je useCoop
    call handleKeys
    jmp gameLoop
useCoop:
    call coopKeys
    jmp gameLoop
gameOver:
    call ShowResult       ;al = 1 replay, 0 exit
    cmp al,1
    je restart
quit:
    call UnhookTimer      ;give the timer back before DOS
    call clrscr
    mov ax,0x4c00
    int 0x21