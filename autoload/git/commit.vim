let s:null = v:null
let s:parsed_commit = {}
function git#commit#parse_init() abort
	let s:parsed_commit = {
		\ 'hash': '',
		\ 'merge_parent': '',
		\ 'merge_left': '',
		\ 'author': '',
		\ 'author_date': '',
		\ 'message': '',
		\ 'nfiles': 0,
		\ 'files': []
		\}
	return funcref('git#commit#parse_headers')
endfunction
function git#commit#parse_headers(line) abort
	if a:line =~ '^commit '
		let s:parsed_commit['hash'] = trim(a:line[7:])
	elseif a:line =~ '^Merge:'
		let l:hashes = split(trim(a:line[7:]), ' ')
		let s:parsed_commit['merge_parent'] = l:hashes[0]
		let s:parsed_commit['merge_left'] = l:hashes[1]
	elseif a:line =~ '^Author:'
		let s:parsed_commit['author'] = trim(a:line[7:])
	elseif a:line =~'^Date:'
		let s:parsed_commit['author_date'] = trim(a:line[5:])
	elseif a:line == ''
		return funcref('git#commit#parse_message')
	else
		echoerr 'Invalid commit header'
	endif
	return funcref('git#commit#parse_headers')
endfunction
function git#commit#parse_message(line) abort
	if a:line == ''
		return funcref('git#commit#parse_file')
	else
		let s:parsed_commit['message'] .= a:line."\n"
	endif
	return funcref('git#commit#parse_message')
endfunction
function git#commit#parse_file(line) abort
	if a:line =~'^diff --git '
		let l:file_path = ''
		for l:file_path_frag in split(a:line[13:], ' ')
			if l:file_path_frag =~ '\\$'
				let l:file_path .= l:file_path_frag[0:-2].' '
			else
				let l:file_path .= l:file_path_frag
				break
			endif
		endfor
		let s:parsed_commit['nfiles'] += 1
		call add(s:parsed_commit['files'], {
			\ 'type': 'edit',
			\ 'path': l:file_path,
			\ 'old_path': '',
			\ 'old_hash': '',
			\ 'new_hash': '',
			\ 'diff': ''
		\})
	elseif a:line =~ '^new file mode '
		let s:parsed_commit['files'][s:parsed_commit['nfiles'] - 1]['type'] = 'new'
	elseif a:line =~'^rename from '
		let s:parsed_commit['files'][s:parsed_commit['nfiles'] - 1]['old_path'] = a:line[12:]
	elseif a:line =~'^rename to '
		" Ignore this line
	elseif a:line =~ '^deleted file mode '
		let s:parsed_commit['files'][s:parsed_commit['nfiles'] - 1]['type'] = 'delete'
	elseif a:line =~ '^index '
		let l:hashes = split(get(split(a:line[6:], ' '), 0), '\.\.')
		let s:parsed_commit['files'][s:parsed_commit['nfiles'] - 1]['old_hash'] = l:hashes[0]
		let s:parsed_commit['files'][s:parsed_commit['nfiles'] - 1]['new_hash'] = l:hashes[1]
	else
		let s:parsed_commit['files'][s:parsed_commit['nfiles'] - 1]['diff'] .= a:line."\n"
	endif
	return funcref('git#commit#parse_file')
endfunction
function git#commit#show_diff(lineid) abort
	let l:line = split(getline(a:lineid), "\t")
	let l:commit_hash = get(split(getline(1), ' '), 1)
	if l:line[0] =~ '^│🖉'
		let l:hashes = split(l:line[1], '\.\.')
		let l:bleft_text = git#system#call('show '.l:hashes[0])
		let l:bright_text = git#system#call('show '.l:hashes[1])
		call git#ui#split_three(s:null, {
			\ 'text': l:bleft_text,
			\ 'name': join(l:hashes, ',').'/'.l:line[2]
		\}, {
			\ 'text': l:bright_text,
			\ 'name': l:commit_hash.'/'.l:line[2]
		\}, 1)
		call win_gotoid(win_getid(2))
		difft
		call win_gotoid(win_getid(3))
		difft
		filetype detect
		return v:true
	elseif l:line[0] =~ '^│+'
		let l:hashes = split(l:line[1], '\.\.')
		let l:bright_text = git#system#call('show '.l:hashes[1])
		call git#ui#split_three(s:null, {
			\ 'text': '',
		\}, {
			\ 'text': l:bright_text,
			\ 'name': l:commit_hash.'/'.l:line[2]
		\}, 1)
		call win_gotoid(win_getid(2))
		difft
		call win_gotoid(win_getid(3))
		difft
		filetype detect
		return v:true
	elseif l:line[0] =~ '^│-'
		let l:hashes = split(l:line[1], '\.\.')
		let l:bleft_text = git#system#call('show '.l:hashes[0])
		call git#ui#split_three(s:null, {
			\ 'text': l:bright_text,
			\ 'name': join(l:hashes, ',').'/'.l:line[2]
		\}, {
			\ 'text': '',
		\}, 1)
		call win_gotoid(win_getid(2))
		difft
		call win_gotoid(win_getid(3))
		difft
		filetype detect
		return v:true
	endif
	return v:false
endfunction
let s:commit_windows = {}
function git#commit#show(hash) abort
	let l:commit_bufname = 'Commit: '.a:hash
	if !exists('s:commit_windows[l:commit_bufname]')
		\ || win_gotoid(s:commit_windows[l:commit_bufname]) == 0
		echo 'Loading commit '.a:hash
		let l:git_commit = git#system#call_list('show --date=local '.a:hash)
		let s:parser_state = git#commit#parse_init()
		for l:line in l:git_commit
			let s:parser_state = s:parser_state(l:line)
		endfor
		let l:top_text = "┌Commit: \t".s:parsed_commit['hash']."\n"
			\ ."│Merge:\t\t".s:parsed_commit['merge_parent'].' '.s:parsed_commit['merge_left']."\n"
			\ ."│Author:\t".s:parsed_commit['author']."\n"
			\ ."│Date:\t\t".s:parsed_commit['author_date']."\n"
			\ ."│Message:\n\n".s:parsed_commit['message']."\n"
			\ ."│Files (".s:parsed_commit['nfiles']."):\n│\n"
		for l:file in s:parsed_commit['files']
			if l:file['type'] == 'edit'
				let l:top_text .= '│🖉'
			elseif l:file['type'] == 'new'
				let l:top_text .= '│+'
			elseif l:file['type'] == 'delete'
				let l:top_text .= '│-'
			endif
			let l:top_text .= "\t".l:file['old_hash'].'..'.l:file['new_hash']."\t".l:file['path']."\n"
			if l:file['old_path'] != ''
				let l:top_text .= "│\t\t\trenamed from: ".l:file['old_path']."\n"
			endif
			let l:top_text .= l:file['diff']."\n"
		endfor
		let l:top_text .= "│\n└"
		tabnew
		call git#ui#split_three({
			\ 'text': l:top_text,
			\ 'name': l:commit_bufname
		\}, s:null, s:null, 1)
		let l:commit_winid = win_getid(1)
		call win_gotoid(l:commit_winid)
		setlocal fdm=expr
		setlocal foldexpr=getline(v:lnum)=~'^[┌│└]'?0:1
		setlocal syn=git_commit
		echo 'Loaded commit '.a:hash
		let s:commit_windows[l:commit_bufname] = l:commit_winid
	endif
endfunction
function git#commit#fix_filetype_detect(...) abort
	filetype detect
	call win_gotoid(win_getid(1))
	call setpos('.', [0, line('.'), 1])
	redraw!
endfunction
let s:popup_commits = []
function git#commit#popup_action_show(popup_id, commit_id) abort
	if a:commit_id != -1
		let l:commit_split = split(s:popup_commits[a:commit_id - 1], ' ')
		for l:commit_frag in l:commit_split
			if l:commit_frag =~ "^[0-9a-f]"
				call git#commit#show(l:commit_frag)
				break
			endif
		endfor
	endif
endfunction
function git#commit#fake_click() abort
	let l:linenr = line('.')
	let l:synstack = synstack(l:linenr, col('.'))
	if len(l:synstack) < 1
		return
	endif
	if synIDattr(l:synstack[len(l:synstack) - 1], 'name') == 'gitCommitHash'
		if git#commit#show_diff(l:linenr)
			call timer_start(1, function('git#commit#fix_filetype_detect'))
		endif
	endif
endfunction
function git#commit#popup_menu(cmd_options, action) abort
	let s:popup_commits = []
	for l:commit in git#system#call_list('log --graph -s --date=local --pretty="%h <%aN>	%ad	%s" '.a:cmd_options)
		call add(s:popup_commits, l:commit)
	endfor
	if len(s:popup_commits)
		let l:popupid = popup_menu(s:popup_commits, {
			\ 'callback': 'git#commit#popup_action_'.a:action,
			\ 'line': 'cursor+1',
			\ 'col': 0,
			\ 'moved': 'any',
			\ 'pos': 'topleft',
			\ 'scrollbar': 1,
			\ 'maxheight': 15
		\})
		call win_execute(l:popupid, 'setlocal syn=git_commit_popup')
	endif
endfunction
autocmd CursorHold Commit:* call git#commit#fake_click()

