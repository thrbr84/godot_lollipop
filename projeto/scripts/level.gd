extends Node2D

onready var cardScene = preload("res://scenes/card.tscn")
onready var comboScene = preload("res://scenes/combo.tscn")

var cards:Array = [0,1,2,3,4,5,6,7,9,10,11,12,13,14,15,16]

var card_per_level:Array = [4,8,16,32]
var col_per_level:Array = [2,4,8,8]
var time_per_level:Array = [30,60,120,240]

var points:int = 50
var pointsOver:int = 25

var card_opened:Array = []
var face_cards:int = 0
var endgame:bool = false
var combo:int = 0
var total:int = 0
var level:int = 1
var time:int = 0

onready var screenSize:Vector2 = get_viewport_rect().size

func _ready() -> void:
	randomize()
	_new_game()

func _on_btnExit_pressed() -> void:
	loader.goto_scene("res://scenes/main.tscn")

func _game_over() -> void:
	$sfxGameover.play()
	$ui/msg_box/title.text = "Ahh!!\nVocê perdeu!"
	$ui/timer.text = ""
	_clear_cards()
	$timer.stop()
	$ui/msg_box.show()
	
	yield($sfxGameover, "finished")
	endgame = true

func _can_play():
	if card_opened.size() < 2:
		return true
	else:
		return false
	
func _next_level():
	if level == card_per_level.size():
		_win_game()
	else:
		level += 1
		_new_game()

func _win_game():
	level = 0
	$ui/points.text = ""
	$ui/msg_box/title.text = str("Parabéns!!!\nVocê ganhou!\n",total, " pts")
	$ui/msg_box.show()
	_clear_cards()
	$sfxWin.play()
	$timer.stop()
	total = 0
	
	yield($sfxWin, "finished")
	endgame = true

func _mark_card(_id) -> void:
	for c in get_tree().get_nodes_in_group("card"):
		# procura no meu deck a carta
		if c.id == _id:
			# marca ela como concluída
			c._set_done(true)

func _clear_cards() -> void:
	# removo todas as instancias das cartas do deck
	for c in get_tree().get_nodes_in_group("card"):
		c.queue_free()

func _on_timer_timeout() -> void:
	var horas = floor(time / 3600);
	var minutos = floor((time - (horas * 3600)) / 60);
	var segundos = floor(time % 60);
	
	if minutos < 10:
		minutos = str("0",minutos)
	if segundos < 10:
		segundos = str("0",segundos)
	
	$ui/timer.text = str(minutos, ":", segundos)
	
	time -= 1
	if time <= 0:
		$timer.stop()
		_game_over()

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and endgame:
			# Se o jogo tiver terminado, e o jogador clicar na tela, sai para o menu
			_on_btnExit_pressed()
			
			
"""
REGRAS DO JOGO DA MEMÓRIA ABAIXO
--------------------------------------------------
"""


func _new_game() -> void:
	$background.texture = load(str("res://assets/backgrounds/bg_",( (randi() % 6) + 1 ),".jpg")) 
	# reset das variaveis
	face_cards = 0
	card_opened.clear()
	combo = 0
	time = time_per_level[level - 1]
	_clear_cards()
		
	var qtd_cards = card_per_level[level - 1]
	# Embaralho as opções para utilizar
	cards.shuffle()
	
	var deck = []
	for i in range(qtd_cards / 2): # idivido por 2 porque as outras duas vão ser duplicadas
		# duplico as cartas
		deck.append(cards[i])
		deck.append(cards[i])
	
	# embaralho meu deck
	deck.shuffle()
	
	var col = 0
	var row = 0
	var cardWidth = null
	# faço um loop no meu deck para instanciar as cartas
	for c in deck:
		var card = cardScene.instance()
		card.id = c # aqui informo qual a carta que vai aparecer
		card.add_to_group("card") # adiciona essa carta em um grupo
		card.connect("clicked", self, "_on_card_click")
		$cards.add_child(card)
		card.rect_position.x = col * (card.rect_size.x + 35)
		card.rect_position.y = row * (card.rect_size.y + 35)
		
		if cardWidth == null:
			cardWidth = card.rect_size
		
		# quebro as cartas por coluna e linha
		col += 1
		if col == col_per_level[level - 1]:
			col = 0
			row += 1
	
	# centralizo as cartas de acordo com a quantidade do level
	# e ajusto o tamanho delas para quanto mais cartas, menor o tamanho
	var scl = .8 - (level / 10.0)
	$cards.scale = Vector2(scl, scl)
	$cards.position.x = (screenSize.x / 2) - (col_per_level[level - 1] * ((cardWidth.x + 35) * scl) / 2)
	
	var rr = card_per_level[level - 1] / col_per_level[level - 1]
	$cards.position.y = (screenSize.y / 2) - (rr * ((cardWidth.y + 35) * scl) / 2) + 80

func _on_card_click(_id) -> void:
	# quando é clicado em uma carta
	
	# marca essa carta como aberta colocando ela no array de cartas abertas
	card_opened.append(_id)
	
	# Se já tenho duas cartas abertas
	if card_opened.size() == 2:
		# Vertifico se as duas são iguais
		if card_opened[0] == card_opened[1]:
			# confirmo para o jogador que ele acertou
			$sfxRight.play()
			face_cards += 2 # apenas somo quantas quartas ele acertou
			combo += 1 # somo o combo
			total += (points * combo) # multiplico a pontuação
			$ui/points.text = str(total)
			_mark_card(_id) # marco a carta como concluída
			card_opened.clear() # limpo as cartas abertas
			
			# Se fez combo, faço um efeito de combo no header
			if combo > 1:
				var cb = comboScene.instance()
				cb.get_node('combo').text = str(combo, "x")
				cb.global_position = $combox.global_position
				$ui.add_child(cb)
			
			# Se na fase atual, ele já acertou todas as cartas
			# avança para o próximo level
			if card_per_level[level - 1] == face_cards:
				yield(get_tree().create_timer(1), "timeout")
				_next_level()
		
		# Se as cartas viradas não forem iguais
		else:
			combo = 0 # quabra o combo, zerando ele
			
			total -= pointsOver # perde pontos
			if total <= 0:
				total = 0
				if level > 1:
					# Se zerar a pontução do level 2 em diante, GAME OVER
					_game_over()
			$ui/points.text = str(total)
			
			# jogada errada, vira as cartas
			yield(get_tree().create_timer(1), "timeout")
			for c in get_tree().get_nodes_in_group("card"):
				# verifica as cartas viradas no deck, e que não estão concluídas
				if c.state == 'show' and !c.done:
					# vira a carta
					c._hide()
			# limpa as cartas abertas
			card_opened.clear()
