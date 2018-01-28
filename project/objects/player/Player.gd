extends RigidBody2D

#Import other scripts
const WallTile = preload("res://objects/WallTile/WallTile.tscn")
const TileHelper = preload("res://lib/TileHelper.gd")

#Keep track of the player state
enum _PlayerState {
	GROUND,
	JUMP,
	WALL,
	DEAD,
}
var _state = _PlayerState.GROUND

#The direction the player is facing (i.e. will jump to the LEFT)
enum _PlayerDirection {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}
var _facing = _PlayerDirection.RIGHT
var _rising = _PlayerDirection.UP

#Map out the sprites for now
#TODO: Figure out a better way? Especially if 'skins' will exist...
var _player_sprites = {
	_PlayerState.GROUND: preload("res://objects/Player/player_ground.png"),
	[_PlayerState.JUMP, _PlayerDirection.UP]: preload("res://objects/Player/player_jump_up.png"),
	[_PlayerState.JUMP, _PlayerDirection.DOWN]: preload("res://objects/Player/player_jump_down.png"),
	[_PlayerState.WALL, _PlayerDirection.UP]: preload("res://objects/Player/player_wall_up.png"),
	[_PlayerState.WALL, _PlayerDirection.DOWN]: preload("res://objects/Player/player_wall_down.png"),
}


#Grab some nodes
onready var sprite = get_node("./Sprite")

#Some player variables
const _jump_vector = Vector2(200, -100)
var previous_jump_direction = 1

var player_color = TileHelper.Tiles.SAFE

func _ready():
	# Called every time the node is added to the scene.

	# Initialization here
	set_process(true)
	set_process_input(true)
	pass

func _process(delta):
	#No angular velocity allowed
	set_angular_velocity(0)

	_update_player_state()

	#Update the sprite
	_set_sprite()


#TODO: Instead of calling every frame should we instead subscribe to an event or something?
func _update_player_state():
	#Are we moving up or down?
	_rising = _PlayerDirection.DOWN
	if get_linear_velocity().y < 0:
		_rising = _PlayerDirection.UP

#TODO: Instead of calling every frame should we instead subscribe to an event or something?
func _set_sprite():
	#First, check if we in a neutral position
	var target_sprite
	if _player_sprites.has(_state):
		#We use this
		target_sprite = _player_sprites[_state]
	else:
		#Use a composite
		var state_key = [_state, _rising]
		if _player_sprites.has(state_key):
			#We use this sprite instead
			target_sprite = _player_sprites[state_key]
	
	#Were we able to find a good sprite?
	if target_sprite:
		sprite.set_texture(target_sprite)

	pass

func _jump():

	#Can we jump

	#Which way do we jump
	previous_jump_direction *= -1
	var jump_direction = Vector2(previous_jump_direction, 1)

	#Make the jump
	var offset = Vector2(0, 0)
	var impulse = _jump_vector * jump_direction

	#Reset the physics for the next jump and apply the jump
	set_linear_velocity(Vector2(0, 0))
	apply_impulse(offset, impulse)

	#Update the state info
	_state = JUMP
	_facing = _PlayerDirection.RIGHT
	if previous_jump_direction < 0:
		_facing = _PlayerDirection.LEFT

func _color_mismatch(mismatched_color):
	print("DEAD BECAUSE ", mismatched_color)

#Process input events AFTER the GUI has had a chance to consume it
func _unhandled_input(event):

	#TODO: Should there be an input map singleton or just use the strings?
	_handle_jump_input(event)

	pass

func _handle_jump_input(event):
	
	#Was it a jump event?
	if event.is_action_pressed("player_jump"):
		#Make it do the jump
		_jump()

func _on_Player_body_entered(body):
	#We hit something. What was it?
	_handle_tile_collision(body)

func _handle_tile_collision(body):
	#Was this body a tile?
	if body.get_type() == WallTile:
		#We need to get it's color
		var tile_color = body.tile_type
		if !TileHelper.TilesMatch(player_color, tile_color):
			_color_mismatch(tile_color)
