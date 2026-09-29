class_name Wire
extends RefCounted
## Signal connection with its Error checked, so no call site discards it.


static func link(sig: Signal, callable: Callable) -> void:
	if sig.connect(callable) != OK:
		push_error("could not connect %s" % sig.get_name())


## Resize a packed array, failing loudly instead of discarding the Error.
static func sized_bytes(count: int) -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	if data.resize(count) != OK:
		push_error("could not allocate %d bytes" % count)
	return data


static func sized_ints(count: int, fill: int) -> PackedInt32Array:
	var data: PackedInt32Array = PackedInt32Array()
	if data.resize(count) != OK:
		push_error("could not allocate %d ints" % count)
	data.fill(fill)
	return data
