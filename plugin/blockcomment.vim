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
" > provide blockcomment with left/right pairs each line (adapt aoMarker)
" > smarter pointer restorage
" > 

" TODO: check if repeat#set is present
" TODO: whitespace when uncommenting blank lines...?
" TODO: action when toggle blank lines?

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

let g:SyntaxRegions = {
    \ 'php': [['', 'html'], ['html.*', 'html'],
    \           ['phpRegion', 'php'], ['javaScript', 'javascript']],
    \ 'html': [['', 'html'], ['html.*', 'html'],
    \           ['javaScript', 'javascript']]
    \ }

" returns [left, right, start, stop, textformat]
function! g:GetBlockCommentStrings(filetype)
    let l:repeat = 40
    " prefer single-line comments
    if has_key(g:SingleLineComment, a:filetype)
        let l:config = g:SingleLineComment[a:filetype]
        let l:effrep = l:config[1] == '' ? 0 : l:repeat / strlen(l:config[1])
        return [
        \     l:config[0],
        \     '',
        \     l:config[0] . repeat(l:config[1], l:repeat),
        \     l:config[0] . repeat(l:config[1], l:repeat)
        \ ]
    " alternatively use multi-line comments
    elseif has_key(g:MultiLineComment, a:filetype)
        let l:config = g:MultiLineComment[a:filetype]
        let l:effrep = l:config[3] == '' ? 0 : l:repeat / strlen(l:config[3])
        return [
        \     l:config[2],
        \     '',
        \     l:config[0] . repeat(l:config[3], l:effrep),
        \     l:config[2] . repeat(l:config[3], l:effrep) . l:config[1]
        \ ]
    " take a guess, using VIM &cms
    elseif has('folding') && (&cms != '')
        let [l:left, l:right] = split(&cms,'%s',1)
        " single-line
        if l:right == ''
            return [
            \     l:left,
            \     '',
            \     l:left . repeat(' -', l:repeat/2),
            \     l:left . repeat(' -', l:repeat/2)
            \ ]
        " multi-line
        else
            return [
            \     '-',
            \     '',
            \     substitute(l:left,'\S\zs$',' ','') . repeat('-', l:repeat),
            \     repeat('-', l:repeat) . substitute(l:right,'^\ze\S',' ','')
            \ ]
        endif
    " default to '#'
    else
        return [
        \     '#',
        \     '',
        \     '#'.repeat('-', l:repeat),
        \     '#'.repeat('-', l:repeat)
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
    return a:line =~ '^\s*$'
endfunction

" NOTE: trailing spaces are preserved by appending them to the right
function! s:AddComment(text, ci)
    let l:match = matchlist(a:text, '\v^(\s*)(.{-})(\s*)$')[1:3]
    let l:left = l:match[0] . a:ci['lIns'] . s:BackupComments(l:match[1], a:ci)
    let l:right = a:ci['rIns'] . l:match[2]
    return l:left . l:right
endfunction

function! s:RemoveComment(text, ci)
    let l:match = matchlist(a:text, a:ci['cPat'])[1:3]
    if !empty(l:match)
        return [1, l:match[0] . s:RestoreComments(l:match[1], a:ci) . l:match[2]]
    else
        return [0, '']
    endif
endfunction

function! s:IsComment(text, ci)
    return a:text =~ a:ci['cPat']
endfunction

" rightmost (optional) argument: rCol = right alignment
function! s:AddCommentAlign(text, ci, lCol, ...)
    let l:match = matchlist(a:text, '\v^(\s*)%'.(a:lCol+1).'v(.{-})(\s*)$')[1:3]
    let l:left = l:match[0] . a:ci['lIns'] . s:BackupComments(l:match[1], a:ci)
    let l:right = a:ci['rIns'] . l:match[2]
    if a:0 == 1 && a:1 > 0
        let l:ins = a:1 - strdisplaywidth(l:left)
        if l:ins > 0
            let l:left .= repeat(' ', l:ins)
        endif
    endif
    return l:left . l:right
endfunction

function! s:GetCommentInfo(cs)
    " cPat matches: [leading-ws, text, trailing-ws]
    let l:ci = {
        \ 'lIns': substitute(a:cs[0],'\S\zs$',' ',''),
        \ 'rIns': substitute(a:cs[1],'^\ze\S',' ',''),
        \ 'cPat': '\v^(\s*)\V'.escape(a:cs[0],'\').
                    \ '\v ?(.{-}) {-}\V'.escape(a:cs[1],'\').
                    \ '\v(\s*)$'
    \}
    " block comment
    if len(a:cs) >= 4
        let l:ci.aPat = '\v^\s*\V'.escape(a:cs[2], '\').'\v\s*$'
        let l:ci.oPat = '\v^\s*\V'.escape(a:cs[3], '\').'\v\s*$'
        if l:ci['aPat'] == l:ci['oPat']
            let l:ci.mPat = l:ci['aPat']
        else
            let l:ci.mPat = '\('.l:ci['aPat'].')|('.l:ci['oPat'].')'
        endif
    endif
    return l:ci
endfunction

function! s:GuessSyntaxRegion(line, col)
    if has_key(g:SyntaxRegions, &ft) && exists("*synstack")
        let l:regions = g:SyntaxRegions[&ft]
        let l:synstack = synstack(line('.'), col('.'))
        if !empty(l:synstack)
            for l:synID in reverse(l:synstack)
                let l:name = synIDattr(l:synID, 'name')
                for l:reg in l:regions
                    if l:name =~ '\v^'.l:reg[0].'$'
                        return l:reg[1]
                    endif
                endfor
            endfor
        endif
        return l:regions[0][1]
    else
        return &ft
    endif
endfunction



function! s:GetMultilineIndent(firstln, lastln)
    " find minimal virtual indentation level
    let l:indent = 0
    let l:matchLine = -1
    for l:lineNo in range(a:firstln, a:lastln)
        if !s:IsBlank(getline(l:lineNo)) &&
                    \ (l:matchLine == -1 || indent(l:lineNo) < l:indent)
            let l:indent = indent(l:lineNo)
            let l:matchLine = l:lineNo
        endif
    endfor
    if l:matchLine == -1
        let l:matchLine = a:firstln
    endif
    " preserve existing indentation (except for whitespace lines):
    " (might be important, e.g. for Makefile)
    if (l:indent % &tabstop) != 0
        for l:lineNo in range(a:firstln, a:lastln)
            let l:line = getline(l:lineNo)
            if strdisplaywidth(l:line) >= l:indent &&
                    \ s:ColToPhysical(l:line, l:indent) == -1
                let l:indent = (l:indent % &tabstop)
                break
            endif
        endfor
    endif
    " return
    let l:padd = matchstr(getline(l:matchLine), '^\s*\%'.(l:indent+1).'v')
    return [ l:indent, l:matchLine, l:padd ]
endfunction

function! s:GetDisplayWidth(firstln, lastln)
    let l:displaywidth = 0
    for l:lineNo in range(a:firstln, a:lastln)
        let l:displaywidth = max([l:displaywidth, strdisplaywidth(getline(l:lineNo))])
    endfor
    return l:displaywidth
endfunction


function! s:BackupComments(str, ci)
    " TODO...
    return a:str
endfunction

function! s:RestoreComments(str, ci)
    " TODO...
    return a:str
endfunction



" block (=aligned) comments {{{2
function! s:BlockComment() range
    " TODO: join preceding/trailing blockcomments (if indentation level fits)
    call s:BlockCommentWork(a:firstline, a:lastline, 1, 1)
endfunction
function! s:BlockUnComment() range
    call s:BlockUnCommentWork(a:firstline, a:lastline)
endfunction
function! s:ToggleBlockComment() range
    call s:ToggleBlockCommentWork(a:firstline, a:lastline)
endfunction

" block (=aligned) commenting {{{3
function! s:BlockCommentWork(firstln, lastln, mayprepend, mayappend)
    let l:firstln = a:firstln
    let l:lastln = a:lastln
    let l:pos = getpos('.')

    " get comment chars
    let l:cs = g:GetBlockCommentStrings(s:GuessSyntaxRegion(l:firstln, 1))
    let l:ci = s:GetCommentInfo(l:cs)

    " detect alignment
    let [l:lCol, l:lNo, l:pad] = s:GetMultilineIndent(l:firstln, l:lastln)
    if l:cs[1] != ''
        let l:rCol = s:GetDisplayWidth(l:firstln, l:lastln)
        let l:rCol += strlen(l:ci['lIns'])
    else
        let l:rCol = -1
    endif

    " perform commenting
    call s:DoBlockComment(l:firstln, l:lastln, l:ci, l:lCol, l:rCol, l:pad)

    " append/prepend block markers
    if a:mayappend
        call append(l:lastln, l:pad . l:cs[3])
    endif
    if a:mayprepend
        call append(l:firstln - 1, l:pad . l:cs[2])
        let l:pos[1] += 1
    endif

    " restore cursor
    call setpos('.', l:pos)
endfunction

function! s:DoBlockComment(firstln, lastln, ci, left, right, pad)
    for l:lineNo in range(a:firstln, a:lastln)
        let l:line = getline(l:lineNo)
        if s:IsBlank(l:line) && l:line !~ '\v^\s*%'.(a:left+1).'v'
            let l:line = a:pad
        endif
        call setline(l:lineNo, s:AddCommentAlign(l:line, a:ci, a:left, a:right))
    endfor
endfunction

" block uncommenting {{{3
function! s:BlockUnCommentWork(firstln, lastln)
    let l:firstln = a:firstln
    let l:lastln = a:lastln
    let l:pos = getpos('.')
    let l:cStart = 0
    let l:cEnd = 0

    " get comment chars
    let l:cs = g:GetBlockCommentStrings(s:GuessSyntaxRegion(l:firstln, 1))
    let l:ci = s:GetCommentInfo(l:cs)

    " loop for each line
    let l:lineNo = l:firstln
    while l:lineNo <= l:lastln
        let l:line = getline(l:lineNo)
        " block comment start/stop line - delete line
        if l:line =~ l:ci['mPat'] 
            execute l:lineNo . 'd'
            if l:lineNo < l:pos[1]
                let l:pos[1] -= 1
            endif
            let l:lineNo -= 1
            let l:lastln -= 1
        " commented code line - remove comment
        else
            let [l:isComment, l:text] = s:RemoveComment(l:line, l:ci)
            if l:isComment
                call setline(l:lineNo, l:text)
                if l:lineNo == l:firstln
                    let l:cStart = 1
                endif
                if l:lineNo == l:lastln
                    let l:cEnd = 1
                endif
            endif
        endif
        let l:lineNo += 1
    endwhile

    " look at line above block
    if l:cStart
        let l:line = getline(l:firstln - 1)
        " abandoned begin comment block line - delete line
        if l:line =~ l:ci['aPat']
            execute (l:firstln - 1) . 'd'
            let l:firstln -= 1
            let l:lastln -= 1
            let l:pos[1] -= 1
        else
            let l:match = matchlist(l:line, l:ci['cPat'])[1:3]
            " abandoned commented code line - insert end comment block line
            if !empty(l:match)
                call append(l:firstln - 1, l:match[0] . l:cs[3])
                let l:firstln += 1
                let l:lastln += 1
                let l:pos[1] += 1
            endif
        endif
    endif

    " look at line below block
    if l:cEnd
        let l:line = getline(l:lastln + 1)
        " abandoned end comment block line - delete line
        if l:line =~ l:ci['oPat']
            execute (l:lastln + 1) . 'd'
            let l:lastln = l:lastln - 1
        else
            let l:match = matchlist(l:line, l:ci['cPat'])[1:3]
            " abandoned commented code line - insert begin comment block line
            if !empty(l:match)
                call append(l:lastln, l:match[0] . l:cs[2])
            endif
        endif
    endif

    " restore cursor
    call setpos('.', l:pos)
endfunction

" toggle block comments {{{3
function! s:ToggleBlockCommentWork(firstln, lastln)
    let l:firstln = a:firstln
    let l:lastln = a:lastln

    " get comment chars
    let l:cs = g:GetBlockCommentStrings(s:GuessSyntaxRegion(l:firstln, 1))
    let l:ci = s:GetCommentInfo(l:cs)

    " join bottom block

    " loop starts at bottom (to avoid confusion about deleted lines) 
    let l:type = 'w'
    let l:startln = l:lastln
    let l:stopln = l:lastln
    let l:lineNo = l:lastln
    while l:lineNo >= l:firstln
        let l:line = getline(l:lineNo)
        let l:indent = s:ColToPhysical(l:line, indent(l:lineNo))

        let l:do_comment = 0
        let l:do_uncomment = 0
        let l:decrement = 0

        " comment
        if l:line =~ l:ci['cPat'] || l:line =~ l:ci['mPat']
            if l:type == 'w'
                let l:stopln = l:lineNo
            elseif l:type == 'tw'
                let l:do_comment = 1
            elseif l:type == 't'
                let l:do_comment = 1
                let l:startln = l:lineNo + 1
            endif
            let l:type = 'c'

        " text
        elseif !s:IsBlank(l:line)
            if l:type == 'w'
                let l:stopln = l:lineNo
            elseif l:type == 'c'
                let l:do_uncomment = 1
                let l:startln = l:lineNo + 1
            endif
            let l:type = 't'

        " blank
        else
            if l:type == 'c'
                let l:type = 'w'
                let l:do_uncomment = 1
                let l:startln = l:lineNo + 1
            elseif l:type == 't'
                let l:type = 'tw'
                let l:startln = l:lineNo + 1
            endif
        endif

        " do current block
        if l:do_comment
            call s:BlockCommentWork(l:startln, l:stopln, 1, 1)
            let l:stopln = l:lineNo
        elseif l:do_uncomment
            call s:BlockUnCommentWork(l:startln, l:stopln)
            let l:stopln = l:lineNo
        endif

        let l:lineNo -= 1
    endwhile

    let l:do_comment = 0
    let l:do_uncomment = 0

    " do last block
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
        call s:BlockCommentWork(l:startln, l:stopln, 1, 1)
        let l:stopln = l:lineNo
    elseif l:do_uncomment
        call s:BlockUnCommentWork(l:startln, l:stopln)
        let l:stopln = l:lineNo
    endif
endfunction
" 3}}}
" 2}}}

" normal comments {{{2
" add simple comments {{{3
" TODO: handle BackupComment() properly
function! s:Comment() range
    let l:cs = g:GetCommentStrings(s:GuessSyntaxRegion(a:firstline))
    let l:ci = s:GetCommentInfo(l:cs)

    for l:lineNo in range(a:firstline, a:lastline)
        let l:line = getline(l:lineNo)
        if !s:IsBlank(l:line)
            call setline(l:lineNo, s:AddComment(l:line, l:ci))
        endif
    endfor
endfunction

" remove simple comments {{{3
function! s:UnComment() range
    let l:cs = g:GetCommentStrings(s:GuessSyntaxRegion(a:firstline))
    let l:ci = s:GetCommentInfo(l:cs)

    for l:lineNo in range(a:firstline, a:lastline)
        let l:line = getline(l:lineNo)
        if !s:IsBlank(l:line)
            let [l:isComment, l:text] = s:RemoveComment(l:line, l:ci)
            if l:isComment
                call setline(l:lineNo, l:text)
            endif
        endif
    endfor
endfunction

" toggle simple comments {{{3
function! s:ToggleComment() range
    let l:cs = g:GetCommentStrings(s:GuessSyntaxRegion(a:firstline))
    let l:ci = s:GetCommentInfo(l:cs)

    for l:lineNo in range(a:firstline, a:lastline)
        let l:line = getline(l:lineNo)
        if !s:IsBlank(l:line)
            let [l:isComment, l:text] = s:RemoveComment(l:line, l:ci)
            if l:isComment
                call setline(l:lineNo, l:text)
            else
                call setline(l:lineNo, s:AddComment(l:line, l:ci))
            endif
        endif
    endfor
endfunction
" 3}}}
" 2}}}
" 1}}}

" vim: fdm=marker fdl=0
