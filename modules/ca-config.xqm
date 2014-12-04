xquery version "3.0";

module namespace existca="http://exist-db.org/apps/existCA";

(: ### the root directory for all CA-related scripts ### :)
declare variable $existca:ca-home := system:get-exist-home() || "/ca-scripts";