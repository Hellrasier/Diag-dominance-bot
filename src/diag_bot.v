module main

import os
import dariotarantini.vgram
import diag_matrix
import json

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
	result_message   = 'Your result is:\n'
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

fn handle_update(update vgram.Update) ?string {
	match update.message.text {
		'/start' {
			return start_message
		}
		'/help' {
			return help_message
		}
		else {
			matrix, vector := parse_input(update.message.text) or { return error_message }
			matrix_string, vec_string := diag_matrix.get_result(matrix, vector)
			return result_message + '$matrix_string\n$vec_string'
		}
	}
}

fn main() {
	token := os.getenv('BOT_TOKEN')
	bot := vgram.new_bot(token)
	mut updates := []vgram.Update{}
	mut last_offset := 0
	for {
		updates = bot.get_updates(offset: last_offset, limit: 100)
		for update in updates {
			if last_offset < update.update_id {
				last_offset = update.update_id
				println('Got update from @$update.message.from.username with text:\n$update.message.text')
				message := handle_update(update) or { unexpected_error }
				bot.send_message(
					chat_id: update.message.from.id.str()
					text: message
				)
			}
		}
	}
}
