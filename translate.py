import re

def translate_line(line):
    # Variable assignment: VAR=value
    line = re.sub(r'^(\w+)=(.*)$', r'int \1 = \2;', line)

    # Arithmetic: let "VAR=expression"
    line = re.sub(r'^let "(\w+)=(.*)"$', r'\1 = \2;', line)

    # if statement: if [ condition ]; then ... fi
    line = re.sub(r'^if \[ (.*) \]; then$', r'if (\1) {', line)
    line = re.sub(r'^fi$', r'}', line)

    # for loop: for VAR in {start..end}; do ... done
    line = re.sub(r'^for (\w+) in \{(\d+)\.\.(\d+)\}; do$', r'for (int \1 = \2; \1 <= \3; \1++) {', line)
    line = re.sub(r'^done$', r'}', line)

    # while loop: while [ condition ]; do ... done
    line = re.sub(r'^while \[ (.*) \]; do$', r'while (\1) {', line)

    return line

def translate_bash_to_c(bash_script):
    c_script = []
    for line in bash_script.splitlines():
        c_script.append(translate_line(line.strip()))
    return '\n'.join(c_script)

# Example usage
bash_script = """
a=5
let "a=a+1"
if [ $a -gt 5 ]; then
    echo "Greater"
fi
"""

c_script = translate_bash_to_c(bash_script)
print(c_script)
