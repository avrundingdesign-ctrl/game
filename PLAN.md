# PANEM ARENA — Umsetzungsplan

Godot-4-Projekt, entwickelt phasenweise. Jede Phase endet mit einem lauffähigen Stand + Commit/Push.
Details zum Spieldesign: siehe [GAME_DESIGN.md](GAME_DESIGN.md).

## Phase 0 — Projekt-Setup ✅ teilweise
- [x] Git-Repo + GitHub-Remote (`avrundingdesign-ctrl/game`)
- [ ] Godot 4 installieren (Homebrew)
- [ ] Godot-Projektgerüst (`project.godot`, Ordnerstruktur, Input-Map)
- [ ] Headless-Validierung des Projekts als Build-Check

## Phase 1 — Graybox-Prototyp (M1)
- [ ] Terrain-Basis: Ebene mit Hügeln (Platzhalter), Arena-Grenze (Kraftfeld)
- [ ] Füllhorn-Platzhalter + 24 Startplatten im Ring
- [ ] Third-Person-Controller (Gehen, Sprinten, Springen, Kamera)
- [ ] Tag/Nacht-Zyklus (Sonnenrotation, Beleuchtungswechsel)
- [ ] Bedürfnisse v1: Durst & Hunger mit HUD-Anzeige
- [ ] Loot v1: Items am Füllhorn aufheben, einfaches Inventar
- [ ] Dummy-KI: 7 Tribute, die herumlaufen und Loot nehmen
- [ ] Spielphasen: Countdown (60 s) → Spiel läuft → Tod/Sieg-Screen

## Phase 2 — Survival Slice (M2)
- [ ] Kampf v1: Nahkampf (Messer/Schwert) + Bogen mit Pfeilphysik
- [ ] Gesundheit/Wunden, Kanonenschuss bei Tod, Himmelsprojektion abends
- [ ] KI v2: Sinne (Sehen/Hören), Zustände (patrouillieren/jagen/fliehen)
- [ ] Wasserquellen (See/Bach): trinken; Beeren sammeln (essbar vs. giftig)
- [ ] Lagerfeuer: bauen, Essen braten, Rauch verrät Position
- [ ] Schlafsystem + Nacht-Temperatur

## Phase 3 — Gamemaker / Regie (M3)
- [ ] Event-Director: Spannungsmetrik + Eventpool
- [ ] Wetter: Regen, Hitze, Nebel (Zustandsmaschine + Übergänge)
- [ ] Waldbrand-Event (Zone + Schaden + Treiber-Logik)
- [ ] Jägerwespen (Schwarm, Halluzinations-Effekt)
- [ ] Feast-Event am Füllhorn
- [ ] Wasser-Austrocknung (Endgame) + Wolfsmutt-Finale
- [ ] Sponsoren-Rating + Fallschirm-Geschenke

## Phase 4 — Grafik-Pass (M4)
- [ ] WorldEnvironment: SDFGI, volumetrischer Nebel, SSAO, Tonemapping
- [ ] Terrain-Texturen (PBR), Vegetation mit Wind-Shader
- [ ] Wasser-Shader (See), Wetter-VFX (Regen/Asche-Partikel)
- [ ] Audio: Ambience, 3D-Sounds, Hymne, Kanone

## Phase 5 — Inhalt & Polish (M5)
- [ ] 24 Tribut-Profile mit Distrikt-Archetypen (Datengetrieben, JSON)
- [ ] Allianzen & Verrat (Karriero-Rudel)
- [ ] Hauptmenü, Reaping-Intro, Statistik-Screen
- [ ] Balancing-Durchgang + Bugfixes

## Arbeitsweise
- Nach jeder abgeschlossenen Phase (und bei größeren Zwischenständen): Commit + Push.
- Godot-Projekt wird headless validiert (`godot --headless --import` + Skript-Check), da kein Editor-Zugriff.
- Grafik-Realismus kommt bewusst NACH funktionierendem Gameplay (Phase 4).
