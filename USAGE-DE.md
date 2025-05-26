# Benutzerhandbuch (Deutsch)

🎯 **Zweck des Skripts**
Dieses AutoLISP-Skript dient dazu, doppelte Property Set Definitions (PSD) in einer AutoCAD Architecture-Zeichnung zu identifizieren und zu entfernen. Dabei wird jeweils nur die ursprüngliche Stammdefinition (z.\u00a0B. `Pset_QuantityTakeOff`) behalten, w\u00e4hrend automatisch erzeugte Kopien wie `(2)`, `(3)` usw. gel\u00f6scht werden.

📦 **Skript laden**
1. Starte AutoCAD Architecture.
2. Tippe den Befehl `APPLOAD` in die Befehlszeile ein.
3. Lade die Datei `PSDDEDUP lsp`.

Nach dem Laden erscheint in der Befehlszeile:
```
PSDDEDUP geladen – Befehl PSDDEDUP eingeben.
```
Das Skript ist jetzt einsatzbereit.

▶️ **Befehl ausf\u00fchren**
1. Tippe `PSDDEDUP` in die Befehlszeile.
2. Es folgt die Eingabeaufforderung:
```
Basisnamen-Filter eingeben (Komma,* ?) <Alle>:
```
Hinweis: Du kannst hier Filtermuster eingeben, z.\u00a0B.:
```
2dBlock,RubnerPolylinien*
```
Wenn du nur Enter dr\u00fcckst, werden alle PSDs \u00fcberpr\u00fcft.

🔎 **Duplikate pr\u00fcfen**
Wenn PSD-Duplikate erkannt wurden, zeigt das Skript:
```
=== Doppelte Gruppen ===
1) Basisname \u2192 Duplikat1, Duplikat2, ...
```
Danach wirst du aufgefordert, eine Nummer auszuw\u00e4hlen:
```
Nummer [1-… ,0=Abbruch]<0>:
```
Gib eine Nummer ein, um eine Duplikatgruppe zu bereinigen, oder `0` zum Abbrechen.

🧹 **Bereinigen und l\u00f6schen**
Zur Best\u00e4tigung erscheint:
```
Bereinige Duplikat1, Duplikat2, … [Y/N] <N>:
```
Best\u00e4tige mit `Y` oder `y` \u2192 Die Eintr\u00e4ge werden bereinigt und gel\u00f6scht.

Mit Enter oder `N` wird der Vorgang abgebrochen.

Nach erfolgreicher L\u00f6schung folgt:
```
✔ Entfernt; bitte anschlie\u00dfend PURGE manuell ausf\u00fchren.
```
F\u00fchre anschlie\u00dfend den Befehl `PURGE` aus, um leere H\u00fcllen zu entfernen.

📋 **Weitere m\u00f6gliche R\u00fcckmeldungen**
- Wenn keine PSDs in der Zeichnung enthalten sind:
```
=> Keine Property-Set-Definitionen in dieser Zeichnung.
```
- Wenn keine Duplikate gefunden wurden:
```
=> Keine doppelten Gruppen gefunden.
```
- Wenn du den Vorgang abbrichst:
```
— Abbruch —
```

⚙️ **Funktionsweise im Hintergrund**
- Das Skript analysiert die Struktur `AEC_PROPERTY_SET_DEFS`, um alle Property Set Definitions zu erfassen.
- PSDs mit \u00e4hnlichem Basisnamen und angeh\u00e4ngten Nummern (wie `(2)`, `(3)`) werden gruppiert.
- Nur die Stammdefinition bleibt erhalten, alle Duplikate werden entfernt.
- Verweise, die eine L\u00f6schung verhindern, werden erkannt – du musst dann die Abh\u00e4ngigkeiten manuell l\u00f6sen und den Vorgang erneut starten.

