function git#ui#buf_puttext(text) abort
	let l:text = type(a:text) == type([]) ? a:text : split(a:text, "\n")
	if get(l:text, 0) =~"\r$"
		setlocal ff=dos
		for l:lineid in range(len(l:text))
			let l:linelen = len(l:text[l:lineid])
			if l:linelen > 1
				let l:text[l:lineid] = l:text[l:lineid][0:l:linelen - 2]
			else
				let l:text[l:lineid] = ''
			endif
		endfor
	else
		setlocal ff=unix
	endif
	call append(0, l:text)
endfunction
function git#ui#win_apply_options(options) abort
	if type(a:options) == type(v:null)
		return
	endif
	let l:modifiable = exists("a:options['modifiable']") ? a:options['modifiable'] : v:false
	if exists("a:options['file']")
		execute 'silent open '.a:options['file']
	else
		if exists("a:options['name']")
			execute 'file '.a:options['name']
			filetype detect
			setlocal noswapfile
			setlocal buftype=nofile
		else
			new
			call win_gotoid(win_getid(winnr() + 1))
			bw
		endif
		if exists("a:options['text']")
			setlocal ma
			%delete _
			call git#ui#buf_puttext(a:options['text'])
			delete
			normal gg
			setlocal buftype=nofile
			setlocal nobuflisted
		endif
	endif
	if l:modifiable
		setlocal ma
	else
		setlocal noma
	endif
endfunction
function git#ui#is_split_three_layout(layout) abort
	return a:layout[0] == 'col' && len(a:layout[1]) == 2
		\ && a:layout[1][0][0] == 'leaf'
		\ && a:layout[1][1][0] == 'row'
		\ && len(a:layout[1][1][1]) == 2
		\ && a:layout[1][1][1][0][0] == 'leaf'
		\ && a:layout[1][1][1][1][0] == 'leaf'
endfunction
function git#ui#split_three(top, bleft, bright, base_winid) abort
	let l:layout = winlayout()
	if l:layout[0] == 'leaf'
		call win_gotoid(a:base_winid)
		call git#ui#win_apply_options(a:top)
		new
		call win_splitmove(a:base_winid + 1, a:base_winid)
		call git#ui#win_apply_options(a:bleft)
		new
		call win_splitmove(a:base_winid + 2, a:base_winid + 1, {'vertical':v:true})
		call git#ui#win_apply_options(a:bright)
	elseif git#ui#is_split_three_layout(l:layout)
		if type(a:top) != type(v:null)
			call win_gotoid(win_getid(a:base_winid))
			call git#ui#win_apply_options(a:top)
		endif
		if type(a:bleft) != type(v:null)
			call win_gotoid(win_getid(a:base_winid + 1))
			call git#ui#win_apply_options(a:bleft)
		endif
		if type(a:bright) != type(v:null)
			call win_gotoid(win_getid(a:base_winid + 2))
			call git#ui#win_apply_options(a:bright)
		endif
	else
		echoerr 'Invalid layout'
	endif
endfunction
function git#ui#is_split_four_layout(layout) abort
	return a:layout[0] == 'col' && len(a:layout[1]) == 2
		\ && a:layout[1][0][0] == 'leaf'
		\ && a:layout[1][1][0] == 'row'
		\ && len(a:layout[1][1][1]) == 2
		\ && a:layout[1][1][1][0][0] == 'col'
		\ && len(a:layout[1][1][1][0][1]) == 2
		\ && a:layout[1][1][1][0][1][0][0] == 'leaf'
		\ && a:layout[1][1][1][0][1][1][0] == 'leaf'
		\ && a:layout[1][1][1][1][0] == 'leaf'
endfunction
function git#ui#split_four(top, bleft1, bleft2, bright, base_winid) abort
	let l:layout = winlayout()
	if l:layout[0] == 'leaf'
		call git#ui#win_apply_options(a:top)
		new
		call win_splitmove(a:base_winid + 1, a:base_winid)
		call git#ui#win_apply_options(a:bleft2)
		new
		call win_splitmove(a:base_winid + 2, a:base_winid + 1, {'vertical':v:true})
		call git#ui#win_apply_options(a:bright)
		call win_gotoid(win_getid(a:base_winid + 1))
		new
		call git#ui#win_apply_options(a:bleft1)
	elseif git#ui#is_split_four_layout(l:layout)
		if type(a:top) != type(v:null)
			call win_gotoid(win_getid(a:base_winid))
			call git#ui#win_apply_options(a:top)
		endif
		if type(a:bleft1) != type(v:null)
			call win_gotoid(win_getid(a:base_winid + 1))
			call git#ui#win_apply_options(a:bleft1)
		endif
		if type(a:bleft2) != type(v:null)
			call win_gotoid(win_getid(a:base_winid + 2))
			call git#ui#win_apply_options(a:bleft2)
		endif
		if type(a:bright) != type(v:null)
			call win_gotoid(win_getid(a:base_winid + 3))
			call git#ui#win_apply_options(a:bright)
		endif
	else
		echoerr 'Invalid layout'
	endif
endfunction

function git#ui#listTabs(tabname) abort
	let l:tabs = []
	let l:tabname = ''
	let l:tab = {}
	let l:tabwins = []
	let l:tabwin = {}
	let l:tabindex = 0
	for l:line in split(execute('tabs'), "\n")
		if l:line =~ '^[^ >].\+\d\+$'
			if l:tabname != ''
				if a:tabname == '' || a:tabname == l:tabname
					call add(l:tabs, {
						\ 'name': l:tabname,
						\ 'index': l:tabindex,
						\ 'wins': l:tabwins
					\ })
					let l:tabwins = []
					let l:tabname = ''
				endif
			endif
			let l:tabindex += 1
		else
			if empty(l:tabwins)
				let l:tabname = l:line[4:]
			endif
			if a:tabname == '' || a:tabname == l:tabname
				call add(l:tabwins, {
					\ 'active': l:line[0] == '>',
					\ 'modified': l:line[2] == '+',
					\ 'name': l:line[4:]
				\ })
			endif
		endif
	endfor
	if l:tabname != ''
		if a:tabname == '' || a:tabname == l:tabname
			call add(l:tabs, {
				\ 'name': l:tabname,
				\ 'index': l:tabindex,
				\ 'wins': l:tabwins
			\ })
		endif
	endif
	return l:tabs
endfunction
function git#ui#openTab(tabname) abort
	let l:tabs = git#ui#listTabs(a:tabname)
	if empty(l:tabs)
		if has('nvim')
			execute 'tabedit '.a:tabname
		else
			silent tabnew
			execute 'silent file '.a:tabname
		endif
		return v:true
	else
		let l:tab = get(l:tabs, 0)
		execute 'tabn'.l:tab['index']
		return v:false
	endif
endfunction

let s:loading_id = 0
let s:loading_time = 0
function git#ui#start_loading(name) abort
	if has('nvim') " Neovim doesn't implement popup_* vim functions
		return 0
	endif
	let s:loading_id = popup_notification('Loading... '.a:name, {
		\ 'pos': 'center',
		\ 'time':3000,
	\ })
	redraw!
	let s:loading_time = localtime()
	return s:loading_id
endfunction
function git#ui#end_loading(name) abort
	if s:loading_id != 0
		call popup_close(s:loading_id)
		if localtime() - s:loading_time > 100
			call popup_notification('Loaded '.a:name, {'pos': 'center','time':500})
			redraw!
		endif
	endif
endfunction

function git#ui#start(ftmatch, namespace) abort
	execute "autocmd BufEnter ".a:ftmatch." call git#ui#event#bind_all('".a:namespace."')"
	execute "autocmd BufLeave ".a:ftmatch." call git#ui#event#unbind_all('".a:namespace."')"
	call git#ui#event#bind_all(a:namespace)
endfunction
