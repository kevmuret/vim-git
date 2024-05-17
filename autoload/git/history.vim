function git#history#at_line(start_linenr, end_linenr, file_path) abort
	call git#commit#popup_menu('-L'.a:start_linenr.','.a:end_linenr.':'.a:file_path, 'show')
endfunction
function git#history#file(file_path) abort
	call git#commit#popup_menu('--follow -- '.a:file_path, 'show')
endfunction
function git#history#graph_file(file_path) abort
	call git#history#graph(['--follow',  a:file_path])
endfunction
function git#history#graph(...) abort
	if a:0 == 0
		let l:history_args = '--all'
	else
		let l:history_args = join(a:000, ' ')
	endif
	let l:history_bufname = 'Git graph: '.l:history_args
	call git#ui#start_loading(l:history_bufname)
	let l:history = git#system#call_list("log --graph --pretty='%d %h <%an>	%ad	%s' --date='format:%Y-%m-%d %H:%M:%S' ".l:history_args)
	let l:history_list = []
	for l:history_line in l:history
		let l:match = matchstr(l:history_line, '^[|\\/.\- *]\+(')
		if l:match != ''
			let l:match2 = matchstr(l:history_line[len(l:match):], '^[^)]\+)')
			call add(l:history_list, substitute(substitute(l:match, '[*\\/]', '|', 'g'), '[^|(]', ' ', 'g').l:match2)
			call add(l:history_list, l:match[0:-2].l:history_line[len(l:match)+len(l:match2):])
		else
			let l:match = matchstr(l:history_line, '^[|\\/.\- *]\+$')
			if l:match != ''
				let l:history_line .= '  '
			endif
			call add(l:history_list, l:history_line)
		endif
	endfor
	if git#ui#openTab(l:history_bufname)
		setlocal noswapfile
		setlocal nobuflisted
		setlocal buftype=nofile
		execute 'file '.l:history_bufname
	endif
	setlocal ma
	%delete _
	call append(0, l:history_list)
	setlocal noma
	setlocal syn=git_graph
	normal gg
	call git#ui#start('Git\ graph:*', 'history')
	call git#ui#end_loading(l:history_bufname)
endfunction

function git#history#on_dblclick(event) abort
	if a:event["synname"] == 'gitGraphHash'
		call git#commit#show(a:event["textsel"])
	elseif getline('.')[a:event["col"]-1] != ' ' && a:event["synname"] == 'gitGraph' || a:event["synname"] == 'gitGraphHL'
		call s:FollowGraphFrom(a:event["lnum"], a:event["col"])
	endif
endfunction
call git#ui#event#on('history', 'dblclick', funcref('git#history#on_dblclick'))
function git#history#on_enter(event) abort
	echom a:event
	if a:event["synname"] == 'gitGraphHash'
		call git#commit#show(expand('<cword>'))
	elseif getline('.')[a:event["col"]-1] != ' ' && a:event["synname"] == 'gitGraph' || a:event["synname"] == 'gitGraphHL'
		call s:FollowGraphFrom(a:event["lnum"], a:event["col"])
	endif
endfunction
call git#ui#event#on('history', 'enter', funcref('git#history#on_enter'))


let s:post_execute = []
function s:GraphHL(linenr, colnr, ncols)
	let l:colnr = a:colnr + 1
	execute 'syn region gitGraphHL start="\%'.a:linenr.'l\%'.l:colnr.'c" end="\%'.a:linenr.'l\%'.(l:colnr + a:ncols).'c"'
endfunction
function s:GraphHLCommit(linenr)
	call add(s:post_execute, 'syn region CursorLine start="\%'.a:linenr.'l\%1c" end="$" contains=gitGraph,gitGraphHash,gitGraphDate')
endfunction
function s:GraphFollowUpPos(rpos, curline, upline)
	let l:pos = a:rpos[0]
	let l:curchr = a:curline[l:pos]
	let l:uplinelen = len(a:upline)
	if a:upline[l:pos] == '|' || a:upline[l:pos] == '*'
	elseif a:curline[a:rpos[1]] == '/'
		if a:upline[a:rpos[1]] == '\'
			let l:pos = a:rpos[1]
		else
			let l:pos = a:rpos[1] + 1
			if l:pos + 1 < l:uplinelen
				if a:upline[l:pos + 1] == '/' || a:upline[l:pos + 1] == '_'
					let l:pos += 1
				endif
			endif
		endif
	elseif l:curchr == '\'
		let l:pos -= 1
		if l:pos > 0 && a:upline[l:pos - 1] == '\'
			let l:pos -= 1
		endif
	elseif l:pos > 0 && a:upline[l:pos - 1] == '\'
		let l:pos -= 1
	elseif a:rpos[1] + 1 < l:uplinelen && a:upline[a:rpos[1] + 1] == '/'
		let l:pos = a:rpos[1] + 1
	endif
	return l:pos
endfunction
function s:GraphFollowDownPos(rpos, curline, downline)
	let l:pos = a:rpos[0]
	let l:curchr = a:curline[l:pos]
	let l:downlinelen = len(a:downline)
	if a:downline[l:pos] == '|' || a:downline[l:pos] == '*'
	elseif l:curchr == '_'
		let l:pos -= 2
	elseif l:curchr == '/'
		let l:pos -= 1
		if l:pos > 1 && a:downline[l:pos - 2] == '/'
			let l:pos -= 1
		endif
	elseif l:curchr == '\'
		if a:downline[l:pos] == '/'
			let l:pos = a:rpos[1]
		else
			let l:pos = a:rpos[1] + 1
		endif
	elseif l:pos > 0 && a:downline[l:pos - 1] == '/'
		let l:pos -= 1
	elseif a:rpos[1] + 1 < l:downlinelen && a:downline[a:rpos[1] + 1] == '\'
		let l:pos = a:rpos[1] + 1
	endif
	return l:pos
endfunction
function s:GraphFollowCurLine(curline, curlinenr, pos) abort
	let l:curchr = a:curline[a:pos]
	let l:npos = v:null
	let l:rpos = v:null
	if l:curchr == ' '
	elseif l:curchr == '|' || l:curchr == '*' || l:curchr == '\'
		let l:npos = [a:pos, 1]
	elseif l:curchr == '/'
		let l:npos = [a:pos, 1]
		let l:rpos = [a:pos, a:pos]
		if a:pos > 1 && a:curline[a:pos - 2] == '_'
			while l:npos[0] > 1
				if a:curline[l:npos[0] - 2] != '_'
					break
				endif
				call s:GraphHL(a:curlinenr, l:npos[0], l:npos[1])
				let l:npos[0] -= 2
			endwhile
		endif
		let l:rpos[0] = l:npos[0]
	elseif l:curchr == '.'
		let l:npos = [a:pos, 1]
		while l:npos[0] > 0
			let l:npos[0] -= 1
			let l:npos[1] += 1
			if a:curline[l:npos[0]] != '-'
				break
			endif
		endwhile
	elseif l:curchr == '-'
		let l:npos = [a:pos, 1]
		while l:npos[0] > 0
			let l:npos[0] -= 1
			let l:npos[1] += 1
			if a:curline[l:npos[0]] != '-'
				break
			endif
		endwhile
		let l:curlinelen = len(a:curline)
		let l:seekpos = a:pos + 1
		while l:seekpos < l:curlinelen
			let l:npos[1] += 1
			if a:curline[l:seekpos] == '.'
				break
			endif
			let l:seekpos += 1
		endwhile
	elseif l:curchr == '_'
		let l:npos = [a:pos, 1]
		while l:npos[0] > 1
			if a:curline[l:npos[0] - 2] != '_'
				break
			endif
			call s:GraphHL(a:curlinenr, l:npos[0], l:npos[1])
			let l:npos[0] -= 2
		endwhile
		let l:rpos = [l:npos[0], a:pos]
		let l:curlinelen = len(a:curline)
		while l:npos[0] < l:curlinelen
			call s:GraphHL(a:curlinenr, l:npos[0], l:npos[1])
			if a:curline[l:npos[0]] == '/'
				break
			endif
			let l:npos[0] += 2
		endwhile
		let l:rpos[1] = l:npos[0]
	endif
	if type(l:npos) != type(v:null)
		call s:GraphHL(a:curlinenr, l:npos[0], l:npos[1])
		if l:curchr == '*'
			call s:GraphHLCommit(a:curlinenr)
		endif
	endif
	if type(l:rpos) == type(v:null) && type(l:npos) != type(v:null)
		let l:rpos = [l:npos[0], l:npos[0] + l:npos[1] - 1]
	endif
	return copy(l:rpos)
endfunction
function s:FollowGraphFrom(lnum, col) abort
	syn clear
	let s:post_execute = []
	let l:curline = getline(a:lnum)
	let l:curlinepos = s:GraphFollowCurLine(l:curline, a:lnum, a:col - 1)
	let l:lastline = l:curline
	let l:rpos = copy(l:curlinepos)
	for l:uplinenr in reverse(range(max([1, a:lnum - g:git_history_max_follow_graph]), a:lnum - 1))
		let l:upline = getline(l:uplinenr)
		let l:pos = s:GraphFollowUpPos(l:rpos, l:lastline, l:upline)
		let l:rpos = s:GraphFollowCurLine(l:upline, l:uplinenr, l:pos)
		if type(l:rpos) == type(v:null)
			break
		endif
		let l:lastline = l:upline
	endfor
	let l:lastline = l:curline
	let l:rpos = copy(l:curlinepos)
	for l:downlinenr in range(a:lnum + 1, min([line('$'), a:lnum + g:git_history_max_follow_graph]))
		let l:downline = getline(l:downlinenr)
		let l:pos = s:GraphFollowDownPos(l:rpos, l:lastline, l:downline)
		let l:rpos = s:GraphFollowCurLine(l:downline, l:downlinenr, l:pos)
		if type(l:rpos) == type(v:null)
			break
		endif
		let l:lastline = l:downline
	endfor
	runtime syntax/git_graph.vim
	for l:execute in s:post_execute
		execute l:execute
	endfor
endfunction
