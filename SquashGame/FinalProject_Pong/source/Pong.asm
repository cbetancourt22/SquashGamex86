;-------------------------------------------------------------------
; Team Two | Whitworth University 
; Last Modified:  May 14, 2020

; Creation of a Pong console game using the Assembly language
;-------------------------------------------------------------------

INCLUDE Irvine32.inc 

.data   
   ; Console Output
   caption db "TEAM TWO", 0
   HelloMsg BYTE "THE BEST ASSEMBLY GAME EVER.", 0dh, 0ah
            BYTE "Click OK to start...", 0
   Message_LivesLeft BYTE "Lives:   ", 0
   lives BYTE 5 ; total of lives
   Message_GameOver BYTE "GAME OVER! ", 0 
   Mesage_PlayerScore BYTE "Score: ", 0
   score BYTE 0 ; score counter
   
   blankLines BYTE 80 dup(219), 0 ; lines where the ball will me moving and updating

   ; Initial Position of Ball 
   ballX BYTE 40 
   ballY BYTE 10
   speedOfBall DWORD 100
   ; Change the direction of the ball
   MoveX BYTE 1 
   MoveY BYTE 1
   prevBallX BYTE 40 ; previous positon of ball in X and Y
   prevBallY BYTE 10
   playerPos BYTE 10

   ; playerPos2 BYTE 
   PaddleMaxMoves = 18 ; y-axis max movements of paddle

.code
main PROC 
    ; Set up the colors for the console
    mov eax, white + (black * 16) 
    call SetTextColor
    mov ebx, 0 ; no caption
    mov ebx, OFFSET caption ; caption
    mov edx, OFFSET HelloMsg ; contents
    call MsgBox

    mov edx, 0
    call Gotoxy ; move cursor 
    mov edx, OFFSET blankLines
    call WriteString
    mov dx, 0
    call Gotoxy

    ; Print out the borders for the console
    mov ecx, 23
    border:
        mov al, 219
        call WriteChar
        call Crlf
    loop border

    ; Print out the lines where the ball and paddle move
    mov edx, OFFSET blankLines
    call WriteString
    mov edx, 4
    call Gotoxy

    ; Get either a 0 or 1 to increase or decrease the movements of
    ; the ball. Thinks of this as a delta x and y for the ball. The
    ; ball is moved randomly
    call Randomize
    mov eax, 2
    call RandomRange
    cmp eax, 1
    jne positive
    mov MoveX, 1
    jmp aroundA

    positive:
        mov MoveX, -1

    aroundA:
        mov eax, 2
        call RandomRange
        cmp eax, 1
        jne positive1
        mov MoveY, 1
        jmp aroundB

    positive1:
        mov MoveY, -1
    aroundB:
        ; start the game
        call GameLoop
        mov eax, 0FFFFFFFFh 
        call Delay

        exit 
main ENDP

;--------------------------------------------------------------------
; GameLoop
;
; The game is developed here, drawing the paddle, updating the paddle,
; updating the ball
;
; Receives: eax
; Returns: NA
;---------------------------------------------------------------------
GameLoop PROC
top:
    call DrawPlayer
    call UpdateBall
    call MovePaddle
    mov eax, speedOfBall
    call Delay
    jmp top
GameLoop ENDP

;--------------------------------------------------------------------
; UpdateBall
;
; Updates the positon of the ball in the blank lines defined for the
; movements of the ball
;
; Receives: eax, edx
; Returns: NA
;---------------------------------------------------------------------
UpdateBall PROC
    push eax
    push edx
    mov dl, ballX ; Clear ball from previous location
    mov dh, ballY
    call Gotoxy

    mov al, ' '
    call WriteChar

    mov al, ballY ; Bottom wall collision
    cmp al, 22
    jb notBottomWall
    neg MoveY
    jmp notYCollide

notBottomWall:
    mov al, ballY ; Top wall collision
    cmp al, 1
    ja notTopWall
    neg MoveY

notTopWall:
notYCollide:
    mov al, ballX ; Paddle collision
    cmp al, 73
    jbe notRightWall
    mov al, ballY
    mov ah, playerPos
    add ah, 5
    cmp al, ah
    jae notPaddle
    cmp al, playerPos
    jbe notPaddle
    neg MoveX
    inc score 
    jmp notRightWall
    ; If it didn't collide with the paddle, then decreases the
    ; lives of the player
notPaddle:
    dec lives
    call ResetRound

notRightWall:
    mov al, ballX
    cmp ballX, 1
    ja notLeftWall
    neg MoveX

notLeftWall:
    mov al, ballX ; Update ball's X position
    add al, MoveX
    mov ballX, al

    mov al, ballY ; Update ball's Y position
    add al, MoveY
    mov ballY, al
    
    mov dl, ballX ; Draw ball in the next position
    mov dh, ballY
    call Gotoxy
    mov al, 'O' ; shape of the ball
    call WriteChar

    pop edx
    pop eax
    ret
UpdateBall ENDP

;--------------------------------------------------------------------
; ResetRound
;
; Moves the ball back to the initial positon after the player had 
; lives decreased 
;
; Receives: eax, edx
; Returns: NA
;---------------------------------------------------------------------
ResetRound PROC
    push eax
    push edx

    ; Lives and score printed out, updated
    mov dl, 10
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET Message_LivesLeft
    call WriteString
    movzx eax, lives
    call WriteDec ; print score

    ; reset ball positions
    mov ballX, 40
    mov ballY, 10

    call Randomize
    mov eax, 2
    call RandomRange
    cmp eax, 1
    jne positive
    mov MoveX, 1
    jmp aroundA
positive:
    mov MoveX, -1
aroundA:
    mov eax, 2
    call RandomRange
    cmp eax, 1
    jne positive1
    mov MoveY, 1
    jmp aroundB
positive1:
    mov MoveY, -1
aroundB:
    cmp lives, 0
    ja continue
    mov dl, 15
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET Message_GameOver
    call WriteString
    call WaitMsg
    exit
continue:
    pop edx
    pop eax
    ret
ResetRound ENDP

;--------------------------------------------------------------------
; DrawPlayer
;
; Moves the paddle along the y-axis, incrementing the position
; of the paddle 1 block at a time
;
; Receives: playerPos
; Returns: NA
;---------------------------------------------------------------------
DrawPlayer PROC
    pushad
    ; !!!!!!!!IMPORTAAAANNTTTTTT PADDLE POSITION HERE!!!!!
    mov dl, 75 ; Clear previous paddle pixels
    mov dh, 1
    call Gotoxy
    mov ecx, (PaddleMaxMoves + 4)
    mov al, ' '
    
    ;Every time the paddle moves, it leaves the characters used to move it
    ; in a line. When the paddle is moved, it deletes the traces it leaves
clearTracePaddle:
    call WriteChar
    inc dh
    call Gotoxy
    loop clearTracePaddle

    ; Increase the movements of the paddle in the y- axis
    mov dh, playerPos
    call Gotoxy

    mov al, 219
    call WriteChar
    inc dh
    call Gotoxy
    call WriteChar
    inc dh
    call Gotoxy
    call WriteChar
    inc dh
    call Gotoxy
    call WriteChar
    inc dh
    call Gotoxy
    call WriteChar

    ; Output Lives
    mov dl, 10
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET Message_LivesLeft
    call WriteString
    movzx eax, lives
    call WriteDec

    ; Output Score
    mov dl, 10
    mov dh, 6
    call Gotoxy
    mov edx, OFFSET Mesage_PlayerScore
    call WriteString
    movzx eax, score
    call WriteDec

    popad
    ret
DrawPlayer ENDP

;--------------------------------------------------------------------
; MovePaddle
;
; Controls the character pressed by the player to move the paddle
; in the y-axis. Then, it moves the paddle, Up and Down
;
; Receives: readKey (checks if key pressed is 'E' or 'D')
; Returns: NA
;---------------------------------------------------------------------
MovePaddle PROC
    mov edx, 0
    call ReadKey ; check for key
    cmp al, 077h ; Is up key pressed? 'W'
    jne notUp
    call MoveUp

    notUp:
    cmp al, 073h ; Is down key pressed? 'S'
    jne notDown
    call moveDown
    notDown:
    ret
 MovePaddle ENDP
 

;--------------------------------------------------------------------
; MoveUp
;
; Moves the paddle along the y-axis, incrementing the position
; of the paddle 1 block at a time
;
; Receives: playerPos
; Returns: NA
;---------------------------------------------------------------------
 MoveUp PROC
    push eax
    movzx eax, playerPos
    cmp eax, 1 ; top border of the console
    ; check for overflow
    jbe tooBigOne
    dec playerPos ; move the paddle
    dec playerPos
    tooBigOne:
    pop eax ; pop position from the eax and compare to border 
    ret
 MoveUp ENDP
 

;--------------------------------------------------------------------
; MoveDown
;
; Moves the paddle along the y-axis, decrementing the position
; of the paddle 1 block at a time
;
; Receives: playerPos 
; Returns: NA
;---------------------------------------------------------------------
 moveDown PROC
    push eax
    movzx eax, playerPos
    cmp eax, PaddleMaxMoves
    ; check for overflow
    jae tooSmallOne
    inc playerPos ; move the paddle
    inc playerPos
    tooSmallOne:
    pop eax
    ret
moveDown ENDP

END main
