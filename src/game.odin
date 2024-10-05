package game

import "core:fmt"
import rl "vendor:raylib"

_ :: fmt

Game_Memory :: struct {
	ground:       rl.Rectangle,
	ground_color: rl.Color,
	player:       Player,
}

g_mem: ^Game_Memory

Width :: 1280
Height :: 720

//--------player related
Player :: struct {
	rect:  rl.Rectangle,
	color: rl.Color,
	vel:   f32,
}

JumpHeight :: 200.0
JumpTime :: .5

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

	g_mem^ = Game_Memory {
		ground       = rl.Rectangle{0.0, Height - 100.0, Width, 100.0},
		ground_color = rl.LIME,
		player       = player,
	}

	game_hot_reloaded(g_mem)
}

@(export)
game_update :: proc() -> bool {
	dt := rl.GetFrameTime()

	rl.BeginDrawing()
	rl.ClearBackground(rl.SKYBLUE)

	update_player(&g_mem.player, dt)

	rl.DrawRectangleRec(g_mem.ground, g_mem.ground_color)
	rl.DrawRectangleRec(g_mem.player.rect, g_mem.player.color)

	rl.EndDrawing()
	return !rl.WindowShouldClose()
}

@(export)
game_shutdown :: proc() {
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
