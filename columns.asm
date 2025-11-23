################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Jaehyuk Ryu 1009558079
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# The address of color constants in hexcode
ADDR_COLORS:
    .word 0xFFA500   # orange
    .word 0xFF00FF   # magenta
    .word 0xFFFF00   # yellow
    .word 0x0000FF   # blue
    .word 0x00FF00   # green
    .word 0xFF0000   # red

ADDR_STAGE:
    .word 0xAAAAAA   # gray (boundary)
    
##############################################################################
# Mutable Data
##############################################################################
ADDR_CAPSULE_COLORS:
    .word 0          # bot gem color
    .word 0          # mid gem color
    .word 0          # top gem color
    
ADDR_CAPSULE_X:
    .word 0          # x coord of capsule
    
ADDR_CAPSULE_Y:
    .word 0          # y coord of capsule (bottom)

ADDR_MARK:
    .word 0:256

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    lw $s0, ADDR_DSPL # load the display address
    
    jal draw_stage      # draw the gray stage
    jal new_capsule
    jal draw_capsule
       
    
    # # --- (3,10) ---
    # la $t0, ADDR_COLORS
    # lw $t1, 12($t0)
    # li $a0, 3
    # li $a1, 10
    # move $a2, $t1
    # jal add_to_board

    # # --- (4,10) ---
    # la $t0, ADDR_COLORS
    # lw $t1, 12($t0)
    # li $a0, 4
    # li $a1, 10
    # move $a2, $t1
    # jal add_to_board

    # # --- (5,10) ---
    # la $t0, ADDR_COLORS
    # lw $t1, 12($t0)
    # li $a0, 5
    # li $a1, 10
    # move $a2, $t1
    # jal add_to_board
    
    # li $a0, 3
    # li $a1, 10
    # li $a2, 1
    # li $a3, 0
    # jal check_direction
    
    j game_loop
    
end_program:
    li $v0, 10              # terminate the program gracefully
    syscall

game_loop:
    # 1a. Check if key has been pressed
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard -> input detector
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop

# 1b. Check which key has been pressed
keyboard_input:
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key a was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key w was pressed
    
    j game_loop

# INPUT MAPPERS
respond_to_Q:
    j end_program
    

# move 1 unit left
respond_to_A:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
   
    # collision detection
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    addi $a0, $t0, -1
    addi $a1, $t1, 0               # check if left for bottom is empty
    jal get_from_board
    # branch CANNOT-MOVE:
    bne $v0, $zero, safe_return 
    
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    addi $a0, $t0, -1
    addi $a1, $t1, -1               # check if left for mid is empty
    jal get_from_board
    # branch CANNOT-MOVE:
    bne $zero, $zero, safe_return
    
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    addi $a0, $t0, -1
    addi $a1, $t1, -2               # check if left for top is empty
    jal get_from_board
    # branch CANNOT-MOVE:
    bne $zero, $zero, safe_return
    
    # branch CAN-MOVE:
    # first, erase the current gem
    # 1) bottom gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    move $a1, $t1                  # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # 2) middle gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    addi $a1, $t1, -1              # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # 3) bottom gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    addi $a1, $t1, -2              # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # next, update the gem location (y does not change)
    la   $t0, ADDR_CAPSULE_X    # load x address
    lw   $t1, 0($t0)            # x coord
    addi $t1, $t1, -1           # x = x - 1
    sw   $t1, 0($t0)            # update new x value (x = x - 1)
    
    # draw capsule once again
    # jal check_collision
    jal draw_capsule
    j safe_return
 
 
# move 1 unit right
respond_to_D:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    # collision detection
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    addi $a0, $t0, 1
    addi $a1, $t1, 0               # check if right for bottom is empty
    jal get_from_board
    # branch CANNOT-MOVE:
    bne $v0, $zero, safe_return 
    
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    addi $a0, $t0, 1
    addi $a1, $t1, -1               # check if right for mid is empty
    jal get_from_board
    # branch CANNOT-MOVE:
    bne $zero, $zero, safe_return
    
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    addi $a0, $t0, 1
    addi $a1, $t1, -2               # check if right for top is empty
    jal get_from_board
    # branch CANNOT-MOVE:
    bne $zero, $zero, safe_return
    
    # branch CAN-MOVE:
    # first, erase the current gem
    # 1) bottom gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    move $a1, $t1                  # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # 2) middle gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    addi $a1, $t1, -1              # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # 3) top gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    addi $a1, $t1, -2              # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # next, update the gem location (y does not change)
    la   $t0, ADDR_CAPSULE_X    # load x address
    lw   $t1, 0($t0)            # x coord
    addi $t1, $t1, 1            # x = x + 1
    sw   $t1, 0($t0)            # update new x value (x = x + 1)
    
    # draw capsule once again
    jal draw_capsule
    j safe_return

    
# move 1 unit down
respond_to_S:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # collision detection
    
    # branch CANNOT-MOVE:
    bne $zero, $zero, safe_return
    
    
    # branch CAN-MOVE:
    # first, erase the current gem
    # 1) bottom gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    move $a1, $t1                  # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # 2) middle gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    addi $a1, $t1, -1              # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # 3) bottom gem
    lw   $t0, ADDR_CAPSULE_X       # x column
    lw   $t1, ADDR_CAPSULE_Y       # bottom y
    move $a0, $t0                  # x
    addi $a1, $t1, -2              # y
    addi $a2, $zero, 0             # color = black as we erase
    jal add_to_board
    
    # next, update the gem location (y does not change)
    la   $t0, ADDR_CAPSULE_Y    # load y address
    lw   $t1, 0($t0)            # y coord
    addi $t1, $t1, 1            # y = y + 1
    sw   $t1, 0($t0)            # update new y value (y = y + 1)
    
    # draw capsule once again
    jal draw_capsule

check_collision:
    # if capsule meets bottom, make a new capsule
    lw  $a0, ADDR_CAPSULE_X
    lw  $a1, ADDR_CAPSULE_Y
    addi $a1, $a1, 1
    jal get_from_board
    
    beq $v0, $zero, safe_return # branch: bottom is black == empty, no collision
    j handle_collision # branch: collision happened

handle_collision:
    # check for matches
    jal cascade
    
    # check for possible game end
    # check if (1, 1) ~ (12, 1) is occupied.
    # additionally check if (6, 2), (6,3) is occupied. if any, game end.
    li $s7, 1
    check_end_loop:
        li $t0, 11
        beq $s7, $t0, create_next_capsule # passing (reaching the end of loop) means game continues
        
        move $a0, $s7
        li $a1, 2 
        jal get_from_board
        bne $v0, $zero, end_program # if the cell is not zero, it reached the top
    
        addi $s7, $s7, 1
        j check_end_loop

create_next_capsule:
    # create new capsule
    jal new_capsule
    jal draw_capsule
    j safe_return
    
cascade:
    # find match -> erase -> gravity -> find match
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

cascade_loop:
    li $v0, 32
    li $a0, 200
    syscall # make sleep for every gravity fall
    
    jal find_match              # scan board for match, fill up MARKED array
    beq $v0, $zero, cascade_end # if no match (return = 0), end iteration
    
    jal clear_marked            # erase marked array
    jal apply_gravity           # apply gravity
    
    j cascade_loop
cascade_end:
    j safe_return
    

# v0 = was there a match
find_match:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    
    li $t0, 1
    sw   $t0, 4($sp) # y index store
    sw   $t0, 8($sp) # x index store
    
    li $v1, 0 # return value place holder. add up all the counts, and move it into v0 to return
    li $t9, 15 # bound for iterations
    li $t0, 1 # y iterator
    find_match_y_loop:
        lw $t0, 4($sp)
        li $t9, 15 # bound for iterations
        beq $t0, $t9, find_match_end_y_loop
        li $t1, 1 # x iterator
        sw $t1, 8($sp)
        find_match_x_loop:
            lw $t1, 8($sp)
            lw $t0, 4($sp)
            li $t9, 12 # bound for iterations
            beq $t1, $t9, find_match_end_x_loop
            move $s6, $t1 # save x value
            move $s7, $t0 # save y value
            
            move $a0, $s6 # copy x into a0
            move $a1, $s7 # copy y into a1 (prepare for the get_from_board args)
            jal get_from_board # v0 = color @ [a0][a1]
            
            lw $t8, ADDR_STAGE # hex code for stage
            beq $v0, $zero, continue_x_loop # if the space is blank, OR
            beq $v0, $t8, continue_x_loop # if the space is stage filler, continue w/o checking
            
            # now here, the x, y needs to be checked for each dx dy combo
            # 1) dx = 1, dy = 0 (horizontal)
            move $a0, $s6 # x
            move $a1, $s7 # y
            li $a2, 1     # dx
            li $a3, 0     # dy
            jal check_direction # marking is done inside this
            add $v1, $v1, $v0
            
            # 2) dx = 1, dy = 1 (diagonal up)
            move $a0, $s6 # x
            move $a1, $s7 # y
            li $a2, 1     # dx
            li $a3, 1     # dy
            jal check_direction # marking is done inside this
            add $v1, $v1, $v0
            
            # 3) dx = 0, dy = 1 (vertical)
            move $a0, $s6 # x
            move $a1, $s7 # y
            li $a2, 0     # dx
            li $a3, 1     # dy
            jal check_direction # marking is done inside this
            add $v1, $v1, $v0
            
            # 4) dx = 1, dy = -1 (diagonal down)
            move $a0, $s6 # x
            move $a1, $s7 # y
            li $a2, 1     # dx
            li $a3, -1     # dy
            jal check_direction # marking is done inside this
            add $v1, $v1, $v0
            
            continue_x_loop:
                lw $t1, 8($sp)
                addi $t1, $t1, 1
                sw $t1, 8($sp)
                j find_match_x_loop
        find_match_end_x_loop:
            lw $t0, 4($sp)
            addi $t0, $t0, 1
            sw $t0, 4($sp)
            j find_match_y_loop
    find_match_end_y_loop:
        move $v0, $v1
        lw   $ra, 0($sp)
        addi $sp, $sp, 12
        jr $ra
            

clear_marked:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    la $t8, ADDR_MARK
    li $t9, 1024 # bound (0~256 = 256 * 4)
    li $t0, 0  # i & offset address
    clear_marked_loop:
        beq $t0, $t9, clear_done
        add $t1, $t8, $t0 # mark address of interest
        lw $t2, 0($t1)
        beq $t2, $zero, clear_mark_continue
        
        # clear off single mark
        sw $zero, 0($t1)
        # display address of interest
        add $t3, $s0, $t0 
        # paint black
        sw $zero, 0($t3) 
    clear_mark_continue:
        addi $t0, $t0, 4 # i+=4
        j clear_marked_loop
    clear_done:
        lw $ra 0($sp)
        addi $sp, $sp, 4
        jr $ra

    
# $a0 = x
# $a1 = y
# $a2 = dx ( 0, 1, 1, 1)
# $a3 = dy ( 1, 0, 1,-1)
check_direction:
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    li   $t5, 1   # consecutive len = 1 (counter initialized)
    sw   $t5, 4($sp)
    
    # copy args into s registers 
    # (will use over the function, 
    # but no other use outside so did not save to stack)
    move $s1, $a0 #  x
    move $s2, $a1 #  y
    move $s3, $a2 # dx
    move $s4, $a3 # dy
    
    # get start color
    move $a0, $s1 # x
    move $a1, $s2 # y
    jal get_from_board
    move $s5, $v0 # start color
    
    # add $t1, $zero, $s2 # set up ny variable
    
    cd_loop:
        lw $t5, 4($sp)
        # advance to next cell: nx = x + dx, ny = y + dy
        add $s1, $s1, $s3
        add $s2, $s2, $s4
        
        # fetch board color at the next cell
        move $a0, $s1
        move $a1, $s2
        jal get_from_board
        move $t6, $v0 # color at next cell
        
        # branch: if same color, increment len and continue
        beq $s5, $t6, cd_inc_len
        j cd_end_loop
        
    cd_inc_len:
        lw $t5, 4($sp)
        addi $t5, $t5, 1
        sw $t5, 4($sp)
        j cd_loop
        
    cd_end_loop_return_zero:
        li $v0, 0
        lw   $ra, 0($sp)
        addi $sp, $sp, 8
        jr $ra
    
    cd_end_loop:
        lw $t5, 4($sp)
        move $v0, $t5
        li $t0, 3
        blt $v0, $t0, cd_end_loop_return_zero # if count is less than 3, return 
        
        # from x, y, iterate v0 times to subtracting dx and dy. add it to mark
        li $t0, 1 # i = 1
        marking_loop:
            bgt $t0, $v0, cd_exit_loop # if i = count, return (do not operate on i = count)
            # x = x - dx * i
            mul $t1, $s3, $t0  # dx * i
            mul $t1, $t1, -1   # should go other direction
            add $t1, $t1, $s1  # + x
            sll $t1, $t1, 2    # * 4 to get the x offset in bits
            
            # y = y + dy * i
            mul $t2, $s4, $t0 # dy * i
            mul $t2, $t2, -1  # should go other direction
            add $t2, $t2, $s2  # + y
            sll $t2, $t2, 6    # * 64 to get the y offset in bits
            
            add $t3, $t1, $t2  # the calculated offset of address
            
            la $t4, ADDR_MARK
            add $t4, $t4, $t3  # mark[nx][ny] address
            li $t5, 1
            sw $t5, 0($t4)     # mark[nx][ny] = 1
            
            addi $t0, $t0, 1 # increment i
            j marking_loop
        
        cd_exit_loop:
            lw   $ra, 0($sp)
            addi $sp, $sp, 8
            jr $ra


apply_gravity:
    li $v0, 32
    li $a0, 200
    syscall # make sleep for every gravity fall
    
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    li $t0, 12  # set up x loop
    sw $t0, 4($sp) # save x in stack, as it will get overridden.
gravity_x_loop:
    lw $t0, 4($sp)
    bltz $t0, gravity_end
    
    li $t1, 14  # y = 14 to 0
    sw $t1, 8($sp)
gravity_y_loop:
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    bltz $t1, gravity_x_continue
    
    move $a0, $t0 # x
    move $a1, $t1 # y
    jal get_from_board
    move $t2, $v0 # cell color code
    
    # branch: if not blank, move on.
    bne $t2, $zero, gravity_y_continue 
    # branch: if blank, search for colored blocks upward
    
    lw $t1, 8($sp)
    move $t3, $t1 # make a variable for ty (top y)
    sw $t3, 12($sp)
gravity_search_up:
    lw $t3, 12($sp)
    addi $t3, $t3, -1 # ty -- (decrement first)
    sw $t3, 12($sp)
    
    bltz $t3, gravity_y_continue
    
    lw $t0, 4($sp)
    move $a0, $t0 # x, loaded by prev line
    move $a1, $t3 # y, loaded by 3 lines above
    jal get_from_board
    
    move $t4, $v0 # value of board color above
    # branch: if the value above is 0, go even more above
    beq $t4, $zero, gravity_search_up
    
    lw $t6, ADDR_STAGE # hex code value
    beq $t4, $t6, gravity_x_continue # if it meets a stage, move the x as it reached the top
    # branch: else, found a block that is hovering
    # destination = t4
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    move $a0, $t0
    move $a1, $t1
    move $a2, $t4
    jal add_to_board
    
    # move down to:
    lw $t0, 4($sp)
    lw $t3, 12($sp)
    move $a0, $t0
    move $a1, $t3
    move $a2, $zero
    jal add_to_board
    
gravity_y_continue:
    lw $t1, 8($sp)
    addi $t1, $t1, -1
    sw $t1, 8($sp)
    j gravity_y_loop
    
gravity_x_continue:
    lw $t0, 4($sp)
    addi $t0, $t0, -1
    sw $t0, 4($sp)
    j gravity_x_loop

gravity_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra


# shift the orientation (top -> mid, mid -> bot, bot -> top)
respond_to_W:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    la $t0, ADDR_CAPSULE_COLORS # capsule address
    lw $t1, 0($t0)              # bot gem color
    lw $t2, 4($t0)              # mid gem color
    lw $t3, 8($t0)              # top gem color
    
    sw $t3, 4($t0)              # store top gem color into mid
    sw $t2, 0($t0)              # store mid gem color into bot
    sw $t1, 8($t0)              # store bot gem color into top
    
    jal draw_capsule
    j safe_return


safe_return:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    

# no args needed. returns the hexcode in $v0
return_random_color:
    li  $v0, 42          # do random call
    li  $a0, 0           # set lower bound to 0
    li  $a1, 6           # set upper bound to 6 (exclusive)
    syscall              # execute random call in (0, 1, 2, 3, 4, 5), save in $a0
    la  $t1, ADDR_COLORS # save address of COLORS array in $t1
    sll $t0, $a0, 2      # t0 = random index * 4 (actual offset in address)
    add $t1, $t1, $t0    # t1 += t0 (t1 = now index of random color)
    lw  $v0, 0($t1)      # write (over) t1, 
    jr  $ra              # return to original line
    
    
new_capsule:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    li $a0, 6
    li $a1, 2
    jal get_from_board
    bne $v0, $zero, end_program
    li $a0, 6
    li $a1, 3
    jal get_from_board
    bne $v0, $zero, end_program
    
    addi $t4, $s0, 116    # coordinate for next top
    
    # upcoming color hex values (should be stored in ADDR_CAPSULE_COLORS)
    lw   $t7,   0($t4)    # color in next top 
    lw   $t8,  64($t4)    # color in next mid 
    lw   $t9, 128($t4)    # color in next bot 
    
    la   $t0, ADDR_CAPSULE_COLORS
    sw   $t7, 8($t0)      # save at current top
    sw   $t8, 4($t0)      # save at current mid
    sw   $t9, 0($t0)      # save at current bot
    
    jal  return_random_color    # random color for bot
    addi $t4, $s0, 116          # coordinate for next top
    sw   $v0, 128($t4)          # save at next bot
    
    jal  return_random_color
    addi $t4, $s0, 116          # coordinate for next top
    sw   $v0, 64($t4)           # save at next mid
    
    jal  return_random_color
    addi $t4, $s0, 116          # coordinate for next top
    sw   $v0, 0($t4)            # save at next top
    
    la   $t0, ADDR_CAPSULE_X    # load x address
    li $t1, 6          # put in 6 (starting x coord)
    sw   $t1, 0($t0)
    
    la   $t2, ADDR_CAPSULE_Y    # load y address
    li $t3, 3          # put in 3 (starting y coord)
    sw   $t3, 0($t2)
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    
    lw   $t0, ADDR_CAPSULE_COLORS   # load first color in capsule (bot)
    beq  $t0, $zero, new_capsule    # if black, needs another round of this
    
    jr   $ra
  
  
# draw current capsule
draw_capsule:
    addi $sp, $sp, -16
    sw   $ra,  0($sp)
    sw   $s1,  4($sp)
    sw   $s2,  8($sp)
    sw   $s3, 12($sp)

    lw   $s1, ADDR_CAPSULE_X       # x column
    lw   $s2, ADDR_CAPSULE_Y       # bottom y
    la   $s3, ADDR_CAPSULE_COLORS  # colors

    # 1) bottom gem
    move $a0, $s1             # x
    move $a1, $s2             # y
    lw   $a2, 0($s3)          # bottom gem color
    jal add_to_board

    # 2) middle gem (y-1)
    move $a0, $s1             # x
    addi $a1, $s2, -1         # y - 1
    lw   $a2, 4($s3)          # middle gem color
    jal add_to_board

    # 3) top gem (y-2)
    move $a0, $s1             # x
    addi $a1, $s2, -2         # y - 2
    lw   $a2, 8($s3)          # top gem color
    jal add_to_board
    
    lw   $ra,  0($sp)
    lw   $s1,  4($sp)
    lw   $s2,  8($sp)
    lw   $s3, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

    
# $a0 = x <coord>
# $a1 = y <coord>
# $a2 = value to inject, is automatically painted.
add_to_board:
    # address = board base + 4x + 64y
    sll  $t0, $a0, 2      # t0 = 4x
    sll  $t1, $a1, 6      # t1 = 64y
    add  $t2, $t0, $t1    # t2 = offset = 4x + 64y
    
    add  $t3, $s0, $t2    # final display DISPLAY = display_base + offset
    sw   $a2, 0($t3)      # paint display memory-mapped IO
    
    jr   $ra


# $a0 = x <coord>
# $a1 = y <coord>
# $v0 = value returned from the board
get_from_board:
    # address = board base + 4x + 64y
    sll  $t0, $a0, 2      # t0 = 4x
    sll  $t1, $a1, 6      # t1 = 64y
    add  $t2, $t0, $t1    # t2 = offset = 4x + 64y

    add  $t3, $s0, $t2    # t3 = board address of interest
    lw   $v0, 0($t3)
    
    jr $ra
    
    
# draw the outer stage in gray
# no arguments needed.
# has inner function calls, stored $ra in stack and returned.
draw_stage:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $a0, 0
    la $a1, 0
    la $a2, 16
    la $a3, 4
    jal draw_line # draw top stage : 0,0 to 15,0 
    
    la $a0, 0
    la $a1, 0
    la $a2, 16
    la $a3, 64
    jal draw_line # draw left stage : 0,0 to 0,15 
    
    la $a0, 11
    la $a1, 0
    la $a2, 16
    la $a3, 64
    jal draw_line # draw right stage : 8,0 to 8,15 
    
    la $a0, 0
    la $a1, 15
    la $a2, 12
    la $a3, 4
    jal draw_line # draw bottom stage : 0,15 to 8,15 
    
    la $a0, 15
    la $a1, 0
    la $a2, 4
    la $a3, 64
    jal draw_line # draw box for next block
    
    la $a0, 12
    la $a1, 4
    la $a2, 4
    la $a3, 4
    jal draw_line # draw box for next block
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra 

    
# $a0 = x <coord> for the starting point of line (+4 = +1 right)
# $a1 = y <coord> for the starting point of line (+64 = +1 down)
# $a2 = length of the line in <coord>
# $a3 = offset (4 = horizontal, 64 = vertical)
# $s0 = the address of the top left corner
# $t1 = gray hex code value
draw_line:
    sll $a0, $a0, 2         # multiply the x <coord> in $a0 by 4 to get the horizontal offset
    sll $a1, $a1, 6         # multiply the y <coord> in $a1 by 64 to get the vertical offset
    add $t0, $a0, $a1       # offset added
    add $t0, $s0, $t0       # add offset to the display address
    
    lw $t1, ADDR_STAGE      # load hexcode of gray
    
    # Make a loop to draw a line.
    mul $a2, $a2, $a3      # get the actual offset needed to get to stop cond
    add $t3, $t0, $a2       # offset from t0 by a2 to find the stop condition
loop_start:
    beq $t3, $t0, loop_end  # check if $t0 has reached the final location of the line
    sw $t1, 0($t0)          # paint the current pixel to something
    add $t0, $t0, $a3       # move $t0 to the next pixel in the row.
    j loop_start            # jump to the start of the loop
loop_end:
    jr $ra                  # return to the calling program (ra = return address)
    