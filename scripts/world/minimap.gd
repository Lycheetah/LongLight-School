extends Control
## Corner minimap — Pokémon town-map energy.

var world: Node = null


func _ready() -> void:
	custom_minimum_size = Vector2(136, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if world == null or world.tiles.is_empty():
		return
	var rw := size.x - 8.0
	var rh := size.y - 8.0
	var aw: int = world.area_w
	var ah: int = world.area_h
	var sx := rw / float(maxi(1, aw))
	var sy := rh / float(maxi(1, ah))
	draw_rect(Rect2(0, 0, size.x, size.y), Color("0a0812ee"))
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("f0d080"), false, 2.0)
	for y in ah:
		for x in aw:
			var t: int = int(world.tiles[y][x])
			var c := Color("1a3020")
			match t:
				AreaData.T_WALL, AreaData.T_TREE:
					c = Color("2a2040")
				AreaData.T_PATH, AreaData.T_FLOOR, AreaData.T_FLOOR2, AreaData.T_DOOR:
					c = Color("5a4a78")
				AreaData.T_WATER:
					c = Color("2a5a90")
				AreaData.T_TALL, AreaData.T_GRASS:
					c = Color("2a6038")
				AreaData.T_WARP:
					c = Color("00d4ff")
				AreaData.T_SHRINE, AreaData.T_ALTAR:
					c = Color("f0d080")
			draw_rect(Rect2(4 + x * sx, 4 + y * sy, maxf(1.0, sx), maxf(1.0, sy)), c)
	var px: float = world.player.global_position.x / 32.0
	var py: float = world.player.global_position.y / 32.0
	draw_circle(Vector2(4 + px * sx, 4 + py * sy), 2.8, Color("f0d080"))
	draw_circle(Vector2(4 + px * sx, 4 + py * sy), 4.0, Color("00d4ff"), false, 1.0)
