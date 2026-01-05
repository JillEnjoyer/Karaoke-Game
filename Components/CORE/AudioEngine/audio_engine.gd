extends Node
class_name AudioEngine

## Singletone
##
## AudioEngine is responsible for managing and maintaning All the input and output devices to stream audio to the many different devices at the same time.
## Engine itself cannot adress more than one Input and Output at the time. This class helps to surpass it.
##
## It works all the time but each time config changes, it reloads completely to free all used memory.
## Even if only 1 mic and speaker used, this package will be active to simplify input/output pipeline.
##
## All the sound effects would be applied on the raw audio stream and will be transfered through AudioEngine


var process_id := -1

## All avaliable audio devices: Mics and Speakers
func get_device_list() -> Dictionary: 
    ## Get All devices that can be possibly microphones
    
    return {}


func start_process(speakers_id: Dictionary, microphones_id: Dictionary) -> void:
    var exe_path =  PreferencesData.get_ext_path("audio_engine") #"audio_engine.exe"
    var args = [
        "--rate", "48000",
        "--block", "256",
        "--in_devices", "3", "5",
        "--out_devices", "10", "11"
    ]

    process_id = OS.create_process(exe_path, args)

    Debugger.debug("AudioEngine PID:" + str(process_id))


func _exit_tree() -> void:
    if process_id != -1:
        if OS.is_process_running(process_id):
            OS.kill(process_id)
        else:
            Debugger.warning("AudioEngine already exited")
