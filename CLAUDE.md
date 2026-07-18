# Panem Arena — Hinweise für Claude

Godot-4.7-Projekt (GDScript, Forward+). Design in GAME_DESIGN.md, Phasenplan in PLAN.md.

## Befehle

- Godot-Binary: `/Applications/Godot.app/Contents/MacOS/Godot`
- Nach neuen `class_name`-Skripten oder Autoload-Änderungen: `godot --headless --import .` (aktualisiert den Klassen-Cache)
- Smoke-Test: `PANEM_FAST=1 godot --headless .` im Hintergrund laufen lassen und Log prüfen (5 s Countdown, 15 s Blutbad, 60 s Tage; Bedürfnis-Verfall skaliert mit)
- Schneller Syntax-Check: `godot --headless --quit-after 10 .`

## Konventionen

- Kommentare und Bezeichner auf Deutsch (keine Umlaute in Identifiern: `staerke`, `ueberleben`)
- UI wird in Code aufgebaut (ui/hud.gd), .tscn-Dateien bleiben minimal
- Typ-Inferenz `:=` nie auf Dictionary-Zugriffe (GDScript kann Variant nicht inferieren) — expliziten Typ oder `float()` verwenden
- Spieler und KI teilen `TributeBase` (scenes/tribute/tribute_base.gd); Balance-Regeln immer dort, nie im Controller
- Autoloads: GameManager, DayNight, LootTables (Reihenfolge in project.godot beibehalten)

## Git

- Remote: https://github.com/avrundingdesign-ctrl/game — nach jedem abgeschlossenen Arbeitsschritt committen und pushen
- Das übergeordnete Verzeichnis ~/Documents/Games liegt in einem versehentlichen Home-Dir-Repo — NIE von dort aus committen, immer aus panem-arena/
