*! version 1.0.0 24sep2026 -- reusable complete table styles
* Writers record their formatting intent with _mdt_format. Value and merge
* writes use overwritefmt; flush applies each completed style by reusable ID.
* RESET describes the original writer's reset semantics, not a putexcel option.
* The format-ID methods are documented in help mf_xl. The connection to the
* already-open putexcel workbook is an internal Stata handle; tested on 15.1/16.
* Cache tracks this helper's writes only. It does not import arbitrary styles
* from pre-existing target cells or external edits made between table calls.
program define _mdt_format
    version 14.1
    if "`1'"=="check" {
        local available 0
        mata: st_local("available", strofreal(findexternal("__putexcel_open_fhandle")!=NULL))
        if !`available' {
            display as error "The open putexcel workbook handle is unavailable."
            exit 498
        }
        exit
    }
    if "`1'"=="init" {
        local resetsession "`2'"
        // outfile(no) can refer to a configured but closed workbook.
        // Keep it open until the existing caller's save/close boundary.
        if "$PUTEXCEL_OPEN_FHANDLE"!="yes" {
            local wb "$PUTEXCEL_FILE_NAME"
            local ws "$PUTEXCEL_SHEET_NAME"
            local mode "$PUTEXCEL_FILE_MODE"
            if "`mode'"=="create" local mode
            if c(stata_version)<16 quietly putexcel set `"`wb'"', `mode' sheet("`ws'") open
            else quietly putexcel set `"`wb'"', `mode' sheet(`"`ws'"') open
        }
        _mdt_format check
        mata: mdt_fmt_init()
        exit
    }
    if `"`0'"'=="flush" {
        mata: mdt_fmt_flush()
        exit
    }
    syntax anything(equalok everything), [FONT(string asis) BORDER(string asis) NFORMAT(string asis) BOLD ITALIC LEFT RIGHT HCENTER VCENTER TXTWRAP MERGE RESET]
    gettoken target rest : anything, parse("=")
    local target = trim(`"`target'"')
    mata: mdt_fmt_add()
    if strpos(`"`anything'"',"=") {
        quietly putexcel `anything', overwritefmt
    }
    if "`merge'"!="" quietly putexcel `target', merge overwritefmt
end
mata:
mdt_styles=asarray_create("real",2)
mdt_history=asarray_create("string",1)
mdt_touched=asarray_create("real",2)
mdt_key=""
void mdt_fmt_init()
{
    external transmorphic scalar mdt_styles,mdt_history,mdt_touched
    external string scalar mdt_key
    string matrix oldkeys
    string scalar prefix
    real scalar i
    if(findexternal("__putexcel_open_fhandle")==NULL) _error(498,"The open putexcel workbook handle is unavailable")
    prefix=st_global("PUTEXCEL_FILE_NAME")+char(9)
    if(st_local("resetsession")!="") {
        oldkeys=asarray_keys(mdt_history)
        for(i=1;i<=rows(oldkeys);i++) if(strpos(oldkeys[i],prefix)==1) asarray_remove(mdt_history,oldkeys[i])
    }
    mdt_key=prefix+st_global("PUTEXCEL_SHEET_NAME")
    if(st_local("resetsession")=="" & asarray_contains(mdt_history,mdt_key)) mdt_styles=asarray(mdt_history,mdt_key)
    else mdt_styles=asarray_create("real",2)
    mdt_touched=asarray_create("real",2)
}
string rowvector mdt_default()
{
    return(("Calibri","11","","","","","","","General","","","",""))
}
real rowvector mdt_coord(string scalar cell)
{
    real scalar i,col
    col=0
    for(i=1;i<=strlen(cell);i++) {
        if (substr(cell,i,1)>="0" & substr(cell,i,1)<="9") break
        col=26*col+ascii(substr(cell,i,1))-64
    }
    return((strtoreal(substr(cell,i,.)),col))
}
string scalar mdt_cell(real scalar r,real scalar c)
{
    string scalar s
    real scalar n
    s=""
    while(c>0) {
        n=mod(c-1,26)
        s=char(n+65)+s
        c=floor((c-1)/26)
    }
    return(s+strofreal(r,"%12.0f"))
}
string rowvector mdt_parts(string scalar text)
{
    string rowvector p
    real scalar i
    p=tokens(text,",")
    p=select(p,p:!=",")
    for(i=1;i<=cols(p);i++) p[i]=subinstr(strtrim(p[i]),char(34),"")
    return(p)
}
// Compose the original ordered formatting operations without editing Excel.
void mdt_fmt_add()
{
    external transmorphic scalar mdt_styles,mdt_touched
    string scalar target,x
    string rowvector limits,s,anchor,p
    real rowvector a,b
    real scalar r,c,i
    target=subinstr(subinstr(st_local("target"),"(",""),")","")
    limits=tokens(target,":")
    a=mdt_coord(limits[1]);b=mdt_coord(limits[cols(limits)])
    anchor=mdt_default()
    if(asarray_contains(mdt_styles,a)) anchor=asarray(mdt_styles,a)
    for(r=a[1];r<=b[1];r++) for(c=a[2];c<=b[2];c++) {
        s=mdt_default()
        if(asarray_contains(mdt_styles,(r,c))) s=asarray(mdt_styles,(r,c))
        if(st_local("merge")!="") s=anchor
        if(st_local("reset")!="") s=mdt_default()
        x=st_local("font")
        if(x!="") {
            p=mdt_parts(x)
            for(i=1;i<=cols(p);i++) if(p[i]!="") s[i]=p[i]
        }
        if(st_local("bold")!="") s[4]="bold"
        if(st_local("italic")!="") s[5]="italic"
        if(st_local("left")!="") s[6]="left"
        if(st_local("right")!="") s[6]="right"
        if(st_local("hcenter")!="") s[6]="hcenter"
        if(st_local("vcenter")!="") s[7]="vcenter"
        if(st_local("txtwrap")!="") s[8]="txtwrap"
        if(st_local("nformat")!="") s[9]=subinstr(st_local("nformat"),char(34),"")
        x=st_local("border")
        if(x!="") {
            p=mdt_parts(x)
            x=p[2]
            if(cols(p)>2) x=x+","+char(34)+p[3]+char(34)
            if(p[1]=="all") for(i=10;i<=13;i++) s[i]=x
            if(p[1]=="left") s[10]=x
            if(p[1]=="right") s[11]=x
            if(p[1]=="top") s[12]=x
            if(p[1]=="bottom") s[13]=x
        }
        asarray(mdt_styles,(r,c),s)
        asarray(mdt_touched,(r,c),1)
    }
}
// Assign all four borders to one format ID; putexcel accepts only one border().
real scalar mdt_makefmt(pointer(class xl scalar) scalar x, string rowvector s)
{
    real scalar id,font,i
    string rowvector p
    id=x->add_fmtid()
    font=x->add_fontid()
    if(s[3]=="") x->fontid_set_font(font,s[1],strtoreal(s[2]))
    else x->fontid_set_font(font,s[1],strtoreal(s[2]),s[3])
    if(s[4]!="") x->fontid_set_font_bold(font,"on")
    if(s[5]!="") x->fontid_set_font_italic(font,"on")
    x->fmtid_set_fontid(id,font)
    if(s[6]!="") x->fmtid_set_horizontal_align(id,s[6]=="hcenter" ? "center" : s[6])
    if(s[7]!="") x->fmtid_set_vertical_align(id,"center")
    if(s[8]!="") x->fmtid_set_text_wrap(id,"on")
    x->fmtid_set_number_format(id,s[9])
    for(i=10;i<=13;i++) if(s[i]!="") {
        p=mdt_parts(s[i])
        if(cols(p)==1) {
            if(i==10) x->fmtid_set_left_border(id,p[1])
            if(i==11) x->fmtid_set_right_border(id,p[1])
            if(i==12) x->fmtid_set_top_border(id,p[1])
            if(i==13) x->fmtid_set_bottom_border(id,p[1])
        }
        else {
            if(i==10) x->fmtid_set_left_border(id,p[1],p[2])
            if(i==11) x->fmtid_set_right_border(id,p[1],p[2])
            if(i==12) x->fmtid_set_top_border(id,p[1],p[2])
            if(i==13) x->fmtid_set_bottom_border(id,p[1],p[2])
        }
    }
    return(id)
}
// Touch only recorded cells; group consecutive rows and reuse identical styles.
void mdt_fmt_flush()
{
    external transmorphic scalar mdt_styles,mdt_history,mdt_touched
    external string scalar mdt_key
    transmorphic scalar cache
    pointer(class xl scalar) scalar x
    real matrix keys
    real scalar i,j,r,c,last,id
    string rowvector s,next
    string scalar signature
    x=findexternal("__putexcel_open_fhandle")
    if(x==NULL) _error(498,"No open putexcel workbook for complete-style application")
    cache=asarray_create("string",1)
    keys=asarray_keys(mdt_touched)
    if(rows(keys)==0) return
    keys=sort(keys,(2,1))
    i=1
    while(i<=rows(keys)) {
        r=keys[i,1];c=keys[i,2];last=r
        s=asarray(mdt_styles,(r,c));j=i+1
        while(j<=rows(keys)) {
            if(keys[j,2]!=c | keys[j,1]!=last+1) break
            next=asarray(mdt_styles,keys[j,])
            if(any(next:!=s)) break
            last=keys[j,1];j++
        }
        signature=invtokens(s,char(9))
        if(asarray_contains(cache,signature)) id=asarray(cache,signature)
        else {
            id=mdt_makefmt(x,s)
            asarray(cache,signature,id)
        }
        x->set_fmtid((r,last),c,id)
        if(x->get_last_error()) _error(691,"Complete Excel style could not be applied")
        i=j
    }
    asarray(mdt_history,mdt_key,mdt_styles)
}
end
