xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

(: to make sure we have a writeable directory use java.io.tmpdir which is always available and writeable :)
let $tmpDir := util:system-property("java.io.tmpdir")

(: serialize cert generation skript as binary :)
let $script := util:binary-doc("/db/apps/eXistCA/ca-scripts/create-ca.sh")

(:
    serialize binary doc to disk (java.io.tmpdir)
:)
let $tmp := file:serialize-binary($script, $tmpDir || "/create-ca.sh")
return 
    process:execute(("sh", $tmpDir || "/create-ca.sh"), ()) 
    

