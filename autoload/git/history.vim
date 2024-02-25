function git#history#at_line(start_linenr, end_linenr, file_path) abort
	call git#commit#popup_menu('-L'.a:start_linenr.','.a:end_linenr.':'.a:file_path, 'show')
endfunction
function git#history#file(file_path) abort
	call git#commit#popup_menu('-- '.a:file_path, 'show')
endfunction
