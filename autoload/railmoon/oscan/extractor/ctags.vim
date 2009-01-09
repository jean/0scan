" Author: Mykola Golubyev ( Nickolay Golubev )
" Email: golubev.nikolay@gmail.com
" Site: www.railmoon.com
" Plugin: oscan
" Module: extractor#ctags
" Purpose: extract ctags record from buffer

function! railmoon#oscan#extractor#ctags#create()
    let new_extractor = copy(s:tag_scan_ctags_extractor)

    let new_extractor.file_name = expand("%:p")
    let new_extractor.buffer_number = bufnr('%')
    let new_extractor.file_extension = expand("%:e")
    let new_extractor.filetype = &filetype
    let new_extractor.description = 'Extract ctags records from "'.new_extractor.file_name.'"'

    return new_extractor
endfunction

function! railmoon#oscan#extractor#ctags#language_function(language, function_name,...)
    call railmoon#trace#debug( 'call language_function "'.a:function_name.'" for "'.a:language.'"' )
    try
        let result = eval('railmoon#oscan#extractor#ctags#'.a:language.'#'.a:function_name.'('.join(a:000,',').')')
    catch /.*/
        call railmoon#trace#debug( 'failed.['.v:exception.'] use cpp' )
        let result = eval('railmoon#oscan#extractor#ctags#cpp#'.a:function_name.'('.join(a:000,',').')')
    endtry

    return result
endfunction

" by language name return kinds to use while ctags build tags base
" default language c++
function! railmoon#oscan#extractor#ctags#kind_types_for_langauge(language)
    return railmoon#oscan#extractor#ctags#language_function(a:language, 'kinds')
endfunction

function! railmoon#oscan#extractor#ctags#process(tag_item)
    try
        let previous_magic = &magic
        set nomagic

        exec 'edit +'.escape(a:tag_item.cmd, ' ').' '.a:tag_item.filename
    finally
        let &magic = previous_magic
    endtry
endfunction

" by language name and ctags tag return record
" default language c++
function! railmoon#oscan#extractor#ctags#record_for_language_tag( language, ctag_item )
    return railmoon#oscan#extractor#ctags#language_function( a:language, 'record', a:ctag_item )
endfunction

" return language name by extension
" default language c++
function! railmoon#oscan#extractor#ctags#language_by_extension( extension )
    if index(['c', 'cpp', 'h', 'cxx', 'hxx', 'cc', 'hh', 'hpp'], a:extension) != -1
        return 'cpp'
    elseif a:extension == 'vim'
        return 'vim'
    elseif a:extension == 'pl'
        return 'perl'
    elseif a:extension == 'py'
        return 'python'
    endif

    return 'cpp'
endfunction

let s:tag_scan_ctags_extractor = {}
function! s:tag_scan_ctags_extractor.process(record)
    call railmoon#oscan#extractor#ctags#process(a:record.data)
endfunction

function! s:tag_scan_ctags_extractor.extract()
    let result = []

    let extension = self.file_extension
    let language = exists( '&filetype' ) ? &filetype : railmoon#oscan#extractor#ctags#language_by_extension(extension)
    let self.language = language

    let language_for_ctags = language
    if language_for_ctags == 'cpp'
        let language_for_ctags = 'c++'
    endif

    " fields 
    " f - file name
    " s - structures
    " i - inherits
    " k - kinds
    " K - kinds full writted 
    " a - access
    " l - language
    " t,m,z - unknown for me yet
    " n - line numbers
    " S - signature
    " extra 
    " q - tag names include namespace
    " f - file names added
    let ctags_tags = railmoon#ctags_util#taglist_for_file(self.file_name, language_for_ctags, railmoon#oscan#extractor#ctags#kind_types_for_langauge(language), 'sikaS')

    for item in ctags_tags
        let record = railmoon#oscan#extractor#ctags#record_for_language_tag(language, item)
        
        " no need file name to show in each row ( all tags in one file )
        let record.additional_info = ''

        call add(result, record)
    endfor

    return result
endfunction

function! railmoon#oscan#extractor#ctags#colorize_keywords()
    syntax keyword Type variable inner field enumeration function method public private
    syntax keyword Keyword constructor destructor
    syntax keyword Identifier declaration
endfunction

function! s:tag_scan_ctags_extractor.colorize()
    let &filetype = self.filetype
    call railmoon#oscan#extractor#ctags#colorize_keywords()
endfunction
