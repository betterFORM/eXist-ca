xquery version "3.0";

declare namespace util="http://exist-db.org/xquery/file";

declare function local:init() {
    let $ca-scripts := "/usr/local/eXistCA"

    (:
    sync easyrsa3 collection to BASEDIR
    :)
    let $sync := file:sync("ca-scripts",$ca-scripts,())
    let $easyrsa := file:sync("resources/easyrsa3",$ca-scripts || "/easyrsa")
};

local:init()