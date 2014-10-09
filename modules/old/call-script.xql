xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $options :=
   <options>
       <workingDir>/Users/joern/dev/eXist-ca/ca-scripts</workingDir>    
       <param>fsjdflkj</param>
       <param2>2222222</param2>
   </options>
return
(:
    evarything after the first 2 arguments is a sequence that will be the concatenated output for the commendline
:)
  process:execute(("sh", "create-ca.sh", "-param", $options//param, "-param2", $options//param2), $options)
