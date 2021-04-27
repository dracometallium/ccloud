#!/usr/bin/awk -f

# Transforma una lista separada por TABs de [nombre_loc, nombre_prov] a una
# lista de tuplas ('ar', id_prov, nombre_prov) y ('ar', id_prov, id_loc,
# nombre_loc), con el fin de que puedan ser facilmente insertadas en una DB.

BEGIN{
    FS="\t"
    OFS=FS
    max=0
    print "----Localidades"
}

{
    gsub(/'/,"\\'")
    if(!($2 in cprovs)){
        max++
        provs[max]=$2
        cprovs[$2]=max;
    }
    clocs[$2]=clocs[$2]+1
    printf("('ar',%d,%d,'%s')\n",cprovs[$2],clocs[$2],$1)
}

END{
    print "----Provincias"
    for(i in provs){
        printf("('ar',%d,'%s')\n",i,provs[i])
    }
}
