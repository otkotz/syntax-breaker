# Audyt grywalności i plan dojścia do jakości Archero/Brotato — 2026-10-03

## Uzupełnienia celu po ludzkich playtestach — do wykonania

Poniższe wymagania rozszerzają istniejący cel „wprowadzaj zmiany zgodnie ze
szczegółowym planem”; nie zastępują punktów 1–17 ani gate'ów A–D.

- [ ] Charger: zastąpić pomarańczowy trójkąt grafiką przeciwnika zgodną z pikselowym
  stylem gry. Zachować kolizję, parametry walki i ostrzeżenie kierunku szarży.
  Wygenerowany kandydat: `assets/sprites/charger-v1.png`; nie jest jeszcze podpięty do gry.
- [ ] Field Compilation: oznaczyć rzeczywiste momenty wyboru na górnym pasku postępu
  walki oraz pokazać liczbę pozostałych wyborów i czas do następnego.
  HUD ma korzystać z tych samych progów i stanu co arena, a nie osobnej kopii harmonogramu.
- [ ] Ocenić i ograniczyć odczuwaną nadmierną częstotliwość przerw Field Compilation.
  Samo oznaczenie progów nie rozwiązuje tego wymagania; zmianę częstotliwości uzgodnić
  na podstawie danych i jakości wyborów, zachowując pierwotne wymagania cadence.

Obecny stan: arena otwiera wybory przy 35% i 70% czasu etapu; HUD pokazuje czas,
procent postępu i przeciwników, ale nie zapowiada wyborów. Szczegółowe kryteria:
[protokół telefonu](phone-playtest-protocol.md#uzupełnienia-celu-czytelność-i-field-compilation).
Automatyczne testowanie telefonu pozostaje zatrzymane na prośbę użytkownika.

## Werdykt

### Stan wdrożenia — pierwsza iteracja

- Wdrożono kumulację ułamków złota i osobne liczniki zarobków/wydatków.
- HP przechodzi między arenami i zapisami; zmiana max HP zachowuje procent zdrowia.
- Po walce odzyskuje się 10% max HP; Ascension stopniowo ogranicza regenerację do 2%.
- Consumable mają wspólny stan z RunManager, limit czterech typów i aktualizowany HUD po dropie.
- Sloty odblokowują się na etapach 1/4/7.
- Zwycięstwa odblokowują kolejne Ascension oddzielnie dla regionów.
- Sklep i manager korzystają z walidacji supportów zwracającej powód odrzucenia.
- Uzupełniono rejestr eksportowanych odblokowań, aby nowe zasoby były dostępne na Androidzie.
- Test `tests/run_integrity.tscn` przeszedł 100 zapisów/wznowień oraz testy HP, consumabli,
  złota, slotów, konfliktów supportów i regionalnego Ascension.

### Stan wdrożenia — druga iteracja

- Zwykła walka i elite prowadzą po nagrodzie na mapę; boss nadal gwarantuje sklep.
- Treasure oferuje sprzęt, odzyskanie 40% HP albo 35 złota.
- Każda arena ma checkpointy przy 35% i 70% czasu. Gracz wybiera jedną z trzech konfiguracji
  aktywnych skilli lub pomija wybór. Konfiguracje mają koszt, są ograniczone tagami i wygasają
  po walce. Pauza obejmuje ruch, spawn oraz cooldowny.
- Startowe skille mają wspólny tier common.
- HUD pokazuje czas fali, postęp, pozostałych przeciwników i modyfikatory.
- Podsumowanie pokazuje czas walki, leczenie i rerolle; koszt rerolla resetuje się w nowym sklepie.
- Jeden slot sklepu preferuje regionalny archetyp, pozostałe pozostają elastyczne.
- Test `tests/cadence_native.tscn` sprawdza oba checkpointy, wybór, pominięcie, blokadę podwójnego
  kliknięcia, wznowienie walki i usunięcie efektów po etapie. Wszystkie asercje przeszły.
- Wyciek zasobów przy zamknięciu areny naprawiono: ObjectPool jest dzieckiem właściciela,
  a pociski przeciwników należą do etapu, zamiast pozostawać w głównej scenie.

### Stan wdrożenia — trzecia iteracja

- Dodano szeroki pasek HP aktywnego bossa, ukrywany po jego śmierci.
- Synergie Overload, Shatter i Frostblight pokazują komunikat HUD z ograniczeniem do jednego
  co dwie sekundy; komunikat znika po 1,5 s.
- Podsumowanie pokazuje rzeczywiste obrażenia bezpośrednie, DPS na czas walki i bezpośrednie
  zabójstwa per skill. Pomiar uwzględnia Deep Freeze, odrzuca nadmiarowe obrażenia ponad HP
  przeciwnika i nie zalicza ponownych trafień martwego celu. DoT i efekty wtórne nadal nie są
  przypisywane do skilla; etykieta „direct” jawnie wskazuje zakres pomiaru.
- Rozszerzony test areny potwierdza boss bar, ograniczenie komunikatów oraz prawidłowe
  przypisanie obrażeń/zabójstw. Zamknięcie testu nie zgłasza już wycieków obiektów ani zasobów.

### Stan wdrożenia — czwarta iteracja

- Charger ma pomarańczową sylwetkę grotu, sekundę ostrzeżenia i zablokowany kierunek
  szarży. Ostrzeżenie pokazuje korytarz ataku; ruch prostopadły umożliwia unik.
- Area-denial caster ma fioletową sylwetkę rombu i stawia strefę w zapamiętanej pozycji
  gracza. Ostrzega przez 1,2 s, następnie działa przez 3 s z tickiem co 0,5 s.
- Charger pojawia się już w pierwszym akcie, caster od drugiego. Spawner ogranicza liczbę
  żywych instancji każdego typu do dwóch, a limit stref wynosi sześć. Nadmiarowe spawny
  zastępuje trash; śmierć zwalnia licznik. Strefy należą do etapu, nie do puli castera.
- Nowe typy resetują stan ataku przy ponownym użyciu z puli. Slow wygasa również podczas
  ostrzeżenia/szarży i postoju castera. Ataki rozpoczynają się tylko z bliskiego dystansu.
- `tests/encounter_native.tscn` przechodzi scenariusze ostrzeżenia, blokady celowania,
  uniku, ticków, wygaśnięcia stref, limitów instancji i ponownego użycia z puli.
  Ponownie przeszły testy dwóch checkpointów i 100 cykli save/resume.
- Wynik headless nie potwierdza czytelności na telefonie ani docelowego balansu obrażeń.

### Stan wdrożenia — piąta iteracja

- Shield support pojawia się od drugiego aktu (limit jednej żywej instancji). Ma turkusową
  sylwetkę krzyża w kwadracie, krąg zasięgu 150 i połączenia z chronionymi sojusznikami.
  Zmniejsza otrzymywane przez nich obrażenia o 30%, nie chroniąc bossów ani supportów.
  Efekt nie kumuluje się i jest sprawdzany przy trafieniu, więc śmierć supporta lub wyjście
  z aury od razu przywraca pełne obrażenia. Pomiar per skill uwzględnia redukcję.
- Elite dostają naprzemiennie affix Trail lub Nova, oznaczony kolorowym podpisem.
  Trail zostawia żółte strefy z ostrzeżeniem 0,8 s i czasem działania 2,5 s. Nova po śmierci
  ostrzega czerwonym kręgiem przez 1,2 s, po czym wykonuje jeden impuls obrażeń.
  Limit wynosi sześć stref elite, z jednym slotem zarezerwowanym przed Trail dla novy.
  Strefy należą do etapu i znikają z nim; reset puli czyści affix przed nowym wyborem.
- Rozszerzony test encounterów sprawdza aurę, brak kumulacji, wykluczenia, rzeczywistą
  śmierć supporta, ponowne użycie puli, oba affixy, ostrzeżenia, limit oraz pojedynczy
  impuls novy. Przeszły również regresje checkpointów i 100 cykli save/resume.
- To nadal weryfikacja headless, nie potwierdzenie balansu ani czytelności na telefonie.

### Stan wdrożenia — szósta iteracja

- Splitter pojawia się od drugiego aktu, ma limonkową dwupłatową sylwetkę i limit dwóch
  żywych instancji. Po śmierci tworzy dwa słabsze, szybsze fragmenty; fragmenty nie dzielą się
  ponownie i mają wspólny limit ośmiu. Przy pełnym limicie nie powstają zastępcze cele.
- Fragment ostrzega przez sekundę kręgiem i nie porusza się ani nie zadaje obrażeń kontaktowych
  w tym czasie. Można go zniszczyć już podczas ostrzeżenia. Reset puli przywraca ostrzeżenie.
- Potomstwo dziedziczy skalowanie etapu, zachowuje ułamkowe nagrody i pozostaje w granicach
  areny. Nie pomniejsza budżetu zwykłej fali, ale jest liczone jako żywy/oczekujący cel.
- Tworzenie fragmentów jest odroczone poza callback fizyki. Rezerwacja oczekujących celów
  blokuje przedwczesny koniec fali i pojawia się w liczniku HUD. Wymuszone zakończenie lub
  nowy setup unieważnia odroczone spawny; force_complete działa tylko na własnych wrogów.
- `tests/splitter_native.tscn` potwierdza rzeczywistą śmierć, ostrzeżenie, skalowanie, limity,
  pulę, nagrody, zakończenie fali, anulowanie kolejki oraz śmierć z sygnału kolizji Area2D.
  Przeszły też regresje wcześniejszych encounterów, checkpointów i 100 cykli save/resume.

### Stan wdrożenia — siódma iteracja

- Spawner wybiera osobne sceny bossów Burning Grounds, Storm Spire i Toxic Depths na
  podstawie regionu StageData; zwykły MiniBoss nadal obsługuje elite i minibossy.
- Burning boss przeplata ściany ognia z bezpieczną przerwą oraz ataki sektorowe z bezpiecznym
  klinem. Storm boss wyprowadza trzy linie o różnych kątach i przesuniętych ostrzeżeniach.
  Toxic boss zostawia trzy strefy trucizny i przyzywa dwa addy z oznaczeniem CLEANSE.
  Zabicie adda usuwa zagrożenie trucizną w promieniu 160 wokół miejsca śmierci.
- Wyłącznie finał na głębokości 10 przechodzi przy 50% HP do drugiej fazy. Burning podpala
  zewnętrzne 80 jednostek areny; Storm wprowadza obracający się bezpieczny sektor; Toxic
  zatruwa przestrzeń poza wyraźnymi, przemieszczanymi pomiędzy atakami bezpiecznymi wyspami.
  Stare wyspy nie nakładają się z nową regułą, a zwykłe puddle nie unieważniają bezpiecznej wyspy.
- HUD pokazuje oddzielny komunikat nowej reguły. Ostrzeżenia nowych ataków trwają 1–2,3 s,
  a reguły drugiej fazy dają 2 s na reakcję. Zwykłe ataki rozpoczynają się z bliskiego dystansu.
- Limit zagrożeń wynosi 12 na bossa. Śmierć/reset/usunięcie bossa czyści jego zagrożenia,
  a śmierć unieważnia również zarezerwowane, jeszcze nieutworzone addy.
- `tests/boss_native.tscn` potwierdza wybór scen, odmienne ataki, bezpieczne obszary,
  sekwencje ostrzeżeń, pojedyncze trafienie linii, czyszczenie po addach, próg finałowej fazy,
  brak tej fazy na głębokości 5, limit zagrożeń i sprzątanie. Test checkpointów obejmuje też
  komunikat fazy w HUD. Wszystkie pięć zestawów natywnych i smoke test przeszły.
- Gate Milestone C pozostaje otwarty: test headless nie zastępuje nagrań śmierci, renderowanej
  oceny 1080×1920 ani pomiaru na słabszym telefonie. Balans nowych bossów wymaga playtestu.

### Stan wdrożenia — ósma iteracja

- Wkład skilla obejmuje teraz bezpośrednie trafienia, DoT i proci, z osobnymi kanałami
  obrażeń oraz zabójstw. Pomiar nadal dotyczy rzeczywistego ubytku HP po redukcjach,
  wyklucza overkill i ponowne trafienia martwego celu. Kill bus dostaje zasób skilla sprawcy.
- DoT zachowuje źródło do kolejnego ticka; zastąpienie tego samego statusu zastępuje także
  źródło. Spread Plague Carrier zachowuje sprawcę pierwotnej trucizny, a cloud Corpse Bloom
  zachowuje skill tworzący chmurę. Chmury należą teraz do etapu, nie do sceny głównej.
- Supporty, mutacje, interakcje tagów i synergie przekazują źródło. Synergie współdzielone
  przypisuje się skillowi uruchamiającemu efekt. Consumable i efekty bez źródła są raportowane
  jako Other damage. Elemental Proliferation używa zgodnego z resztą systemu statusu burn.
- Podsumowanie pokazuje łączny damage/DPS/kills per skill oraz rozbicie Direct/DoT/proc.
  Statystyki można przewijać, a przycisk powrotu pozostaje dostępny także w krótkim viewport.
  Starsze zapisy zachowują znane wcześniejsze trafienia direct i jawnie zaznaczają, że
  historycznych DoT/proców nie da się odtworzyć. Nowe liczniki przechodzą save/resume.
- Sharpened Edge, Arcane Tempo, Virulence, Detonation Expert i Deep Freeze emitują komunikat
  przy aktywacji warunku bojowego. Limity emisji i HUD ograniczają komunikaty do jednego na
  dwie sekundy; etykieta znika po 1,5 s i nie zastępuje informacji o fazie bossa ani synergii.
- `tests/damage_native.tscn` potwierdza kanały obrażeń, źródła DoT, zabójstwa, synergię,
  Ignite, support poison, nieprzypisane obrażenia, sumy, save/resume, zgodność starego zapisu,
  warunki pięciu silników oraz przewijane podsumowanie w 1080×720. Test checkpointów sprawdza
  etykietę keystone i throttling. Wszystkie sześć testów natywnych oraz smoke test przeszły.

### Stan wdrożenia — dziewiąta iteracja

- Dodano natywny symulator ekonomii i rozkładu ofert wykorzystujący dane StageTree,
  Spawnera, scen przeciwników, Shop i RewardRoller. Wykonał 10 000 przebiegów w 48 kohortach
  (region, Ascension 0/5/10/20, HIGH/LOW, dwie polityki zakupów), bez naruszeń bilansu złota.
- Raport `docs/economy-audit-2026-10-03.md` zapisuje założenia, wyniki i komendę odtworzenia.
  Pełny JSON w `.godot/economy_simulation.json` obejmuje statystyki per akt i histogramy ofert.
- Model szybkiego czyszczenia wykazał nadmiar złota i wpływ presetu LOW na przychód.
  Nie uznano go za playtest ani prognozę win-rate; nie obniżono cen bez danych z realnej walki.
  Docelowa konkurencja upgrade'u z 2–3 przedmiotami nadal wymaga strojenia.
- Anulowany zakup nie zwiększa zarobku ani wydatków netto; actual Cancel UI nie duplikuje zwrotu.
  Naprawiono też naliczanie kosztu kolejnego upgrade'u przy wielokrotnym sumowaniu float.
  Rozszerzony test integralności przeszedł po 50 zakupów każdego upgrade'u i 100 save/resume.

### Stan wdrożenia — dziesiąta iteracja

- Dodano lokalny rejestrator runów: czas walki i decyzji, oczekiwanie na spawn, role wrogów,
  oferty, wybory, transakcje, HP, źródła trafień/śmierci i dane czasu klatek. Bez wysyłania danych.
- Atomowe checkpointy i snapshot w save zachowują run ID po wznowieniu. Stare zapisy nie
  dziedziczą obcej rejestracji; headless i fixture'y są oznaczone jako synthetic.
- Podsumowanie pokazuje źródło śmierci, odróżniając kontakt, charge, projectile i hazard.
  I-frame nie nadpisuje źródła, a auto-revive nie jest zapisywany jako śmierć.
- Dodano raport z percentylami, kohortami win-rate i pick-rate względem dostępności.
  Domyślnie wyklucza synthetic; wymaganie 50 realnych próbek nie może być spełnione fixture'ami.
- Test telemetrii przeszedł 50 syntetycznych sekwencji save/resume oraz testy agregacji,
  starego save, timingu, revive i limitu zdarzeń. Przeszły też sześć regresji i smoke 300 klatek.
- Instrukcje zbierania i analizy oraz ograniczenia pomiaru: `docs/telemetry-2026-10-03.md`.
  Nie zebrano jeszcze 50–100 prawdziwych playtestów ani dowodów czytelności na telefonie.

### Stan wdrożenia — jedenasta iteracja

- Raport lokalny sprawdza pięć ostatnich zakończonych realnych runów, zamiast wybierać
  korzystną podgrupę. Obejmuje pierwszy wybór, początkowy i końcowy odstęp oraz spawn wait.
- Dodano `--require-cadence`: brak pięciu próbek lub niespełnienie pomiaru zwraca kod 2.
  Wynik liczbowy nie zastępuje ekonomicznej i jakościowej części gate'u Milestone B.
- Walidacja odrzuca uszkodzone pola i niemożliwe czasy. Kopie tego samego ID nie zwiększają
  liczby runów; konflikt kopii i niejednoznaczna chronologia blokują potwierdzenie cadence.
- Nowy natywny test raportu potwierdza wybór ostatnich pięciu, granice 30/45 s, końcowy ogon,
  częściowe resume, synthetic, uszkodzone logi oraz duplikaty. Nie dodano danych playtestu.

### Stan wdrożenia — dwunasta iteracja

- Dodano cele Mine Specialist, Dual Compiler i Unpatched do Codexu oraz nowe ukończenia
  do podsumowania zwycięstwa. Profil zapamiętuje pierwszy wynik bez przyznawania mocy.
- Warunki badają historię runu: rzeczywiste casty min/zwykłych skilli, bazowe żywioły dodatnich
  obrażeń i odzyskane HP. Końcowa podmiana buildu nie ukrywa wcześniejszego naruszenia.
- Auto-revive nalicza teraz odzyskane HP do Healing Received. Regen po etapie również
  wyklucza wyzwanie bez leczenia; procentowe przeliczenie max HP nie jest leczeniem.
- Liczniki przechodzą save/resume. Stare zapisy bez historii nie otrzymują retroaktywnych
  osiągnięć. Naprawiono load_progress, aby używał wybranego save_path tak jak zapis profilu.
- Test wyzwań, osiem wcześniejszych regresji oraz smoke przechodzą. Dokładne reguły i
  ograniczenia: `docs/archetype-challenges-2026-10-03.md`.
- Mine-only wymaga jeszcze kontraktu startera: standardowy start musi najpierw walczyć
  bez Mine. Kontrakty o równym budżecie, kosmetyki i pozostałe gate'y nie są ukończone.

### Stan wdrożenia — trzynasta iteracja

- Ekran startera oferuje Standard, Miner po pierwszym zwycięstwie i Architect po trzech.
  Kontrakty zaczynają ze skillem common; support zajmuje socket i pomniejsza początkowe złoto
  według ceny sklepu. Wspólny budżet wartości sklepowej nie dowodzi równego win-rate.
- Wspólna walidacja blokuje niezgodne skille. Alokacja jest jednorazowa przed pierwszą areną;
  nie zwiększa zarobków ani wydatków. Kontrakt i jego budżet przechodzą save/resume.
- Uzupełnienie katalogu odblokowanych kontraktów obsługuje starsze profile bez Mine/Totem.
  Telemetria rejestruje wybór, a kohorty raportu uwzględniają kontrakt startera.
- Mine Specialist ma już ścieżkę startową bez wcześniejszych zwykłych castów. Miny i totemy
  należą do etapu i są usuwane wraz z areną, zamiast pozostawać w scenie głównej.
- Natywny test kontraktów obejmuje prawdziwą pierwszą arenę z Mine i sprzątanie. Dziesięć
  zestawów natywnych i smoke przechodzą. Szczegóły: `docs/starter-contracts-2026-10-03.md`.
- Nadal otwarte: balans kontraktów, kosmetyki/trofea, realne playtesty i gate'y urządzenia.

### Stan wdrożenia — czternasta iteracja

- Kosmetyczne cele wyzwań mają widoczne nagrody: dwa warianty płaszcza i styl śladów pocisków.
  Codex pokazuje warunki, podglądy płaszczy i przyciski wyposażenia; profil zachowuje wybór.
- Warianty płaszcza nie zmieniają barw żywiołu. Pociski zachowują parametry, kolizje i core;
  ich ślady wykorzystują istniejący bufor, bez dodatkowych węzłów ani pocisków.
- Trofea trzech regionów pokazują odrębne znaki, zwycięstwa i odblokowane Ascension.
  Samo odkrycie bossa nie odblokowuje trofeum. Kosmetyki i trofea nie przyznają mocy.
- Nowy test obejmuje odblokowania, profil, fallback, paletę, niezmienne parametry pocisku,
  reset puli i Codex. Jedenaście testów natywnych oraz smoke przechodzą. Szczegóły:
  `docs/cosmetics-2026-10-03.md`.
- Czytelność oraz koszt renderowania na telefonie nadal nie zostały potwierdzone.
  Daily seed/historia pozostają uzależnione od stabilnego balansu, jak w pierwotnym planie.

### Stan wdrożenia — piętnasta iteracja

- Pierwsze upgrade'y kosztują 30/36/45 zamiast 90/105/120: 2/2,4/3 zwykłe przedmioty przy
  zmierzonej medianie 15. Kolejne zakupy nadal drożeją, ilości bonusów nie zmieniono.
- Nowa symulacja 10 000 przebiegów, 48 kohort, seed 20261003, nie wykazała błędu bilansu.
  Wszystkie kohorty kupują upgrade w 100% modelowanych runów; mediana oferowanego upgrade'u
  wynosi 36. Model szybkiego czyszczenia nadal ma nadmiar złota, więc ekonomia nie jest zamknięta.
- Test cen obejmuje po 50 kolejnych zakupów. Jedenaście regresji przechodzi; smoke symulatora
  sprawdza nowe ekwiwalenty cen i osobną ścieżkę raportu, bez zastępowania wyniku 10 000.
- Otwarte ostrzeżenie 32 pozostających zasobów GDScript przy zamknięciu symulatora odnotowano
  w `docs/economy-audit-2026-10-03.md`. Nie uznano go za dowód braku wycieków.

### Stan wdrożenia — szesnasta iteracja

- Usunięto statyczny cache katalogu z wewnętrznej klasy sklepu symulatora. Cache jest polem
  jednej instancji, zwalnianym przy sprzątaniu; ostrzeżenie o 32 zasobach nie występuje w regresji.
- Porównanie 48 próbek przy tym samym seedzie potwierdza identyczne wyniki ekonomii i ofert.
- Test `tests/economy_cleanup.tscn` uruchamia osobne procesy dla 48 i 480 przebiegów oraz
  sprawdza logi po zamknięciu, zamiast uznawać sam kod 0 za brak wycieków. Obie próby przechodzą.
- Smoke 300 klatek przechodzi. Poprzedni raport 10 000 zachowano; nie reinterpretowano jego
  ostrzeżenia jako dowodu braku wycieków ani małych prób jako testu całej gry na telefonie.

### Stan wdrożenia — siedemnasta iteracja

- Ascension ma jawne jakościowe progi: A5 dodatkowy elite na pulsie 3, A10 caster na pulsie 2,
  A15 shield support na pulsie 4. Reguły są kumulatywne, omijają pierwszy etap i bossów.
- Znaczniki są widoczne na mapie/HUD, zapisują się w StageTree i przechodzą save/resume.
  Spawny zachowują limity casterów/supportów i są jednorazowe w ramach wyznaczonego pulsu.
- Test obejmuje granice poziomów, serializację, rzeczywisty scheduler, spawny, capy i wyjątki.
  Symulator korzysta ze wspólnej listy ról i oznacza nową rewizję modelu w raporcie.
- Próby ekonomii 48/480 uwzględniają reguły; pełny wynik 10 000 sprzed zmiany pozostaje
  historyczny. Nowe progi nie mają jeszcze potwierdzonego balansu ani czytelności na telefonie.
- Szczegóły i ograniczenia: `docs/ascension-rules-2026-10-03.md`.

### Stan wdrożenia — osiemnasta iteracja

- Odtworzono 10 000 przebiegów bieżącego modelu Ascension, 48 kohort, seed 20261003,
  149,513 s. Nie wykryto naruszeń bilansu ani ostrzeżeń ObjectDB/resources po zamknięciu.
- Aktualny raport zapisano osobno w `.godot/economy_ascension_10000.json`, zachowując stare
  wyniki. Mediana zwykłej ceny pozostaje 15, relacje pierwszych upgrade'ów to 2/2,4/3.
- Model nadal ma nadmiar złota i zależność przychodu od LOW; 10 000 przebiegów ekonomii
  nie jest pomiarem balansu bojowego ani 50–100 rzeczywistymi playtestami.
- Read-only kontrola ADB poza sandboxem potwierdziła pustą listę urządzeń. Nie wykonano
  pomiaru telefonu; zgłoszono użytkownikowi potrzebę podłączenia urządzenia.

### Stan wdrożenia — dziewiętnasta iteracja

- Zastąpiono długą listę nazw modyfikatorów w HUD kompaktowymi oznaczeniami.
  Wszystkie dziewięć obecnych reguł mieści się w pasie 720 px; przyciski mają pola dotyku
  co najmniej 68×48 px. Czas, postęp i liczba przeciwników pozostają w osobnym wierszu.
- Dotknięcie pokazuje pełną nazwę i opis przez pięć sekund bez pauzowania walki;
  na komputerze dostępny jest także tooltip. Zmiana reguł usuwa nieaktualny opis.
  HUD nie przebudowuje przycisków przy każdym odświeżeniu czasu fali.
- Test `cadence_native` sprawdza szerokość wszystkich oznaczeń, odstęp od paska bossa,
  dotknięcie, wygaśnięcie opisu, ponowne użycie przycisków, duplikaty i nieznane ID.
  Test headless nie jest dowodem czytelności na fizycznym telefonie.

### Stan wdrożenia — dwudziesta iteracja

- Zaktualizowano design overview: rzeczywistą ścieżkę nagród, checkpointy, sloty 1/4/7,
  reset rerolla na sklep, ceny upgrade'ów, kontrakty, regionalną drabinę i 12 mutacji.
- Dodano `docs/catalog-snapshot.md` oraz natywny generator/test `catalog_native`.
  Wczytuje sześć kategorii (7/25/55/40/3/8), weryfikuje ID i rejestr eksportu Androida,
  sprawdza 12 mutacji oraz eksportowane pola RegionResource z refleksji Godota.
  Porównuje snapshot dokumentacji i nagłówki liczebności w design overview.
  Wygenerowany blok trafia do cache `.godot`, bez automatycznego nadpisywania dokumentów.
- Potwierdzono źródło różnicy LOW/HIGH: budżet przeciwników jest mnożony przez
  `QualitySettings.entity_mult`, bez kompensacji nagród. Nie zmieniono tego balansu
  przed pomiarami walki i słabszego telefonu wymaganymi przez plan.

### Stan wdrożenia — dwudziesta pierwsza iteracja

- Eksport Androida ujawnił błędy parsowania Storm/Toxic boss, mimo kodu wyjścia 0.
  Usunięto preload scen regionalnych ze Spawnera: ścieżki są ładowane dopiero przy
  tworzeniu encounteru, co przerywa cykl przez Player/SkillCaster/Arena/Spawner.
  Ponowny eksport nie zgłasza błędów scen/skryptów.
- Przygotowano debug APK `builds/SyntaxBreaker-playtest.apk` i sprawdzono podpis.
  Siedem testów regresyjnych przeszło; test trzech bossów przeszedł również na zasobach
  wyciągniętych z APK, a nie na źródłowych scenach. Nie jest to test telefonu.
- Ponowna kontrola ADB pokazuje pustą listę; domyślny katalog telemetrii tego komputera
  nie istnieje. Raport `.godot/playtest_gate.json` ma `insufficient_data` dla cadence.
- Dodano [protokół telefonu](phone-playtest-protocol.md): parowanie, smoke, pięć kolejnych
  runów, nagrania czytelności, słabszy telefon i 50–100 playtestów. Nie instalowano APK
  ani nie zmieniano urządzeń. Ostrzeżenia środowiska eksportu są jawnie opisane w protokole.

### Stan wdrożenia — dwudziesta druga iteracja

- Ponownie uruchomiono cały zestaw 14 regresji po poprawce eksportu; wszystkie przeszły.
- Audyt punktu 9 wykrył, że licznik procentowy nie realizował osobnego paska fali.
  Dodano pasek postępu 720×8 px, niezabierający inputu ruchu. Rozszerzony test cadence
  sprawdza wartość i brak nakładania na dotykowe oznaczenia modyfikatorów.
- Odświeżono APK i zweryfikowano podpis; rozszerzony cadence przeszedł także na zasobach
  wyciągniętych z tego APK. Hash zaktualizowano w protokole telefonu.
- [Macierz weryfikacji](plan-verification-2026-10-03.md) obejmuje wszystkie 17 punktów,
  gate'y i metryki. Wyraźnie wskazuje brak dowodów realnego balansu, telefonu i playtestów
  oraz brak osobnych regresji pełnych przejść UI GameManager i ofert regionalnego sklepu.

### Stan wdrożenia — dwudziesta trzecia iteracja

- `node_routes_native` sprawdza rzeczywiste areny/UI dla combat, elite, treasure heal/gold,
  map shop, całej sekwencji boss 5 oraz finału. Dodatkowo pokrywa kolejny treasure po
  nagrodzie, zakończenie runu z otwartym pickerem i zamknięcie bez wyboru.
- Test wykrył błędną obsługę `tree_exiting`: dwie lambdy miały niezależną kopię scalar
  `chose`, co pozwalało ponowić przejście. Zmieniono flagę na współdzieloną tablicę;
  fallback jest deferred, sprawdza stan/generację UI i nie działa przy teardown właściciela.
  Zachowanie przechwytywania potwierdza [dokumentacja GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#lambda-functions).
- `shop_affinity_native` wykonał 90 regionalnych i 30 neutralnych rolli w kontrolowanym
  katalogu: preferencja tylko build slotu, oferty spoza regionu, brak wzmacniania statów,
  brak duplikatu zarezerwowanej oferty i respektowanie filtrów posiadanych przedmiotów.
- Osiem powiązanych regresji przeszło. Odświeżono APK i podpis; test przejść węzłów
  przeszedł także na zasobach wyciągniętych z APK. Macierz pokrycia i hash są aktualne.
  To syntetyczne sprawdzenia przejść, nie czas realnego runu ani pomiar telefonu.

Milestone B nadal wymaga pomiaru pięciu pełnych runów i czasu oczekiwania na spawn.
Milestone C wymaga jeszcze testów czytelności i wydajności na telefonie.
Milestone D nadal wymaga zebrania 50–100 realnych runów przez lokalną telemetrię, strojenia ekonomii/win-rate
oraz poziomej meta-progresji. Powyższe testy
potwierdzają integralność stanu, nie dowodzą docelowego win-rate ani jakości encounterów.

Syntax Breaker ma już mocny system budowania postaci: 7 skilli, 25 supportów, 55 pasywek,
12 mutacji, synergie żywiołów, regiony i rozgałęzioną mapę. Największą przeszkodą nie jest dziś
liczba przedmiotów, lecz pętla runu. Walka daje zbyt rzadkie decyzje, ekonomia ma błędy
zaokrągleń, część stanu nie przechodzi między etapami, a przeciwnicy i bossowie za słabo
zmieniają sposób poruszania się gracza.

Obecny build jest funkcjonalnym vertical slice'em, ale nie jest jeszcze gotowy jako publiczne demo
o jakości porównywalnej z liderami gatunku. Najpierw trzeba naprawić integralność runu, potem
tempo decyzji i encounter design. Dalsze dokładanie supportów przed tymi pracami zwiększy katalog,
ale nie poprawi odczuwalnej grywalności.

## Zakres i metoda

Audyt objął:

- pełną ścieżkę `menu → wybór skilla → mapa → walka → nagroda → sklep → podsumowanie`;
- sterowanie, obrażenia, leczenie, śmierć i consumable;
- generowanie mapy, długość etapów, role przeciwników oraz bossów;
- ekonomię złota, ceny, rerolle i skalowanie Ascension;
- tempo rozwoju buildu oraz meta-progresję;
- zapis/wznowienie runu i raport końcowy;
- statyczny audyt 1 760 644 wariantów buildu i natywny test Godota;
- headless smoke test projektu przez 300 klatek.

Smoke test i parser Godota zakończyły się kodem `0`. Nie wykonano jeszcze sterowanego testu na
telefonie ani pomiaru realnych zwycięstw, czasu runu, obrażeń otrzymywanych i wyborów graczy.
Oceny dotyczące feelingu są więc hipotezami wymagającymi playtestu, a wykazane błędy stanu i
ekonomii wynikają bezpośrednio z kodu.

## Mocne strony, które należy zachować

1. System skill + support tworzy czytelne archetypy i ma dużo legalnych kombinacji.
2. Reward roller odfiltrowuje większość bezużytecznych ofert i rozdziela wybór na ulepszenie,
   nowy kierunek oraz bezpieczną opcję.
3. Regiony mają własną oprawę, zagrożenie i preferencje draftu bez darmowego power creepu.
4. Telegraphy bossa, formacje spawnu, statusy oraz efekty trafienia dają podstawę dobrej
   czytelności walki.
5. Run można wznowić, a projekt ma limity obiektów zależne od klasy urządzenia.

## Wyniki wymagające działania

### P0 — integralność runu i ekonomii

#### 1. Złoto jest tracone przez konwersję `float → int`

`EnemyBase.apply_scaling()` wykonuje `int(base_gold * multiplier)`. Podstawowy wróg ma wartość
1, a rola `trash` mnożnik 0,5, więc większość wrogów fazy 1 daje 0 złota. Ascension zmniejsza
mnożnik złota o 2% na poziom; już przy Ascension 1 przeciwnik wart 1 może zostać zaokrąglony do 0.
W efekcie wyższa trudność może niemal wyłączyć sklep zamiast tworzyć kontrolowany niedobór.

Zmiana:

- przechowywać nagrodę jako `float` i kumulować ułamki w portfelu albo gwarantować minimum 1 dla
  każdego przeciwnika, który ma dodatnią wartość;
- rozdzielić `gold_earned` od aktualnego salda;
- zasymulować przychód na każdej głębokości i Ascension 0/5/10/20 względem cen sklepu.

Kryterium: mediana runu może kupić co najmniej jeden sensowny przedmiot po większości walk,
Ascension zmniejsza liczbę zakupów stopniowo, a żaden zwykły mnożnik nie zeruje nagrody.

#### 2. HP resetuje się po każdym etapie

Każda arena tworzy nowego gracza, a `Player._ready()` ustawia `current_hp = max_hp`. Obrażenia nie
mają więc konsekwencji między pokojami. Osłabia to leczenie, wybór trasy, sklepy i napięcie runu.

Zmiana:

- przenieść `current_hp` i `max_hp` do `RunManager`;
- zachowywać procent HP po zmianie maksymalnego zdrowia;
- po walce leczyć tylko kontrolowaną wartość, np. 10%, a pełne leczenie przypisać do konkretnego
  węzła, zakupu lub nagrody;
- zapisywać HP w aktywnym runie.

Kryterium: obrażenia z wcześniejszej walki wpływają na następną decyzję, ale gracz nie wpada w
nieodwracalną spiralę po jednym błędzie.

#### 3. Zużycie consumabli nie wraca do stanu runu

`ConsumableManager` dostaje kopię slotów. Zmniejszenie `charges` lub usunięcie przedmiotu nie
aktualizuje `RunManager.owned_consumables`, więc zużyty przedmiot może wrócić w kolejnej arenie.

Zmiana:

- manager ma emitować każdą zmianę ekwipunku albo operować przez API `RunManager`;
- zsynchronizować stan przed zamknięciem areny i przed auto-save;
- dodać test: drop → użycie → następny etap → zapis → wznowienie.

Kryterium: liczba ładunków jest identyczna w HUD, `RunManager`, zapisie i po wznowieniu.

#### 4. Czwarty slot skilla jest nieosiągalny

Run zaczyna z jednym slotem, a `advance_stage()` dodaje slot tylko na etapach 1 i 4. Maksymalna
wartość 4 istnieje w kodzie, ale normalny run dochodzi najwyżej do 3.

Zmiana: odblokowywać sloty po wejściu na głębokości 1, 4 i 7 albo jawnie ograniczyć projekt do 3.
Rekomendacja: 1/4/7, bo trzeci akt runu potrzebuje ostatniej dużej zmiany buildu.

#### 5. Ascension 0–20 jest dostępne od razu

Menu zapisuje dowolnie wybrany poziom, ale nie istnieje `highest_ascension_unlocked`. Nowy gracz
może uruchomić poziom 20, a zwycięstwo nie odblokowuje kolejnego stopnia. System nie tworzy więc
drabiny mistrzostwa.

Zmiana:

- przechowywać najwyższy odblokowany poziom per region;
- zwycięstwo odblokowuje kolejny poziom;
- selektor pozwala wybrać tylko `0..highest_unlocked`;
- co kilka poziomów dodawać regułę jakościową, nie tylko HP/damage (np. dodatkowy elite,
  trudniejszy modyfikator, mniej darmowego leczenia).

### P1 — rdzeń feelingu i tempo decyzji

#### 6. Za mało decyzji podczas 50–90 sekund walki

Rozwój odbywa się dopiero po całym etapie. Gracz przez długi odcinek tylko porusza postacią,
podczas gdy skille celują i strzelają automatycznie. W dobrym auto-combat roguelite decyzja o
pozycji musi być przeplatana częstymi, znaczącymi zmianami buildu.

Zmiana rekomendowana: dwa checkpointy kompilacji na etap walki (około 35% i 70% postępu).
Checkpoint zatrzymuje grę i daje 3 małe, tymczasowe ulepszenia aktywnego runu. Pula powinna
zawierać głównie zmianę zachowania lub specjalizację, nie kolejne płaskie `+5% damage`.

Kryterium: pierwsza znacząca decyzja następuje w pierwszych 30 sekundach, a odstęp między
decyzjami rzadko przekracza 45 sekund.

#### 7. Obowiązkowy sklep po każdej zwykłej walce spłaszcza mapę

Każda walka prowadzi do reward pickera, a potem sklepu. Osobny węzeł SHOP traci wyjątkowość,
zaś run jest często przerywany przez dwa kolejne ekrany.

Zmiana:

- po zwykłej walce: tylko nagroda i powrót na mapę;
- sklep: osobny węzeł oraz gwarantowany przystanek po bossie;
- elite: wybór jednej z trzech nagród wysokiej jakości bez obowiązkowego sklepu;
- treasure: wybór między przedmiotem, leczeniem i złotem.

Kryterium: typ węzła zmienia oczekiwaną nagrodę i koszt alternatywny, a nie tylko kolejność tych
samych ekranów.

#### 8. Startowa rzadkość zachęca do restartowania

Każdy skill startowy osobno losuje tier. Gracz może restartować do wysokiej rzadkości zamiast
wybierać archetyp.

Zmiana: wszystkie startowe skille mają tier common albo cały ekran dostaje jeden wspólny tier.
Losowe tiery powinny zaczynać się dopiero w nagrodach runu.

#### 9. Brakuje informacji bojowej potrzebnej do uczenia się

HUD pokazuje HP, złoto i etap, ale nie pokazuje czasu/progresu fali, aktywnych modyfikatorów,
ważnych proców, przyczyny śmierci ani realnego wkładu skilli.

Zmiana:

- pasek czasu/progresu i liczba pozostałych przeciwników;
- widoczne ikony modyfikatorów etapu;
- boss bar na szerokość ekranu;
- podsumowanie DPS/obrażeń/zabójstw per skill, obrażeń otrzymanych i wydanego złota;
- komunikaty aktywacji synergii oraz keystone'ów z limitem częstotliwości.

### P1 — encounter design

#### 10. Większość fal rozwiązuje się tym samym ruchem

W fazie 1 nie ma ranged, później stanowią około 8–12%. Role `trash` i `medium` korzystają z tej
samej sceny melee, a modyfikatory w większości zwiększają statystyki. Brakuje przeciwników, którzy
tworzą strefy, odcinają drogę lub wymuszają zmianę kierunku.

Zmiana — dodać kolejno:

1. telegraphed charger, którego trzeba minąć prostopadle;
2. area-denial caster zostawiający czasową strefę;
3. shield/support enemy wzmacniający grupę i będący priorytetowym celem;
4. splitter albo summoner zmieniający liczbę celów;
5. elite affixes jakościowe: orbitujące pociski, trail, nova po śmierci.

Każdy nowy typ musi mieć unikalną sylwetkę, kolor telegraphu, licznik aktywnych instancji i
scenariusz testowy. Nie dodawać pięciu kolejnych wariantów samego HP/speed.

#### 11. Bossowie różnią się głównie wyglądem

Region wybiera sprite, lecz wszystkie bossy używają jednego `MiniBoss` z tym samym zestawem
Charge/Slam/Volley. Boss na głębokości 5 i 10 również używa tego samego modelu zachowania.

Zmiana:

- Burning Grounds: ściany ognia i bezpieczne kliny;
- Storm Spire: sekwencje linii/łańcuchów i wymuszona rotacja;
- Toxic Depths: strefy trucizny, addy i czyszczenie przestrzeni;
- boss 10 dostaje drugą fazę zmieniającą regułę areny, nie tylko większe statystyki;
- każde trafienie śmiertelne musi mieć telegraph możliwy do odczytania na ekranie telefonu.

### P2 — ekonomia, buildy i meta

#### 12. Sklep oferuje ulepszenia statystyk praktycznie nieosiągalne cenowo

Globalne ulepszenia kosztują 90–120 złota, podczas gdy zwykłe przedmioty kosztują 8–25, a duża
część wrogów obecnie daje 0. Po naprawie złota trzeba policzyć budżet, nie zgadywać cen.

Zmiana:

- przygotować symulator 10 000 przebiegów ekonomii bez walki;
- określić docelowo: liczba zakupów, rerolli i zachowanego złota na każdym akcie;
- stat upgrade powinien konkurować z 2–3 przedmiotami, ale być realnym wyborem co najmniej raz
  na run;
- reroll ma resetować lub miękko maleć po sklepie, inaczej późne sklepy przestają służyć.

#### 13. Meta-progresja kończy się na odblokowaniu katalogu

Po odblokowaniu contentu Codex nie tworzy nowych celów, regiony są dostępne od razu, a Ascension
nie ma progresji. Nie rekomenduje się dużego drzewa stałych bonusów obrażeń — spłaszczyłoby balans.

Zmiana: meta pozioma zamiast grind-to-power:

- osobne zwycięstwa i Ascension per region;
- wyzwania archetypów (np. zwycięstwo mine-only, dwoma elementami, bez leczenia);
- odblokowywane starter contracts zmieniające początek runu z równym budżetem mocy;
- kosmetyczne warianty postaci, pocisków i boss trophies;
- codzienny seed oraz historia wyników, gdy podstawowy balans będzie stabilny.

#### 14. Region bias działa w rewardach, ale nie w sklepie

Regiony zwiększają wagę ofert w `RewardRoller`, natomiast `Shop` nadal losuje jednolicie. To
rozmywa regionalną tożsamość.

Zmiana: użyć tej samej funkcji affinity w sklepie, ale tylko dla jednego z czterech slotów, żeby
region inspirował build bez wymuszania go.

### P2 — spójność i edge cases

#### 15. Sklep nie używa pełnej walidacji kombinacji supportów

Reward roller korzysta z `BuildOptions.can_offer_support`, ale panel linkowania sklepu sprawdza
tylko tagi i liczbę slotów. Może pokazać cel, którego `SkillInstance.link_support()` później
odrzuci z powodu konfliktu Mine/Totem/Echo lub supportów pociskowych.

Zmiana: wszystkie UI mają używać jednego API `can_link_support_to_instance()` zwracającego również
powód odrzucenia.

#### 16. Run summary podpisuje saldo jako zarobione złoto

`Gold Earned` pokazuje `RunManager.gold`, czyli pozostałe saldo po zakupach. Dodać osobne liczniki
`gold_earned`, `gold_spent`, `damage_taken`, `healing_received`, `rerolls` i `time_played`.

#### 17. Dokumentacja danych jest już nieaktualna

Design overview nadal podaje 8 mutacji i stare pola RegionResource. Aktualizować dokumentację z
testu katalogu albo generować tabelę automatycznie, aby kolejne audyty nie pracowały na błędnym
obrazie zawartości.

## Kolejność wdrożenia

### Milestone A — run integrity (1–2 dni)

1. Naprawić fractional gold i liczniki ekonomii.
2. Utrwalić HP oraz ładunki consumabli między etapami i w save.
3. Odblokować sloty na 1/4/7.
4. Ograniczyć Ascension do najwyższego pokonanego poziomu.
5. Ujednolicić walidację supportów w rewardach, sklepie i managerze.

Gate: automatyczny test pełnego run state przechodzi sekwencję walka → użycie → zakup → save →
load bez zmiany HP, złota, ładunków ani buildu.

### Milestone B — cadence pass (2–4 dni)

1. Usunąć obowiązkowy sklep po każdej walce.
2. Dodać dwa checkpointy rozwoju w walce.
3. Ujednolicić tier startowych skilli.
4. Dodać progress fali, modyfikatory i pełne statystyki końcowe.
5. Skrócić lub wydłużyć etapy dopiero po pomiarze czasu bezczynnego oczekiwania na spawn.

Gate: w pięciu kolejnych runach odstęp między decyzjami nie przekracza 45 s, a każdy typ węzła
ma odmienną funkcję ekonomiczną.

### Milestone C — enemy and boss pass (4–7 dni)

1. Dodać charger i area-denial caster.
2. Dodać support enemy oraz dwa affixy elite.
3. Rozdzielić trzech bossów regionalnych.
4. Dodać drugą fazę finałowego bossa.
5. Przeprowadzić test czytelności telegraphów na ekranie 1080×1920 oraz słabszym urządzeniu.

Gate: nagranie każdej śmierci pozwala wskazać czytelny błąd gracza; żaden atak nie pojawia się
spoza ekranu bez ostrzeżenia.

### Milestone D — balance and retention pass (3–5 dni + playtesty)

1. Symulator ekonomii i rozkładu ofert.
2. Telemetria lokalna 50–100 runów testowych.
3. Strojenie trudności według win-rate i przyczyny śmierci, nie samego proxy DPS.
4. Region progression, wyzwania archetypów i starter contracts.
5. Dopiero potem nowa zawartość katalogowa.

## Metryki gotowości dema

Przed nazwaniem builda poziomem Archero/Brotato należy zebrać dowody z gry, nie tylko testów kodu:

- crash-free sessions: 99%+;
- brak utraty lub duplikacji stanu w 100 sekwencjach save/resume;
- czas do pierwszej decyzji: poniżej 30 s;
- mediana odstępu między decyzjami: poniżej 40 s;
- pełny run: około 15–25 minut, bez ponad 60 s ciągłej gry bez nowego bodźca/decyzji;
- co najmniej 3 realnie używane archetypy na każdy starter w zbiorze testowym;
- żaden pojedynczy skill, support lub pasywka z pick-rate >70% przy porównywalnej dostępności;
- win-rate pierwszego ukończenia po nauczeniu zasad: docelowo 25–45%;
- każda śmierć przypisana do źródła i widoczna w podsumowaniu;
- stabilny limit klatek na docelowym słabszym telefonie przy capie 40 pocisków.

Te wartości są celami produkcyjnymi do walidacji, nie wynikami obecnego builda.

## Rekomendowana następna czynność

Nie zaczynać od nowych skilli. Następny commit powinien zrealizować cały Milestone A, ponieważ
bez wiarygodnego HP, złota, consumabli i Ascension żaden playtest balansu nie dostarczy użytecznych
danych. Po nim należy rozegrać minimum 10 pełnych runów na telefonie i dopiero stroić cadence.
