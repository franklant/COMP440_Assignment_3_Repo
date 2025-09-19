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

function _init()

	-- player
	init_player()
end

i = 0
function _update60()
	-- player
	update_player()
end

function _draw()
	cls()
	
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
