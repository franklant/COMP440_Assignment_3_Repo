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
end

function update_game_state()
	-- player
	update_player()
end

function draw_game_state()
	-- draw map
	draw_map()

	-- player
	draw_player()

	-- display message
	display_message(
		"Press X to Freeze", 
		5,
		56, 0
	)

	-- print(player.col, 0, 64, 7)
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
		col = 0,  -- might be uneccessary
		
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

				-- replace the map tile with the correct tile
				mp[row + 1][col + 1] = complete_mp[row + 1][col + 1]
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

function update_player()
	-- freeze the player
	if btnp(5) then -- x button
		player.is_freezing = not player.is_freezing
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
		player.x + player.size,
		player.y + player.size,
		7
	)
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

i = 0 -- might be uneccessary
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
