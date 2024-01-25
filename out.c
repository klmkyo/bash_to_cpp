#include <stdio.h>
int main() {
    int limit = 10;
    int suma = 0;
    int i = 0;

    printf("Obliczanie sumy liczb parzystych do %d\n", limit);

    while (i <= limit) {
        if ((i % 2) == 0) {
            suma = (suma + i);
            printf("Dodano %d do sumy, aktualna suma: %d\n", i, suma);
        }
        i = (i + 1);
    }

    printf("Suma liczb parzystych do %d wynosi: %d\n", limit, suma);


    for (int j = 1; j <= 5; j++) {
        printf("Numer sekwencji: %d\n", j);
    }


    for (int i = 1; i <= 5; i++) {
        printf("Numer zakresu: %d\n", i);
    }


    int a = 1;
    int b = 2;
    int c = 3;
    printf("a=%d, b=%d, c=%d\n", a, b, c);

    suma = (a + b + c);
    printf(
        "Próba sumowania %d, %d i %d (Uwaga: Bash nie obsługuje liczb "
        "zmiennoprzecinkowych): %d\n",
        a, b, c, suma);


    const char* znaki = "test";
    printf("znaki=%s\n", znaki);
}
