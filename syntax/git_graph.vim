if !exists('main_syntax')
	let main_syntax = 'git_commit_popup'
endif

runtime! syntax/git_common.vim

syn region gitGraphLine	oneline keepend start="^" end="$" contains=@gitGraphCluster
syn cluster gitGraphCluster contains=gitGraph,gitGraphRef,gitGraphDate,gitGraphAuthor,gitGraphMessage,gitGraphHash
"syn match gitGraph	"^\([\*\|][ _\\/]\)\+"
syn region gitGraph	oneline start="^" end="  " contains=gitGraphHL
"syn match gitGraph	"^[*| \_/]\+ "
syn match gitGraphAuthor	"<.\+>"
syn match gitGraphHash	"[0-9a-f]\+"
syn match gitGraphDate	"[0-9]\{4}-[0-9]\{2}-[0-9]\{2} [0-9]\{2}:[0-9]\{2}:[0-9]\{2}"
syn match gitGraphMessage	"\t[^\t]\+$"

syn region gitGraphRef	oneline start="(" end=")" contains=gitGraphRefName matchgroup=NonText
syn cluster gitGraphRefCluster contains=gitGraphHead,gitGraphRefSep,gitGraphRefName
syn region gitGraphRefName	contained oneline start="[( ]" end="[,)]" contains=@gitGraphRefCluster
syn keyword gitGraphHead	contained HEAD tag
syn match gitGraphHead		contained "[^/, )]\+/"
syn match gitGraphRefSep	contained "->"
syn match gitGraphRefSep	contained "[(,)]"

hi def link gitGraphHL		Search
hi def link gitGraphHash	Constant
hi def link gitGraphDate	Special
hi def link gitGraphHead	Special
hi def link gitGraphRefSep	NonText
hi def link gitGraph		NonText
hi def link gitGraphRefName	SpecialKey
