pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

game_states = {
    menu = 1,
    game = 2,
    win = 3
}

-- current state of the game
state = game_states.menu

-- menu state
function init_menu_state()
    local offset = 32
    title_text = {
        text = "just paint!",
        x = 64 - offset,
        y = 64,
        c = 4
    }

    start_text = {
        text = "press x to start",
        x = 56 - offset,
        y = 72,
        c = 8
    }

    -- playing menu music 
    

end

angle = 0
function update_menu_state()
    -- make text floaty
    angle += 0.01

    title_text.y += sin(angle)

    if angle >= 1 then
        angle = 0
    end

    if btnp(5) then -- x button pressed
       sfx(0) --playing start game sound effect
        state = game_states.game
        _init() -- reinitialize the game
    end
end

function draw_menu_state()
    -- title
    print(
        title_text.text, 
        title_text.x, title_text.y,
        title_text.c
    )

    -- start
    print(
        start_text.text,
        start_text.x, start_text.y,
        start_text.c
    )
end

-- game state
function init_game_state()
    -- map
    music(0) -- background music 
    init_map()

    -- player
    init_player()

    -- bombs
    bombs = {}
    bomb_count = 2
    
    -- switches
    switches = {}
    switch_count = 2
    
    init_switches()
    init_bombs()
end

function update_game_state()
    -- player
    update_player()

    -- switches
    update_switches()

    -- bombs
    update_bombs()

    -- check for collision with bombs
    for bomb in all(bombs) do
        if is_bomb_active(bomb) and check_collision(player, bomb) then
           --play bomb collision sounds and stop music 
           sfx(2)
           music(-1)
            state = game_states.menu
            angle = 0
            countdown_duration = 0
            deactivate_timer = 0
            _init() -- re-init menu
        end
    end

    -- check win condition
    if player.cells_painted >= 264 then
        --play win game sound effect
        sfx(4)
        state = game_states.win
        angle = 0
        countdown_duration = 0
        deactivate_timer = 0
        _init() -- reinitialize the game
    end
end

function draw_game_state()
    -- draw map
    draw_map()

    -- draw switches
    draw_switches()

    -- draw bombs
    draw_bombs()

    -- player
    draw_player()

    -- display message
    display_message(
        "press x to freeze", 
        5,
        56, 0
    )
end

-- win state
function init_win_state()
    local offset = 32
    win_text = {
        text = "congratulations! true art!",
        x = 47 - offset,
        y = 64,
        c = 10
    }

    retry_text = {
        text = "press x to paint again",
        x = 56 - offset,
        y = 72,
        c = 8
    }

-- playing win music on entering this state
music(2)

end

angle = 0
function update_win_state()
    -- make text floaty
    angle += 0.01

    win_text.y += sin(angle)

    if angle >= 1 then
        angle = 0
    end

    if btnp(5) then -- x button pressed
        sfx(0) --play 
        state = game_states.game
        angle = 0
        countdown_duration = 0
        deactivate_timer = 0
        _init() -- reinitialize the game
    end
end

function draw_win_state()
    -- win 
    print(
        win_text.text, 
        win_text.x, win_text.y,
        win_text.c
    )

    -- retry
    print(
        retry_text.text,
        retry_text.x, retry_text.y,
        retry_text.c
    )
end

-- player
function init_player()
    player = {
        x = 0 - 7, -- ensures the player paints the whole map
        y = 0,
        size = 8,
        speed = 1,
        dir = 1,

        -- states
        is_walking = false,
        is_shifting = false,
        is_reversing = false,
        is_freezing = false,
        row = 0,
        cells_painted = 0,
        
        walk = function(self)
            -- walk state
            self.x += self.speed * self.dir
            
            if self.x >= 127
            and self.dir == 1 then
                self.is_walking = false
                self.is_shifting = true
                self.row += 1
            end
            
            if self.x + self.size <= 0
            and self.dir == -1 then
                self.is_walking = false
                self.is_shifting = true
                self.row += 1
            end
            
            -- update col number
            if self.x % 8 == 0 then
                -- update map
                -- use the player position to get the correct index on the map
                local row = flr(self.y / 8)
                local col = flr(self.x / 8)
                
                if row >= 0 and row <= 15 and col >= 0 and col <= 15 then
                    mp[row + 1][col + 1] = complete_mp[row + 1][col + 1]
                end
                self.cells_painted += 1
            end
        end,
        
        shift = function(self)
            -- shift state
            self.y += self.speed
            
            if self.y >= self.row * 8 then
                -- self.col = 0
                self.is_shifting = false
                self.is_reversing = true
            end
        end,
        
        reverse = function(self)
            -- reverse state
            self.dir = -self.dir
            self.is_reversing = false
            self.is_walking = true
        end,
        
        freeze = function(self)
            -- freeze state
            self.x += 0
            self.y += 0
        end
    }
    
    -- set the default state to active
    player.is_walking = true
end

i = 0
countdown_duration = 0
function update_player()
    -- freeze the player
    if btnp(5) then -- x button
        if not player.is_freezing and countdown_duration == 0 then
            player.is_freezing = true
            sfx(1) -- playing freeze sound effect
            music(-1)
            countdown_duration = 60 * 5
        end
    end
    
    -- 5 second time for freezing   
    if countdown_duration > 0 then
        countdown_duration -= 1
        -- check if the timer has reached zero.
        if countdown_duration == 0 then
            player.is_freezing = false
            music(0)
        end
    end

    -- call states approriately
    if player.is_walking 
    and not player.is_freezing then
        player:walk()
    end
    
    if player.is_shifting 
    and not player.is_freezing then
        player:shift()
    end
    
    if player.is_reversing
    and not player.is_freezing then
        player:reverse()
    end
    
    if player.is_freezing then
        player:freeze()
    end
end

function draw_player()
    -- subject to change
    -- rectfill(
    --     player.x,
    --     player.y,
    --     player.x + player.size,
    --     player.y + player.size,
    --     7
    -- )
    spr(0, player.x, player.y + 0.5, 1, 1, false, true)

    if countdown_duration > 0 then
        print(flr(countdown_duration / 60) + 1, player.x + 3, player.y + 2, 8)
    end
end


-- message display
function display_message(text, t, x, y)
    -- text: text to display
    -- t: how long to display
    -- x: texts x-position
    -- y: texts y-position

    i += 1
    if i <= t * 60 then
        print(text, x, y, 10)
    end
end

-- bomb and switch functions
function init_bombs()
    local min_dist_x = 16
	for i=1,bomb_count do
        local potential_bomb_x
        local is_valid_pos = false
        local retries = 0
        
        while not is_valid_pos and retries < 50 do
            potential_bomb_x = 8 + rnd(112)
            is_valid_pos = true
            
            for existing_bomb in all(bombs) do
                if abs(potential_bomb_x - existing_bomb.x) < min_dist_x then
                    is_valid_pos = false
                    break
                end
            end
            retries += 1
        end

		local bomb = {
			size = 8,
			pattern = "vertical",
			group_id = i % (switch_count + 1)
		}
        
        if bomb.group_id == 1 then bomb.color = 8
        elseif bomb.group_id == 2 then bomb.color = 11
        elseif bomb.group_id == 3 then bomb.color = 3
        else bomb.color = 7 
        end
        
		bomb.y_start = 10 + rnd(40)
		bomb.y_end = bomb.y_start + 30 + rnd(40)
		bomb.x = potential_bomb_x
		bomb.y = bomb.y_start
		bomb.speed = 0.1 + rnd(0.1)
		bomb.dir = (rnd(2) < 1) and -1 or 1

		add(bombs, bomb)
	end
end

function is_bomb_active(bomb)
	if bomb.group_id == 0 then return true end
	
	for s in all(switches) do
		if s.group_id == bomb.group_id then
			return not s.is_active
		end
	end
	return true
end

function update_bombs()
    for bomb in all(bombs) do
        if is_bomb_active(bomb) then
            bomb.y += bomb.speed * bomb.dir
            if bomb.y < bomb.y_start or bomb.y > bomb.y_end then
                    bomb.dir *= -1
            end
        end
    end
end

function draw_bombs()
    for bomb in all(bombs) do
        local interior_color = bomb.color
        if not is_bomb_active(bomb) then
            interior_color = 5 -- deactivated color
        end
        -- rectfill(bomb.x, bomb.y, bomb.x + bomb.size - 1, bomb.y + bomb.size - 1, 1)
        -- rectfill(bomb.x + 1, bomb.y + 1, bomb.x + bomb.size - 2, bomb.y + bomb.size - 2, interior_color)
        -- pset(bomb.x + 2, bomb.y + 2, 7)
        spr(1, bomb.x, bomb.y, 1, 1, false, false)
    end
end

function init_switches()
	local switch_colors = {8, 11, 3}
	for i=1,switch_count do
		local s = {
			x = 16 + rnd(96),
			y = 16 + rnd(96),
			size = 8,
			group_id = i,
			color = switch_colors[i],
			is_active = false
		}
		add(switches, s)
	end
end

deactivate_timer = 0
start_time = false
function update_switches()
	for s in all(switches) do
		if check_collision(player, s) then
			s.is_active = true
            start_time = true
            sfx(5)
		end

        if not start_time then
            s.is_active = false
        end
	end

    if start_time and deactivate_timer == 0 then
        deactivate_timer = 60 * 5
    end

    -- 5 second time for freezing   
    if deactivate_timer > 0 then
        deactivate_timer -= 1
        -- check if the timer has reached zero.
        if deactivate_timer == 0 then
            start_time = false
        end
    end
end

function draw_switches()
	for s in all(switches) do
		local color = s.color
		if s.is_active then
			color = 7
		end
		rectfill(s.x, s.y, s.x+s.size-1, s.y+s.size-1, 0)
		rect(s.x, s.y, s.x+s.size-1, s.y+s.size-1, color)
		print("s", s.x+2, s.y+1, color)

        if s.is_active and deactivate_timer > 0 then
            print(flr(deactivate_timer / 60) + 1, s.x + 3, s.y + 2, 8)
        end
	end
end

function check_collision(a, b)
	return a.x < b.x + b.size and
		 a.x + a.size > b.x and
		 a.y < b.y + b.size and
		 a.y + a.size > b.y
end

-- map functions
function init_map()
    -- 16 * 16 tile grid.
    mp = {
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    }

    -- the completed map when the player fully crosses the screen
    -- each value corresponds to the color it will show
    test_mp = {
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1},
        {7, 2, 7, 2, 7, 2, 7, 2, 2, 2, 7, 2, 2, 1, 1, 1}
    }
    smile_face_mp = {
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 1, 1, 1, 1},
        {1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 1, 1, 1},
        {1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 1, 1},
        {1, 1, 10, 10, 12, 12, 10, 10, 10, 12, 12, 10, 10, 10, 1, 1},
        {1, 10, 10, 10, 12, 12, 10, 10, 10, 12, 12, 10, 10, 10, 10, 1},
        {1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 1},
        {1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 1},
        {1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 1},
        {1, 1, 10, 10, 10, 9, 9, 9, 9, 9, 9, 10, 10, 10, 1, 1},
        {1, 1, 1, 10, 10, 10, 9, 9, 9, 9, 10, 10, 10, 1, 1, 1},
        {1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
    }
    apple_mp = {
        {11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11},
        {11, 11, 11, 11, 11, 11, 11, 4, 4, 11, 11, 11, 11, 11, 11, 11},
        {11, 11, 11, 11, 11, 11, 4, 4, 4, 11, 11, 11, 11, 11, 11, 11},
        {11, 11, 11, 11, 11, 11, 8, 8, 8, 8, 11, 11, 11, 11, 11, 11},
        {11, 11, 11, 11, 11, 8, 7, 8, 8, 8, 8, 11, 11, 11, 11, 11},
        {11, 11, 11, 11, 8, 7, 8, 8, 8, 8, 8, 8, 11, 11, 11, 11},
        {11, 11, 11, 11, 8, 7, 8, 8, 8, 8, 8, 8, 8, 11, 11, 11},
        {11, 11, 11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11, 11},
        {11, 11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11},
        {11, 11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11},
        {11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11},
        {11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11},
        {11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11},
        {11, 11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11, 11},
        {11, 11, 11, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 11, 11, 11},
        {11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11}
    }
    flower_mp = {
        {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 10, 10, 10, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 10, 10, 10, 10, 10, 10, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 10, 10, 10, 10, 10, 10, 10, 10, 3, 3, 3, 3, 3},
        {3, 3, 3, 10, 10, 9, 9, 9, 10, 10, 10, 10, 3, 3, 3, 3},
        {3, 3, 10, 10, 9, 9, 10, 9, 9, 9, 10, 10, 3, 3, 3, 3},
        {3, 3, 10, 10, 9, 10, 9, 9, 10, 9, 10, 10, 3, 3, 3, 3},
        {3, 3, 10, 10, 9, 9, 10, 9, 9, 9, 10, 10, 3, 3, 3, 3},
        {3, 3, 3, 10, 10, 9, 9, 9, 10, 10, 10, 10, 3, 3, 3, 3},
        {3, 3, 3, 3, 10, 10, 10, 10, 10, 10, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 10, 10, 10, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 3, 3, 11, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 3, 3, 11, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 3, 3, 11, 3, 3, 3, 3, 3, 3, 3, 3},
        {3, 3, 3, 3, 3, 3, 3, 11, 3, 3, 3, 3, 3, 3, 3, 3}
    }
    sun_mp = {
        {2, 2, 2, 2, 2, 2, 10, 10, 10, 2, 2, 2, 2, 2, 2, 2},
        {2, 2, 2, 2, 2, 10, 9, 9, 9, 10, 2, 2, 2, 2, 2, 2},
        {2, 2, 2, 2, 10, 9, 9, 9, 9, 9, 10, 2, 2, 2, 2, 2},
        {2, 2, 2, 10, 9, 9, 10, 10, 9, 9, 9, 10, 2, 2, 2, 2},
        {2, 2, 10, 9, 9, 10, 10, 10, 10, 9, 9, 9, 10, 2, 2, 2},
        {2, 10, 9, 9, 10, 10, 10, 10, 10, 10, 10, 9, 9, 10, 2, 2},
        {10, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 9, 9, 10, 2},
        {10, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 9, 9, 10},
        {10, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 9, 9, 10},
        {2, 10, 9, 9, 10, 10, 10, 10, 10, 10, 10, 9, 9, 10, 2, 2},
        {2, 2, 10, 9, 9, 10, 10, 10, 10, 9, 9, 9, 10, 2, 2, 2},
        {2, 2, 2, 10, 9, 9, 10, 10, 9, 9, 9, 10, 2, 2, 2, 2},
        {2, 2, 2, 2, 10, 9, 9, 9, 9, 9, 10, 2, 2, 2, 2, 2},
        {2, 2, 2, 2, 2, 10, 9, 9, 9, 10, 2, 2, 2, 2, 2, 2},
        {2, 2, 2, 2, 2, 2, 10, 10, 10, 2, 2, 2, 2, 2, 2, 2},
        {2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2}
    }

    -- randomize the map selection each game
    complete_mp = rnd({test_mp, smile_face_mp, apple_mp, flower_mp, sun_mp})
end

function draw_map()
    -- iterate through the map and draw correct color tiles
    -- row (y)
    for i2=1, 16 do 
        -- col (x)
        for j2=1, 16 do
            local val = mp[i2][j2]
            if val != 0 then
                local x = j2 * 8
                local y = i2 * 8
                circfill(x - 4,  y - 4, 4, val)
            end
        end
    end
end

function _init()
    -- handle states
    if state == game_states.menu then
        init_menu_state()
    elseif state == game_states.game then
        init_game_state()
    elseif state == game_states.win then
        init_win_state()
    end
end

function _update60()
    -- handle states
    if state == game_states.menu then
        update_menu_state()
    elseif state == game_states.game then
        update_game_state()
    elseif state == game_states.win then
        update_win_state()
    end
end

function _draw()
    cls()

    -- handle states
    if state == game_states.menu then
        draw_menu_state()
    elseif state == game_states.game then
        draw_game_state()
    elseif state == game_states.win then
        draw_win_state()
    end
end


__gfx__
0000000008000000cccccccc0000000000000000ccccccccc8cccccc000000000000000000000000000000000000000000000000000000000000000000000000
0007700000400000cccccccc0000000000000000cccccccccc4ccccc000000000000000000000000000000000000000000000000000000000000000000000000
0007700000040000cccccccc0000000000000000ccccccccccc4cccc000000000000000000000000000000000000000000000000000000000000000000000000
0004400000555000c77444440000000000000000cccccccccc555ccc000000000000000000000000000000000000000000000000000000000000000000000000
0004400005555500c77444440000000000000000ccccccccc55555cc000000000000000000000000000000000000000000000000000000000000000000000000
0004400005555500cccccccc0000000000000000ccccccccc55555cc000000000000000000000000000000000000000000000000000000000000000000000000
0004400005555500cccccccc0000000000000000ccccccccc55555cc000000000000000000000000000000000000000000000000000000000000000000000000
0004400000555000cccccccc0000000000000000cccccccccc555ccc000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00000000015500255003550045500555007550095500b5500d5501155012550145501655018550195501b5501c5501f5502155022550285502b5502d550000000000000000000000000000000000000000000000
00100000244301f430164300000000000144300000000000144300000014430000000000013430000000000011430104300c43000000000000d430000000e430204000f430164001043017430194302043029430
001000000707007070070700707003070186000500005000050000600008000090000a0000a0000a0000600000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000002c550305502b5502a55030550365503a5503e5503e5503e550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001e53000000000001d5300000000000000001d5300000000000000001d530000000000000000000001e53000000000001d5300000000000000001d5300000000000000001d530000001d5302453029530
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000f00013050140501405013050100500c0500b0500b0000a7500c7501075014750177501875018750157500f7500c7000b0500e0501305017050190501805015050110500b7000b7500b7500b7500b750
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000f500287502b7502f75033750327502d550295502655024550225502255022750257502c750347502e5502a550275502955033750317502a550275502755027550307502f75027750245502555025550
0010000000010241102121024110212102511027110222102221023210242102521026210272102a4102b4102c4102521027210262101e2101841015410164100d110101101511017110191100d1100b1100b110
__music__
03 0a424344
03 07070707
03 4c094344

