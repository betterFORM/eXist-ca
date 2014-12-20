xquery version "3.0";

declare namespace file="http://exist-db.org/xquery/file";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace existca="http://exist-db.org/apps/existCA" at "modules/ca-config.xqm";

(: creates root directory for ca-scripts and easyRSA scripts and
 : syncs all files from collection ca-scripts and resources/easyrsa3
 : to that location
 :)
declare function local:init() {
    let $ca-scripts := $existca:ca-home
    
    let $createDir := if( not(file:exists($ca-scripts)) ) then
        file:mkdir($ca-scripts)
    else (
        util:log("info","CA home dir already existed")
        )
    (:
    sync easyrsa3 collection to BASEDIR
    :)
    let $sync := file:sync("/db/apps/eXistCA/ca-scripts",$ca-scripts,())
    let $easyrsa := file:sync("/db/apps/eXistCA/resources/easyrsa3",$ca-scripts || "/easyrsa",())
    (:
    also sync sys-scripts to BASEDIR
    :)
    let $sys := file:sync("/db/apps/eXistCA/sys-scripts",$ca-scripts || "/sys-scripts",())
    
    let $fake := xmldb:create-collection("/db/apps/eXistCA/data","ca")
    return ()
};

local:init()
