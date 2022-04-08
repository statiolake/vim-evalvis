" Evaluate visual selection in Vim.
"
" Version: 0.1.0
" Author: statiolake <statiolake@gmail.com>
" License: MIT
if exists('g:loaded_evalvis')
  finish
endif
let g:loaded_evalvis = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:eval_string(expr) abort
  return eval(printf('call({-> %s}, [])', a:expr))
endfunction

function! evalvis#eval_visual() abort
  let old_reg = @a
  normal! gv"ay
  let selected = @a
  try
    let evaluated = s:eval_string(selected)
    " If evaluated value is not a string, JSON encode it.
    if type(evaluated) != v:t_string
      let evaluated = json_encode(evaluated)
    endif
    let @a = evaluated
    normal! gv"aP
  catch
    " Restore original value when error
    echohl Error
    echomsg v:exception
    echohl None
  endtry
  let @a = old_reg
endfunction

" Key mappings
xnoremap <silent> <Plug>(evalvis-eval)
  \ :<C-u>call evalvis#eval_visual()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
