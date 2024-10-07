package game

import "core:fmt"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

_ :: fmt

Game_Memory :: struct {
	ground:                rl.Rectangle,
	ground_color:          rl.Color,
	player:                Player,
	platforms:             [dynamic]Platform,
	spawn_platforms_timer: Timer,
	dead:                  bool,
	score:                 int,
}

g_mem: ^Game_Memory

Width :: 1280
Height :: 720

//------------timer related
Timer :: struct {
	time:     f32,
	max_time: f32,
}

create_timer :: proc(max_time: f32) -> Timer {
	return Timer{time = 0.0, max_time = max_time}
}

update_timer :: proc(timer: ^Timer, dt: f32) -> bool {
	finished := false
	timer.time += dt
	if timer.time >= timer.max_time {
		finished = true
		timer.time = 0.0
	}
	return finished
}

draw_timer :: proc(timer: Timer, name: string = "") {
	fmt.println(name, ": ", timer.time, " | ", timer.max_time)
}

//--------player related
Player :: struct {
	rect:  rl.Rectangle,
	color: rl.Color,
	vel:   f32,
}

JumpHeight :: 120.0
JumpTime :: .3

get_jumping_ver_speed :: proc() -> f32 {
	return 2 * JumpHeight / JumpTime
}

get_gravity :: proc() -> f32 {
	return -2 * JumpHeight / (JumpTime * JumpTime)
}

create_player :: proc() -> Player {
	size := f32(30.0)
	return Player {
		rect = rl.Rectangle{Width / 2 - size / 2, Height / 2 - size / 2, size, size},
		color = rl.PINK,
	}
}

update_player :: proc(player: ^Player, dt: f32) {
	if rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.K) {
		player.vel = get_jumping_ver_speed()
	}

	player.rect.y -= 0.5 * get_gravity() * dt * dt + player.vel * dt
	player.vel += get_gravity() * dt
}

//platform
Platform :: struct {
	rect_top:    rl.Rectangle,
	rect_bottom: rl.Rectangle,
	rect_open:   rl.Rectangle,
	color:       rl.Color,
	speed:       f32,
	passed_by:   bool,
}

create_plaform :: proc() -> Platform {
	//hole_size := f32(180.0)
	hole_size := f32(350.0)
	grass_size := f32(100.0)
	padding := f32(50.0)

	top_point := padding
	bottom_point := f32(Height - (padding + grass_size + hole_size))

	y := f32(rand.int31() % i32(bottom_point - top_point)) + top_point

	return Platform {
		rect_top = rl.Rectangle{Width + 150.0, 0.0, 50.0, y},
		rect_bottom = rl.Rectangle{Width + 150.0, y + hole_size, 50.0, Height},
		rect_open = rl.Rectangle{Width + 150, y, 50.0, hole_size},
		color = rl.WHITE,
		speed = 300.0,
	}
}

update_platform :: proc(platform: ^Platform, dt: f32) {
	platform.rect_top.x -= platform.speed * dt
	platform.rect_bottom.x -= platform.speed * dt
	platform.rect_open.x -= platform.speed * dt
}

render_platform :: proc(platform: Platform) {
	rl.DrawRectangleRec(platform.rect_top, platform.color)
	rl.DrawRectangleRec(platform.rect_bottom, platform.color)
}

@(export)
game_init_window :: proc() {
	rl.InitWindow(Width, Height, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	player := create_player()

	platforms: [dynamic]Platform
	append(&platforms, create_plaform())
	g_mem^ = Game_Memory {
		ground                = rl.Rectangle{0.0, Height - 100.0, Width, 100.0},
		ground_color          = rl.LIME,
		player                = player,
		platforms             = platforms,
		spawn_platforms_timer = create_timer(1.0),
		dead                  = false,
	}

	game_hot_reloaded(g_mem)
}

@(export)
game_update :: proc() -> bool {
	dt := rl.GetFrameTime()

	rl.BeginDrawing()
	rl.ClearBackground(rl.SKYBLUE)

	if !g_mem.dead {
		update_player(&g_mem.player, dt)

		if spawn_platform := update_timer(&g_mem.spawn_platforms_timer, dt); spawn_platform {
			append(&g_mem.platforms, create_plaform())
		}

		for &platform, i in g_mem.platforms {
			update_platform(&platform, dt)

			if platform.rect_top.x < -100.0 {
				unordered_remove(&g_mem.platforms, i)
			}

			if rl.CheckCollisionRecs(platform.rect_top, g_mem.player.rect) ||
			   rl.CheckCollisionRecs(platform.rect_bottom, g_mem.player.rect) {
				g_mem.dead = true
			}

			if rl.CheckCollisionRecs(platform.rect_open, g_mem.player.rect) &&
			   !platform.passed_by {
				g_mem.score += 1
				platform.passed_by = true
			}
		}

		//if rl.CheckCollisionRecs(platof)
	}


	rl.DrawRectangleRec(g_mem.player.rect, g_mem.player.color)
	for platform in g_mem.platforms {
		render_platform(platform)
	}
	rl.DrawRectangleRec(g_mem.ground, g_mem.ground_color)

	buf: [8]byte
	score_str := strconv.itoa(buf[:], g_mem.score)
	rl.DrawText(
		strings.clone_to_cstring(score_str, context.temp_allocator),
		Width / 2,
		50,
		40,
		rl.BLACK,
	)

	if g_mem.dead {
		rl.DrawText("You're ded", Width / 2 - 200, 150, 80, rl.BLACK)
		rl.DrawText("press [Q] to restart", Width / 2 - 125, 250, 30, rl.BLACK)
	}

	rl.EndDrawing()

	free_all(context.temp_allocator)

	return !rl.WindowShouldClose()
}

@(export)
game_shutdown :: proc() {
	delete(g_mem.platforms)
	free_all(context.temp_allocator)
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.Z)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.Q)
}
