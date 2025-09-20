pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

-- player
function init_player()
    player = {
        x = 0,
        y = 0,
        size = 8,
        speed = 1,
        dir = 1,
        is_walking = false,
        is_shifting = false,
        is_reversing = false,
        is_freezing = false,
        row = 0,
        
        walk = function(self)
                self.x += self.speed * self.dir
                
                if self.x + self.size >= 127
                and self.dir == 1 then
                    self.is_walking = false
                    self.is_shifting = true
                    self.row += 1
                end
                
                if self.x <= 0
                and self.dir == -1 then
                    self.is_walking = false
                    self.is_shifting = true
                    self.row += 1
                end
        end,
        
        shift = function(self)
                self.y += self.speed
                
                if self.y >= self.row * 8 then
                    self.is_shifting = false
                    self.is_reversing = true
                end
        end,
        
        reverse = function(self)
            self.dir = -self.dir
            self.is_reversing = false
            self.is_walking = true
        end,
        
        freeze = function(self)
            self.x += 0
            self.y += 0
        end
    }
    
    player.is_walking = true
end

function update_player()
    if btnp(5) then -- x button
        player.is_freezing = not player.is_freezing
    end
    
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
    rectfill(
        player.x,
        player.y,
        player.x + player.size,
        player.y + player.size,
        7
    )
end


-- message display
function display_message(text, t, i2)
    -- text: text to display
    -- t = how long to display
    i += 1
    if i <= t * 60 then
        print(text, 0, 64, 4)
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
        elseif bomb.group_id == 4 then bomb.color = 14 -- Added color for 4th group
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
            interior_color = 5
        end

        rectfill(bomb.x, bomb.y, bomb.x + bomb.size - 1, bomb.y + bomb.size - 1, 1)
        rectfill(bomb.x + 1, bomb.y + 1, bomb.x + bomb.size - 2, bomb.y + bomb.size - 2, interior_color)
        pset(bomb.x + 2, bomb.y + 2, 8)
    end
end

function init_switches()
	local switch_colors = {8, 11, 3, 14} -- Added 4th color
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

-- MAIN GAME LOOPS

function _init()
    -- initialize game variables
    bombs = {}
    switches = {}
    bomb_count = 8
    switch_count = 4 -- Changed to 4
    i = 0

    -- player
    init_player()
    -- bombs and switches
    init_switches()
    init_bombs()
end


function _update60()
    -- player
    update_player()
    -- bombs and switches
    update_switches()
    update_bombs()

    -- check for collision
    for bomb in all(bombs) do
        if is_bomb_active(bomb) and check_collision(player, bomb) then
            -- on collision, restart the game
            _init()
        end
    end
end

function _draw()
    cls()
    
    -- bombs and switches
    draw_switches()
    draw_bombs()
    
    -- player
    draw_player()
    
    -- display message
    display_message(
    "press x to freeze",
     4, 0
    )
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

