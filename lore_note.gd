extends Node3D

@export_category("Configurações da Nota")
@export_multiline var text_content: String = "Escreva o texto da lore aqui..."
@export var is_already_in_cabin: bool = false # Marque isso apenas na nota que fica DENTRO da cabana!

@export_category("Conexão (Opcional)")
@export var cabin_twin_note: Node3D # Arraste a nota da cabana pra cá!

# Função que o seu InteractionComponent deve chamar quando o jogador clicar na nota
func read_note() -> void:
	# 1. Abre o papel na tela do jogador com o texto
	Global.open_note_ui.emit(text_content)
	
	# 2. Se ela for a nota da floresta, executa a rotina de envio
	if not is_already_in_cabin:
		
		# Liga a nota gêmea que estava escondida na cabana
		if cabin_twin_note:
			cabin_twin_note.visible = true
			# Se você usar colisão para interação, lembre de religar a colisão dela aqui!
			var col = cabin_twin_note.get_node_or_null("CollisionShape3D")
			if col: col.disabled = false
			
		# Manda a notificação avisando
		Global.show_notification.emit("Nota encontrada! Ela foi enviada para a cabana.")
		
		# Destrói a nota da floresta
		queue_free()
