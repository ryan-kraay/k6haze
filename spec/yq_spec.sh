Describe "yq modifier"
  Include "spec/support/modifiers/yq.sh"

  Describe "with valid JSON"
    Data
      #|{"key": "value", "nested": {"id": "test"}}
    End

    It "should extract simple key"
      When call cat
      The output as yq ".key" should equal "value"
    End

    It "should extract nested key"
      When call cat
      The output as yq ".nested.id" should equal "test"
    End

    It "should return null for nonexistent key"
      When call cat
      The output as yq ".nonexistent" should equal "null"
    End
  End

  Describe "with null input"
    Data
      #|null
    End

    It "should handle null gracefully"
      When call cat
      The output as yq ".nonexistent" should equal "null"
    End

    It "should return null when accessing properties on null"
      When call cat
      The output as yq ".metadata.id" should equal "null"
    End
  End
End
