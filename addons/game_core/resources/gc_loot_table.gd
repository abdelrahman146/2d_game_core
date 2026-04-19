extends Resource
class_name GCLootTable
## Defines what items/rewards drop from an entity.
## Each entry has a scene, weight, and optional count.

@export var entries: Array[Dictionary] = []
## Each entry: { "scene": PackedScene, "weight": float, "min_count": int, "max_count": int }


func roll(count: int = 1) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var total_weight := _total_weight()
	if total_weight <= 0.0:
		return results
	for _i in range(count):
		var roll_value := randf() * total_weight
		var accumulated := 0.0
		for entry in entries:
			accumulated += float(entry.get("weight", 1.0))
			if roll_value <= accumulated:
				var min_c: int = entry.get("min_count", 1)
				var max_c: int = entry.get("max_count", 1)
				results.append({
					&"scene": entry.get("scene"),
					&"count": randi_range(min_c, max_c),
				})
				break
	return results


func _total_weight() -> float:
	var total := 0.0
	for entry in entries:
		total += float(entry.get("weight", 1.0))
	return total
