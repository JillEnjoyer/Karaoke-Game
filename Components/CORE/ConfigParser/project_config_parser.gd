extends Resource
class_name ProjectConfigParser

## Every OffsetController represents a single file thing - video, audio, subtitles, and etc.

## Video, Audio
const media_file_config_example := {
	"file_name": "",
	"file_path": "",
    "type": "",
	"length": 0.0,
	"jumpers": []
}
"""
var jumpers_example := [
    {"Start_from": 0.0}, # Mandatory to declare where to start playing from initially
	{"from_time": 10.0, "to_time": 22.4}, 
	{"from_time": 50.0, "to_time": 75.0},
    {"from_time": 80.0, "to_time": 60.0}, # backwards jump
    {"from_time": 85.0, "to_time": 90.0, "loops_amount": 3, "interrupt_avaliable_after": 2}, # loop can be from 1 (no loop) to -1 (till user interrupts) - avaliable_after reads next line and if it stops player, it interrupts loop
    {"Stop_at": 90.0} # Optional - if not declared, plays till the end of the file reached. Else (if loop declared) plays till player interrupts.
]"""

## Subtitles
const subtitles_file_config_example := {
    "file_name": "",
    "file_path": "",
    "type": "subtitles",
    "length": 0.0,
    "lyrics": []
}
"""
"lyrics": [
    {
        start_time: 0.0,
        end_time: 4.0,
        line: "First comment",
        words: [
            {
                "word": "First",
                "start_time": 0.0,
                "end_time": 0.8
            },
            {
                "word": "comment",
                "start_time": 1.0,
                "end_time": 3.0,
                "subwords": [
                    {
                        "subword": "com",
                        "start_time": 1.0,
                        "end_time": 2.0
                    },
                    {
                        "subword": "ment",
                        "start_time": 2.0,
                        "end_time": 3.0
                    }
                ]
            }
        ]
    }
]
"""

## WIP
const service_file_config_example := {
    "file_name": "",
    "file_path": "",
    "type": "",
    "settings": {}
}

var file_config: Dictionary = {}


# creating real file from config data
# path should be as "sth://folder^n". /filename.ext would be added automatically
func create_config_file(data: Dictionary) -> void:
    var config_file := FileAccess.open(data.get("file_path", "") + "/" + data.get("file_name", "") + ".json", FileAccess.ModeFlags.WRITE)
    if config_file != null:
        config_file.store_var(file_config)
        config_file.close()


func get_config_pathes(project_config_header_path) -> Dictionary:
    var file = FileAccess.open(project_config_header_path, FileAccess.ModeFlags.READ)
    #var files: Dictionary = {}
    if file:
        while not file.eof_reached():
            var line = file.get_line()
            Debugger.info(line)
        file.close()
    return {
        "file_name": file_config.get("file_name", ""),
        "file_path": file_config.get("file_path", "")
    }


## parsing config data from file
func parse_config(data: Dictionary) -> void:
    var file_type = data.get("type", "")
    if file_type == "subtitles":
        file_config = subtitles_file_config_example.duplicate()
    elif file_type == "service":
        file_config = service_file_config_example.duplicate()
    else:
        file_config = media_file_config_example.duplicate()

    for key in file_config.keys():
        if data.has(key):
            file_config[key] = data[key]


func get_config() -> Dictionary:
    return file_config