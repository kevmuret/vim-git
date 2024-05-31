function git#parser#diff#init(filename=v:null, callback=v:null) abort
	return {
		\ 'filename': a:filename,
		\ 'offset': 0,
		\ 'old_offset': 0,
		\ 'old_linenum': 0,
		\ 'old_length': 0,
		\ 'new_offset': 0,
		\ 'new_linenum': 0,
		\ 'new_length': 0,
		\ 'del_nlines': 0,
		\ 'add_nlines': 0,
		\ 'diff_nlines': 0,
		\ 'del_lines': [],
		\ 'add_lines': [],
		\ 'callback': a:callback,
		\ 'difflist': [],
	\ }
endfunction
function git#parser#diff#parse_file(state, line) abort
	let l:type = matchstr(a:line, '^\(diff \|index \|new \|--- \|+++ \|@@ \)')
	if l:type == '+++ '
		let a:state['filename'] = strpart(a:line, 6)
	elseif l:type == '@@ '
		return git#parser#diff#parse_diff(a:state, a:line)
	endif
	return funcref('git#parser#diff#parse_file', [a:state])
endfunction
function s:DiffAddEntry(state, lnum, nlines, type, text) abort
	let l:lnum = max([1, a:lnum])
	if type(a:state['callback']) == type(v:null)
		call add(a:state['difflist'], {
			\ 'filename': a:state['filename'],
			\ 'lnum': l:lnum,
			\ 'nlines': a:nlines,
			\ 'type': a:type,
			\ 'text': trim(strpart(a:text, 1))
		\ })
	else
		call a:state['callback'](a:state['filename'], l:lnum, a:nlines, a:type)
	endif
endfunction
function git#parser#diff#parse_diff(state, line) abort
	let l:type = matchstr(a:line, '^\(diff \|@@ \|+\|-\| \)')
	if l:type == ''
		throw 'Invalid diff line: '.a:line
	endif
	if l:type == 'diff '
		call git#parser#diff#end_file(a:state)
		return git#parser#diff#parse_file(a:state, a:line)
	elseif l:type == '@@ '
		let l:linenum_infos = matchlist(a:line, '^@@ -\(\d\+\),\(\d\+\) +\(\d\+\),\(\d\+\)')
		if len(l:linenum_infos) == 0
			throw 'Invalid diff line: '.a:line
		endif
		let l:old_offset = str2nr(l:linenum_infos[1])
		let l:old_linenum = str2nr(l:linenum_infos[1])
		let l:old_length = str2nr(l:linenum_infos[2])
		let l:new_offset = str2nr(l:linenum_infos[3])
		let l:new_linenum = str2nr(l:linenum_infos[3])
		let l:new_length = str2nr(l:linenum_infos[4])
		let a:state['offset'] = l:new_offset
		let a:state['old_offset'] = l:old_offset
		let a:state['old_linenum'] = l:old_linenum
		let a:state['old_length'] = l:old_length
		let a:state['new_offset'] = l:new_offset
		let a:state['new_linenum'] = l:new_linenum
		let a:state['new_length'] = l:new_length
		let a:state['del_nlines'] = 0
		let a:state['add_nlines'] = 0
		let a:state['diff_nlines'] = l:new_length + l:old_length
	elseif l:type == '-'
		call add(a:state['del_lines'], a:line)
		let a:state['old_linenum'] += 1
		let a:state['del_nlines'] += 1
		let a:state['diff_nlines'] -= 1
	elseif l:type == '+'
		call add(a:state['add_lines'], a:line)
		let a:state['new_linenum'] += 1
		let a:state['add_nlines'] += 1
		let a:state['diff_nlines'] -= 1
	elseif l:type == ' '
		if a:state['del_nlines']
			if a:state['add_nlines']
				let l:delta = a:state['add_nlines'] - a:state['del_nlines']
				if l:delta > 0
					call s:DiffAddEntry(
						\ a:state,
						\ a:state['offset'],
						\ a:state['del_nlines'],
						\ 'M',
						\ a:state['add_lines'][0]
					\ )
					call s:DiffAddEntry(
						\ a:state,
						\ a:state['offset'] + a:state['del_nlines'],
						\ l:delta,
						\ 'A',
						\ a:state['add_lines'][a:state['del_nlines']]
					\ )
				elseif l:delta == 0
					call s:DiffAddEntry(
						\ a:state,
						\ a:state['offset'],
						\ a:state['del_nlines'],
						\ 'M',
						\ a:state['add_lines'][0]
					\ )
				else
					if a:state['add_nlines'] != 1
						call s:DiffAddEntry(
							\ a:state,
							\ a:state['offset'],
							\ a:state['add_nlines'],
							\ 'M',
							\ a:state['add_lines'][0]
						\ )
					endif
					call s:DiffAddEntry(
						\ a:state,
						\ a:state['offset'] + a:state['add_nlines'] - 1,
						\ abs(l:delta),
						\ 'DM',
						\ a:state['del_lines'][a:state['add_nlines']]
					\ )
				endif
				let a:state['offset'] += a:state['add_nlines']
				let a:state['add_nlines'] = 0
				let a:state['add_lines'] = []
			else
				call s:DiffAddEntry(
					\ a:state,
					\ a:state['offset'] - 1,
					\ a:state['del_nlines'],
					\ 'D',
					\ a:state['del_lines'][0]
				\ )
			endif
			let a:state['del_nlines'] = 0
			let a:state['del_lines'] = []
		elseif a:state['add_nlines']
			call s:DiffAddEntry(
				\ a:state,
				\ a:state['offset'],
				\ a:state['add_nlines'],
				\ 'A',
				\ a:state['add_lines'][0]
			\ )
			let a:state['offset'] += a:state['add_nlines']
			let a:state['add_nlines'] = 0
			let a:state['add_lines'] = []
		endif
		let a:state['offset'] += 1
		let a:state['old_linenum'] += 1
		let a:state['new_linenum'] += 1
	endif
	return funcref('git#parser#diff#parse_diff', [a:state])
endfunction
function git#parser#diff#end_file(state) abort
	call git#parser#diff#parse_diff(a:state, ' ')
endfunction
function git#parser#diff#end(state) abort
	call git#parser#diff#end_file(a:state)
endfunction

