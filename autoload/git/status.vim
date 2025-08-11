function git#status#open() abort
	let l:status_bufname = "GitStatus"
	call git#ui#start_loading(l:status_bufname)
	if git#ui#openTab(l:status_bufname)
		setlocal fdm=expr
		setlocal foldexpr=getline(v:lnum)=~'^[┌│└]'?0:1
		setlocal syn=git_status
		setlocal nonumber
		setlocal nolist
	endif
	let l:git_status = git#system#call_list('status --untracked-files=all --porcelain -b')
	let l:staged_files = []
	let l:unmerged_files = []
	let l:unstaged_files = []
	let l:untracked_files = []
	let l:ignored_files = []
	let l:status_infos = [] "matchlist(l:git_status[0], '^## \([^ ]\+\)\( .\+\)\?$')
	let l:current_line = 0
	while !exists("l:status_infos[1]") && exists("l:git_status[l:current_line]")
		let l:status_infos = matchlist(l:git_status[l:current_line], '^## \([^ ]\+\)\( .\+\)\?$')
		let l:current_line = l:current_line + 1
	endwhile

	for l:file in l:git_status[l:current_line:]
		let l:file_infos = matchlist(l:file, '^\([ MTADRCU?!]\)\([ MTADRCU?!]\) \(.\+\)\( -> \)\?\(.\+\)\?$')
		if !exists("l:file_infos[1]")
			continue
		endif
		
		if l:file_infos[1] != ' '
			if l:file_infos[1] == 'U'
				call add(l:unmerged_files, l:file_infos)
			elseif l:file_infos[1] == '?'
				call add(l:untracked_files, l:file_infos)
			elseif l:file_infos[1] == '!'
				call add(l:ignored_files, l:file_infos)
			else
				call add(l:staged_files, l:file_infos)
			endif
		endif
		if l:file_infos[2] != ' '
			if l:file_infos[2] == 'U'
				call add(l:unmerged_files, l:file_infos)
			elseif l:file_infos[1] != '?' && l:file_infos[1] != '!'
				call add(l:unstaged_files, l:file_infos)
			endif
		endif
	endfor
	let l:top_text = "┌Branch:	".l:status_infos[1]."\n"
		\ .(l:status_infos[2] != '' ? "│	".l:status_infos[2]."\n" : '')
		\ ."│\n"
	if len(l:staged_files) > 0
		let l:top_text .= "│Staged files:\n"
		for l:file_infos in uniq(sort(l:staged_files))
			if l:file_infos[1] == 'M'
				let l:top_text .= "🖉"
			elseif l:file_infos[1] == 'A'
				let l:top_text .= "+"
			elseif l:file_infos[1] == 'D'
				let l:top_text .= "-"
			endif
			let l:top_text .= "	".l:file_infos[0]."\n"
		endfor
	endif
	if len(l:unstaged_files) > 0
		let l:top_text .= "│Unstaged files:\n"
		for l:file_infos in uniq(sort(l:unstaged_files))
			if l:file_infos[2] == 'M'
				let l:top_text .= "🖉"
			elseif l:file_infos[2] == 'A'
				let l:top_text .= "+"
			elseif l:file_infos[2] == 'D'
				let l:top_text .= "-"
			endif
			let l:top_text .= "	".l:file_infos[0]."\n"
		endfor
	endif
	if len(l:unmerged_files) > 0
		let l:top_text .= "│Unmerged files:\n"
		for l:file_infos in uniq(sort(l:unmerged_files))
			let l:top_text .= "🖉	".l:file_infos[0]."\n"
		endfor
	endif
	if len(l:untracked_files) > 0
		let l:top_text .= "│Untracked files:\n"
		for l:file_infos in uniq(sort(l:untracked_files))
			let l:top_text .= "+	".l:file_infos[3]."\n"
		endfor
	endif
	if len(l:ignored_files) > 0
		let l:top_text .= "│Ignored files:\n"
		for l:file_infos in uniq(sort(l:ignored_files))
			let l:top_text .= "!	".l:file_infos[3]."\n"
		endfor
	endif
	let l:top_text .= "│\n└"
	call git#ui#win_apply_options({
		\ 'text': l:top_text,
		\ 'name': l:status_bufname
	\})
	call git#ui#end_loading(l:status_bufname)
	call git#ui#start('GitStatus', 'status')
endfunction
function git#status#show_diff(winopts_left, winopts_right) abort
	let l:layout = winlayout()
	if l:layout[0] != 'leaf'
		call win_gotoid(win_getid(2))
		0file
		diffoff
		call win_gotoid(win_getid(3))
		0file
		diffoff
		call win_gotoid(win_getid(1))
	endif

	call git#ui#split_three(v:null, a:winopts_left, a:winopts_right, 1)
	call win_gotoid(win_getid(2))
	difft
	call win_gotoid(win_getid(3))
	difft
	set ma
	filetype detect
endfunction
function git#status#get_head_blob(file_path) abort
	return git#system#call_list('show HEAD:'.a:file_path)
endfunction
function git#status#get_staged_blob(file_path) abort
	let l:diff_lines = git#system#call_list('diff --raw '.a:file_path)
	for l:diff_line in l:diff_lines
		let l:against_diff_infos = matchlist(l:diff_line, '^\:\d\+ \d\+ \([^ ]\+\)')
		if exists('l:against_diff_infos[1]')
			return git#system#call_list('show '.l:against_diff_infos[1])
			break
		endif
	endfor
	return ''
endfunction
function git#status#get_file_line_infos(lineid) abort
	let l:line = getline(a:lineid)
	let l:file_infos = matchlist(l:line, '^\(.\)\?	\([ MTADRCU?!]\)\([ MTADRCU?!]\) \(.\+\)\( -> \)\?\(.\+\)\?$')
	let l:staged = v:false
	let l:added = v:true
	let l:modified = v:false
	let l:staged_modified = v:false
	if exists('l:file_infos[0]')
		let l:file_path = l:file_infos[4]
		let l:added = l:file_infos[2] == 'A'
		let l:modified = l:file_infos[3] == 'M'
		let l:staged_modified = l:file_infos[2] == 'M'
		for l:lineid in range(a:lineid, 0, -1)
			let l:line = getline(l:lineid)
			if l:line =~ '^│Unstaged files:' || l:line =~ '│Untracked files:'
				break
			elseif l:line =~ '│Staged files:'
				let l:staged = v:true
			endif
		endfor
	else
		let l:file_infos = matchlist(l:line, '^+	\(.\+\)\?$')
		let l:file_path = l:file_infos[1]
	endif
	return {
		\ 'path': l:file_path,
		\ 'staged': l:staged,
		\ 'added': l:added,
		\ 'modified': l:modified,
		\ 'staged_modified': l:staged_modified,
	\ }
endfunction
function git#status#show_file_status(lineid) abort
	let l:line = getline(a:lineid)
	call git#ui#start_loading(l:line[1])
	let l:file_infos = git#status#get_file_line_infos(a:lineid)
	if l:file_infos['staged']
		if l:file_infos['added']
			if !l:file_infos['modified']
				execute 'tabedit '.l:file_infos['path']
			else
				call git#status#show_diff({
					\ 'text': '',
				\ }, {
					\ 'text': git#status#get_staged_blob(l:file_infos['path']),
					\ 'name': 'STAGE/'.l:file_infos['path'],
				\ })
			endif
		elseif l:file_infos['staged_modified'] && l:file_infos['modified']
			call git#status#show_diff({
				\ 'text': git#status#get_head_blob(l:file_infos['path']),
				\ 'name': 'HEAD/'.l:file_infos['path'],
			\ }, {
				\ 'text': git#status#get_staged_blob(l:file_infos['path']),
				\ 'name': 'STAGE/'.l:file_infos['path'],
			\ })
		else
			call git#status#show_diff({
				\ 'text': git#status#get_head_blob(l:file_infos['path']),
				\ 'name': 'HEAD/'.l:file_infos['path'],
			\ }, {
				\ 'file': l:file_infos['path'],
			\ })
		endif
	else
		if l:file_infos['added']
			if !l:file_infos['modified']
				execute 'tabedit '.l:file_infos['path']
			else
				call git#status#show_diff({
					\ 'text': git#status#get_staged_blob(l:file_infos['path']),
					\ 'name': 'STAGE/'.l:file_infos['path'],
				\ }, {
					\ 'file': l:file_infos['path'],
				\ })
			endif
		elseif l:file_infos['staged_modified']
			call git#status#show_diff({
				\ 'text': git#status#get_staged_blob(l:file_infos['path']),
				\ 'name': 'STAGE/'.l:file_infos['path'],
			\ }, {
				\ 'file': l:file_infos['path'],
			\ })
		else
			call git#status#show_diff({
				\ 'text': git#status#get_head_blob(l:file_infos['path']),
				\ 'name': 'HEAD/'.l:file_infos['path'],
			\ }, {
				\ 'file': l:file_infos['path'],
			\ })
		endif
	endif
	call git#ui#end_loading(l:line[1])

"	let l:line = getline(a:lineid)
"	if l:line =~ '^🖉'
"		call git#ui#start_loading(l:line[1])
"
"		let l:file_infos = matchlist(l:line, '^.\?	\([ MTADRCU?!]\)\([ MTADRCU?!]\) \(.\+\)\( -> \)\?\(.\+\)\?$')
"
"		let l:file_path = l:file_infos[3]
"
"		if l:file_infos[1] == ' '
"			let l:against_text = git#system#call_list('show HEAD:'.l:file_path)
"		else
"			let l:diff_lines = git#system#call_list('diff --raw '.l:file_path)
"			for l:diff_line in l:diff_lines
"				let l:against_diff_infos = matchlist(l:diff_line, '^\:\d\+ \d\+ \([^ ]\+\)')
"				if exists('l:against_diff_infos[1]')
"					let l:against_text = git#system#call_list('show '.l:against_diff_infos[1])
"					break
"				endif
"			endfor
"		endif
"
"		call git#status#show_diff({
"			\ 'text': l:against_text,
"			\ 'name': 'HEAD/'.l:file_path
"		\}, {
"			\ 'file': l:file_path,
"		\})
"
"		call git#ui#end_loading(l:line[1])
"		return v:true
"	elseif l:line =~ '^+	\([ MTADRCU?!]\)\([ MTADRCU?!]\) '
"		let l:file_infos = matchlist(l:line, '^.\?	\([ MTADRCU?!]\)\([ MTADRCU?!]\) \(.\+\)\( -> \)\?\(.\+\)\?$')
"		execute 'tabedit '.l:file_infos[3]
"		return v:true
"	elseif l:line =~ '^+'
"		let l:file_infos = matchlist(l:line, '^+	\(.\+\)\?$')
"		execute 'tabedit '.l:file_infos[1]
"		return v:true
"	endif
endfunction
function git#status#git_add(lineid, refresh=v:true) abort
	let l:line = getline(a:lineid)

	if l:line =~ '^🖉'
		let l:file_infos = matchlist(l:line, '^.\?	\([ MTADRCU?!]\)\([ MTADRCU?!]\) \(.\+\)\( -> \)\?\(.\+\)\?$')
		let l:file_path = l:file_infos[3]
		if l:file_infos[2] == ' '
			call git#system#call('restore --staged '.l:file_path)
		else
			call git#system#call('add '.l:file_path)
		endif
	elseif l:line =~ '^+	\([ MTADRCU?!]\)\([ MTADRCU?!]\) '
		let l:file_infos = matchlist(l:line, '^.\?	\([ MTADRCU?!]\)\([ MTADRCU?!]\) \(.\+\)\( -> \)\?\(.\+\)\?$')
		let l:file_path = l:file_infos[3]
		call git#system#call('rm --cached '.l:file_path)
	elseif l:line =~ '^+'
		let l:file_infos = matchlist(l:line, '^+	\(.\+\)\?$')
		let l:file_path = l:file_infos[1]
		call git#system#call('add '.l:file_path)
	elseif l:line =~ '^-'
		let l:file_infos = matchlist(l:line, '^-	 D \(.\+\)\?$')
		let l:file_path = l:file_infos[1]
		call git#system#call('rm '.l:file_path)
	endif
	if a:refresh
		call git#status#open()
	endif
endfunction
function git#status#git_add_multi(start_lineid, end_lineid) abort
	for l:lineid in range(a:start_lineid, a:end_lineid)
		call git#status#git_add(l:lineid, v:false)
	endfor
	call git#status#open()
endfunction

function git#status#on_dblclick(event) abort
	if a:event["vsynname"] == 'gitStatusFile'
		call git#status#show_file_status(a:event["vlnum"])
	elseif a:event["vsynname"] == 'DiffChange' || a:event["vsynname"] == 'DiffAdd' || a:event["vsynname"] == 'DiffDelete'
		call git#status#git_add(a:event["vlnum"])
	endif
endfunction
call git#ui#event#on('status', 'dblclick', funcref('git#status#on_dblclick'))
function git#status#on_enter(event) abort
	if a:event["synname"] == 'gitStatusFile'
		call git#status#show_file_status(a:event["lnum"])
	elseif a:event["synname"] == 'DiffChange' || a:event["synname"] == 'DiffAdd' || a:event["vsynname"] == 'DiffDelete'
		call git#status#git_add(a:event["lnum"])
	endif
endfunction
call git#ui#event#on('status', 'enter', funcref('git#status#on_enter'))
