extends Node
class_name SystemInfo

"""
### For future ###
var ram_amount := 0
var disk_space := {}
"""

func gather_system_info() -> Dictionary:
	var os = OS.get_name()
	var cpu_cores = OS.get_processor_count()
	var gpu_name = RenderingServer.get_video_adapter_name()
	var gpu_vendor = RenderingServer.get_video_adapter_vendor()
	
	Debugger.debug("CPU Cores: " + str(cpu_cores) + 
	" GPU: ", gpu_name + " by: ", gpu_vendor)
	
	return {
		"OS": os,
		"cpu_cores": cpu_cores, 
		"gpu_name": gpu_name,
		"gpu_vendor": gpu_vendor
	}
