#!/bin/bash

# Zadeklaruj tablicę asocjacyjną do śledzenia zadeklarowanych zmiennych
declare -A declared_variables

# Funkcja do obsługi zastępowania zmiennych
variable_replacement() {
    local variable_name
    local variable_value
    local og_match

    # Wyrażenie regularne do dopasowywania przypisań zmiennych w bashu
    if [[ $line =~ ([[:alnum:]_]+)([[:space:]]*)=([[:space:]]*)([^;]+)(;|$) ]]; then
        og_match="${BASH_REMATCH[0]}"
        variable_name="${BASH_REMATCH[1]}"
        variable_value="${BASH_REMATCH[4]}"
    else
        return
    fi

    # Usuń ';' na końcu, jeśli jest obecne
    variable_value="${variable_value%;}"

    # Określ typ zmiennej na podstawie wartości
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

    # Sprawdź, czy nazwa zmiennej jest pusta
    if [[ -z "$variable_name" ]]; then
        echo "Error: nazwa zmiennej jest pusta"
        exit 1
    fi

    # Sprawdź, czy zmienna była wcześniej zadeklarowana
    local was_there=${declared_variables[$variable_name]+_}
    if [[ -n "$was_there" ]]; then
        line="${variable_name}=${variable_value};"
    else
        declared_variables[$variable_name]=$variable_type
        substitute="${variable_type} ${variable_name}=${variable_value};"
        line="${line/$og_match/$substitute}"
    fi
}

# Tabela przekierowań do formaterów typu printf
declare -A type_formatter_lookup
type_formatter_lookup["int"]="%d"
type_formatter_lookup["double"]="%f"
type_formatter_lookup["const char*"]="%s"

# Flaga wskazująca zakończenie tłumaczenia echo
echo_done=false

# Funkcja do tłumaczenia instrukcji echo
echo_translation() {
    local echo_content

    # Wyrażenie regularne do dopasowywania instrukcji echo
    if [[ $line =~ ^echo[[:space:]]+(.*)$ ]]; then
        echo_content="${BASH_REMATCH[1]}"
        echo_content="${echo_content%\"}"
        echo_content="${echo_content#\"}"

        local printf_command='printf("'
        local printf_arguments=()

        # Przetwarzanie każdej zmiennej w instrukcji echo
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

# Funkcja do tłumaczenia pętli for-range
range_for_translation() {
    local variable_name
    local start
    local end

    # Wyrażenie regularne do dopasowywania pętli for-range
    if [[ $line =~ for[[:space:]]+([[:alnum:]_]+)[[:space:]]+in[[:space:]]+\{([0-9]+)\.\.([0-9]+)\}\;([[:space:]]*)(\{)? ]]; then
        variable_name="${BASH_REMATCH[1]}"
        start="${BASH_REMATCH[2]}"
        end="${BASH_REMATCH[3]}"
        bracket="${BASH_REMATCH[5]}"

        line="for (int ${variable_name} = ${start}; ${variable_name} <= ${end}; ${variable_name}++) ${bracket}"
    fi
}

# Funkcja do tłumaczenia linii skryptu bash na C
translate_line() {
    line="$1"

    # Obsłuż komentarz: zamień # na // i nie tłumacz niczego po #
    if [[ "$line" =~ ^# ]]; then
        line=${line/#\#//}
        return
    fi

    # Sprawdź czy linia jest wspierana: jeśli jest to funkcja (wykrywana po słowie kluczowym function oraz nawiasach klamrowych), to napisz że skrypt nie jest wspierany
    if [[ "$line" =~ function ]]; then
        echo "Error: skrypt zawiera funkcje, które nie są wspierane"
        exit 1
    fi

    # Wykryj () w nazwie funkcji
    if [[ "$line" =~ [a-zA-Z_][a-zA-Z0-9_]*\(\) ]]; then
        echo "Error: skrypt zawiera funkcje, które nie są wspierane"
        exit 1
    fi

    # Tłumaczenie instrukcji echo
    echo_translation

    # Różne tłumaczenia przy użyciu sed
    line=$(echo "$line" | sed -E 's/^done$/}/')
    line=$(echo "$line" | sed -E 's/do$/{/')
    line=$(echo "$line" | sed -E 's/for \(\((.*)\)\);?/for (\1)/')

    # Arytmetyka: let "VAR=wyrażenie"
    line=$(echo "$line" | sed -E 's/^let "(\w+)=(.*)"$/\1 = \2;/')

    # Przypisanie zmiennej: VAR=wartość
    # tylko działa, jeśli echo_done jest fałszywe
    if [[ $echo_done == false ]]; then
        variable_replacement
    fi
    echo_done=false

    # Arytmetyka: $((wyrażenie))
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
    line=$(echo "$line" | sed -E 's/while \[ (.*) \];?/while (\1)/')
    line=$(echo "$line" | sed -E 's/\$(\w+)/\1/g')

    # Wypisz przetłumaczoną linię
    echo "$line" >>"$2"
}

input_file="$1"
output_file="$2"

# Wyczyść plik wynikowy
>"$output_file"

echo "#include <stdio.h>" >>"$output_file"
echo "int main() {" >>"$output_file"

# pętli przetwarzaj każdą linię i przetłumacz ją
while read -r line; do
    # Jeśli linia jest shebang, zignoruj ją
    if [[ "$line" =~ ^#! ]]; then
        continue
    fi

    # Przetłumacz linię i dodaj ją do pliku wynikowego
    echo "Translating: $line"
    translate_line "$line" "$output_file"
done <"$input_file"

echo "}" >>"$output_file"

# Skompiluj i uruchom plik wynikowy
gcc "$output_file" -o out && ./out
