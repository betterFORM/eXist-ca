xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";
(:
import module namespace system="http://exist-db.org/xquery/system"
let $home := system:get-exist-home()
:)

let $ca-home := $existca:ca-home
let $cert-data-collection := $existca:cert-data-collection

(:let $data := request:get-data():)
let $data := <CA name="myname" nicename="" servername="example.org">
            <keysize>4096</keysize>
            <expire>1825</expire>
            <capass>aaa</capass>
            <expiry-date/>
            <country/>
            <province/>
            <city/>
            <org/>
            <org-unit/>
            <email/>
            <cacert/>
            <cakey/>
            <certs>
                <cert name="" nicename="">
                    <certtype/>
                    <status/>
                    <expire-timestamp/>
                    <serial/>
                    <certpass/>
                    <country/>
                    <province/>
                    <city/>
                    <org/>
                    <org-unit/>
                    <email/>
                    <cert/>
                    <key/>
                    <pkcs12/>
                    <req/>
                </cert>
            </certs>
            <pending-requests>
                <req name="" type=""/>
            </pending-requests>
            <rejected-requests>
                <req name="" type="" rej-reason=""/>
            </rejected-requests>
        </CA>

let $cert-tmp := $existca:ca-home || '/pki/' || $data/@name || '.xml'
(: 
 : prepare options for calling external ca-scripts via shell
 :)
let $create-ca-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$data/@name}"/>
           <env name="EXISTCA_CAKEYSIZE" value="{$data/keysize}"/>
           <env name="EXISTCA_CAEXPIRE" value="{$data/expire}"/>
           <env name="EXISTCA_CAPASS" value="{$data/capass}"/>
           <env name="EXISTCA_CACOUNTRY" value="{$data/country}"/>
           <env name="EXISTCA_CAPROVINCE" value="{$data/province}"/>
           <env name="EXISTCA_CACITY" value="{$data/city}"/>
           <env name="EXISTCA_CAORG" value="{$data/org}"/>
           <env name="EXISTCA_CAOU" value="{$data/org-unit}"/>
           <env name="EXISTCA_CAEMAIL" value="{$data/email}"/>

           <env name="EXISTCA_SRVNAME" value="{$data/@servername}"/>
           <env name="EXISTCA_SRVPASS" value="{$data/capass}"/>
           <env name="EXISTCA_SRVKEYSIZE" value="{$data/keysize}"/>
           <env name="EXISTCA_SRVEXPIRE" value="{$data/expire}"/>
           <env name="EXISTCA_SRVCOUNTRY" value="{$data/country}"/>
           <env name="EXISTCA_SRVPROVINCE" value="{$data/province}"/>
           <env name="EXISTCA_SRVCITY" value="{$data/city}"/>
           <env name="EXISTCA_SRVORG" value="{$data/org}"/>
           <env name="EXISTCA_SRVOU" value="{$data/org-unit}"/>
           <env name="EXISTCA_SRVEMAIL" value="{$data/email}"/>

           <env name="EXISTCA_XMLOUT" value="{$cert-tmp}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="PKI_BASE" value="{$ca-home || '/pki'}"/>

	   <!-- next two only for reconfig-jetty, will go away here -->
           <env name="JETTY_HOME" value="{$existca:jetty-home}"/>
           <env name="JAVA_HOME" value="{environment-variable("JAVA_HOME")}"/>
           
       </environment>
   </options>
 
let $result := (process:execute(("sh", "create-ca.sh"), $create-ca-options))

let $generated-cert-file:=file:read($cert-tmp)

let $foo := if($result/@exitCode=0) then
        let $uuid := util:uuid()
        let $resourceName := $data/@name || ".xml"
        return xmldb:store($cert-data-collection, $resourceName, $generated-cert-file)
else ()
     

return $result
(:return $generated-cert-file:)

(:let $uuid := util:uuid() :)

(: this part does not work for some reason :)
(:let $new-data := update value $data/CA/@id with string($uuid):)

(:
let $resourceName := data($uuid) || ".xml"
let $stored :=  xmldb:store($cert-data-collection, $resourceName, $data)
return $data

:)

(: EXPERIMENTAL: factor out reconfig-hetty.sh from create-ca.sh :)

(: 
 : prepare options for calling external ca-scripts/reconfig-jetty.sh via shell
 :)
(: NOTE "???" below
let $reonf-jetty-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
	   <!-- SERVER_P12=${PKI_BASE}/${THIS_CA}/private/${THIS_SRV}.p12 -->
           <env name="SERVER_P12" value="???"/>
           <env name="JAVA_HOME" value="{environment-variable("JAVA_HOME")}"/>
           <env name="JETTY_HOME" value="{$existca:jetty-home}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="EXISTCA_SRVPASS" value="{$data/capass}"/>
       </environment>
   </options>
 
let $result := (process:execute(("sh", "reconfig-jetty.sh"), $reonf-jetty-options))

:)
