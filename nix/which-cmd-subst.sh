
# I keep forgetting which variable substitution I want.

echo -n "String? "
read str

echo -n "Delimiter? "
read delim

echo
echo , = delimiter
echo "#*,  ${str#*${delim}}"
echo "##*, ${str##*${delim}}"
echo "%*,  ${str%*${delim}}"
echo "%%*, ${str%%*${delim}}"
echo "#,*  ${str#${delim}*}"
echo "##,* ${str##${delim}*}"
echo "%,*  ${str%${delim}*}"
echo "%%,* ${str%%${delim}*}"
