extends Node

const SAVE_PATH := "user://savegame.dat"

# =====================
# DATOS GUARDADOS
# =====================
var coins := 0
var high_score := 0

var owned_skins := ["default"]
var selected_skin := "default"

var owned_pets := []
var equipped_pet := ""

# =====================
# GUARDAR
# =====================
func save():
	var data = {
		"coins": coins,
		"high_score": high_score,
		"owned_skins": owned_skins,
		"selected_skin": selected_skin,
		"owned_pets": owned_pets,
		"equipped_pet": equipped_pet
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)
	file.close()

# =====================
# CARGAR
# =====================
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()

	coins = data.get("coins", 0)
	high_score = data.get("high_score", 0)
	owned_skins = data.get("owned_skins", ["default"])
	selected_skin = data.get("selected_skin", "default")
	owned_pets = data.get("owned_pets", [])
	equipped_pet = data.get("equipped_pet", "")
