package main 

import rl "vendor:raylib" 
import "core:math/rand"
import "core:fmt"

GRID_SIZE := Vector2 { 10, 7 }
FRAMES_BETWEEN_UPDATE: i32 = 30
SNAKE_COLOR := rl.GREEN
APPLE_COLOR := rl.RED
DEFAULT_SNAKE_POSITION: Vector2 = {
  0,
  0,
}

Game :: struct {
  window: Window,
  row_distance: i32,
  column_distance: i32,
  snake: Snake,
  current_apple: Vector2,
  tick_number: i32,
  game_over: bool,
}

Window :: struct {
  width: i32,
  height: i32,
}

Snake :: struct {
  current_direction: Direction,
  head_position: Vector2,
  segments: [dynamic]Vector2,
}

Direction :: enum {
  Up,
  Down,
  Right,
  Left,
}

Vector2 :: struct {
  x: i32,
  y: i32,
}

main :: proc() {
  game := Game {
    Window {
      800,
      600,
    },
    0,
    0,
    Snake {
      Direction.Right,
      DEFAULT_SNAKE_POSITION,
      [dynamic]Vector2 {},
    },
    Vector2 {
      0, // game.column_distance * rand.int31_max(GRID_SIZE.x),
      0, // game.row_distance * rand.int31_max(GRID_SIZE.y),
    },
    0,
    false,
  }

  game.row_distance = game.window.width / GRID_SIZE.x 
  game.column_distance = game.window.height / GRID_SIZE.y

  game.current_apple = random_position(game) 

  rl.InitWindow(game.window.width, game.window.height, "Snake") 

  rl.SetTargetFPS(60)

  for !rl.WindowShouldClose() {
    // Update
    if game.game_over {
      draw_game_over() 

      if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
	game.snake.segments = [dynamic]Vector2 {}
	game.snake.head_position = DEFAULT_SNAKE_POSITION 
	game.snake.current_direction = Direction.Right
	game.current_apple = random_position(game) 
	game.tick_number = 0
	game.game_over = false
      }
    }

    if rl.IsKeyDown(rl.KeyboardKey.D) {
      game.snake.current_direction = Direction.Right	
    }

    if rl.IsKeyDown(rl.KeyboardKey.A) {
      game.snake.current_direction = Direction.Left	
    }

    if rl.IsKeyDown(rl.KeyboardKey.W) {
      game.snake.current_direction = Direction.Up	
    }

    if rl.IsKeyDown(rl.KeyboardKey.S) {
      game.snake.current_direction = Direction.Down	
    }

    if game.tick_number == FRAMES_BETWEEN_UPDATE && !game.game_over {
      // Update snake segments  
      segments_number := len(game.snake.segments)
      for i := segments_number - 1; i >= 0; i -= 1 {
	if i == 0 {
	  game.snake.segments[i] = game.snake.head_position
	} else {
	  game.snake.segments[i] = game.snake.segments[i - 1]// + 1] 
	}
      }

      new_position: Vector2 = { 0, 0 }
      // This code is an absolute mess, i don't know what that does and i will never know, good luck figuring it out! 
      switch game.snake.current_direction {
	case .Right:
	  new_position = { game.snake.head_position.x + game.row_distance, game.snake.head_position.y }
	  if new_position.x >= game.column_distance * (GRID_SIZE.x - 1) {
	    new_position.x = 0
	  }
	case .Left: 
	  new_position = { game.snake.head_position.x - game.row_distance, game.snake.head_position.y }
	  if new_position.x < 0 {
	    new_position.x = (GRID_SIZE.x - 1) * game.row_distance 
	  }

	case .Down:
	  new_position = { game.snake.head_position.x, game.snake.head_position.y + game.column_distance }
	  if new_position.y >= game.column_distance * GRID_SIZE.y {
	    new_position.y = 0
	  }

	case .Up:
	  new_position = { game.snake.head_position.x, game.snake.head_position.y - game.column_distance }
	  if new_position.y < 0 {
	    new_position.y = (GRID_SIZE.y - 1) * game.column_distance
	  }
      }

      for segment in game.snake.segments {
	if new_position == segment {
	  game.game_over = true 
	}
      }

      game.snake.head_position = new_position
      game.tick_number = 0
    }

    // Check if player ate the apple 
    if game.snake.head_position == game.current_apple {
      game.current_apple = Vector2 { 
	game.row_distance * rand.int31_max(GRID_SIZE.x),
	game.column_distance * rand.int31_max(GRID_SIZE.y),
      }

      append(&game.snake.segments, game.snake.head_position) 
    }

    rl.BeginDrawing()
      // Draw
      rl.ClearBackground(rl.WHITE);

      draw_grid(game)

      draw_snake(game)
      draw_apple(game)
    rl.EndDrawing()

    game.tick_number += 1
  }
}

draw_grid :: proc(game: Game) {
  for x: i32 = 0; x < GRID_SIZE.x; x += 1 {
    rl.DrawLine(game.row_distance * x, 0, game.row_distance * x, game.window.height, rl.BLACK)  
  } 

  for y: i32 = 0; y < GRID_SIZE.y; y += 1 {
    rl.DrawLine(0, game.column_distance * y, game.window.width, game.column_distance * y, rl.BLACK)    
  } 
}

draw_snake :: proc(game: Game) {
  for piece in game.snake.segments {
    rl.DrawRectangle(piece.x, piece.y, game.row_distance, game.column_distance, rl.BLUE)
  }

  rl.DrawRectangle(game.snake.head_position.x, game.snake.head_position.y, game.row_distance, game.column_distance, SNAKE_COLOR)
}

draw_apple :: proc(game: Game) { 
  rl.DrawRectangle(game.current_apple.x, game.current_apple.y, game.row_distance, game.column_distance, APPLE_COLOR)
}

draw_game_over :: proc() {
  game_over_text: cstring = "Game Over\nPress space to retry"
  font_size: i32 = 25

  font_measure: i32 = rl.MeasureText(game_over_text, font_size)
  rl.DrawText(game_over_text, (rl.GetScreenWidth() / 2) - font_measure / 2, 250, font_size, rl.BLACK)
}

random_position :: proc(game: Game) -> Vector2 {
  result := Vector2 {
    game.row_distance * rand.int31_max(GRID_SIZE.x), 
    game.column_distance * rand.int31_max(GRID_SIZE.y),
  }

  if game.snake.head_position == result {
    return random_position(game)
  }

  return result
}
















