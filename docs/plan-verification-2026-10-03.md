# Pokrycie planu i brakujące dowody — 2026-10-03

Zakres pozostaje pełnym [planem grywalności](gameplay-audit-2026-10-03.md).
„Kod/test” nie oznacza ukończonego gate'u produkcyjnego. Poniżej oddzielono mechanikę
od kryteriów, których nie potwierdza headless ani model ekonomii.

| Punkt | Bieżąca implementacja / dowód | Pozostała weryfikacja |
| --- | --- | --- |
| 1. Fractional gold | RunManager kumuluje ułamki; `run_integrity` i model 10 000 przebiegów | Realny budżet po większości walk i stopniowy spadek zakupów na Ascension |
| 2. HP między etapami | RunManager/save, procent max HP, kontrolowana regeneracja; `run_integrity` | Brak nieodwracalnej spirali po jednym błędzie w grze |
| 3. Consumable | Wspólny stan i ładunki; użycie/save/resume w `run_integrity` | Smoke dotykowego HUD na telefonie |
| 4. Sloty | Głębokości 1/4/7; `run_integrity` | Ocena ostatniej zmiany buildu w trzecim akcie |
| 5. Ascension | Regionalne limity i zwycięstwa; `run_integrity`, `ascension_rules_native` | Balans jakościowych reguł 5/10/15 w realnej walce |
| 6. Decyzje w walce | Checkpointy 35/70%, pauza/skip/wygasanie; `cadence_native` | Pięć kolejnych pełnych realnych runów, pierwsza decyzja <30 s, odstępy ≤45 s |
| 7. Funkcje węzłów | GameManager: combat/elite → reward → mapa, boss 5 → sklep; treasure gear/heal/gold; `node_routes_native` tworzy rzeczywiste UI i areny | Ocena odmiennych funkcji ekonomicznych i jakości decyzji w grze |
| 8. Starter common | SkillPicker/StarterContracts; `contracts_native` | Brak restartowego bodźca w playtestach |
| 9. Informacja bojowa | HUD: licznik i pasek fali, oznaczenia modyfikatorów, boss HP, procs; `cadence_native`, `damage_native` | Czytelność telefonu; oznaczenia modyfikatorów są skrótami/symbolami, nie ilustracjami |
| 10. Nowe role/affixy | Charger/caster/shield/splitter/fragmenty, Trail/Nova; `encounter_native`, `splitter_native` | Różnorodność ruchu, sylwetki i telegraphy w nagraniach, wydajność urządzenia |
| 11. Bossowie | Trzy regionalne zachowania, druga faza finału; `boss_native`, także zasoby z APK | Nagrania śmierci i brak nieczytelnych trafień spoza ekranu |
| 12. Ekonomia | Model 10 000, ceny pierwszych upgrade'ów 30/36/45, reset rerolla; `economy_cleanup`, `run_integrity` | Docelowe zakupy/rerolle/saldo na akt, realne strojenie; nadmiar waluty i wpływ LOW nadal otwarte |
| 13. Meta pozioma | Regionalne zwycięstwa, wyzwania, kontrakty, kosmetyki/trofea; `challenges_native`, `contracts_native`, `cosmetics_native` | Równy budżet bojowy kontraktów; daily seed/historia dopiero po stabilizacji balansu |
| 14. Shop affinity | Shop używa RewardRoller.get_region_affinity dla jednego build slotu; `shop_affinity_native`: 90 regionalnych i 30 neutralnych rolli w kontrolowanym katalogu | Realny brak wymuszenia buildu i ocena dostępności pełnego katalogu w playtestach |
| 15. Support validation | Wspólny powód odrzucenia w SkillInstance/BuildOptions i UI; `run_integrity` | Smoke linkowania i zamiany na telefonie |
| 16. Run summary | Earned/spent/refunded, obrażenia, leczenie, rerolle, czas i źródła; `damage_native`, `run_integrity` | Każda realna śmierć ma poprawne źródło; czytelność scrolla na telefonie |
| 17. Dokumentacja | Design overview zaktualizowany; `catalog_native` sprawdza katalog i RegionResource | Snapshot aktualizować świadomie przy kolejnych zmianach danych |

## Gate'y i metryki końcowe

Użytkownik rozszerzył cel o grafikę chargera zamiast trójkąta oraz zapowiedź
Field Compilation na górnym pasku (znaczniki, pozostałe wybory, czas do następnego).
Zgłosił też nadmierną częstotliwość przerw; ocena i uzgodnienie jej zmiany pozostają
osobnym zadaniem. Kandydat grafiki jest zapisany, ale żadna z tych zmian nie jest
jeszcze wdrożona. Kryteria zapisano w
[protokole](phone-playtest-protocol.md#uzupełnienia-celu-czytelność-i-field-compilation)
i [pełnym planie](gameplay-audit-2026-10-03.md).

- A: test 100 save/resume przechodzi, ale nie pokrywa wejścia do następnego węzła po
  odczycie mapy z JSON. Próba RESUME na telefonie ujawniła błąd typowania modyfikatorów
  w `StageTree.visit` i szary ekran. Gate A nie jest domknięty.
  Nie utożsamiać testu z 99% crash-free realnych sesji.
- B: mechanika checkpointów przechodzi, ale raport playtestów ma `insufficient_data`.
  Dwa nowe ludzkie runy mają pełny pomiar oczekiwania na spawn (0,543/0,576 s),
  lecz to nadal 2/5 próbek; jeden zawiera odstęp 71,632 s przekraczający 45 s.
  Brak dowodu pięciu kolejnych pełnych runów spełniających gate przed zmianą duration.
- C: scenariusze headless i pakowanie APK przechodzą; telefon jest już połączony,
  ale brak nagrań 1080×1920, nagrań śmierci oraz profilowania przy capie 40 pocisków.
- D: model/syntetyczne fixture'y nie zastępują 50–100 realnych runów ani win-rate.
  Różnorodność trzech archetypów na starter, pick-rate ≤70% przy porównywalnej dostępności,
  win-rate 25–45%, pełny run 15–25 min i brak >60 s bez bodźca są niepotwierdzone.
  Mediana odstępów <40 s również wymaga realnego zbioru.

Pełny zestaw 14 regresji przeszedł po poprawce eksportu. Po dodaniu paska fali ponownie
przeszedł zmieniony test `cadence_native`. Wyniki nie domykają powyższych gate'ów.

Luki regresji przejść UI oraz shop affinity zostały pokryte w iteracji 23. Testy przejść
mają wyłączone przetwarzanie walki/animacji; nie mierzą cadence ani dotykowej czytelności.
Test chestów wywołuje sygnał wyboru, a picker i sklep używają rzeczywistych przycisków.
Wykryte podwójne przejście przy zamykaniu pickera naprawiono i dodano scenariusze dwóch
kolejnych nagród, zamknięcia bez wyboru oraz zakończenia runu z otwartym UI.

Telefon jest dostępny przez ADB. Po zgodzie użytkownika zebrano jeden zakończony log
sprzed aktualizacji (porażka, MEDIUM/cap 50); raport `.godot/phone_report.json` nadal
ma `insufficient_data` dla cadence i kod 2 dla minimum 50. Zaktualizowano APK bez
odinstalowania, sprawdzono hash pakietu oraz niezmienione hashe profilu/logu.
Uruchomiono nowy build i przeprowadzono częściową automatyczną próbę ADB: menu, Unlocks,
dwie walki, checkpointy, nagrody i trzeci etap. Odtworzono blokowanie scrolla na kartach
Unlocks i nagłe, niezapowiedziane checkpointy. Próba wznowienia po aktualizacji wykazała
błąd mapy opisany powyżej. Nie ukończono runu; automatyczny ID
`aefc20edecd62d0e906d10ca` nie może powiększać ludzkiego zbioru mimo `source=playtest`.
Dodano zamówione debugowe strzałki, regresję realnego wejścia przez viewport i zbudowano
osobne testowe APK, zainstalowane i sprawdzone fizycznie (prawo/lewo/przełącznik OFF).
Później dokończono `a240225f718b22b4519980ec` (Fireball) i nowy
`74bd602d39df3d4eb7156e10` (Lightning Bolt) do naturalnych porażek na bossie 5/10.
Potwierdzono też Treasure, elitarną nagrodę, zakupy/odjęcie 27 gold i przypisanie supportu
do skilla na fizycznym telefonie. Surowe logi obu mają `death`, bez dropped events;
zachowano je w `.godot/phone-arrows-two-ended-20261003/files/telemetry`.
Żaden z trzech ID ADB nie może powiększać ludzkiego zbioru mimo `source=playtest`.
Kilkusekundowe opóźnienia sterowania i brak wideo nie pozwalają domknąć czytelności
telegraphów ani stroić bossa. Wykryto dodatkowo nadpisywanie Best Combo między etapami
(HUD 32 → summary 2), bez poprawki. Telefon pozostawiono w menu.
17 natywnych scen oraz smoke przeszły przy zmianie strzałek; GUT nie jest zainstalowany.
Użytkownik wybrał kontynuację testów telefonu zamiast proponowanej naprawy resume;
nie zmieniano teraz kodu. Następne warunki: uzgodniona naprawa wznowienia mapy i ludzkie
pełne runy według
[protokołu playtestów](phone-playtest-protocol.md). Nie należy uznawać celu za osiągnięty.

Po zatrzymaniu automatycznych testów użytkownik wykonał dwa runy opisane w
[osobnym audycie](phone-human-runs-2026-10-03.md). Ponowne uruchomienie raportu na
izolowanym zbiorze dwóch ID potwierdziło 2 completed playtests, 0 invalid files,
0 duplicates i 0 dropped events; kod 2 oraz `insufficient_data` pozostają prawidłowe.
Obie śmierci to `mini_boss:slam` na Elite + Deadly. Odczyt/analiza nie wznowiły gry
ani testowania telefonu i nie zmieniły balansu. Surowe logi pozostają poza Git.
