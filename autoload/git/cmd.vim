let s:git_cmd_last = v:null
let s:git_cmd_chain = []
let s:git_cmd_chain_eof = 0
let s:git_cmd_termid = 0
let s:git_cmd_jobid = 0
let s:git_cmd_bufnr = 0
let s:git_commands = {
	\ 'switch': {
		\ 'options': {
			\ '-c': v:null,
			\ '--merge': v:null,
		\ },
		\ 'complete_func': ['git#branch#custom_list', 'git#cmd#rev_custom_list'],
	\ },
	\ 'rebase': {
		\ 'options': {
			\ '-i': v:null,
		\ },
		\ 'complete_func': 'git#branch#custom_list',
	\ },
	\ 'merge': {
		\ 'complete_func': 'git#branch#custom_list',
	\ },
	\ 'checkout': {
		\ 'complete_func': 'git#cmd#rev_custom_list',
	\ },
	\ 'add': {
		\ 'options': {
			\ '-i': v:null,
		\ },
		\ 'complete_func': 'git#cmd#add_custom_list',
	\ },
	\ 'commit': {
		\ 'options': {
			\ '-m': v:null,
			\ '--amend': v:null,
		\ },
	\ },
	\ 'fetch': {
		\ 'options': {
			\ '--all': v:null,
		\ },
		\ 'complete_func': ['git#remote#custom_list', 'git#branch#custom_list'],
	\},
	\ 'pull': {
		\ 'options': {
			\ '--rebase': v:null,
		\ },
		\ 'complete_func': ['git#remote#custom_list', 'git#branch#custom_list'],
	\},
	\ 'push': {
		\ 'options': {
			\ '--force': v:null,
		\ },
		\ 'complete_func': ['git#remote#custom_list', 'git#branch#custom_list'],
	\},
	\ 'cherry-pick': {
		\ 'options': {
			\ '--continue': v:null,
		\ },
		\ 'complete_func': 'git#cmd#rev_custom_list',
	\ },
	\ 'stash': {
		\ 'options': {
			\ '-m': v:null,
		\ },
		\ 'commands': ['push', 'pop'],
	\ },
	\ 'restore': {
		\ 'options': {
			\ '--staged': v:null,
		\ },
		\ 'complete_func': 'git#cmd#restore_custom_list',
	\ },
	\ 'branch': {
		\ 'options': {
			\ '-d': v:null,
			\ '-c': v:null,
			\ '-m': v:null,
		\ },
		\ 'complete_func': 'git#branch#custom_list',
	\ },
\ }
function s:cmd_exec(cmd, from) abort
	if !exists('a:cmd[a:from]')
		echoerr 'Invalid offset '.a:from
		return
	endif
	if !exists('s:git_commands[a:cmd[a:from]]')
		echoerr 'Unknown command "'.a:cmd[a:from].'"'
		return
	endif
	let l:eof_cmd = a:from
	let l:cmd = [g:git_cmd_path, a:cmd[a:from]]
	for l:argid in range(a:from + 1, len(a:cmd) - 1)
		if a:cmd[l:argid] == '&&' || a:cmd[l:argid] == '||'
			break
		endif
		let l:eof_cmd += 1
		call add(l:cmd, a:cmd[l:eof_cmd])
	endfor
	let s:git_cmd_last = l:cmd
	let s:git_cmd_chain_eof = l:eof_cmd
	let s:git_cmd_errors = []
	let s:git_cmd_termid = term_start(l:cmd, {
		\ 'err_cb': funcref('s:cmd_error'),
		\ 'exit_cb': funcref('s:cmd_exit'),
		\ 'term_finish': 'open',
		\ 'norestore': v:true,
	\ })
	let s:git_cmd_jobid = term_getjob(s:git_cmd_termid)
endfunction
function s:cmd_append_output(msg)
	let l:winid = bufwinid(s:git_cmd_bufnr)
	let l:linenum = line('$', l:winid)
	let l:lines = []
	if type(a:msg) != type(l:lines)
		call add(l:lines, a:msg)
	else
		let l:lines = a:msg
	endif
	call win_execute(l:winid, 'setlocal ma')
	for l:line in l:lines
		call appendbufline(s:git_cmd_bufnr, l:linenum, '|'.s:git_cmd_last[1].'|'.l:line)
	endfor
	call win_execute(l:winid, 'setlocal noma')
endfunction
function s:cmd_error(ch, msg)
	call s:cmd_append_output(': '.a:msg)
endfunction
function s:cmd_exit(jobid, status)
	if a:status != 0
		call s:cmd_append_output(' returned with status: '.a:status)
	endif
	if exists('s:git_cmd_chain[s:git_cmd_chain_eof + 1]')
		let l:oper = s:git_cmd_chain[s:git_cmd_chain_eof + 1]
		let l:continue_to = 0
		if l:oper == '&&'
			if a:status == 0
				let l:continue_to = s:git_cmd_chain_eof + 1
			endif
		elseif l:oper == '||'
			if a:status != 0
				let l:continue_to = s:git_cmd_chain_eof + 1
			endif
		else
			echoerr 'Invalid operator "'.l:oper.'"'
			return
		endif
		if l:continue_to > 0 && exists('s:git_cmd_chain[l:continue_to + 1]')
			quit
			call s:cmd_exec(s:git_cmd_chain, l:continue_to + 1)
		elseif a:status == 0
			checktime
			quit
		endif
	else
		checktime
		if a:status == 0
			quit
		endif
	endif
endfunction

function git#cmd#execute(...)
	if len(a:000) > 0
		let s:git_cmd_last = v:null
		let s:git_cmd_chain = copy(a:000)
		let s:git_cmd_chain_eof = 0
		if git#ui#openTab('Git cmd')
			let s:git_cmd_bufnr = bufnr()
			call append(0, '----- Git commands: -----')
			setlocal noma
			setlocal buftype=nofile
			setlocal nobuflisted
			setlocal syn=git_commands
		endif
		setlocal ma
		call append(line('$'), ['--', '-- Command chain: '.join(a:000, ' '), '--'])
		setlocal noma
		call s:cmd_exec(s:git_cmd_chain, s:git_cmd_chain_eof)
	endif
endfunction
function git#cmd#custom_list(arglead, cmd, curpos)
	let l:result = []
	let l:is_bof_cmd = v:true
	let l:is_in_args = v:false
	let l:cmd_name = ''
	let l:opt_name = ''
	let l:arg_num = -1
	let l:pos = 0
	let l:is_first = v:true "Skip the first argument (Git command)
	for l:arg in split(a:cmd, ' ')
		if l:is_first
			let l:is_first = v:false
			let l:pos += len(l:arg) + 1
			continue
		endif
		if l:is_bof_cmd
			let l:is_bof_cmd = v:false
			let l:cmd_name = l:arg
		elseif l:arg == '&&' || l:arg == '||'
			let l:is_bof_cmd = v:true
			let l:is_in_args = v:false
			let l:cmd_name = ''
			let l:opt_name = ''
			let l:arg_num = -1
		else
			let l:is_in_args = v:true
			if l:arg =~ '^-'
				let l:opt_name = l:arg
			else
				let l:arg_num += 1
			endif
		endif
		let l:pos += len(l:arg) + 1
		if l:pos > a:curpos
			break
		endif
	endfor
	if !l:is_bof_cmd && l:pos == a:curpos
		let l:is_in_args = v:true
		let l:arg_num += 1
	endif
	let l:choices = []
	if !l:is_in_args
		let l:choices = keys(s:git_commands)
	elseif exists('s:git_commands[l:cmd_name]')
		if a:arglead =~ '^-'
			let l:choices = keys(s:git_commands[l:cmd_name])
		elseif l:opt_name != '' && exists('s:git_commands[l:cmd_name]["options"][l:opt_name]') && type(s:git_commands[l:cmd_name]["options"][l:opt_name]) != type(v:null)
			let l:choices = call(s:git_commands[l:cmd_name]["options"][l:opt_name], [a:arglead, a:cmd, a:curpos])
		else
			if exists('s:git_commands[l:cmd_name]["complete_func"]')
				let l:func_choices = v:null
				if type(s:git_commands[l:cmd_name]["complete_func"]) == type([])
					if exists('s:git_commands[l:cmd_name]["complete_func"][l:arg_num]')
						let l:func_choices = s:git_commands[l:cmd_name]["complete_func"][l:arg_num]
					endif
				else
					let l:func_choices = s:git_commands[l:cmd_name]["complete_func"]
				endif
				let l:choices = call(l:func_choices, [a:arglead, a:cmd, a:curpos])
			endif
			if exists('s:git_commands[l:cmd_name]["commands"]')
				call extend(l:choices, s:git_commands[l:cmd_name]["commands"])
			endif
		endif
		if exists('s:git_commands[l:cmd_name]["options"]')
			call extend(l:choices, keys(s:git_commands[l:cmd_name]["options"]))
		endif
		call extend(l:choices, ['&&', '||'])
	endif
	for l:choice in l:choices
		if l:choice =~ '^'.a:arglead
			call add(l:result, l:choice)
		endif
	endfor
	return uniq(l:result)
endfunction
function git#cmd#add_custom_list(arglead, cmd, curpos)
	let l:result = []
	for l:addline in git#system#call_list('status -s --untracked=all')
		let l:add_infos = matchlist(l:addline, '^.. \(.\+\)')
		if len(l:add_infos) > 0
			call add(l:result, l:add_infos[1])
		endif
	endfor
	return l:result
endfunction
function git#cmd#rev_custom_list(arglead, cmd, curpos)
	let l:result = git#branch#custom_list(a:arglead, a:cmd, a:curpos)
	for l:revline in git#system#call_list('rev-list --all --abbrev-commit')
		if l:revline =~ '^'.a:arglead
			call add(l:result, l:revline)
		endif
	endfor
	return l:result
endfunction
