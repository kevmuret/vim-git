function git#diff#buffer_versus(...) abort
	let l:save_cursor = getcurpos()
	let l:save_winnr = winnr()
	let l:file_path = git#utils#get_git_relative_path(expand('%'))
	if len(a:000) == 0
		let l:rev = 'HEAD'
	else
		let l:rev = a:000[0]
	endif
	difft
	new
	setlocal buftype=nofile
	setlocal nobuflisted
	call win_splitmove(winnr(), winnr() + 1, {'vertical': v:true})
	execute 'file '.l:rev.'/'.l:file_path
	filetype detect
	let l:text = git#system#call_list('show '.l:rev.':'.l:file_path)
	call git#ui#buf_puttext(l:text)
	delete
	setlocal noma
	difft
	call win_gotoid(win_getid(l:save_winnr + 1))
	call setpos('.', l:save_cursor)
endfunction
function git#diff#list_all(...) abort
	if len(a:000) == 0
		let l:rev = 'HEAD'
	else
		let l:rev = a:000[0]
	endif
	let l:lines = git#system#call_list('diff -u '.l:rev)
	let l:parser_state = git#parser#diff#init()
	let l:Parser_fn = funcref('git#parser#diff#parse_file', [l:parser_state])
	for l:line in l:lines
		let l:Parser_fn = l:Parser_fn(l:line)
	endfor
	call git#parser#diff#end(l:parser_state)
	for l:diff in l:parser_state['difflist']
		let l:diff['text'] = l:diff['nlines'].'L | '.l:diff['text']
	endfor
	call setqflist(l:parser_state['difflist'], 'r')
endfunction
