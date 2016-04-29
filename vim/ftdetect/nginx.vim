
" file detection for nginx
" Source: http://www.vim.org/scripts/script.php?script_id=1886
au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/* if &ft == '' | setfiletype nginx | endif 
