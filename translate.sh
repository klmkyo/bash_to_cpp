#!/bin/bash

declare -A declared_variables

variable_replacement() {
    local variable_name
    local variable_value

    local og_match
    # echo -e "\033[94m${line}\033[0m"

    if [[ $line =~ ([[:alnum:]_]+)([[:space:]]*)=([[:space:]]*)([^;]+)(;|$) ]]; then
        # PRINT ALL THE BASH_REMATCHES
        # for i in "${!BASH_REMATCH[@]}"; do
        #     echo -e "\033[92m${i}\033[0m is \033[92m${BASH_REMATCH[$i]}\033[0m"
        # done

        og_match="${BASH_REMATCH[0]}"

        variable_name="${BASH_REMATCH[1]}"
        variable_value="${BASH_REMATCH[4]}"
    else
        return
    fi


    # Trim ';' at the end if there
    variable_value="${variable_value%;}"
    
    # echo -e "\033[92m${variable_name}\033[0m is \033[92m${variable_value}\033[0m"

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

    if [[ -z "$variable_name" ]]; then
        echo "Error: variable name is empty"
        exit 1
    fi


    local was_there=${declared_variables[$variable_name]+_}

    if [[ -n "$was_there" ]]; then
        line="${variable_name}=${variable_value};"
    else
        declared_variables[$variable_name]=$variable_type
        # echo -e "\033[94m"
        # declare -p declared_variables
        # echo -e "\033[0m"

        substitute="${variable_type} ${variable_name}=${variable_value};"
        line="${line/$og_match/$substitute}"
    fi
}

declare -A type_formatter_lookup
type_formatter_lookup["int"]="%d"
type_formatter_lookup["double"]="%f"
type_formatter_lookup["const char*"]="%s"

echo_done=false

echo_translation() {
    local echo_content

    if [[ $line =~ ^echo[[:space:]]+(.*)$ ]]; then
        echo_content="${BASH_REMATCH[1]}"

        # Trim the "" at beginning and end if they are there
        echo_content="${echo_content%\"}"
        echo_content="${echo_content#\"}"

        local printf_command='printf("'
        local printf_arguments=()

        while [[ $echo_content =~ (\$[a-zA-Z_][a-zA-Z0-9_]*) ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local var_name_stripped="${var_name:1}"
            local var_type=${declared_variables[$var_name_stripped]}

            # DEBUG print variable name and type
            # echo -e "\033[92m${var_name_stripped}\033[0m is \033[92m${var_type}\033[0m"
            # echo -e "\033[94m${echo_content}\033[0m"

            # add up to the variable name
            printf_command+="${echo_content%%"$var_name"*}"
            printf_command+="${type_formatter_lookup[$var_type]}"
            printf_arguments+=("$var_name_stripped")

            # remove everything up to the variable name
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

translate_line() {
    line="$1"

    # in red
    # printf "\033[91m%s\033[0m\n" "$line"
    
    # Handle comment: convert # to //, and don't translate anything after #
    if [[ "$line" =~ ^# ]]; then
        line=${line/#\#//}
        # printf "\033[92m%s\033[0m\n" "$line"
        return
    fi


    # echo: echo "string"
    echo_translation
  
    line=$(echo "$line" | sed -E 's/^done$/}/')
    line=$(echo "$line" | sed -E 's/do$/{/')

    # for loops (())
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

    # if statement: if [ condition ]; then ... fi
    line=$(echo "$line" | sed -E 's/^if \[ (.*) \]; then$/if (\1) {/')
    line=$(echo "$line" | sed -E 's/^fi$/}/')

    # Conditions inside if statement: VAR -eq|ne|lt|le|gt|ge value
    line=$(echo "$line" | sed 's/-eq/==/g')
    line=$(echo "$line" | sed 's/-ne/!=/g')
    line=$(echo "$line" | sed 's/-lt/</g')
    line=$(echo "$line" | sed 's/-le/<=/g')
    line=$(echo "$line" | sed 's/-gt/>/g')
    line=$(echo "$line" | sed 's/-ge/>=/g')

    # for loop: for VAR in {start..end}; do ... done
    line=$(echo "$line" | sed -E 's/^for (\w+) in \{(\d+)\.\.(\d+)\}(;?)/for (int \1 = \2; \1 <= \3; \1++)/')

    # while loop: while [ condition ]; do ... done
    line=$(echo "$line" | sed -E 's/^while \[ (.*) \](.*)$/while (\1)/')

    # while loop: while [ condition ]
    line=$(echo "$line" | sed -E 's/^while \[ (.*) \]$/while (\1)/')

    # handle variable usage
    line=$(echo "$line" | sed -E 's/\$(\w+)/\1/g')

    # output the translated line
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