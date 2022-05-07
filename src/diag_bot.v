module main

import os
import dariotarantini.vgram
import diag_matrix
import json
import time

const (
	start_message = "Hello! I can turn your matrix to diag dominance :)\nPlease, input your matrix and vector using '[' ']', separating it with semicolon, for example:\n\n[[1.0, 0.42, 0.54, 0.66],
[0.42, 1.0, 0.32, 0.44],
[0.44, 0.32, 1.0, 0.22],
[0.66, 0.44, 0.22, 1.0]];
		
[0.3, 0.5, 0.7, 0.9]"

	help_message = "You shuld input your matrix and vector using '[' ']', separating it with semicolon, right like in example:\n\n[[1.0, 0.42, 0.54, 0.66],
[0.42, 1.0, 0.32, 0.44],
[0.44, 0.32, 1.0, 0.22],
[0.66, 0.44, 0.22, 1.0]];
		
[0.3, 0.5, 0.7, 0.9]"
	error_message    = 'Incorrect data in your input, press /help for more info'
	unexpected_error = 'Woops, something went wrong, contact @urrvan if it continiues'
	wait_time        = 100
)

fn parse_input(input string) ?([][]f64, []f64) {
	splited := input.split(';')
	if splited.len != 2 {
		return none
	}
	raw_mtrx := splited[0]
	raw_vec := splited[1]
	parsed_mtrx := json.decode([][]f64, raw_mtrx) or { return none }
	parsed_vec := json.decode([]f64, raw_vec) or { return none }
	return parsed_mtrx, parsed_vec
}

fn handle_update(update vgram.Update, bot vgram.Bot) {
	match update.message.text {
		'/start' {
			bot.send_message(
				chat_id: update.message.from.id.str()
				text: start_message
			)
		}
		'/help' {
			bot.send_message(
				chat_id: update.message.from.id.str()
				text: help_message
			)
		}
		else {
			matrix, vector := parse_input(update.message.text) or {
				bot.send_message(
					chat_id: update.message.from.id.str()
					text: error_message
				)
				return
			}
			matrix_string, vec_string, logs := diag_matrix.get_result(matrix, vector)
			bot.send_message(
				chat_id: update.message.from.id.str()
				text: 'Data recieved, output:'
			)
			for i, log in logs {
				bot.send_message(
					chat_id: update.message.from.id.str()
					text: 'Step ${i + 1}:\n$log'
				)
				time.sleep(wait_time * time.millisecond)
			}
			bot.send_message(
				chat_id: update.message.from.id.str()
				text: 'Your result is:\n' + '$matrix_string\n$vec_string'
			)
		}
	}
}

fn main() {
	token := os.getenv('BOT_TOKEN')
	bot := vgram.new_bot(token)
	mut updates := []vgram.Update{}
	mut last_offset := 0
	for {
		updates = bot.get_updates(offset: last_offset, limit: 10)
		for update in updates {
			if last_offset < update.update_id {
				last_offset = update.update_id
				println('Got update from @$update.message.from.username with text:\n$update.message.text')
				go handle_update(update, bot)
			}
		}
	}
}
