xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

let $log := util:log("INFO", $exist:path || " : " || $exist:resource || " : " || $exist:controller || " : " || $exist:prefix || " : " || $exist:root)
return 
if($exist:path eq "") then
    (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/exist/apps/eXistCA/index.xhtml"/>
    </dispatch>        
    )
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.xhtml"/>
    </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
