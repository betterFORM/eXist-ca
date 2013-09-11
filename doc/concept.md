Grundannahme: Wir brauchen keine komplette CA mit allen denkbaren Optionen,
sondern nur eine CA, die folgenden Anforderungen erfuellt:

- soll zusammen mit eXist/betterform als VM Image oder Hardware Appliance
  ausgeliefert werden, also nicht "general purpose", sondern nur CA fuer
  diese eine eXist Instanz
- soll verschluesselte Verbindungen zwischen Browser und eXistDB/betterform
  Instanz ermoeglichen (HTTPS), ohne laestige Browser-Warnungen
- soll fuer Kunden einfach und kostenguenstig sein, daher Self-Signed CA
  statt kostenpflichtiger und z.T. recht umstaendlicher Verfahren beim Kauf
  von offiziellen Certs
- soll einfaches Deployment ermoeglichen, d.h. das CA Cert steht unter
  einem definierten URL als klickbarer Link zur Verfuegung.  Dabei wird
  des CA Cert mit einem bestimmten MIME Type ausgeliefert, der moderne
  Browser veranlasst, einen Dialog zum Import eines CA Certs zu oeffnen

Wenn das CA Cert, auf das sich der eXist/betterform Web-Server beruft, im
Client Browser importiert ist, reicht das, um HTTPS verschluesselte Client-
Verbindungen ohne stoerende Browser-Warnungen zu ermoeglichen.  Das ist der
einfache Fall A: verschluesselt, aber anonym und ohne weitere
Authentifizierung.

Fall B waere verschluesselt und authentifiziert.  In dem Fall muss die CA
explizit Client-Certs ausstellen und gelegentlich auch revoken.  Ein neues
Client-Cert steht im gleich Anschluss an die Erzeugung als klickbarer Link
mit dem richtigen MIME Type zur Verfuegung.  Client-Certs erfordern die
Eingabe eines persoenlichen Passworts.  Verbindungen zum Server werden nur
akzeptiert wenn

- das bei der SSL-Verschluesselung praesentierte Client-Cert von der lokalen
  CA ausgestellt und nicht widerrufen ist (vgl. Tokens zu Parkhaeusern,
  wer eins hat darf rein, egal wer er ist).  Das waere Fall B1, geschlossene
  Benutzergruppe ohne weitere Identitaetspruefung.

- oder alternativ: wenn das bei der SSL-Verschluesselung praesentierte
  Client-Cert von der lokalen CA ausgestellt und nicht widerrufen ist,
  *und* zu einem erlaubten User gehoert.  Fall B2, nur autorisierte Personen.


Ich weiss, dass eXist einen integrierten Webserver hat, und vielleicht auch
einen SSL-faehigen (?).  Aber entscheidend fuer Fall 2 ist, dass die SSL
Implementierung Eures Web-Servers tatsaechlich Cert Validierung implementiert,
manche sparen sich den Aufwand (zu Recht).  Falls dies bei Euch der Fall ist,
muesste man eine Proxy-Instanz vorschalten die dies erledigt (zB Apache oder
nginx), waere vermutlich einfacher, als das selbst zu implementieren.


UI Konzept (Fall A)
-------------------

Es muss eine CA erzeugt werden, diese CA muss ein Server-Cert fuer die
lokale eXist/betterform Instanz erzeugen, das wars.  Passt auf eine Seite.

page "start"
............

wenn noch keine CA Daten oder eXist Server-Cert Daten vorliegen
==> springe zu page "setup"

else display CA and Server Cert Info (Organization, Validity ...), readonly
and  display URL for CA Cert download
and  display "Renew Certs" button  (==> onclick: page "renewsyscerts")

page "setup"
............

Kundendaten:
textfield, required:	Organization ("Example Ltd")
textfield, recommended:	OrganizationalUnit ("Foo Project")
textfield, optional:	Bundesland ("Berlin")
textfield, required:	City ("Berlin")
select, required:	Country ("DE")

CA Details:
numeric textfield, req	Cert Gueltigkeit in Tagen ("3650")
password textfield, req	Set CA Passwort
password textfield, req	Set CA Passwort (confirm)

eXist/betterform Server Details:
textfield, required:	eXist Server DNS Name ("foosrv.example.org")

button: Abschicken

Man haette fuer das Server-Cert ne andere Gueltigkeit als fuer das CA Cert
erlauben koennen, aber warum?  Darueber sollte der Anwender nicht nachdenken
muessen, beide Certs laufen gleich lang, und beide werden bei "Renew"
erneuert.

Bei "Abschicken" passiert folgendes:
- die Daten werden in einen XML config Node geschrieben (XForms)
- mit XSL wird eine einzige Config Datei dynamisch erzeugt
- externer Aufruf von zwei Scripts, die mit diesen Daten CA Cert und
  Server-Cert erstellen
- externer Aufruf von Script, das das neue Server-Cert in eXist Webserver
  Config oder Proxy Config installiert und diese neu startet

Anschliessend springe zu page "start"

page "renewsyscerts"
....................

numeric textfield, req	neue Cert Gueltigkeit in Tagen ("3650")

password textfield, req	Enter CA Passwort
button: Abschicken

Bei "Abschicken" passiert folgendes:
- externer Aufruf von zwei Scripts, die die CA und Server Certs verlaengern
- externer Aufruf von Script, das das neue Server-Cert in eXist Webserver
  Config oder Proxy Config installiert und diese neu startet

Anschliessend springe zu page "start"


UI Konzept (Fall B)
-------------------

Wie in Fall A muss eine CA erzeugt werden, diese CA muss ein Server-Cert fuer
die lokale eXist/betterform Instanz erzeugen.  Zusaetzlich wird ein
Listen-Element benoetigt, das alle ausgestellten Client-Certs anzeigt, sowie
eine Seite, die ein Client-Cert (readonly) anzeigt und die Buttons
"Renew Cert" und "Revoke Cert" anbietet.

page "start"
............

wie in Fall A: wenn noch keine CA Daten oder eXist Server-Cert Daten vorliegen
==> springe zu page "setup"

else display CA and Server Cert Info (Organization, Validity ...), readonly
and  display URL for CA Cert download
and  display "Renew Certs" button  (==> onclick: page "renewcerts")

zusaetzlich in Fall B: zeige Listen-Element aller ausgestellten Client-Certs.
Die einzelnen Listen-Elemente sollten klickbar sein, und fuehren dann zu
page "displayclientcert".

und ein Button "New Client Cert"  (==> onclick: page "newclientcert")

page "newclientcert"
....................

textfield, required:	User Name ("John Doe")
textfield, required:	User Email ("jdoe@example.org")
password textfield, req	Set User Passwort
password textfield, req	Set User Passwort (confirm)
numeric textfield, req	Gueltigkeit in Tagen ("365")

password textfield, req	Enter CA Passwort
button: Abschicken

Bei "Abschicken" passiert folgendes:
- die Daten werden in einen XML config Node geschrieben (XForms)
- externer Aufruf von einem Script, die mit diesen Daten Client Cert erstellt

Anschliessend springe zu page "displayclientcert"

page "displayclientcert"
........................

display User Cert Info (User Name, Email, Organization, Validity ...), readonly
display URL for User Cert download

Button: "Renew Cert"  (==> onclick: page "renewclientcert")
Button: "Revoke Cert" (==> onclick: page "revokeclientcert")
Button: "Certs Overview" (==> onclick: page "start")

page "renewclientcert"
......................

numeric textfield, req	neue Cert Gueltigkeit in Tagen ("365")

password textfield, req	Enter CA Passwort
button: Abschicken

Bei "Abschicken" passiert folgendes:
- externer Aufruf von einem Script, die mit diesen Daten Client Cert erneuert

Anschliessend springe zu page "displayclientcert"

page "revokeclientcert"
.......................

display "Really revoke this client cert?"

password textfield, req	Enter CA Passwort
button: Abschicken

Bei "Abschicken" passiert folgendes:
- externer Aufruf von einem Script, die das Cert revoked, eine aktuelle CRL
  (Certificate Revocation List) erstellt, und die neue CRL im eXist Webserver
  oder Proxy installiert

Anschliessend springe zu page "start"
