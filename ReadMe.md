# Aspell Action

This action checks spelling in one or more TeX files.


## Inputs

### `files`

**Optional** Files on which to run `aspell`. By default, the action will look for `.tex` files in all directories.

### `args`

**Optional** Arguments passed to `aspell`.


## Example Usage

```yml
uses: reitermarkus/aspell@main
with:
  files: ReadMe.md
  args: --lang=en_GB --mode=markdown
```
