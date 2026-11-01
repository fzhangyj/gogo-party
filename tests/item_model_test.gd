extends SceneTree

var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var roots: Array[Node3D] = []
	for item in range(CourseData.ITEMS.size()):
		var root_item := ToyFactory.item_model(parent, item, Color(CourseData.ITEMS[item].color))
		roots.append(root_item)
		check(root_item.name == "ItemModel_%d" % item, "item %d has named model root" % item)
		check(root_item.get_child_count() >= 3, "item %d is a multi-part model" % item)
		var mesh_count := 0
		for child in root_item.get_children():
			if child is MeshInstance3D:
				mesh_count += 1
		check(mesh_count >= 2, "item %d has multiple visible meshes" % item)
	check(roots[0].get_child_count() != roots[1].get_child_count(), "soda and bubble have distinct silhouettes")
	check(roots[1].get_child_count() != roots[5].get_child_count(), "bubble and rewind have distinct silhouettes")
	check(roots[2].get_child_count() != roots[4].get_child_count(), "spring and feather have distinct silhouettes")
	print("ITEM MODEL RESULT: %d checks, %d failures" % [checks, failures.size()])
	for message in failures: print(message)
	parent.queue_free()
	await process_frame
	ToyFactory.materials.clear()
	quit(0 if failures.is_empty() else 1)
