function Bufputtext(text) abort
	let l:text = split(a:text, "\n")
	if get(l:text, 0) =~"\r$"
		setlocal ff=dos
		for l:lineid in range(len(l:text))
			let l:text[l:lineid] = trim(l:text[l:lineid], "\r", 2)
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
		execute 'open '.a:options['file']
	else
		if exists("a:options['name']")
			execute 'file '.a:options['name']
			filetype detect
			setlocal noswapfile
		else
			new
			call win_gotoid(win_getid(winnr() + 1))
			bw
		endif
		if exists("a:options['text']")
			setlocal ma
			%delete _
			call Bufputtext(a:options['text'])
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

