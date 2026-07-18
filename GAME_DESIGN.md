# PANEM ARENA — Game Design Dokument

Ein 3D-Survival-Battle-Royale nach Vorbild der 74. Hungerspiele (Tribute von Panem, Band 1), gebaut mit **Godot 4** (Forward+-Renderer, möglichst realistische Optik).

> **Rechtlicher Hinweis:** „Die Tribute von Panem / The Hunger Games" ist geschützte IP (Suzanne Collins / Lionsgate). Als privates Fanprojekt unproblematisch — für eine Veröffentlichung müssen Namen, Logos und direkte Bezüge ersetzt werden (z. B. „Arena 74" statt „Hunger Games", eigene Distrikt-Namen).

---

## 1. Was passiert in den 74. Hungerspielen? (Vorlage)

Kern der Vorlage, den das Spiel abbilden soll:

- **24 Tribute** (je 1 Junge + 1 Mädchen aus 12 Distrikten) kämpfen in einer riesigen, vollständig kontrollierten Arena, bis nur eine:r überlebt.
- Die Arena der 74. Spiele: eine flache Ebene aus hartem Boden mit dem **Füllhorn (Cornucopia)** im Zentrum — ein goldenes, kletterbares Horn voller Waffen, Nahrung, Camping- und Medizin-Ausrüstung. Drumherum: **Wald, Bäche, Wiesen, ein See, ein Weizenfeld, Höhlen und Teiche**. Die Arena ist so groß, dass man mehrere Tage von einem Ende zum anderen läuft.
- **Start:** Die 24 Tribute stehen im Ring um das Füllhorn auf Metallplatten. **60 Sekunden Countdown** — wer vorher runtersteigt, wird von Landminen getötet. Dann: das **Blutbad** um den Loot im Füllhorn. Die besten Items liegen am Horn, schwächerer Loot weiter außen verstreut.
- **Die Spielmacher (Gamemaker)** kontrollieren alles: Temperatur (eiskalte Nächte, glühende Tage), Waldbrände als „Treiber", das Austrocknen von Wasserquellen, und sie setzen **Mutationen** ein — u. a. **Jägerwespen** (Tracker Jacker: verfolgen ihre Opfer, halluzinogenes, potenziell tödliches Gift) und im Finale **Wolfsmutts**, die die gefallenen Tribute repräsentieren.
- **Das Fest (Feast):** Die Spielmacher laden zu einem Event am Füllhorn — für jeden Distrikt liegt dort genau das bereit, was er am dringendsten braucht (z. B. Medizin). Hochrisiko-Hotspot.
- **Sponsoren:** Wer beim Publikum gut ankommt, bekommt vom Mentor **Geschenke per Fallschirm** (Medizin, Suppe, Brot). Geschenke werden mit fortschreitendem Spiel teurer.
- **Wasser & Nahrung** sind knapp: Wasser muss mit Jod entkeimt werden, Nahrung wird gejagt/gesammelt (giftige Beeren = Todesfalle „Nachtschatten").
- **Tote:** Kanonenschuss beim Tod, abends werden die Gefallenen am Himmel projiziert. Ein Hovercraft birgt die Leichen.
- **Endgame:** Die Spielmacher trocknen alle Wasserquellen bis auf den See aus und treiben die letzten Tribute dort zum Finale zusammen.

---

## 2. Spielkonzept

- **Genre:** Third-Person Survival-Battle-Royale mit Stealth- und Survival-Fokus (langsamer & taktischer als Fortnite — näher an „The Long Dark trifft Hunt: Showdown").
- **Spieler:** 1 menschlicher Spieler + 23 KI-Tribute (Multiplayer = späterer Ausbau).
- **Ziel:** Als letzte:r überleben. Gewinnen durch Kampf **oder** Verstecken/Überleben — beide Wege müssen tragfähig sein.
- **Rundenlänge:** Eine komplette Partie ≈ 45–90 Minuten Echtzeit = ca. 7–14 Arena-Tage (Zeitraffer, konfigurierbar).

### Core Loop
1. **Vorbereitung** (Tribut wählen/auswürfeln, Attribute sehen, Strategie festlegen)
2. **Countdown & Blutbad** (Risiko-Entscheidung: Loot greifen oder fliehen?)
3. **Überleben** (Wasser, Nahrung, Wärme, Schlaf managen; craften; jagen)
4. **Konflikt** (KI-Tribute, Allianzen, Spielmacher-Events zwingen zu Bewegung)
5. **Endgame** (Arena schrumpft „organisch" durch Events → Finale am See/Füllhorn)
6. **Sieg/Tod → Statistik, Publikums-Rating, Freischaltungen**

---

## 3. Die Tribute — Attribute & Stärken

Jeder Tribut hat ein Profil aus 6 Attributen (1–10):

| Attribut | Wirkung |
|---|---|
| **Stärke** | Nahkampfschaden, Tragekapazität, Ringen |
| **Geschick** | Fernkampf-Präzision (Bogen/Messerwurf), Klettern, Ausweichen |
| **Ausdauer** | Sprint-Dauer, Hunger-/Durst-Resistenz, Wundheilung |
| **Überleben** | Erfolgsquote bei Jagen, Pflanzen erkennen (giftig/essbar!), Feuer machen, Wasser finden |
| **Tarnung** | Sichtbarkeit für KI, Geräusche, Spuren, Camouflage-Qualität |
| **Charisma** | Sponsoren-Rating-Multiplikator → billigere/häufigere Geschenke |

### Distrikt-Archetypen (bestimmen Start-Attribute)
- **D1/D2/D4 „Karrieros":** hohe Stärke/Geschick, niedriges Überleben — jagen im Rudel, kontrollieren nach dem Blutbad das Füllhorn.
- **D3/D5/D6:** Technik — können **Fallen** bauen (Minen reaktivieren, Schlingen), Elektronik.
- **D7 (Holz):** Axt-Bonus, gutes Klettern.
- **D10/D11 (Vieh/Landwirtschaft):** hohes Überleben, Pflanzen-/Tierkenntnis.
- **D12 (Kohle):** Allrounder, Bogen-/Jagd-Bonus, hohe Ausdauer (Katniss-Profil).

### KI-Verhalten (pro Tribut ein Behavior-Profil)
- **Aggressiv** (Karrieros): patrouillieren, jagen aktiv, bewachen Loot.
- **Überlebend**: meidet Kontakt, sammelt, versteckt sich (Rue-Profil).
- **Opportunist**: greift nur Schwache/Verwundete an, plündert Kämpfe.
- **Allianzen:** KI bildet Bündnisse (Karriero-Rudel ab Start; situative 2er-Bündnisse), die im Endgame zerbrechen (Verrat-Logik mit Vertrauenswert).
- KI hat dieselben Bedürfnisse (Durst/Hunger) → wird von denselben Events zum See getrieben wie der Spieler.

---

## 4. Loot-System

### 4.1 Füllhorn (Blutbad-Loot, 3 Ringe)
- **Ring A (im/am Horn):** Top-Waffen (Bogen + Pfeile, Schwert, Speere, Wurfmesser-Set), Medizin-Kits, Schlafsäcke, Nachtsichtbrille.
- **Ring B (10–30 m):** Rucksäcke mit Zufallsinhalt (Seil, Jodflasche, Trockenfleisch, Plane, Draht).
- **Ring C (30–60 m):** Kleinkram (leere Flasche, Plastikfolie, ein Laib Brot, Messer).
- Nach dem Blutbad wird das Füllhorn zum **Karriero-Camp** mit bewachtem Loot-Berg (+ von D3-Tribut reaktivierte Minen als Falle — wie im Buch).

### 4.2 Welt-Loot & Crafting
- **Jagd:** Kaninchen, Vögel, Fische (See/Bach), Rehe → braten am Feuer (Feuer = Rauch = Verrat der Position!).
- **Sammeln:** Beeren (essbar vs. **Nachtschatten** — tödlich; Überleben-Attribut entscheidet, ob der Spieler einen Warnhinweis sieht), Wurzeln, Kräuter (Heilpaste gegen Jägerwespen-Stiche).
- **Crafting (einfach halten):** Fackel, Schlinge/Falle, Speer schnitzen, Verband, Camouflage (Schlamm/Blätter), Wasser entkeimen (Jod oder Abkochen).

### 4.3 Sponsoren-Geschenke (Fallschirm)
- Verstecktes **Publikums-Rating** steigt durch: Kills, knappe Fluchten, Allianz-Drama, Verletzungen überleben, „Kamera-Momente". Sinkt durch: tagelanges Verstecken ohne Aktion.
- Geschenke skalieren mit Spielfortschritt und werden teurer (wie im Buch): Wasser → Brot → Suppe → Brandsalbe → High-End-Medizin.
- Mentor-Logik: Geschenke kommen genau dann, wenn das Rating hoch ist **und** ein Bedürfnis kritisch wird — nie auf Bestellung.

### 4.4 Das Fest (Feast)
- Ansage per Arena-Lautsprecher, Tische fahren am Füllhorn aus.
- Pro überlebendem Tribut ein Beutel mit dem, was er **am dringendsten braucht** (System prüft: kritische Wunde → Medizin; kein Wasser-Zugang → Kanister; keine Waffe → Waffe).
- Design-Ziel: der stärkste erzwungene Konfliktpunkt im Mittelspiel.

---

## 5. Survival-Systeme („Runden" = Tage)

### 5.1 Tag/Nacht-Zyklus
- 1 Arena-Tag ≈ 8–12 Minuten Echtzeit.
- **Nachts:** Temperatursturz (ohne Schlafsack/Feuer → Erfrierungsschaden), Sichtweite sinkt, KI-Karrieros jagen mit Fackeln/Nachtsichtbrille.
- **Abendritual:** Kanonenschüsse gesammelt, **Himmelsprojektion** der heute Gefallenen (Distrikt-Nummer + Porträt), Hymne. Wichtig fürs Spielgefühl UND als Information (wer lebt noch?).

### 5.2 Bedürfnisse
| Bedürfnis | Verfall | Kritisch-Folge |
|---|---|---|
| **Durst** | schnell (½ Tag) | Ausdauer-Malus → Bewusstlosigkeit → Tod |
| **Hunger** | langsam (2–3 Tage) | Stärke/Geschick-Malus, lauter Magen (Stealth-Malus!) |
| **Schlaf** | 1× pro Nacht nötig | Wahrnehmungs-Malus, Halluzinations-Schleier |
| **Temperatur** | situativ | Zittern (Zielwackeln) → Schaden |
| **Wunden** | durch Kampf/Fall/Stiche | Blutung (Spur für Verfolger!), Infektion ohne Behandlung |

### 5.3 Wetter & Spielmacher (der „AI-Director")
Der **Gamemaker** ist ein Regie-System, das Langeweile misst (Zeit ohne Spieler-KI-Kontakt, Abstand der Tribute) und eingreift:

- **Wetter:** Hitzewelle, Gewitterregen (löscht Feuer, verwischt Spuren), Nebel, eiskalte Nacht. Alles dient der Regie, nichts ist rein zufällig.
- **Waldbrand mit Feuerbällen:** treibt Tribute aus „zu sicheren" Zonen Richtung Zentrum (Buch-Szene). Hinterlässt verbrannte Zone (kein Loot, keine Deckung).
- **Wasser-Austrocknung (Endgame):** Bäche/Teiche verschwinden nacheinander → alle müssen zum See. Das ist unsere „Zone" — statt Battle-Royale-Kreis eine **diegetische** Verknappung.
- **Mutationen:**
  - **Jägerwespen-Nester** (in Bäumen; Erschütterung/Rauch löst Schwarm aus; Stiche → Halluzinations-Shader + DoT; können taktisch auf Gegner geworfen werden — Katniss-Move).
  - **Wolfsmutts (nur Finale):** spawnen am Waldrand, wenn ≤3 Tribute leben, treiben alle aufs Füllhorn-Dach. Je gefallener Tribut ein Mutt (Fell-Farbe/Halsband mit Distriktnummer).
  - **Spotttölpel** (Ambient + Gameplay: imitieren Geräusche → 4-Noten-Signal als Allianz-Kommunikation).
- **Lautsprecher-Ansagen** (Claudius Templesmith): Feast, Regeländerungen — mit dem berühmten Twist: **„Zwei Sieger, wenn aus demselben Distrikt"** als optionale Spielvariante (Koop mit einem KI-Partner + möglicher Widerruf im Finale).

---

## 6. Kampf & Stealth

- **Waffen:** Bogen (Skill-basiert, Pfeile begrenzt & bergbar), Wurfmesser, Speer, Schwert/Machete, Axt, Sichel, Faust/Ringen, Steine. Keine Schusswaffen (Lore-treu).
- **Fallen:** Schlingen (D11-Stil), Grubenfalle, reaktivierte Minen (nur D3-Profil), Wespennest-Abwurf.
- **Stealth als First-Class-System:** Sichtkegel + Hörradius der KI; Gras/Büsche/Baumkronen als Verstecke; **Klettern auf Bäume** (Karrieros mit hoher Stärke können nicht folgen — Buch-Logik); Schlamm-Camouflage; Spuren (Fußabdrücke, Blut, Rauch) die KI lesen kann.
- **Kein HP-Schwamm:** 2–4 Treffer sind tödlich. Kämpfe sind kurz, brutal, vermeidbar. Wunden bleiben (Humpeln, Blutspur) — Realismus vor Balance-Symmetrie.

---

## 7. Die Arena (Level-Design)

Kreisrunde Arena, Ø ≈ 2–3 km (im Prototyp 1 km), unsichtbares Kraftfeld als Grenze:

```
            Berghang/Felsen (N)
     Wald (dicht) ────────── Höhlen
    /                              \
  Bach ──> Teiche      Füllhorn-Ebene (Zentrum)
    \                              /
     Wiese ── Weizenfeld (S) ── See (SO)
```

- **Füllhorn-Ebene:** offenes Sichtfeld, keine Deckung — Risiko pur.
- **Wald (≈60 % der Fläche):** Hauptbiom. Dichte Vegetation, Jägerwespen-Nester, jagdbares Wild, kletterbare Bäume.
- **Bach + Teiche:** Wasserquellen (werden im Endgame trockengelegt), Fische.
- **See:** einzige permanente Wasserquelle → Endgame-Bühne.
- **Weizenfeld:** hüfthohes Gras = Stealth-Paradies, aber Rascheln verrät.
- **Höhlen:** sichere Schlafplätze, Regenschutz (Peeta-Höhle), aber Sackgassen.
- **Verbrannte Zone:** entsteht dynamisch durch den Waldbrand.

---

## 8. Realistische Grafik in Godot 4 — Umsetzung

Ziel: das grafische Maximum aus Godot 4.x (Forward+) herausholen:

- **Licht/GI:** `DirectionalLight3D` (Sonne) + **SDFGI** für Echtzeit-Global-Illumination, **volumetrischer Nebel** (Morgennebel im Wald!), `WorldEnvironment` mit physikalischem Himmel (Tag/Nacht-Rotation), SSAO + SSIL, Screen-Space-Reflections auf dem See.
- **Post-Processing:** ACES-Tonemapping, Bloom (dezent), Depth of Field in Cutscene-Momenten, Vignette/Verzerrungs-Shader für Jägerwespen-Halluzinationen, Hitzeflimmern beim Waldbrand.
- **Terrain:** **Terrain3D-Addon** (De-facto-Standard für Godot, C++-Performance) mit Splatmap (Erde/Gras/Fels/Sand).
- **Vegetation:** PBR-Bäume/Gras via Asset-Bibliotheken (unten), Wind-Shader auf Blättern/Gras, dichte Bodendecker mit MultiMesh + Distanz-Culling.
- **Assets (fotorealistisch, kostenlos):**
  - **Poly Haven** — HDRIs, PBR-Texturen, gescannte Modelle (CC0)
  - **ambientCG** — PBR-Materialien (CC0)
  - **Quaternius / Kenney** — Fallback-Props
  - Charaktere: **Mixamo** (Rigs + Animationen) oder **Character Creator/MakeHuman**-Export
- **Wasser:** Godot-Water-Shader (Gerstner-Wellen auf dem See, Fluss-Flowmap für den Bach).
- **Wetter-VFX:** GPUParticles (Regen, Asche, Glut), Wet-Shader (Roughness runter bei Regen), Blitz als getimte `DirectionalLight`-Pulse.
- **Audio:** entscheidend für Realismus — Wald-Ambience-Schichten (Tag/Nacht), 3D-Positional (Schritte, Kanonenschuss hallt über die ganze Arena, Spotttölpel-Rufe), Hymne abends.

**Performance-Budget:** M-Serie-Mac, 60 FPS bei 1440p → LOD auf allem, Occlusion Culling, SDFGI in „Half Resolution".

---

## 9. Technische Architektur (Godot)

```
res://
├── scenes/
│   ├── main_menu.tscn
│   ├── arena/            # Terrain, Biome, Füllhorn, See...
│   ├── tribute/          # player.tscn, ai_tribute.tscn (geteilte Basis)
│   ├── items/            # Waffen, Loot, Fallschirm
│   └── mutts/            # Jägerwespen-Schwarm, Wolfsmutt, Spotttölpel
├── systems/  (Autoloads)
│   ├── game_manager.gd       # Phasen: Countdown → Bloodbath → Tage → Finale
│   ├── gamemaker.gd          # AI-Director: Events, Wetter, Spannung-Metrik
│   ├── weather_system.gd     # Wetterzustände + Übergänge + VFX
│   ├── day_night.gd          # Sonnenstand, Temperatur, Himmelsprojektion
│   ├── sponsor_system.gd     # Rating, Geschenk-Auswahl, Fallschirm-Spawn
│   ├── loot_tables.gd        # Ring A/B/C, Welt-Loot, Feast-Logik
│   └── audio_director.gd
├── ai/
│   ├── behavior/             # LimboAI oder Beehave (Behavior Trees)
│   ├── alliance_manager.gd   # Bündnisse, Vertrauen, Verrat
│   └── senses.gd             # Sicht/Gehör/Spurenlesen
└── data/
    ├── tributes.json         # 24 Profile, Distrikt-Archetypen
    ├── items.json
    └── events.json           # Gamemaker-Eventpool mit Triggerbedingungen
```

- **KI:** Behavior Trees via **LimboAI**-Addon (aktiv gepflegt), `NavigationRegion3D` fürs Terrain, Utility-Layer für Bedürfnis-Entscheidungen.
- **Spieler & KI teilen dieselbe Tribut-Basisklasse** (Bedürfnisse, Inventar, Kampf) — nur der Controller unterscheidet sich. Das hält Balance ehrlich.
- **Determinismus-freundlich:** Seed pro Partie (Loot-Verteilung, KI-Profile, Eventpool) → Runs sind teilbar/wiederholbar.

---

## 10. Roadmap

| Phase | Inhalt | Ergebnis |
|---|---|---|
| **M1 — Graybox-Prototyp** | Terrain 1 km², Third-Person-Controller, Füllhorn-Loot, 7 Dummy-KIs, Tag/Nacht, Durst/Hunger | spielbare Runde, alles Platzhalter-Grafik |
| **M2 — Survival Slice** | Jagen/Sammeln/Crafting, Feuer+Rauch, Stealth-Sinne der KI, Kampf (Bogen/Nahkampf), Kanone+Himmelsprojektion | „ein Tag in der Arena" fühlt sich gut an |
| **M3 — Gamemaker** | Event-Director, Wetter, Waldbrand, Jägerwespen, Feast, Wasser-Austrocknung, Sponsoren | komplette Partie mit Spannungsbogen |
| **M4 — Grafik-Pass** | Terrain3D + PBR-Vegetation, SDFGI, volumetrischer Nebel, Wasser, Wetter-VFX, Audio | „Realismus"-Ziel erreicht |
| **M5 — Inhalt & Polish** | 24 Tribut-Profile, Allianzen/Verrat, Wolfsmutt-Finale, Menü/Statistik, Balancing | Release-Kandidat |

**Scope-Warnung (ehrlich):** M1–M2 sind gut machbar. M3+ ist ambitioniert — das Spiel lebt aber genau von der Gamemaker-Regie, deshalb ist sie vor der Grafik priorisiert.

---

## 11. Offene Design-Entscheidungen

1. **Perspektive:** Third-Person (empfohlen, man sieht den eigenen Tribut) vs. First-Person (immersiver, schwerer für Stealth-Lesbarkeit)?
2. **Permadeath-Härte:** Ein Tod = Partie vorbei (Buch-treu) vs. milde Meta-Progression (freigeschaltete Distrikte/Skins)?
3. **„Zwei-Sieger-Regel"** als Modus ab M5 oder ganz streichen?
4. **Tribut-Wahl:** Frei wählbarer Distrikt oder ausgelost (Reaping-Zeremonie als Intro)?

---

## Quellen (Recherche)

- [74th Hunger Games — Hunger Games Wiki](https://thehungergames.fandom.com/wiki/74th_Hunger_Games)
- [74th Hunger Games Arena — Hunger Games Wiki](https://thehungergames.fandom.com/wiki/74th_Hunger_Games_arena)
- [Cornucopia / Bloodbath — Hunger Games Wiki](https://thehungergames.fandom.com/wiki/Cornucopia_bloodbath)
- [Arena (Mechaniken, Gamemaker-Kontrolle) — Hunger Games Wiki](https://thehungergames.fandom.com/wiki/Arena)
- [Tracker Jacker — Hunger Games Wiki](https://thehungergames.fandom.com/wiki/Tracker_jacker)
- [Muttations Explained — Book Analysis](https://bookanalysis.com/the-hunger-games/muttations/)
- [The 74th Hunger Games Explained — Book Analysis](https://bookanalysis.com/the-hunger-games/74th-hunger-games/)
- [The Hunger Games (novel) — Wikipedia](https://en.wikipedia.org/wiki/The_Hunger_Games_(novel))
