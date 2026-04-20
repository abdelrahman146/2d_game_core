extends Resource
class_name GCChunkData
## Metadata describing a single chunk for procedural/streaming world sources.
## Used by GCStreamChunkSource and GCChunkSelector for smart chunk selection.

## The scene to instantiate for this chunk.
@export var scene: PackedScene

## Category identifier (e.g., &"falling_boxes", &"drones", &"gates").
@export var category: StringName = &""

## Difficulty rating from 0.0 (easiest) to 1.0 (hardest).
@export var difficulty: float = 0.0

## Length of this chunk in pixels along the scroll axis.
@export var length: float = 320.0

## If true, this chunk is a non-challenge connector/rest chunk.
@export var is_connector: bool = false

## Freeform tags for filtering (e.g., &"has_walls", &"no_platforms").
@export var tags: Array[StringName] = []

## Categories that are valid predecessors for this chunk.
## Empty means any chunk can precede it.
@export var connects_from: Array[StringName] = []

## Categories that are valid successors for this chunk.
## Empty means any chunk can follow it.
@export var connects_to: Array[StringName] = []
