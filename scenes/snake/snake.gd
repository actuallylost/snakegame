extends TileMap
class_name Snake

# The timer node.
@onready var timer = $"../Timer"

# The score label.
@onready var score_label = $"../BoxContainer/ScoreLabel"
# The game over label.
@onready var game_over_label = $"../BoxContainer/GameOverLabel"
# The Retry button.
@onready var retry_button = $"../BoxContainer/RetryButton"

# Snake's movement timer in seconds.
@export var wait_time: float = 0.3

# Layer IDs
const BG_LAYER: int = 0
const SNEK_LAYER: int = 1

# Boundary rectangle.
var bounds: Rect2i = Rect2i(0, 0, 48, 27)

# Boundary center.
var bounds_center = bounds.get_center()

# Food spawn point
var spawn_point: Vector2i
var food_type: int

# Snake's head positions.
var snake_head_pos: Vector2i = Vector2i(bounds_center.x, bounds_center.y)
var last_snake_head_pos: Vector2i

# Snake's tile positions.
var snake_tail_pos: Array[Vector2i] = [Vector2i(snake_head_pos.x, snake_head_pos.y + 1), Vector2i(snake_head_pos.x, snake_head_pos.y + 2)]
var last_snake_tail_pos: Vector2i

# Snake's input direction.
var input_dir: Vector2 = Vector2.ZERO

# Snake's current direction
var current_dir: Vector2 = Vector2.UP

# Player score.
var score: int

func _ready():
	# draw tiles
	for x in range(0, bounds.size.x):
		for y in range(0, bounds.size.y):
				# draw black tile
				set_cell(BG_LAYER, Vector2i(x, y), 0, Vector2i(2, 0))

	# snake head
	set_cell(SNEK_LAYER, snake_head_pos, 1, Vector2i(0, 0))
	# snake tail
	for pos in snake_tail_pos:
		set_cell(SNEK_LAYER, pos, 2, Vector2i(0, 0))
	# spawn food
	spawn_food()
	
	timer.wait_time = wait_time
	timer.start()

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.is_action("Quit"):
			get_tree().quit()
			return

		var next_direction: Vector2

		if event.is_action("Down"):
			next_direction = Vector2.DOWN
		elif event.is_action("Up"):
			next_direction = Vector2.UP
		elif event.is_action("Left"):
			next_direction = Vector2.LEFT
		else:
			next_direction = Vector2.RIGHT

		input_dir = next_direction

func _on_timer_timeout():
	# check if snake head has left tile area
	if !bounds.has_point(snake_head_pos):
		game_over(str("YOU TRIED TO LEAVE THE MAP! YOU HAD A SCORE OF ", score, "."))
		print("you went out of bounds!")

	last_snake_head_pos = snake_head_pos
	last_snake_tail_pos = snake_tail_pos[-1]
	# set next snake head position
	if input_dir != Vector2.ZERO and !check_opposite(current_dir, input_dir):
		current_dir = input_dir
	snake_head_pos += Vector2i(current_dir)
	# iterate backwards over the array and update tile positions
	for i in range(snake_tail_pos.size() - 1, -1, -1):
		if i == 0:
			snake_tail_pos[i] = last_snake_head_pos
		else:
			snake_tail_pos[i] = snake_tail_pos[i - 1]
	
	# check if snake head is trying to move to a tail tile
	if snake_tail_pos.has(snake_head_pos):
		game_over(str("YOU TRIED TO EAT YOUR OWN TAIL! YOU HAD A SCORE OF ", score, "."))
		print("you fell into your own tail!")
	
	if snake_head_pos == spawn_point:
		if food_type == 0:
			score += 1
			timer.wait_time = max(timer.wait_time * 0.95, 0.01)
		else:
			score += 3
			timer.wait_time = max(timer.wait_time * 0.85, 0.01)
		snake_tail_pos.append(last_snake_tail_pos)
		score_label.text = str("SCORE: ", score)
		spawn_food()

	# clear trailing tail
	erase_cell(SNEK_LAYER, last_snake_tail_pos)

	# move snake tail (before head to make sure head is rendered on top of tail)
	for pos in snake_tail_pos:
		set_cell(SNEK_LAYER, pos, 2, Vector2i(0, 0))
	# move snake head
	set_cell(SNEK_LAYER, snake_head_pos, 1, Vector2i(0, 0))

func _on_retry_button_pressed():
	get_tree().reload_current_scene()

## Checks whether two directions are opposite
func check_opposite(prev_direction: Vector2, next_direction: Vector2):
	return prev_direction.dot(next_direction) == -1

## Spawns food randomly on the empty tiles
func spawn_food():
	# food atlas x coord (0 or 1)
	food_type = randi() % 2
	# generate random vector with x and y within bounds
	spawn_point = Vector2i(randi_range(bounds.position.x, bounds.size.x - 1), randi_range(bounds.position.y, bounds.size.y - 1))
	print(spawn_point)
	# check if spawn point is occupied by head or tail
	if snake_head_pos == spawn_point or snake_tail_pos.has(spawn_point):
		return

	set_cell(1, spawn_point, 0, Vector2i(food_type, 0))

func game_over(text: String):
	game_over_label.text = text
	score_label.visible = false
	game_over_label.visible = true
	retry_button.visible = true
	get_tree().paused = true
