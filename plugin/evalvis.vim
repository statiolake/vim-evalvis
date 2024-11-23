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
  let lang = get(g:, 'evalvis#language', 'vim')
  let Evaluator =
    \ lang ==# 'python3' ? function('s:eval_python3') :
    \ lang ==# 'python3-system' ? function('s:eval_python3_system') :
    \ function('s:eval_vim')
  return Evaluator(a:expr)
endfunction

function s:eval_python3(expr) abort
  return py3eval(trim(a:expr))
endfunction

function s:eval_vim(expr) abort
  return eval(trim(a:expr))
endfunction

function s:remove_indent(expr) abort
  " Remove the minimum indent from each line.
  let lines = split(a:expr, "\n")
  let non_empty_lines = filter(
    \   copy(lines),
    \   'v:val !~ ''^\s*$'''
    \ )
  if empty(non_empty_lines)
    return ['', '']
  endif

  let min_indent = min(
    \   map(copy(non_empty_lines), 'strlen(matchstr(v:val, ''^\s*''))')
    \ )
  let indent_removed = join(
    \   map(
    \     copy(non_empty_lines),
    \     'substitute(v:val, ''^\s\{' . min_indent . '}'', '''', '''')'
    \   ),
    \   "\n"
    \ )
  " Preserve indent to later restore it. Use non_empty_lines[0][0] to get the
  " indent character (space or tab usually).
  let removed_indent = repeat(non_empty_lines[0][0], min_indent)

  return [indent_removed, removed_indent]
endfunction

function s:eval_python3_system(expr) abort
  let interpreter_path = get(
    \   g:, 'evalvis#python3_system_interpreter_path',
    \   get(g:, 'python3_host_prog', 'python3')
    \ )
  let prog = substitute(a:expr, '\n\+$', '', '')
  let preserved_indent = ''
  if prog !~ "\n"
    " Treat it as a simple expression. In this mode, the evaluation result is
    " the result of the expression.
    let prog = 'print(' .. trim(prog) .. ')'
  else
    " Treat it as a multi-line script. In this mode, the evaluation result is
    " the standard output of the script.
    let [prog, preserved_indent] = s:remove_indent(prog)
  endif

  let result = system([interpreter_path], prog)
  let indent_restored = join(map(
    \   split(result, "\n"),
    \   'preserved_indent .. v:val'
    \ ), "\n")

  return substitute(indent_restored, '\n\+$', '', '')
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
