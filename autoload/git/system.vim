if !exists("g:git_bin_path")
	let g:git_bin_path = 'git'
endif

function git#system#call(cmd_options)
	return system(g:git_bin_path.' '.a:cmd_options)
endfunction
function git#system#call_list(cmd_options)
	return systemlist(g:git_bin_path.' '.a:cmd_options)
endfunction

