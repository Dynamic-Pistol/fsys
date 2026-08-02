package main

import "core:flags"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

command_read :: proc(args: []string) -> bool {
	// opt: ListFilesOptions
	if len(args) > 2 {
		// err := flags.parse(&opt, args[2:], .Unix, true, true, context.temp_allocator)
		// if help, help_ok := err.(flags.Help_Request); help_ok {
		// flags.write_usage(os.to_writer(os.stdout), ListFilesOptions, args[0], .Unix)
		// return true
		// } else if err != nil do return false

	}
	read_file(slice.last(args))
	return true
}

ReadFileOptions :: struct {}

read_file :: proc(file_path: string) {
	data, read_err := os.read_entire_file_from_path(file_path, context.temp_allocator)
	if read_err != nil {
		fmt.eprintln(read_err)
		return
	}
	fmt.println(strings.clone_from_bytes(data, context.temp_allocator))
}
