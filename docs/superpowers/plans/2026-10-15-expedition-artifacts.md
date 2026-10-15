# Expedition Artifacts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dodać do Expedition cztery trwałe sloty, sześć transformacyjnych artefaktów, zestaw Covenant of Embers z progami 2/3–3/3 oraz działające efekty na istniejącej arenie.

**Architecture:** Zasoby `ArtifactResource` opisują przedmioty, a czysty `ArtifactLoadout` waliduje kolekcję i progi setów. `ArtifactRuntime` buduje dla jednej walki małe zachowania z `ArtifactRegistry` i komunikuje się ze współdzieloną walką wyłącznie przez `ArtifactCombatHooks`; profil i sesja pozostają jedynymi źródłami trwałego oraz zamrożonego loadoutu.

**Tech Stack:** Godot 4.6, GDScript, `.tres`, programowe UI mobile-first, natywne testy scen headless.

**Spec:** `docs/superpowers/specs/2026-10-15-expedition-artifacts-design.md`

## Global Constraints

- Dokładnie cztery uporządkowane sloty; jedno ID nie może wystąpić w dwóch slotach.
- W pierwszym pionie istnieje sześć artefaktów: trzy elementy Covenant of Embers i trzy niezależne.
- Loadout jest zamrażany przy starcie wyprawy i nie może zmienić się do zwycięstwa lub porzucenia.
- Przy 3/3 działają jednocześnie bonusy 2/3 i 3/3.
- Artefakty nie zapisują ani nie odczytują trwałego stanu roguelite.
- Efekty wtórne przenoszą pochodzenie i limit generacji, aby nie tworzyć nieskończonych łańcuchów.
- Minimalna wysokość interaktywnych kart i przycisków wynosi 88 px.
- Drop, Kodeks, duplikaty, pity counter, XP i plansza rozwoju pozostają poza tym planem.

## Review Focus

- Uszkodzone sloty (null, zła długość, duplikaty, nieposiadane ID) mają normalizować się do czterech bez błędu; test w Task 2.
- Nieznane ID zasobu lub `behavior_key` ma wyłączyć tylko ten efekt i nie blokować walki; test w Tasks 1 i 4.
- Wtórny pocisk, echo lub żar nie może ponownie uruchamiać swojego generatora; test w Tasks 5–6.
- Zakończenie/porzucenie walki przed timerem echa musi anulować callback bez wycieku i obrażeń; test w Task 5.
- Nieudany zapis wyposażenia ma przywrócić model oraz UI do poprzedniego loadoutu; test w Task 7.

---

## Mapa plików

### Nowe pliki

- `scripts/resources/artifact_resource.gd` — dane pojedynczego artefaktu.
- `scripts/resources/set_bonus_resource.gd` — progi jednego zestawu.
- `scripts/expedition/artifact_catalog.gd` — jawne ID i ładowanie sześciu zasobów/setu.
- `scripts/expedition/artifact_loadout.gd` — normalizacja slotów i aktywne progi.
- `scripts/expedition/artifacts/artifact_behavior.gd` — neutralny interfejs zachowania.
- `scripts/expedition/artifacts/artifact_registry.gd` — fabryki po `behavior_key`.
- `scripts/expedition/artifacts/artifact_runtime.gd` — cykl życia zachowań jednej walki.
- `scripts/expedition/artifacts/artifact_combat_hooks.gd` — sygnały i konteksty współdzielonej walki.
- `scripts/expedition/artifacts/independent_artifact_behaviors.gd` — Prism, Hourglass, Sigil.
- `scripts/expedition/artifacts/ember_artifact_behaviors.gd` — trzy elementy i progi setu.
- `scripts/ui/expedition_artifacts.gd`, `scenes/ui/expedition_artifacts.tscn` — kolekcja/loadout.
- `resources/artifacts/*.tres`, `resources/artifact_sets/covenant_of_embers.tres` — sześć przedmiotów i set.
- `tests/expedition_artifact_*.gd/.tscn` — model, runtime, zachowania i UI.

### Modyfikowane pliki

- `scripts/expedition/expedition_profile.gd`, `expedition_session.gd` — schema 2.
- `scripts/autoloads/expedition_manager.gd` — transakcyjne wyposażanie i migracje.
- `scripts/skills/skill_instance.gd`, `skill_caster.gd`, `projectile_base.gd` — neutralne hooki.
- `scripts/enemies/enemy_base.gd`, `scripts/player/player.gd` — stosy podpaleń i koszt HP.
- `scripts/expedition/expedition_game_manager.gd` — tworzenie/niszczenie runtime.
- `scripts/ui/expedition_hub.gd` — wejście do kolekcji.
- `tests/expedition_flow_native.gd`, `tests/run_integrity.gd` — prawdziwa arena i izolacja.

---

### Task 1: Zasoby, katalog i katalog treści

**Files:**
- Create: `scripts/resources/artifact_resource.gd`
- Create: `scripts/resources/set_bonus_resource.gd`
- Create: `scripts/expedition/artifact_catalog.gd`
- Create: `resources/artifacts/{furnace_heart,ashen_needle,cinder_crown,fractured_prism,echoing_hourglass,bloodwritten_sigil}.tres`
- Create: `resources/artifact_sets/covenant_of_embers.tres`
- Create: `tests/expedition_artifact_catalog_native.gd`
- Create: `tests/expedition_artifact_catalog_native.tscn`

**Interfaces:**
- Consumes: `Resource`, istniejący wzorzec `SkillResource`.
- Produces: `ArtifactCatalog.get_artifact(id: String) -> ArtifactResource`, `all_ids() -> Array[String]`, `get_set(set_id: String) -> SetBonusResource`.

- [ ] **Step 1: Napisz czerwony test katalogu**

Test ładuje sześć stabilnych ID, sprawdza unikalność, niepuste nazwy/opisy/klucze, dokładnie trzy
elementy `covenant_of_embers`, parametry liczbowe oraz `get_artifact("missing") == null`.

```gdscript
var expected := ["furnace_heart", "ashen_needle", "cinder_crown",
	"fractured_prism", "echoing_hourglass", "bloodwritten_sigil"]
check(ArtifactCatalog.all_ids() == expected, "Catalog exposes six stable ids")
check(ArtifactCatalog.get_artifact("missing") == null, "Unknown artifact is safe")
```

- [ ] **Step 2: Uruchom test i potwierdź RED**

Run: Godot headless `res://tests/expedition_artifact_catalog_native.tscn`.  
Expected: błąd kompilacji `ArtifactCatalog not found`.

- [ ] **Step 3: Dodaj klasy zasobów i jawny katalog**

```gdscript
class_name ArtifactResource
extends Resource
@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var region_id := "burning_grounds"
@export var behavior_key := ""
@export var behavior_parameters: Dictionary = {}
@export var set_id := ""
@export var set_piece_name := ""
```

`ArtifactCatalog` używa stałej mapy ID → preload, zwraca `null` dla nieznanego ID i kopię listy,
aby konsument nie mógł zmienić katalogu.

- [ ] **Step 4: Utwórz `.tres` z wartościami ze specyfikacji**

Parametry: Furnace `direct_hit_mult=0.8`; Prism `fragment_damage_mult=0.55`; Hourglass
`cast_interval=3`, `delay=0.35`, `cooldown_mult=1.2`; Sigil `hp_threshold=0.9`, `hp_cost=0.08`,
`damage_mult=1.35`, `area_mult=1.3`; set `stack_limit=5`, `max_generations=2`.

- [ ] **Step 5: Uruchom test GREEN i commit**

Expected: kod 0, `failures:[]`, sześć ID. Commit: `feat: define expedition artifact catalog`.

---

### Task 2: Loadout, profil schema 2 i transakcyjny zapis

**Files:**
- Create: `scripts/expedition/artifact_loadout.gd`
- Modify: `scripts/expedition/expedition_profile.gd`
- Modify: `scripts/autoloads/expedition_manager.gd`
- Modify: `tests/expedition_profile_native.gd`
- Create: `tests/expedition_artifact_loadout_native.gd/.tscn`

**Interfaces:**
- Consumes: katalog z Task 1.
- Produces: `ArtifactLoadout.normalize(owned, equipped) -> Array[String]`, `active_set_tiers(slots) -> Dictionary`; `ExpeditionManager.equip_artifact(id, slot) -> bool`, `unequip_artifact(slot) -> bool`.

- [ ] **Step 1: Napisz testy RED migracji i walidacji**

Przypadki: schema 1 zachowuje level/XP i otrzymuje sześć prototypowych ID; schema 2 z `null`, pięcioma
slotami, duplikatami i nieposiadanym ID daje cztery legalne sloty. Dwa elementy setu zwracają
`{"covenant_of_embers": 2}`, trzy zwracają poziom 3.

- [ ] **Step 2: Dodaj czysty `ArtifactLoadout`**

```gdscript
static func normalize(owned: Array[String], raw: Variant) -> Array[String]:
	var result: Array[String] = ["", "", "", ""]
	if not raw is Array: return result
	for i in mini(4, raw.size()):
		var id := raw[i] as String if raw[i] is String else ""
		if owned.has(id) and not result.has(id): result[i] = id
	return result
```

- [ ] **Step 3: Podnieś `ExpeditionProfile.SCHEMA_VERSION` do 2**

`from_dict()` przyjmuje schema 1 i 2; schema 1 dostaje komplet `ArtifactCatalog.all_ids()`. Schema 2
waliduje tablice przed iteracją. `to_dict()` zawsze zapisuje schema 2.

- [ ] **Step 4: Dodaj transakcyjne API managera**

Przed zmianą manager kopiuje sloty, waliduje ownership/indeks 0–3/duplikat, zapisuje profil i przy
`false` przywraca kopię. Test ustawia niewritable path i sprawdza rollback.

- [ ] **Step 5: Uruchom testy GREEN i commit**

Run: profile + artifact_loadout. Expected: oba exit 0. Commit: `feat: persist expedition artifact loadouts`.

---

### Task 3: Zamrożony loadout sesji i migracja

**Files:**
- Modify: `scripts/expedition/expedition_session.gd`
- Modify: `scripts/autoloads/expedition_manager.gd`
- Modify: `tests/expedition_session_native.gd`

**Interfaces:**
- Consumes: `profile.equipped_artifact_ids`.
- Produces: `ExpeditionSession.create(seed, region, artifact_ids := [])`, pole `artifact_loadout_ids: Array[String]`.

- [ ] **Step 1: Dodaj test RED migawki**

Start wyprawy kopiuje sloty; późniejsza zmiana profilu nie zmienia sesji. Roundtrip zachowuje cztery
ID. Schema 1 sesji migruje do czterech pustych slotów; null/duplikaty normalizują się bez błędu.

- [ ] **Step 2: Rozszerz fabrykę i serializację**

`start_expedition()` przekazuje zduplikowane sloty profilu. `from_dict()` rozpoznaje schema 1/2,
ale zapisuje tylko 2. Nie używa ownership profilu przy wczytaniu, bo sesja jest samodzielną migawką;
akceptuje wyłącznie znane, unikalne ID.

- [ ] **Step 3: Uruchom profile/session/flow GREEN i commit**

Expected: stare testy przechodzą bez zmiany ścieżki użytkownika. Commit: `feat: freeze artifacts in expedition sessions`.

---

### Task 4: Neutralne hooki i cykl życia runtime

**Files:**
- Create: `scripts/expedition/artifacts/artifact_behavior.gd`
- Create: `scripts/expedition/artifacts/artifact_registry.gd`
- Create: `scripts/expedition/artifacts/artifact_combat_hooks.gd`
- Create: `scripts/expedition/artifacts/artifact_runtime.gd`
- Create: `tests/expedition_artifact_runtime_native.gd/.tscn`

**Interfaces:**
- Produces: `ArtifactRuntime.setup(ids, skills, arena)`, `teardown()`; hooks `skill_cast`, `projectile_spawned`, `projectile_hit`, `status_applied`, `enemy_killed`, `player_health_spent`.

- [ ] **Step 1: Napisz test RED runtime**

Fałszywe zachowanie liczy setup/event/teardown. Runtime ignoruje nieznane ID i nieznany key, aktywuje
oba progi przy 3/3, nie obsługuje eventu po teardown i dwukrotny teardown jest bezpieczny.

- [ ] **Step 2: Zaimplementuj bazowy kontrakt**

```gdscript
class_name ArtifactBehavior
extends RefCounted
var parameters: Dictionary
var runtime: ArtifactRuntime
func setup(context: Dictionary) -> void: pass
func before_skill_recompute(_skill: SkillInstance) -> void: pass
func handle(_event: StringName, _context: Dictionary) -> void: pass
func teardown() -> void: pass
```

- [ ] **Step 3: Zaimplementuj registry i runtime**

Registry ma jawne fabryki `Callable`; runtime posiada zachowania, łączy dokładnie jedną callable z
routerem, wywołuje modyfikacje przed `skill.recompute([])` i odłącza sygnały przy teardown.

- [ ] **Step 4: Uruchom test GREEN i commit**

Commit: `feat: add isolated artifact combat runtime`.

---

### Task 5: Hooki współdzielonej walki i artefakty niezależne

**Files:**
- Create: `scripts/expedition/artifacts/independent_artifact_behaviors.gd`
- Modify: `scripts/skills/skill_instance.gd`
- Modify: `scripts/skills/skill_caster.gd`
- Modify: `scripts/skills/projectile_base.gd`
- Modify: `scripts/player/player.gd`
- Create: `tests/expedition_independent_artifacts_native.gd/.tscn`

**Interfaces:**
- Consumes: hook router z Task 4.
- Produces: event contexts z `event_id`, `origin_flags`, `generation`; zachowania Prism/Hourglass/Sigil.

- [ ] **Step 1: Napisz testy RED trzech efektów**

Prism: bazowy projectile tworzy dwa konteksty odłamków 55%, wtórny nie dzieli się. Hourglass: tylko
3., 6. cast tworzy echo po 0,35 s; teardown przed timerem anuluje. Sigil: próg 90%, koszt 8%, HP
nie spada poniżej 1, cast bez kosztu nie dostaje mnożników.

- [ ] **Step 2: Dodaj emisję hooków bez zmiany zachowania roguelite**

Router jest domyślnie nieaktywny; `SkillCaster` emituje zaakceptowany cast i udostępnia
`spawn_artifact_echo(si, direction, target, flags)`. `ProjectileBase` przechowuje `artifact_origin`
i emituje spawn/hit. `SkillInstance` stosuje runtime overrides oddzielnie od `stage_overrides`.

- [ ] **Step 3: Zaimplementuj trzy zachowania i rejestrację**

Każde sprawdza flagę własnego pochodzenia przed generowaniem. Sigil używa
`Player.try_spend_artifact_health(percent) -> bool`, która emituje HP i nie używa `take_damage()`.

- [ ] **Step 4: Uruchom nowe oraz istniejące testy skilli**

Run: independent artifacts, `skill_math_native`, `support_mechanics_native`, `run_integrity`.
Expected: nowe efekty działają, a router bez runtime nie zmienia wyników roguelite.

- [ ] **Step 5: Commit**

Commit: `feat: add independent expedition artifacts`.

---

### Task 6: Covenant of Embers i wielostackowe podpalenia

**Files:**
- Create: `scripts/expedition/artifacts/ember_artifact_behaviors.gd`
- Modify: `scripts/enemies/enemy_base.gd`
- Modify: `scripts/skills/projectile_base.gd`
- Create: `tests/expedition_ember_set_native.gd/.tscn`

**Interfaces:**
- Produces: `EnemyBase.apply_dot_stack(type, damage, duration, interval, source, stack_id, limit)`, `get_dot_stacks(type)`, `consume_dot_stacks(type, count)`.

- [ ] **Step 1: Napisz czerwone testy stosów i każdego progu**

Bez 2/3 istniejące `apply_dot` zachowuje jeden burn. Z 2/3 pięć stosów tyka niezależnie, szósty
zastępuje najstarszy. Detonacja konsumuje pięć, liczy damage z ich pozostałej siły, limituje boss
damage i żary do dwóch generacji.

- [ ] **Step 2: Zmień `_dots` na tablice wpisów zgodnie wstecznie**

`apply_dot()` zapisuje jeden wpis i zastępuje dotychczasowy tego typu. `apply_dot_stack()` dopisuje
do limitu. `_process()` iteruje wpisy, usuwa wygasłe i agreguje ikonę bez wpływu na poison/bleed.

- [ ] **Step 3: Dodaj Furnace, Needle i Crown**

Furnace modyfikuje direct hit i po fire hit dodaje jeden oznaczony stack. Needle zwiększa pierce
tylko przed pierwszym trafieniem palącego celu i emituje jedną smugę. Crown na kill wybiera
najbliższy żywy cel i kopiuje najsilniejszy burn.

- [ ] **Step 4: Dodaj Kindling Engine i Chain Conflagration**

Detonacja wymaga fire direct hit na primed target. Kontekst zawiera `chain_id` i `generation`;
zachowanie odrzuca generację >2 oraz już przetworzony `event_id`.

- [ ] **Step 5: Uruchom testy GREEN i regresje statusów**

Run: ember set, combat readability, status interactions, run integrity. Commit: `feat: add covenant of embers artifact set`.

---

### Task 7: Mobilna kolekcja i blokada aktywnej wyprawy

**Files:**
- Create: `scripts/ui/expedition_artifacts.gd`
- Create: `scenes/ui/expedition_artifacts.tscn`
- Modify: `scripts/ui/expedition_hub.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Create: `tests/expedition_artifact_ui_native.gd/.tscn`

**Interfaces:**
- Produces: sygnały `equip_requested(id, slot)`, `unequip_requested(slot)`, `back_pressed`; `setup(profile, locked)`.

- [ ] **Step 1: Napisz test UI RED**

Sprawdź cztery sloty, sześć kart, cele ≥88 px, opis kosztu, stan 2/3 i 3/3. Przy aktywnej sesji
przyciski equip są disabled i widoczny jest tekst blokady.

- [ ] **Step 2: Zbuduj ekran programowo**

Karty używają danych katalogu i prostych proceduralnych ikon zastępczych, jeśli `icon == null`.
Ekran nie liczy progów sam — używa `ArtifactLoadout.active_set_tiers()`.

- [ ] **Step 3: Połącz hub i transakcyjne API**

Manager po udanym equip odświeża ekran. Po błędzie zapisu pokazuje komunikat i ponownie renderuje
profil, który manager już cofnął. `locked = ExpeditionManager.session != null`.

- [ ] **Step 4: Uruchom UI/profile/flow GREEN i commit**

Commit: `feat: add expedition artifact loadout screen`.

---

### Task 8: Prawdziwa arena, resume, izolacja i dokumentacja

**Files:**
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Modify: `tests/expedition_flow_native.gd`
- Modify: `tests/run_integrity.gd`
- Modify: `docs/design-overview.md`

**Interfaces:**
- Consumes: cały system Tasks 1–7.
- Produces: kompletny pion artefaktów gotowy pod osobny plan lootu.

- [ ] **Step 1: Dodaj test integracyjny RED prawdziwej areny**

Wyposaż Prism + pełny set, rozpocznij wyprawę, wejdź do combat room i sprawdź runtime, aktywne
progi oraz realny projectile context. Zmień profil po starcie i potwierdź brak wpływu. Zapisz,
usuń manager, resume i sprawdź identyczne ID/progi.

- [ ] **Step 2: Podepnij lifecycle runtime**

`_start_combat()` tworzy runtime po instancji areny i przed `start_stage()`. `_clear_arena()` najpierw
wywołuje teardown, potem przywraca RunManager. Śmierć, abandon, nieudany checkpoint i `_exit_tree()`
przechodzą tą samą ścieżką.

- [ ] **Step 3: Dodaj jednoznaczny feedback aktywacji**

Runtime emituje `artifact_triggered(artifact_id, world_position)`. Arena mapuje Prism na fioletowy
rozbłysk rozdzielenia, Hourglass na echo konturu, Sigil na czerwony glif, Needle na smugę, Crown na
żar, a Conflagration na pomarańczowy pierścień. Test sprawdza dokładnie jedno zdarzenie wizualne na
aktywację oraz brak emisji po teardown; VFX nie uczestniczy w obliczeniach obrażeń.

- [ ] **Step 4: Rozszerz test izolacji w obie strony**

Ustaw roguelite passives/consumables/gold, przeprowadź eventy artefaktów, zakończ Expedition i
porównaj pełny snapshot. Następnie uruchom syntetyczny roguelite bez runtime i potwierdź brak Prism,
echo, stacków setu oraz zmian HP od Sigil.

- [ ] **Step 5: Uzupełnij dokumentację**

Dodaj sześć ID, cztery sloty, zamrożenie sesji, progi setu i jawnie odroczone loot/XP/Kodeks.

- [ ] **Step 6: Uruchom pełną weryfikację**

Uruchom sześć nowych scen, sześć bazowych scen Expedition, regresje skilli/statusów/UI oraz editor
smoke. Każdy exit 0 i `failures:[]`; skan logów bez `SCRIPT ERROR`, `Parse Error`, wycieków ObjectDB
i zasobów. Przywróć wyłącznie automatyczne zmiany `assets/**/*.import`.

- [ ] **Step 7: Commit**

Commit: `test: verify expedition artifacts and isolation`.

---

## Bramka zakończenia

Etap jest ukończony, gdy gracz może w hubie wyposażyć dowolne cztery z sześciu artefaktów, zobaczyć
aktywację setu 2/3 lub 3/3, rozpocząć wyprawę, użyć transformacyjnych efektów na prawdziwej arenie,
zamknąć i wznowić tę samą sesję z identycznym loadoutem oraz wrócić do roguelite bez jakiejkolwiek
zmiany jego zapisu lub buildu. Następny plan obejmuje zdobywanie przedmiotów: loot tables,
tymczasowe nagrody, Kodeks, duplikaty i pity counter.
