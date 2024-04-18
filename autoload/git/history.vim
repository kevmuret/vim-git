function git#history#at_line(start_linenr, end_linenr, file_path) abort
	call git#commit#popup_menu('-L'.a:start_linenr.','.a:end_linenr.':'.a:file_path, 'show')
endfunction
function git#history#file(file_path) abort
	call git#commit#popup_menu('--follow -- '.a:file_path, 'show')
endfunction
function git#history#graph_file(file_path) abort
	call git#history#graph(['--follow', '--',  a:file_path])
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
		let l:match = matchstr(l:history_line, '^[|\\/ *]\+(')
		if l:match != ''
			let l:match2 = matchstr(l:history_line[len(l:match):], '^[^)]\+)')
			call add(l:history_list, substitute(l:match, '*', '|', 'g').l:match2)
			call add(l:history_list, l:match[0:-2].l:history_line[len(l:match)+len(l:match2):])
		else
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
	call git#ui#end_loading(l:history_bufname)
endfunction
let s:last_chr = ''
function s:FollowGraphHorizontalBar(linenr, colnr, line, dir) abort
	let l:syn_colnr = a:colnr
	let l:syn_cmd = 'syn region gitGraphHL start="\%'.a:linenr.'l\%'.l:syn_colnr.'c" end="\%'.a:linenr.'l\%'.(l:syn_colnr + 1).'c"'
	execute l:syn_cmd
	let l:syn_colnr += a:dir * 2
	if a:dir < 0
		while l:syn_colnr - 1 < len(a:line)
			if a:line[l:syn_colnr - 1] != '_'
				break
			endif
			let l:syn_cmd = 'syn region gitGraphHL start="\%'.a:linenr.'l\%'.l:syn_colnr.'c" end="\%'.a:linenr.'l\%'.(l:syn_colnr + 1).'c"'
			execute l:syn_cmd
			let l:syn_colnr += a:dir * 2
		endwhile
		let l:syn_colnr -= a:dir * 2
	else
		while l:syn_colnr > 0
			if a:line[l:syn_colnr - 1] != '_'
				break
			endif
			let l:syn_cmd = 'syn region gitGraphHL start="\%'.a:linenr.'l\%'.l:syn_colnr.'c" end="\%'.a:linenr.'l\%'.(l:syn_colnr + 1).'c"'
			execute l:syn_cmd
			let l:syn_colnr += a:dir * 2
		endwhile
	endif
	return l:syn_colnr
endfunction
function s:FollowGraph(linenr, colnr, dir) abort
	let l:syn_line = getline(a:linenr)
	let l:syn_char = l:syn_line[a:colnr - 1]
	let l:syn_len = 1
	let l:syn_colnr = a:colnr
	if l:syn_char == ' '
		if l:syn_colnr > 1
			if s:last_chr == '/'
				if l:syn_line[l:syn_colnr - 1 + a:dir] == '_'
					"TODO
				endif
			elseif s:last_chr == '\'
				if l:syn_line[l:syn_colnr - 1 - a:dir] == '_'
					"TODO
				endif
			endif
			if l:syn_line[l:syn_colnr - 1 - a:dir] == '\'
				let l:syn_colnr = l:syn_colnr - a:dir
			elseif l:syn_line[l:syn_colnr - 1 + a:dir] == '/'
				let l:syn_colnr += a:dir
			else
				let s:last_chr = '\'
				return -1
			endif
		else
			let s:last_chr = '\'
			return l:syn_colnr
		endif
	elseif l:syn_char == '|'
		if s:last_chr == '/'
			if l:syn_line[l:syn_colnr - 1 + a:dir] == '_'
				"TODO
				let l:syn_colnr += a:dir
				let l:syn_colnr = s:FollowGraphHorizontalBar(a:linenr, l:syn_colnr, l:syn_line, a:dir)
			elseif l:syn_line[l:syn_colnr - 1 + a:dir] == '/'
				let l:syn_colnr += a:dir
			endif
		elseif s:last_chr == '\'
			if l:syn_line[l:syn_colnr - 1 - a:dir] == '_'
				"TODO
			elseif l:syn_line[l:syn_colnr - 1 - a:dir] == '\'
				let l:syn_colnr -= a:dir
			endif
		endif
	elseif l:syn_char == '_'
		"TODO
		let l:syn_colnr = s:FollowGraphHorizontalBar(a:linenr, l:syn_colnr, l:syn_line, a:dir)
	elseif l:syn_char == '\'
		if l:syn_line[l:syn_colnr - 1 - a:dir] == '_'
			"TODO
		endif
	elseif l:syn_char == '/'
		if l:syn_line[l:syn_colnr - 1 + (a:dir * 2)] == '_'
			"TODO
			let l:syn_colnr = s:FollowGraphHorizontalBar(a:linenr, l:syn_colnr, l:syn_line, a:dir)
		endif
	elseif l:syn_char == '*'
		for l:chrnr in range(l:syn_colnr, len(l:syn_line) - 1)
			if l:syn_line[l:chrnr] == '<'
				let l:syn_len -= 1
				break
			endif
			let l:syn_len += 1
		endfor
	endif
	let l:syn_cmd = 'syn region gitGraphHL start="\%'.a:linenr.'l\%'.l:syn_colnr.'c" end="\%'.a:linenr.'l\%'.(l:syn_colnr + l:syn_len).'c"'
	"echom l:syn_cmd
	let l:syn_char = l:syn_line[l:syn_colnr - 1]
	let s:last_chr = l:syn_char
	if l:syn_char == '\'
		let l:syn_colnr -= a:dir
	elseif l:syn_char == '/'
		let l:syn_colnr += a:dir
	elseif l:syn_char == '_'
		let l:syn_colnr += a:dir * 2
	endif
	execute l:syn_cmd
	return l:syn_colnr
endfunction
if !exists('g:git_history_max_follow_graph')
	let g:git_history_max_follow_graph = 100
endif

function git#history#on_dbl_click(synname, wordsel) abort
	if a:synname == 'gitGraphHash'
		let l:hash = expand('<cword>')
		"call setpos('.', [0, line('.'), 1])
		call git#commit#show(l:hash)
	elseif getline('.')[col('.')-1] != ' ' && a:synname == 'gitGraph' || a:synname == 'gitGraphHL'
		syn clear
		let l:linenr = line('.')
		let l:colnr = col('.')
		let l:syn_colnr = l:colnr
		let s:last_chr = '|'
		let l:syn_dir = 1
		for l:syn_linenr in reverse(range(max([1, l:linenr - g:git_history_max_follow_graph]), l:linenr))
			let l:syn_colnr = s:FollowGraph(l:syn_linenr, l:syn_colnr, l:syn_dir)
			if l:syn_colnr < 0
				break
			endif
		endfor
		let s:last_chr = '|'
		let l:syn_colnr = col('.')
		let l:syn_dir = -1
		for l:syn_linenr in range(l:linenr, min([line('$'), l:linenr + g:git_history_max_follow_graph]))
			let l:syn_colnr = s:FollowGraph(l:syn_linenr, l:syn_colnr, l:syn_dir)
			if l:syn_colnr < 0
				break
			endif
		endfor
		runtime syntax/git_graph.vim
	endif
endfunction
call git#ui#dbl_click('Git\ graph:*', 'history')
	
