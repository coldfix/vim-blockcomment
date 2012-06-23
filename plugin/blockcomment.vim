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

if v:version < 700 || !has("eval") || !has("autocmd")
    echoerr 'blockcomment requires VIM 7, compiled with +eval +autocmd'
    " Note:
    " +autocmd: &ft
    " +eval:    substitute
    finish
endif

" Agenda:
" > join neighboring comment blocks if overlap is detected
" > Backup and restore comment termination sequences when required
" > provide bindings to be used with a motion command
" > smarter pointer restorage
" > 

" TODO: check if repeat#set is present
" TODO: whitespace when uncommenting blank lines...?
" TODO: action when toggle blank lines?
" TODO: if GuessSyntaxRegion(firstline) != GuessSyntaxRegion(lastline) ..

" mappings {{{1
" plugins {{{2
map <silent> <Plug>BlockComment       :call <SID>BlockComment()<CR>:silent! call repeat#set("\<Plug>BlockComment")<CR>
map <silent> <Plug>BlockUnComment     :call <SID>BlockUnComment()<CR>:silent! call repeat#set("\<Plug>BlockUnComment")<CR>
map <silent> <Plug>ToggleBlockComment :call <SID>ToggleBlockComment()<CR>:silent! call repeat#set("\<Plug>ToggleBlockComment")<CR>

map <silent> <Plug>RBlockComment       :call <SID>RBlockComment()<CR>:silent! call repeat#set("\<Plug>RBlockComment")<CR>
map <silent> <Plug>RBlockUnComment     :call <SID>RBlockUnComment()<CR>:silent! call repeat#set("\<Plug>RBlockUnComment")<CR>
map <silent> <Plug>ToggleRBlockComment :call <SID>ToggleRBlockComment()<CR>:silent! call repeat#set("\<Plug>ToggleRBlockComment")<CR>

map <silent> <Plug>Comment            :call <SID>Comment()<CR>:silent! call repeat#set("\<Plug>Comment")<CR>
map <silent> <Plug>UnComment          :call <SID>UnComment()<CR>:silent! call repeat#set("\<Plug>UnComment")<CR>
map <silent> <Plug>ToggleComment      :call <SID>ToggleComment()<CR>:silent! call repeat#set("\<Plug>ToggleComment")<CR>

" key mappings {{{2
map <silent> \\a    <Plug>BlockComment
map <silent> \\u    <Plug>BlockUnComment
map <silent> \\\    <Plug>ToggleBlockComment

map <silent> \0a    <Plug>RBlockComment
map <silent> \0u    <Plug>RBlockUnComment
map <silent> \00    <Plug>ToggleRBlockComment

map <silent> \"a    <Plug>Comment
map <silent> \"u    <Plug>UnComment
map <silent> \""    <Plug>ToggleComment
" 2}}}
" 1}}}

" Comment strings {{{1
" SingleLineComment: filetype => [left, fillchar]
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

" MultiLineComment: filetype => [start, stop, left, right, fillchar]
let g:MultiLineComment = {
    \ 'c':        ['/*',    '*/', '*',  '', '*'],
    \ 'css':      ['/*',    '*/', '*',  '', '*'],
    \ 'entity':   ["<!--", '-->', ' !', '', ''],
    \ 'html':     ["<!--", '-->', ' !', '', ''],
    \ 'markdown': ["<!--", '-->', ' !', '', ''],
    \ 'xml':      ["<!--", '-->', ' !', '', '']
    \ }

let g:SyntaxRegions = {
    \ 'php': [['', 'html'], ['html.*', 'html'],
    \           ['phpRegion', 'php'], ['javaScript', 'javascript']],
    \ 'html': [['', 'html'], ['html.*', 'html'],
    \           ['javaScript', 'javascript']]
    \ }

function! g:GetBlockCommentStrings(filetype)
    let l:repeat = 40
    " prefer single-line comments
    if has_key(g:SingleLineComment, a:filetype)
        let l:config = g:SingleLineComment[a:filetype]
        return {
        \ 'fill':   l:config[1],
        \ 'inner': [l:config[0], ''],
        \ 'outer': [l:config[0], '']
        \ }
    " alternatively use multi-line comments
    elseif has_key(g:MultiLineComment, a:filetype)
        let l:config = g:MultiLineComment[a:filetype]
        return {
        \ 'fill':   l:config[4],
        \ 'inner': [l:config[2], l:config[3]],
        \ 'outer': [l:config[0], l:config[1]]
        \ }
    " take a guess, using VIM &cms
    elseif has('folding') && (&cms != '')
        let [l:left, l:right] = split(&cms,'%s',1)
        " single-line
        if l:right == ''
            return {
            \ 'fill':  '-',
            \ 'inner': [l:left, ''],
            \ 'outer': [l:left, '']
            \ }
        " multi-line
        else
            return {
            \ 'fill':   '-',
            \ 'inner': ['-', ''],
            \ 'outer': [l:left, l:right]
            \ }
        endif
    " default to '#'
    else
        return {
        \ 'fill':   '-',
        \ 'inner': ['#', ''],
        \ 'outer': ['#', '']
        \ ] }
    endif
endfunction

function! g:GetRBlockCommentStrings(filetype)
    " prefer single-line comments
    if has_key(g:SingleLineComment, a:filetype)
        let l:config = g:SingleLineComment[a:filetype]
        return {
        \ 'fill':   l:config[1]==''?' ':l:config[1],
        \ 'inner': [l:config[0], l:config[0]],
        \ 'outer': [l:config[0], l:config[0]]
        \ }
    " alternatively use multi-line comments
    elseif has_key(g:MultiLineComment, a:filetype)
        let l:config = g:MultiLineComment[a:filetype]
        return {
        \ 'fill':   l:config[4]==''?' ':l:config[4],
        \ 'inner': [l:config[0], l:config[1]],
        \ 'outer': [l:config[0], l:config[1]]
        \ }
    " take a guess, using VIM &cms
    elseif has('folding') && (&cms != '')
        let [l:left, l:right] = split(&cms,'%s',1)
        if l:right == ''
            return {
            \ 'fill':  '-',
            \ 'inner': [l:left, l:left],
            \ 'outer': [l:left, l:left]
            \ }
            return [l:left, l:left]
        else
            return {
            \ 'fill':  '-',
            \ 'inner': [l:left, l:right],
            \ 'outer': [l:left, l:right]
            \ }
        endif
    " default to '#'
    else
        return {
        \ 'fill':   '-',
        \ 'inner': ['#', '#'],
        \ 'outer': ['#', '#']
        \ }
    endif
endfunction

function! g:GetCommentStrings(filetype)
    " prefer single-line comments
    if has_key(g:SingleLineComment, a:filetype)
        let l:config = g:SingleLineComment[a:filetype]
        return {'fill': l:config[1], 'inner': [l:config[0], '']}
    " alternatively use multi-line comments
    elseif has_key(g:MultiLineComment, a:filetype)
        let l:config = g:MultiLineComment[a:filetype]
        return {'fill': l:config[4], 'inner': [l:config[0], l:config[1]]}
    " take a guess, using VIM &cms
    elseif has('folding') && (&cms != '')
        return {'fill': '-', 'inner': split(&cms,'%s',1)}
    " default to '#'
    else
        return {'fill': '-', 'inner': ['#', '']}
    endif
endfunction

function! s:GetCommentPatterns(ci)
    " cPat matches: [leading-ws, text, trailing-ws]
    let l:ci = extend(a:ci, {
        \ 'lIns': substitute(a:ci['inner'][0],'\S\zs$',' ',''),
        \ 'rIns': substitute(a:ci['inner'][1],'^\ze\S',' ',''),
        \ 'cPat': '\v^(\s*)\V'.escape(a:ci['inner'][0],'\').
        \         '\v ?(.{-}) {-}\V'.escape(a:ci['inner'][1],'\').
        \         '\v(\s*)$'
        \ })
    " marker
    if has_key(l:ci, 'outer')
        let l:ci.aPat = '\V\^\s\*'.escape(l:ci['outer'][0], '\').
                            \ '\('.escape(l:ci['fill'], '\').'\)\+'.
                            \      escape(l:ci['inner'][1], '\').'\s\*\$'
        let l:ci.oPat = '\V\^\s\*'.escape(l:ci['inner'][0], '\').
                            \ '\('.escape(l:ci['fill'], '\').'\)\+'.
                            \      escape(l:ci['outer'][1], '\').'\s\*\$'
        if l:ci['aPat'] == l:ci['oPat']
            let l:ci.mPat = l:ci['aPat']
        else
            let l:ci.mPat = '\('.l:ci['aPat'].'\)\|\('.l:ci['oPat'].'\)'
        endif
    endif
    return l:ci
endfunction

function! s:GetCommentMarker(ci, ...)
    if a:0 > 0 && a:1 > 0
        let l:awidth = a:1-strlen(a:ci['outer'][0])-strlen(a:ci['inner'][1])
        let l:owidth = a:1-strlen(a:ci['inner'][0])-strlen(a:ci['outer'][1])
    else
        let l:awidth = 40
        let l:owidth = 40
    endif
    let l:arep = a:ci['fill'] == '' ? 0 : l:awidth / strlen(a:ci['fill'])
    let l:orep = a:ci['fill'] == '' ? 0 : l:owidth / strlen(a:ci['fill'])
    return [
        \ a:ci['outer'][0].repeat(a:ci['fill'], l:arep).a:ci['inner'][1],
        \ a:ci['inner'][0].repeat(a:ci['fill'], l:orep).a:ci['outer'][1]
    \ ]
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
    let l:ci = s:GetCommentPatterns(g:GetBlockCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    call s:BlockCommentWork(a:firstline, a:lastline, l:ci, 1, 1)
endfunction
function! s:BlockUnComment() range
    let l:ci = s:GetCommentPatterns(g:GetBlockCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    call s:BlockUnCommentWork(a:firstline, a:lastline, l:ci)
endfunction
function! s:ToggleBlockComment() range
    let l:ci = s:GetCommentPatterns(g:GetBlockCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    call s:ToggleBlockCommentWork(a:firstline, a:lastline, l:ci)
endfunction

" block (=aligned) commenting {{{3
function! s:BlockCommentWork(firstln, lastln, ci, mayprepend, mayappend)
    let l:pos = getpos('.')

    " detect alignment
    let [l:lCol, l:lNo, l:pad] = s:GetMultilineIndent(a:firstln, a:lastln)
    if a:ci['inner'][1] != ''
        let l:rCol = s:GetDisplayWidth(a:firstln, a:lastln)
        let l:rCol += strlen(a:ci['lIns'])
    else
        let l:rCol = -1
    endif

    " perform commenting
    for l:lineNo in range(a:firstln, a:lastln)
        let l:line = getline(l:lineNo)
        if s:IsBlank(l:line) && l:line !~ '\v^\s*%'.(l:lCol+1).'v'
            let l:line = l:pad
        endif
        call setline(l:lineNo, s:AddCommentAlign(l:line, a:ci, l:lCol, l:rCol))
    endfor

    " append/prepend block markers
    if a:mayprepend || a:mayappend
        let l:ms = s:GetCommentMarker(a:ci, l:rCol-l:lCol+strlen(a:ci['rIns']))
    endif
    if a:mayappend
        call append(a:lastln, l:pad . l:ms[1])
    endif
    if a:mayprepend
        call append(a:firstln - 1, l:pad . l:ms[0])
        let l:pos[1] += 1
    endif

    " restore cursor
    call setpos('.', l:pos)
endfunction

" block uncommenting {{{3
function! s:BlockUnCommentWork(firstln, lastln, ci)
    let l:firstln = a:firstln
    let l:lastln = a:lastln
    let l:pos = getpos('.')
    let l:cStart = 0
    let l:cEnd = 0

    " loop for each line
    let l:lineNo = l:firstln
    while l:lineNo <= l:lastln
        let l:line = getline(l:lineNo)
        " block comment start/stop line - delete line
        if l:line =~ a:ci['mPat'] 
            execute l:lineNo . 'd'
            if l:lineNo < l:pos[1]
                let l:pos[1] -= 1
            endif
            let l:lineNo -= 1
            let l:lastln -= 1
        " commented code line - remove comment
        else
            let [l:isComment, l:text] = s:RemoveComment(l:line, a:ci)
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
        if l:line =~ a:ci['aPat']
            execute (l:firstln - 1) . 'd'
            let l:firstln -= 1
            let l:lastln -= 1
            let l:pos[1] -= 1
        else
            let l:match = matchlist(l:line, a:ci['cPat'])[1:3]
            " abandoned commented code line - insert end comment block line
            if !empty(l:match)
                let l:ms = s:GetCommentMarker(a:ci)
                call append(l:firstln - 1, l:match[0] . l:ms[1])
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
        if l:line =~ a:ci['oPat']
            execute (l:lastln + 1) . 'd'
            let l:lastln = l:lastln - 1
        else
            let l:match = matchlist(l:line, a:ci['cPat'])[1:3]
            " abandoned commented code line - insert begin comment block line
            if !empty(l:match)
                let l:ms = s:GetCommentMarker(a:ci)
                call append(l:lastln, l:match[0] . l:ms[0])
            endif
        endif
    endif

    " restore cursor
    call setpos('.', l:pos)
endfunction

" toggle block comments {{{3
function! s:ToggleBlockCommentWork(firstln, lastln, ci)
    " loop starts at bottom (to avoid confusion about deleted lines) 
    let l:type = 'w'    " w=whitespace, t=text, c=comment, tw=t->w
    let l:stopln = a:lastln
    let l:lineNo = a:lastln
    let l:workDone = 0
    while l:lineNo >= a:firstln
        let l:line = getline(l:lineNo)
        " comment
        if l:line =~ a:ci['cPat'] || l:line =~ a:ci['mPat']
            while l:lineNo >= a:firstln
                let l:line = getline(l:lineNo)
                if l:line !~ a:ci['cPat'] && l:line !~ a:ci['mPat']
                    break
                endif
                let l:lineNo -= 1
            endwhile
            call s:BlockUnCommentWork(l:lineNo+1, l:stopln, a:ci)
            let l:stopln = l:lineNo
            let l:workDone = 1
        " blank
        elseif s:IsBlank(l:line)
            let l:lineNo -= 1
        " text
        else
            while l:lineNo >= a:firstln
                let l:line = getline(l:lineNo)
                if l:line =~ a:ci['cPat'] || l:line =~ a:ci['mPat']
                    break
                endif
                let l:lineNo -= 1
            endwhile
            call s:BlockCommentWork(l:lineNo+1, l:stopln, a:ci, 1, 1)
            let l:stopln = l:lineNo
            let l:workDone = 1
        endif
    endwhile
    if !l:workDone
        call s:BlockCommentWork(a:firstln, a:lastln, a:ci, 1, 1)
    endif
endfunction
" 3}}}
" 2}}}
" ralign-block comments {{{2
function! s:RBlockComment() range
    let l:ci = s:GetCommentPatterns(g:GetRBlockCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    call s:BlockCommentWork(a:firstline, a:lastline, l:ci, 1, 1)
endfunction
function! s:RBlockUnComment() range
    let l:ci = s:GetCommentPatterns(g:GetRBlockCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    call s:BlockUnCommentWork(a:firstline, a:lastline, l:ci)
endfunction
function! s:ToggleRBlockComment() range
    let l:ci = s:GetCommentPatterns(g:GetRBlockCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    call s:ToggleBlockCommentWork(a:firstline, a:lastline, l:ci)
endfunction

" normal comments {{{2
" add simple comments {{{3
" TODO: handle BackupComment() properly
function! s:Comment() range
    let l:ci = s:GetCommentPatterns(g:GetCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
    for l:lineNo in range(a:firstline, a:lastline)
        let l:line = getline(l:lineNo)
        if !s:IsBlank(l:line)
            call setline(l:lineNo, s:AddComment(l:line, l:ci))
        endif
    endfor
endfunction

" remove simple comments {{{3
function! s:UnComment() range
    call s:UnCommentWork(a:firstline, a:lastline)
endfunction

function! s:UnCommentWork(firstln, lastln)
    let l:ci = s:GetCommentPatterns(g:GetCommentStrings(s:GuessSyntaxRegion(a:firstln, 1)))
    for l:lineNo in range(a:firstln, a:lastln)
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
    let l:ci = s:GetCommentPatterns(g:GetCommentStrings(s:GuessSyntaxRegion(a:firstline, 1)))
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
