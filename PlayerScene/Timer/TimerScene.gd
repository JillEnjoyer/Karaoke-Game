extends Control

@onready var TimeLbl = $TimeLbl
@onready var TimerNode = $Timer  # Предположим, что Timer это твой таймер элемент

# Получаем значение из глобального скрипта
var countdown_time = Core.get_node("PreferencesData").getData("countdown_time")

signal ready_to_start

func _ready() -> void:
	# Устанавливаем длительность таймера
	TimerNode.wait_time = countdown_time
	TimerNode.one_shot = true  # Таймер сработает только один раз
	TimerNode.connect("timeout", Callable(self, "_on_Timer_timeout"))  # Подключаем сигнал
	TimerNode.start()  # Запускаем таймер
	TimeLbl.text = str(int(countdown_time))  # Отображаем начальное время

func _process(delta: float) -> void:
	# Обновляем метку времени каждый кадр
	var remaining_time = TimerNode.time_left
	TimeLbl.text = str(int(remaining_time))

# Функция вызывается, когда таймер завершает отсчет
func _on_Timer_timeout() -> void:
	print("Timer finished, removing scene")
	# Удаляем сцену
	self.queue_free()
	# Отправляем сигнал в PlayerScene
	emit_signal("ready_to_start")
