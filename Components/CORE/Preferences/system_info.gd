extends Node
class_name SystemInfo

var os := ""
var cpu_cores := 0
var gpu_name := ""
var gpu_vendor := ""
var ram_amount := 0
var disk_space := {}


func _init() -> void:
	os = OS.get_name()
	cpu_cores = OS.get_processor_count()
	gpu_name = RenderingServer.get_video_adapter_name()
	gpu_vendor = RenderingServer.get_video_adapter_vendor()
	ram_amount = 4096#OS.get_static_memory_usage() / (1024 * 1024) # in MB
	disk_space = {"device0": 1024, "device1": 512}#OS.get_total_space() / (1024 * 1024 * 1024) # in GB


func gather_system_info() -> Dictionary:
	return {
		"OS": os,
		"cpu_cores": cpu_cores, 
		"gpu_name": gpu_name,
		"gpu_vendor": gpu_vendor,
		"ram_amount": ram_amount,
		"disk_space": disk_space
	}
