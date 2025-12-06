Describe "Custom Modifier"
  payload() {
    echo "{ \"key1\": \"hello\", \"key2\": \"world\"}"
  }

  json_path() {
    # $1: stdout, $2: stderr, $3: status, $4..$N Custom args
    #echo "$1" | jq -re ".key1"
    echo "$1" | jq -re ".$4"
  }

#  It "will parse json"
#    When call payload
#    The result of function "json_path" "bob" should equal "hello"
#    #The result of function json_path with bob should equal "5"
#  End

  It "will use my custom modifier"
    When call payload
    The jq ".key1" of stdout should equal "hello"
    The output as jq ".key1" should equal "hello"
    #The jqfilter ".key1" of stdout should equal "helloz"
    #The jqfilter of stdout should equal "helloz"
  End
End
