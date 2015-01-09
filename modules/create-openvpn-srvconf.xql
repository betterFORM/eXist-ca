xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
(: import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm"; :)
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";


let $ca-home := $existca:ca-home
let $pki-home := $ca-home || '/pki'

let $data := request:get-data()
 
(:let $data := :)
(:    <openvpn num="1" name="" nicename="Example VPN">:)
(:        <srvaddr>192.168.45.125</srvaddr>:)
(:        <srvport>1194</srvport>:)
(:        <srvproto>udp</srvproto>:)
(:        <network>10.9.0.0</network>:)
(:        <netmask>255.255.255.0</netmask>:)
(:        <dnsname>vpn.example.org</dnsname>:)
(:        <caname>Example CA</caname>:)
(:        <cipher>AES-256-CBC</cipher>:)
(:    </openvpn>:)

(: 
 : prepare options for calling external ca-scripts/sys-scripts/create-openvpn-srvconf.sh via shell
 :)
 
let $ovpnsrv-tmp := $pki-home || '/' || util:uuid() || '.xml'

let $create-openvpn-srvconf-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="OPENVPN_VPNNAME" value="{$data//@nicename}"/>
           <env name="OPENVPN_VPNNUM" value="{$data//@num}"/>
           <env name="OPENVPN_SRVADDR" value="{$data//srvaddr}"/>
           <env name="OPENVPN_SRVPORT" value="{$data//srvport}"/>
           <env name="OPENVPN_SRVPROTO" value="{$data//srvproto}"/>
           <env name="OPENVPN_NETWORK" value="{$data//network}"/>
           <env name="OPENVPN_NETMASK" value="{$data//netmask}"/>
           <env name="OPENVPN_CANAME" value="{$data//caname}"/>
           <env name="OPENVPN_DNSNAME" value="{$data//dnsname}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="EXISTCA_XMLOUT" value="{$casrvcert-tmp}"/>
           <env name="PKI_BASE" value="{$pki-home}"/>
	   <env name="DEBUG" value="1"/>
       </environment>
   </options>

let $result := (process:execute(("sh", "sys-scripts/create-openvpn-srvconf.sh"), $create-openvpn-srvconf-options))

let $generated-vpn-file:=util:parse(file:read($ovpnsrv-tmp))

let $foo := if($result/@exitCode=0) then ()
else ()

return $result
