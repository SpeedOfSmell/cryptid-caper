class_name ChunkLibrary
extends Resource

@export var types: Array[ChunkType]

func pick_chunk(chunk_type: StringName, can_double_jump: bool, can_dash: bool, remaining_difficulty_budget: int, rng: RandomNumberGenerator) -> ChunkTemplate:
	for type: ChunkType in types:
		if type.type_name == chunk_type:
			var available_templates: Array[ChunkTemplate] = []
			for template: ChunkTemplate in type.templates:
				# Exclude templates that require abilities the player does not have.
				if not can_double_jump and template.requires_double_jump:
					continue
				if not can_dash and template.requires_dash:
					continue
				available_templates.append(template)

			assert(not available_templates.is_empty(), "Chunk type has no templates available for the player's abilities")

			# Always keep a difficulty-1 option when the budget is exhausted. If a
			# type has no difficulty-1 variant, fall back to its easiest variant.
			var difficulty_limit := maxi(remaining_difficulty_budget, 1)
			var affordable_templates: Array[ChunkTemplate] = []
			for template: ChunkTemplate in available_templates:
				if template.difficulty <= difficulty_limit:
					affordable_templates.append(template)

			if affordable_templates.is_empty():
				var easiest_difficulty := available_templates[0].difficulty
				for template: ChunkTemplate in available_templates:
					easiest_difficulty = mini(easiest_difficulty, template.difficulty)
				for template: ChunkTemplate in available_templates:
					if template.difficulty == easiest_difficulty:
						affordable_templates.append(template)

			return _pick_weighted_template(affordable_templates, rng)
	
	assert(false, "Attempted to get a chunk type that does not exist")
	return null

func _pick_weighted_template(templates: Array[ChunkTemplate], rng: RandomNumberGenerator) -> ChunkTemplate:
	var total_weight := 0.0
	for template: ChunkTemplate in templates:
		total_weight += 1.0 / maxf(float(template.difficulty), 1.0)

	var roll := rng.randf() * total_weight
	for template: ChunkTemplate in templates:
		roll -= 1.0 / maxf(float(template.difficulty), 1.0)
		if roll < 0.0:
			return template

	return templates.back()
