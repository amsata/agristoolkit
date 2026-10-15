program define _tab_from_mdt_outfile, rclass
    version 14.1
    syntax, SPEC(string asis)
    mata: mdt_outfile_parse()
    if `"`parse_error'"'!="" {

        di as error `"Invalid outfile(): `parse_error'"'
        di as error `"Expected: outfile("file.xlsx", "sheet", row, column)"'
        exit 198
    
}
    return local normalized `"`normalized'"'
    return local path `"`parsed_path'"'
    return local sheet `"`parsed_sheet'"'
    return scalar row = `parsed_row'
    return local column "`parsed_col'"
end
mata:
void mdt_outfile_parse()
{

    string scalar text,part,ch,err,path,sheet,col,norm
    string rowvector parts
    real scalar i,quoted,n,row,colnum
    text=strtrim(st_local("spec"))
    if(substr(text,1,2)==char(96)+char(34) & substr(text,strlen(text)-1,2)==char(34)+char(39)) text=substr(text,3,strlen(text)-4)
    part="";parts=J(1,0,"");quoted=0;err=""
    for(i=1;i<=strlen(text);i++) {

        ch=substr(text,i,1)
        if(ch==char(34)) quoted=!quoted
        if(ch=="," & !quoted) {
parts=(parts,strtrim(part));part=""
}
        else part=part+ch
    
}
    parts=(parts,strtrim(part));n=cols(parts)
    if(quoted) err="unmatched quotation mark"
    if(n>4) err="at most four comma-separated arguments are allowed"
    for(i=1;i<=n;i++) {

        part=parts[i]
        if(strlen(part)>=2 & substr(part,1,1)==char(34) & substr(part,strlen(part),1)==char(34)) part=substr(part,2,strlen(part)-2)
        parts[i]=strtrim(part)
        if(parts[i]=="" & err=="") err="argument "+strofreal(i)+" is empty; omit trailing arguments entirely or supply an explicit value"
        if(strpos(parts[i],char(34)) & err=="") err="quotation marks must surround an entire argument"
    
}
    if(err!="") {
st_local("parse_error",err);return
}
    path=parts[1];sheet="TABLES";row=1;col="A"
    if(n>=2) sheet=parts[2]
    if(n>=3) {

        row=strtoreal(parts[3])
        if(missing(row) | row<1 | row>1048576 | row!=floor(row)) {

            st_local("parse_error","argument 3 must be a row integer from 1 to 1048576; received "+parts[3]+". Did you omit the sheet name?");return
        
}
    
}
    if(n>=4) col=strupper(parts[4])
    colnum=0
    for(i=1;i<=strlen(col);i++) {

        ch=substr(col,i,1)
        if(ch<"A" | ch>"Z") {
colnum=16385;break
}
        colnum=26*colnum+ascii(ch)-64
        if(colnum>16384) break
    
}
    if(colnum<1 | colnum>16384) {
st_local("parse_error","argument 4 must be Excel column letters A through XFD; received "+col);return
}
    norm=char(34)+path+char(34)+", "+char(34)+sheet+char(34)+", "+strtrim(strofreal(row,"%12.0f"))+", "+col
    if(n==1 & path=="no") norm="no"
    st_local("parsed_path",path);st_local("parsed_sheet",sheet);st_local("parsed_row",strtrim(strofreal(row,"%12.0f")));st_local("parsed_col",col);st_local("normalized",norm)

}
end



