#!/bin/bash

# Declare associative array to keep track of declared variables
declare -A declared_variables

# Function to handle variable replacement
variable_replacement() {
    local variable_name
    local variable_value
    local og_match

    # Regex to match variable assignments in bash
    if [[ $line =~ ([[:alnum:]_]+)([[:space:]]*)=([[:space:]]*)([^;]+)(;|$) ]]; then
        og_match="${BASH_REMATCH[0]}"
        variable_name="${BASH_REMATCH[1]}"
        variable_value="${BASH_REMATCH[4]}"
    else
        return
    fi

    # Trim ';' at the end if present
    variable_value="${variable_value%;}"
    
    # Determine variable type based on value
    local variable_type=""
    if [[ $variable_value =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
        if [[ $variable_value =~ ^[+-]?[0-9]+$ ]]; then
            variable_type="int"
        else
            variable_type="double"
        fi
    else
        variable_type="const char*"
    fi

    # Check for empty variable name
    if [[ -z "$variable_name" ]]; then
        echo "Error: variable name is empty"
        exit 1
    fi

    # Check if variable was previously declared
    local was_there=${declared_variables[$variable_name]+_}
    if [[ -n "$was_there" ]]; then
        line="${variable_name}=${variable_value};"
    else
        declared_variables[$variable_name]=$variable_type
        substitute="${variable_type} ${variable_name}=${variable_value};"
        line="${line/$og_match/$substitute}"
    fi
}

# Lookup table for printf type formatters
declare -A type_formatter_lookup
type_formatter_lookup["int"]="%d"
type_formatter_lookup["double"]="%f"
type_formatter_lookup["const char*"]="%s"

# Flag to indicate echo translation completion
echo_done=false

# Function to translate echo statements
echo_translation() {
    local echo_content

    # Regex to match echo statements
    if [[ $line =~ ^echo[[:space:]]+(.*)$ ]]; then
        echo_content="${BASH_REMATCH[1]}"
        echo_content="${echo_content%\"}"
        echo_content="${echo_content#\"}"

        local printf_command='printf("'
        local printf_arguments=()

        # Process each variable in the echo statement
        while [[ $echo_content =~ (\$[a-zA-Z_][a-zA-Z0-9_]*) ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local var_name_stripped="${var_name:1}"
            local var_type=${declared_variables[$var_name_stripped]}

            printf_command+="${echo_content%%"$var_name"*}"
            printf_command+="${type_formatter_lookup[$var_type]}"
            printf_arguments+=("$var_name_stripped")
            echo_content="${echo_content#*"$var_name"}"
        done

        printf_command+='\n"'


        if [[ ${#printf_arguments[@]} -gt 0 ]]; then
            IFS=","
            printf_command+=", ${printf_arguments[*]}"
            unset IFS
        fi

        printf_command+=");"
        line="$printf_command"
        echo_done=true
    fi
}

# Function to translate for-range loops
range_for_translation() {
    local variable_name
    local start
    local end

    # Regex to match for-range loops
    if [[ $line =~ ^for[[:space:]]+([[:alnum:]_]+)[[:space:]]+in[[:space:]]+\{([0-9]+)\.\.([0-9]+)\}$ ]]; then
        variable_name="${BASH_REMATCH[1]}"
        start="${BASH_REMATCH[2]}"
        end="${BASH_REMATCH[3]}"
        line="for (int ${variable_name} = ${start}; ${variable_name} <= ${end}; ${variable_name}++)"
    fi
}

# Function to translate a line of bash script to C
translate_line() {
    line="$1"

    # Handle comment: convert # to //, and don't translate anything after #
    if [[ "$line" =~ ^# ]]; then
        line=${line/#\#//}
        return
    fi


    # Translate echo statements
    echo_translation

    # Various translations using sed
    line=$(echo "$line" | sed -E 's/^done$/}/')
    line=$(echo "$line" | sed -E 's/do$/{/')
    line=$(echo "$line" | sed -E 's/^for \(\((.*)\)\)(.*)$/for (\1)/')

    # Arithmetic: let "VAR=expression"
    line=$(echo "$line" | sed -E 's/^let "(\w+)=(.*)"$/\1 = \2;/')

    # Variable assignment: VAR=value
    # only runs if echo_done is false
    if [[ $echo_done == false ]]; then
        variable_replacement
    fi
    echo_done=false

    # Arithmetic: $((expression))
    line=$(echo "$line" | sed -E 's/\$\(\((.*)\)\)$/(\1);/')
    line=$(echo "$line" | sed -E 's/\$\(\((.*)\)\)/(\1)/')
    line=$(echo "$line" | sed -E 's/^if \[ (.*) \]; then$/if (\1) {/')
    line=$(echo "$line" | sed -E 's/^fi$/}/')
    line=$(echo "$line" | sed 's/-eq/==/g')
    line=$(echo "$line" | sed 's/-ne/!=/g')
    line=$(echo "$line" | sed 's/-lt/</g')
    line=$(echo "$line" | sed 's/-le/<=/g')
    line=$(echo "$line" | sed 's/-gt/>/g')
    line=$(echo "$line" | sed 's/-ge/>=/g')
    range_for_translation
    line=$(echo "$line" | sed -E 's/^while \[ (.*) \](.*)$/while (\1)/')
    line=$(echo "$line" | sed -E 's/^while \[ (.*) \]$/while (\1)/')
    line=$(echo "$line" | sed -E 's/\$(\w+)/\1/g')

    # Output the translated line
    echo "$line"
}


# same as above, but as bash string
bash_script=$(cat << 'END_HEREDOC'
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
END_HEREDOC
)

# Create a file to store the translated lines
output_file="out.c"

# clear the output file
> "$output_file"

echo "#include <stdio.h>" >> "$output_file"
echo "int main() {" >> "$output_file"

# In a loop, go through each line and translate it
while read -r line; do
    # If line is a shebang, ignore it
    if [[ "$line" =~ ^#! ]]; then
        continue
    fi

    # Translate the line and append it to the output file
    translate_line "$line" >> "$output_file"
    # translate_line "$line"
done <<< "$bash_script"

echo "}" >> "$output_file"

# compile this shitt and run it
gcc "$output_file" -o out && ./out