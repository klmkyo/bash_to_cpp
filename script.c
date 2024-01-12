
#include <stdio.h>

int main() {



// Initialize variables
int limit = 10;
int sum = 0;
int i = 0;

// Using while loop for summing even numbers
while (i <= limit)
{
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
// for (( j = 1; j <= 5; j++ ))
// do
//     echo "Sequence number: $j"
// done

return 0;
}
