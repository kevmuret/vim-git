if !exists("g:git_cmd_path")
	let g:git_cmd_path = 'git'
endif
if !exists('g:git_history_max_follow_graph')
	let g:git_history_max_follow_graph = 1000
endif
if !exists('g:git_auto_fetch_interval')
	let g:git_auto_fetch_interval = 60000
endif
if !exists('g:git_auto_fetch_args')
	let g:git_auto_fetch_args = ''
endif
if !exists('g:git_auto_fetch')
	let g:git_auto_fetch = v:false
endif

command! -nargs=1 -complete=customlist,git#cmd#rev_custom_list GitCommitShow call git#commit#show(<f-args>)
command! -range GitLogLine call git#history#at_line(<line1>,<line2>,expand('%'))
command! -nargs=0 GitLogFile call git#history#file(expand('%'))
command! -nargs=* -complete=customlist,git#cmd#rev_custom_list GitGraph call git#history#graph(<f-args>)
command! -nargs=* -complete=customlist,git#cmd#rev_custom_list GitGraphFile call git#history#graph_buffer(<f-args>)

command! -nargs=* -complete=customlist,git#cmd#custom_list Git call git#cmd#execute(<f-args>)

command! -nargs=0 GitDiffSigns call git#sign#place_file(expand('%'))
autocmd BufWinEnter * :GitDiffSigns
autocmd BufWritePost * :GitDiffSigns

command! -nargs=* -complete=customlist,git#cmd#rev_custom_list GitDiff call git#diff#buffer_versus(<f-args>)
command! -nargs=* -complete=customlist,git#cmd#rev_custom_list GitDiffList call git#diff#list_all(<f-args>) | copen

command! -nargs=0 GitAutoFetch call git#auto_fetch#toggle()
