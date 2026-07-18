# PANEM ARENA — Umsetzungsplan

Godot-4-Projekt, entwickelt phasenweise. Jede Phase endet mit einem lauffähigen Stand + Commit/Push.
Details zum Spieldesign: siehe [GAME_DESIGN.md](GAME_DESIGN.md).

## Phase 0 — Projekt-Setup ✅
- [x] Git-Repo + GitHub-Remote (`avrundingdesign-ctrl/game`)
- [x] Godot 4 installieren (Homebrew, 4.7.1)
- [x] Godot-Projektgerüst (`project.godot`, Ordnerstruktur, Input-Map)
- [x] Headless-Validierung des Projekts als Build-Check

## Phase 1 — Graybox-Prototyp (M1) ✅
- [x] Terrain-Basis: Ebene (Platzhalter), Arena-Grenze (Kraftfeld-Clamp)
- [x] Füllhorn-Platzhalter + 24 Startplatten im Ring
- [x] Third-Person-Controller (Gehen, Sprinten, Springen, Kamera)
- [x] Tag/Nacht-Zyklus (Sonnenrotation, Beleuchtungswechsel)
- [x] Bedürfnisse v1: Durst & Hunger mit HUD-Anzeige
- [x] Loot v1: Items am Füllhorn aufheben, Inventar mit 6 Slots
- [x] KI: 23 Tribute mit Profilen (Karriero/Überlebende/Opportunist/…)
- [x] Spielphasen: Countdown (60 s) → Blutbad → Tage → Finale → Tod/Sieg
- [x] Testmodi: PANEM_FAST (Zeitraffer) + PANEM_OBSERVER (KI-Simulation)

## Phase 2 — Survival Slice (M2) ✅
- [x] Kampf v1: Nahkampf + Bogen mit ballistischen Pfeilen (bergbar)
- [x] Wunden/Blutungen (Verband stoppt), Kanone, Himmelsprojektion abends
- [x] KI v2: Sinne (Sichtweite nachts/gegen Tarnung reduziert, Sprint hörbar)
- [x] Wasserquellen (See + 2 Teiche); Beeren sammeln (15 % Nachtschatten!)
- [x] Lagerfeuer: platzieren, wärmt nachts, Feuerschein lockt Jäger an
- [x] Nachtkälte (23–5 Uhr) statt Schlafsystem; Schlafsack schützt; passive Heilung bei guter Versorgung
- [ ] Essen braten am Feuer (→ Phase 5)

## Phase 3 — Gamemaker / Regie (M3) ✅
- [x] Event-Director: Langeweile-Metrik (20 Arena-Stunden ohne Tod → Eingriff)
- [x] Wetter: Regen (löscht Feuer), Nebel (Sicht 45 %), Gluthitze (Durst 1,8×)
- [x] Waldbrand-Event (wachsende Zone, 6 Schaden/s, KI flieht Richtung Zentrum)
- [x] Jägerwespen-Nester (6 an Bäumen; Schwarm verfolgt, Gift = DoT + Verlangsamung)
- [x] Feast-Event am Füllhorn (8 Top-Items, Bedürftige + Karrieros riskieren es)
- [x] Wasser-Austrocknung (Finale/Tag 4: Teiche weg, nur der See bleibt)
- [x] Wolfsmutt-Finale (3–5 Mutts mit Distriktnummern der Gefallenen, treiben zum Zentrum)
- [x] Sponsoren: Rating (Kills +15, Charisma-Bonus), Geschenke bei kritischem Bedürfnis, steigende Schwelle, Fallschirm-Einschweben
- [x] Lautsprecher-Ansagen der Spielmacher im HUD

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
