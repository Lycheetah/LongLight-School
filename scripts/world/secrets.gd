extends RefCounted
## Secret discovery helpers — false walls, digs, switches, collectibles.


static func wall_key(area: String, x: int, y: int) -> String:
	return "fw:%s:%d:%d" % [area, x, y]


static func dig_key(area: String, x: int, y: int) -> String:
	return "dig:%s:%d:%d" % [area, x, y]


static func col_key(area: String, x: int, y: int) -> String:
	return "col:%s:%d:%d" % [area, x, y]


static func switch_key(area: String, id: String) -> String:
	return "sw:%s:%s" % [area, id]
