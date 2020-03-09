extends Control

export(int) var id: int = 17
var state = "hide"
var done:bool = false

signal clicked(id)

func _ready() -> void:
	randomize()
	# Altera o frame da carta, colocando qual a carta atual
	$front.frame = id
	
	# timer para mostrar a carta quando entra no tabuleiro
	yield(get_tree().create_timer(randf()), "timeout")
	$anim.play("start")

func _on_touch_pressed() -> void:
	# Não deixa clicar novamente se essa carta já tiver seu par
	if done: return
	# Se ainda não pode jogar novamente então não deixa clicar
	if !get_node("../../")._can_play(): return
	# Se a animação da carta estiver sendo executada então não deixa clicar
	if $anim.is_playing(): return
	# Se a carta está virada, então deixa clicar
	if state == 'hide':
		emit_signal("clicked", id)
		_show()

func _hide() -> void:
	# Esconde a carta novamente, criamos um timer apenas para ter uma randomização nos movimentos
	yield(get_tree().create_timer(randf() / 8), "timeout")
	state = 'hide'
	$anim.play_backwards("show")

func _show() -> void:
	# mostra a carta
	state = 'show'
	$anim.play("show")
	$sfx.play()

func _set_done(_state):
	# marca essa carta como concluída, ou seja, foi encontrado um par pra ela
	done = _state
	# Deixa ela um pouco transparente
	modulate.a = .5
