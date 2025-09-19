pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function init_game_state()
	game_state = "start"
	bombs = {}
	switches = {}
	canvas = {}
	paint_count = 0
	win_percent = 85
	bomb_count = 8
	switch_count = 3
end

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
		freeze_timer = 0,
		freeze_cooldown = 0,
		
		walk = function(self)
				self.x += self.speed * self.dir
				
				if self.x + self.size > 128
				and self.dir == 1 then
					self.x = 128 - self.size
					self.is_walking = false
					self.is_shifting = true
					self.row += 1
				end
				
				if self.x < 0
				and self.dir == -1 then
					self.x = 0
					self.is_walking = false
					self.is_shifting = true
					self.row += 1
				end
		end,
		
		shift = function(self)
				self.y += self.speed
				
				if self.y >= self.row * self.size then
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
			
		end,
		
		paint = function(self)
			
			for i=0,self.size-1 do
				for j=0,self.size-1 do
					local cx = flr((self.x + i) / 4)
					local cy = flr((self.y + j) / 4)
					if (canvas[cx] and canvas[cx][cy] == 0) then
						canvas[cx][cy] = 1
						paint_count += 1
					end
				end
			end
		end
	}
	
	player.is_walking = true
end

function update_player()
	if btnp(5) then
		if not player.is_freezing and player.freeze_cooldown <= 0 then
			
			player.is_freezing = true
		elseif player.is_freezing then
			
			player.is_freezing = false
			player.freeze_timer = 0
			player.freeze_cooldown = 10
		end
	end

	
	if player.freeze_cooldown > 0 then
		player.freeze_cooldown -= 1/60
		if player.freeze_cooldown < 0 then
				player.freeze_cooldown = 0
		end
	end

	
	if player.y + player.size > 128 then
		game_state = "win"
		return
	end
	
	if player.is_walking 
	and not player.is_freezing then
		player:walk()
		player:paint()
	end
	
	if player.is_shifting 
	and not player.is_freezing then
		player:shift()
		player:paint()
	end
	
	if player.is_reversing
	and not player.is_freezing then
		player:reverse()
	end
	
	if player.is_freezing then
		player:freeze()
		player.freeze_timer += 1/60
		if player.freeze_timer >= 5 then
			
			player.is_freezing = false
			player.freeze_timer = 0
			player.freeze_cooldown = 10
		end
	end
end

function draw_player()
	
	rectfill(
		player.x,
		player.y,
		player.x + player.size -1,
		player.y + player.size -1,
		8
	)
	
	if (player.dir == 1) then
		pset(player.x+5, player.y+2, 7)
		pset(player.x+5, player.y+5, 7)
	else
		pset(player.x+2, player.y+2, 7)
		pset(player.x+2, player.y+5, 7)
	end
end

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
            interior_color = 5
        end

        rectfill(bomb.x, bomb.y, bomb.x + bomb.size - 1, bomb.y + bomb.size - 1, 1)
        rectfill(bomb.x + 1, bomb.y + 1, bomb.x + bomb.size - 2, bomb.y + bomb.size - 2, interior_color)
        pset(bomb.x + 2, bomb.y + 2, 8)
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

function init_canvas()
	for x=0,31 do
		canvas[x] = {}
		for y=0,31 do
			canvas[x][y] = 0
		end
	end
	paint_count = 0
end

function draw_canvas()
	for x=0,31 do
		for y=0,31 do
			if (canvas[x][y] == 1) then
				rectfill(x*4, y*4, x*4+3, y*4+3, 11)
			end
		end
	end
end

function check_collision(a, b)
	return a.x < b.x + b.size and
		 a.x + a.size > b.x and
		 a.y < b.y + b.size and
		 a.y + a.size > b.y
end

function _init()
	init_game_state()
	init_player()
	init_canvas()
	init_switches()
	init_bombs()
end

function _update60()
	if game_state == "playing" then
		update_player()
		update_switches()
		update_bombs()
		
		
		for bomb in all(bombs) do
			if is_bomb_active(bomb) and check_collision(player, bomb) then
				game_state = "game_over"
			end
		end

		
		local current_percent = (paint_count / (32*32)) * 100
		if current_percent >= win_percent then
			game_state = "win"
		end

	elseif game_state == "start" or game_state == "game_over" or game_state == "win" then
		if btnp(5) then
			_init()
			game_state = "playing"
		end
	end
end

function _draw()
	cls(5)
	
	
	draw_canvas()
	
	if game_state == "start" then
		print("choice", 52, 40, 7)
		print("paint the canvas.", 32, 54, 13)
		print("step on switches to", 28, 62, 13)
		print("deactivate bombs.", 34, 70, 13)
		print("press x to start/stop", 24, 84, 7)

	elseif game_state == "playing" then
		draw_switches()
		draw_bombs()
		draw_player()
		
		
		local percent_done = flr((paint_count / (32*32)) * 100)
		print(percent_done .. "% / " .. win_percent .. "%", 2, 2, 7)
		if player.is_freezing then
			print("stopped", 100, 2, 8)
		end

	elseif game_state == "game_over" then
		draw_switches()
		draw_bombs()
		draw_player()
		print("game over", 48, 52, 8)
		print("press x to retry", 32, 64, 7)

	elseif game_state == "win" then
		print("a masterpiece!", 38, 52, 11)
		print("press x to play again", 20, 64, 7)
	end
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
