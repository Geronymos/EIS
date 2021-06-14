### CHESS GAME MADE BY JULIAN SEHBAOUI ###

#importing nessesary libaries and own classes from the components folder#
import pygame
import json
import os
from pygame import mixer
from components.test_mode_button_cls import Testmode_Button
from stockfish import Stockfish
from components.pieces_cls import Pieces
from components.kings_cls import Kings
from components.board_cls import Board
from components.clock import Clock
from components.history import Hud
from components.button import Button
from components.external_funktions import *
from components.takeback_func import takeback


def main(player1 = "Player 1", player2 = "Player 2", mode = "STANDARD", bot_bool = False, bot_difficulty = 6):

    # resetting the variables in the .json file#
    json_file = open(r'components\constants.json', 'r')
    json_content = json.load(json_file)
    json_content["round_int"] = 0
    json_file.close()
    json_file = open(r'components\constants.json', 'w')
    json_file.writelines(json.dumps(json_content))
    json_file.close()

    Pieces.white_is_checked = False
    Pieces.black_is_checked = False
    Pieces.checking_piece = None

    #initiating pygame#
    pygame.init()

    player1 = "Spieler 1" if player1 == "" else player1
    player2 = "Spieler 2" if player2 == "" else player2
    
    #Constants#
    BLACK = (0,0,0)
    GREY = (50,50,50)
    WHITE = (255,255,255)
    BG_COLOR_1 = (0, 152, 163)
    BG_COLOR_2 = (2, 112, 120)

    #reading the constants from the json file#
    json_file = open(os.getcwd()+r"\components\constants.json", "r")
    json_content = json.load(json_file)
    round_int = json_content["round_int"]
    tile_size = json_content["tile_size"]
    anchor_point_s = (json_content["anchor_point_s_x"]*tile_size, json_content["anchor_point_s_y"]*tile_size)
    anchor_point_h = (json_content["anchor_point_h_x"]*tile_size, json_content["anchor_point_h_y"]*tile_size)
    anchor_point_hud = (json_content["anchor_point_hud_x"]*tile_size, json_content["anchor_point_hud_y"]*tile_size)
    json_file.close()

    #setting up the variables for a new and fresh game#
    screen_size = (11*tile_size, 11*tile_size)
    font = pygame.font.SysFont("DejaVu Sans", int(tile_size*0.2))
    font_titles = pygame.font.SysFont("DejaVu Sans", int(tile_size*0.25))
    go = True
    timer = Clock(time = 5)

    #creating the surfaces#
    screen = pygame.display.set_mode(screen_size, 0,0)
    s = pygame.Surface((8*tile_size, 8*tile_size))
    hud = pygame.Surface((10.25*tile_size, 2*tile_size))
    p1 = pygame.Surface((3*tile_size, 1.5*tile_size))
    p2 = pygame.Surface((3*tile_size, 1.5*tile_size))
    h = Hud((2*tile_size, 8*tile_size))
    screen.fill(BG_COLOR_1)
    hud.fill(BG_COLOR_2)
    h.fill(BG_COLOR_2)
    h.print(pos = (0.6*tile_size, 20), label = 'Spielhistorie', font = font)

    #window caption#
    pygame.display.set_caption("Chess")

    #creating a clock for the ingame ticks#
    clock = pygame.time.Clock()
    
    #creating the board on the subsurface#
    board = Board(master = s, width = 8, height = 8, tile_size = tile_size, color_a = (245, 216, 188), color_b = (176, 142, 109), color_t1=(240, 230, 221), color_t2=(201, 181, 163), anchor_point = anchor_point_s)

    #loading the images for the pieces#
    images = {
    "white_pawn_img" :    pygame.image.load(r'assets/white_pawn.png'),
    "white_rook_img" :    pygame.image.load(r'assets/white_rook.png'),
    "white_knight_img" :  pygame.image.load(r'assets/white_knight.png'),
    "white_bishop_img" :  pygame.image.load(r'assets/white_bishop.png'),
    "white_queen_img" :   pygame.image.load(r'assets/white_queen.png'),
    "white_king_img" :    pygame.image.load(r'assets/white_king.png'),
    "black_pawn_img" :    pygame.image.load(r'assets/black_pawn.png'),
    "black_rook_img" :    pygame.image.load(r'assets/black_rook.png'),
    "black_knight_img" :  pygame.image.load(r'assets/black_knight.png'),
    "black_bishop_img" :  pygame.image.load(r'assets/black_bishop.png'),
    "black_queen_img" :   pygame.image.load(r'assets/black_queen.png'),
    "black_king_img" :    pygame.image.load(r'assets/black_king.png')
    }
    #loading the icons for the buttons#
    quit_icon =     pygame.image.load(r'assets/quit.png')
    takeback_icon = pygame.image.load(r'assets/takeback.png')
    resign_icon =   pygame.image.load(r'assets/resign_flag.png')
    test_icon =     pygame.image.load(r'assets/lightbulb.png')

    #creating the board
    build_board(mode, s, images)
        
    #creating the chessbot based on .json parameters
    bot = Stockfish(b'components\stockfish_20011801_x64.exe')
    bot.set_skill_level(bot_difficulty)
    

    quit_button = Button(    x = 8.5*tile_size,
                             y = 0.4*tile_size,
                             w = int(0.6*tile_size),
                             h = int(0.6*tile_size),
                             color_b=BLACK,
                             color_in = GREY,
                             color_t=WHITE,
                             command = quit,
                             icon = quit_icon,
                             imaginary_x=anchor_point_hud[0],
                             imaginary_y=anchor_point_hud[1]
                             )

    
    resign_button = Button(x = 9.2*tile_size,
                             y = 0.4*tile_size, 
                             w = int(0.6*tile_size),
                             h = int(0.6*tile_size),
                             color_b=BLACK,
                             color_in = GREY,
                             color_t=WHITE,
                             command = lambda:[decideWhoLost(round_int)],
                             icon = resign_icon,
                             imaginary_x=anchor_point_hud[0],
                             imaginary_y=anchor_point_hud[1]
                             )


    test_zone_button = Testmode_Button(x=9.2*tile_size,
                                y = 0.4*tile_size+0.74*tile_size,
                                w = int(0.6*tile_size),
                                h = int(0.6*tile_size), 
                                color_b=BLACK,
                                color_in = GREY,
                                color_t=WHITE,
                                command1 = lambda:[Board.change_testmode(),
                                                   #Pieces.change_ignore_me_standard(),
                                                   Pieces.crop_move_done(),
                                                   Pieces.kill_board(),
                                                   build_board(mode, s, images),
                                                   Pieces.build_from_list(screen=s),
                                                   Pieces.set_round(Pieces.round_safe)
                                                   ], 

                                command2 = lambda:[Board.change_testmode(),
                                                   #Pieces.change_ignore_me_standard(),
                                                   Pieces.safe_round()
                                                   ],
                                icon = test_icon,
                                imaginary_x=anchor_point_hud[0],
                                imaginary_y=anchor_point_hud[1],
                                deaf=False)

    if bot_bool:
        command = lambda:[takeback(board, s, takeback_button), takeback(board, s, takeback_button)]
    else:
        command = lambda:[takeback(board, s, takeback_button)]

    takeback_button = Button(x = 8.5*tile_size,
                             y = 0.4*tile_size+0.74*tile_size, 
                             w = int(0.6*tile_size),
                             h = int(0.6*tile_size),
                             color_b=BLACK,
                             color_in = GREY,
                             color_t=WHITE,
                             command = command,
                             icon = takeback_icon,
                             imaginary_x=anchor_point_hud[0],
                             imaginary_y=anchor_point_hud[1]
                             )

    start_sound = mixer.Sound("assets/sounds/board-start.mp3")
    start_sound.play()

    #the mainloop#
    while go:
        #setting the framerate#
        clock.tick(60)
        
        #refreshing the round counter#
        json_file = open(os.getcwd()+r"\components\constants.json", "r")
        json_content = json.load(json_file)
        round_int = json_content["round_int"]
        json_file.close()

        #drawing the board#
        # if not Board.game_over:
        board.draw_board()

        #updating the bot with the new game state#
        bot.set_fen_position(Pieces.give_FEN())
        
        #detecting, if the game is over, or not
        if not Board.game_over:
            Pieces.detectingCheck()
            Board.game_over = Pieces.detectGameOver(round_int=round_int)

        #end the game if the game is over#
        if Board.game_over or Board.resign_w or Board.resign_b:
            if Pieces.white_is_checked or Board.resign_w:
                board.end_screen('BLACK', s)
            elif Pieces.black_is_checked or Board.resign_b:
                board.end_screen('WHITE', s)
            else:
                board.end_screen('STALEMATE', s)
            takeback_button.active = False
            resign_button.active = False
            test_zone_button.active = False

        #checking if a pawn is promotable#
        for pawn in Pieces.all_pieces_list:
            if 'Pawn-B' in pawn.name and pawn.y == 7*tile_size or 'Pawn-W' in pawn.name and pawn.y == 0*tile_size:
                pawn.promotion()

        Pieces.detectingCheck()
        #highlighting the checked king#
        if Pieces.white_is_checked:
            for king in Pieces.all_pieces_list:
                if isinstance(king, Kings) and king.farbe == WHITE:
                    board.check(king_pos = (king.x, king.y))

        #highlighting the checked king#            
        elif Pieces.black_is_checked: 
            for king in Pieces.all_pieces_list:
                if isinstance(king, Kings) and king.farbe == BLACK:
                    board.check(king_pos = (king.x, king.y))

        #drawing all the pieces#
        # if not Board.game_over:
        for pieces in Pieces.all_pieces_list:
            pieces.draw(screen)
        
        #updating the mainsurface#
        pygame.display.update()

        #clearing the Subsurfaces#
        p1.fill(BG_COLOR_1)
        p2.fill(BG_COLOR_1)
        hud.fill(BG_COLOR_2)

        #refresh the time of the timers#
        timer.refreshTime()

        #creating the labels to be printed on the subsurfaces#
        Player_1_label = font_titles.render(player1, 1, BLACK)
        Player_2_label = font_titles.render(player2, 1, BLACK)
        timer_label = font_titles.render(timer.getTime(), 1, BLACK)

        #printing the labes on the subsurfaces#        
        p1.blit(Player_1_label, (p1.get_width()/2 - Player_1_label.get_width()/2,0))
        p2.blit(Player_2_label, (p2.get_width()/2 - Player_2_label.get_width()/2,0))

        #creating the history
        h.fill(BG_COLOR_2)
        h.print((0.31*tile_size, 20), 'Spielhistorie', font)
        for i in range(len(Pieces.moves_done)):
            fac_50 = 5/7 *tile_size
            fac_20 = 2/7 *tile_size
            h.print(pos = ((i%2)*fac_50+fac_20, (i//2)*fac_20+2*fac_20), label = Pieces.moves_done[i], font= font)



        #showing the taken pieces#
        Pieces.taken_pieces.sort(key= lambda x: x.value, reverse = False)
        white_loss = [[], []]
        black_loss = [[], []]
        for piece in Pieces.taken_pieces:
            if piece.farbe == (0,0,0):
                if len(black_loss[0]) < 8:
                    black_loss[0].append(piece)
                else:
                    black_loss[1].append(piece)
            elif piece.farbe == WHITE:
                if len(white_loss[0]) < 8:
                    white_loss[0].append(piece)
                else:
                    white_loss[1].append(piece)

        for line in black_loss:
            for piece in line:
                p1.blit(pygame.transform.scale(piece.image, (tile_size//3, tile_size//3)), ((line.index(piece)*11/32 + 6/40 )*tile_size, (black_loss.index(line)+1)*0.5*tile_size))
        for line in white_loss:
            for piece in line:
                p2.blit(pygame.transform.scale(piece.image, (tile_size//3, tile_size//3)), ((line.index(piece)*11/32 + 6/40 )*tile_size, (white_loss.index(line)+1)*0.5*tile_size))

        value_white = 0
        value_black = 0

        for piece in Pieces.taken_pieces:
            if piece.farbe == (0,0,0):
                value_black += piece.value
            elif piece.farbe == WHITE:
                value_white += piece.value

        label = font.render('+'+str(abs(int(value_white-value_black))), True, BLACK)
        if int(value_white-value_black) > 0:
            if len(white_loss[0]) < 8:
                p2.blit(label, ((len(white_loss[0])*11/32 + 6/40 )*tile_size, 0.55*tile_size))
            else:
                p2.blit(label, ((len(white_loss[1])*11/32 + 6/40 )*tile_size, 1.05*tile_size))
        elif int(value_white-value_black) < 0:
            if len(black_loss[0]) < 8:
                p1.blit(label, ((len(black_loss[0])*11/32 + 6/40 )*tile_size, 0.55*tile_size))
            else:
                p1.blit(label, ((len(black_loss[1])*11/32 + 6/40 )*tile_size, 1.05*tile_size))

        #updating the hud#
        if round_int % 2 == 0:
            pygame.draw.rect(hud, BLACK, [0.45*tile_size, 0.2*tile_size, 3.1*tile_size, 1.6*tile_size])
        elif round_int % 2 == 1:
            pygame.draw.rect(hud, BLACK, [4.45*tile_size, 0.2*tile_size, 3.1*tile_size, 1.6*tile_size])
        hud.blit(p1, (0.5*tile_size, 0.25*tile_size))
        hud.blit(p2, (4.5*tile_size, 0.25*tile_size))
        hud.blit(timer_label, (3.65*tile_size, 0.75*tile_size))

        #creating the buttons on the hud
        resign_button.draw(screen = hud)
        quit_button.draw(screen = hud)
        takeback_button.draw(screen = hud)
        test_zone_button.draw(screen = hud)

        items = [quit_button, resign_button, takeback_button, test_zone_button]

        #bliting the subsurfaces on the mainsurface
        screen.blit(s, anchor_point_s)
        screen.blit(h, anchor_point_h)
        screen.blit(hud, anchor_point_hud)

        #bot moves#   
        if round_int % 2 == 1 and bot_bool and not Board.game_over and not Board.test_mode:
            opt_move = bot.get_best_move_time(random.randint(400,1200))
            for piece in Pieces.all_pieces_list:
                if piece.farbe == BLACK:
                    move = piece.move_from_pos(move=opt_move, board=board, screen = screen, takeback_button = takeback_button, ignore_me = Pieces.ignore_me_standard)
                    if move != None:
                        break

        #checking for events#
        else:
            for event in pygame.event.get():

                for item in items:
                    item.processEvent(event)

                #closing the screen by clicking the X#
                if event.type == pygame.QUIT:
                    go = False
    
                #Keyboard-Inputs#
                if event.type == pygame.KEYDOWN:

                    #kill window if ESC is pressed#
                    if event.key == pygame.K_ESCAPE:
                        Pieces.white_is_checked = False
                        Pieces.black_is_checked = False
                        Pieces.checking_piece = None

                        json_file = open(r'components\constants.json', 'r')
                        json_content = json.load(json_file)
                        json_content["round_int"] = 0
                        json_file.close()
                        json_file = open(r'components\constants.json', 'w')
                        json_file.writelines(json.dumps(json_content))
                        json_file.close()

                        quit()
                    
                    #(TEMP) my information key (arrow down) to get certain information#
                    if event.key == pygame.K_DOWN:
                        print(Pieces.give_FEN())
                        #print([x.name for x in Pieces.all_pieces_list])
                        # for king in Pieces.all_pieces_list:
                        #     if "King-W" in king.name:
                        #         print(list(king.is_castle_legal()))
                        

                #left mouse click#
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:

                                      
                    #getting the mouseposition and than correcting it by the relative position of the subsurface#
                    mouse_pos = pygame.mouse.get_pos()
                    mouse_pos = (mouse_pos[0]-anchor_point_s[0], mouse_pos[1]-anchor_point_s[1])

                    #checking if a Piece stands on the clicked tile#
                    if not Board.game_over:
                        for piece in Pieces.all_pieces_list:
                            if mouse_pos[0] >= piece.x and mouse_pos[1] >=piece.y:
                                if mouse_pos[0] < piece.x+tile_size and mouse_pos[1] < piece.y+tile_size:
                                    
                                    #if the clicked piece is one of the team that currently is to move...#

                                    with_bool = round_int % 2 == 0 and piece.farbe == (255, 255, 255)
                                    without_bool = round_int % 2 == 1 and piece.farbe == (0,0,0)

                                    if with_bool or without_bool:

                                        #...wait for the second mouse input#
                                        move_ = piece.move(board = board, screen = screen, takeback_button = takeback_button, ignore_me = Pieces.ignore_me_standard)

                                        move_ = move_[1][2:3] + move_[2] +str(move_[0][2:])

                                        #check if the white kiung is checked#
                                        Pieces.detectingCheck()

    #resetting class variables#
    Pieces.white_is_checked = False
    Pieces.black_is_checked = False
    Pieces.checking_piece = None

    #resetting the variables in the .json file#
    json_file = open(r'components\constants.json', 'r')
    json_content = json.load(json_file)
    json_content["round_int"] = 0
    json_file.close()
    json_file = open(r'components\constants.json', 'w')
    json_file.writelines(json.dumps(json_content))
    json_file.close()

#executing the script if started from the main.py file#
if __name__ == '__main__':
    main()
