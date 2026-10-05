# Zakres aktywnego celu — 2026-10-05

Treść aktywnego goala odczytana z sesji:

> trzeba tez przygotowac grafiki dla supportow i pasywek itp a stylu brotato/binding of isaac. menu jest nieprzejrzyste i maloczytelne;glowny ekran wyboru skilli takze maloczytelny i nie da sie kliknac w cale okienko tylko napis na dole;moze wieksze kafelki i lista przesuwana w dol?. trzeba cos wymyslec na wyzsze ascension bo teraz jedyna defensywa to hp pool

Rozszerzenie na wyraźną prośbę użytkownika „mozesz dodac poprzednia wiadomosc do goala”:

> przeprowadz poprawki na podstawie audytu

Audyt odniesienia: [czytelność i obrażenia walki](combat-readability-audit-2026-10-05.md).
Rozszerzenie obejmuje pociski wrogów, ostrzeżenia/aktywację ground effectów bossów,
one-shoty wynikające ze skalowania, wielkość sylwetek oraz wskazane w audycie
uzupełnienie telemetrii. Wdrożenie wymaga testów mechanik i kontroli renderów.

To zapis rozszerzenia w repozytorium, nie modyfikacja pola objective w interfejsie
goala: dostępne narzędzia sesji nie pozwalają edytować treści istniejącego aktywnego
goala. Aktualny goal pozostaje aktywny. Zakończenie poprawek walki nie kończy
wymagań dotyczących grafik, menu, wyboru skilli i defensywy.

Status rozszerzenia: poprawki walki wdrożono, sprawdzono natywne regresje,
rendery i zasoby z nowego APK. Szczegóły:
[wynik wdrożenia](combat-readability-fixes-2026-10-05.md).

Wybrany przez użytkownika kierunek defensywy:

> odnawialna oslona ktora bedzie mozna skalowac dzieki pasywkom

Wdrożono osłonę, trzy pasywki, stan w zapisie i HUD oraz pierwszą serię ikon.
Menu i wybór skilli mają większe elementy i pełną klikalność kafelków.
[Wynik, testy i pozostały zakres](shield-ui-2026-10-05.md).
Goal pozostaje aktywny: grafiki dla pozostałego katalogu i playtest na urządzeniu
nie są zakończone.

## Aktualizacja kolejności i punkt wznowienia

Użytkownik dopisał do celu: **grafiki na końcu**. Najpierw należy dokończyć
UI i weryfikację defensywy; nie rozpoczynać dalszych generacji wcześniej.
W lokalnym teście GUI odtworzono niedziałające przewijanie palcem w pickerze;
sam test kółka myszy nie wystarcza do potwierdzenia tej funkcji.

Pełny zapis dzisiejszych postępów, aktualnych dowodów i niedokończonych zadań:
[punkt wznowienia — 2026-10-05](progress-2026-10-05.md).
