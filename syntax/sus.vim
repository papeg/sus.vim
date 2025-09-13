" syntax/sus.vim - Syntax highlighting for Sus language

if exists('b:current_syntax')
  finish
endif

syntax case match

" Comments
syntax match  susLineComment "//.*$" contains=@Spell
syntax region susBlockComment start="/\*" end="\*/" contains=@Spell fold
highlight default link susLineComment  Comment
highlight default link susBlockComment Comment

" Types, Keywords, Modifiers
syntax keyword susType     int bool containedin=ALLBUT,susLineComment,susBlockComment
highlight default link susType Type

syntax keyword susKeyword  gen if when else while for in input output containedin=ALLBUT,susLineComment,susBlockComment
syntax keyword susDecl     module struct type const interface action query trigger domain extern __builtin__ containedin=ALLBUT,susLineComment,susBlockComment
highlight default link susKeyword Keyword
highlight default link susDecl    Keyword

syntax keyword susStorage  reg state initial assume containedin=ALLBUT,susLineComment,susBlockComment
highlight default link susStorage StorageClass

" Numbers
syntax match susNumber "\v<\d[_\d]*(\.[_\d]*)?>" contains=@NoSpell containedin=ALLBUT,susLineComment,susBlockComment
highlight default link susNumber Number

" Grouping and punctuation
syntax region susParen  matchgroup=susParenDelim  start=/(/ end=/)/ contains=@susTop keepend containedin=ALLBUT,susLineComment,susBlockComment
syntax region susBracket matchgroup=susBracketDelim start=/\[/ end=/\]/ contains=@susTop keepend containedin=ALLBUT,susLineComment,susBlockComment
syntax region susBrace  matchgroup=susBraceDelim  start=/{/ end=/}/ contains=@susTop keepend fold containedin=ALLBUT,susLineComment,susBlockComment

highlight default link susParenDelim   Delimiter
highlight default link susBracketDelim Delimiter
highlight default link susBraceDelim   Delimiter

" Clusters for nesting
syntax cluster susTop contains=
      \ susType,
      \ susKeyword,
      \ susDecl,
      \ susStorage,
      \ susNumber,
      \ susLineComment,
      \ susBlockComment,
      \ susParen,
      \ susBracket,
      \ susBrace

let b:current_syntax = 'sus'

