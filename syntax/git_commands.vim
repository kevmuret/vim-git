if !exists('main_syntax')
	let main_syntax = 'gitcommands'
endif

runtime! syntax/git_common.vim

syn region gitCmdBigHead	oneline keepend matchgroup=Comment start="^-----" end="-----$"
syn region gitCmdHead	oneline keepend matchgroup=Comment start="^--" end="$"
syn region gitCmdName	keepend matchgroup=Special start="^|" end="|"
syn match gitCmdReturnStatusCode "returned with status: \d\+"

hi def link gitCmdDecoration	NonText
hi def link gitCmdBigHead	Comment
hi def link gitCmdHead		Comment
hi def link gitCmdName		Special
hi def link gitCmdReturnStatusCode	Constant
