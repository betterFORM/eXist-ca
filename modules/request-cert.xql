xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $ca-scripts := "/usr/local/eXistCA"

let $config := 
    <CA name="Example CA">
	<new-req name="www.example.org" type="server" keysize="2048" 
		 certpass=""/>
    </CA>

let $options :=
   <options>
       <workingDir>$ca-scripts</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$config/@name}"/>
           <env name="EXISTCA_CERTNAME" value="{$config/new-req/@name}"/>
           <env name="EXISTCA_CERTPASS" value="{$config/new-req/@certpass}"/>
           <env name="EXISTCA_CERTTYPE" value="{$config/new-req/@type}"/>
           <env name="EXISTCA_CERTKEYSIZE" value="{$config/new-req/@keysize}"/>
       </environment>
       <!-- myopt>myopt</myopt -->
   </options>

return
(process:execute(("sh", $ca-scripts || "/request-cert.sh"), $options))

