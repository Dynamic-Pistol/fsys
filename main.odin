package main

import "core:flags"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import "core:time"

main :: proc() {

	if len(os.args) <= 1 do return

	switch os.args[1] {
	case "list":
		opt: ListFilesOptions
		if len(os.args) > 2 {
			err := flags.parse(&opt, os.args[2:], .Unix, true, true, context.temp_allocator)
			if help, help_ok := err.(flags.Help_Request); help_ok {
				flags.write_usage(os.to_writer(os.stdout), ListFilesOptions, os.args[0], .Unix)
				return
			}
			else if err != nil do return
		}
		list_files(opt)
	}

	free_all(context.temp_allocator)
}

//List files

ListFilesOptions :: struct {
	show_hidden: bool `args:"name=all" usage:" Show all files"`,
	show_long:   bool `args:"name=extra" usage:" Show more info"`,
	// show_help:   bool `args:"name=help" usage:" Show this menu"`,
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

list_files :: proc(options: ListFilesOptions) -> os.Error {
	directory := os.get_working_directory(context.temp_allocator) or_return
	walker := os.walker_create_path(directory)
	defer os.walker_destroy(&walker)

	if options.show_long do fmt.println("Permissions | Size | Modified Date | File Name")
	for file in os.walker_walk(&walker) {

		if strings.starts_with(file.name, ".") && !options.show_hidden {
			os.walker_skip_dir(&walker)
			continue
		}

		if options.show_long {
			fmt.printfln(
				"%v | %v |  %v-%v-%v | %v",
				strings.centre_justify(
					get_file_permissions_line(file.mode),
					11,
					" ",
					context.temp_allocator,
				),
				strings.centre_justify(
					get_file_size_rounded(file.size),
					4,
					" ",
					context.temp_allocator,
				),
				time.date(file.modification_time),
				file.name,
			)
		} else do fmt.printfln("%#v", file.name)

		if os.is_directory(file.fullpath) {
			os.walker_skip_dir(&walker)
			continue
		}
	}

	return nil
}
