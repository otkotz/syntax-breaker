# Expedition Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dodać dostępny z menu, grywalny fundament osobnego trybu Expedition: trwały profil, deterministyczny graf pięciu pokojów, wybór trasy, walkę na istniejącej arenie oraz bezpieczne wznowienie aktywnej wyprawy.

**Architecture:** Nowy autoload `ExpeditionManager` jest jedynym właścicielem profilu i aktywnej sesji; nie zapisuje niczego w `RunManager`. Czysty `DungeonGenerator` tworzy serializowalny `DungeonLayout` na podstawie seeda, a `ExpeditionGameManager` przekłada wybrany pokój walki na istniejące `Arena` i `StageData`. Programowe ekrany `ExpeditionHub` i `ExpeditionMapUI` korzystają wyłącznie z publicznego API managera.

**Tech Stack:** Godot 4.6, GDScript, sceny `.tscn`, zasoby `.tres`, istniejący natywny wzorzec testów headless.

**Spec:** `docs/superpowers/specs/2026-10-14-expedition-rpg-mode-design.md`

## Global Constraints

- Tryb Expedition ma osobny zapis, ekonomię i stan od istniejącego roguelite.
- Pierwszy etap obejmuje tylko Burning Grounds i jedną postać.
- Generator składa graf z logicznych modułów pokojów; nie generuje dowolnej geometrii.
- Każdy układ ma legalną trasę od startu do bossa i przynajmniej jedno znaczące rozwidlenie.
- Aktywna sesja zapisuje seed, graf, aktualny pokój, ukończone pokoje i stan HP.
- Interfejs pozostaje mobile-first dla viewportu 1080×1920.
- Ten plan nie dodaje jeszcze artefaktów, dropów, XP, planszy rozwoju ani endgame'u.

## Review Focus

- Uszkodzony lub niekompletny JSON profilu ma utworzyć bezpieczny profil domyślny bez wpływu na zapis roguelite; test przypisano do Task 2.
- Ten sam seed ma tworzyć identyczny graf, a różne seedy nie mogą korzystać ze wspólnego stanu RNG; test przypisano do Task 1.
- Próba wejścia do nieosiągalnego albo już ukończonego pokoju ma zostać odrzucona bez zmiany sesji; test przypisano do Task 3.
- Ponowne rozliczenie tego samego ukończenia pokoju nie może dwa razy przesunąć postępu; test przypisano do Task 3.
- Jednoczesny zapis roguelite i Expedition musi używać różnych ścieżek i czyszczenie jednego nie może usuwać drugiego; test przypisano do Task 6.

---

## Mapa plików

### Nowe pliki

- `scripts/expedition/dungeon_room_data.gd` — typ i serializacja pojedynczego pokoju.
- `scripts/expedition/dungeon_layout.gd` — graf pokojów, osiągalność i serializacja.
- `scripts/expedition/dungeon_generator.gd` — deterministyczne tworzenie pierwszego układu.
- `scripts/expedition/expedition_profile.gd` — trwały stan profilu i walidacja danych.
- `scripts/expedition/expedition_session.gd` — stan aktywnej wyprawy i przejścia między pokojami.
- `scripts/autoloads/expedition_manager.gd` — zapis profilu/sesji i publiczne API trybu.
- `scripts/expedition/expedition_game_manager.gd` — orkiestracja huba, mapy i istniejącej areny.
- `scripts/ui/expedition_hub.gd` — ekran rozpoczęcia/wznowienia wyprawy.
- `scripts/ui/expedition_map.gd` — wybór osiągalnego pokoju.
- `scenes/main/expedition_game_manager.tscn` — korzeń trybu Expedition.
- `scenes/ui/expedition_hub.tscn` — scena huba.
- `scenes/ui/expedition_map.tscn` — scena mapy.
- `tests/expedition_generator_native.gd` i `.tscn` — generator i graf.
- `tests/expedition_profile_native.gd` i `.tscn` — profil oraz odporność zapisu.
- `tests/expedition_session_native.gd` i `.tscn` — reguły sesji.
- `tests/expedition_flow_native.gd` i `.tscn` — pełny przepływ UI/walka/save.

### Modyfikowane pliki

- `project.godot` — rejestracja autoloadu `ExpeditionManager`.
- `scripts/ui/main_menu.gd` — sygnał i przycisk wejścia do Expedition.
- `scripts/main/main.gd` — utworzenie i zamknięcie osobnego managera trybu.
- `docs/design-overview.md` — oznaczenie fundamentu Expedition jako prototypu, bez deklarowania gotowego RPG.

---

### Task 1: Deterministyczny graf lochu

**Files:**
- Create: `scripts/expedition/dungeon_room_data.gd`
- Create: `scripts/expedition/dungeon_layout.gd`
- Create: `scripts/expedition/dungeon_generator.gd`
- Create: `tests/expedition_generator_native.gd`
- Create: `tests/expedition_generator_native.tscn`

**Interfaces:**
- Consumes: wyłącznie `RandomNumberGenerator` z Godot.
- Produces: `DungeonGenerator.generate(seed_value: int, region_id: String) -> DungeonLayout`; `DungeonLayout.get_available_room_ids() -> Array[String]`; `DungeonLayout.serialize() -> Dictionary`; `DungeonLayout.deserialize(data: Dictionary) -> DungeonLayout`.

- [ ] **Step 1: Dodać test, który opisuje cały kontrakt generatora**

```gdscript
extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var first := DungeonGenerator.generate(20261014, "burning_grounds")
	var repeated := DungeonGenerator.generate(20261014, "burning_grounds")
	var other := DungeonGenerator.generate(20261015, "burning_grounds")
	check(first.serialize() == repeated.serialize(), "Same seed reproduces identical layout")
	check(first.serialize() != other.serialize(), "Different seed changes room assignment")
	check(first.rooms.size() == 5, "Prototype contains five rooms")
	check(first.start_room_id == "room_0" and first.boss_room_id == "room_4", "Start and boss are stable")
	check(first.has_path(first.start_room_id, first.boss_room_id), "Boss is reachable")
	check(first.get_outgoing("room_0").size() == 2, "Start presents a route choice")
	var restored := DungeonLayout.deserialize(first.serialize())
	check(restored.serialize() == first.serialize(), "Layout roundtrip preserves graph")
	var global_before := randf()
	DungeonGenerator.generate(44, "burning_grounds")
	var global_after := randf()
	seed(1)
	var expected_before := randf()
	var expected_after := randf()
	check(global_before != global_after or expected_before != expected_after, "Generator call completed without an exception")
	print(JSON.stringify({"failures": failures, "rooms": first.rooms.size()}))
	get_tree().quit(0 if failures.is_empty() else 1)
```

Test sceny:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/expedition_generator_native.gd" id="1"]

[node name="ExpeditionGeneratorTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Uruchomić test i potwierdzić brak klas**

Run:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_generator_native.tscn --log-file .godot/expedition_generator_native.log
```

Expected: kod różny od 0 i błąd parsera dla `DungeonGenerator`.

- [ ] **Step 3: Zaimplementować dane pokoju i graf**

`dungeon_room_data.gd`:

```gdscript
class_name DungeonRoomData
extends RefCounted

enum Type { START, COMBAT, ELITE, EVENT, TREASURE, BOSS }

var id: String = ""
var depth: int = 0
var type: Type = Type.COMBAT
var region_id: String = ""

func serialize() -> Dictionary:
	return {"id": id, "depth": depth, "type": int(type), "region_id": region_id}

static func deserialize(data: Dictionary) -> DungeonRoomData:
	var room := DungeonRoomData.new()
	room.id = str(data.get("id", ""))
	room.depth = maxi(0, int(data.get("depth", 0)))
	room.type = clampi(int(data.get("type", Type.COMBAT)), Type.START, Type.BOSS) as Type
	room.region_id = str(data.get("region_id", ""))
	return room
```

`dungeon_layout.gd` ma przechowywać `rooms: Dictionary`, `edges: Dictionary`, `start_room_id`,
`boss_room_id`, `current_room_id` i `completed_room_ids`. `has_path()` używa lokalnego stosu oraz
zbioru odwiedzonych ID; `deserialize()` pomija krawędzie do nieznanych pokojów.

- [ ] **Step 4: Zaimplementować generator bez globalnego RNG**

```gdscript
class_name DungeonGenerator
extends RefCounted

static func generate(seed_value: int, region_id: String) -> DungeonLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var layout := DungeonLayout.new()
	layout.seed_value = seed_value
	layout.region_id = region_id
	var types: Array[DungeonRoomData.Type] = [
		DungeonRoomData.Type.START,
		DungeonRoomData.Type.COMBAT,
		DungeonRoomData.Type.ELITE if rng.randf() < 0.5 else DungeonRoomData.Type.TREASURE,
		DungeonRoomData.Type.COMBAT if rng.randf() < 0.5 else DungeonRoomData.Type.EVENT,
		DungeonRoomData.Type.BOSS,
	]
	for index in 5:
		var room := DungeonRoomData.new()
		room.id = "room_%d" % index
		room.depth = index
		room.type = types[index]
		room.region_id = region_id
		layout.rooms[room.id] = room
	layout.edges = {
		"room_0": ["room_1", "room_2"],
		"room_1": ["room_3"],
		"room_2": ["room_3"],
		"room_3": ["room_4"],
		"room_4": [],
	}
	layout.start_room_id = "room_0"
	layout.boss_room_id = "room_4"
	layout.current_room_id = "room_0"
	layout.completed_room_ids = ["room_0"]
	return layout
```

- [ ] **Step 5: Poprawić test izolacji RNG i uruchomić cały kontrakt**

Przed wywołaniem generatora ustaw `seed(90210)`, pobierz jedną wartość, wywołaj generator, pobierz
drugą wartość, a następnie powtórz sekwencję bez wywołania generatora. Obie pary mają być równe.

Run: polecenie ze Step 2.  
Expected: kod 0 i JSON z `"failures":[]`.

- [ ] **Step 6: Commit**

```powershell
git add scripts/expedition/dungeon_room_data.gd scripts/expedition/dungeon_layout.gd scripts/expedition/dungeon_generator.gd tests/expedition_generator_native.gd tests/expedition_generator_native.tscn
git commit -m "feat: add deterministic expedition dungeon layout"
```

---

### Task 2: Trwały profil Expedition i bezpieczny zapis

**Files:**
- Create: `scripts/expedition/expedition_profile.gd`
- Create: `scripts/autoloads/expedition_manager.gd`
- Create: `tests/expedition_profile_native.gd`
- Create: `tests/expedition_profile_native.tscn`
- Modify: `project.godot`

**Interfaces:**
- Consumes: `DungeonLayout.serialize()` z Task 1.
- Produces: `ExpeditionProfile.from_dict(data: Dictionary) -> ExpeditionProfile`; `ExpeditionManager.load_profile() -> bool`; `save_profile() -> bool`; `start_new_profile() -> void`; `clear_active_session() -> void`.

- [ ] **Step 1: Napisać test profilu, uszkodzonego JSON i separacji ścieżek**

Test ustawia:

```gdscript
ExpeditionManager.profile_path = "res://.godot/expedition_profile_test.json"
ExpeditionManager.session_path = "res://.godot/expedition_session_test.json"
ExpeditionManager.start_new_profile()
ExpeditionManager.profile.level = 7
check(ExpeditionManager.save_profile(), "Profile saves")
ExpeditionManager.profile = null
check(ExpeditionManager.load_profile(), "Profile loads")
check(ExpeditionManager.profile.level == 7, "Level survives roundtrip")
var broken := FileAccess.open(ExpeditionManager.profile_path, FileAccess.WRITE)
broken.store_string("{broken")
broken.close()
check(not ExpeditionManager.load_profile(), "Malformed JSON reports failure")
check(ExpeditionManager.profile != null and ExpeditionManager.profile.level == 1, "Malformed JSON falls back safely")
check(ExpeditionManager.profile_path != RunManager.save_path, "Expedition never aliases roguelite save")
```

Test ma również przekazać `{"schema_version": 999}` i oczekiwać bezpiecznego profilu poziomu 1.

- [ ] **Step 2: Uruchomić test i potwierdzić brak autoloadu**

Run:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_profile_native.tscn --log-file .godot/expedition_profile_native.log
```

Expected: niepowodzenie, bo `ExpeditionManager` nie jest zarejestrowany.

- [ ] **Step 3: Dodać model profilu z wersją schematu**

```gdscript
class_name ExpeditionProfile
extends RefCounted

const SCHEMA_VERSION := 1

var character_id: String = "breaker"
var level: int = 1
var experience: int = 0
var unlocked_regions: Array[String] = ["burning_grounds"]

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"character_id": character_id,
		"level": level,
		"experience": experience,
		"unlocked_regions": unlocked_regions,
	}

static func from_dict(data: Dictionary) -> ExpeditionProfile:
	var profile := ExpeditionProfile.new()
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return profile
	profile.character_id = str(data.get("character_id", "breaker"))
	profile.level = maxi(1, int(data.get("level", 1)))
	profile.experience = maxi(0, int(data.get("experience", 0)))
	profile.unlocked_regions.assign(data.get("unlocked_regions", ["burning_grounds"]))
	if not profile.unlocked_regions.has("burning_grounds"):
		profile.unlocked_regions.append("burning_grounds")
	return profile
```

- [ ] **Step 4: Dodać manager i atomowy helper zapisu**

`ExpeditionManager` rozszerza `Node`, ma domyślne ścieżki `user://expedition_profile.json` oraz
`user://active_expedition.json`. `_write_json_atomic(path, data)` zapisuje do `path + ".tmp"`,
zamyka plik, usuwa poprzedni `path` i zmienia nazwę pliku tymczasowego w tym samym katalogu.
Każdy błąd zwraca `false` i nie zeruje obiektu profilu w pamięci.

Publiczny odczyt ma ten kontrakt:

```gdscript
func load_profile() -> bool:
	profile = ExpeditionProfile.new()
	if not FileAccess.file_exists(profile_path):
		return false
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		return false
	var parsed := JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var version := int((parsed as Dictionary).get("schema_version", -1))
	if version != ExpeditionProfile.SCHEMA_VERSION:
		return false
	profile = ExpeditionProfile.from_dict(parsed)
	return true
```

Zarejestruj w `project.godot`:

```ini
ExpeditionManager="*res://scripts/autoloads/expedition_manager.gd"
```

- [ ] **Step 5: Uruchomić test profilu**

Run: polecenie ze Step 2.  
Expected: kod 0, brak `SCRIPT ERROR`, `"failures":[]`.

- [ ] **Step 6: Commit**

```powershell
git add project.godot scripts/expedition/expedition_profile.gd scripts/autoloads/expedition_manager.gd tests/expedition_profile_native.gd tests/expedition_profile_native.tscn
git commit -m "feat: add isolated expedition profile storage"
```

---

### Task 3: Sesja wyprawy, nawigacja i idempotentne ukończenie pokoju

**Files:**
- Create: `scripts/expedition/expedition_session.gd`
- Create: `tests/expedition_session_native.gd`
- Create: `tests/expedition_session_native.tscn`
- Modify: `scripts/autoloads/expedition_manager.gd`

**Interfaces:**
- Consumes: `DungeonGenerator.generate()` i `DungeonLayout` z Task 1; atomowy zapis z Task 2.
- Produces: `ExpeditionSession.create(seed_value: int, region_id: String) -> ExpeditionSession`; `can_enter(room_id: String) -> bool`; `enter_room(room_id: String) -> bool`; `complete_current_room(completion_id: String, hp: float, max_hp: float) -> bool`; `ExpeditionManager.start_expedition(seed_value: int, region_id: String) -> bool`; `save_session() -> bool`; `load_session() -> bool`.

- [ ] **Step 1: Napisać test reguł przejścia i roundtripu**

```gdscript
var session := ExpeditionSession.create(20261014, "burning_grounds")
check(session.get_available_room_ids().size() == 2, "Start exposes two routes")
check(not session.enter_room("room_4"), "Locked boss cannot be entered")
check(session.current_room_id == "room_0", "Rejected entry does not mutate current room")
check(session.enter_room("room_1"), "Reachable room can be entered")
check(session.complete_current_room("clear-room-1", 72.0, 100.0), "Room completes once")
check(not session.complete_current_room("clear-room-1", 10.0, 100.0), "Duplicate completion is ignored")
check(session.current_hp == 72.0, "Duplicate completion cannot overwrite state")
check(not session.enter_room("room_1"), "Completed room cannot be entered again")
var restored := ExpeditionSession.from_dict(session.to_dict())
check(restored.to_dict() == session.to_dict(), "Session survives roundtrip")
```

Dodaj również przypadki: nieznane ID pokoju, ujemne HP, `max_hp` równe zero oraz dane sesji z
grafem bez osiągalnego bossa. Niepoprawne dane mają zwrócić `null` z `from_dict()`.

- [ ] **Step 2: Uruchomić test i potwierdzić brak klasy sesji**

Run:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_session_native.tscn --log-file .godot/expedition_session_native.log
```

Expected: parser nie znajduje `ExpeditionSession`.

- [ ] **Step 3: Zaimplementować sesję jako czysty model**

Model zawiera `SCHEMA_VERSION = 1`, `seed_value`, `region_id`, `layout`, `current_room_id`,
`completed_room_ids`, `completion_ids`, `current_hp = 100.0`, `max_hp = 100.0` i `status` z
wartościami `active`, `victory`, `failed`.

Kluczowa walidacja:

```gdscript
func can_enter(room_id: String) -> bool:
	return status == "active" \
		and layout.rooms.has(room_id) \
		and not completed_room_ids.has(room_id) \
		and get_available_room_ids().has(room_id)

func complete_current_room(completion_id: String, hp: float, hp_max: float) -> bool:
	if completion_id.is_empty() or completion_ids.has(completion_id):
		return false
	if current_room_id.is_empty() or completed_room_ids.has(current_room_id):
		return false
	completion_ids.append(completion_id)
	completed_room_ids.append(current_room_id)
	max_hp = maxf(1.0, hp_max)
	current_hp = clampf(hp, 0.0, max_hp)
	if current_room_id == layout.boss_room_id:
		status = "victory"
	return true
```

Startowy pokój jest oznaczony jako ukończony podczas `create()`, a `current_room_id` wskazuje start.

- [ ] **Step 4: Rozszerzyć manager o start, zapis, odczyt i czyszczenie sesji**

`start_expedition()` akceptuje tylko region odblokowany w profilu, tworzy sesję, zapisuje ją i
zwraca wynik zapisu. `load_session()` pozostawia `session = null` przy niezgodnej wersji, martwym
grafie lub błędnym JSON. `clear_active_session()` usuwa wyłącznie `session_path` i plik `.tmp`.

- [ ] **Step 5: Uruchomić test sesji i ponownie test profilu**

Run: test z Task 3, potem test z Task 2.  
Expected: oba kończą się kodem 0.

- [ ] **Step 6: Commit**

```powershell
git add scripts/expedition/expedition_session.gd scripts/autoloads/expedition_manager.gd tests/expedition_session_native.gd tests/expedition_session_native.tscn
git commit -m "feat: add resumable expedition session state"
```

---

### Task 4: Manager gry Expedition i walka w pokojach

**Files:**
- Create: `scripts/expedition/expedition_game_manager.gd`
- Create: `scenes/main/expedition_game_manager.tscn`
- Create: `tests/expedition_flow_native.gd`
- Create: `tests/expedition_flow_native.tscn`

**Interfaces:**
- Consumes: `ExpeditionManager.session`, `Arena.start_stage(stage_number, skill_instances, stage_data)` oraz istniejący Fireball.
- Produces: sygnały `return_to_main_menu`; metody `open_hub()`, `start_new_expedition(seed_value)`, `enter_room(room_id)`, `abandon_expedition()`.

- [ ] **Step 1: Napisać integracyjny test wejścia do pokoju walki**

Test tworzy `ExpeditionGameManager`, ustawia testowe ścieżki zapisu, wywołuje
`start_new_expedition(20261014)`, wybiera osiągalny pokój `COMBAT` i sprawdza:

```gdscript
check(game.state == ExpeditionGameManager.State.COMBAT, "Combat room opens arena")
check(game.arena != null, "Existing arena is reused")
check(game.skill_instances.size() == 1 and game.skill_instances[0].base.id == "fireball", "Prototype has stable starter skill")
game.arena._on_all_waves_cleared()
check(ExpeditionManager.session.completed_room_ids.has(chosen_room_id), "Arena clear completes room")
check(game.state == ExpeditionGameManager.State.MAP, "Clear returns to expedition map")
check(ExpeditionManager.has_saved_session(), "Clear checkpoints session")
```

Drugi przypadek wywołuje śmierć gracza i sprawdza stan `failed`, brak utraty profilu i powrót do huba.

- [ ] **Step 2: Uruchomić test i potwierdzić brak managera**

Run:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_flow_native.tscn --log-file .godot/expedition_flow_native.log
```

Expected: parser nie znajduje `ExpeditionGameManager`.

- [ ] **Step 3: Dodać manager stanów bez zależności od `RunManager`**

```gdscript
class_name ExpeditionGameManager
extends Node

enum State { HUB, MAP, COMBAT }

signal return_to_main_menu

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const FIREBALL := preload("res://resources/skills/fireball.tres")

var state: State = State.HUB
var arena: Arena
var skill_instances: Array[SkillInstance] = []
var _active_room_id: String = ""
```

`start_new_expedition()` tworzy profil, jeśli go nie ma, uruchamia sesję dla `burning_grounds`,
tworzy `SkillInstance.new(FIREBALL)` i pokazuje mapę. `enter_room()` najpierw wywołuje
`session.enter_room(room_id)`, następnie zapisuje sesję i dla `COMBAT`, `ELITE` lub `BOSS`
uruchamia arenę. Pozostałe typy w tym planie są rozliczane jako natychmiastowe, jawnie opisane
prototype reward rooms i wracają do mapy.

- [ ] **Step 4: Przetłumaczyć pokój na istniejący `StageData`**

```gdscript
func _make_stage_data(room: DungeonRoomData) -> StageData:
	var stage := StageData.new()
	stage.depth = room.depth + 1
	stage.region = load("res://resources/regions/%s.tres" % room.region_id) as RegionResource
	match room.type:
		DungeonRoomData.Type.ELITE: stage.type = StageData.Type.ELITE
		DungeonRoomData.Type.BOSS: stage.type = StageData.Type.BOSS
		_: stage.type = StageData.Type.COMBAT
	return stage
```

Przed `Arena.start_stage()` manager kopiuje HP sesji do `RunManager.current_hp/max_hp` tylko jako
adapter dla istniejących scen gracza. Nie wywołuje `RunManager.start_run()`, nie przyznaje złota i
po walce kopiuje HP z powrotem do sesji. Ten tymczasowy adapter zostanie usunięty w późniejszym
planie wydzielenia wspólnego `CombatContext`.

- [ ] **Step 5: Obsłużyć ukończenie, zwycięstwo i śmierć**

Ukończenie używa unikalnego `completion_id = "%s:%s" % [session.session_id, room_id]`. Boss ustawia
`victory`, czyści aktywny zapis dopiero po zapisaniu profilu i wraca do huba. Śmierć ustawia
`failed`, czyści aktywną sesję, zachowuje profil i pokazuje hub z komunikatem wyniku.

- [ ] **Step 6: Uruchomić test przepływu**

Run: polecenie ze Step 2.  
Expected: kod 0, brak zapisu złota/roguelite i `"failures":[]`.

- [ ] **Step 7: Commit**

```powershell
git add scripts/expedition/expedition_game_manager.gd scenes/main/expedition_game_manager.tscn tests/expedition_flow_native.gd tests/expedition_flow_native.tscn
git commit -m "feat: run expedition combat rooms through arena"
```

---

### Task 5: Hub, mapa dotykowa i wejście z menu głównego

**Files:**
- Create: `scripts/ui/expedition_hub.gd`
- Create: `scripts/ui/expedition_map.gd`
- Create: `scenes/ui/expedition_hub.tscn`
- Create: `scenes/ui/expedition_map.tscn`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scripts/main/main.gd`
- Modify: `tests/expedition_flow_native.gd`

**Interfaces:**
- Consumes: publiczne API `ExpeditionGameManager` z Task 4.
- Produces: `MainMenu.expedition_pressed`; `ExpeditionHub.new_expedition_pressed`, `resume_pressed`, `back_pressed`; `ExpeditionMapUI.room_chosen(room_id)`.

- [ ] **Step 1: Rozszerzyć test przepływu o rzeczywiste przyciski**

Test instancjonuje `main.tscn`, pomija animację splash przez bezpośrednie pokazanie menu i sprawdza,
że przycisk o `name == "ExpeditionButton"` ma co najmniej `Vector2(600, 88)`. Emisja `pressed`
ukrywa `MainMenu`, tworzy `ExpeditionGameManager` i pokazuje hub. Przycisk nowej wyprawy pokazuje
mapę, a każdy dostępny pokój ma cały klikalny kafel o wysokości co najmniej 96 px.

- [ ] **Step 2: Uruchomić test i potwierdzić brak przycisku**

Run: test przepływu z Task 4.  
Expected: FAIL z komunikatem testu o `ExpeditionButton`.

- [ ] **Step 3: Zbudować prosty hub programowo**

Hub pokazuje tytuł `EXPEDITION`, poziom profilu, przycisk `NEW EXPEDITION`, warunkowy `RESUME`
oraz `BACK`. `RESUME` jest widoczny tylko gdy `ExpeditionManager.has_saved_session()` zwraca true.
Przyciski używają istniejących kolorów `UITheme` i wysokości minimum 96 px.

- [ ] **Step 4: Zbudować mapę jako pięć dużych kafli**

`setup(session: ExpeditionSession)` czyści kontener i tworzy kafel dla każdego pokoju. Kafel pokazuje
typ, głębokość i stan `COMPLETED`, `AVAILABLE` albo `LOCKED`; wyłącznie `AVAILABLE` emituje
`room_chosen`. Połączenia mogą być tekstowe w tym etapie (`START → A/B → MERGE → BOSS`), ponieważ
celem jest sprawdzenie przepływu, nie finalna grafika mapy.

- [ ] **Step 5: Dodać wejście Expedition do głównego menu**

W `MainMenu` dodaj `signal expedition_pressed` i przycisk `EXPEDITION RPG` pod głównym przyciskiem
startu. W `Main` trzymaj `_expedition_game: ExpeditionGameManager`; po sygnale ukryj menu,
instancjonuj `scenes/main/expedition_game_manager.tscn`, podłącz `return_to_main_menu`, a przy
powrocie usuń manager i pokaż menu. Istniejący `GameManager` roguelite pozostaje nietknięty.

- [ ] **Step 6: Połączyć hub i mapę z managerem**

`ExpeditionGameManager.open_hub()` instancjonuje hub, a `show_map()` instancjonuje mapę i przekazuje
aktywną sesję. Manager jest jedyną klasą, która przełącza ekrany; UI tylko emituje sygnały.

- [ ] **Step 7: Uruchomić test przepływu i dotyku**

Run: test przepływu z Task 4.  
Expected: kod 0, pełna ścieżka menu → hub → mapa → walka → mapa.

- [ ] **Step 8: Commit**

```powershell
git add scripts/ui/expedition_hub.gd scripts/ui/expedition_map.gd scenes/ui/expedition_hub.tscn scenes/ui/expedition_map.tscn scripts/expedition/expedition_game_manager.gd scripts/ui/main_menu.gd scripts/main/main.gd tests/expedition_flow_native.gd
git commit -m "feat: expose expedition prototype from main menu"
```

---

### Task 6: Wznowienie, izolacja zapisów i weryfikacja całego fundamentu

**Files:**
- Modify: `tests/expedition_flow_native.gd`
- Modify: `tests/run_integrity.gd`
- Modify: `docs/design-overview.md`

**Interfaces:**
- Consumes: pełne publiczne API Tasks 1–5.
- Produces: zweryfikowany pionowy fundament gotowy pod kolejny plan artefaktów i lootu.

- [ ] **Step 1: Dodać test wznowienia w połowie wyprawy**

Test startuje wyprawę, kończy jeden pokój z HP 63/100, zapisuje sesję, usuwa manager sceny,
zeruje obiekt sesji, ponownie ładuje zapis i sprawdza:

```gdscript
check(ExpeditionManager.load_session(), "Active expedition resumes")
check(ExpeditionManager.session.current_hp == 63.0, "Resume preserves health")
check(ExpeditionManager.session.completed_room_ids.has(cleared_room_id), "Resume preserves cleared room")
check(ExpeditionManager.session.layout.seed_value == 20261014, "Resume preserves seed")
check(not ExpeditionManager.session.can_enter(cleared_room_id), "Resume cannot replay cleared room")
```

- [ ] **Step 2: Dodać regresję niezależnych plików zapisu**

W `run_integrity.gd` ustaw testowe ścieżki obu trybów, zapisz roguelite oraz Expedition, wyczyść
aktywną Expedition i sprawdź, że zapis roguelite nadal istnieje. Następnie wyczyść roguelite i
sprawdź, że profil Expedition nadal istnieje.

- [ ] **Step 3: Uruchomić test przed ewentualnymi poprawkami**

Run:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_flow_native.tscn --log-file .godot/expedition_flow_native.log
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/run_integrity.tscn --log-file .godot/run_integrity.log
```

Expected: oba testy kończą się kodem 0. Jeśli nowy test ujawni błąd, zmiana ma być ograniczona do
klasy będącej właścicielem naruszonego kontraktu.

- [ ] **Step 4: Uzupełnić dokumentację stanu funkcji**

W `docs/design-overview.md` dodać sekcję `Expedition prototype` z dokładnym zakresem: osobny profil,
pięciopokojowy layout Burning Grounds, istniejąca arena, Fireball jako stały starter i save/resume.
Jawnie zaznaczyć, że artefakty, XP, kampania trzech regionów i endgame nie są jeszcze wdrożone.

- [ ] **Step 5: Uruchomić pełny zestaw istotnych regresji**

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_generator_native.tscn --log-file .godot/expedition_generator_native.log
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_profile_native.tscn --log-file .godot/expedition_profile_native.log
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_session_native.tscn --log-file .godot/expedition_session_native.log
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/expedition_flow_native.tscn --log-file .godot/expedition_flow_native.log
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/run_integrity.tscn --log-file .godot/run_integrity.log
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/node_routes_native.tscn --log-file .godot/node_routes_native.log
```

Expected: sześć kodów 0, wszystkie raporty z `"failures":[]`, brak `SCRIPT ERROR`, `ObjectDB instances leaked` i `resources still in use` w logach.

- [ ] **Step 6: Sprawdzić projekt w trybie edytora/headless**

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --editor --path . --quit --log-file .godot/expedition_editor_smoke.log
```

Expected: kod 0 i brak błędów parsera lub brakujących zasobów.

- [ ] **Step 7: Commit**

```powershell
git add tests/expedition_flow_native.gd tests/run_integrity.gd docs/design-overview.md
git commit -m "test: verify expedition resume and save isolation"
```

---

## Bramka zakończenia etapu

Etap jest ukończony tylko wtedy, gdy użytkownik może z menu wejść do Expedition, rozpocząć wyprawę
w Burning Grounds, wybrać jedną z dwóch tras, ukończyć pokój na istniejącej arenie, zamknąć grę,
wznowić ten sam seed i stan HP, dojść do bossa oraz wrócić do huba po zwycięstwie. Zapis roguelite
nie może zostać zmodyfikowany ani usunięty przez tę ścieżkę.

Kolejny plan po tej bramce obejmie `ArtifactResource`, wyposażanie czterech artefaktów, zachowania,
jeden zestaw 2/3–3/3, jawne tabele dropu, Kodeks i ochronę przed pechem.
