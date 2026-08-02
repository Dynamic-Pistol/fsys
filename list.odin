package main

import "core:flags"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"


command_list :: proc(args: []string) -> bool {
	opt: ListFilesOptions
	if len(os.args) > 2 {
		err := flags.parse(&opt, os.args[2:], .Unix, true, true, context.temp_allocator)
		if help, help_ok := err.(flags.Help_Request); help_ok {
			flags.write_usage(os.to_writer(os.stdout), ListFilesOptions, os.args[0], .Unix)
			return true
		} else if err != nil do return false
	}
	list_files(opt)
	return true
}

ListFilesOptions :: struct {
	show_hidden: bool `args:"name=all" usage:" Show all files"`,
	show_long:   bool `args:"name=extra" usage:" Show more info"`,
	// show_help:   bool `args:"name=help" usage:" Show this menu"`,
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
