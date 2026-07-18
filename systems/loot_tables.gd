extends Node
## Item-Definitionen und Loot-Verteilung der drei Fuellhorn-Ringe.
## Ring A (im Horn) = Top-Ausruestung, Ring B = Rucksack-Niveau, Ring C = Kleinkram.

const ITEMS := {
	# --- Waffen (Tier A) ---
	"bogen": {"name": "Bogen", "type": "waffe", "damage": 30.0, "color": Color(0.55, 0.35, 0.15)},
	"schwert": {"name": "Schwert", "type": "waffe", "damage": 40.0, "color": Color(0.75, 0.75, 0.8)},
	"speer": {"name": "Speer", "type": "waffe", "damage": 35.0, "color": Color(0.6, 0.5, 0.3)},
	"wurfmesser": {"name": "Wurfmesser-Set", "type": "waffe", "damage": 25.0, "color": Color(0.65, 0.65, 0.7)},
	"axt": {"name": "Axt", "type": "waffe", "damage": 38.0, "color": Color(0.5, 0.3, 0.2)},
	# --- Waffen (kleiner) ---
	"messer": {"name": "Messer", "type": "waffe", "damage": 20.0, "color": Color(0.6, 0.6, 0.65)},
	"kleines_messer": {"name": "Kleines Messer", "type": "waffe", "damage": 14.0, "color": Color(0.55, 0.55, 0.6)},
	# --- Verbrauch ---
	"medikit": {"name": "Medizin-Kit", "type": "medizin", "heal": 60.0, "color": Color(0.9, 0.2, 0.2)},
	"verband": {"name": "Verband", "type": "medizin", "heal": 25.0, "color": Color(0.9, 0.6, 0.6)},
	"trockenfleisch": {"name": "Trockenfleisch", "type": "essen", "nutrition": 40.0, "color": Color(0.5, 0.25, 0.15)},
	"brot": {"name": "Brot", "type": "essen", "nutrition": 30.0, "color": Color(0.8, 0.65, 0.4)},
	"apfel": {"name": "Apfel", "type": "essen", "nutrition": 15.0, "color": Color(0.4, 0.75, 0.3)},
	"wasserflasche": {"name": "Wasserflasche", "type": "wasser", "hydration": 45.0, "color": Color(0.3, 0.55, 0.9)},
	# --- Ausruestung (Phase 2+: Funktion) ---
	"schlafsack": {"name": "Schlafsack", "type": "ausruestung", "color": Color(0.3, 0.4, 0.3)},
	"seil": {"name": "Seil", "type": "ausruestung", "color": Color(0.7, 0.6, 0.4)},
	"jod": {"name": "Jodflasche", "type": "ausruestung", "color": Color(0.5, 0.3, 0.5)},
	"plane": {"name": "Plane", "type": "ausruestung", "color": Color(0.4, 0.45, 0.5)},
}

## Ring-Tabellen: Item-Pools und Anzahl der Spawns pro Partie.
const RING_A := {"pool": ["bogen", "schwert", "speer", "wurfmesser", "axt", "medikit", "schlafsack"], "count": 10, "radius_min": 3.0, "radius_max": 8.0}
const RING_B := {"pool": ["messer", "trockenfleisch", "wasserflasche", "verband", "seil", "jod", "speer"], "count": 14, "radius_min": 12.0, "radius_max": 24.0}
const RING_C := {"pool": ["kleines_messer", "brot", "apfel", "wasserflasche", "plane"], "count": 16, "radius_min": 28.0, "radius_max": 48.0}

func get_item(id: String) -> Dictionary:
	var item: Dictionary = ITEMS[id].duplicate()
	item["id"] = id
	return item

## Liefert [{id, position}, ...] fuer alle drei Ringe (Fuellhorn am Ursprung).
func roll_bloodbath_loot(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	for ring in [RING_A, RING_B, RING_C]:
		for i in ring.count:
			var angle := rng.randf() * TAU
			var radius := rng.randf_range(ring.radius_min, ring.radius_max)
			spawns.append({
				"id": ring.pool[rng.randi() % ring.pool.size()],
				"position": Vector3(cos(angle) * radius, 0.0, sin(angle) * radius),
			})
	return spawns
