extends Node3D

## Size of every manga is 20x15 or 21x14 for every block. Page width = 0.008 cm

## Internal variables
var front_page: Texture2D = null
var back_page: Texture2D = null
var front_back_page: Texture2D = null
var current_page: Texture2D = null

var left_block_height: float = 0.0
var right_block_height: float = 0.0


var page_index: int = 0


## External dependencies
#var manga_parser := MangaParser.new()
var manga_page_canvas: CanvasLayer = null


func init(manga_path: String) -> void:
    pass
