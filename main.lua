if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end

local vector = require("hump.vector")
local humpcam = require("hump.camera")

local particles = {}
local obstacles = {}
local gravity = vector(0, -9.81)
local zoom = 10
local camera = humpcam(0, 0, zoom)

local drag = false
local drag_pos = vector(0,0)
local curr_pos = vector(0,0)

function math.clamp(val, min, max)
	return math.max(min, math.min(val, max))
end

local function create_particle(pos, accel, rad, res, color)
	return {
		pos = pos,
		oldpos = pos:clone(),
		accel = accel,
		rad = rad,
		res = res,
		color = {
			r=color[1],
			g=color[2] or color[1],
			b=color[3] or color[1],
			a=color[4] or 1
		},
	}
end
local function create_obstacle(pos, size, res, color, collide)
	return {
		pos = pos,
		size = size,
		res = res,
		color = {
			r=color[1],
			g=color[2] or color[1],
			b=color[3] or color[1],
			a=color[4] or 1},
		collide = collide or true
	}
end

local function verlet(part, dt)
	local temp = part.pos:clone()
	part.pos = part.pos+(part.pos-part.oldpos)+part.accel*dt^2
	part.oldpos = temp
	part.accel = vector(0, 0)
end

local function resolve_obstacle_collision(part, obst)
	local closest = vector(
		math.clamp(part.pos.x, obst.pos.x, obst.pos.x+obst.size.x),
        math.clamp(part.pos.y, obst.pos.y-obst.size.y, obst.pos.y)
	)
	local diff = part.pos-closest
	local dist = diff:len2()
	local normal = diff:normalized()
	local rest = part.res * obst.res
	local dot = (part.pos - part.oldpos)*normal
	local reflect = (part.pos-part.oldpos)-normal*((1+rest)*dot)
	if dist < part.rad^2 then
		part.pos = part.pos+normal*(part.rad-math.sqrt(dist))
		part.oldpos=part.pos-reflect
	end
end

function love.load()
	local rest = 1
	love.graphics.setBackgroundColor(0.25, 0.25, 0.25)
	table.insert(obstacles, create_obstacle(vector(-65,40), vector(10,70), rest, {0.1}))
	table.insert(obstacles, create_obstacle(vector(55,40), vector(10,70), rest, {0.1}))
	table.insert(obstacles, create_obstacle(vector(-65,40), vector(130,10), rest, {0.1}))
	table.insert(obstacles, create_obstacle(vector(-65,-30), vector(130,10), rest, {0.1}))
	table.insert(obstacles, create_obstacle(vector(-25,-10), vector(50,5), rest, {0.1}, false))
	table.insert(particles, create_particle(vector(0, 20), vector(500, 1), 5, 1, {1,0,0}))
	table.insert(particles, create_particle(vector(0, 20), vector(-100, 100), 5, 1, {0,1,0}))
	table.insert(particles, create_particle(vector(0, 20), vector(1000, 0), 5, 1, {0,0,1}))
end

function love.mousepressed(x, y, button)
    if button == 1 then
        drag = true
    end
end
function love.mousemoved(x, y, dx, dy)
    if drag then
        camera:move(-dx/camera.scale, -dy/camera.scale)
    end
end
function love.mousereleased(x, y, button)
    if button == 1 and drag then
        drag = false
    end
end
function love.wheelmoved(x, y)
	if y < 0 and camera.scale > 1 then
		camera:zoom(0.9)
	elseif y > 0 and camera.scale < 20 then
		camera:zoom(1.1)
	end
end

function love.update(dt)
	for _,v in pairs(particles) do
		v.accel = v.accel+gravity
		verlet(v, 1/60)
		for _,k in pairs(obstacles) do
			if k.collide == true then
				resolve_obstacle_collision(v, k)
			end
		end
	end
end
function love.draw()
	camera:attach()
	for _,v in pairs(obstacles) do
		love.graphics.setColor(v.color.r, v.color.g, v.color.b, v.color.a)
		love.graphics.rectangle("fill", v.pos.x, -v.pos.y, v.size.x, v.size.y)
	end
	for _,v in pairs(particles) do
		love.graphics.setColor(v.color.r, v.color.g, v.color.b, v.color.a)
		love.graphics.circle("fill", v.pos.x, -v.pos.y, v.rad)
	end
	camera:detach()
	love.graphics.setColor(1,1,1)
	love.graphics.print("fps: "..love.timer.getFPS(),0,0,0,1.5,1.5)
	love.graphics.print("x: "..camera.x.." y: "..camera.y.." z: "..camera.scale,0,15,0,1.5,1.5)
	love.graphics.print("particles: "..#particles,0,30,0,1.5,1.5)
end
