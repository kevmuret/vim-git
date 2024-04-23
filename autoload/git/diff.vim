function git#diff#buffer_versus(...) abort
	let l:file_path = expand('%')
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
	let l:nlines = len(l:text)
	if l:nlines && l:text[l:nlines-1] == ''
		let l:text = l:text[0:l:nlines-2]
	endif
	call append(0, l:text)
	delete
	setlocal noma
	difft
endfunction
