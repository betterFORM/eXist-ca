xquery version "3.0";

module namespace existca="http://exist-db.org/apps/existCA";

(: ### the root directory for all CA-related scripts ### :)
declare variable $existca:ca-home := system:get-exist-home() || "/ca-scripts";
declare variable $existca:jetty-home := system:get-exist-home() || "/tools/jetty";
declare variable $existca:cert-data-collection := "/db/apps/eXistCA/data/ca";
