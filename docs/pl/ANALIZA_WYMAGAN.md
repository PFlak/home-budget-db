[EN](../eng/REQUIREMENTS_ANALYSIS.md) | **PL**

[Dom](./PRZECZYTAJMNIE.md) > Analiza Wymagań

# Analiza Wymagań

## Cel

Aplikacja ma na celu zarządzanie budżetem domowym użytkowników poprzez rejestrowanie przychodów oraz wydatków, analizy przepływów majątku oraz sporządzaniem podsumowań oraz raportów

## Zakres

Baza danych będzie obsługiwać użytkowników, ich portfele, grupy, kategorie wydatków oraz raporty finansowe

## Wymagania funkcjonalne

Funkcjonalność aplikacji została podzielona na poniższe moduły:

### Użytkownicy

- Rejestrowania użytkownika
- Logowanie użytkownika oraz przechowywanie aktywnych sesji
- Przechowywanie danych użytkownika, takich jak:
  - email;
  - imię i nazwisko;
  - unikalny nick;
  - zaszyfrowane hasło
  - obywatelstwo;
- Obsługa wielu użytkowników z separacją ich danych

### Portfele

- Możliwość tworzenia wielu portfeli przez użytkowników
- Portfele mogą być tworzone w różnych walutach
- Do portfeli możemy wpłacać oraz z nich wypłacać pieniądze

### Grupy

- Grupa może zawierać wielu użytkowników
- Każda grupa posiada:
  - nazwę;
  - opis (opcjonalne);
  - zdjęcie (opcjonalne);
- Użytkownicy mogą tworzyć oraz dołączać do grup
- Użytkownicy w grupach podzieleni są na role:
  - administator;
  - guest;

### Tranzakcje

- Rejestrowanie przychodów i wydatków
- Uwzględnienie użytkownika, grupy oraz portfela
- Kwalifikowanie tranzakcji względem kategorii oraz podkategorii (opcjonalne)
- Tylko portfele z wystarczającymi środkami mogą wykonać określoną transakcje

### Kategorie

- Tworzenie własnych kategorii i podkategorii
- Podsumowania tworzone uwzględniając kategorie
- Użycie kategorii w transakcjach

### Raporty

- Generowanie raportów finansowych:
  - bilans przychodów i wydatków w wybranym okresie;
  - wydatki z podziałem na kategorie

## Wymagania niefunkcjonalne

### Bezpieczeństwo

- Zapis *Posolenych* haseł
- Ograniczony dostęp do danych użytkownika - każdy użytkownik widzi tylko swoje dane
- Tylko administratorzy mają możliwość dodawania, zmiany uprawnień oraz usuwania użytkowników z grupy

### Zgodność
- Zgodność z systemem `PostreSQL`

### Wydajność
- Czas odpowiedzi na zapytania nie powinien przekraczać 1 sekundy dla typowych operacji