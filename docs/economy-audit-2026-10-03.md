# Symulator ekonomii — 2026-10-03

## Aktualizacja cen — piętnasta iteracja

Uwaga o aktualności: liczby w sekcji piętnastej iteracji poprzedzają jakościowe reguły Ascension.
Pełny aktualny przebieg `ascension_opening_roles_v1` opisano poniżej w osiemnastej iteracji;
wcześniejsze wyniki zachowano jako historyczne.

## Bieżąca rewizja — osiemnasta iteracja

`ascension_opening_roles_v1`: 10 000 przebiegów, 48 kohort, seed `20261003`, 149,513 s.
Wszystkie kontrole bilansu przeszły. Log zamknięcia nie zawiera ostrzeżeń ObjectDB/resources.
Raport: `.godot/economy_ascension_10000.json`; log: `.godot/economy_ascension_10000.log`.
Nie zastąpiono wcześniejszych raportów. Odtworzenie bieżącej próby:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/economy_simulation.tscn --log-file .godot/economy_ascension_10000.log -- --runs=10000 --seed=20261003 --output=res://.godot/economy_ascension_10000.json
```

Zebrano 73 888 ofert (20 867 supportów, 19 826 pasywek, 14 723 skille, 18 472 upgrade'y).
Mediana zwykłej oferty wynosi 15, pierwsze upgrade'y nadal mają ekwiwalenty 2/2,4/3.
W każdej kohorcie 100% modelowanych runów kupuje upgrade. Najniższy udział wizyt z dostępnym
cenowo zwykłym przedmiotem wynosi 98,71%. To nie pick-rate ani deklaracja użyteczności w walce.

Mediany Burning Grounds / items_first, po uwzględnieniu dodatkowych ról Ascension:

| Ascension | Preset | Zarobek | Wydatki | Upgrade'y | Saldo końcowe |
| --- | --- | ---: | ---: | ---: | ---: |
| 0 | HIGH | 3561,0 | 123 | 2 | 3517,25 |
| 5 | HIGH | 3383,0 | 121 | 2 | 3309,9 |
| 10 | HIGH | 3028,4 | 123 | 2 | 2942,6 |
| 20 | HIGH | 2457,35 | 120 | 2 | 2381,7 |
| 0 | LOW | 2382,5 | 117 | 2 | 2284,5 |
| 5 | LOW | 2237,3 | 123 | 2 | 2148,2 |
| 10 | LOW | 1920,8 | 123 | 2 | 1839,8 |
| 20 | LOW | 1494,5 | 118 | 2 | 1398,0 |

Mediany się nie sumują. Obowiązują wcześniejsze ograniczenia: pełny katalog, standardowy
starter, szybkie czyszczenie, brak śmierci/leczenia oraz rzeczywistych decyzji o wartości.
Dodatkowe wrogie role uwzględniają przychód, nie prawdopodobieństwo śmierci ani czas zabijania.
Nadmiar waluty i zależność przychodu od LOW pozostają; danych do strojenia win-rate nadal brak.

Sprawdzenie sprzętu w tej iteracji: ADB poza sandboxem zakończyło `devices` kodem 0 z pustą
listą. Nie ma dostępnego telefonu do pomiaru. Nie uznano tej kontroli za test Androida,
czytelności, wydajności lub crash-free rate.

Pierwsze upgrade'y kosztują teraz 30/36/45 złota (damage/haste/precision), a przyrost ceny
kolejnego zakupu wynosi 10/12/15. Ilości bonusów nie zmieniono. Przy medianie zwykłej oferty
15 pierwsze zakupy odpowiadają 2/2,4/3 przedmiotom. Powtórzenia pozostają droższe; to nie
gwarancja, że każda kolejna oferta będzie kosztować najwyżej trzy przedmioty.

Nowy eksperyment wykonał 10 000 przebiegów, seed `20261003`, 48 kohort, 151,757 s,
bez naruszeń bilansu. Zebrano 73 932 oferty: 20 877 supportów (mediana ceny 12),
19 825 pasywek (15), 14 747 skilli (20), 18 483 upgrade'y (36). Mediana zwykłej oferty
nadal wynosi 15. Udział runów z zakupionym upgradem wynosi 100% w każdej modelowanej
kohorcie; najniższy udział wizyt z dostępnym cenowo zwykłym przedmiotem wynosi 96,66%.

Przykładowe mediany Burning Grounds / items_first:

| Ascension | Preset | Zarobek | Wydatki | Upgrade'y | Saldo końcowe |
| --- | --- | ---: | ---: | ---: | ---: |
| 0 | HIGH | 3561,0 | 123 | 2 | 3517,25 |
| 5 | HIGH | 3290,65 | 121 | 2 | 3225,8 |
| 10 | HIGH | 2944,0 | 123 | 2 | 2855,8 |
| 20 | HIGH | 2375,15 | 120 | 2 | 2303,7 |
| 0 | LOW | 2382,5 | 117 | 2 | 2284,5 |
| 5 | LOW | 2137,05 | 123 | 2 | 2042,15 |
| 10 | LOW | 1824,4 | 119 | 2 | 1726,6 |
| 20 | LOW | 1403,75 | 116 | 2 | 1315,1 |

Mediany osobnych kolumn nie sumują się. Model zachowuje poprzednie ograniczenia: szybkie
czyszczenie, brak śmierci/leczenia i standardowy starter, nie nowe kontrakty. Mniejsze ceny
rozwiązują początkową relację 2–3 przedmiotów, ale zwiększają pozostające saldo; nie zamykają
strojenia przychodu ani win-rate. Nie zmieniono gęstości, złota wrogów ani mocy upgrade'ów.

Jedenaście zestawów natywnych ponownie przechodzi. Test integralności sprawdza zakres
pierwszej ceny i po 50 powtórzeń wszystkich trzech upgrade'ów. Dodatkowy smoke symulatora
obejmuje 48 kohort i nowe pola raportu: medianę zwykłej ceny oraz ekwiwalenty pierwszych
upgrade'ów. Opcja `--output=<ścieżka>` pozwala zapisywać takie krótkie próby bez zastępowania
raportu 10 000. Aktualny pełny raport jest w `.godot/economy_simulation.json`; bazowy został
zachowany w `.godot/economy_before_upgrade_prices_20261003.json`.

W piętnastej iteracji przy zamknięciu symulatora Godot zgłaszał 32 pozostające zasoby.
Verbose wskazuje zasoby GDScript/klasy, nie żywe instancje przeciwników; przyczyna nie została
jeszcze ustalona w tej iteracji. Wyczyszczenie cache katalogu nie usuwało ostrzeżenia. Wynik `failures=[]`
potwierdza bilans modelu, nie brak wszystkich wycieków ani gotowość produkcyjną.

## Sprzątanie symulatora — szesnasta iteracja

Przyczynę zawężono eksperymentalnie do `static var catalog` w wewnętrznej klasie CatalogShop.
Samo wyczyszczenie słownika oraz dodatkowa klatka przed wyjściem nie usuwały 32 zasobów.
Zmiana cache'u na pole instancji sklepu usuwa ostrzeżenie; cache jest zwalniany wraz ze sklepem.
Symulator ma jedną instancję CatalogShop, więc nie potrzebuje współdzielenia cache'u między
instancjami. Zakres i częstotliwość odczytów katalogu w ramach jednego eksperymentu nie zmieniają się.

To jest zgodne z udokumentowanym utrzymywaniem skryptów posiadających statyczne zmienne;
Godot 4.6 opisuje też ograniczenie `@static_unload`, dlatego nie przyjęto samej adnotacji za
naprawę bez dowodu z uruchomienia. [Dokumentacja GDScript 4.6](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/gdscript_basics.html#static-unload-annotation).

Przy seedzie 20261003 porównano raporty 48 próbek przed i po poprawce: identyczne kohorty,
zarobki/wydatki/salda, zakupy, histogramy ID/cen, tabela upgrade'ów, mediana i ekwiwalenty.
Wyłączono jedynie czas wykonania z porównania. Nie zmieniono bilansu ani strumienia losowań.

`tests/economy_cleanup.tscn` uruchamia w osobnych procesach 48 oraz 480 przebiegów, sprawdza
exit code, wszystkie 48 kohort, pustą listę błędów bilansu i logi zamknięcia. Nie przechodzi
przy ObjectDB instances leaked, resources still in use lub SCRIPT ERROR. Obie próby i smoke
300 klatek przeszły. Uruchomienie:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/economy_cleanup.tscn --log-file .godot/economy_cleanup.log
```

Raport 10 000 z poprzedniej iteracji zachowano; nie deklarujemy, że jego dawne ostrzeżenie
zniknęło retrospektywnie ani że małe próby potwierdzają całkowity brak wycieków w grze.
Bezpośrednia regresja zamknięcia symulatora jest naprawiona i sprawdzona dla 48/480 próbek.

## Wynik bazowy — przed zmianą cen

Model bazowy wykonał **10 000 przebiegów** (seed `20261003`) w 145,941 s.
Pokrywa 48 kombinacji: trzy regiony × Ascension 0/5/10/20 × HIGH/LOW × dwie polityki zakupów.
Suma próbek scenariuszy wynosi 10 000. Nie wykryto naruszeń bilansu
`30 + gold_earned = gold_spent + gold + gold_fraction`.

To symulacja ekonomii bez walki, a nie 10 000 playtestów, pomiar win-rate ani prognoza feelingu.

## Źródła i ograniczenia

- Mapy i legalne przejścia generuje rzeczywisty StageTree. Trasa jest wybierana losowo.
- Budżety, fazy, role, capy w obrębie pulsu i mnożniki pochodzą ze Spawnera i StageData.
  Wartości złota odczytywane są z eksportowanych pól scen przeciwników.
- Model natychmiast zabija pełny puls, włącznie z fragmentami splittera, przed następnym.
  Respektuje czas etapu, minimalny odstęp pulsów, power pulses, elite i minibossy.
  Nie obejmuje przychodu z addów toksycznego bossa ani consumabli.
- Oferty oraz ceny generuje właściwy Shop; wolne nagrody generuje RewardRoller.
  Profil ma odblokowany cały katalog i zaczyna jednym z trzech common starterów.
- Treasure wybiera 35 złota. Boss 5 daje mutację, legalną losową legendary i kolejną
  nagrodę, następnie sklep. Po bossie 10 run kończy się bez zakupów.
- Polityki `items_first` i `upgrade_first` kupują do dwóch legalnych zwykłych ofert oraz
  jeden upgrade na wizytę. Mogą wymienić support przez legalną walidację buildu.
  Reroll następuje najwyżej raz, gdy nie kupiono zwykłego przedmiotu i starcza na kolejną ofertę.
- Wynik nie uwzględnia czasu zabijania, śmierci, leczenia, decyzji o sprzęcie zamiast złota,
  oceny wartości przedmiotów, dodatkowych rerolli ani wielu zakupów tego samego upgrade'u.
  Jest scenariuszem potencjału przychodów przy szybkim czyszczeniu, nie oszacowaniem realnego budżetu gracza.

## Przykład: Burning Grounds, items_first

W tabeli są mediany dla osobnych kohort (208–209 próbek). Mediany nie sumują się między kolumnami.

| Ascension | Preset | Zarobek | Zwykłe zakupy | Upgrade'y | Wizyty w sklepie | Saldo końcowe |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 0 | HIGH | 3561,0 | 4 | 2 | 2 | 3407,0 |
| 5 | HIGH | 3285,8 | 4 | 2 | 2 | 3108,4 |
| 10 | HIGH | 2946,8 | 4 | 2 | 2 | 2746,8 |
| 20 | HIGH | 2375,2 | 4 | 1 | 2 | 2220,3 |
| 0 | LOW | 2382,5 | 4 | 1 | 2 | 2189,8 |
| 5 | LOW | 2130,6 | 4 | 1 | 2 | 1929,9 |
| 10 | LOW | 1832,4 | 4 | 1 | 2 | 1646,4 |
| 20 | LOW | 1403,8 | 4 | 1 | 2 | 1269,6 |

Przykład A0/HIGH: mediany zarobku na akt wynoszą 190,0 / 1389,8 / 2016,8.
Pełny JSON zawiera p10/medianę/p90 przychodu, wydatków, zakupów, upgrade'ów, rerolli
i salda na każdy akt, a także wszystkie 48 kohort oraz histogramy ofert i cen.

## Rozkład ofert i bramki ekonomiczne

Zarejestrowano 74 020 ofert, także po rerollach:

| Typ | Liczba | Mediana oferowanej ceny |
| --- | ---: | ---: |
| Support | 20 921 | 12 |
| Passive | 19 801 | 15 |
| Skill | 14 793 | 20 |
| Stat upgrade | 18 505 | 105 |

Łączna mediana ceny zwykłej oferty wynosiła 15 złota. Startowe upgrade'y kosztowały
90/105/120, czyli 6/7/8 takich ofert, a nie docelowe 2–3. Ich dostępność finansowa nie jest
jednak problemem w tym modelu: najniższy udział runów z zakupionym upgradem wśród kohort
wynosi 93,75%, a najniższy udział wizyt z dostępnym cenowo zwykłym przedmiotem — 97,92%.

W iteracji bazowej nie obniżono cen na podstawie samego modelu. Późniejsza korekta pierwszej
ceny realizuje jawny próg 2–3 przedmiotów z planu, nie rozwiązuje nadmiaru waluty.

## Wnioski wymagające danych z walki

1. W wariancie szybkiego czyszczenia przychód znacznie przewyższa wydatki wybranych polityk.
   Szczególnie dużo waluty powstaje w trzecim akcie i po finale, gdy nie ma już zakupów.
2. LOW zmniejsza budżet przeciwników bez kompensacji nagrody. W przykładowych kohortach
   obniża medianę przychodu o około 33–41% względem HIGH. To wpływ ustawienia wydajności
   na ekonomię, który trzeba uwzględnić w testach słabszego telefonu.
3. Ascension zmniejsza przychód stopniowo; dodatnia nagroda nie jest zerowana przez int.
4. Kolejny krok to lokalna telemetria rzeczywistych spawnów, liczby zabójstw przed końcem
   timera, czasu oczekiwania, wizyt, zakupów i porzuconego salda. Bez niej nie rozstrzygamy,
   czy zmienić przychód, częstotliwość sklepów, ceny czy limity zakupów.

## Naprawy księgowania i weryfikacja

- Anulowanie kupionego skilla zwraca pieniądze przez `refund_gold`, zamiast zwiększać
  `gold_earned`. `gold_spent` oznacza wydatki netto po anulowaniu; `gold_refunded` zapisuje zwroty.
- Ponowny klik Cancel nie duplikuje zwrotu. Nie można zwrócić kwoty bez wcześniejszego wydatku.
- Cena kolejnego upgrade'u używa zaokrąglonego licznika zakupów, aby błędy sumowania float
  nie zaniżały kosztu. Test sprawdza po 50 zakupów każdego z trzech upgrade'ów.
- Test integralności sprawdza rzeczywistą ścieżkę kupno skilla przy pełnych slotach → Cancel,
  a następnie 100 cykli save/resume. Przeszedł również test statystyk obrażeń i checkpointów.

## Odtworzenie

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/economy_simulation.tscn --log-file .godot\economy_simulation.log -- --runs=10000 --seed=20261003
```

Raport maszynowy: `.godot/economy_simulation.json`. To plik cache; polecenie odtwarza go
z bieżących danych projektu. Symulator używa testowych ścieżek zapisów w `.godot`,
nie nadpisuje profilu użytkownika. Wyniki dotyczą obecnych danych; zmiana katalogu,
cen, gęstości lub polityki wymaga ponownego przebiegu.
