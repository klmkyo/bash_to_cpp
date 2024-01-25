#!/bin/bash

# Inicjalizacja zmiennych
limit=10
suma=0
i=0

echo "Obliczanie sumy liczb parzystych do $limit..."

# Używanie pętli while do sumowania liczb parzystych
while [ $i -le $limit ]; do
  # Wyrażenie matematyczne do sprawdzania, czy liczba jest parzysta
  if [ $((i % 2)) -eq 0 ]; then
    # Wyrażenie matematyczne do sumowania
    suma=$((suma + i))
    echo "Dodano $i do sumy, aktualna suma: $suma"
  fi
  i=$((i + 1))
done

echo "Suma liczb parzystych do $limit wynosi: $suma"

echo "Wyświetlanie sekwencji od 1 do 5 za pomocą pętli for..."

# Używanie pętli for do wyświetlania sekwencji
for ((j = 1; j <= 5; j++)); do
  echo "Numer sekwencji: $j"
done

echo "Wyświetlanie zakresu od 1 do 5 za pomocą pętli for range..."

# Zakres for
for i in {1..5}; do
  echo "Numer zakresu: $i"
done

echo "Demonstracja obsługi liczb niecałkowitych..."

# Testowanie double, float
a=1.5
b=2.5
c=3.5
echo "a=$a, b=$b, c=$c"

# Uwaga: Bash nie obsługuje arytmetyki zmiennoprzecinkowej.
# To nie da oczekiwanego wyniku.
suma=$((a + b + c))
echo "Próba sumowania $a, $b i $c (Uwaga: Bash nie obsługuje liczb zmiennoprzecinkowych): $suma"

echo "Demonstracja obsługi łańcuchów znaków..."

znaki="siema"
echo "znaki=$znaki"

echo "Wykonanie skryptu zakończone."
