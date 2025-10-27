Describe "Example specfile"
  Describe "hello()"
    hello() {
      echo # "hello $1"
    }

    add() {
      echo "$1 + $2" | bc
    }

    It "puts greeting, but not implemented"
      Pending "You should implement hello function"
      When call hello world
      The output should eq "hello world"
    End

    It "calculates the sum of two numbers"
      When call add 3 2
      The output should eq "5"
    End
  End
End
