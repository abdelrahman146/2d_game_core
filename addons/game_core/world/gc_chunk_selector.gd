extends Resource
class_name GCChunkSelector
## Base chunk selection strategy. Subclass to implement weighted, archetype-aware,
## or rule-based chunk selection for procedural streaming.
##
## Override select_next() to control which chunk appears next.
## Override filter_pool() to narrow candidates before selection.

## Select the next chunk from the available pool.
## [param pool]: All chunks registered in the source (challenge or connector as appropriate).
## [param history]: Array of category StringNames of recently spawned chunks (most recent last).
## [param context]: Dictionary with runtime info — keys include:
##   "elapsed_time" (float), "chunks_spawned" (int), "difficulty_cursor" (float 0-1),
##   "last_category" (StringName), "last_was_connector" (bool).
## Returns: The selected GCChunkData, or null if nothing is valid.
func select_next(pool: Array, history: Array[StringName], context: Dictionary) -> Resource:
	var filtered := filter_pool(pool, history, context)
	if filtered.is_empty():
		filtered = pool
	if filtered.is_empty():
		return null
	return filtered[randi() % filtered.size()]


## Filter the pool to valid candidates based on history and context.
## Default: filters by connection rules (connects_from/connects_to).
func filter_pool(pool: Array, history: Array[StringName], _context: Dictionary) -> Array:
	if history.is_empty():
		return pool
	var last_cat: StringName = history.back()
	var result: Array = []
	for chunk in pool:
		if chunk == null:
			continue
		# Check if this chunk accepts the previous category
		var from_arr: Array[StringName] = chunk.connects_from
		if not from_arr.is_empty() and not from_arr.has(last_cat):
			continue
		result.append(chunk)
	return result
