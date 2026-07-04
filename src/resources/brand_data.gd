class_name BrandData
extends Resource

## WWJMD Brand Data — Custom Resource
## Stage 2: Lead Game Architect

@export var brand_name: String = "Generic"
@export var product_texture: Texture2D = null
@export var container_class: String = "box"   # box / bag / can / bottle
@export var destruction_class: String = "debris"  # debris / liquid

func get_description() -> String:
	return "%s (%s, %s)" % [brand_name, container_class, destruction_class]
