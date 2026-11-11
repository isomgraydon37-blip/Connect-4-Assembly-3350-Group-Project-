# Main Setup For Gomoku
# Team Members: Jonathan Dawson, Benjamin Bruns, Graydon Isom, Caleb Lewis
# Step 1: Make the Background and the Grid
# Step 2: Have Player Be Player 1. Place a Piece in the 
# Step 3: Use Move_Loop and li and move to continue moving and implementing

# Notes: Use t For Temporary, a For Into-Functions, v for outputted or
 .data
 BOARD_START: .word 0x10040000 # start in top left corner
 BOARD_COLOR: .word 0x00E8D3A8 # Dark brown board color
 LINE_COLOR: .word 0x004A3B2A # light tan
 imageBuffer: .space 0x80000 # allocate space for 512 x 256 x 4 (each pixel is stored with a word)
 
 # Grid
 GRID_X: .word 50 # Start X
 GRID_Y: .word 50 # Start Y
 GRID_ROWS: .word 15 # Number Rows. Note: Space Lines 8 Pixels Between
 GRID_COLUMNS: .word 15 # Number Columns. Note: Each Pixel is 8 In Between, Space Lines 8 Pixels Between
  
 # Pieces
 PIECE_COLOR_P1: .word 0x00FFA500 # Orange Piece For Player 1
 PIECE_COLOR_P2: .word 0x00000080 # Navy Blue Piece For Player 2
  
 # Array
 .align 2 # Used Since Last Element Was Word
 GOMOKU_GRID: .word 0:225 # 15*15 Array is 225
  
 # Variables
 current_player: .word 1
 player_col_start: .word 7 # Middle
 player_row_start: .word 7 # Middle
  
 .text
 .globl main
 
 main: 

 # GET THE S VALUES
  lw $s0, current_player
  lw $s1, player_col_start
  lw $s2, player_row_start
 
  li $s3, 0 # Unknown Tile Number
  la $s4, GOMOKU_GRID # The 15 * 15 array. 0 = no piece, 1 = P1, 2 = P2
 
  jal drawBoard
  
  li $a0, 7
  li $a1, 7
  li $a2, 0x00DD550C # Auburn Orange
  jal drawPiece
  li $a0, 7
  li $a1, 8
  li $a2, 0x000C2340 # Auburn Navy
  jal drawPiece
  
  li $v0, 10
  syscall

 

# DRAW BOARD ------------------------------------------------------------ 
# Fill 512x512 Bitmap display with brown
# Unit width x height is 2 x 2
# Start is at 0x10040000 on the heap
# Draw grid lines from (22, 22) to (232, 232) with 14 pixels between each grid line
# DRAW BOARD ------------------------------------------------------------

 drawBoard:
   lw $t4, BOARD_COLOR       # background color
   lw $t7, LINE_COLOR        # grid line color
   li $t1, 0                 # y = 0

   drawRow:
     bge $t1, 256, drawExit

     lw $t0, BOARD_START
     sll $t3, $t1, 10        # y * 1024 bytes per row
     add $t0, $t0, $t3       # row starting address

     # Per-row flags, computed once per row instead of once per pixel
     li $t8, 0               # $t8 = 1 if this row is a horizontal line
     li $t9, 0               # $t9 = 1 if this row is inside the grid's y range
     
     # early exit
     blt $t1, 22, rowFlagsDone # y < 22 outside grid range
     bgt $t1, 232, rowFlagsDone # y > 232 outside grid range
     
     li $t9, 1
     addi $t5, $t1, -22
     rem  $t6, $t5, 15
     seq  $t8, $t6, 0        # 1 if (y-22) % 15 == 0
     
   rowFlagsDone:
     li $t2, 0               # x = 0

     drawCol:
       bge $t2, 256, nextRow
       
       # not a grid line
       move $t3, $t4         # brown
       beq $t9, $zero, paintBoard       # paint brown if outside of range
       blt $t2, 22, paintBoard   # x < 22 --> paint brown
       bgt $t2, 232, paintBoard   # x > 232 --> paint brown
       
       # grid line
       bne $t8, $zero, useLine     # horizontal line row -> line color
       addi $t5, $t2, -22
       rem  $t6, $t5, 15
       bne $t6, $zero, paintBoard      # if x - 22 % 15 == 0 then grid line
     useLine:
       move $t3, $t7         # line color

     paintBoard:
       sw  $t3, 0($t0)

       addi $t2, $t2, 1
       addi $t0, $t0, 4
       j drawCol

     nextRow:
       addi $t1, $t1, 1
       j drawRow

   drawExit:
     jr $ra

# DRAW PIECE ----------------------------------------------------------------------------
# Draws a rectangular piece at ($a0, $a1) == (x, y) of size 10x10
# a2 holds the piece color
# DRAW PIECE ----------------------------------------------------------------------------
 
 drawPiece:
   li   $t7, 15 # grid spacing
   mul  $t0, $a0, $t7
   addi $t0, $t0, 22 # ux = 15*col + 22
   mul  $t1, $a1, $t7
   addi $t1, $t1, 22 # uy = 15*row + 22
   
   subi $t0, $t0, 5
   subi $t1, $t1, 5
   
   lw $t2, BOARD_START
   sll $t3, $t1, 10 # uy * 1024 (256 * 4 bytes per row)
   sll $t4, $t0, 2 # ux * 4 (4 bytes per pixel)
   addu $t2, $t2, $t3 # Board start + y pixel
   addu $t2, $t2, $t4 # finds top-left corner of piece
   
   li $t5, 0 # y = 0
   
   pieceRow:
     bgt $t5, 10, endDrawPiece
     move $t6, $t2 
     li $t7, 0
     
     pieceCol:
       bgt $t7, 10, endPieceCol
       sw $a2, 0($t6)
       addi $t6, $t6, 4
       addi $t7, $t7, 1 # Loop invariant
       j pieceCol
     
     endPieceCol:
       addi $t2, $t2, 1024 # Next row from left edge
       addi $t5, $t5, 1 # Add to row count
       j pieceRow
   
   endDrawPiece:
     jr $ra
  
# Board Utility: Update Board Pieces.
 # Value = 0: EMPTY
 # Value = 1: P1 (orange)
 # Value = 2: P2 (navy)
 update_board:
  li $a0, 0 # Start Column
  li $a1, 0 # End Column
  
  check_row_loop:
   # start of loop
   lw $t0, GRID_ROWS
   lw $t1, GRID_COLUMNS
   
   lw $t2, PIECE_COLOR_P1
   lw $t3, PIECE_COLOR_P2
   
   bge $a0, $t0, next_row
   addi $a0, $a0, 1
   
   jal get_tile_number #a0 is x, a1 is y, s3 = tile number
   
   # switch to the function: paint or skip?
   li $t4, 0
   li $t5, 1
   li $t6, 2
   beq $s3, $t4, skip_update
   beq $s3, $t5, update_color_p1
   beq $s3, $t6, update_color_p2
   
   j skip_update #Fall Back
   
   # update board functions
   
   update_color_p1: #orange
    move $t7, $t2
    j paint
    
   update_color_p2: #navy
    move $t7, $t3
    j paint
    
   skip_update: #color it back to the grid or skip
    j check_row_loop
   
   paint:
    # Get s3, The Tile Number
    # Or Get t0 and t1, Confident Those are X's and Y's
    sw  $t4, 0($s3) # Then Paint. $t7 is Now Famous.
   
    j check_row_loop
    
   next_row:
    bge $a0, $t1, end_update_board
    addi $a0, $a1, 1
    j check_row_loop
 
 end_update_board:
  j game_loop 
 
 get_tile_number: # Gets the Tile's Color Number From $a0 column # and $a1 row #
  # Calculation For Array: Base + (row * Col #) * 4 (4 Bytes Allocated Per Word)
  # Start The Piece On the Top Right
  move $t0, $s1 #base $t0= number or rows
  lw $t1, GRID_COLUMNS #t1 = number of columns
  mult $t1, $s2 #t1 *= row #
  addu $t2, $t0, $t1 #t2 = total sum   #Graydon chnaged from addi to addu 
  
  sll $t2, $t2, 2 #Shift 2 literals
  lw $s3, 0($s2)
  jr $ra #changed from jal to jr

 
 # Draw The Piece After Updating Board
 update_piece:
  sw $s4, 0($s4)
  
 
 
 
 
 
 
 
 
 
 
 # Game Loop + Insert Piece Functions. A.K.A Code => Bug => Regret => Despair => Wake Up => Repeat
 # Game Loop
 # 1) Checks For Keyboard 
 # 2) 
 game_loop:
  lw $t0, current_player
  lw $t1, player_col_start
  lw $t2, player_row_start
  
 wait_for_keyboard: # Loop Constatnly Checking For Inputs Of WASD Keys. When Insert (Space), Inset Piece At That Location
  
  lui $t0, 0xFFFF # Base MMIO Address
  lw $t1, 0($t0) # Loads Control
  andi $t1, $t1, 1 # Checks If Bit Is Ready
  beq $t1, $zero, wait_for_keyboard
 
  lw $t2, 4($t0) # Loads Keyboard Address
 
 check_up: #Check Up Key
  li $t3, 'w'
  bne $t2, $t3, check_down
  ble $s2, $zero, jump_to_game_loop
  addi $s2, $s2, -1 # row -= 1
  j update_grid
 
 check_down:
  li $t3, 's'
  bne $t2, $t3, check_left
  lw $t4, GRID_COLUMNS
  bge $s2, $t4, jump_to_game_loop
  addi $s2, $s2, 1 # row += 1
  j update_grid
 
 check_left:
  li $t3, 'a'
  bne $t2, $t3, check_right
  ble $s2, $zero, jump_to_game_loop
  addi $s1, $s1, -1 # column -= 1
  j update_grid
  
 check_right:
  li $t3, 'd'
  bne $t2, $t3, check_space
  lw $t4, GRID_ROWS
  bge $s2, $t4, jump_to_game_loop
  addi $s1, $s1, 1 # column += 1
  j update_grid
  
 check_space: # Move to Insert Piece
  li $t3, ' '
  bne $t2, $t3, jump_to_game_loop
  j insert_piece #s1 is col, s2 is row 
 
 insert_piece: # Inserts Piece
  # Calculation For Array: Base + (row * Col #) * 4 (4 Bytes Allocated Per Word)
  # Start The Piece On the Top Right
  li $t0, 0 #base
  lw $t1, GRID_ROW
  mul $t2, $s2, $t1 #changed from mult to mul 
  mul $t2, $t2, 4 #chnaged from mult to mul
 
 check_win: # Check For Win. Check Vertical, Horizontal, Right-Left Diagonals, and Left-Right Diagonals
 
 switch_players: # Switch Players After Check Win, Then End Turn
 li $t0, 1 
 bne $s0, $t0 #If Player is not 1, Switch To P2, Else Switch To P1
 
 set_to_p1:
 #li $s0, 1
 #la $t0, current_player
 #sw $s0, 0($t0) # Tutorial on switching to current_player to 0($t0)
 
 li $s0, 1
 j jump_to_game_loop
 
 set_to_p2:
 li $s0, 2
 j jump_to_game_loop
 
 jump_to_game_loop:
 lw $s1, player_row_start
 lw $s2, player_col_start
 jal update_grid
 j game_loop
 
 # Win Functions
 simulate_win: # When Won, Will Show Text You Won In Bottom, and Cannot Place More Pieces.
 
 # Restart Function
 func_restart_game: 
  li $t0, 0
  move $t1, $s4
  clear_loop:
  bge $t0, 225, clear_done
  sw $zero, 0($t1)
  addi $t0, $t0, 1
  addi $t1, $t1, 4
  j clear_loop
  clear_done:
  j main
 
 
 end_program: 
  li $v0, 10
  syscall
  
 # Idea: Use "On Claude" AI. Sends quotes
 
 
 
 # Idea: The Rubric Is the Instructions or Add A Tutorial
 
 # Idea: You Can Flip the Board Sideways Multiple Times or Expand It In Different Directions
 
 # Idea: Dark Mode
 
 # Idea: Human Counter Where There are 8 Billion Humans But When We Run Out of Pieces "The Humans Escaped" and There are 0 Humans Even Though There are Still 8 Billion Humans on Earth. Twist: If There were 9 billion humans there would still be 8 billion humans.
 
 # Idea: "Harder" Mode. Love of the game. "Hardest Mode." One More Time. Well, Maybe Not, They're Researching that in..."Hard-vard".
 
 # More Ideas To Be Added By Graydom Isom
 
 
