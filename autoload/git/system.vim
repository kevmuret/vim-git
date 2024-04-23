function git#system#call(cmd_options)
	return system(g:git_cmd_path.' '.a:cmd_options)
endfunction
function git#system#call_list(cmd_options)
	return systemlist(g:git_cmd_path.' '.a:cmd_options)
endfunction

