
#include <stdio.h>

int main() {
    // Initialize variables
    int limit = 10;
    int sum = 0;
    int i = 0;

    // Using while loop for summing even numbers
    while (i <= limit) {
        // Math expression to check if number is even
        if ((i % 2) == 0) {
            // Math expression for summing
            sum = (sum + i);
            printf("Added %d to sum\n", i);
        }
        i = (i + 1);
    }

    printf("Sum of even numbers up to %d is: %d\n", limit, sum);

    // Using for loop for displaying a sequence
    for (int j = 1; j <= 5; j++) {
        printf("Sequence number: %d\n", j);
    }

    // for range
    for (int i = 1; i <= 5; i++) {
        printf("Range number: %d\n", i);
    }

    return 0;
}
