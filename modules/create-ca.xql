xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";
(:
import module namespace system="http://exist-db.org/xquery/system"
let $home := system:get-exist-home()
:)

let $ca-home := $existca:ca-home
let $pki-home := $ca-home || '/pki'

(:let $data := request:get-data():)
let $data := <CA name="" nicename="my name">
            <keysize>4096</keysize>
            <expire>1825</expire>
            <capass>aaa</capass>
            <expiry-date/>
	    <dnsname>ca.example.org</dnsname>
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

(: 
 : prepare options for calling external ca-scripts via shell
 :)
let $cert-tmp := $pki-home || '/' || util:uuid() || '.xml'

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
           <env name="EXISTCA_XMLOUT" value="{$cert-tmp}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="PKI_BASE" value="{$pki-home'}"/>
       </environment>
   </options>
 
let $result := (process:execute(("sh", "create-ca.sh"), $create-ca-options))

let $generated-cert-file:=file:read($cert-tmp)
let $cert-data-collection := xmldb:create-collection($existca:cert-data-collection, data($generated-cert-file//CA/@name))

let $foo := if($result/@exitCode=0) then
        let $resourceName := "ca.xml"
        return xmldb:store($cert-data-collection, $resourceName, $generated-cert-file)
else ()
     

(: 
 : prepare options for calling external ca-scripts/create-casrvcert.sh via shell
 :)

let $casrvcert-tmp := $pki-home || '/' || util:uuid() || '.xml'

let $create-cert-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="EXISTCA_CAPASS" value="{$data/capass}"/>
           <env name="EXISTCA_CANAME" value="{$data/@name}"/>
           <env name="EXISTCA_CERTNAME" value="{$data/dnsname}"/>
           <env name="EXISTCA_CERTPASS" value="{$data/capass}"/>
           <env name="EXISTCA_CERTTYPE" value="server"/>
           <env name="EXISTCA_CERTKEYSIZE" value="{$data/keysize}"/>
           <env name="EXISTCA_CERTEXPIRE" value="{$data/expire}"/>
           <env name="EXISTCA_CERTCOUNTRY" value="{$data/country}"/>
           <env name="EXISTCA_CERTPROVINCE" value="{$data/province}"/>
           <env name="EXISTCA_CERTCITY" value="{$data/city}"/>
           <env name="EXISTCA_CERTORG" value="{$data/org}"/>
           <env name="EXISTCA_CERTOU" value="{$data/org-unit}"/>
           <env name="EXISTCA_CERTEMAIL" value="{$data/email}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="EXISTCA_XMLOUT" value="{$cert-tmp}"/>
           <env name="PKI_BASE" value="{$pki-home}"/>
       </environment>
   </options>

let $result := (process:execute(("sh", "create-cert.sh"), $create-cert-options))

let $generated-cert-file:=file:read($casrvcert-tmp)

let $foo := if($result/@exitCode=0) then
        let $resourceName := util:uuid() || ".xml"
        return xmldb:store($cert-data-collection, $resourceName, $generated-cert-file)
else ()
     

(: 
 : prepare options for calling external ca-scripts/reconfig-jetty.sh via shell
 :)

let $srv-p12-file := $pki-home || '/' || $data/@name || 'private' || $data/dnsname || '.p12'
let $reconf-jetty-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="SERVER_P12" value="{$srv-p12-file}"/>
           <env name="JAVA_HOME" value="{environment-variable("JAVA_HOME")}"/>
           <env name="JETTY_HOME" value="{$existca:jetty-home}"/>
           <env name="JETTY_PORT" value="{environment-variable("JETTY_PORT")}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="EXISTCA_CERTPASS" value="{$data/capass}"/>
       </environment>
   </options>
 
let $result := (process:execute(("sh", "reconfig-jetty.sh"), $reconf-jetty-options))

(: check exit code 
return
	<foobar/>
:)


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

