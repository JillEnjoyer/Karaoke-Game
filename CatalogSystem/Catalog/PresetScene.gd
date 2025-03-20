extends Control

var text_load = texture_loader.new()

@onready var ModeCheckBox = $ModeCheckBox
@onready var AcapellaCheckBox = $AcapellaCheckBox
@onready var NameLbl = $SongNameLbl
@onready var SongIcon = $SongIcon

var EndPath = ""
var Franchise = ""
var Song = ""
var Acapella = ""
var FolderData = {}

func _ready() -> void:
	pass

func _on_back_btn_pressed() -> void:
	self.queue_free()

func _on_start_btn_pressed() -> void:
	var selected_mode = ModeCheckBox.text if ModeCheckBox else ""
	var selected_acapella = AcapellaCheckBox.text if AcapellaCheckBox else ""

	if selected_acapella != "":
		start_karaoke(Franchise, Song, selected_acapella, selected_mode)

func CollectNames(FranchiseName: String, SongName: String):
	Franchise = FranchiseName
	Debugger.debug("PresetScene.gd", "CollectNames()", "FrPath = " + Franchise)
	Song = SongName
	Debugger.debug("PresetScene.gd", "CollectNames()", "SnName = " + Song)
	Init()

func Init():
	ScanFolder()
	ModeCheckBox.text = "Standart"
	AcapellaCheckBox.clear()

	for folder_name in FolderData.keys():
		AcapellaCheckBox.add_item(folder_name)
	
	Debugger.debug("PresetScene.gd", "Init()", EndPath + " / " + Franchise + " / " + Song + " / " + Acapella)
	
	NameLbl.text = Song
	SongIcon.texture = text_load.load_texture(Franchise + "/" + Song + "/" + "Icon.png")

func ScanFolder():
	var path = Franchise + "/" + Song + "/Audio"
	Debugger.info("PresetScene.gd", "ScanFolder()", "Path for scanning = " + path)
	FolderData = {}

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		
		while folder_name != "":
			if dir.current_is_dir():
				FolderData[folder_name] = true
			folder_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		Debugger.debug("PresetScene.gd", "ScanFolder()", "Failed to open folder: " + path)

	Debugger.debug("PresetScene.gd", "ScanFolder()", str(FolderData))

func start_karaoke(franchise: String, song: String, acapella: String, mode: String) -> void:
	Debugger.info("PresetScene.gd", "start_karaoke()", "Karaoke init with data:")
	Debugger.info("PresetScene.gd", "start_karaoke()", "Franchise: " + franchise)
	Debugger.info("PresetScene.gd", "start_karaoke()", "Song: " + song)
	Debugger.info("PresetScene.gd", "start_karaoke()", "Acapella: " + acapella)
	Debugger.info("PresetScene.gd", "start_karaoke()", "Mode: " + mode)
	var playlist = {0: [franchise, song, acapella, mode]}
	UIManager.show_ui("player_scene").import_playlist(playlist)
