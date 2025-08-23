function git#branch#custom_list(arglead, cmdline, curpos) abort
	let l:result = []
	let l:branches = git#system#call_list('branch -l'.(a:arglead != '' ? ' '.a:arglead.'*' :  ''))
	for l:branch in l:branches
		if l:branch[2:] !~ ' -> ' && l:branch[2:] !~ '^(HEAD\>'
			call git#cmd#custom_list_add_result(l:result, a:arglead, l:branch[2:], '/')
		endif
	endfor
	let l:branches = git#system#call_list('branch -l -r'.(a:arglead != '' ? ' '.a:arglead.'*' :  ''))
	for l:branch in l:branches
		if l:branch[2:] !~ '->' && l:branch[2:] !~ '^(HEAD\>'
			call git#cmd#custom_list_add_result(l:result, a:arglead, l:branch[2:], '/')
		endif
	endfor
	return l:result
endfunction

let g:git_current_branch_name = 'N/A'
let s:git_current_branch_timer = 0
let g:git_current_branch_timer_delay = 1000
let s:line_chunk = ''

function s:read_current_branch_name(ch, msg)
	if a:msg =~ '^*'
		let g:git_current_branch_name = a:msg[2:]
	endif
endfunction
function s:read_current_branch_name_neovim(ch, msg, event)
	if s:line_chunk != '' && ((len(a:msg) > 1 && a:msg[-1] == '') || a:msg[0] == '')
		call s:read_current_branch_name(a:ch, s:line_chunk)
		let s:line_chunk = ''
	endif
	if len(a:msg) > 1
		let s:line_chunk = a:msg[-1] == '' ? a:msg[-2] : a:msg[-1]
	else
		let s:line_chunk .= a:msg[0]
	endif
endfunction
function s:refresh_current_branch_name(timer) abort
	if has('nvim')
		let s:line_chunk = ''
		call jobstart('git branch', {
				\ "on_stdout": funcref('s:read_current_branch_name_neovim'),
				\ "on_exit": funcref('s:exit_current_branch_name'),
			\ })
	else
		call job_start('git branch', {
				\ "out_mode": "nl",
				\ "out_cb": funcref('s:read_current_branch_name'),
				\ "exit_cb": funcref('s:exit_current_branch_name'),
			\ })
	endif
endfunction
function s:reset_current_branch_timer() abort
	if s:git_current_branch_timer
		call timer_stop(s:git_current_branch_timer)
	endif
endfunction
function s:exit_current_branch_name(job, status, event)
	" a:event only apply to neovim
	if has('nvim')
		call s:read_current_branch_name(0, s:line_chunk)
	endif
	if a:status == 0
		let g:git_current_branch_timer_delay = 1000
		call s:track_current_branch_name()
	endif
endfunction
function s:track_current_branch_name() abort
	let s:git_current_branch_timer = timer_start(g:git_current_branch_timer_delay, funcref('s:refresh_current_branch_name'))
endfunction
function s:short_track_current_branch_name() abort
	call s:reset_current_branch_timer()
	let g:git_current_branch_timer_delay = 1000
	call s:track_current_branch_name()
endfunction
function git#branch#start_tracking() abort
	call s:reset_current_branch_timer()
	call s:track_current_branch_name()
	autocmd CursorMoved * call s:short_track_current_branch_name()
endfunction
function git#branch#stop_tracking() abort
	call s:reset_current_branch_timer()
endfunction
