#!/bin/bash

# Initialize variables
limit=10
sum=0
i=0

# Using while loop for summing even numbers
while [ $i -le $limit ]; do
  # Math expression to check if number is even
  if [ $((i % 2)) -eq 0 ]; then
    # Math expression for summing
    sum=$((sum + i))
    echo "Added $i to sum"
  fi
  i=$((i + 1))
done

echo "Sum of even numbers up to $limit is: $sum"

# Using for loop for displaying a sequence
for ((j = 1; j <= 5; j++)); do
  echo "Sequence number: $j"
done

# for range
for i in {1..5}; do
  echo "Range number: $i"
done

# double, float testing
a=1.5
b=2.5
c=3.5
echo "a=$a,b=$b,c=$c"
sum=$((a + b + c))
echo "sum=$sum"
znaki="siema"
echo "znaki=$znaki"
