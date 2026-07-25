class_name NeighborGrid
extends RefCounted

const MAX_CELL_COUNT: int = 65536

static var _neighbor_column_offsets: PackedInt32Array = PackedInt32Array([1, -1, 0, 1])
static var _neighbor_row_offsets: PackedInt32Array = PackedInt32Array([0, 1, 1, 1])

var _positions: PackedVector2Array = PackedVector2Array()
var _item_count: int = 0
var _origin: Vector2 = Vector2.ZERO
var _inverse_cell_size: float = 1.0
var _column_count: int = 1
var _row_count: int = 1
var _item_cells: PackedInt32Array = PackedInt32Array()
var _item_columns: PackedInt32Array = PackedInt32Array()
var _item_rows: PackedInt32Array = PackedInt32Array()
var _cell_starts: PackedInt32Array = PackedInt32Array()
var _cell_cursors: PackedInt32Array = PackedInt32Array()
var _cell_items: PackedInt32Array = PackedInt32Array()
var _pairs: PackedInt32Array = PackedInt32Array()
var _pair_count: int = 0


func build(positions: PackedVector2Array, cell_size: float) -> void:
	_positions = positions
	_item_count = positions.size()
	_pair_count = 0
	if _item_count == 0:
		return

	var minimum := positions[0]
	var maximum := positions[0]
	for index in range(1, _item_count):
		var position := positions[index]
		minimum.x = minf(minimum.x, position.x)
		minimum.y = minf(minimum.y, position.y)
		maximum.x = maxf(maximum.x, position.x)
		maximum.y = maxf(maximum.y, position.y)

	_origin = minimum
	var extent := maximum - minimum
	var effective_cell_size := maxf(cell_size, 0.001)
	_column_count = _get_axis_cell_count(extent.x, effective_cell_size)
	_row_count = _get_axis_cell_count(extent.y, effective_cell_size)

	while _column_count * _row_count > MAX_CELL_COUNT:
		effective_cell_size *= 2.0
		_column_count = _get_axis_cell_count(extent.x, effective_cell_size)
		_row_count = _get_axis_cell_count(extent.y, effective_cell_size)

	_inverse_cell_size = 1.0 / effective_cell_size

	var cell_count := _column_count * _row_count
	_item_cells.resize(_item_count)
	_item_columns.resize(_item_count)
	_item_rows.resize(_item_count)
	_cell_items.resize(_item_count)
	_cell_starts.resize(cell_count + 1)
	_cell_starts.fill(0)

	var last_column := _column_count - 1
	var last_row := _row_count - 1
	for index in _item_count:
		var position := positions[index]
		var column := clampi(
			int((position.x - _origin.x) * _inverse_cell_size), 0, last_column
		)
		var row := clampi(
			int((position.y - _origin.y) * _inverse_cell_size), 0, last_row
		)
		var cell_index := row * _column_count + column

		_item_columns[index] = column
		_item_rows[index] = row
		_item_cells[index] = cell_index
		_cell_starts[cell_index + 1] += 1

	for cell_index in range(1, cell_count + 1):
		_cell_starts[cell_index] += _cell_starts[cell_index - 1]

	_cell_cursors.resize(cell_count)
	for cell_index in cell_count:
		_cell_cursors[cell_index] = _cell_starts[cell_index]

	for index in _item_count:
		var cell_index := _item_cells[index]
		_cell_items[_cell_cursors[cell_index]] = index
		_cell_cursors[cell_index] += 1


func collect_pairs(max_distance: float) -> void:
	_pair_count = 0
	if _item_count < 2:
		return

	var max_distance_squared := max_distance * max_distance
	if _pairs.size() < 64:
		_pairs.resize(64)

	for a_index in _item_count:
		var a_position := _positions[a_index]
		var a_cell := _item_cells[a_index]
		var a_column := _item_columns[a_index]
		var a_row := _item_rows[a_index]

		var cursor := _cell_starts[a_cell]
		var cell_end := _cell_starts[a_cell + 1]
		while cursor < cell_end:
			var b_index := _cell_items[cursor]
			cursor += 1
			if b_index <= a_index:
				continue

			if a_position.distance_squared_to(_positions[b_index]) >= max_distance_squared:
				continue

			if _pair_count * 2 + 2 > _pairs.size():
				_pairs.resize(_pairs.size() * 2)

			_pairs[_pair_count * 2] = a_index
			_pairs[_pair_count * 2 + 1] = b_index
			_pair_count += 1

		for offset_index in 4:
			var column := a_column + _neighbor_column_offsets[offset_index]
			if column < 0 or column >= _column_count:
				continue

			var row := a_row + _neighbor_row_offsets[offset_index]
			if row < 0 or row >= _row_count:
				continue

			var neighbor_cell := row * _column_count + column
			var neighbor_cursor := _cell_starts[neighbor_cell]
			var neighbor_end := _cell_starts[neighbor_cell + 1]
			while neighbor_cursor < neighbor_end:
				var neighbor_index := _cell_items[neighbor_cursor]
				neighbor_cursor += 1
				if (
					a_position.distance_squared_to(_positions[neighbor_index])
					>= max_distance_squared
				):
					continue

				if _pair_count * 2 + 2 > _pairs.size():
					_pairs.resize(_pairs.size() * 2)

				_pairs[_pair_count * 2] = a_index
				_pairs[_pair_count * 2 + 1] = neighbor_index
				_pair_count += 1


func get_pairs() -> PackedInt32Array:
	return _pairs


func get_pair_count() -> int:
	return _pair_count


func _get_axis_cell_count(extent: float, cell_size: float) -> int:
	return maxi(1, int(extent / cell_size) + 1)
