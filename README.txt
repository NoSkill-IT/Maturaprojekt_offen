In "Rohe Spieldateien" sind die Spieldateien so gespeichert, wie sie tatsächlich in der Engine bearbeitet wurden.
Mit Godot 4.5stable starten


Installationsanweisungen Windows

1. game_windows.zip herunterladen und entpacken.
2. game.exe starten
Falls beim Starten eine Fehlermeldung erscheint, muss in den Dateieigenschaften von game.exe der Zugriff freigegeben werden
(bei "Die Datei stammt von einem anderen Computer. Der Zugriff wurde aus Sicherheitsgründen eventuell blockiert" das Häkchen bei "Zulassen" setzen)

Installationsaweisungen MacOS

1. game_macOS.zip herunterladen und entpacken.
2. Folgende Anweisung im Terminal ausführen um Gatekeeper zu umgehen
Sim_game_v0.app % chmod +x "$HOME/Downloads/Sim_game_v0.app/Contents/MacOS/Sim_game_v0"
xattr -dr com.apple.quarantine "$HOME/Downloads/Sim_game_v0.app"
open "$HOME/Downloads/Sim_game_v0.app"
open "/Pfad/zu/Sim_game_v0.app"
