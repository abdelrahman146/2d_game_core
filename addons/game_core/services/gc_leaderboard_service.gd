extends GCService
class_name GCLeaderboardService
## Generic leaderboard interface. Implement a subclass for your backend
## (Firebase, Supabase, custom REST, etc.).

signal score_submitted(board_id: String, success: bool)
signal scores_fetched(board_id: String, scores: Array)


func submit_score(_board_id: String, _player_id: String, _score: int, _extra: Dictionary = {}) -> void:
	push_warning("GCLeaderboardService: submit_score not implemented. Provide a backend subclass.")


func get_top_scores(_board_id: String, _count: int = 10) -> Array:
	push_warning("GCLeaderboardService: get_top_scores not implemented.")
	return []


func get_player_rank(_board_id: String, _player_id: String) -> int:
	push_warning("GCLeaderboardService: get_player_rank not implemented.")
	return -1
