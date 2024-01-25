---
title: Projekt 3. Programowanie Systemowe - Tłumaczenie Basha na C
author: Marcin Klimek, Kacper Kosmal
date: 25 stycznia 2024
subtitle: Systemy Operacyjne
numbersections: true
geometry: margin=3cm
---

\begin{center}

\thispagestyle{empty}
\vfill
\includegraphics[width=250px]{"./logo2.png"}
\end{center}

\newpage

\thispagestyle{empty}
\tableofcontents

\newpage

\setcounter{page}{1}
# Wstęp

Projekt prezentuje skrypt Bash, który konwertuje skrypt Bash na program w języku C. Celem tego projektu jest stworzenie narzędzia, które ułatwi przenoszenie prostych skryptów Bash do programów C.

# Kod programu

Skrypt składa się z kilku kluczowych części:

- Funkcje do tłumaczenia linii kodu Bash na C
- Obsługa specjalnych przypadków składni Bash, takich jak pętle, instrukcje warunkowe, echo i operacje arytmetyczne
- Główna pętla, która czyta skrypt Bash i tłumaczy go na C

Każda część skryptu skupia się na konkretnym zadaniu, co ułatwia zrozumienie i modyfikację kodu.

## Kluczowe Funkcje

### `variable_replacement`
Funkcja ta służy do zamiany deklaracji zmiennych z Bash na C. Wykorzystuje wyrażenia regularne do identyfikacji i zamiany zmiennych.

### `echo_translation`
Ta funkcja przekształca instrukcje `echo` z Bash na odpowiedniki w C, używając `printf`.

### `range_for_translation`
Funkcja konwertuje pętle `for` w Bash na ich odpowiedniki w C.

### `translate_line`
Główna funkcja do tłumaczenia pojedynczej linii kodu Bash na C. Wykorzystuje powyższe funkcje oraz dodatkowe wyrażenia regularne do obsługi innych przypadków.

## Proces tłumaczenia

Skrypt czyta każdą linię z podanego skryptu Bash, a następnie stosuje serię przekształceń, aby przetłumaczyć ją na C. Wszystkie przetłumaczone linie są zapisywane do pliku wyjściowego, który następnie może być kompilowany i uruchamiany jako program C.

# Działanie Programu

Program jest w stanie przetłumaczyć podstawowe konstrukcje języka Bash, w tym:

- Deklaracje zmiennych
- Instrukcje warunkowe
- Pętle
- Instrukcje echo
- Proste operacje arytmetyczne

Skrypt jest przydatny do szybkiego prototypowania i przekształcania prostych skryptów Bash, które nie wykorzystują zaawansowanych funkcji lub zewnętrznych poleceń.

# Ograniczenia

Skrypt ma kilka ograniczeń:

- Nie obsługuje wszystkich funkcji i składni Bash
- Może nie radzić sobie z bardziej skomplikowanymi skryptami
- Wymaga ręcznej interwencji w przypadku wystąpienia specyficznych konstrukcji Bash

# Podsumowanie

Projekt ten demonstruje, jak można użyć Bash i wyrażeń regularnych do stworzenia narzędzia do konwersji kodu. Jest to przykład prostego kompilatora, który może być przydatny w określonych scenariuszach. Mimo swoich ograniczeń, projekt stanowi ciekawe ćwiczenie z zakresu przetwarzania i tłumaczenia kodu.
