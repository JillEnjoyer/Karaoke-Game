extends Control

# Экспортируем переменные для установки значений
@export var song_title: String
@export var about_title: String
@export var album_art: Texture
@export var background: Texture

# Ссылки на элементы интерфейса
@onready var title_label = $NameLbl
@onready var about_label = $AboutLbl
@onready var icon_rect = $Thumb
@onready var background_rect = $Background

func _ready():
	# Устанавливаем значения
	title_label.text = song_title
	about_label.text = about_title
	icon_rect.texture = album_art
	background_rect.texture = background
