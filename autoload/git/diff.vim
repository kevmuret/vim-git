function git#diff#buffer_versus(...) abort
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
endfunction
function git#diff#list_all(refname='HEAD') abort
	let l:lines = git#system#call_list('diff '.a:refname)
	let l:entries = []
	let l:entry = {}
	let l:linenum = 0
	let l:del_linenum = 0
	let l:del_nlines = 0
	for l:line in l:lines
		let l:first_char = matchstr(l:line, '^.')
		if l:first_char == 'd'
			if exists('l:entry["type"]')
				call add(l:entries, copy(l:entry))
			endif
			let l:entry = {}
			let l:entry['filename'] = matchlist(l:line, '^[^ ]\+ [^ ]\+ a/\([^ ]\+\)')[1]
		elseif l:first_char == '@'
			let l:linenum_infos = matchlist(l:line, '^@@\(\( [+-]\d\+,\d\+\)*\)')
			if len(l:linenum_infos) > 0
				let l:linenum = 0
				let l:del_linenum = 0
				let l:del_nlines = 0
				for l:linenum in split(l:linenum_infos[1][1:], ' ')
					let l:infos = matchlist(l:linenum, '\([+-]\)\(\d\+\),\(\d\+\)')
					if l:infos[1] == '+'
						let l:linenum = str2nr(l:infos[2]) - 1
						break
					endif
				endfor
			endif
		elseif l:first_char == '-'
			if l:del_linenum == 0
				let l:del_linenum = l:linenum
				let l:del_nlines = 0
			endif
			let l:del_nlines += 1
		elseif l:first_char == '+'
			let l:entry['type'] = 'A'
			if l:del_nlines && l:linenum >= l:del_linenum
				let l:entry['type'] = 'M'
				let l:del_nlines -= 1
			endif
			let l:entry['lnum'] = l:entry['type'] == 'A' ? l:linenum : l:linenum + 1
			let l:linenum += 1
		elseif l:first_char == ' '
			if l:linenum == l:del_linenum && l:del_nlines
				let l:entry['type'] = 'D'
				let l:entry['lnum'] = l:linenum == 0 ? 1 : l:linenum
			endif
			if exists('l:entry["type"]')
				call add(l:entries, copy(l:entry))
				unlet l:entry['type']
			endif
			let l:linenum += 1
		endif
	endfor
	if exists('l:entry["type"]')
		call add(l:entries, copy(l:entry))
	endif
	call setqflist(l:entries, 'r')
endfunction
