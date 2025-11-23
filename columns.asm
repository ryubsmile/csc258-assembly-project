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
    
    jal draw_stage
    jal new_capsule
    jal draw_capsule

    # Play game
    j game_loop
    

game_loop:
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard -> input detector
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
# time_tick:
#     li $v0, 32
#     li $a0, 1000
#     syscall
#     jal move_down
    j game_loop




# terminate the program gracefully
end_program:
    li $v0, 10              
    syscall


# check which key has been pressd
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
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)

    lw   $s1, ADDR_CAPSULE_X       # x column
    lw   $s2, ADDR_CAPSULE_Y       # y row bottom

    # collision detection

    # check if left for bottom is empty
    addi $a0, $s1, -1
    addi $a1, $s2, 0               
    jal get_from_board
    # BRANCH: cannot move => halt movement
    bne $v0, $zero, end_respond_to_D 
    
    # check if left for mid is empty
    addi $a0, $s1, -1
    addi $a1, $s2, -1               
    jal get_from_board
    # BRANCH: cannot move => halt movement
    bne $zero, $zero, end_respond_to_D
    
    # check if left for top is empty
    addi $a0, $s1, -1
    addi $a1, $s2, -2               
    jal get_from_board
    # BRANCH: cannot move => halt movement
    bne $zero, $zero, end_respond_to_D
    
    # BRANCH: can move => erase current capsule -> update location -> draw new capsule
    # 1) erase the current gem
    # 1-1) bottom gem
    move $a0, $s1        # x
    move $a1, $s2        # y
    la   $a2,   0        # color = black as we erase
    jal add_to_board
    # 1-2) middle gem
    move $a0, $s1        # x
    addi $a1, $s2, -1    # y
    la   $a2,   0        # color = black as we erase
    jal add_to_board
    # 1-3) top gem
    move $a0, $s1        # x
    addi $a1, $s2, -2    # y
    la   $a2,   0        # color = black as we erase
    jal add_to_board
    
    # 2) next, update the gem location (y does not change)
    la   $t0, ADDR_CAPSULE_X    # load x address
    lw   $t1, 0($t0)  # x coord
    addi $t1, $t1, -1  # x = x - 1
    sw   $t1, 0($t0)  # update new x value (x = x - 1)
    
    # 3) draw capsule once again
    jal draw_capsule
end_respond_to_A:
    lw   $ra, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    addi $sp, $sp, 12
    jr   $ra
 
 
# move 1 unit right
respond_to_D:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)

    lw   $s1, ADDR_CAPSULE_X       # x column
    lw   $s2, ADDR_CAPSULE_Y       # y row bottom

    # collision detection

    # check if right for bottom is empty
    addi $a0, $s1, 1
    addi $a1, $s2, 0               
    jal get_from_board
    # BRANCH: cannot move => halt movement
    bne $v0, $zero, end_respond_to_D 
    
    # check if right for mid is empty
    addi $a0, $s1, 1
    addi $a1, $s2, -1               
    jal get_from_board
    # BRANCH: cannot move => halt movement

    bne $zero, $zero, end_respond_to_D
    
    # check if right for top is empty
    addi $a0, $s1, 1
    addi $a1, $s2, -2               
    jal get_from_board
    # BRANCH: cannot move => halt movement
    bne $zero, $zero, end_respond_to_D
    
    # BRANCH: can move => erase current capsule -> update location -> draw new capsule
    # 1) erase the current gem
    # 1-1) bottom gem
    move $a0, $s1        # x
    move $a1, $s2        # y
    la   $a2,   0        # color = black as we erase
    jal add_to_board
    # 1-2) middle gem
    move $a0, $s1        # x
    addi $a1, $s2, -1    # y
    la   $a2,   0        # color = black as we erase
    jal add_to_board
    # 1-3) top gem
    move $a0, $s1        # x
    addi $a1, $s2, -2    # y
    la   $a2,   0        # color = black as we erase
    jal add_to_board
    
    # 2) next, update the gem location (y does not change)
    la   $t0, ADDR_CAPSULE_X    # load x address
    lw   $t1, 0($t0)  # x coord
    addi $t1, $t1, 1  # x = x + 1
    sw   $t1, 0($t0)  # update new x value (x = x + 1)
    
    # 3) draw capsule once again
    jal draw_capsule
end_respond_to_D:
    lw   $ra, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

    
# move 1 unit down
respond_to_S:
move_down:
    addi $sp, $sp, -16
    sw   $ra,  0($sp)
    sw   $s1,  4($sp) # x location
    sw   $s2,  8($sp) # y location
    sw   $s3, 12($sp) # loop variable

    lw   $s1, ADDR_CAPSULE_X
    lw   $s2, ADDR_CAPSULE_Y

    # first, erase the current gem
    # 1) bottom gem
    move $a0, $s1     # x
    move $a1, $s2     # y
    li   $a2,   0     # color = black as we erase
    jal add_to_board
    
    # 2) middle gem
    move $a0, $s1     # x
    addi $a1, $s2, -1 # y = bottom - 1
    li   $a2,   0     # color = black as we erase
    jal add_to_board
    
    # 3) bottom gem
    move $a0, $s1     # x
    addi $a1, $s2, -2 # y = bottom - 2
    li   $a2,   0     # color = black as we erase
    jal add_to_board

    # next, update the gem location (x does not change)
    la   $t0, ADDR_CAPSULE_Y    # load y address
    addi $t1, $s2, 1            # ny = y + 1
    sw   $t1, 0($t0)            # update new y value (y = y + 1)
    
    lw   $s2, ADDR_CAPSULE_Y    # update new y value

    # draw capsule once again
    jal draw_capsule

    # capsule location updated (1 down), now check for collision.

    # get bottom = color(x, y + 1)
    move $a0, $s1
    addi $a1, $s2, 1
    jal get_from_board
    
    # BRANCH: bottom == empty => no collision, end response
    beq $v0, $zero, end_respond_to_S 

    # BRANCH: bottom != empty => reached ground, check for matches and handle
    jal cascade # check for matches and handle them
    
    # check for possible game end
    # check if (1, 1) ~ (10, 1) is occupied.
    li $s3, 1
    check_game_over_loop:
        li $t0, 11
        beq $s3, $t0, check_game_over_end_loop # BRANCH: end of loop => game continues
        
        move $a0, $s3
        li $a1, 2 
        jal get_from_board

        # BRANCH: (nx, ny) != zero => the gem reached the top, game over.
        bne $v0, $zero, end_program 

        # BRANCH: (nx, ny) == zero => the top is empty, continue for other checks
        addi $s3, $s3, 1
        j check_game_over_loop
    check_game_over_end_loop:
        # create new capsule
        jal new_capsule
        jal draw_capsule
end_respond_to_S:
    lw   $ra,  0($sp)
    lw   $s1,  4($sp)
    lw   $s2,  8($sp)
    lw   $s3, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

    
# find match -> erase -> gravity -> find match
cascade:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    cascade_loop:
        li $v0, 32
        li $a0, 200
        syscall # make sleep for every gravity fall
        
        jal find_match              # scan board for match, fill up MARKED array

        # BRANCH: no match => end iteration
        beq $v0, $zero, cascade_end 

        # BRANCH: has match => erase marked, apply gravity.
        #         iterate until there is no match.
        jal clear_marked   # erase marked array
        jal apply_gravity  # apply gravity
        j cascade_loop              
cascade_end:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    

# v0 = was there a match
find_match:
    addi $sp, $sp, -16
    sw   $ra,  0($sp) 
    sw   $s1,  4($sp) # y iterator
    sw   $s2,  8($sp) # x iterator
    sw   $s3, 12($sp) # return value accumulator
    
    li $s3, 0 # return value place holder. add up all the counts, and move it into v0 to return
    
    li $s1, 1 # initialize y iterator to 1. loop y = 1 -> 15
    find_match_y_loop:
        li $t0, 15 # bound for outer loop iterations
        beq $s1, $t0, find_match_end_loop # end of loop, exit function

        li $s2, 1 # x iterator
        find_match_x_loop:
            li $t1, 12 # bound for inner loop iterations
            beq $s2, $t1, find_match_y_continue # end of loop, continue to next outer loop
            
            # check if there is a gem at (x, y)
            move $a0, $s2      # copy x into a0
            move $a1, $s1      # copy y into a1 (prepare for the get_from_board args)
            jal get_from_board # v0 = color(x, y)
            
            beq $v0, $zero, find_match_x_continue # space == blank, OR
            lw $t8, ADDR_STAGE                    # (hex code for stage)
            beq $v0,   $t8, find_match_x_continue # space == stage => no gem, continue w/o checking
            
            # now here, the x, y needs to be checked for each dx dy combo
            # 1) dx = 1, dy = 0 (horizontal)
            move $a0, $s2 # x
            move $a1, $s1 # y
            li $a2, 1     # dx
            li $a3, 0     # dy
            jal check_direction # marking is done inside this
            add $s3, $s3, $v0
            
            # 2) dx = 1, dy = 1 (diagonal up)
            move $a0, $s2 # x
            move $a1, $s1 # y
            li $a2, 1     # dx
            li $a3, 1     # dy
            jal check_direction # marking is done inside this
            add $s3, $s3, $v0
            
            # 3) dx = 0, dy = 1 (vertical)
            move $a0, $s2 # x
            move $a1, $s1 # y
            li $a2, 0     # dx
            li $a3, 1     # dy
            jal check_direction # marking is done inside this
            add $s3, $s3, $v0
            
            # 4) dx = 1, dy = -1 (diagonal down)
            move $a0, $s2 # x
            move $a1, $s1 # y
            li $a2, 1     # dx
            li $a3, -1     # dy
            jal check_direction # marking is done inside this
            add $s3, $s3, $v0
            
        find_match_x_continue:
            addi $s2, $s2, 1
            j find_match_x_loop
    find_match_y_continue:
        addi $s1, $s1, 1
        j find_match_y_loop
find_match_end_loop:
    move $v0, $s3
    lw   $ra,  0($sp)
    lw   $s1,  4($sp)
    lw   $s2,  8($sp)
    lw   $s3, 12($sp)
    addi $sp, $sp, 16
    jr $ra
            

clear_marked:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    la $t0, ADDR_MARK     # mark array base address
    li $t1, 0             # t1 = iterator, i & offset from base address
    li $t2, 1024          # loop bound (0~256 = 256 * 4)
    clear_marked_loop:
        beq $t1, $t2, clear_done # end of loop: exit & end function

        add $t3, $t0, $t1 # address of mark(x, y)
        lw $t4, 0($t3)    # value of mark(x, y)

        # BRANCH: mark(x, y) == 0 => no mark, continue
        beq $t4, $zero, clear_mark_continue 
        
        # BRANCH: mark(x, y) != 0 => has mark, erase mark + erase gem @ (x, y)
        sw $zero, 0($t3)  # erase mark
        add $t5, $s0, $t1 # display address of interest
        sw $zero, 0($t5)  # paint black
    clear_mark_continue:
        addi $t1, $t1, 4  # i+=4
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
    addi $sp, $sp, -28
    sw   $ra,  0($sp)
    sw   $s1,  4($sp) # x
    sw   $s2,  8($sp) # y
    sw   $s3, 12($sp) # dx
    sw   $s4, 16($sp) # dy
    sw   $s5, 20($sp) # start color
    sw   $s6, 24($sp) # consecutive match

    # consecutive match len = 1 (counter initialized)
    li   $s6, 1

    # copy args into s registers 
    move $s1, $a0 #  x
    move $s2, $a1 #  y
    move $s3, $a2 # dx
    move $s4, $a3 # dy

    # get start color, that is, color(x, y)
    move $a0, $s1 # x
    move $a1, $s2 # y
    jal get_from_board
    move $s5, $v0 # start color

    cd_loop:
        # advance to next cell: nx = x + dx, ny = y + dy
        add $s1, $s1, $s3
        add $s2, $s2, $s4

        # fetch board color at the next cell
        move $a0, $s1
        move $a1, $s2
        jal get_from_board
        move $t6, $v0 # color at next cell

        # BRANCH: start color != end color => end loop
        bne $s5, $t6, cd_end_loop

        # BRANCH: start color == end color => increment len and continue loop
        addi $s6, $s6, 1
        j cd_loop
cd_end_loop:
    # BRANCH: count < 3 => no match. return 0
    li $t0, 3
    blt $s6, $t0, cd_end_loop_return_zero 
    
    # BRANCH: count >= 3 => has match. mark the matches
    move $v0, $s6

    # from (nx, ny), iterate s6 times subtracting dx and dy. add them to mark
    li $t0, 1 # i = 1
    marking_loop:
        bgt $t0, $s6, cd_exit_loop # i == count => end loop, return (do not operate on i = count)
        
        # x = x - dx * i
        mul $t1, $s3, $t0  # dx * i
        mul $t1, $t1, -1   # should go other direction
        add $t1, $t1, $s1  # + x
        sll $t1, $t1, 2    # * 4 to get the x offset in bits

        # y = y - dy * i
        mul $t2, $s4, $t0  # dy * i
        mul $t2, $t2, -1   # should go other direction
        add $t2, $t2, $s2  # + y
        sll $t2, $t2, 6    # * 64 to get the y offset in bits

        add $t3, $t1, $t2  # the calculated offset of address
        la $t4, ADDR_MARK  # get mark address
        add $t4, $t4, $t3  # mark[nx][ny] address
        li $t5, 1         
        sw $t5, 0($t4)     # mark[nx][ny] = 1

        addi $t0, $t0, 1 # increment i
        j marking_loop
cd_end_loop_return_zero:
    li $v0, 0
cd_exit_loop:
    lw   $ra,  0($sp)
    lw   $s1,  4($sp)
    lw   $s2,  8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    addi $sp, $sp, 28
    jr $ra


# find EVERY blocks that are hovering, drop down.
# no argument
apply_gravity:
    addi $sp, $sp, -16
    sw $ra,  0($sp)
    sw $s1,  4($sp) # used for x iterator
    sw $s2,  8($sp) # used for y iterator
    sw $s3, 12($sp) # used for ty iterator

    # make 200ms sleep for every gravity fall
    li $v0, 32
    li $a0, 200
    syscall 
    
    # loop around x, see if any block is above black blocks
    li $s1, 12 # set up x loop iterator (x = 12 -> 0)
    gravity_x_loop:
        bltz $s1, gravity_end # end of loop: end function.
        
        # loop around y, until block is 
        li $s2, 14 # set up y loop iterator (y = 4 -> 0)
        gravity_y_loop:
            bltz $s2, gravity_x_continue # end of loop: next x iteration
            
            # get the color block for (x, y)
            move $a0, $s1 # x
            move $a1, $s2 # y
            jal get_from_board
            move $t0, $v0 # cell color code
            
            # BRANCH: colored (1st row) => move upwards on until highest ground.
            bne $t0, $zero, gravity_y_continue 

            # BRANCH: empty => search for colored blocks upward (if there is one)
            move $s3, $s2 # make a variable for ty (top y), starting from y
            gravity_search_up: # loop upwards until meeting (color | ceiling)
                addi $s3, $s3, -1 # ty-- (decrement first)
                bltz $s3, gravity_x_continue # end of loop: next x iteration
                
                # t1 = get color(x, ty)
                move $a0, $s1 # x
                move $a1, $s3 # ty
                jal get_from_board
                move $t1, $v0 # value of board color above
                
                # BRANCH: (above == black) => go even more above
                beq $t1, $zero, gravity_search_up

            # BRANCH: (above == stage) => next x iteration
            lw $t2, ADDR_STAGE # hex code value
            beq $t1, $t2, gravity_x_continue 

            # BRANCH: (above != stage, black) => found a hovering block. drop down
            # color(x, y) = t1
            move $a0, $s1
            move $a1, $s2
            move $a2, $t1
            jal add_to_board
            # color(x, ty) = black
            move $a0, $s1
            move $a1, $s3
            move $a2, $zero
            jal add_to_board
        gravity_y_continue:
            addi $s2, $s2, -1
            j gravity_y_loop
    gravity_x_continue:
        addi $s1, $s1, -1
        j gravity_x_loop
gravity_end:
    # END gravity
    lw $ra,  0($sp)
    lw $s1,  4($sp)
    lw $s2,  8($sp)
    lw $s3, 12($sp)
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
    
    jal draw_capsule            # update the gem colors

    # END respond_to_w
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    

# no args needed. returns the hexcode in $v0
# candidates: [ADDR_COLORS, ADDR_COLORS + 6)
get_random_gem_color:
    # make a random color between 0 to 5
    li  $v0, 42          # do random call
    li  $a0, 0           # set lower bound to 0
    li  $a1, 6           # set upper bound to 6 (exclusive)
    syscall              # execute random call in (0, 1, 2, 3, 4, 5), save in $a0

    la  $t0, ADDR_COLORS # save address of COLORS array in $t0
    sll $t1, $a0, 2      # t1 = random index * 4 (actual offset in address)
    add $t2, $t0, $t1    # t2 = t0 + t1 (t2 = index of random color)
    lw  $v0, 0($t2)      # get random hex code, stored in t2 
    jr  $ra              # return to original line
    
    
# create a new capsule, initialized at 6,3
# if there is a gem at 6,3 (and above), end game
new_capsule:
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $s1, 4($sp)

    # coordinate for next top
    addi $s1, $s0, 116
    
    # check if (6,3) is already painted. in case, end game.
    li $a0, 6
    li $a1, 3
    jal get_from_board
    bne $v0, $zero, end_program
    
    # upcoming color hex values 
    # (fetch from next capsule and store in ADDR_CAPSULE_COLORS)
    la   $t0, ADDR_CAPSULE_COLORS # load color address
    lw   $t1, 128($s1) 
    sw   $t1,   0($t0) # load color from next bot and save at current bot
    lw   $t2,  64($s1) 
    sw   $t2,   4($t0) # load color from next mid and save at current mid
    lw   $t3,   0($s1) 
    sw   $t3,   8($t0) # load color from next top and save at current top
    
    # generate and save random color at next capsule viewer
    jal  get_random_gem_color
    sw   $v0,   0($s1)        # save at next top
    jal  get_random_gem_color
    sw   $v0,  64($s1)        # save at next mid
    jal  get_random_gem_color
    sw   $v0, 128($s1)        # save at next bot
    
    # set (x, y) of new capsule to (6, 3)
    la   $t0, ADDR_CAPSULE_X  # load x address
    li   $t1, 6               # put in 6 (starting x coord)
    sw   $t1, 0($t0)          # save to ADDR_CAPSULE_X
    la   $t2, ADDR_CAPSULE_Y  # load y address
    li   $t3, 3               # put in 3 (starting y coord)
    sw   $t3, 0($t2)          # save to ADDR_CAPSULE_Y
    
    lw   $ra, 0($sp)
    lw   $s1, 4($sp)
    addi $sp, $sp, 8
    
    lw   $t0, ADDR_CAPSULE_COLORS   # load first color in capsule (bot)
    beq  $t0, $zero, new_capsule    # if black, needs another round of this
    
    jr   $ra
  

# draw current capsule. 
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
    move $a0, $s1      # x
    move $a1, $s2      # y
    lw   $a2, 0($s3)   # bottom gem color
    jal add_to_board

    # 2) middle gem (y-1)
    move $a0, $s1      # x
    addi $a1, $s2, -1  # y - 1
    lw   $a2, 4($s3)   # middle gem color
    jal add_to_board

    # 3) top gem (y-2)
    move $a0, $s1      # x
    addi $a1, $s2, -2  # y - 2
    lw   $a2, 8($s3)   # top gem color
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
    
    li $a0, 0
    li $a1, 0
    li $a2, 16
    li $a3, 4
    jal draw_line # draw top stage : 0,0 to 15,0 
    
    li $a0, 0
    li $a1, 0
    li $a2, 16
    li $a3, 64
    jal draw_line # draw left stage : 0,0 to 0,15 
    
    li $a0, 11
    li $a1, 0
    li $a2, 16
    li $a3, 64
    jal draw_line # draw right stage : 8,0 to 8,15 
    
    li $a0, 0
    li $a1, 15
    li $a2, 12
    li $a3, 4
    jal draw_line # draw bottom stage : 0,15 to 8,15 
    
    li $a0, 15
    li $a1, 0
    li $a2, 4
    li $a3, 64
    jal draw_line # draw box for next block
    
    li $a0, 12
    li $a1, 4
    li $a2, 4
    li $a3, 4
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
    