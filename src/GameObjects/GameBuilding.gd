class_name GameBuilding
extends Area2D

# the index of the player who owns this building
export var player_num := 0

var is_defense_building: bool
var is_resource_building: bool

var placeable := false
# set to true when we enter an area which is NOT a territory
# ie, it is another building
var in_non_territory_area := false
# set by Map.gd
# ensures we only process this for the thing we just selected and are moving around, nothing else
var newly_spawned := false

func _ready() -> void:
	connect("area_entered", self, "_on_area_entered")
	connect("area_exited", self, "_on_area_exited")
	Signals.connect("game_building_selected", self, "_on_game_building_selected")

func _on_area_entered(area):
	if not newly_spawned:
		return

	var child = area.get_child(0)
	if child is Territory:
		if is_resource_building:
			# we just entered a resource territory
			if child.type == Enums.territory_types.resource:
				# and we're not touching a building
				if not in_non_territory_area:
					placeable = true
			# not a resource territory
			else:
				placeable = false
		elif is_defense_building:
			# we just entered a normal territory
			if child.type == Enums.territory_types.normal:
				# and we're not touching a building
				if not in_non_territory_area:
					placeable = true
			# not a normal territory
			else:
				placeable = false
	# not a territory; some building or whatever
	else:
		in_non_territory_area = true
		placeable = false


func _on_area_exited(area):
	if not newly_spawned:
		return

	# if we exit a resource territory, we would normally want to set plcaeable to false
	# but if we entered a new resoruce territory, we don't want to do that
	# so we check for that
	var child_node = area.get_child(0)
	# if we just exited a territory
	if child_node is Territory:
		if is_resource_building:
			# only go ahead if we just exited a resource territory
			if child_node.type == Enums.territory_types.resource:
				validate_new_territory(area)
		elif is_defense_building:
			# only go ahead if we just exited a normal territory
			if child_node.type == Enums.territory_types.normal:
				validate_new_territory(area)
	# if we just exited an area and it wasn't a territory
	else:
		# we're probably no longer intneractng with a non-territory area
		in_non_territory_area = false
		# but we might have exited the building into a resource/normal territory
		# so we need to re-validate
		validate_new_territory(area)


func validate_new_territory(area):
	# get all the areas we're inside of
	var areas = get_overlapping_areas()
	# remove the area we just exited from
	areas.erase(area)
	for a in areas:
		var child = a.get_child(0)
		if child is Territory:
			if is_resource_building:
				# if we're in another resource territory, we're good
				if child.type == Enums.territory_types.resource:
					placeable = true
				# we r in a non-resource territory
				else:
					placeable = false
			elif is_defense_building:
				# if we're in another normal territory, we're good
				if child.type == Enums.territory_types.normal:
					placeable = true
				# we r in a non-normal territory
				else:
					placeable = false
		# if the area is not a Territory, it's something else
		# say it's not placeable and quit
		else:
			in_non_territory_area = true
			placeable = false
			return

	# if the list is empty, we're in the ocean. heck nah
	if areas.size() == 0:
		placeable = false


func _on_game_building_selected(scene_path, building):
	player_num = PlayersManager.whoami().num
