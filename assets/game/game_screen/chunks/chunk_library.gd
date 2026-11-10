class_name ChunkLibrary
extends Resource

@export var types: Array[ChunkType]

func pick_chunk(chunk_type: StringName, can_double_jump: bool, can_dash: bool, remaining_difficulty_budget: int, max_unlocked_difficulty: int, rng: RandomNumberGenerator) -> ChunkTemplate:
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

			var difficulty_cap := maxi(max_unlocked_difficulty, 1)
			var unlocked_templates: Array[ChunkTemplate] = []
			for template: ChunkTemplate in available_templates:
				if template.difficulty <= difficulty_cap:
					unlocked_templates.append(template)
			assert(not unlocked_templates.is_empty(), "Chunk type has no template at or below the room's unlocked difficulty")

			# The room budget can run out, but the easiest unlocked variant remains available.
			var difficulty_limit := mini(maxi(remaining_difficulty_budget, 1), difficulty_cap)
			var affordable_templates: Array[ChunkTemplate] = []
			for template: ChunkTemplate in unlocked_templates:
				if template.difficulty <= difficulty_limit:
					affordable_templates.append(template)

			if affordable_templates.is_empty():
				var easiest_difficulty := unlocked_templates[0].difficulty
				for template: ChunkTemplate in unlocked_templates:
					easiest_difficulty = mini(easiest_difficulty, template.difficulty)
				for template: ChunkTemplate in unlocked_templates:
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
