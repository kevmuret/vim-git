syn match gitCommitAuthorEmail	contained	"<[^]]\+@[^@]\+>"
syn match gitCommitAuthor	contained	"<.\+>"
syn match gitCommitHash		contained	"[0-9a-f]\{4,}"
syn match gitCommitDate		contained	"[A-Z][a-z]\{2\} [A-Z][a-z]\{2\} [0-9]\{1,2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} [0-9]\{4\}\( +[0-9]\{4\}\)\?"

hi def link gitCommitHash	Constant
hi def link gitCommitDate	Special
hi def link gitCommitGraph	SpecialKey
