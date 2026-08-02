package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"

main :: proc() {

	if len(os.args) <= 1 do return

	switch os.args[1] {
	case "list":
		if !command_list(os.args) {
			fmt.eprintln("Failed to list files!")
			return
		}
	case "read":
		if !command_read(os.args) {
			fmt.eprintln("Failed to read file!")
			return
		}
	}

	free_all(context.temp_allocator)
}


get_file_size_rounded :: proc(size: i64, unit: rune = 'b') -> string {

	if size < 1000 do return fmt.tprintf("{0}{1}", size, unit)

	rounded_unit: rune = ---

	switch unit {
	case 'b':
		rounded_unit = 'k'
	case 'k':
		rounded_unit = 'm'
	case 'm':
		rounded_unit = 'g'
	case 'g':
		rounded_unit = 't'
	case 't':
		rounded_unit = 'p'
	}

	rounded_size := cast(i64)math.round(f32(size) / 1000)
	return get_file_size_rounded(rounded_size, rounded_unit)
}

get_file_permissions_line :: proc(permissions: os.Permissions) -> string {

	line_builder: strings.Builder
	strings.builder_init(&line_builder, context.temp_allocator)


	for permission in os.Permission_Flag {
		if permission not_in permissions {
			strings.write_rune(&line_builder, '-')
			continue
		}

		switch permission {
		case .Execute_Group, .Execute_User, .Execute_Other:
			strings.write_rune(&line_builder, 'x')
		case .Write_Group, .Write_User, .Write_Other:
			strings.write_rune(&line_builder, 'w')
		case .Read_Group, .Read_User, .Read_Other:
			strings.write_rune(&line_builder, 'r')
		}
	}

	return strings.to_string(line_builder)
}
