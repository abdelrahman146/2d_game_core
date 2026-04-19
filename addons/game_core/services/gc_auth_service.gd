extends GCService
class_name GCAuthService
## Generic auth interface. Implement a subclass for your backend.

signal signed_in(user: Dictionary)
signal signed_out
signal auth_error(message: String)

var current_user: Dictionary = {}
var is_signed_in := false


func sign_in(_provider: String, _credentials: Dictionary = {}) -> bool:
	push_warning("GCAuthService: sign_in not implemented.")
	return false


func sign_out() -> void:
	current_user = {}
	is_signed_in = false
	signed_out.emit()


func get_current_user() -> Dictionary:
	return current_user
