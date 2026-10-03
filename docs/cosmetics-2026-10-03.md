# Kosmetyki i trofea — 2026-10-03

Codex ma zakładki Cosmetics i Trophies. Wybór płaszcza oraz stylu pocisków zapisuje się w
profilu, a zablokowane opcje pokazują warunek odblokowania bez możliwości wyposażenia.
Nieznany ID, niezgodny slot lub utracony warunek odblokowania daje wariant domyślny.
Starsze profile bez nowego pola otrzymują bezpieczne ustawienia domyślne.

| Wariant | Warunek | Zakres zmiany |
| --- | --- | --- |
| Original Cloak | Od początku | Oryginalna paleta postaci |
| Silver Cloak | Unpatched | Cztery odcienie płaszcza |
| Verdant Cloak | Mine Specialist | Cztery odcienie płaszcza |
| Original Trails | Od początku | Dotychczasowe ślady pocisków |
| Faceted Trails | Dual Compiler | Rombowe ślady fireball/poison dart i dodatkowe akcenty śladu lightning |

Paleta zmienia wyłącznie indeksy 2–5 proceduralnego modelu BreakerSprite. Zachowuje obrys,
twarz, highlight i wszystkie akcenty żywiołu; komunikat trafienia nadal działa. Codex pokazuje
podgląd odblokowanych płaszczy. Wariant stosuje się przy tworzeniu gracza, a styl pocisku
przy initialize i jest czyszczony w reset puli. Wyposażenie nie tworzy supporta, nie dodaje
statystyk, nie zmienia rozmiaru kolizji, zasięgu, prędkości, pierce ani barwy żywiołu.

Ślady używają istniejących maksymalnie 12 pozycji. Nie tworzą dodatkowych pocisków, timerów
ani węzłów; cap pocisków jest bez zmian. Lightning dodaje najwyżej pięć małych ozdobnych
rombów na swoich istniejących segmentach. To nie dowód braku kosztu renderowania ani
czytelności na słabszym telefonie — oba pomiary pozostają otwarte.

Trofea regionalne mają odrębne znaki ognia, błyskawicy i trucizny oraz złotą ramkę po
ukończeniu regionu. Wynik jest wyprowadzany z zapisanych zwycięstw nad finałowym bossem;
samo odkrycie przeciwnika w Codexie nie wystarcza. Karty pokazują liczbę zwycięstw i poziom
odblokowanego Ascension. Trofea nie dają mocy i nie są przedmiotami do wyposażenia.

`tests/cosmetics_native.tscn` sprawdza warunki, wybór/zapis/wczytanie, fallback, paletę,
niezmienione parametry pocisku, reset i prezentację trofeów. Przeszło jedenaście zestawów
natywnych oraz smoke 300 klatek. To testy kodu headless, nie ocena renderowanego wyglądu
na telefonie. Docelowa czytelność oraz koszt draw calls wymagają weryfikacji urządzenia.

Daily seed i historia wyników pozostają zależne od ustabilizowania balansu, zgodnie z planem.
Nie wprowadzono ich jako zastępstwa za brakujące realne playtesty.
