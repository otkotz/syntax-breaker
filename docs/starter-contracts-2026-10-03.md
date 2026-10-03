# Kontrakty startowe — 2026-10-03

Na ekranie wyboru skilla można wybrać Standard, Miner lub Architect. Każdy zaczyna ze
skillem common. Niedozwolone połączenia są zablokowane przez tę samą walidację supportów
co reszta gry; Mine nie pasuje do melee, Totem wymaga projectile.

| Kontrakt | Odblokowanie | Start | Złoto |
| --- | --- | --- | --- |
| Standard | Od początku | Common skill | 30 |
| Miner | 1 zwycięstwo, suma regionów | Common skill + Mine | 15 |
| Architect | 3 zwycięstwa, suma regionów | Common skill + Totem | 15 |

Support zużywa część początkowego budżetu według aktualnej tabeli cen sklepu, nie dodaje
darmowej wartości. Dziś Mine i Totem kosztują po 15. Każdy kontrakt ma zatem 45 wartości
sklepowej (common skill wart 15 + złoto + support). To wyrównanie ekonomiczne, nie dowód
równego win-rate ani mocy bojowej: natychmiastowy dostęp do trybu ataku może dawać przewagę
w pierwszym akcie, a niektóre kombinacje mogą być słabsze. Wymagają strojenia z playtestów.

Odblokowania wynikają z zapisanych zwycięstw regionalnych. Przy zwycięstwie lub wczytaniu
starszego profilu uzupełniany jest brakujący katalog Mine/Totem dla odblokowanych kontraktów.
Żadne zwycięstwa ani wcześniej odblokowane przedmioty nie są usuwane. Wczytanie nie wymusza
zapisu profilu; kolejne standardowe save utrwala migrację.

Kontrakt jest stosowany przed wejściem do pierwszego etapu. Nie można zastosować go ponownie
ani w trakcie runu. Początkowa alokacja nie jest dochodem, zakupem ani refundem; liczniki
Gold Earned/Spent pozostają zerowe. ID, koszt i początkowe złoto przechodzą aktywny save,
podpięty support przechodzi zwykłą serializację buildu. Telemetria zapisuje alokację i kontrakt,
a raport rozdziela kohorty również według kontraktu. Zmiana kontraktu odświeża dostępne oferty
startera, zamiast przypisywać wybór do nieaktualnej listy.

Miner umożliwia rozpoczęcie pomiaru Mine Specialist już w pierwszej walce. Nie blokuje jednak
rozwoju buildu: gracz może później wybrać normalny skill, tracąc warunek wyzwania. Miny i
totemy należą teraz do areny i znikają przy jej zamknięciu; nie przechodzą do następnej walki.

`tests/contracts_native.tscn` sprawdza odblokowania, starszy profil, wspólny budżet, tier common,
kompatybilność, blokadę powtórzeń i zmiany mid-run, zapis, GameManager oraz rzeczywistą pierwszą
arenę z Mine i sprzątanie miny. Dziesięć zestawów natywnych i smoke 300 klatek przechodzą.
Nie zebrano jeszcze dowodów równowagi bojowej kontraktów ani pełnego mine-only zwycięstwa gracza.
