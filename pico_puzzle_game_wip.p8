pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
game_states = {
    menu = 1,
    game = 2
}

-- current state of the game
state = game_states.menu

-- menu state
function init_menu_state()
    local offset = 32
    title_text = {
        text = "Just Paint!",
        x = 64 - offset,
        y = 64,
        c = 4
    }

    start_text = {
        text = "Press X to Start",
        x = 56 - offset,
        y = 72,
        c = 8
    }


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
        state = game_states.game
        _init() -- reinitialize the game
    end
end

function draw_menu_state()
    local offset = 12
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
    init_map()

    -- player
    init_player()

    -- bombs
    bombs = {}
    bomb_count = 8
    
    -- switches
    switches = {}
    switch_count = 3
    
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
            state = game_states.menu
            _init() -- re-init menu
        end
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
        "Press X to Freeze", 
        5,
        56, 0
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
        col = 0,
        
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
                self.col += 1
            end
        end,
        
        shift = function(self)
            -- shift state
            self.y += self.speed
            
            if self.y >= self.row * 8 then
                self.col = 0
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
            countdown_duration = 60 * 5
        end
    end
    
    -- 5 second time for freezing   
    if countdown_duration > 0 then
        countdown_duration -= 1
        -- check if the timer has reached zero.
        if countdown_duration == 0 then
            player.is_freezing = false
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
    rectfill(
        player.x,
        player.y,
        player.x + player.size - 1,
        player.y + player.size - 1,
        7
    )

    if countdown_duration > 0 then
        print(flr(countdown_duration / 60) + 1, player.x + 3, player.y + 2, 1)
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
        print(text, x, y, 4)
    end
end

-- BOMB AND SWITCH FUNCTIONS
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
		bomb.speed = 0.5 + rnd(1)
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
            interior_color = 5 -- Deactivated color
        end
        rectfill(bomb.x, bomb.y, bomb.x + bomb.size - 1, bomb.y + bomb.size - 1, 1)
        rectfill(bomb.x + 1, bomb.y + 1, bomb.x + bomb.size - 2, bomb.y + bomb.size - 2, interior_color)
        pset(bomb.x + 2, bomb.y + 2, 7)
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

function update_switches()
	for s in all(switches) do
		if check_collision(player, s) then
			s.is_active = true
		else
			s.is_active = false
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
	end
end

function check_collision(a, b)
	return a.x < b.x + b.size and
		 a.x + a.size > b.x and
		 a.y < b.y + b.size and
		 a.y + a.size > b.y
end

-- MAP FUNCTIONS
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
    complete_mp = {
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
    end
end

function _update60()
    -- handle states
    if state == game_states.menu then
        update_menu_state()
    elseif state == game_states.game then
        update_game_state()
    end
end

function _draw()
    cls()

    -- handle states
    if state == game_states.menu then
        draw_menu_state()
    elseif state == game_states.game then
        draw_game_state()
    end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000


