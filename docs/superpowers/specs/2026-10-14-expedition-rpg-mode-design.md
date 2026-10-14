# Syntax Breaker — tryb Expedition RPG

**Data:** 2026-10-14  
**Status:** projekt do akceptacji przed przygotowaniem planu wdrożenia

## Cel

Rozszerzyć Syntax Breaker o osobny tryb RPG z trwałą postacią, proceduralnymi mini-lochami,
kampanią prowadzącą do endgame'u oraz artefaktami zmieniającymi zasady buildu. Tryb ma dawać
graczowi czytelny powód do kolejnych wypraw: wybrać cel, odnaleźć właściwego bossa i polować
na konkretny artefakt lub element zestawu.

Obecny roguelite pozostaje niezależnym, szybszym trybem. Oba tryby współdzielą fundament walki
i katalog treści, lecz mają osobne zapisy, ekonomię oraz balans progresji.

## Kryteria sukcesu

- Gracz przed rozpoczęciem wyprawy potrafi wskazać, na jaki przedmiot poluje i gdzie może go zdobyć.
- Pojedyncza ekspedycja trwa około 6–12 minut i zawiera przynajmniej jedno znaczące rozwidlenie.
- Artefakty zmieniają sposób działania buildu, zamiast sprowadzać się do małych premii liczbowych.
- Ukończenie kampanii odblokowuje powtarzalny endgame z rosnącą różnorodnością mechaniczną.
- Śmierć kończy bieżącą wyprawę, ale nie odbiera poziomów ani wcześniej wyposażonych przedmiotów.
- Tryb RPG nie jest wymagany do uzyskania mocy w roguelite i odwrotnie.

## Zakres pierwszego wydania

Pierwszy grywalny pionowy wycinek obejmuje:

- jedną trwałą postać;
- region Burning Grounds;
- trzy krótkie ekspedycje kampanijne;
- proceduralny graf lochu z ręcznie przygotowanych modułów pomieszczeń;
- jednego minibossa i jednego bossa;
- poziomy postaci 1–10;
- małą planszę rozwoju;
- trzy aktywne skille, supporty oraz cztery pasywki w loadoucie;
- cztery sloty artefaktów;
- sześć zwykłych artefaktów;
- jeden trzyczęściowy zestaw;
- jeden chase item przypisany do bossa;
- Kodeks pokazujący odkrycia i źródła dropu;
- osobny zapis trybu RPG.

Pionowy wycinek ma potwierdzić pętlę eksploracja → boss → rozpoznawalny drop → zmiana buildu.
Pozostałe regiony i pełny endgame są rozszerzeniem po walidacji tej pętli.

## Poza zakresem pierwszego wydania

- losowe afiksy i poziomy jakości przedmiotów;
- klasyczne sloty broni, pancerza i biżuterii;
- handel, multiplayer oraz sezony;
- wielowalutowy crafting;
- nieskończone poziomy postaci lub trudności;
- duże miasto eksplorowane postacią;
- rozbudowane dialogi i questy fabularne;
- wiele klas postaci;
- utrata wyposażenia lub poziomów po śmierci;
- przenoszenie siły postaci między RPG i roguelite.

## Główna pętla

1. Gracz wybiera trwałą postać w hubie Expedition.
2. W Kodeksie lub na mapie wybiera cel: region, ekspedycję, bossa albo poszukiwany przedmiot.
3. Generator buduje loch z 5–8 pomieszczeń i co najmniej jednego rozwidlenia.
4. Gracz przechodzi walki, wydarzenia, skarby i elity, podejmując decyzje o trasie.
5. Wyprawę kończy miniboss albo boss z własną tabelą dropu.
6. Po sukcesie znalezione przedmioty i materiały trafiają do trwałego ekwipunku.
7. W hubie gracz zmienia loadout, wydaje punkty rozwoju i wybiera kolejny cel.

## Kampania i odblokowanie endgame'u

Docelowa kampania wykorzystuje trzy istniejące regiony: Burning Grounds, Storm Spire oraz Toxic
Depths. Każdy region ma trzy ekspedycje, jedno zadanie specjalne, regionalnego bossa, własny
zestaw artefaktów oraz jeden chase item.

Kampania uczy systemów przez układ przeciwników i zasady pomieszczeń. Fabuła pozostaje lekka:
krótkie wydarzenia, prezentacja bossów i opisy przedmiotów. Pokonanie wszystkich trzech bossów
odblokowuje Fractured Realms, czyli powtarzalny endgame.

## Proceduralne lochy

Generator nie tworzy dowolnej geometrii. Składa graf z ręcznie przygotowanych modułów, które
mają jawne wejścia, wyjścia, punkty spawnu, strefy zagrożeń i dane nawigacyjne.

Obsługiwane rodzaje pomieszczeń:

- zwykła walka;
- elita;
- próba czasowa;
- kapliczka z korzyścią i kosztem;
- skarb;
- wydarzenie;
- handlarz lub rzemieślnik;
- sekret sygnalizowany wskazówką wizualną;
- miniboss;
- boss.

Każdy wygenerowany loch musi mieć legalną drogę od startu do finału, kontrolowaną długość,
limit kolejnych pomieszczeń tego samego rodzaju oraz co najmniej jeden wybór pomiędzy ryzykiem
i nagrodą. Seed lochu jest przechowywany w aktywnym zapisie, aby wznowienie odtwarzało identyczny
układ.

## Trwała postać i loadout

Postać posiada trwałe XP, poziom, punkty rozwoju, bibliotekę odblokowanych skilli/supportów,
artefakty, materiały i postęp kampanii.

Docelowy loadout zawiera:

- trzy aktywne skille;
- maksymalnie trzy supporty na skill;
- cztery pasywki;
- cztery artefakty;
- jeden consumable.

Istniejący `SkillInstance`, tagi i walidacja supportów pozostają źródłem prawdy dla kompozycji
skilli. Tryb RPG dostarcza im osobny kontekst postaci i osobne źródło modyfikatorów; nie zapisuje
swojej progresji w `RunManager` roguelite.

## Poziomy i plansza rozwoju

Pierwsze wydanie ma poziomy 1–10, a docelowa kampania około 30 poziomów. Każdy poziom daje jeden
punkt do planszy z trzema kierunkami:

- Power — obrażenia, krytyki i statusy;
- Control — obszar, pociski, cooldowny i mobilność;
- Survival — HP, odnawialna osłona, regeneracja i odporności.

Zwykłe węzły dają umiarkowane premie. Węzły kluczowe zmieniają reguły, lecz zawierają wyraźny
koszt lub ograniczenie. Plansza ma skończony limit mocy; endgame nie opiera się na nieskończonym
zdobywaniu punktów statystyk.

## Artefakty

Artefakt jest zasobem danych z następującymi polami logicznymi:

- stabilne `id`, nazwa, opis i ikona;
- region i jawne źródło dropu;
- warunek wyposażenia, jeśli istnieje;
- podstawowy bonus;
- klucz zachowania zmieniającego mechanikę;
- opcjonalne `set_id`;
- poziom trudności wymagany do dropu;
- flaga chase itemu.

Efekty mechaniczne implementują oddzielne zachowania rejestrowane podobnie do supportów.
Interfejs zachowania artefaktu musi obsługiwać tylko potrzebne punkty zaczepienia, np. zmianę
statystyk, przyjęcie obrażeń, pęknięcie osłony, trafienie, zabójstwo i zastosowanie statusu.

Artefakty mają stałe właściwości. Pierwsze wydanie nie losuje afiksów ani wartości, dzięki czemu
przedmiot jest rozpoznawalny, testowalny i możliwy do opisania w Kodeksie.

## Zestawy artefaktów

Regionalny zestaw składa się z trzech artefaktów. Każdy element działa samodzielnie:

- 2/3 aktywuje główną mechanikę zestawu;
- 3/3 rozwija tę mechanikę albo dodaje jej drugi etap;
- czwarty slot pozwala użyć artefaktu spoza zestawu.

Bonusy zestawu są oddzielnymi zachowaniami, a nie wyłącznie pakietem statystyk. UI zawsze pokazuje
posiadane elementy, brakujące elementy, efekt 2/3 i efekt 3/3. Pierwsze wydanie zawiera wyłącznie
jeden zestaw Burning Grounds, co ogranicza koszt balansu.

## Drop, chase itemy i ochrona przed pechem

Źródła przedmiotów są deterministycznie przypisane do rodzaju aktywności:

- zwykłe artefakty: elity, skarby i wydarzenia;
- elementy zestawu: regionalny miniboss oraz boss;
- chase item: konkretny boss albo specjalny wariant ekspedycji;
- materiały: nagroda za ukończenie wyprawy.

Kodeks pokazuje miejsce zdobycia odkrytego przedmiotu. Dla nieodkrytych przedmiotów może pokazać
zagadkę lub ogólne źródło, ale nie ukrywa zasad koniecznych do świadomego farmienia.

Każdy chase item ma licznik ochrony przed pechem powiązany z postacią i źródłem dropu. Po ustalonej
liczbie kwalifikujących zwycięstw przedmiot wypada gwarantowanie. Licznik zeruje się dopiero po
zdobyciu właściwego przedmiotu i jest częścią zapisu.

## Duplikaty i materiały

Duplikat nie zwiększa bez końca statystyk artefaktu. Jest automatycznie lub ręcznie rozkładany na
jeden wspólny materiał regionalny. W pierwszym wydaniu materiał służy do otwierania specjalnych
ekspedycji i nie tworzy nieodkrytych chase itemów.

Po walidacji kampanii materiał może odblokowywać alternatywne warianty już odkrytego artefaktu.
Warianty są rozłączne i zmienia się je w hubie; nie dodają kolejnego równoległego poziomu mocy.

## Endgame: Fractured Realms

Fractured Realms odblokowują się po kampanii. Gracz wybiera region, poziom trudności, zestaw
modyfikatorów i kategorię nagrody. Pierwsze pełne wydanie ma dziesięć poziomów trudności.

Wyższy poziom może zwiększać liczby, ale podstawowym źródłem trudności są zmiany zachowania:
nowe role przeciwników, affixy elit, reguły osłony i leczenia, zagrożenia pomieszczeń oraz dodatkowe
mechaniki bossów. Poziomy odblokowują nowe chase itemy i warianty, a nie silniejsze kopie tych
samych przedmiotów.

## Śmierć, sukces i wznowienie

Po śmierci gracz zachowuje wcześniejszy stan postaci, Kodeks i postęp kampanii. Traci przedmioty
zebrane od ostatniego zabezpieczonego punktu, część materiałów zdobytych w bieżącej wyprawie oraz
zużyty koszt wejścia do aktywności specjalnej.

Zwykłe ekspedycje nie wymagają kosztu wejścia. Przed finałem może pojawić się punkt zabezpieczenia,
który pozwala zachować jeden znaleziony przedmiot kosztem innej nagrody.

Aktywna ekspedycja zapisuje seed, bieżący pokój, stan postaci, tymczasowy łup oraz ukończone pokoje.
Wznowienie nie może przeliczać dropów ani generować innego układu.

## Hub i interfejs

Hub jest początkowo zestawem ekranów UI, nie osobną chodzoną lokacją:

- mapa kampanii i ekspedycji;
- karta postaci oraz loadout;
- plansza rozwoju;
- kolekcja artefaktów;
- Kodeks ze źródłami dropu;
- rozkładanie duplikatów;
- wybór trudności endgame'u.

Interfejs jest projektowany mobile-first. Każdy ekran ma jeden główny cel, duże pola dotykowe
i nie wymaga porównywania wielu drobnych liczb jednocześnie.

## Granica pomiędzy trybami

Roguelite i Expedition współdzielą sceny walki, skille, supporty, zachowania, przeciwników, bossów,
regiony, VFX oraz narzędzia danych. Nie współdzielą złota, poziomów, aktywnego ekwipunku, ekonomii,
zapisu ani finalnych krzywych balansu.

Odblokowania między trybami mogą być wyłącznie kosmetyczne albo informacyjne. Ukończenie RPG nie
jest wymagane do skutecznej gry w roguelite.

## Podział odpowiedzialności

Nowe podsystemy powinny mieć wyraźne granice:

- `ExpeditionProfile` — trwały stan jednej postaci i serializacja;
- `ExpeditionSession` — stan aktywnej wyprawy bez zależności od `RunManager`;
- `DungeonGenerator` — czysty generator grafu na podstawie seeda i ograniczeń;
- `RoomController` — cykl życia jednego pokoju i warunek ukończenia;
- `ArtifactResource` / `ArtifactInstance` — dane przedmiotu i aktywne zachowania;
- `ArtifactRegistry` — mapowanie kluczy zachowań na implementacje;
- `LootTableResource` / `LootRoller` — jawne pule, warunki i pity counter;
- `SetBonusResource` — progi i zachowania zestawów;
- `ExpeditionProgression` — XP, poziomy i plansza rozwoju;
- `ExpeditionCodex` — odkrycia oraz prezentacja źródeł dropu.

Generator i roller łupu mają być niezależne od scen UI, aby dało się je testować headless.
Walka otrzymuje gotowy kontekst buildu zamiast bezpośrednio czytać zapis postaci.

## Przepływ danych

1. Hub ładuje `ExpeditionProfile` i wybór aktywności.
2. `ExpeditionSession` pobiera seed oraz parametry ekspedycji.
3. `DungeonGenerator` zwraca serializowalny graf pokojów.
4. `RoomController` uruchamia właściwy moduł i emituje wynik pokoju.
5. `LootRoller` używa źródła, trudności i pity countera do utworzenia nagrody.
6. Tymczasowy łup pozostaje w sesji aż do zabezpieczenia albo sukcesu wyprawy.
7. Po sukcesie profil otrzymuje XP, artefakty, materiały i aktualizacje Kodeksu.
8. Zapis profilu odbywa się atomowo po zatwierdzeniu wyników.

## Odporność na błędy zapisu

- Profil i aktywna sesja używają osobnych plików oraz jawnej wersji schematu.
- Zapis jest wykonywany do pliku tymczasowego, a następnie podmieniany po poprawnej serializacji.
- Nagrody mają stabilny identyfikator rozliczenia, aby ponowne wczytanie nie duplikowało dropu.
- Nieznane lub usunięte ID zasobu są pomijane z ostrzeżeniem i kompensacją materiałem, zamiast
  blokować cały profil.
- Migracje schematu są testowane przynajmniej z poprzedniej wersji zapisu.

## Strategia testów

### Testy jednostkowe

- deterministyczność generatora dla seeda;
- legalność grafu, długość, osiągalność finału i wymagane rozwidlenie;
- reguły slotów artefaktów i aktywacja bonusów 2/3 oraz 3/3;
- tabele dropu, warunki trudności i gwarantowany pity drop;
- naliczanie XP i ograniczenia planszy;
- serializacja profilu oraz aktywnej sesji;
- idempotentne rozliczenie nagród.

### Testy integracyjne

- hub → ekspedycja → kilka pokojów → boss → powrót do hubu;
- śmierć bez utraty wcześniejszego ekwipunku;
- save/resume zachowujący seed, graf, łup i stan pokojów;
- artefakt oraz bonus zestawu wpływający na istniejący `SkillInstance`;
- pełna separacja zapisów i ekonomii roguelite oraz Expedition.

### Testy symulacyjne i playtesty

- tysiące seedów bez nielegalnych lub martwych grafów;
- rozkład czasu do zwykłego artefaktu, elementu zestawu i chase itemu;
- pomiar długości ekspedycji oraz czasu między decyzjami;
- wydajność na docelowym telefonie przy przejściach między pokojami;
- przynajmniej trzy sensowne buildy używające zestawu i chase itemu pionowego wycinka.

## Kolejność rozwoju produktu

1. Fundament osobnego profilu i sesji Expedition.
2. Generator grafu oraz przechodzenie między prostymi modułami pokojów.
3. Jedna kompletna ekspedycja bez trwałego lootu.
4. Artefakty, wyposażanie i integracja efektów z walką.
5. Tabele dropu, Kodeks i ochrona przed pechem.
6. XP oraz plansza rozwoju 1–10.
7. Trzy ekspedycje Burning Grounds, miniboss, boss, set i chase item.
8. Balans, save/resume, telemetria i testy urządzenia.
9. Decyzja produkcyjna: rozwijać kolejne regiony albo zmienić pętlę na podstawie playtestów.

Ta kolejność opisuje zależności produktu. Szczegółowy plan implementacyjny z zadaniami, plikami,
testami i punktami weryfikacji powstanie po zatwierdzeniu niniejszej specyfikacji.

## Ryzyka

- **Rozrost zakresu:** ograniczyć pierwszy wycinek do jednego regionu i jednej postaci.
- **Dublowanie logiki trybów:** współdzielić komponenty walki, ale nie mieszać managerów stanu.
- **Nieczytelne efekty artefaktów:** każdy efekt musi mieć osobny sygnał wizualny i krótki opis.
- **Farma bez celu:** źródła dropu i pity counter muszą być widoczne lub przewidywalne.
- **Inflacja mocy:** brak losowych afiksów i nieskończonego ulepszania duplikatami.
- **Monotonne lochy:** różnicować cele pokojów i trasy, zanim powstanie duża liczba biomów.
- **Koszt treści:** moduły pokojów i zachowania artefaktów powinny być data-driven oraz wielokrotnego
  użycia między regionami.

## Decyzje przyjęte w projekcie

- Tryb RPG jest osobny od roguelite.
- Ma trwałą postać i strukturę kampania → endgame.
- Lochy są generowane z ręcznie przygotowanych modułów.
- Chase itemy pozostają artefaktami zmieniającymi mechanikę.
- Set ma trzy elementy i progi 2/3 oraz 3/3; postać ma cztery sloty artefaktów.
- Dropy mają konkretne źródła i ochronę przed pechem.
- Śmierć nie usuwa trwałego progresu ani wcześniej posiadanego wyposażenia.
- Pierwszy etap to pionowy wycinek Burning Grounds, nie pełna kampania.
