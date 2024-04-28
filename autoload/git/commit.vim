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
	let l:infos = matchlist(a:line, '\(\d\+ \d\+ \?\d*\) \([a-f0-9]\+ [a-f0-9]\+ \?[a-f0-9]*\) \([ADMR]\d*[ADMR]\?\d*\)	\(.\+\)')
	if len(l:infos) > 0
		let l:infos_modes = split(l:infos[1], ' ')
		let l:infos_hashes = split(l:infos[2], ' ')
		let l:infos_oper = matchlist(l:infos[3], '^\([ADMR]\)\d*\([ADMR]\)\?\d*$')
		let l:infos_files = split(l:infos[4], '	')
		let l:type = 'edit'
		if l:infos_oper[1] == 'A'
			let l:type = 'new'
		elseif l:infos_oper[1] == 'D'
			let l:type = 'delete'
		elseif l:infos_oper[1] == 'M'
			let l:type = 'edit'
		elseif l:infos_oper[1] == 'R'
			let l:type = 'edit'
		endif
		let s:parsed_commit['nfiles'] += 1
		call add(s:parsed_commit['files'], {
			\ 'type': l:type,
			\ 'path': l:infos_files[len(l:infos_files) > 1 ? 1 : 0],
			\ 'old_path': len(l:infos_files) > 1 ? l:infos_files[0] : '',
			\ 'old_hash': l:infos_hashes[0],
			\ 'old_hash2': len(l:infos_hashes) > 2 ? l:infos_hashes[1] : '',
			\ 'new_hash': l:infos_hashes[len(l:infos_hashes) > 2 ? 2 : 1],
			\ 'diff': ''
		\})
	endif
	return funcref('git#commit#parse_file')
endfunction
function git#commit#show_diff(lineid) abort
	let l:line = split(getline(a:lineid), "\t")
	let l:commit_hash = get(split(getline(1), ' '), 1)
	if l:line[0] =~ '^│🖉'
		call git#ui#start_loading(l:line[1])
		let l:hashes = split(l:line[1], '\.\.')
		let l:old_hashes = split(l:hashes[0], ',')
		let l:bleft_text = git#system#call('show '.l:old_hashes[0])
		let l:bleft_name = l:commit_hash[0:6].'/'.l:old_hashes[0].'/'
		let l:bright_text = git#system#call('show '.l:hashes[1])
		let l:next_line = getline(a:lineid + 1)
		let l:is_rename = matchlist(l:next_line, '			renamed from: \(.\+\)')
		let l:bright_name = l:commit_hash[0:6].'/'.l:hashes[1].'/'.l:line[2]
		if len(l:is_rename) > 0
			let l:bleft_name = l:bleft_name . l:is_rename[1]
		else
			let l:bleft_name = l:bleft_name . l:line[2]
		endif
		if len(l:old_hashes) == 2
			let l:bleft1_text = l:bleft_text
			let l:bleft1_name = l:bleft_name
			let l:bleft2_text = git#system#call('show '.l:old_hashes[1])
			let l:bleft2_name = l:commit_hash[0:6].'/'.l:old_hashes[1].'_2/'
			if len(l:is_rename) > 0
				let l:bleft2_name = l:bleft2_name . l:is_rename[1]
			else
				let l:bleft2_name = l:bleft2_name . l:line[2]
			endif
			call git#ui#split_four(s:null, {
				\ 'text': l:bleft1_text,
				\ 'name': l:bleft1_name,
			\}, {
				\ 'text': l:bleft2_text,
				\ 'name': l:bleft2_name,
			\}, {
				\ 'text': l:bright_text,
				\ 'name': l:bright_name,
			\}, 1)
		else
			call git#ui#split_three(s:null, {
				\ 'text': l:bleft_text,
				\ 'name': l:bleft_name,
			\}, {
				\ 'text': l:bright_text,
				\ 'name': l:bright_name,
			\}, 1)
		endif
		call win_gotoid(win_getid(2))
		difft
		call win_gotoid(win_getid(3))
		difft
		if len(l:old_hashes) == 2
			call win_gotoid(win_getid(4))
			difft
		endif
		filetype detect
		call git#ui#end_loading(l:line[1])
		return v:true
	elseif l:line[0] =~ '^│+'
		call git#ui#start_loading(l:line[1])
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
		call git#ui#end_loading(l:line[1])
		return v:true
	elseif l:line[0] =~ '^│-'
		call git#ui#start_loading(l:line[1])
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
		call git#ui#end_loading(l:line[1])
		return v:true
	endif
	return v:false
endfunction
function git#commit#show(hash) abort
	let l:commit_bufname = 'Commit: '.a:hash
	if git#ui#openTab(l:commit_bufname)
		call git#ui#start_loading(l:commit_bufname)
		"TODO Display minimal output with 'show --date=local --raw '.a:hash
		let l:git_commit = git#system#call_list('show --date=local --raw '.a:hash)
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
			let l:top_text .= "\t".l:file['old_hash'].(l:file['old_hash2'] != '' ? ','.l:file['old_hash2'] : '').'..'.l:file['new_hash']."\t".l:file['path']."\n"
			if l:file['old_path'] != ''
				let l:top_text .= "│\t\t\trenamed from: ".l:file['old_path']."\n"
			endif
			if l:file['diff'] != ''
				let l:top_text .= l:file['diff']."\n"
			endif
		endfor
		let l:top_text .= "│\n└"
		call git#ui#win_apply_options({
			\ 'text': l:top_text,
			\ 'name': l:commit_bufname
		\})
		let l:commit_winid = win_getid(1)
		call win_gotoid(l:commit_winid)
		setlocal fdm=expr
		setlocal foldexpr=getline(v:lnum)=~'^[┌│└]'?0:1
		setlocal syn=git_commit
		call git#ui#end_loading(l:commit_bufname)
	endif
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

function git#commit#on_dbl_click(synname, wordsel, colnr) abort
	let l:linenr = line('.')
	if a:synname == 'gitCommitHashes' || a:synname == 'gitCommit3Hashes'
		call git#commit#show_diff(l:linenr)
	elseif a:synname == 'gitCommitHash'
		call git#commit#show(a:wordsel)
	endif
endfunction
call git#ui#dbl_click('Commit:*', 'commit')

