

#TEXTY_EXECUTE ruby {MYSELF}
a = <<-EOL
set tabstop=4
set shiftwidth=4
set nu
set ai
syntax on
filetype plugin indent on
EOL
print a.gsub(/[\n\r]/,"<br/>\n");

