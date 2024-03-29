import re

def is_float(string):
    try:
        float(string)
        return True
    except ValueError:
        return False


# set of declared variables
declared_variables = {}

def variable_replacement(match):
    # Extract the value of the first group
    variable_name = match.group(1)
    variable_value = match.group(4)
    
    # trim ; at the end if there
    if variable_value.endswith(";"):
        variable_value = variable_value[:-1]
        
    # print(f"\033[92m{variable_name}\033[0m is \033[92m{variable_value}\033[0m")

    variable_type = ""
    if is_float(variable_value):
        if variable_value.isdigit():
            variable_type = "int"
        else:
            variable_type = "double"
    else:
        variable_type = "const char*"

    if variable_name == "":
        print("Error: variable name is empty")
        exit(1)

    # Perform some operation with extracted_value if needed
    # Construct the variable_replacement string

    was_there = variable_name in declared_variables

    if was_there:
        return f"{variable_name} = {variable_value};"
    else:
        declared_variables[variable_name] = variable_type
        # print in blue
        print("\033[94m")
        print(declared_variables)
        print("\033[0m")
        return f"{variable_type} {variable_name} = {variable_value};"


type_formatter_lookup = {"int": "%d", "double": "%f", "const char*": "%s"}


def echo_translation(line):
    def process(match):
        echo_content = match.group(1)

        # trim the "" at beginning and end if they are there
        if echo_content.startswith('"') and echo_content.endswith('"'):
            echo_content = echo_content[1:-1]

        pattern = r"(\$[a-zA-Z_]\w*)"
        # Splitting the text using the pattern
        arguments = re.split(pattern, echo_content)
        arguments = [x for x in arguments if x != ""]
        
        printf_command = 'printf("'
        printf_arguments = []

        for (i, arg) in enumerate(arguments):
            is_var = arg.startswith("$")
            is_last = i == len(arguments) - 1

            if is_var:
                var_name = arg[1:]
                var_type = declared_variables[var_name]
                printf_command += type_formatter_lookup[var_type]

                printf_arguments.append(var_name)
            else:
                printf_command += arg

        printf_command += '\\n"'
        
        if(len(printf_arguments)):
          printf_command += ', '

          printf_command += ", ".join(printf_arguments)

        printf_command += ");"

        return printf_command

    return re.sub(r"^echo (.*)$", process, line)
  
def translate_line(line):
    # in red
    print("\033[91m", end="")
    print(line)
    print("\033[0m", end="")
    
    if line == "sum=$((sum + i))":
      print("sum = sum + i;")
    
    # Handle comment: convert # to //, and don't translate anything after #
    is_match = re.match(r"#", line)
    if is_match:
      line = re.sub(r"#", "//", line)
      return line

        # echo: echo "string"
    line = echo_translation(line)
  
    line = re.sub(r"^done$", r"}", line)
    line = re.sub(r"do$", r"{", line)
    # for loops (())
    
    line = re.sub(r"^for \(\((.*)\)\)(.*)$", r"for (\1)", line)
    
    # Arithmetic: let "VAR=expression"
    line = re.sub(r'^let "(\w+)=(.*)"$', r"\1 = \2;", line)
    
    # Variable assignment: VAR=value
    line = re.sub(r"(\w+)(\s*)=(\s*)(\S*)(;|$)", variable_replacement, line)

    # Arithemtic: $((expression))
    line = re.sub(r"\$\(\((.*)\)\)$", r"(\1);", line)
    line = re.sub(r"\$\(\((.*)\)\)", r"(\1)", line)

    # if statement: if [ condition ]; then ... fi
    line = re.sub(r"^if \[ (.*) \]; then$", r"if (\1) {", line)
    line = re.sub(r"^fi$", r"}", line)

    # Conditions inside if statement: VAR -eq|ne|lt|le|gt|ge value
    line = re.sub(r"-eq", r"==", line)
    line = re.sub(r"-ne", r"!=", line)
    line = re.sub(r"-lt", r"< ", line)
    line = re.sub(r"-le", r"<=", line)
    line = re.sub(r"-gt", r"> ", line)
    line = re.sub(r"-ge", r">=", line)

    # for loop: for VAR in {start..end}; do ... done
    line = re.sub(
        r"^for (\w+) in \{(\d+)\.\.(\d+)\}(;?)",
        r"for (int \1 = \2; \1 <= \3; \1++)",
        line,
    )
    
    # while loop: while [ condition ]; do ... done
    line = re.sub(r"^while \[ (.*) \](.*)$", r"while (\1)", line)
    
    # while loop: while [ condition ]
    line = re.sub(r"^while \[ (.*) \]$", r"while (\1)", line)
    
    # handle variable usage
    line = re.sub(r"\$(\w+)", r"\1", line)
    
    # in green
    print("\033[92m", end="")
    print(line)
    print("\033[0m", end="")

    return line


pre = """
#include <stdio.h>

int main() {
"""

post = """
return 0;
}
"""

def translate_bash_to_c(bash_script):
    c_script = []
    
    c_script.append(pre)
    
    for line in bash_script.splitlines():
        if line.startswith("#!"):
            continue
      
        c_script.append(translate_line(line.strip()))
    
    c_script.append(post)
    
    return "\n".join(c_script)


# Example usage
bash_script = """
#!/bin/bash

# Initialize variables
limit=10
sum=0
i=0

# Using while loop for summing even numbers
while [ $i -le $limit ]
do
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
for (( j = 1; j <= 5; j++ ))
do
    echo "Sequence number: $j"
done

# for range
for i in {1..5}
do
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
"""

c_script = translate_bash_to_c(bash_script)

# print(c_script)

# save to file and try to compile
with open("script.c", "w") as f:
    f.write(c_script)
