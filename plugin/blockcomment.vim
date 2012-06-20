" ToggleComment.vim
" Authors: Thomas Gläßle
" Version: 1.0
" License: GPL v2.0 
" 
" Description:
" This script defines functions and key mappings to comment code.
" 
" Installation:
" Simply drop this file into your plugin directory.
" 
" Changelog:
" 

" if exists("loaded_toggle_comment")
	" finish
" endif
" let loaded_toggle_comment = 1


" mappings {{{1
" plugins {{{2
map <silent> <Plug>BlockComment             :call <SID>BlockComment()<CR>:silent! call repeat#set("\<Plug>BlockComment")<CR>
map <silent> <Plug>BlockUnComment           :call <SID>BlockUnComment()<CR>:silent! call repeat#set("\<Plug>BlockUnComment")<CR>
map <silent> <Plug>ToggleBlockComment       :call <SID>ToggleBlockComment()<CR>:silent! call repeat#set("\<Plug>ToggleBlockComment")<CR>

map <silent> <Plug>Comment                  :call <SID>Comment()<CR>:silent! call repeat#set("\<Plug>Comment")<CR>
map <silent> <Plug>UnComment                :call <SID>UnComment()<CR>:silent! call repeat#set("\<Plug>UnComment")<CR>
map <silent> <Plug>ToggleComment            :call <SID>ToggleComment()<CR>:silent! call repeat#set("\<Plug>ToggleComment")<CR>

map <silent> <Plug>AddMarker_Open       :call <SID>AddMarker(1, 0, 1, 0)<CR>:silent! call repeat#set("\<Plug>AddMarker_Open")<CR>
map <silent> <Plug>AddMarker_Close      :call <SID>AddMarker(1, 0, 0, 1)<CR>:silent! call repeat#set("\<Plug>AddMarker_Close")<CR>
map <silent> <Plug>AddMarker_Surround   :call <SID>AddMarker(1, 1, 1, 1)<CR>:silent! call repeat#set("\<Plug>AddMarker_Surround")<CR>

" key mappings {{{2
map <silent> \a    <Plug>BlockComment
map <silent> \u    <Plug>BlockUnComment
map <silent> \"    <Plug>ToggleBlockComment
                    
map <silent> \c    <Plug>Comment
map <silent> \t    <Plug>UnComment
map <silent> \\    <Plug>ToggleComment
                    
map <silent> \e    <Plug>AddMarker_Open
map <silent> \i    <Plug>AddMarker_Close
map <silent> \I    <Plug>AddMarker_Surround

noremap <silent> <F3> :exe '/{'.'{{' <CR>
" 2}}}
" 1}}}
" Implementation {{{1
" utility functions {{{2
" Set comment characters by filetype
function! s:getCommentStrings()
    let s:comment_save1 = '('
    let s:comment_save2 = ')'
	if &ft == "vim"
		let s:comment_strt = '"'
		let s:comment_mid = '"'
		let s:comment_stop = ''
		let s:comment_bkup = 0
	elseif &ft == "c" || &ft == "css"
		let s:comment_strt = '/*'
		let s:comment_mid = '*'
		let s:comment_stop = '*/'
		let s:comment_bkup = 1
		let s:comment_strtbak = '/ *'
		let s:comment_stopbak = '* /'
	elseif &ft == "cpp" || &ft == "java" || &ft == "javascript" || &ft == "php" || &ft == "xkb"
		let s:comment_strt = '//'
		let s:comment_mid = '//'
		let s:comment_stop = ''
		let s:comment_bkup = 0
	elseif &ft == "asm" || &ft == "lisp" || &ft == "scheme"
		let s:comment_strt = ';'
		let s:comment_mid = ';'
		let s:comment_stop = ''
		let s:comment_bkup = 0
    elseif &ft == "lua"
		let s:comment_strt = '--'
		let s:comment_mid = '--'
		let s:comment_stop = ''
		let s:comment_bkup = 0
	elseif &ft == "vb"
		let s:comment_strt = '\''
		let s:comment_mid = '\''
		let s:comment_stop = ''
		let s:comment_bkup = 0
	elseif &ft == "sql"
		let s:comment_strt = '--'
		let s:comment_mid = '--'
		let s:comment_stop = ''
		let s:comment_bkup = 0
	elseif &ft == "tex" || &ft == "plaintex"
		let s:comment_strt = '%'
		let s:comment_mid = '%'
		let s:comment_stop = ''
		let s:comment_bkup = 0
	elseif &ft == "html" || &ft == "xml" || &ft == "entity"
		let s:comment_strt = '<!--'
		let s:comment_mid = '!'
		let s:comment_stop = '-->'
		let s:comment_bkup = 1
		let s:comment_strtbak = '< !--'
		let s:comment_stopbak = '-- >'
	else
		let s:comment_strt = '#'
		let s:comment_mid = '#'
		let s:comment_stop = ''
		let s:comment_bkup = 0
	endif
	let s:comment_pad = '-------------------------------------------------'
	let s:comment_start_mark = s:comment_strt . s:comment_pad . s:comment_save1
	let s:comment_stop_mark = s:comment_mid . s:comment_pad . s:comment_save2 . s:comment_stop
	let s:comment_mid0 = s:comment_mid . ' '
endfunction

" retrieve byte index corresponding to a virtual index
function! s:byteIndex(string, virtual_index)
    let l:byte_index = 0
    let l:vindex = 0
    while l:vindex < a:virtual_index
        if strpart(a:string, l:byte_index, 1) == "\t"
            let l:vindex += &tabstop - (l:vindex % &tabstop)
        else
            let l:vindex += 1
        endif
        let l:byte_index += 1
    endwhile 
    return l:byte_index
endfunction

function! s:isBlank(line)
    return a:line =~ "^\s*$"
endfunction

function! s:lineText(lineNo)
	let l:line = getline(a:lineNo)
	let l:indent = indent(a:lineNo)
	return strpart(l:line, s:byteIndex(l:line, l:indent))
endfunction

function! s:indentation (lineno)
	let l:line = getline(a:lineno)
	let l:indent = s:byteIndex(l:line, indent(a:lineno))
	let l:pad = strpart(l:line, 0, l:indent)
	return l:pad
endfunction

" block commenting {{{2
function! s:BlockComment() range
    call s:BlockCommentWork(a:firstline, a:lastline)
endfunction

function! s:DoComment(firstln, lastln, indent)
endfunction

function! s:DoUncomment(firstln, lastln)
endfunction


function! s:BlockCommentWork(firstln, lastln)
    let l:firstln = a:firstln
    let l:lastln = a:lastln

	" get comment chars
	call s:getCommentStrings()

    " get cursor position
    let l:cursor_line = line(".")
    let l:cursor_col = col(".") + strlen(s:comment_mid0)

	" get minimum indentation level among all relevant lines
    let l:indent = 0
    let l:iline = -1
    for l:midline in range(l:firstln, l:lastln)
        if !s:isBlank(getline(l:midline)) && (l:iline == -1 || indent(l:midline) < l:indent)
            let l:indent = indent(l:midline) 
            let l:iline = l:midline
        endif
    endfor

    let l:line = getline(l:iline)
    let l:pindent = s:byteIndex(l:line, l:indent)
    let l:padding = strpart(l:line, 0, l:pindent)

	let l:mayappend = 1
	let l:mayprepend = 1

	"--------------------------------------------------
	" " delete preceding / trailing block marker on fitting indentation level TODO
	" if indent(l:lastln + 1) == l:indent && s:lineText(l:lastln + 1) == s:comment_start_mark
	" 	execute (l:lastln + 1) . "d"
	" 	let l:mayappend = 0
	" endif
	" if indent(l:firstln - 1) == l:indent && s:lineText(l:firstln - 1) == s:comment_stop_mark
	" 	execute (l:firstln - 1) . "d"
	" 	let l:firstln -= 1
	" 	let l:lastln -= 1
	" 	let l:cursor_line -= 1
	" 	let l:mayprepend = 0
	" endif
	"-------------------------------------------------- 

    " append comment block end marker
	if l:mayappend
		call append(l:lastln, l:padding . s:comment_stop_mark)
	endif
    " prepend comment block start marker
	if l:mayprepend
		call append(l:firstln - 1, l:padding . s:comment_start_mark)
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
            let l:pindent = s:byteIndex(l:line, l:indent)
            let l:padding = strpart(l:line, 0, l:pindent)
            let l:line = strpart(l:line, l:pindent)

            " handle comments within comments
            if s:comment_bkup == 1
                let l:line = substitute(l:line, escape(s:comment_strt, '\*^$.~[]'), s:comment_strtbak, "g")
                let l:line = substitute(l:line, escape(s:comment_stop, '\*^$.~[]'), s:comment_stopbak, "g")
            endif
        endif

        call setline(l:midline, l:padding . s:comment_mid0 . l:line)
	endfor

	" set cursor position
    call cursor(l:cursor_line, l:cursor_col)
endfunction

" block uncommenting {{{2
function! s:BlockUnComment() range
    call s:BlockUnCommentWork(a:firstline, a:lastline)
endfunction

function! s:BlockUnCommentWork(firstln, lastln)
    let l:firstln = a:firstln
    let l:lastln = a:lastln

	" get comment chars
	call s:getCommentStrings()
	let l:clen = strlen(s:comment_mid0)

    " get cursor position
    let l:cursor_line = line(".")
    let l:cursor_col = col(".")
    " let l:comment_start = 0
    " let l:comment_end = 0

	" loop for each line
    let l:midline = l:firstln
	while l:midline <= l:lastln
		" get indent level
		let l:line = getline(l:midline)
		let l:indent = s:byteIndex(l:line, indent(l:midline))

		" begin comment block line - delete line
		if strpart(l:line, l:indent) == s:comment_start_mark
			execute l:midline . "d"
			let l:midline = l:midline - 1
			let l:lastln = l:lastln - 1 
            if l:midline < l:cursor_line
                let l:cursor_line -= 1
            endif

		" end comment block line - delete line
		elseif strpart(l:line, l:indent) == s:comment_stop_mark
			execute l:midline . "d"
			let l:midline = l:midline - 1
			let l:lastln = l:lastln - 1
            if l:midline < l:cursor_line
                let l:cursor_line -= 1
            endif

		" commented code line - remove comment
		elseif strpart(l:line, l:indent, l:clen) == s:comment_mid0
			let l:pad = strpart(l:line, 0, l:indent)
			let l:line = strpart(l:line, l:indent + l:clen)
            if l:midline == l:cursor_line && l:cursor_col >= l:indent + l:clen
                let l:cursor_col -= l:clen
            endif

            " if l:midline == l:firstln
                " let l:comment_start = 1
            " endif
            " if l:midline == l:lastln
                " let l:comment_end = 1
            " endif

			" handle comments within comments
			if s:comment_bkup == 1
				let l:line = substitute(l:line, escape(s:comment_strtbak, '\*^$.~[]'), s:comment_strt, "g")
				let l:line = substitute(l:line, escape(s:comment_stopbak, '\*^$.~[]'), s:comment_stop, "g")
			endif
			call setline(l:midline, l:pad . l:line)
		endif

		let l:midline = l:midline + 1
	endwhile

	" look at line above block
    " if l:comment_start
        let l:line = getline(l:firstln - 1)
        let l:indent = s:byteIndex(l:line, indent(l:firstln - 1))

        " abandoned begin comment block line - delete line
        if strpart(l:line, l:indent) == s:comment_start_mark
            execute (l:firstln - 1) . "d"
            let l:firstln = l:firstln - 1
            let l:lastln = l:lastln - 1
            let l:cursor_line -= 1

        " abandoned commented code line - insert end comment block line
        elseif strpart(l:line, l:indent, l:clen) == s:comment_mid0
            let l:pad = strpart(l:line, 0, l:indent)
            call append(l:firstln - 1, l:pad . s:comment_stop_mark)
            let l:lastln = l:lastln + 1
            let l:cursor_line += 1
        endif
    " endif

	" look at line below block
    " if l:comment_end
        let l:line = getline(l:lastln + 1)
        let l:indent = s:byteIndex(l:line, indent(l:lastln + 1))

        " abandoned end comment block line - delete line
        if strpart(l:line, l:indent) == s:comment_stop_mark
            execute (l:lastln + 1) . "d"
            let l:lastln = l:lastln - 1

        " abandoned commented code line - insert begin comment block line
        elseif strpart(l:line, l:indent, l:clen) == s:comment_mid0
            let l:pad = strpart(l:line, 0, l:indent)
            call append(l:lastln, l:pad . s:comment_start_mark)
        endif
    " endif

    call cursor(l:cursor_line, l:cursor_col)
endfunction

" toggle block comments {{{2
function! s:ToggleBlockComment() range
    call s:ToggleBlockCommentWork(a:firstline, a:lastline)
endfunction

function! s:ToggleBlockCommentWork(firstln, lastln) range
    let l:firstln = a:firstln
    let l:lastln = a:lastln

	" get comment chars
	call s:getCommentStrings()
    
	" get length of comment string
	let l:clen = strlen(s:comment_mid0)

	" loop for each line
    let l:type = 'w'
	let l:startln = l:lastln
	let l:stopln = l:lastln
	let l:midline = l:lastln
    while l:midline >= l:firstln
		let l:line = getline(l:midline)
        let l:indent = s:byteIndex(l:line, indent(l:midline))

		let l:do_comment = 0
		let l:do_uncomment = 0
		let l:decrement = 0

		" comment
		if strpart(l:line, l:indent) == s:comment_stop_mark || strpart(l:line, l:indent) == s:comment_start_mark || strpart(l:line, l:indent, l:clen) == s:comment_mid0
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
		elseif !s:isBlank(l:line)
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

" add simple comments {{{2
function! s:Comment() range
    call s:getCommentStrings()
    if s:comment_bkup
        call s:BlockCommentWork(a:firstline, a:lastline)
        return
    endif
    for l:midline in range(a:firstline, a:lastline)
        let l:line = getline(l:midline)
        if ! s:isBlank(l:line)
            let l:indent = s:byteIndex(l:line, indent(l:midline))
            let l:pad = strpart(l:line, 0, l:indent)
            let l:line = strpart(l:line, l:indent)
            call setline(l:midline, l:pad . s:comment_strt . ' ' . l:line) 
        endif
    endfor
endfunction

" remove simple comments {{{2
function! s:UnComment() range
    call s:getCommentStrings()
    if s:comment_bkup
        call s:BlockUnCommentWork(a:firstline, a:lastline)
        return
    endif
    let l:clen = strlen(s:comment_strt)
    for l:midline in range(a:firstline, a:lastline)
        let l:line = getline(l:midline)
        if ! s:isBlank(l:line)
            let l:indent = s:byteIndex(l:line, indent(l:midline))
            let l:pad = strpart(l:line, 0, l:indent)
            let l:line = strpart(l:line, l:indent)
            if strpart(l:line, 0, l:clen) == s:comment_strt
                let l:line = strpart(l:line, l:clen)
                if strpart(l:line, 0, 1) == ' '
                    let l:line = strpart(l:line, 1)
                endif
                call setline(l:midline, l:pad . l:line)
            endif
        endif
    endfor
endfunction


"--------------------------------------------------
" toggle simple comments
"-------------------------------------------------- 
function! s:ToggleComment() range
    call s:getCommentStrings()
    if s:comment_bkup
        call s:ToggleUnCommentWork(a:firstline, a:lastline)
        return
    endif
    let l:clen = strlen(s:comment_strt)
    for l:midline in range(a:firstline, a:lastline)
        let l:line = getline(l:midline)
        if ! s:isBlank(l:line)
            let l:indent = s:byteIndex(l:line, indent(l:midline))
            let l:pad = strpart(l:line, 0, l:indent)
            let l:line = strpart(l:line, l:indent)
            if strpart(l:line, 0, l:clen) == s:comment_strt
                let l:line = strpart(l:line, l:clen)
                if strpart(l:line, 0, 1) == ' '
                    let l:line = strpart(l:line, 1)
                endif
                call setline(l:midline, l:pad . l:line)
            else
                call setline(l:midline, l:pad . s:comment_strt . ' ' . l:line . s:comment_stop) 
            endif
        endif
    endfor
endfunction

" markers {{{2
function! s:AddMarker(showlevel, increase, showopen, showclose) range
    if a:showlevel 
        let l:level = foldlevel(a:firstline)
        if a:increase || l:level == 0
            let l:level += 1
        endif
    else
        let l:level = 0
    endif

    if a:showclose
        call s:CloseMarker(a:lastline, l:level)
    endif
    if a:showopen
        call s:OpenMarker(a:firstline, l:level)
    endif
endfunction

function! s:OpenMarker(line, level)
	call s:getCommentStrings()

    let l:marker = s:comment_strt . ' {{{'
    if a:level
        let l:marker .=  a:level
    endif
    let l:marker .= s:comment_stop

	call append(a:line-1, l:marker)

    call cursor(a:line, 2+strlen(s:comment_strt))
endfunction

function! s:CloseMarker(line, level)
	call s:getCommentStrings()

    let l:marker = s:comment_strt . ' '
    if a:level
        let l:marker .= a:level
    endif
    let l:marker .= '}}}' . s:comment_stop
	call append(a:line, l:marker)
endfunction

" 2}}}
" 1}}}

