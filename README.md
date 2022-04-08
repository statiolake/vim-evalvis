# vim-evalvis

Evaluate visual selection as VimScript and replace it to the result of
expression.

## Example

```
Length of hello is len("hello").
```

Selecting `len("hello")` and pressing keybind you setup results in:

```
Length of hello is 5.
```

## Keybindings

This plugin doesn't have the default keybindings. You need to set up manually.

For example, if you want to use `<C-e>` to evaluate selection, add this in
your .vimrc:

```
xmap <C-e> <Plug>(evalvis-eval)
```

Alternatively, you can call `evalvis#eval_visual()` function for this.
