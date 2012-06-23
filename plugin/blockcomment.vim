" File:    blockcomment.vim
" Author:  Thomas Gläßle
" Version: 1.1
" License: GPL v2.0
"
" Description:
" This script defines functions and key mappings to comment code.
"
" Installation:
" Simply drop this file into your plugin directory.
"

if v:version < 700
    echoerr 'blockcomment requires VIM 7'
    finish
endif

" Agenda:
" > join neighboring comment blocks if overlap is detected
" > detect inner file type (php -> html -> javascript)
" > provide bindings to be used with a motion command
" > provide blockcomment with left/right pairs each line


" mappings {{{1
" plugins {{{2
map <silent> <Plug>BlockComment       :call <SID>BlockComment()<CR>:silent! call repeat#set("\<Plug>BlockComment")<CR>
map <silent> <Plug>BlockUnComment     :call <SID>BlockUnComment()<CR>:silent! call repeat#set("\<Plug>BlockUnComment")<CR>
map <silent> <Plug>ToggleBlockComment :call <SID>ToggleBlockComment()<CR>:silent! call repeat#set("\<Plug>ToggleBlockComment")<CR>

map <silent> <Plug>Comment            :call <SID>Comment()<CR>:silent! call repeat#set("\<Plug>Comment")<CR>
map <silent> <Plug>UnComment          :call <SID>UnComment()<CR>:silent! call repeat#set("\<Plug>UnComment")<CR>
map <silent> <Plug>ToggleComment      :call <SID>ToggleComment()<CR>:silent! call repeat#set("\<Plug>ToggleComment")<CR>

" key mappings {{{2
map <silent> \a    <Plug>BlockComment
map <silent> \u    <Plug>BlockUnComment
map <silent> \"    <Plug>ToggleBlockComment

map <silent> \c    <Plug>Comment
map <silent> \t    <Plug>UnComment
map <silent> \\    <Plug>ToggleComment
" 2}}}
" 1}}}

" Comment strings {{{1
" SingleLineComment: filetype => [pattern, fillchar]
let g:SingleLineComment = {
    \ 'apache':     ['#',  '-'],
    \ 'asm':        [';',  '-'],
    \ 'bib':        ['%',  '-'],
    \ 'cpp':        ['//', '-'],
    \ 'crontab':    ['#',  '-'],
    \ 'debsources': ['#',  '-'],
    \ 'desktop':    ['#',  '-'],
    \ 'gitcommit':  ['#',  '-'],
    \ 'gitconfig':  [';',  '-'],
    \ 'gitrebase':  ['#',  '-'],
    \ 'gnuplot':    ['#',  '-'],
    \ 'java':       ['//', '-'],
    \ 'javascript': ['//', '-'],
    \ 'lua':        ['--', '-'],
    \ 'make':       ['#',  '-'],
    \ 'maple':      ['#',  '-'],
    \ 'php':        ['//', '-'],
    \ 'perl':       ['#',  '-'],
    \ 'plaintex':   ['%',  '-'],
    \ 'python':     ['#',  '-'],
    \ 'sh':         ['#',  '-'],
    \ 'sql':        ['--', '-'],
    \ 'tex':        ['%',  '-'],
    \ 'vim':        ['"',  '-'],
    \ 'xkb':        ['//', '-']
    \ }

" MultiLineComment: filetype => [start, stop, linestart, fillchar]
let g:MultiLineComment = {
    \ 'c':        ['/*',    '*/', '*', '*'],
    \ 'css':      ['/*',    '*/', '*', '*'],
    \ 'entity':   ["<!--", '-->', ' !', ''],
    \ 'html':     ["<!--", '-->', ' !', ''],
    \ 'markdown': ["<!--", '-->', ' !', ''],
    \ 'xml':      ["<!--", '-->', ' !', '']
    \ }

" returns [blockstart, blockstop, textformat]
function! g:GetBlockCommentStrings(filetype)
    let l:repeat = 40
    " prefer single-line comments
    if has_key(g:SingleLineComment, a:filetype)
        let l:config = g:SingleLineComment[a:filetype]
        let l:effrep = l:config[1] == '' ? 0 : l:repeat / strlen(l:config[1])
        return [
        \     l:config[0] . repeat(l:config[1], l:repeat),
        \     l:config[0] . repeat(l:config[1], l:repeat),
        \     l:config[0]
        \ ]
    " alternatively use multi-line comments
    elseif has_key(g:MultiLineComment, a:filetype)
        let l:config = g:MultiLineComment[a:filetype]
        let l:effrep = l:config[3] == '' ? 0 : l:repeat / strlen(l:config[3])
        return [
        \     l:config[0] . repeat(l:config[3], l:effrep),
        \     l:config[2] . repeat(l:config[3], l:effrep) . l:config[1],
        \     l:config[2]
        \ ]
    " take a guess, using VIM &cms
    elseif has('folding') && (&cms != '')
        let [l:left, l:right] = split(&cms,'%s',1)
        " single-line
        if l:right == ''
            return [
            \     l:left . repeat(' -', l:repeat/2),
            \     l:left . repeat(' -', l:repeat/2),
            \     l:left
            \ ]
        " multi-line
        else
            return [
            \     substitute(l:left,'\S\zs$',' ','') . repeat('-', l:repeat),
            \     repeat('-', l:repeat) . substitute(l:right,'^\ze\S',' ',''),
            \     '-'
            \ ]
        endif
    " default to '#'
    else
        return [
        \     '#'.repeat('-', l:repeat),
        \     '#'.repeat('-', l:repeat),
        \     '#'
        \ ]
    endif
endfunction

" returns [left, right]
function! g:GetCommentStrings(filetype)
    " prefer single-line comments
    if has_key(g:SingleLineComment, a:filetype)
        let l:config = g:SingleLineComment[a:filetype]
        return [l:config[0], '']
    " alternatively use multi-line comments
    elseif has_key(g:MultiLineComment, a:filetype)
        let l:config = g:MultiLineComment[a:filetype]
        return [l:config[0], l:config[1]]
    " take a guess, using VIM &cms
    elseif has('folding') && (&cms != '')
        return split(&cms,'%s',1)
        "----------------------------------------
        " return [substitute(l:left,'\S\zs$',' ',''),
        "         \ substitute(l:right,'^\ze\S',' ','')]
        "----------------------------------------
    " default to '#'
    else
        return ['#', '']
    endif
endfunction
" 1}}}

" Implementation {{{1
" utility functions {{{2

" retrieve byte index corresponding to a virtual index
" (calculate the inverse of strdisplaywidth())
function! s:ColToPhysical(string, virtual)
    return match(a:string, '\%'.(a:virtual+1).'v')
endfunction

function! s:ColToVirtual(string, physical)
    return strdisplaywidth(strpart(string, 0, physical))
endfunction

function! s:IsBlank(line)
    return a:line =~ "^\s*$"
endfunction

function! s:GetBlank(line)
    return matchstr(a:line, "^\s*")
endfunction

" returns [indent, text]
function! s:SplitLine(line)
    return matchlist(a:line, '\v^(\s*)(.*)$')[1:2]
endfunction

function! s:IsComment(text, cLeft, cRight)
    return (a:cLeft == '' || a:text[:strlen(a:cLeft)] == a:cLeft) &&
        \ (a:cRight == '' || a:text[-strlen(a:cRight):] == a:cRight)
endfunction

function! s:ExtractText(text, cLeft, cRight)
    let l:left = strlen(a:cLeft)
    let l:right = strlen(a:cRight)
    let l:len = strlen(a:text)
    let l:isComment = (l:left == 0 || strpart(a:text, 0, l:left) == a:cLeft) &&
            \ (l:right == 0 || strpart(a:text, l:len-l:right-1) == a:cRight)
    if l:isComment
        return [1, strpart(a:text, l:left, l:len-l:left-l:right)]
    else
        return [0, a:text]
    endif
endfunction

function! s:AnalyzeLine(text, cLeft, cRight)
endfunction

function! s:CommentText(text, cLeft, cRight)
endfunction


function! s:GetMultilineIndent(firstln, lastln)
    " find minimal virtual indentation level
    let l:indent = 0
    let l:lineNo = -1
    for l:midline in range(a:firstln, a:lastln)
        if !s:IsBlank(getline(l:midline)) &&
                    \ (l:lineNo == -1 || indent(l:midline) < l:indent)
            let l:indent = indent(l:midline)
            let l:lineNo = l:midline
        endif
    endfor
    " preserve existing indentation (except for whitespace lines):
    " (might be important, e.g. for Makefile)
    if (l:indent % &tabstop) != 0
        for l:midline in range(a:firstln, a:lastln)
            let l:line = getline(l:midline)
            if !s:IsBlank(l:line) && s:ColToPhysical(l:line, l:indent) == -1
                let l:indent = (l:indent % &tabstop)
                break
            endif
        endfor
    endif
    " return
    let l:line = getline(l:lineNo)
    let l:padd = strpart(l:line, 0, s:ColToPhysical(l:line, l:indent))
    return [ l:indent, l:lineNo, l:padd ]
endfunction


function! s:BackupMultiLineComments(str, ft)
    " TODO:
    "-------------------------------------------------(
    " let l:str = substitute(a:str, '\V'.escape(s:comment_strt, '\'), s:comment_strtbak, "g")
    " let l:str = substitute(l:str, '\V'.escape(s:comment_stop, '\'), s:comment_stopbak, "g")
    "-------------------------------------------------)
    return l:str
endfunction

function! s:RestoreMultiLineComments(str, ft)
    " if s:comment_bkup == 1
    " 	let l:line = substitute(l:line, escape(s:comment_strtbak, '\*^$.~[]'), s:comment_strt, "g")
    " 	let l:line = substitute(l:line, escape(s:comment_stopbak, '\*^$.~[]'), s:comment_stop, "g")
    " endif
    return l:str
endfunction



" block (=aligned) comments {{{2
" block (=aligned) commenting {{{3
function! s:BlockComment() range
    call s:BlockCommentWork(a:firstline, a:lastline)
endfunction

function! s:BlockCommentWork(firstln, lastln)
    let l:firstln = a:firstln
    let l:lastln = a:lastln

	" get comment chars
    let [l:cStart, l:cStop, l:cLeft] = g:GetBlockCommentStrings(&ft)
    let l:leftIns = substitute(l:cLeft,'\S\zs$',' ','')

    " get cursor position
    let l:cursor_line = line(".")
    let l:cursor_col = col(".") + strlen(l:leftIns)

	" get minimum indentation level among all relevant lines
    let l:indent_info = s:GetMultilineIndent(l:firstln, l:lastln)
    let l:indent = l:indent_info[0]
    let l:padding = l:indent_info[2]

    " 
	let l:mayappend = 1
	let l:mayprepend = 1

    " TODO: join preceding/trailing blockcomments (if indentation level fits)

    " append comment block end marker
	if l:mayappend
		call append(l:lastln, l:padding . l:cStop)
	endif
    " prepend comment block start marker
	if l:mayprepend
		call append(l:firstln - 1, l:padding . l:cStart)
		let l:firstln += 1
		let l:lastln += 1
		let l:cursor_line += 1
	endif

	" loop for each line
	for l:midline in range(l:firstln, l:lastln)
		let l:line = getline(l:midline)

		" trivial line: blank + less indentation
        if indent(l:midline) < l:indent
            let l:line = ""
		" non-trivial line
        else
            let l:pindent = s:ColToPhysical(l:line, l:indent)
            let l:padding = strpart(l:line, 0, l:pindent)
            let l:line = strpart(l:line, l:pindent)
            " let l:line = BackupMultiLineComments(l:line, &ft)
        endif
        call setline(l:midline, l:padding . l:leftIns . l:line)
	endfor

	" set cursor position
    call cursor(l:cursor_line, l:cursor_col)
endfunction

" block uncommenting {{{3
function! s:BlockUnComment() range
    call s:BlockUnCommentWork(a:firstline, a:lastline)
endfunction

function! s:BlockUnCommentWork(firstln, lastln)
    let l:firstln = a:firstln
    let l:lastln = a:lastln

	" get comment chars
    let [l:cStart, l:cStop, l:cLine] = g:GetBlockCommentStrings(&ft)
	let l:clen = strlen(l:cLine)
    let l:stopLeft = strlen(matchstr(l:cStop, '^\s*'))
    let l:startLeft = strlen(matchstr(l:cStart, '^\s*'))
    let l:lineLeft = strlen(matchstr(l:cLine, '^\s*'))

    " get cursor position
    " let l:pos = getpos() TODO
    let l:cursor_line = line(".")
    let l:cursor_col = col(".")
    " let l:comment_start = 0
    " let l:comment_end = 0

	" loop for each line
    let l:midline = l:firstln
	while l:midline <= l:lastln
		" get indent level
		let l:line = getline(l:midline)
		let l:indent = s:ColToPhysical(l:line, indent(l:midline))

        " block comment start/stop line - delete line
		if strpart(l:line, l:indent - l:startLeft) == l:cStart ||
         \ strpart(l:line, l:indent - l:stopLeft) == l:cStop
			execute l:midline . "d"
			let l:midline = l:midline - 1
			let l:lastln = l:lastln - 1
            if l:midline < l:cursor_line
                let l:cursor_line -= 1
            endif

		" commented code line - remove comment
		elseif strpart(l:line, l:indent - l:lineLeft, l:clen) == l:cLine
			let l:pad = strpart(l:line, 0, l:indent - l:lineLeft)
			let l:line = strpart(l:line, l:indent - l:lineLeft + l:clen)
            if l:midline == l:cursor_line && l:cursor_col >= l:indent + l:clen
                let l:cursor_col -= l:clen
            endif
            " delete 1 space if present
            let l:line = substitute(l:line, '^ ', '', '')

            " if l:midline == l:firstln
                " let l:comment_start = 1
            " endif
            " if l:midline == l:lastln
                " let l:comment_end = 1
            " endif

            " let l:line = RestoreMultiLineComment(l:line, &filetype)
			call setline(l:midline, l:pad . l:line)
		endif

		let l:midline = l:midline + 1
	endwhile

	" look at line above block
    " if l:comment_start
        let l:line = getline(l:firstln - 1)
        let l:indent = s:ColToPhysical(l:line, indent(l:firstln - 1))

        " abandoned begin comment block line - delete line
        if strpart(l:line, l:indent - l:startLeft) == l:cStart
            execute (l:firstln - 1) . "d"
            let l:firstln = l:firstln - 1
            let l:lastln = l:lastln - 1
            let l:cursor_line -= 1

        " abandoned commented code line - insert end comment block line
        elseif strpart(l:line, l:indent - l:lineLeft, l:clen) == l:cLine
            let l:pad = strpart(l:line, 0, l:indent)
            call append(l:firstln - 1, l:pad . l:cStop)
            let l:lastln = l:lastln + 1
            let l:cursor_line += 1
        endif
    " endif

	" look at line below block
    " if l:comment_end
        let l:line = getline(l:lastln + 1)
        let l:indent = s:ColToPhysical(l:line, indent(l:lastln + 1))

        " abandoned end comment block line - delete line
        if strpart(l:line, l:indent - l:stopLeft) == l:cStop
            execute (l:lastln + 1) . "d"
            let l:lastln = l:lastln - 1

        " abandoned commented code line - insert begin comment block line
        elseif strpart(l:line, l:indent - l:lineLeft, l:clen) == l:cLine
            let l:pad = strpart(l:line, 0, l:indent)
            call append(l:lastln, l:pad . l:cStart)
        endif
    " endif

    call cursor(l:cursor_line, l:cursor_col)
endfunction

" toggle block comments {{{3
function! s:ToggleBlockComment() range
    call s:ToggleBlockCommentWork(a:firstline, a:lastline)
endfunction

function! s:ToggleBlockCommentWork(firstln, lastln) range
    let l:firstln = a:firstln
    let l:lastln = a:lastln

	" get comment chars
    let [l:cStart, l:cStop, l:cLine] = g:GetBlockCommentStrings(&ft)
	let l:clen = strlen(l:cLine)
    let l:stopLeft = strlen(matchstr(l:cStop, '^\s*'))
    let l:startLeft = strlen(matchstr(l:cStart, '^\s*'))
    let l:lineLeft = strlen(matchstr(l:cLine, '^\s*'))

	" loop for each line
    let l:type = 'w'
	let l:startln = l:lastln
	let l:stopln = l:lastln
	let l:midline = l:lastln
    while l:midline >= l:firstln
		let l:line = getline(l:midline)
        let l:indent = s:ColToPhysical(l:line, indent(l:midline))

		let l:do_comment = 0
		let l:do_uncomment = 0
		let l:decrement = 0

		" comment
		if strpart(l:line, l:indent - l:stopLeft) == l:cStop ||
                \ strpart(l:line, l:indent - l:startLeft) == l:cStart ||
                \ strpart(l:line, l:indent - l:lineLeft, l:clen) == l:cLine
			if l:type == 'w'
				let l:stopln = l:midline
			elseif l:type == 'tw'
				let l:do_comment = 1
			elseif l:type == 't'
				let l:do_comment = 1
				let l:startln = l:midline + 1
			endif
			let l:type = 'c'

		" text
		elseif !s:IsBlank(l:line)
			if l:type == 'w'
				let l:stopln = l:midline
			elseif l:type == 'c'
				let l:do_uncomment = 1
				let l:startln = l:midline + 1
			endif
			let l:type = 't'

		" blank
		else
			if l:type == 'c'
				let l:type = 'w'
				let l:do_uncomment = 1
				let l:startln = l:midline + 1
			elseif l:type == 't'
				let l:type = 'tw'
				let l:startln = l:midline + 1
			endif
		endif

		" perform operation
		if l:do_comment
            call s:BlockCommentWork(l:startln, l:stopln)
			let l:stopln = l:midline
		elseif l:do_uncomment
            call s:BlockUnCommentWork(l:startln, l:stopln)
			let l:stopln = l:midline
		endif

		let l:midline -= 1
    endwhile

	let l:do_comment = 0
	let l:do_uncomment = 0

	if l:type == 'c'
		let l:do_uncomment = 1
		let l:startln = l:firstln
	elseif l:type == 't'
		let l:do_comment = 1
		let l:startln = l:firstln
	elseif l:type == 'tw'
		let l:do_comment = 1
	endif
	if l:do_comment
        call s:BlockCommentWork(l:startln, l:stopln)
		let l:stopln = l:midline
	elseif l:do_uncomment
        call s:BlockUnCommentWork(l:startln, l:stopln)
		let l:stopln = l:midline
	endif
endfunction
" 3}}}
" 2}}}

" normal comments {{{2
" add simple comments {{{3
" TODO: handle BackupComment() properly
function! s:Comment() range
    let [l:left, l:right] = g:GetCommentStrings(&ft)
    let l:leftIns = substitute(l:left,'\S\zs$',' ','')
    let l:rightIns = substitute(l:right,'^\ze\S',' ','')
    for l:midline in range(a:firstline, a:lastline)
        let [l:pad, l:line] = s:SplitLine(getline(l:midline))
        if l:line != ''
            " TODO: BackupComment
            call setline(l:midline, l:pad . l:leftIns . l:line . l:rightIns)
        endif
    endfor
endfunction

" remove simple comments {{{3
function! s:UnComment() range
    let [l:left, l:right] = g:GetCommentStrings(&ft)
    for l:midline in range(a:firstline, a:lastline)
        let [l:pad, l:line] = s:SplitLine(getline(l:midline))
        if l:line != ''
            let [l:isComment, l:text] = s:ExtractText(l:line, l:left, l:right)
            if l:isComment
                " delete 1 space left+right if present
                let l:text = substitute(l:text, '^ ', '', '')
                let l:text = substitute(l:text, ' $', '', '')
                " TODO: RestoreComment
                call setline(l:midline, l:pad . l:text)
            endif
        endif
    endfor
endfunction

" toggle simple comments {{{3
function! s:ToggleComment() range
    let [l:left, l:right] = g:GetCommentStrings(&ft)
    let l:leftIns = substitute(l:left,'\S\zs$',' ','')
    let l:rightIns = substitute(l:right,'^\ze\S',' ','')
    for l:lineNo in range(a:firstline, a:lastline)
        let [l:pad, l:line] = s:SplitLine(getline(l:lineNo))
        if l:line != ''
            let [l:isComment, l:text] = s:ExtractText(l:line, l:left, l:right)
            if l:isComment
                " delete 1 space if present
                let l:text = substitute(l:text, '^ ', '', '')
                let l:text = substitute(l:text, ' $', '', '')
                " TODO: RestoreComment
                call setline(l:lineNo, l:pad . l:text)
            else
                " TODO: BackupComment
                call setline(l:lineNo, l:pad . l:leftIns . l:line . l:rightIns)
            endif
        endif
    endfor
endfunction
" 3}}}
" 2}}}
" 1}}}

" vim: fdm=manual fdl=0
