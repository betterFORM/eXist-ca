xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";


let $ca-home := $existca:ca-home
let $pki-home := $ca-home || '/pki'

(:let $data := request:get-data():)

let $data := 
    <CA name="exist-db.org" nicename="">
        <keysize>2048</keysize>
        <expire>1825</expire>
        <capass>a</capass>
        <expiry-date>2019-12-22</expiry-date>
        <dnsname>x</dnsname>
        <country/>
        <province/>
        <city/>
        <org/>
        <org-unit/>
        <email/>
        <cacert/>
        <cakey/>
        <pending-requests>
            <req name="" type=""/>
        </pending-requests>
        <rejected-requests>
            <req name="" rej-reason="" type=""/>
        </rejected-requests>
    </CA>
 
(: 
 : prepare options for calling external ca-scripts/create-casrvcert.sh via shell
 :)
 
let $casrvcert-tmp := $pki-home || '/' || util:uuid() || '.xml'

let $create-cert-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="EXISTCA_CAPASS" value="{$data//capass}"/>
           <env name="EXISTCA_CANAME" value="{$data//@name}"/>
           <env name="EXISTCA_CERTNAME" value="{$data//dnsname}"/>
           <env name="EXISTCA_CERTPASS" value="{$data//capass}"/>
           <env name="EXISTCA_CERTTYPE" value="server"/>
           <env name="EXISTCA_CERTKEYSIZE" value="{$data//keysize}"/>
           <env name="EXISTCA_CERTEXPIRE" value="{$data//expire}"/>
           <env name="EXISTCA_CERTCOUNTRY" value="{$data//country}"/>
           <env name="EXISTCA_CERTPROVINCE" value="{$data//province}"/>
           <env name="EXISTCA_CERTCITY" value="{$data//city}"/>
           <env name="EXISTCA_CERTORG" value="{$data//org}"/>
           <env name="EXISTCA_CERTOU" value="{$data//org-unit}"/>
           <env name="EXISTCA_CERTEMAIL" value="{$data//email}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="EXISTCA_XMLOUT" value="{$casrvcert-tmp}"/>
           <env name="PKI_BASE" value="{$pki-home}"/>
       </environment>
   </options>

let $result := (process:execute(("sh", "create-cert.sh"), $create-cert-options))

let $generated-cert-file:=util:parse(file:read($casrvcert-tmp))

let $foo := if($result/@exitCode=0) then
        let $cert-data-collection := $existca:cert-data-collection || $data//@name
        let $resourceName := util:uuid() || ".xml"
        return xmldb:store($cert-data-collection, $resourceName, $generated-cert-file)
else ()

return $result
