class_name Leaderboard extends VBoxContainer

@export var id: String

@onready var entry_container: VBoxContainer = $ScrollContainer/LeaderboardEntries
@onready var entry_scene: PackedScene = load("res://scenes/ui/leaderboard/leaderboard_entry.tscn")

var entry_lookup: Dictionary = {}
var entry_nodes: Array[LeaderboardEntry] = []
var entries: Array = []

func get_file_name():
	return "user://leaderboard/" + id + ".leaderboard.json"

func load():
	var file = FileAccess.open(get_file_name(), FileAccess.READ)
	if file == null:
		print("No leaderboard exists yet for " + id)
		save()
		return
	
	if file.get_position() >= file.get_length():
		printerr("Empty leaderboard for " + id)
		return
	
	var json_leaderboard = file.get_as_text(true)
	var json = JSON.new()
	var parse_result = json.parse(json_leaderboard)
	if not parse_result == OK:
		printerr("Failed to parse leaderboard \"", id, "\", error at line ", json.get_error_line(), ": ", json.get_error_message())
		return
		
	entry_lookup = json.get_data()
	rebuild_entries()
	
func rebuild_entries():
	var entries: Array = []
	for key in entry_lookup.keys():
		var entry_data = entry_lookup[key]
		entries.push_back([key, entry_data.points, entry_data.updated])

	entries.sort_custom(compare_entries)
	
	var entry_count = min(10, entries.size())
	
	var container_children = entry_container.get_children()
	while container_children.size() > entry_count:
		var last_child = container_children.pop_back()
		entry_container.remove_child(last_child)
		last_child.queue_free()

	while container_children.size() < entry_count:
		var new_entry: LeaderboardEntry = entry_scene.instantiate()
		new_entry.name = "entry" + str(container_children.size())
		container_children.push_back(new_entry)
		entry_container.add_child(new_entry)

	for index in range(0, entry_count):
		var entry = entries[index]
		var node: LeaderboardEntry = container_children[index]
		entry_nodes.push_back(node)
		node.number = index + 1
		node.entry_name = entry[0]
		node.points = entry[1]

static func compare_entries(a: Array, b: Array):
	if a[1] > b[1]:
		return true
	
	return a[1] == b[1] and a[2] < b[2]

func save():
	ensure_save_directory()

	var file_name = get_file_name()
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	
	if file == null:
		printerr("Failed to create \"", file_name, "\": ", FileAccess.get_open_error())
	var json = JSON.new()
	var json_leaderboard = json.stringify(self.entry_lookup)
	file.store_string(json_leaderboard)

# Called when the node enters the scene tree for the first time.
func _ready():
	#entry_container.remove_child(entry_container.get_child(0))
	self.load()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_points(name: String, num_points: int = 1, save = true):
	var entry = entry_lookup.get_or_add(name, {
		"points": 0,
		"updated": 0
	})
	entry.points += num_points
	entry.updated = Time.get_unix_time_from_system()

	if save:
		save()

	rebuild_entries()

static func ensure_save_directory():
	if not DirAccess.dir_exists_absolute("user://leaderboard"):
		DirAccess.make_dir_absolute("user://leaderboard")
