# Syntax Breaker — artefakty Expedition

**Data:** 2026-10-15  
**Status:** projekt zatwierdzony koncepcyjnie; dokument do przeglądu przed planem wdrożenia

## Cel

Dodać do trybu Expedition pierwszy trwały system budowania postaci: cztery sloty artefaktów,
sześć rozpoznawalnych przedmiotów oraz trzyczęściowy zestaw Burning Grounds. Artefakty mają
zmieniać zachowanie skilli i przebieg walki w stylu Path of Exile, Binding of Isaac i Hero Siege,
a nie sprowadzać się do małych premii procentowych.

Ten etap potwierdza pętlę „zmiana loadoutu → widocznie inna walka”. Zdobywanie przedmiotów,
Kodeks, duplikaty, ochrona przed pechem, XP i plansza rozwoju pozostają w kolejnych pionach.

## Kryteria sukcesu

- Profil Expedition przechowuje kolekcję artefaktów oraz cztery uporządkowane sloty wyposażenia.
- Gracz może zmieniać loadout w mobilnym hubie, ale nie podczas aktywnej wyprawy.
- Każdy z sześciu artefaktów wyraźnie zmienia decyzje lub zachowanie skilla podczas walki.
- Wyposażenie dwóch i trzech elementów zestawu aktywuje odpowiednio bonus 2/3 i 3/3.
- Aktywna wyprawa używa zamrożonej kopii loadoutu, więc wznowienie odtwarza te same efekty.
- Artefakty nie odczytują ani nie zapisują trwałego stanu roguelite.
- Profil schematu 1 migruje bez utraty poziomu, doświadczenia i odblokowanych regionów.

## Zakres

Etap obejmuje:

- `ArtifactResource` z identyfikatorem, tekstami, ikoną, źródłem regionu, kluczem zachowania,
  parametrami zachowania oraz opcjonalnym `set_id`;
- kolekcję posiadanych artefaktów w `ExpeditionProfile`;
- cztery sloty wyposażenia bez duplikowania tego samego artefaktu;
- migawkę wyposażonych ID w `ExpeditionSession`;
- `ArtifactRuntime` tworzący aktywne zachowania dla bieżącej walki;
- rejestr zachowań bez zależności zasobów danych od konkretnych klas scen;
- zestaw `Covenant of Embers` z progami 2/3 i 3/3;
- trzy artefakty niezależne;
- ekran kolekcji i loadoutu w hubie, zaprojektowany mobile-first;
- efekty wizualne i krótkie komunikaty niezbędne do zrozumienia aktywacji;
- testy jednostkowe i integracyjne rzeczywistej areny.

Poza zakresem pozostają:

- tabele dropu i nagrody pokojów;
- Kodeks oraz prezentacja źródeł dropu;
- duplikaty, materiały i rozkładanie;
- pity counter i chase item;
- losowe afiksy, rzadkości i wartości przedmiotów;
- XP, poziomowanie i plansza rozwoju;
- nowe ekspedycje, bossowie oraz endgame;
- zmiana artefaktów podczas aktywnej wyprawy.

## Model danych

### ArtifactResource

`ArtifactResource` jest stałym zasobem danych i zawiera:

- `id: String` — stabilny identyfikator zapisu;
- `display_name: String` i `description: String`;
- `icon: Texture2D`;
- `region_id: String`;
- `behavior_key: String`;
- `behavior_parameters: Dictionary`;
- `set_id: String`, pusty dla artefaktów niezależnych;
- `set_piece_name: String` dla elementów zestawu.

Parametry przechowują wyłącznie dane balansowe. Wybór zachowania odbywa się przez jawny rejestr,
bez ładowania ścieżek klas zapisanych w zasobach.

### ExpeditionProfile — schema 2

Profil otrzymuje:

- `owned_artifact_ids: Array[String]`;
- `equipped_artifact_ids: Array[String]` o stałej długości czterech, z pustym stringiem dla
  wolnego slotu.

Migracja schema 1 → 2 zachowuje wszystkie dotychczasowe pola, tworzy pustą kolekcję i cztery
puste sloty. Nieznane ID są pomijane przy budowaniu runtime, ale pozostają w zapisie do czasu
wdrożenia reguły kompensacji w pionie lootu. Profil nie może wyposażyć artefaktu, którego nie
posiada, tego samego ID w dwóch slotach ani więcej niż czterech przedmiotów.

Na potrzeby prototypu nowe profile otrzymują wszystkie sześć artefaktów. Migracja istniejącego
profilu również odblokowuje komplet prototypowy, ponieważ system dropu nie istnieje jeszcze.
Ta jednorazowa reguła zostanie zastąpiona startową kolekcją, gdy powstanie pion lootu.

### ExpeditionSession — schema 2

Przy rozpoczęciu wyprawy sesja kopiuje `equipped_artifact_ids` do `artifact_loadout_ids`.
Wznowienie korzysta wyłącznie z migawki sesji, a nie z aktualnego profilu. Sesja schema 1 migruje
z pustym loadoutem, dzięki czemu starsze aktywne wyprawy można bezpiecznie dokończyć.

## Architektura zachowań

Wybrane podejście to małe klasy zachowań podłączane przez jawne hooki. Alternatywy odrzucone:
logika w `ExpeditionGameManager` stworzyłaby monolit, a uniwersalny język efektów jest zbyt kosztowny
dla sześciu przedmiotów i utrudnia nietypowe transformacje.

### ArtifactRegistry

`ArtifactRegistry` mapuje `behavior_key` na fabrykę zachowania. Nie przechowuje stanu walki.
Nieznany klucz zwraca zachowanie puste i raportuje ostrzeżenie diagnostyczne bez blokowania profilu.

### ArtifactRuntime

Runtime powstaje dla jednej walki z zamrożonego loadoutu sesji. Odpowiada za:

- utworzenie zachowań sześciu artefaktów i aktywnych progów zestawu;
- przekazanie im ograniczonego kontekstu walki;
- podłączenie i odłączenie sygnałów;
- zastosowanie modyfikacji do `SkillInstance` przed rozpoczęciem etapu;
- wyczyszczenie efektów po zwycięstwie, śmierci, porzuceniu lub usunięciu managera.

Zachowania nie zapisują profilu i nie komunikują się bezpośrednio z `RunManager`. Adapter istniejącej
areny może używać odizolowanego stanu `RunManager`, ale jedynym źródłem loadoutu jest sesja.

### Combat hooks

Pierwszy kontrakt udostępnia wyłącznie potrzebne punkty zaczepienia:

- `before_skill_recompute(skill)`;
- `on_skill_cast(skill, cast_id)`;
- `on_projectile_hit(hit_context)`;
- `on_status_applied(status_context)`;
- `on_enemy_killed(kill_context)`;
- `on_player_health_changed(health_context)`;
- `on_combat_ended()`.

Każdy kontekst zawiera stabilny identyfikator zdarzenia. Zachowania przechowują przetworzone ID,
jeżeli powtórna emisja mogłaby utworzyć dodatkowy pocisk, echo lub detonację. Hooki są neutralne
wobec trybu gry i później mogą stać się wspólną warstwą walki, ale ten etap podłącza je wyłącznie
do Expedition.

## Zawartość artefaktów

Wartości liczbowe są parametrami balansowymi i mogą zmieniać się bez migracji zapisu. Kontrakty
mechaniczne poniżej są stałe dla tego etapu.

### Covenant of Embers

#### Furnace Heart

- Każde trafienie skillem z tagiem `fire` nakłada dodatkowy stos podpalenia.
- Bezpośrednie obrażenia trafienia tego skilla są mnożone przez 0,8.
- Dodatkowy stos nie może sam wywołać kolejnego zastosowania zachowania.

#### Ashen Needle

- Pocisk trafiający podpalonego przeciwnika otrzymuje jedno dodatkowe przebicie.
- Po przejściu przez cel tworzy krótką ognistą smugę zadającą obrażenia w czasie.
- Jeden pocisk może utworzyć najwyżej jedną smugę z tego artefaktu.

#### Cinder Crown

- Śmierć podpalonego przeciwnika tworzy jeden samonaprowadzający żar.
- Żar wybiera najbliższego żywego wroga w ograniczonym promieniu i przenosi na niego najsilniejsze
  aktywne podpalenie zabitego celu.
- Żar nie może celować w tego samego przeciwnika i wygasa, jeśli nie ma legalnego celu.

### Bonus 2/3 — Kindling Engine

- Podpalenia zadające obrażenia mogą kumulować się do pięciu stosów na jednym przeciwniku.
- Każdy stos zachowuje własną siłę, źródło i pozostały czas.
- Odświeżenie nie duplikuje istniejącego stosu; najstarszy stos jest zastępowany dopiero po
  osiągnięciu limitu.

### Bonus 3/3 — Chain Conflagration

- Cel z pięcioma stosami otrzymuje znacznik `primed`.
- Następne bezpośrednie trafienie skillem ognia zużywa pięć stosów i wywołuje eksplozję obszarową.
- Eksplozja skaluje się z łączną pozostałą siłą zużytych podpaleń.
- Zabici eksplozją emitują żar zgodny z regułami Cinder Crown, ale łańcuch ma maksymalnie dwa
  pokolenia na pierwotną detonację.
- Boss otrzymuje obrażenia detonacji z limitem procentu maksymalnego HP; detonacja nie tworzy
  dodatkowych pokoleń bez zabójstwa.

## Artefakty niezależne

### Fractured Prism

- Pierwszy kontakt bazowego pocisku z przeciwnikiem tworzy dwa odłamki pod stałymi kątami.
- Każdy odłamek zadaje 55% obrażeń pocisku źródłowego.
- Odłamki dziedziczą tagi i dozwolone statusy, ale nie mogą ponownie uruchomić Prism.
- Efekt nie działa na pociski utworzone przez inne artefakty, jeśli ich kontekst ma flagę
  `secondary_artifact_projectile`.

### Echoing Hourglass

- Co trzeci zaakceptowany cast aktywnego skilla jest powtarzany po 0,35 sekundy.
- Echo nie płaci kosztu i nie przesuwa licznika, ale używa pozycji/celu zapamiętanego przy castcie.
- Bazowy cooldown wszystkich aktywnych skilli jest mnożony przez 1,2.
- Anulowany cast nie zwiększa licznika; echo jest kasowane po końcu walki.

### Bloodwritten Sigil

- Cast rozpoczęty przy co najmniej 90% maksymalnego HP zużywa 8% maksymalnego HP.
- Wzmocniony cast otrzymuje 35% więcej obrażeń i 30% większy obszar.
- Koszt nie może obniżyć HP poniżej 1 i nie jest obrażeniem, więc nie uruchamia efektów trafienia
  gracza ani śmierci.
- Jeśli koszt nie może zostać zapłacony, cast odbywa się normalnie bez premii.

## Zasady zestawów

`SetBonusResource` opisuje `set_id`, progi 2 i 3, teksty oraz klucze zachowań. `ArtifactRuntime`
liczy unikalne wyposażone elementy zestawu. Aktywacja progów jest kumulatywna: przy 3/3 działają
zarówno `Kindling Engine`, jak i `Chain Conflagration`.

UI pokazuje przy każdym elemencie:

- nazwę zestawu;
- stan `n/3`;
- posiadane i brakujące elementy;
- pełny opis efektu 2/3 oraz 3/3;
- wyraźne podświetlenie aktywnych progów.

## Interfejs kolekcji

Hub otrzymuje przycisk `ARTIFACTS`. Ekran ma dwa obszary:

- na górze lub z lewej — cztery duże sloty wyposażenia;
- poniżej lub z prawej — przewijana kolekcja kart.

Dotknięcie artefaktu wybiera go i pokazuje pełny opis, koszt oraz informacje o zestawie. Główny
przycisk `EQUIP` umieszcza przedmiot w wybranym wolnym slocie albo w slocie wskazanym przez gracza.
Dotknięcie zajętego slotu pozwala `UNEQUIP` lub `REPLACE`. Minimalna wysokość interaktywnych kart
i przycisków wynosi 88 px. Podczas aktywnej wyprawy ekran jest tylko do odczytu i wyjaśnia, że
loadout jest zablokowany do jej zakończenia lub porzucenia.

UI nie interpretuje mechaniki zachowań. Otrzymuje gotowe dane prezentacyjne z zasobów i stan
aktywacji setu z modelu loadoutu.

## Przepływ danych

1. Hub ładuje kolekcję oraz wyposażone ID z profilu.
2. Zmiana slotu przechodzi przez walidator loadoutu i atomowo zapisuje profil.
3. Start ekspedycji kopiuje cztery ID do sesji.
4. Wejście do pokoju walki buduje `ArtifactRuntime` z migawki sesji.
5. Runtime modyfikuje skille i reaguje na hooki areny.
6. Koniec walki usuwa wszystkie połączenia i stan tymczasowy zachowań.
7. Wznowienie sesji odbudowuje identyczny runtime z zapisanych ID.

## Obsługa błędów

- Nieznane ID artefaktu daje pusty slot runtime i ostrzeżenie, ale nie blokuje wyprawy.
- Nieznany klucz zachowania nie aktywuje efektu; UI nadal może pokazać zasób.
- Nieprawidłowa liczba slotów jest normalizowana do czterech podczas migracji/wczytania.
- Duplikaty ID w slotach zachowują pierwsze wystąpienie, a kolejne stają się puste.
- Nieudany zapis po zmianie loadoutu cofa zmianę w pamięci i pozostawia UI w poprzednim stanie.
- Brak celu dla żaru, usunięty wróg lub zakończona walka bezpiecznie anuluje efekt asynchroniczny.

## Strategia testów

### Testy modelu

- migracja profilu i sesji schema 1 → 2;
- cztery sloty, ownership, brak duplikatów oraz normalizacja uszkodzonego zapisu;
- zamrożenie loadoutu w sesji;
- aktywacja setu dla 0/3, 1/3, 2/3 i 3/3;
- ignorowanie nieznanego zasobu i zachowania.

### Testy zachowań

- Furnace Heart dodaje dokładnie jeden stos i zmniejsza direct hit;
- Ashen Needle przyznaje jedno przebicie oraz jedną smugę;
- Cinder Crown wybiera legalny cel i nie zapętla żaru;
- Kindling Engine utrzymuje maksymalnie pięć niezależnych stosów;
- Chain Conflagration konsumuje stosy, ogranicza generacje i ma limit obrażeń bossa;
- Fractured Prism tworzy dwa niedzielące się odłamki;
- Echoing Hourglass powtarza dokładnie co trzeci zaakceptowany cast;
- Bloodwritten Sigil respektuje próg HP, koszt i dolny limit jednego HP.

### Testy integracyjne

- hub → wyposażenie → start wyprawy → prawdziwa arena używa wybranego efektu;
- zmiana profilu po rozpoczęciu nie zmienia aktywnej sesji;
- save/resume odtwarza set i liczniki zachowań wymagane w obrębie pokoju;
- zwycięstwo, śmierć, porzucenie i usunięcie managera odłączają runtime;
- roguelite zachowuje swój loadout, ekonomię i zapis po walce Expedition;
- ekran mobilny ma cele dotykowe minimum 88 px i czytelne stany slotów/setu.

## Kolejność wdrożenia

1. Zasoby artefaktów, katalog i walidator czterech slotów.
2. Migracja profilu/sesji oraz zamrażanie loadoutu.
3. Kontrakt hooków i cykl życia `ArtifactRuntime` bez konkretnych efektów.
4. Trzy artefakty niezależne.
5. Trzy elementy Covenant of Embers i model stosów podpalenia.
6. Bonusy 2/3 oraz 3/3 wraz z zabezpieczeniami łańcuchów.
7. Mobilny ekran kolekcji i wyposażenia.
8. Integracja z rzeczywistą areną, save/resume i pełne regresje izolacji.

## Ryzyka i ograniczenia

- **Rekurencyjne efekty:** każdy wtórny pocisk, echo, żar i eksplozja niesie flagi pochodzenia oraz
  limit generacji.
- **Sprzężenie z areną:** hooki mają kontekst danych, nie referencje do managerów trybu.
- **Koszt balansu:** wartości pozostają w zasobach; testy chronią kontrakty, nie tymczasowe liczby.
- **Czytelność:** aktywacje mają jednoznaczny VFX/komunikat i nie mogą wyglądać jak zwykły hit.
- **Wydajność telefonu:** smugi, żary i odłamki korzystają z limitów aktywnych instancji oraz puli,
  jeśli profilowanie wykaże alokacje w gorącej ścieżce.
- **Przyszły loot:** prototypowe odblokowanie kompletu jest jawnie tymczasowe i odseparowane od
  finalnego sposobu zdobywania.

## Decyzje przyjęte

- Efekty są transformacyjne i zawsze mają ograniczenie, koszt albo warunek.
- Pierwszy set opiera się na podpaleniach i łańcuchowym czyszczeniu grup, ale pozostaje użyteczny
  przeciw bossom.
- Set ma trzy elementy; progi 2/3 i 3/3 działają jednocześnie przy pełnym zestawie.
- Loadout ma cztery sloty i jest zamrożony na czas wyprawy.
- Zachowania używają jawnych hooków i rejestru, nie logiki wpisanej w manager Expedition.
- Ten etap dostarcza przedmioty prototypowo; system zdobywania powstanie w następnym pionie.
