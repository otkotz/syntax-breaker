# Wyzwania archetypów — 2026-10-03

Codex ma zakładkę Challenges z jawnymi warunkami trzech osiągnięć. Ukończenie jest
zapisywane raz w profilu wraz z regionem, Ascension i datą; podsumowanie zwycięstwa pokazuje
nowe osiągnięcia. To cele poziome, bez stałych statystyk ani nagród zwiększających obrażenia.

- Mine Specialist: zwycięstwo z co najmniej jednym rzeczywistym postawieniem miny i bez
  normalnych/totemowych castów w całym runie. Spawn pocisku przez caster, także triggered
  recast, wyklucza osiągnięcie. DoT/proci przypisane do skilla miny są dozwolone, obrażenia
  bez przypisanego skilla (np. bomb consumable) nie. Samo podpięcie Mine na końcu nie wystarczy.
- Dual Compiler: rzeczywiste dodatnie obrażenia skilli pochodzą z dokładnie dwóch bazowych
  szkół fire/cold/lightning/poison. Obrażenia physical i nieprzypisane wykluczają cel. To szkoły
  bazowych zasobów skilla, nie każdy wtórny żywioł proca ani tag supporta. Nie liczy się samo
  posiadanie skilla, trafienie za zero ani końcowy build usuwający wcześniej użyty trzeci żywioł.
- Unpatched: zwycięstwo bez rzeczywistego odzyskania HP. Liczy się także regen po walce i
  auto-revive (naprawiono brak naliczenia odtworzonego HP do Healing Received). Ulepszenie
  max HP zachowujące procent zdrowia nie jest leczeniem. Leczenie przy pełnym HP za zero
  nie wyklucza celu.

Wszystkie cele wymagają dodatnich obrażeń w zwycięskim runie. Śmierć, pusty run i starszy
save bez `challenge_tracking_version=1` nie przyznają osiągnięć. Nowe liczniki przechodzą
aktywny save/resume i trafiają do statystyk telemetrii. Warunki nie są odtwarzane wstecz.

`tests/challenges_native.tscn` sprawdza cały przebieg elementów, trzeci żywioł, physical,
unknown damage, odrzucone trafienie, realne postawienie miny i spawn pocisku, regen,
save/resume, profil, idempotencję, brak power reward, Codex i podsumowanie. Regresja
telemetrii sprawdza dodatkowo HP odzyskane przez auto-revive. Dziewięć testów natywnych
przeszło; to dowód działania kodu, nie playtest ani dowód balansu wyzwań.

Kontrakt Miner pozwala już rozpocząć pierwszy etap z Mine po pierwszym zwycięstwie profilu.
Opis budżetu i ograniczeń: `docs/starter-contracts-2026-10-03.md`. Standardowy starter nadal
wymaga zwykłych castów przed pierwszą nagrodą; sam późny zakup Mine nie spełnia wyzwania.
Równość siły bojowej kontraktów nie została jeszcze potwierdzona. Kosmetyczne warianty i
trofea opisuje `docs/cosmetics-2026-10-03.md`; daily seed i historia wyników pozostają
zależne od ustabilizowania balansu.
