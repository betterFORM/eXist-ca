xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $options :=
    <options>
        <stdin>
            <line>Hello world!</line>
            <line>Are you ready?</line>
        </stdin>
    </options>
return
    process:execute("cat", $options)
