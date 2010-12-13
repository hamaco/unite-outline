"=============================================================================
" File    : autoload/unite/source/outline/util.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2010-12-13
" Version : 0.1.7
" License : MIT license {{{
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"   
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"   
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

function! unite#sources#outline#util#capitalize(str, ...)
  let flag = (a:0 ? a:1 : '')
  return substitute(a:str, '\<\(\u\)\(\u\+\)\>', '\u\1\L\2', flag)
endfunction

function! unite#sources#outline#util#indent(level)
  return repeat(' ', (a:level - 1) * g:unite_source_outline_indent_width)
endfunction

function! unite#sources#outline#util#join_to(lines, idx, pattern, ...)
  let limit = (a:0 ? a:1 : 3)
  if limit < 0
    return s:join_to_backward(a:lines, a:idx, a:pattern, limit * -1)
  endif
  let idx = a:idx
  let lim_idx = min([a:idx + limit, len(a:lines) - 1])
  while idx <= lim_idx
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx += 1
  endwhile
  return join(a:lines[a:idx : idx], "\n")
endfunction

function! s:join_to_backward(lines, idx, pattern, ...)
  let limit = (a:0 ? a:1 : 3)
  let idx = a:idx
  let lim_idx = max(0, a:idx - limit])
  while idx > 0
    let line = a:lines[idx]
    if line =~ a:pattern
      break
    endif
    let idx -= 1
  endwhile
  return join(a:lines[idx : a:idx], "\n")
endfunction

function! unite#sources#outline#util#neighbor_match(lines, idx, pattern, ...)
  let nb = (a:0 ? a:1 : 1)
  if type(nb) == type([])
    let prev = nb[0]
    let next = nb[1]
  else
    let prev = nb
    let next = nb
  endif
  let nb_range = range(max([0, a:idx - prev]), min([a:idx + next, len(a:lines) - 1]))
  for idx in nb_range
    if a:lines[idx] =~ a:pattern
      return 1
    endif
  endfor
  return 0
endfunction

let s:shared_patterns = {
      \ 'c': {
      \   'heading-1': '^\s*\/\*\s*[-=*]\{10,}\s*$',
      \   'header'   : ['^/\*', '\*/\s*$'],
      \ },
      \ 'cpp': {
      \   'heading-1': '^\s*\(//\|/\*\)\s*[-=/*]\{10,}\s*$',
      \   'header'   : {
      \     'leading': '^//',
      \     'block'  : ['^/\*', '\*/\s*$'],
      \   },
      \ },
      \ 'sh': {
      \   'heading-1': '^\s*#\s*[-=#]\{10,}\s*$',
      \   'header'   : '^#',
      \ },
      \}

function! unite#sources#outline#util#shared_pattern(filetype, which)
  let ft_patterns = s:shared_patterns[a:filetype]
  return ft_patterns[a:which]
endfunction

" vim: filetype=vim