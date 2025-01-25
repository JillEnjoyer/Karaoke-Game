extends Control

@onready var catalog_path = load("res://CatalogSystem/CatalogV2.gd")

var catalog1 = catalog_path.instantiate()
var catalog2 = catalog_path.instantiate()

func _ready() -> void:
	pass

func _on_catalog_ready_1(catalog):
	# Реакция для первого подокна
	print("Catalog 1 is ready")

func _on_catalog_ready_2(catalog):
	# Реакция для второго подокна
	print("Catalog 2 is ready")

func _catalogInstantiate(Index: int):
	if Index == 1:
		add_child(catalog1)
		catalog1.connect("catalog_ready", self, "_on_catalog_ready_1")  # Подключаем сигнал для первого каталога
	elif Index == 2:
		add_child(catalog2)
		catalog2.connect("catalog_ready", self, "_on_catalog_ready_2")  # Подключаем сигнал для второго каталога
	else:
		print("Number is not 1 or 2")


#func _DeleteFromScene(): # After Making new Catalog old one must be deleted from memory to save space
	
