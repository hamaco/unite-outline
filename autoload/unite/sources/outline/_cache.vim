"=============================================================================
" File    : autoload/unite/source/outline/_cache.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2011-01-04
" Version : 0.2.0
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

function! unite#sources#outline#_cache#instance()
  return s:cache
endfunction

" singleton
let s:cache = { 'data': {} }

function! s:cache.has_data(path)
  return has_key(self.data, a:path) || s:exists_cache_file(a:path)
endfunction

function! s:exists_cache_file(path)
  return (g:unite_source_outline_cache_dir != '' && filereadable(s:cache_file_path(a:path)))
endfunction

function! s:cache_file_path(path)
  let path = substitute(a:path, '^/', '', '')
  return g:unite_source_outline_cache_dir . '/' . path
endfunction

function! s:cache.get_data(path)
  if !has_key(self.data, a:path) && s:exists_cache_file(a:path)
    let self.data[a:path] = s:load_cache_file(a:path)
  endif
  let item = self.data[a:path]
  let item.touched = localtime()
  return item.candidates
endfunction

function! s:load_cache_file(path)
  try
    let cache_file = s:cache_file_path(a:path)
    let dumped_data = readfile(cache_file)[0]
    " update the timestamp of the file
    call writefile([dumped_data], cache_file)
    return eval(dumped_data)
  catch
    call unite#util#print_error(
          \ "unite-outline: could not load the cache file: " . cache_file)
    return []
  endtry
endfunction

function! s:cache.set_data(path, cands, should_serialize)
  let self.data[a:path] = {
        \ 'candidates': a:cands,
        \ 'touched'   : localtime(),
        \ }
  let cache_items = items(self.data)
  let num_deletes = len(cache_items) - g:unite_source_outline_cache_buffers
  if num_deletes > 0
    call map(cache_items, '[v:key, v:val.timestamp]')
    call sort(cache_items, 's:compare_timestamp')
    let delete_keys = map(cache_items[0 : num_deletes - 1], 'v:val[0]')
    for path in delete_keys
      unlet self.data[path]
    endfor
  endif
  if a:should_serialize && g:unite_source_outline_cache_dir != ''
    call s:save_cache_file(a:path, self.data[a:path])
  endif
endfunction

function! s:save_cache_file(path, data)
  try
    let cache_file = s:cache_file_path(a:path)
    let dir = unite#util#path2directory(cache_file)
    if !isdirectory(dir) | call mkdir(dir, 'p') | endif
    let dumped_data = string(a:data)
    call writefile([dumped_data], cache_file)
  catch
    call unite#util#print_error(
          \ "unite-outline: could not save the cache to: " . cache_file)
    return
  endtry
  call s:cleanup_old_cache_files()
endfunction

function! s:cleanup_old_cache_files()
  let cache_files = split(globpath(g:unite_source_outline_cache_dir, '**/*'), "\<NL>")
  call filter(cache_files, 'filereadable(v:val)')
  let num_deletes = len(cache_files) - g:unite_source_outline_cache_buffers
  if num_deletes > 0
    call map(cache_files, '[v:val, getftime(v:val)]')
    call sort(cache_files, 's:compare_timestamp')
    let delete_files = map(cache_files[0 : num_deletes - 1], 'v:val[0]')
    for path in delete_files
      call s:delete_cache_file(path)
    endfor
  endif
endfunction

if unite#util#is_win() && !executable('rm')
  let s:rmdir_command = 'rmdir /Q /S $srcs'
else
  let s:rmdir_command = 'rm -r $srcs'
endif

function! s:delete_cache_file(path)
  try
    call delete(a:path)
  catch
    call unite#util#print_error(
          \ "unite-outline: could not delete the cache file: " . a:path)
  endtry
  call s:delete_empty_dirs(a:path)
endfunction

function! s:delete_empty_dirs(path)
  let dir = unite#util#path2directory(a:path)
  while 1
    if dir ==# g:unite_source_outline_cache_dir || len(globpath(dir, '*')) > 0
      break
    endif
    call s:delete_dir(dir)
    let dir = fnamemodify(a:path, ':p:h'))
  endwhile
endfunction

function! s:delete_dir(path)
  try
    call system(s:rmdir_command . ' "' . a:path . '"')
  catch
    call unite#util#print_error(
          \ "unite-outline: could not delete the directory: " . a:path)
  endtry
endfunction

function! s:compare_timestamp(pair1, pair2)
  let t1 = a:pair1[1]
  let t2 = a:pair2[1]
  return t1 == t2 ? 0 : t1 > t2 ? 1 : -1
endfunction

" vim: filetype=vim