Describe "determine"

  Include "$SHELLSPEC_HELPERDIR/../../../.github/scripts/determine.sh"

  It "works some magic"
    When call add 3 2
    The output should eq "5"
  End

End
