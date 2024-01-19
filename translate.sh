#!/bin/bash

declare -A declared_variables

function variable_replacement {
    local variable_name="$1"
    local variable_value="$2"

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
        echo "${variable_name}=${variable_value};"
    else
        declared_variables[$variable_name]=$variable_type
        echo -e "\033[94m"
        declare -p declared_variables
        echo -e "\033[0m"
        echo "${variable_type} ${variable_name}=${variable_value};"
    fi
}

declare -A type_formatter_lookup
type_formatter_lookup["int"]="%d"
type_formatter_lookup["double"]="%f"
type_formatter_lookup["const char*"]="%s"

function echo_translation {
    local line="$1"
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
            echo -e "\033[92m${var_name_stripped}\033[0m is \033[92m${var_type}\033[0m"
            echo -e "\033[94m${echo_content}\033[0m"

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
        echo "$printf_command"
    fi
}

# Example usage
declared_variables["var1"]="int"
declared_variables["var2"]="double"
declared_variables["var3"]="const char*"
echo_translation "echo \"Value of var1: \$var1, var2: \$var2, and var3: \$var3\""