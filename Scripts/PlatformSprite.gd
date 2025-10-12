extends Sprite2D

var original_scale: Vector2
var adjusted_region_size: Vector2

func _ready():
	# 確保 Sprite2D 已經有賦予紋理（Texture）
	if texture == null:
		print("錯誤：Sprite2D 沒有賦予紋理！無法設定 Region。")
		return

	# 1. 記錄原始縮放比例
	original_scale = scale
	print("原始縮放比例: %s" % original_scale)

	# 2. 計算考慮縮放後的渲染矩形尺寸
	var rendered_width = get_rect().size.x * original_scale.x
	var rendered_height = get_rect().size.y * original_scale.y
	print("渲染尺寸: %.2f x %.2f" % [rendered_width, rendered_height])
	
	# 3. 調整區域尺寸以補償將要設定的 scale = 1
	# 新的區域尺寸 = 原始區域尺寸 * 原始縮放比例
	adjusted_region_size = Vector2(rendered_width, rendered_height)
	
	# 5. 將縮放比例設為 1，但視覺大小保持不變
	scale = Vector2.ONE
	
	print("縮放已正規化為 1，區域尺寸已調整為: %d x %d" % [int(adjusted_region_size.x), int(adjusted_region_size.y)])
	_random_update_region()
	
	# 初始化碰撞形狀
	_update_collision_shape()

func _random_update_region():
	"""隨機更新區域位置，但保持相同尺寸"""
	if texture == null:
		return
	
	# 獲取紋理尺寸
	var texture_size = texture.get_size()
	
	# 計算可用的隨機範圍（確保不會超出紋理邊界）
	var max_x = max(0, int(texture_size.x - adjusted_region_size.x))
	var max_y = max(0, int(texture_size.y - adjusted_region_size.y))
	
	if max_x <= 0 or max_y <= 0:
		print("警告：紋理太小，無法進行隨機區域更新")
		return
	
	# 隨機選擇新的起始位置
	var new_x = randi() % (max_x + 1)
	var new_y = randi() % (max_y + 1)
		
	# 更新區域（保持相同尺寸）
	region_rect = Rect2(new_x, new_y, int(adjusted_region_size.x), int(adjusted_region_size.y))

func _update_collision_shape():
	"""更新碰撞形狀以匹配當前的區域尺寸"""
	var floor_collision = $Floor/CollisionShape2D
	if floor_collision == null:
		print("警告：找不到 Floor/CollisionShape2D 節點")
		return
	
	var new_shape := RectangleShape2D.new()
	new_shape.size = Vector2(adjusted_region_size.x, adjusted_region_size.y)
	floor_collision.shape = new_shape

	print("碰撞形狀已更新為: %.2f x %.2f" % [adjusted_region_size.x, adjusted_region_size.y])
