
" file detection for nginx
" Source: http://www.vim.org/scripts/script.php?script_id=1886
" v1 au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/* if &ft == '' | setfiletype nginx | endif 
au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/*,/home/client/sites/*nginx*.conf if &ft == '' | setfiletype nginx | endif

" http://learnvimscriptthehardway.stevelosh.com/chapters/44.html
" Detecting Filetypes - see the exercises
au BufNewFile,BufRead nginx*.conf set filetype=nginx
