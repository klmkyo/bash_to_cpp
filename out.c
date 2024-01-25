#include <stdio.h>
int main() {


int limit=10;
int sum=0;
int i=0;

while (i <= limit)
{
if ((i % 2) == 0) {
sum=(sum + i);
printf("Added %d\n", i);
}
i=(i + 1);
}

printf("Sum of even numbers up to %d is: %d\n", limit,sum);

for ( int j=1; j <= 5; j++ )
{
printf("Sequence number: %d\n", j);
}

for i in {1..5}
{
printf("Range number: %d\n", i);
}

double a=1.5;
double b=2.5;
double c=3.5;
printf("a=%f,b=%f,c=%f\n", a,b,c);
sum=(a + b + c);
printf("sum=%d\n", sum);
const char* znaki="siema";
printf("znaki=%s\n", znaki);
}
