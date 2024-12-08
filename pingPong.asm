org 0x100  
cmp word[WidthProtection], 1
jne skipChecks
	cmp word[FieldWidth], 15
	jge sc1
	mov ax, 0x4C00
	int 0x21
	sc1:
	cmp word[FieldWidth], 38
	jle skipChecks
	mov ax, 0x4C00
	int 0x21
skipChecks:
call clearScreen
mov ax, 0xB800
mov es, ax
mov di, 160
mov ax, 0x0720
mov si, PT1
pn1:
	lodsb
	stosw
	cmp al, 0
	jnz pn1
push di
mov ax, P1
push ax
call inputString
mov ax, 0x0720
mov di, 320
mov si, PT2
pn2:
	lodsb
	stosw
	cmp al, 0
	jnz pn2
push di
mov ax, P2
push ax
call inputString
mov ax, [FieldWidth]
shl ax, 1
mov [FieldWidth], ax
mov word[BallPos], 2000
mov word[NextPos], 2000
mov word[BallMotion], -158
mov word[GameState], 0xFFFF
mov word[P2pos], 558
mov ax, [FieldWidth]
sub word[P2pos], ax
mov word[P1pos], 560
add word[P1pos], ax
mov word[P1score], 0
mov word[P2score], 0
lewp:
	mov ax, 0x0100
	int 0x16
	jz updateBall
	jmp checkInputs
	updateBall:
	cmp word[GameState], 0
	jnz cont
	mov ax, 0
	int 0x16
	cmp ah, 0x39
	jnz lewp
	call changeGameState
	cont:
	call delay
	call printScreen
	push ax
	push bx
	push dx
	startIteration:
		mov ax, [BallMotion]
		add [NextPos], ax
		mov ax, [BallMotion]
		checkSides:
			mov ax, 0xB800
			mov es, ax
			mov di, [NextPos]
			cmp word[es:di], 0x0020
			jnz checkWalls
			cmp word[BallMotion], -158
			jnz sk1
			call incP1
			sk1:
			cmp word[BallMotion], 162
			jnz sk2
			call incP1
			sk2:
			cmp word[BallMotion], 158
			jnz sk3
			call incP2
			sk3:
			cmp word[BallMotion], -162
			jnz sk4
			call incP2
			sk4:
			mov word[BallPos], 2000
			mov word[NextPos], 2000
			mov ax, [BallMotion]
			not ax
			add ax, 1
			mov word[BallMotion], ax
		checkWalls:
			cmp word[NextPos], 318 
				jge checkLowWall
				jmp UpperWall
		checkLowWall:
			cmp word[NextPos], 3680
				jle checkPlayers
				jmp LowerWall
		checkPlayers:
			mov ax, 0xB800
			mov es, ax
			mov di, [NextPos]
			cmp word[es:di], 0x0CDB
			jnz R1
			call RightWall
			jmp nextIteration
			R1:
			cmp word[es:di+2], 0x0CDB
			jnz checkLeftPlr
			call RightWall
			jmp nextIteration
		checkLeftPlr:
			mov ax, 0xB800
			mov es, ax
			mov di, [NextPos]
			cmp word[es:di], 0x02DB
			jnz L1
			call LeftWall
			jmp nextIteration
			L1:
			cmp word[es:di-2], 0x02DB
			jnz nextIteration
			call LeftWall
		nextIteration:
			mov ax, [BallMotion]
			add word[BallPos], ax
			mov ax, [BallPos]
			mov [NextPos], ax
			pop dx
			pop bx
			pop ax
			mov ax, [WinningScore]
			cmp ax, [P1score]
			je end
			cmp ax, [P2score]
			je end
			jmp lewp
	checkInputs:
	mov ax, 0
	int 0x16
	cmp ah, 0
	jz endIteration
	cmp ah, 0x48
	jne i0
	call P1up
	i0:
	cmp ah, 0x50
	jne i1
	call P1down
	i1:
	cmp ah, 0x11
	jne i2
	call P2up
	i2:
	cmp ah, 0x1F
	jne i3
	call P2down
	i3:
	cmp ah, 0x39
	jne i4
	call changeGameState
	i4:
	cmp ah, 0x01
	je end
	endIteration:
	call printScreen
	jmp lewp
end:
mov ax, 0xB800
mov es, ax
mov di, 2140
mov ax, 0x0700
mov bx, [P1score]
mov dx, [P2score]
cmp dx, bx
je w1
	cmp bx, dx
	jl w2
	mov si, P1
	jmp w3
		w2:
		mov si, P2
		w3:
			lodsb
			stosw
			cmp al, 0
			jnz w3
		mov si, WinText
		w4:
			lodsb
			stosw
			cmp al, 0
			jnz w4
	jmp stop
w1:
	mov di, 2140
	mov si, Tie
	w5:
		lodsb
		stosw
		cmp al, 0
		jnz w5
stop:
mov ax, 0x4C00
int 0x21

incP1:
	inc word[P1score]
	ret

incP2:
	inc word[P2score]
	ret

P1up:
	cmp word[P1pos], 640
	jle p1u
	sub word[P1pos], 160
	p1u:
	ret

P1down:
	cmp word[P1pos], 3360
	jge p1d
	add word[P1pos], 160
	p1d:
	ret

P2up:
	cmp word[P2pos], 640
	jle p2u
	sub word[P2pos], 160
	p2u:
	ret

P2down:
	cmp word[P2pos], 3360
	jge p2d
	add word[P2pos], 160
	p2d:
	ret

UpperWall:
	add word[BallMotion], 320
	jmp nextIteration

LowerWall:
	add word[BallMotion], -320
	jmp nextIteration

RightWall:
	add word[BallMotion], -4
	ret

LeftWall:
	add word[BallMotion], 4
	ret

changeGameState:
	not word[GameState]
	ret

clearScreen:
	push ax
	push cx
	push es
	push di
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov cx, 2000
	mov ax, 0x0720
	cld
	rep stosw
	pop di
	pop es
	pop cx
	pop ax
	ret

delay:
	push ax
	push cx
	mov ax, 0x8600
	mov cx, [BallDelay]
	int 0x15
	pop cx
	pop ax
	ret

printScreen:
	call clearScreen
	push ax
	push bx
	push cx
	push dx
	push es
	push di
	push si
	mov ax, 0xB800
	mov es, ax
	mov di, 238
	sub di, [FieldWidth]
	mov ax, 242
	add ax, [FieldWidth]
	TopBottomWalls:
		mov word[es:di], 0x0ECD
		add di, 3520
		mov word[es:di], 0x0ECD
		sub di, 3520
		add di, 2
		cmp di, ax
		jnz TopBottomWalls
	mov word[es:80],0x0EBA
	mov word[es:240],0x0ECA
	mov di, 398
	sub di, [FieldWidth]
	mov ax, [FieldWidth]
	shl ax, 1
	add ax, 2
	LeftRightWalls:
		mov word[es:di], 0x0020
		add di, ax
		mov word[es:di], 0x0020
		sub di, ax
		add di, 160
		cmp di, 3600
		jl LeftRightWalls
	mov di, [BallPos]
	mov ax, [Ball]
	mov word[es:di], ax
	mov di, 646
	mov ax, 0x0720
	mov di, [P1pos]
	mov word[es:di], 0x0CDB
	mov word[es:di+160], 0x0CDB
	mov word[es:di-160], 0x0CDB
	mov di, [P2pos]
	mov word[es:di], 0x02DB
	mov word[es:di+160], 0x02DB
	mov word[es:di-160], 0x02DB
	mov di, 3852
	mov si, crText
	cld
	push ax
	mov ax, 0x0F00
	pr1:
		lodsb
		stosw
		cmp al, 0
		jnz pr1
	pop ax
	mov di, 0
	mov si, P1
	pr2:
		lodsb
		stosw
		cmp al, 0
		jnz pr2
	mov si, P2
	pr3:
		lodsb
		cmp al, 0
		jnz pr3
	sub si, P2
	shl si, 1
	mov di, 158
	sub di, si
	mov si, P2
	pr4:
		lodsb
		stosw
		cmp al, 0
		jnz pr4
	mov ax, [P1score]
	mov bx, 10
	mov di, 78
	pr5:
		mov dx, 0
		div bx
		add dx, 0x0030
		mov dh, 0x07
		mov word[es:di], dx
		sub di, 2
		cmp ax, 0
		jnz pr5
	mov ax, [P2score]
	mov di, 88
	pr6:
		mov dx, 0
		div bx
		add dx, 0x0030
		mov dh, 0x07
		mov word[es:di], dx
		sub di, 2
		cmp ax, 0
		jnz pr6
	pop si
	pop di
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	ret
inputString:
	push bp
	mov bp, sp
	push ax
	push bx
	push es
	push di
	push si
	mov ax, 0xB800
	mov es, ax
	mov si, [bp+4]
	mov di, [bp+6]
	mov bx, 0
	input:
		mov ax, 0
		int 0x16
		cmp ax, 0x1C0D
		jz endInput
		cmp ax, 0x0E08
		jnz si1
			cmp bx, 0
			jz si2
			dec bx
			sub di, 2
			mov byte[si+bx], 0x20
			mov word[es:di], 0x0720
			jmp si2
		si1:
		mov byte[si+bx], al
		mov ah, 0x07
		mov word[es:di], ax
		add di, 2
		inc bx
		si2:
		cmp bx, 15
		jnz input
	endInput:
	mov byte[si+bx], 0
	pop si
	pop di
	pop es
	pop bx
	pop ax
	pop bp
	ret 2

GameState: dw 0
BallPos: dw 0
NextPos: dw 0
BallMotion: dw 0
P1pos: dw 06
P2pos: dw 0
P1score: dw 0
P2score: dw 0
WinText: db 'won the game', 0
Tie: db 'The match was a tie', 0
crText: db '        Made with ', 3 ,' by Sajjad and Usman (23F-0620 , 23F-0618)', 0
P1: db '               ', 0
P2: db '               ', 0
PT1: db 'Player 1 Enter your name:', 0
PT2: db 'Player 2 Enter your name:', 0

BallDelay: dw 2
FieldWidth: dw 38
WidthProtection: dw 1
Ball: dw 0x0209
WinningScore: dw 3  ; Sets the winning score to 3