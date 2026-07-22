# format_rules

### Code Format Rules

- Put '{' and '}' on separate lines and have matching braces line up.

- Add a comment on the same line as every '}' to indicate what it is closing.
  For example, "} // HStack" or "} // ScrollView"  or "} // if", or 
               "} // class Metronome", etc.

- Place all function parameters on separate lines and align the ':'s up.

- Put a line of 12 '-' characters in front of every top level class or struct.

- Put a line of 4 '-' characters in front of every internal function declaration.

- Put 2 blank lines in front of each function declaration.

- Put a blank line before and after a comment. The blank line should come 
  AFTER the comment line, not before it. For example:
  
  Good:
    let x = 5
    
            // This is a comment
    
    let y = 10
  
  Bad:
    let x = 5
    
    
            // This is a comment
    let y = 10

- When indenting use only 2 spaces.

- For a comment describing the code that follows indent the comment an 
  extra 8 spaces farther than the code itself.
  
  Make all the colons line up in object definitions.
  
  Don't let any line exeed 100 characters wide.  If needed, break the line at
  the equal sign; put parameters on separate lines making their colons line up;
  etc.

end
