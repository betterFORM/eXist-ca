xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $options :=
   <options><workingDir>/Users/wolf</workingDir></options>
return
   process:execute(("ls", "-l"), $options)