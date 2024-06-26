if !exists("g:git_cmd_path")
	let g:git_cmd_path = 'git'
endif
if !exists('g:git_history_max_follow_graph')
	let g:git_history_max_follow_graph = 1000
endif

command! -nargs=1 GitCommitShow call git#commit#show(<f-args>)
command! -range GitLogLine call git#history#at_line(<line1>,<line2>,expand('%'))
command! -nargs=0 GitLogFile call git#history#file(expand('%'))
command! -nargs=* GitGraph call git#history#graph(<f-args>)
command! -nargs=* GitGraphFile call git#history#graph_buffer(<f-args>)

command! -nargs=* -complete=customlist,git#cmd#custom_list Git call git#cmd#execute(<f-args>)

command! -nargs=0 GitDiffSigns call git#sign#place_file(expand('%'))
autocmd BufWinEnter * :GitDiffSigns
autocmd BufWritePost * :GitDiffSigns

command! -nargs=* GitDiff call git#diff#buffer_versus(<f-args>)
command! -nargs=* GitDiffList call git#diff#list_all(<f-args>) | copen
