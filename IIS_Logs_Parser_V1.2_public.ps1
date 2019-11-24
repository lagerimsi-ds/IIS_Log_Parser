##################################################################################################################################
# IIS-Log-Parser V1.2
#
# Dieses Script durchforstet das neueste IIS-Log nach den in $errorcodes festgelegten Statuscodes, und sendet sie per mail an die 
# eingestellten Empfänger.
# 
#
# Erstellt ursprünglichfür das IT-DLZ Bayern am 2016-05-24.
# 
# Um unnütze Kommentare erleichtert und der Öffentlichkeit zur Verfügung gestellt am 24.11.2019.
# published 24.11.2019
#
# ---> if needed please adjust the explanation of the errorcodes in the mailbody and comments to your language.
#
# 
# As I am still owner of this work made at the IT-DLZ Bayern as a worker for a governmental institution
# I make this script public under the following conditions:
#
# 
#    Copyright (C) 2019  Dominik Steinberger
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#
#
##################################################################################################################################

# hier die gewünschte Range an Errorcodes einstellen
$errorcodes = 500 .. 511

# IIS-Log-Pfade und temporäres Verzeichnis für das Script
$Path = "C:\IIS-LOG-Directory"
$OutPath="C:\IIS-LOG-Directory\Logfile_Temp"


#"von", "an, "server" und "body" der Mail

$mailfrom = 'iis-user@anywhere.moon' # Absender der Notification-Mail 
$mailto = 'anyone@anywhere.moon', "anytwo@anywhere.moon"   # Empfänger der Notification-Mail 
$smtpserver = 'relay.anywhere.moon'   # SMTP-Server 
$betreff = 'Moon -- IIS-Log' 
$body = '5xx – Server-Fehler

Code 	Nachricht 	Bedeutung
500 	Internal Server Error 	Dies ist ein Sammel-Statuscode für unerwartete Serverfehler.
501 	Not Implemented 	Die Funktionalität, um die Anfrage zu bearbeiten, wird von diesem Server nicht bereitgestellt. Ursache ist zum Beispiel eine unbekannte oder nicht unterstützte HTTP-Methode.
502 	Bad Gateway 	Der Server konnte seine Funktion als Gateway oder Proxy nicht erfüllen, weil er seinerseits eine ungültige Antwort erhalten hat.
503 	Service Unavailable 	Der Server steht temporär nicht zur Verfügung, zum Beispiel wegen Überlastung oder Wartungsarbeiten. Ein „Retry-After“-Header-Feld in der Antwort kann den Client auf einen Zeitpunkt hinweisen, zu dem die Anfrage eventuell bearbeitet werden könnte.
504 	Gateway Time-out 	Der Server konnte seine Funktion als Gateway oder Proxy nicht erfüllen, weil er innerhalb einer festgelegten Zeitspanne keine Antwort von seinerseits benutzten Servern oder Diensten erhalten hat.
505 	HTTP Version not supported 	Die benutzte HTTP-Version (gemeint ist die Zahl vor dem Punkt) wird vom Server nicht unterstützt oder abgelehnt.
506 	Variant Also Negotiates 	Die Inhaltsvereinbarung der Anfrage ergibt einen Zirkelbezug.[17]
507 	Insufficient Storage 	Die Anfrage konnte nicht bearbeitet werden, weil der Speicherplatz des Servers dazu zurzeit nicht mehr ausreicht.[9]
508 	Loop Detected 	Die Operation wurde nicht ausgeführt, weil die Ausführung in eine Endlosschleife gelaufen wäre. Definiert in der Binding-Erweiterung für WebDAV gemäß RFC 5842, weil durch Bindings zyklische Pfade zu WebDAV-Ressourcen entstehen können.
509 	Bandwidth Limit Exceeded 	Die Anfrage wurde verworfen, weil sonst die verfügbare Bandbreite überschritten würde (inoffizielle Erweiterung einiger Server).
510 	Not Extended 	Die Anfrage enthält nicht alle Informationen, die die angefragte Server-Extension zwingend erwartet.[18]
511 	Network Authentication Required 	Der Client muss sich zuerst authentifizieren um Zugang zum Netzwerk zu erhalten.[11]'


# Trenner der Spalten im log
$log_separator = " "


# Stelle des Errorcode in der Log-Zeile (von rechts)
$errorcode_in_log = "4"




###################################
# ENDE DER ZU SETZENDEN VARIABLEN #
###################################



# neuestes log ermitteln

$filename = get-childitem -Path "$path" -file | sort -Property creationtime  -Descending | select -First 1 | select -expandProperty name


# log nach errorcodes durchsuchen und in eine errorcode-datei packen

Foreach($Pattern in $errorcodes){
    $OutFile = "$OutPath\$Pattern.log"
    $PatternLines = Select-String -path "$Path\$filename" -pattern $Pattern
        
    
    foreach($line in $patternlines) {
       $line_error = $line.ToString().Split("$log_separator") | Select-Object -Last $errorcode_in_log
       if ($line_error[0] -eq $Pattern){
        $line >> $OutFile   #Ausgabe in ein File
        }
    }
}


# erstellte errorfiles ermitteln
$errorfiles = get-childitem -Path "$Outpath\*.log"  | select -expandProperty fullname

# gesamtdatei prüfen, alte löschen und neue erstellen
$combined_exists = test-path $OutPath\combined_errors.txt

if ($combined_exists -eq $true){
    remove-item $OutPath\combined_errors.txt
}

New-Item -ItemType file "$OutPath\combined_errors.txt" –force



# errordateien mit inhalt ausfindig machen und deren inhalt in die gesamtdatei schreiben
ForEach($file in $errorfiles){
    $filesize = get-item $file
    $error_name = get-item $file | select -ExpandProperty basename
    if ($filesize.Length -gt 0){
        echo "`n##################`n#      $error_name       #`n##################"  | Add-Content $outpath\combined_errors.txt
        Get-Content $file | Add-Content $outpath\combined_errors.txt
        }
}



# überprüfen ob die gesamtdatei leer ist und falls nicht, diese an die/den oben genannten empfänger/n per mail verschicken
$combined_filesize = get-item $outpath\combined_errors.txt

if ($combined_filesize.length -gt 0){

    $attached_files = "$OutPath\combined_errors.txt"
    send-mailmessage -from $mailfrom -to $mailto -smtpserver $smtpserver -subject $betreff -body $body -encoding UTF8 -Attachments $attached_files
}


# tempräre errorfiles wieder entfernen, wenn überhaupt welche angelegt wurden
$log_exists = test-path $OutPath\*.log

if ($log_exists -eq $true){
    remove-item $errorfiles
}
