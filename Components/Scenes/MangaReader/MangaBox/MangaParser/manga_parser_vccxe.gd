## manga_parser_vccxe.gd
extends Node
class_name MangaParserVCCXE


func parse_manga_file(file_path: String) -> Dictionary:
    var manga_data = {}

    if FileAccess.file_exists(file_path):
        var file := FileAccess.open(file_path, FileAccess.READ)
        var vccxe_data = file.get_as_text()
        file.close()
        
        manga_data = parse_vccxe_data(vccxe_data)
    else:
        Debugger.warning("File not found: " + file_path)
    
    return manga_data


func parse_vccxe_data(vccxe_data: String) -> Dictionary:
    var manga_data = {}


    return manga_data