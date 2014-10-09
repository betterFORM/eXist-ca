xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

(: serialize cert generation skript as binary :)
let $script := util:binary-doc("/db/apps/eXistCA/ca-scripts/create-ca.sh")

return
    process:execute(("sh", "-c", util:binary-to-string($script)), ())


