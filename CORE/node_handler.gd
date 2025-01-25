extends Control

var PREFERENCES: NodePath = ""

func add_child_to_tree(node_link: Node) -> Node:
	if not node_link:
		push_error("Node link is invalid!")
		return null
	
	get_tree().root.add_child(node_link)
	return node_link

func remove_child_from_tree(node_link: Node) -> void:
	if not node_link or not node_link.get_parent():
		push_error("Cannot remove: Node is invalid or has no parent!")
		return
	
	node_link.get_parent().remove_child(node_link)

func cleanup_tree() -> void:
	var root = get_tree().root
	for child in root.get_children():
		root.remove_child(child)
