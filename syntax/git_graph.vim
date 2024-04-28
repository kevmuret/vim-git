if !exists('main_syntax')
	let main_syntax = 'git_commit_popup'
endif

runtime! syntax/git_common.vim

syn match gitGraph	"^[*|][ *|\-_/\\.]\+" contains=gitGraphHL

syn region gitGraphBranch	start="(" end=")" contains=gitGraphHead,gitGraphBranchName matchgroup=NonText
syn keyword gitGraphHead	contained HEAD tag
syn match gitGraphHead		contained "[^/, ()\->]\+/"
syn match gitGraphBranchName	contained "[^/, ()\->]"

syn region gitGraphCommit	start="[0-9a-f]\{7\}" end="$" contains=gitGraphHash,gitGraphDate
syn match gitGraphHash	"[0-9a-f]\{7,\}"
syn match gitGraphDate	"[0-9]\{4}-[0-9]\{2}-[0-9]\{2} [0-9]\{2}:[0-9]\{2}:[0-9]\{2}"

hi def link gitGraphHL		Search
hi def link gitGraphHash	Constant
hi def link gitGraphDate	Special
hi def link gitGraphHead	Special
hi def link gitGraphRefSep	NonText
hi def link gitGraph		NonText
hi def link gitGraphBranch	NonText
hi def link gitGraphBranchName	SpecialKey
hi def link gitGraphRefName	SpecialKey
hi def link gitGraphCommit	Text
hi def link gitGraphUnderline	CusrorLine
